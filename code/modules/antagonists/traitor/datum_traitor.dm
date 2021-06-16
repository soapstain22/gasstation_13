
/datum/antagonist/traitor
	name = "Traitor"
	roundend_category = "traitors"
	antagpanel_category = "Traitor"
	job_rank = ROLE_TRAITOR
	antag_moodlet = /datum/mood_event/focused
	antag_hud_type = ANTAG_HUD_TRAITOR
	antag_hud_name = "traitor"
	///10 seconds per hijack stage by default
	hijack_speed = 0.5
	ui_name = "TraitorInfo"
	///give this traitor objectives? doesn't include ending objective
	var/give_objectives = TRUE
	///give this traitor codewords? nanotrasen traitors do not.
	var/give_codewords = TRUE
	///give this traitor an uplink?
	var/give_uplink = TRUE
	///if TRUE, this traitor will always get hijacking as their final objective
	var/is_hijacker = FALSE

	///the name of the antag flavor this traitor has.
	var/employer

	///assoc list of strings set up after employer is given
	var/list/traitor_flavor

	///datum of the contractor hub, if they decide to become a contractor in the round.
	///in the future, this should definitely be moved into a component that attaches to these datums
	var/datum/contractor_hub/contractor_hub

	///reference to the uplink this traitor was given, if they were.
	var/datum/component/uplink/uplink

	///how many more objectives past the starting bunch need to get finished before escape objective is unlocked
	var/additional_objectives_before_escape = 4
	///if new objectives won't be added because a previously finished objective got unfinished, lazylist reference to uncompleted objectives
	var/list/new_objectives_blocked
	/**
	 * if objectives are unreasonable they get a 10 minute timer before a new objective is given for smooth progression. still doesn't count for greentext doe
	 * this is an assoc list, objective reference = timer id
	 */
	var/list/unreasonable_objective_timers = list()

	///when new objectives are blocked, the objectives to add pile up here
	var/objectives_to_add = 0
	///the final objective the traitor has to accomplish, be it escaping, hijacking, or just martyrdom.
	var/datum/objective/ending_objective

/datum/antagonist/traitor/on_gain()
	owner.special_role = job_rank
	if(give_objectives)
		forge_traitor_objectives()
	//will be actually later
	forge_ending_objective()

	//this can be 'as anything' at this point in the code as the non-smart ending objective is created but not added
	for(var/datum/objective/smart/objective as anything in objectives)
		RegisterSignal(objective, COMSIG_SMART_OBJECTIVE_ACHIEVED, .proc/objective_done)
		RegisterSignal(objective, COMSIG_SMART_OBJECTIVE_UNACHIEVED, .proc/objective_undone)
		RegisterSignal(objective, COMSIG_SMART_OBJECTIVE_REASONABLE, .proc/objective_reasonable)
		RegisterSignal(objective, COMSIG_SMART_OBJECTIVE_UNREASONABLE, .proc/objective_unreasonable)


	var/faction = prob(75) ? FACTION_SYNDICATE : FACTION_NANOTRASEN
	pick_employer(faction)

	traitor_flavor = strings(TRAITOR_FLAVOR_FILE, employer)

	if(give_uplink)
		owner.give_uplink(silent = TRUE, antag_datum = src)

	uplink = owner.find_syndicate_uplink()

	owner.current.playsound_local(get_turf(owner.current), 'sound/ambience/antag/tatoralert.ogg', 100, FALSE, pressure_affected = FALSE, use_reverb = FALSE)

	return ..()

/datum/antagonist/traitor/on_removal()
	if(!silent && owner.current)
		to_chat(owner.current, span_userdanger("You are no longer the [name]!"))

	owner.special_role = null

	return ..()

/datum/antagonist/traitor/proc/pick_employer(faction)
	var/possible_employers = list()
	switch(faction)
		if(FACTION_SYNDICATE)
			possible_employers = GLOB.syndicate_employers.Copy()
			if(istype(ending_objective, /datum/objective/hijack))
				possible_employers -= GLOB.normal_employers
			else //escape or martyrdom
				possible_employers -= GLOB.hijack_employers
		if(FACTION_NANOTRASEN)
			possible_employers = GLOB.nanotrasen_employers.Copy()
			if(istype(ending_objective, /datum/objective/hijack))
				possible_employers -= GLOB.normal_employers
			else //escape or martyrdom
				possible_employers -= GLOB.hijack_employers
	employer = pick(possible_employers)

/// Generates a complete set of traitor objectives up to the traitor objective limit, including non-generic objectives such as martyr and hijack.
/datum/antagonist/traitor/proc/forge_traitor_objectives()
	objectives.Cut()
	var/objective_count = 0

	if ((GLOB.joined_player_list.len >= HIJACK_MIN_PLAYERS) && prob(HIJACK_PROB))
		is_hijacker = TRUE
		objective_count++

	var/objective_limit = CONFIG_GET(number/traitor_objectives_amount)

	// for(in...to) loops iterate inclusively, so to reach objective_limit we need to loop to objective_limit - 1
	// This does not give them 1 fewer objectives than intended.
	for(var/i in objective_count to objective_limit - 1)
		objectives += forge_single_generic_objective()


/**
 * ## forge_ending_objective
 *
 * Forges the endgame objective, does NOT add it to this datum's objective list.
 * ending objective is added when the traitor completes enough objectives to earn the ending objective
 */
/datum/antagonist/traitor/proc/forge_ending_objective()
	if(is_hijacker)
		ending_objective = new /datum/objective/hijack
		ending_objective.owner = owner
		return

	var/martyr_compatibility = TRUE

	for(var/datum/objective/traitor_objective in objectives)
		if(!traitor_objective.martyr_compatible)
			martyr_compatibility = FALSE
			break

	if(martyr_compatibility && prob(MARTYR_PROB))
		ending_objective = new /datum/objective/martyr
		ending_objective.owner = owner
		objectives += ending_objective
		return

	ending_objective = new /datum/objective/escape
	ending_objective.owner = owner
	objectives += ending_objective

/// Adds a generic kill or steal objective to this datum's objective list.
/datum/antagonist/traitor/proc/forge_single_generic_objective()
	if(prob(KILL_PROB))
		var/list/active_ais = active_ais()
		if(active_ais.len && prob(DESTROY_AI_PROB(GLOB.joined_player_list.len)))
			return create_smart_objective(/datum/objective/smart/destroy_ai)
		if(prob(MAROON_PROB))
			return create_smart_objective(/datum/objective/smart/maroon)
		return create_smart_objective(/datum/objective/smart/assassinate)

	if(prob(DOWNLOAD_PROB) && !(locate(/datum/objective/smart/download) in objectives) && !(owner.assigned_role in list("Research Director", "Scientist", "Roboticist", "Geneticist")))
		return create_smart_objective(/datum/objective/smart/download) //note to self: smart objective needs to use a different proc than this one used to

	return create_smart_objective(/datum/objective/smart/steal)

/// small helper does all the setup for smart objective adding
/datum/antagonist/traitor/proc/create_smart_objective(type)
	var/datum/objective/smart/new_objective = new type
	new_objective.owner = owner
	new_objective.find_target()
	new_objective.post_find_target()
	return new_objective

/datum/antagonist/traitor/greet()
	to_chat(owner.current, span_alertsyndie(traitor_flavor["introduction"]))

/datum/antagonist/traitor/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/datum_owner = mob_override || owner.current

	antag_memory += "Your allegiances: \"[traitor_flavor["allies"]]\"" + "<br>"

	add_antag_hud(antag_hud_type, antag_hud_name, datum_owner)
	handle_clown_mutation(datum_owner, mob_override ? null : "Your training has allowed you to overcome your clownish nature, allowing you to wield weapons without harming yourself.")
	datum_owner.AddComponent(/datum/component/codeword_hearing, GLOB.syndicate_code_phrase_regex, "blue", src)
	datum_owner.AddComponent(/datum/component/codeword_hearing, GLOB.syndicate_code_response_regex, "red", src)

/datum/antagonist/traitor/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/datum_owner = mob_override || owner.current
	remove_antag_hud(antag_hud_type, datum_owner)
	handle_clown_mutation(datum_owner, removing = FALSE)

	for(var/datum/component/codeword_hearing/component as anything in datum_owner.GetComponents(/datum/component/codeword_hearing))
		component.delete_if_from_source(src)

/datum/antagonist/traitor/roundend_report()
	var/list/result = list()

	var/traitor_won = TRUE

	result += printplayer(owner)

	var/used_red_telecrystals = 0
	var/uplink_owned = FALSE
	var/purchases = ""

	LAZYINITLIST(GLOB.uplink_purchase_logs_by_key)
	// Uplinks add an entry to uplink_purchase_logs_by_key on init.
	var/datum/uplink_purchase_log/purchase_log = GLOB.uplink_purchase_logs_by_key[owner.key]
	if(purchase_log)
		used_red_telecrystals = purchase_log.total_spent
		uplink_owned = TRUE
		purchases += purchase_log.generate_render(FALSE)

	var/objectives_text = ""
	if(objectives.len) //If the traitor had no objectives, don't need to process this.
		var/count = 1
		for(var/datum/objective/objective in objectives)
			if(objective.check_completion())
				objectives_text += "<br><B>Objective #[count]</B>: [objective.explanation_text] [span_greentext("Success!")]"
			else
				objectives_text += "<br><B>Objective #[count]</B>: [objective.explanation_text] [span_redtext("Fail.")]"
				traitor_won = FALSE
			count++

	if(uplink_owned)
		var/uplink_text = "(used [used_red_telecrystals] red TC) [purchases]"
		if((used_red_telecrystals == 0) && traitor_won)
			var/static/icon/badass = icon('icons/badass.dmi', "badass")
			uplink_text += "<BIG>[icon2html(badass, world)]</BIG>"
		result += uplink_text

	result += objectives_text

	var/special_role_text = lowertext(name)

	if (contractor_hub)
		result += contractor_round_end()

	if(traitor_won)
		result += span_greentext("The [special_role_text] was successful!")
	else
		result += span_redtext("The [special_role_text] has failed!")
		SEND_SOUND(owner.current, 'sound/ambience/ambifailure.ogg')

	return result.Join("<br>")

/// Proc detailing contract kit buys/completed contracts/additional info
/datum/antagonist/traitor/proc/contractor_round_end()
	var/result = ""
	var/total_spent_rep = 0

	var/completed_contracts = contractor_hub.contracts_completed
	var/tc_total = contractor_hub.contract_TC_payed_out + contractor_hub.contract_TC_to_redeem

	var/contractor_item_icons = "" // Icons of purchases
	var/contractor_support_unit = "" // Set if they had a support unit - and shows appended to their contracts completed

	/// Get all the icons/total cost for all our items bought
	for (var/datum/contractor_item/contractor_purchase in contractor_hub.purchased_items)
		contractor_item_icons += "<span class='tooltip_container'>\[ <i class=\"fas [contractor_purchase.item_icon]\"></i><span class='tooltip_hover'><b>[contractor_purchase.name] - [contractor_purchase.cost] Rep</b><br><br>[contractor_purchase.desc]</span> \]</span>"

		total_spent_rep += contractor_purchase.cost

		/// Special case for reinforcements, we want to show their ckey and name on round end.
		if (istype(contractor_purchase, /datum/contractor_item/contractor_partner))
			var/datum/contractor_item/contractor_partner/partner = contractor_purchase
			contractor_support_unit += "<br><b>[partner.partner_mind.key]</b> played <b>[partner.partner_mind.current.name]</b>, their contractor support unit."

	if (contractor_hub.purchased_items.len)
		result += "<br>(used [total_spent_rep] Rep) "
		result += contractor_item_icons
	result += "<br>"
	if (completed_contracts > 0)
		var/pluralCheck = "contract"
		if (completed_contracts > 1)
			pluralCheck = "contracts"

		result += "Completed [span_greentext("[completed_contracts]")] [pluralCheck] for a total of \
					[span_greentext("[tc_total] TC")]![contractor_support_unit]<br>"

	return result

///signal called by an objective completing
/datum/antagonist/traitor/proc/objective_done(datum/objective/smart/objective)
	SIGNAL_HANDLER

	var/possible_reroll_timer = unreasonable_objective_timers[objective]
	if(possible_reroll_timer)
		deltimer(possible_reroll_timer)

	if(new_objectives_blocked)
		if(!LAZYFIND(new_objectives_blocked, objective))
			objectives_to_add++
			to_chat(owner.current, "<span class='warning'>You have completed an objective, \
			but you cannot get more until you make sure previously uncompleted objectives are once again complete!</span>")
			return
		LAZYREMOVE(new_objectives_blocked, objective)
		if(new_objectives_blocked)
			to_chat(owner.current, "<span class='warning'>You have re-accomplished an objective, \
			but there are still more un-completed objectives for you to complete before you can get more.</span>")
			return
		to_chat(owner.current, "<span class='warning'>You have re-accomplished an objective, \
		and you are ready once again to get more. Any objectives that were waiting will now be added.</span>")
		for(var/iteration in 1 to objectives_to_add)
			if(!additional_objectives_before_escape)
				if(!ending_objective)
					to_chat(owner.current, "<span class='boldnotice'>You have completed enough objectives. Your final objective has been granted.</span>")
					objectives += ending_objective
				break
			objectives += forge_single_generic_objective()
		objectives_to_add = 0
		return

	if(additional_objectives_before_escape && !ending_objective)
		additional_objectives_before_escape--
		to_chat(owner.current, "<span class='boldnotice'>You have completed an objective. A new objective has been granted.</span>")
		uplink?.black_telecrystals += objective.black_telecrystal_reward
		objectives += forge_single_generic_objective()
		return
	to_chat(owner.current, "<span class='boldnotice'>You have completed enough objectives. Your final objective has been granted.</span>")
	objectives += ending_objective

///signal called by an objective uncompleting
/datum/antagonist/traitor/proc/objective_undone(datum/objective/smart/objective)
	SIGNAL_HANDLER

	if(objective.unreasonable)
		to_chat(owner.current, "<span class='boldwarning'>Your \"[objective]\" objective is no longer complete. \
		Considering the status of the objective at this point, you are not blocked from getting more objectives and moving on.</span>")
		return
	to_chat(owner.current, "<span class='boldwarning'>Your \"[objective]\" objective is no longer complete. \
	You are restricted from getting more objectives until you accomplish it.</span>")
	LAZYADD(new_objectives_blocked, objective)

/datum/antagonist/traitor/proc/objective_reasonable(datum/objective/smart/objective)
	SIGNAL_HANDLER

	if(objective.completed)
		return
	to_chat(owner.current, "<span class='boldwarning'>Your \"[objective]\" objective is once again reasonable to complete. \
	You must now complete this objective before getting new objectives.</span>")
	LAZYADD(new_objectives_blocked, objective)

/datum/antagonist/traitor/proc/objective_unreasonable(datum/objective/smart/objective)
	SIGNAL_HANDLER

	if(objective.completed)
		return
	to_chat(owner.current, "<span class='boldnotice'>Your \"[objective]\" objective is no longer reasonable to complete. \
	You are being given a new objective, and this one will reroll after [DisplayTimeText(OBJECTIVE_REROLL_TIMER)] into a new objective.</span>")
	objectives += forge_single_generic_objective()
	var/new_timer_id = addtimer(CALLBACK(src, .proc/reroll, objective), OBJECTIVE_REROLL_TIMER)
	unreasonable_objective_timers[objective] = new_timer_id

/datum/antagonist/traitor/proc/reroll(datum/objective/smart/objective)
	to_chat(owner.current, "<span class='boldnotice'>Your \"[objective.name]\" objective has been rerolled.</span>")
	unreasonable_objective_timers -= objective
	var/removed_objective_list_position = objectives.Find(objective)
	objectives[removed_objective_list_position] = "ERROR"
	qdel(objective)
	//replaced by this
	var/new_objective = forge_single_generic_objective()
	objectives[removed_objective_list_position] = new_objective

/datum/antagonist/traitor/ui_static_data(mob/user)
	var/list/data = list()
	data["phrases"] = jointext(GLOB.syndicate_code_phrase, ", ")
	data["responses"] = jointext(GLOB.syndicate_code_response, ", ")
	data["theme"] = traitor_flavor["ui_theme"]
	data["code"] = uplink.unlock_code
	data["intro"] = traitor_flavor["introduction"]
	data["allies"] = traitor_flavor["allies"]
	data["goal"] = traitor_flavor["goal"]
	data["has_uplink"] = uplink ? TRUE : FALSE
	if(uplink)
		data["uplink_intro"] = traitor_flavor["uplink"]
		data["uplink_unlock_info"] = uplink.unlock_text
	data["objectives"] = get_objectives()
	return data

/datum/antagonist/traitor/roundend_report_footer()
	var/phrases = jointext(GLOB.syndicate_code_phrase, ", ")
	var/responses = jointext(GLOB.syndicate_code_response, ", ")

	var/message = "<br><b>The code phrases were:</b> <span class='bluetext'>[phrases]</span><br>\
					<b>The code responses were:</b> [span_redtext("[responses]")]<br>"

	return message
