
//////////////////////////////////////////////
//                                          //
//           SYNDICATE TRAITORS             //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/traitor
	name = "Traitors"
	persistent = TRUE
	antag_flag = ROLE_TRAITOR
	antag_datum = /datum/antagonist/traitor/
	protected_roles = list("Security Officer", "Warden", "Detective", "Head of Security", "Captain")
	restricted_roles = list("Cyborg")
	required_candidates = 1
	weight = 5
	cost = 10
	requirements = list(10,10,10,10,10,10,10,10,10,10)
	high_population_requirement = 10
	var/autotraitor_cooldown = 450 // 15 minutes (ticks once per 2 sec)

/datum/dynamic_ruleset/roundstart/traitor/pre_execute()
	var/traitor_scaling_coeff = 10 - max(0,round(mode.threat_level/10)-5) // Above 50 threat level, coeff goes down by 1 for every 10 levels
	var/num_traitors = min(round(mode.candidates.len / traitor_scaling_coeff) + 1, candidates.len)
	for (var/i = 1 to num_traitors)
		var/mob/M = pick(candidates)
		assigned += M
		candidates -= M
		M.mind.special_role = antag_flag
		M.mind.restricted_roles = restricted_roles
	return TRUE

/datum/dynamic_ruleset/roundstart/traitor/process()
	if (autotraitor_cooldown)
		autotraitor_cooldown--
	else
		autotraitor_cooldown = 450 // 15 minutes
		message_admins("Dynamic Mode: Checking if we can turn someone into a traitor...")
		mode.picking_specific_rule(/datum/dynamic_ruleset/midround/autotraitor)

//////////////////////////////////////////////
//                                          //
//               CHANGELINGS                //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/changeling
	name = "Changelings"
	antag_flag = ROLE_CHANGELING
	antag_datum = /datum/antagonist/changeling
	restricted_roles = list("AI", "Cyborg")
	protected_roles = list("Security Officer", "Warden", "Detective", "Head of Security", "Captain")
	required_candidates = 1
	weight = 3
	cost = 30
	requirements = list(80,70,60,50,40,20,20,10,10,10)
	high_population_requirement = 30

/datum/dynamic_ruleset/roundstart/changeling/pre_execute()
	var/num_changelings = min(round(mode.candidates.len / 10) + 1, candidates.len)
	for (var/i = 1 to num_changelings)
		var/mob/M = pick(candidates)
		assigned += M
		candidates -= M
		M.mind.special_role = ROLE_CHANGELING
		M.mind.restricted_roles = restricted_roles
	return TRUE

/datum/dynamic_ruleset/roundstart/changeling/execute()
	var/list/team_objectives = subtypesof(/datum/objective/changeling_team_objective)
	var/list/possible_team_objectives = list()
	for(var/T in team_objectives)
		var/datum/objective/changeling_team_objective/CTO = T

		if(assigned.len >= initial(CTO.min_lings))
			possible_team_objectives += T

	if(possible_team_objectives.len && prob(20*assigned.len))
		GLOB.changeling_team_objective_type = pick(possible_team_objectives)

	for(var/datum/mind/changeling in assigned)
		var/datum/antagonist/changeling/new_antag = new antag_datum()
		new_antag.team_mode = TRUE
		changeling.add_antag_datum(new_antag)

	return TRUE

//////////////////////////////////////////////
//                                          //
//               WIZARDS                    //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/wizard
	name = "Wizard"
	antag_flag = ROLE_WIZARD
	antag_datum = /datum/antagonist/wizard
	restricted_roles = list("Head of Security", "Captain") // Just to be sure that a wizard getting picked won't ever imply a Captain or HoS not getting drafted
	required_candidates = 1
	weight = 3
	cost = 30
	requirements = list(90,90,70,40,30,20,10,10,10,10)
	high_population_requirement = 40
	var/list/roundstart_wizards = list()

/datum/dynamic_ruleset/roundstart/wizard/acceptable(var/population=0,var/threat=0)
	if(GLOB.wizardstart.len == 0)
		log_admin("Cannot accept Wizard ruleset. Couldn't find any wizard spawn points.")
		message_admins("Cannot accept Wizard ruleset. Couldn't find any wizard spawn points.")
		return FALSE
	return ..()

/datum/dynamic_ruleset/roundstart/wizard/pre_execute()
	if(GLOB.wizardstart.len == 0)
		return FALSE
	
	var/mob/M = pick(candidates)
	if (M)
		assigned += M
		candidates -= M
		M.mind.assigned_role = ROLE_WIZARD
		M.mind.special_role = ROLE_WIZARD
	
	return TRUE

/datum/dynamic_ruleset/roundstart/wizard/execute()
	for(var/mob/M in assigned)
		M.mind.current.forceMove(pick(GLOB.wizardstart))
		M.mind.add_antag_datum(new antag_datum())
	return TRUE
	
//////////////////////////////////////////////
//                                          //
//                BLOOD CULT                //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/bloodcult
	name = "Blood Cult"
	antag_flag = ROLE_CULTIST
	antag_datum = /datum/antagonist/cult
	restricted_roles = list("AI", "Cyborg", "Security Officer", "Warden", "Detective", "Head of Security", "Captain", "Chaplain", "Head of Personnel")
	required_candidates = 4
	weight = 3
	cost = 30
	requirements = list(90,80,60,30,20,10,10,10,10,10)
	high_population_requirement = 40
	flags = HIGHLANDER_RULESET
	var/cultist_cap = list(2,2,3,4,4,4,4,4,4,4)
	var/datum/team/cult/main_cult

/datum/dynamic_ruleset/roundstart/bloodcult/ready(var/forced = 0)
	var/indice_pop = min(10,round(mode.roundstart_pop_ready/5)+1)
	required_candidates = cultist_cap[indice_pop]
	. = ..()

/datum/dynamic_ruleset/roundstart/bloodcult/pre_execute()
	var/indice_pop = min(10,round(mode.roundstart_pop_ready/5)+1)
	var/cultists = cultist_cap[indice_pop]

	for(var/cultists_number = 1 to cultists)
		if(candidates.len <= 0)
			break
		var/mob/M = pick(candidates)
		assigned += M
		candidates -= M
		M.mind.special_role = ROLE_CULTIST
		M.mind.restricted_roles = restricted_roles

	return TRUE

/datum/dynamic_ruleset/roundstart/bloodcult/execute()
	main_cult = new
	for(var/mob/M in assigned)
		var/datum/antagonist/cult/new_cultist = new antag_datum()
		new_cultist.give_equipment = TRUE
		M.mind.add_antag_datum(new_cultist)	
	main_cult.setup_objectives()
	return TRUE

/datum/dynamic_ruleset/roundstart/bloodcult/round_result()
	..()
	if(main_cult.check_cult_victory())
		SSticker.mode_result = "win - cult win"
		SSticker.news_report = CULT_SUMMON
	else
		SSticker.mode_result = "loss - staff stopped the cult"
		SSticker.news_report = CULT_FAILURE

//////////////////////////////////////////////
//                                          //
//          NUCLEAR OPERATIVES              //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/nuclear
	name = "Nuclear Emergency"
	antag_flag = ROLE_OPERATIVE
	antag_datum = /datum/antagonist/nukeop
	var/datum/antagonist/antag_leader_datum = /datum/antagonist/nukeop/leader
	restricted_roles = list("Head of Security", "Captain") // Just to be sure that a nukie getting picked won't ever imply a Captain or HoS not getting drafted
	required_candidates = 5
	weight = 3
	cost = 40
	requirements = list(90,90,90,80,60,40,30,20,10,10)
	high_population_requirement = 60
	flags = HIGHLANDER_RULESET
	var/operative_cap = list(2,2,3,3,4,5,5,5,5,5)
	var/datum/team/nuclear/nuke_team


/datum/dynamic_ruleset/roundstart/nuclear/ready(var/forced = 0)
	var/indice_pop = min(10,round(mode.roundstart_pop_ready/5)+1)
	required_candidates = operative_cap[indice_pop]
	. = ..()

/datum/dynamic_ruleset/roundstart/nuclear/pre_execute()
	// If ready() did its job, candidates should have 5 or more members in it

	var/indice_pop = min(10,round(mode.roundstart_pop_ready/5)+1)
	var/operatives = operative_cap[indice_pop]
	for(var/operatives_number = 1 to operatives)
		if(candidates.len <= 0)
			break
		var/mob/M = pick(candidates)
		assigned += M
		candidates -= M
	return TRUE

/datum/dynamic_ruleset/roundstart/nuclear/execute()
	var/leader = TRUE
	for(var/mob/M in assigned)
		M.mind.assigned_role = "Nuclear Operative"
		M.mind.special_role = "Nuclear Operative"
		if (leader)
			leader = FALSE
			var/datum/antagonist/nukeop/leader/new_op = new antag_leader_datum()
			nuke_team = new_op.nuke_team
			M.mind.add_antag_datum(new_op)
		else
			var/datum/antagonist/nukeop/new_op = new antag_datum()
			M.mind.add_antag_datum(new_op)

/datum/dynamic_ruleset/roundstart/nuclear/check_finished()
	if(nuke_team.operatives_dead())
		for(var/obj/machinery/nuclearbomb/N in GLOB.nuke_list)
			if(N.proper_bomb && (N.timing || N.exploding))
				return FALSE
		// If ops are dead and bomb is not exploding, end the round
		return TRUE
	return FALSE

/datum/dynamic_ruleset/roundstart/nuclear/round_result()
	var result = nuke_team.get_result()
	switch(result)
		if(NUKE_RESULT_FLUKE)
			SSticker.mode_result = "loss - syndicate nuked - disk secured"
			SSticker.news_report = NUKE_SYNDICATE_BASE
		if(NUKE_RESULT_NUKE_WIN)
			SSticker.mode_result = "win - syndicate nuke"
			SSticker.news_report = STATION_NUKED
		if(NUKE_RESULT_NOSURVIVORS)
			SSticker.mode_result = "halfwin - syndicate nuke - did not evacuate in time"
			SSticker.news_report = STATION_NUKED
		if(NUKE_RESULT_WRONG_STATION)
			SSticker.mode_result = "halfwin - blew wrong station"
			SSticker.news_report = NUKE_MISS
		if(NUKE_RESULT_WRONG_STATION_DEAD)
			SSticker.mode_result = "halfwin - blew wrong station - did not evacuate in time"
			SSticker.news_report = NUKE_MISS
		if(NUKE_RESULT_CREW_WIN_SYNDIES_DEAD)
			SSticker.mode_result = "loss - evacuation - disk secured - syndi team dead"
			SSticker.news_report = OPERATIVES_KILLED
		if(NUKE_RESULT_CREW_WIN)
			SSticker.mode_result = "loss - evacuation - disk secured"
			SSticker.news_report = OPERATIVES_KILLED
		if(NUKE_RESULT_DISK_LOST)
			SSticker.mode_result = "halfwin - evacuation - disk not secured"
			SSticker.news_report = OPERATIVE_SKIRMISH
		if(NUKE_RESULT_DISK_STOLEN)
			SSticker.mode_result = "halfwin - detonation averted"
			SSticker.news_report = OPERATIVE_SKIRMISH
		else
			SSticker.mode_result = "halfwin - interrupted"
			SSticker.news_report = OPERATIVE_SKIRMISH

//////////////////////////////////////////////
//                                          //
//               REVS		                //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/delayed/revs
	name = "Revolution"
	persistent = TRUE
	antag_flag = ROLE_REV_HEAD
	antag_datum = /datum/antagonist/rev/head
	restricted_roles = list("AI", "Cyborg", "Security Officer", "Warden", "Detective", "Head of Security", "Captain", "Head of Personnel", "Chief Engineer", "Chief Medical Officer", "Research Director")
	required_candidates = 3
	weight = 2
	cost = 35
	requirements = list(101,101,70,40,30,20,10,10,10,10)
	high_population_requirement = 50
	delay = 5 MINUTES
	flags = HIGHLANDER_RULESET
	var/required_heads = 3
	var/datum/team/revolution/revolution
	var/finished = 0

/datum/dynamic_ruleset/roundstart/delayed/revs/ready(var/forced = 0)
	if (forced)
		required_heads = 1
		required_candidates = 1
	if (!..())
		return FALSE
	var/head_check = 0
	for (var/mob/dead/new_player/player in GLOB.player_list)
		if (player.mind.assigned_role in GLOB.command_positions)
			head_check++
	return (head_check >= required_heads)

/datum/dynamic_ruleset/roundstart/delayed/revs/execute()
	var/max_canditates = 4
	revolution = new()
	for(var/i = 1 to max_canditates)
		if(candidates.len <= 0)
			break
		var/mob/M = pick(candidates)
		assigned += M
		candidates -= M
		M.mind.restricted_roles = restricted_roles
		M.mind.special_role = antag_flag
		var/datum/antagonist/rev/head/new_head = new antag_datum()
		new_head.give_flash = TRUE
		new_head.give_hud = TRUE
		new_head.remove_clumsy = TRUE
		M.mind.add_antag_datum(new_head,revolution)

	revolution.update_objectives()
	revolution.update_heads()
	SSshuttle.registerHostileEnvironment(src)

	return TRUE
	
/datum/dynamic_ruleset/roundstart/delayed/revs/rule_process()
	if(check_rev_victory())
		finished = 1
	else if(check_heads_victory())
		finished = 2
	return

/datum/dynamic_ruleset/roundstart/delayed/revs/check_finished()
	if(CONFIG_GET(keyed_list/continuous)["revolution"])
		if(finished)
			SSshuttle.clearHostileEnvironment(src)
		return ..()
	if(finished != 0)
		return TRUE
	else
		return ..()

/datum/dynamic_ruleset/roundstart/delayed/revs/proc/check_rev_victory()
	for(var/datum/objective/mutiny/objective in revolution.objectives)
		if(!(objective.check_completion()))
			return FALSE
	return TRUE

/datum/dynamic_ruleset/roundstart/delayed/revs/proc/check_heads_victory()
	for(var/datum/mind/rev_mind in revolution.head_revolutionaries())
		var/turf/T = get_turf(rev_mind.current)
		if(!considered_afk(rev_mind) && considered_alive(rev_mind) && is_station_level(T.z))
			if(ishuman(rev_mind.current) || ismonkey(rev_mind.current))
				return FALSE
	return TRUE

/datum/dynamic_ruleset/roundstart/delayed/revs/round_result()
	if(finished == 1)
		SSticker.mode_result = "win - heads killed"
		SSticker.news_report = REVS_WIN
	else if(finished == 2)
		SSticker.mode_result = "loss - rev heads killed"
		SSticker.news_report = REVS_LOSE

//////////////////////////////////////////////
//                                          //
//               HIVEMIND                   //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/hivemind
	name = "Hivemind"
	antag_flag = ROLE_HIVE
	antag_datum = /datum/antagonist/hivemind
	restricted_roles = list("Cyborg", "AI", "Security Officer", "Warden", "Detective", "Head of Security", "Captain")
	required_candidates = 3
	weight = 3
	cost = 30
	requirements = list(101,101,70,40,30,20,10,10,10,10)
	high_population_requirement = 50

/datum/dynamic_ruleset/roundstart/hivemind/pre_execute()
	var/num_hosts = max( 1 , rand(0,1) + min(8, round(num_players() / 8) ) )
	for(var/i = 1 to num_hosts)
		var/mob/M = pick(candidates)
		assigned += M
		candidates -= M
		M.mind.special_role = ROLE_HIVE
		M.mind.restricted_roles = restricted_roles
		log_game("[key_name(M)] has been selected as a hivemind host")
	return TRUE

// Admin only rulesets. The threat requirement is 101 so it is not possible to roll them.

//////////////////////////////////////////////
//                                          //
//               EXTENDED                   //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/extended
	name = "Extended"
	antag_flag = null
	antag_datum = null
	restricted_roles = list()
	required_candidates = 0
	weight = 3
	cost = 0
	requirements = list(101,101,101,101,101,101,101,101,101,101)
	high_population_requirement = 101

/datum/dynamic_ruleset/roundstart/extended/pre_execute()
	message_admins("Starting a round of extended.")
	log_admin("Starting a round of extended.")
	mode.spend_threat(mode.threat)
	return TRUE

//////////////////////////////////////////////
//                                          //
//               CLOCKCULT                  //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/clockcult
	name = "Clockcult"
	antag_flag = ROLE_SERVANT_OF_RATVAR
	antag_datum = /datum/antagonist/clockcult
	restricted_roles = list("AI", "Cyborg", "Security Officer", "Warden", "Detective", "Head of Security", "Captain", "Chaplain", "Head of Personnel")
	required_candidates = 4
	weight = 3
	cost = 0
	requirements = list(101,101,101,101,101,101,101,101,101,101)
	high_population_requirement = 101
	flags = HIGHLANDER_RULESET
	var/ark_time

/datum/dynamic_ruleset/roundstart/clockcult/pre_execute()
	var/list/errorList = list()
	var/list/reebes = SSmapping.LoadGroup(errorList, "Reebe", "map_files/generic", "City_of_Cogs.dmm", default_traits = ZTRAITS_REEBE, silent = TRUE)
	if(errorList.len)
		message_admins("Reebe failed to load!")
		log_game("Reebe failed to load!")
		return FALSE
	for(var/datum/parsed_map/PM in reebes)
		PM.initTemplateBounds()

	var/starter_servants = 4
	var/number_players = num_players()
	if(number_players > 30)
		number_players -= 30
		starter_servants += round(number_players / 10)
	starter_servants = min(starter_servants, 8)
	for (var/i in 1 to starter_servants)
		var/mob/servant = pick(candidates)
		assigned += servant
		candidates -= servant
		servant.mind.assigned_role = ROLE_SERVANT_OF_RATVAR
		servant.mind.special_role = ROLE_SERVANT_OF_RATVAR
	ark_time = 30 + round((number_players / 5))
	ark_time = min(ark_time, 35)
	return TRUE

/datum/dynamic_ruleset/roundstart/clockcult/execute()
	var/list/spread_out_spawns = GLOB.servant_spawns.Copy()
	for(var/mob/S in assigned)
		if(!spread_out_spawns.len)
			spread_out_spawns = GLOB.servant_spawns.Copy()
		var/datum/mind/servant = S.mind
		log_game("[key_name(servant)] was made an initial servant of Ratvar")
		var/turf/T = pick_n_take(spread_out_spawns)
		S.forceMove(T)
		greet_servant(S)
		equip_servant(S)
		add_servant_of_ratvar(S, TRUE)
	var/obj/structure/destructible/clockwork/massive/celestial_gateway/G = GLOB.ark_of_the_clockwork_justiciar //that's a mouthful
	G.final_countdown(ark_time)
	return TRUE

/datum/dynamic_ruleset/roundstart/clockcult/proc/greet_servant(mob/M) //Description of their role
	if(!M)
		return 0
	to_chat(M, "<span class='bold large_brass'>You are a servant of Ratvar, the Clockwork Justiciar!</span>")
	to_chat(M, "<span class='brass'>You have approximately <b>[ark_time]</b> minutes until the Ark activates.</span>")
	to_chat(M, "<span class='brass'>Unlock <b>Script</b> scripture by converting a new servant.</span>")
	to_chat(M, "<span class='brass'><b>Application</b> scripture will be unlocked halfway until the Ark's activation.</span>")
	M.playsound_local(get_turf(M), 'sound/ambience/antag/clockcultalr.ogg', 100, FALSE, pressure_affected = FALSE)
	return 1

/datum/dynamic_ruleset/roundstart/clockcult/proc/equip_servant(mob/living/M) //Grants a clockwork slab to the mob, with one of each component
	if(!M || !ishuman(M))
		return FALSE
	var/mob/living/carbon/human/L = M
	L.equipOutfit(/datum/outfit/servant_of_ratvar)
	var/obj/item/clockwork/slab/S = new
	var/slot = "At your feet"
	var/list/slots = list("In your left pocket" = SLOT_L_STORE, "In your right pocket" = SLOT_R_STORE, "In your backpack" = SLOT_IN_BACKPACK, "On your belt" = SLOT_BELT)
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		slot = H.equip_in_one_of_slots(S, slots)
		if(slot == "In your backpack")
			slot = "In your [H.back.name]"
	if(slot == "At your feet")
		if(!S.forceMove(get_turf(L)))
			qdel(S)
	if(S && !QDELETED(S))
		to_chat(L, "<span class='bold large_brass'>There is a paper in your backpack! It'll tell you if anything's changed, as well as what to expect.</span>")
		to_chat(L, "<span class='alloy'>[slot] is a <b>clockwork slab</b>, a multipurpose tool used to construct machines and invoke ancient words of power. If this is your first time \
		as a servant, you can find a concise tutorial in the Recollection category of its interface.</span>")
		to_chat(L, "<span class='alloy italics'>If you want more information, you can read <a href=\"https://tgstation13.org/wiki/Clockwork_Cult\">the wiki page</a> to learn more.</span>")
		return TRUE
	return FALSE

/datum/dynamic_ruleset/roundstart/clockcult/round_result()
	if(GLOB.clockwork_gateway_activated)
		SSticker.news_report = CLOCK_SUMMON
		SSticker.mode_result = "win - servants completed their objective (summon ratvar)"
	else
		SSticker.news_report = CULT_FAILURE
		SSticker.mode_result = "loss - servants failed their objective (summon ratvar)"

//////////////////////////////////////////////
//                                          //
//               OVERTHROW                  //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/overthrow
	name = "Overthrow"
	antag_flag = ROLE_OVERTHROW
	antag_datum = /datum/antagonist/overthrow
	restricted_roles = list("Security Officer", "Warden", "Detective", "AI", "Cyborg","Captain", "Head of Personnel", "Head of Security", "Chief Engineer", "Research Director", "Chief Medical Officer")
	required_candidates = 2
	weight = 3
	cost = 0
	requirements = list(101,101,101,101,101,101,101,101,101,101)
	high_population_requirement = 101
	flags = HIGHLANDER_RULESET	
	var/agent_count = list(4,4,3,3,3,2,2,1,1,0)

/datum/dynamic_ruleset/roundstart/overthrow/pre_execute()
	var/sleeping_agents = agent_count[round(mode.threat_level/10)] + round(num_players()*0.05)

	for (var/i in 1 to sleeping_agents)
		var/mob/sleeping_agent = pick(candidates)
		candidates -= sleeping_agent
		assigned += sleeping_agent
		sleeping_agent.mind.restricted_roles = restricted_roles
		sleeping_agent.mind.special_role = ROLE_OVERTHROW

/datum/dynamic_ruleset/roundstart/overthrow/execute()
	for(var/i in assigned)
		var/mob/agent = i
		var/datum/antagonist/overthrow/O = agent.mind.add_antag_datum(antag_datum)
		O.equip_initial_overthrow_agent()
	return TRUE

//////////////////////////////////////////////
//                                          //
//               CLOWN OPS                  //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/nuclear/clown_ops
	name = "Clown Ops"
	antag_datum = /datum/antagonist/nukeop/clownop
	antag_leader_datum = /datum/antagonist/nukeop/leader/clownop
	requirements = list(101,101,101,101,101,101,101,101,101,101)
	high_population_requirement = 101

/datum/dynamic_ruleset/roundstart/nuclear/clown_ops/pre_execute()
	. = ..()
	if(.)
		for(var/obj/machinery/nuclearbomb/syndicate/S in GLOB.nuke_list)
			var/turf/T = get_turf(S)
			if(T)
				qdel(S)
				new /obj/machinery/nuclearbomb/syndicate/bananium(T)
		for(var/V in assigned)
			var/mob/the_op = V
			the_op.mind.assigned_role = "Clown Operative"
			the_op.mind.special_role = "Clown Operative"

//////////////////////////////////////////////
//                                          //
//               DEVIL                      //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/devil
	name = "Devil"
	antag_flag = ROLE_DEVIL
	antag_datum = /datum/antagonist/devil
	restricted_roles = list("Lawyer", "Curator", "Chaplain", "Head of Security", "Captain", "AI")
	required_candidates = 1
	weight = 3
	cost = 0
	requirements = list(101,101,101,101,101,101,101,101,101,101)
	high_population_requirement = 101
	var/devil_limit = 4 // Hard limit on devils if scaling is turned off

/datum/dynamic_ruleset/roundstart/devil/pre_execute()	
	var/tsc = CONFIG_GET(number/traitor_scaling_coeff)
	var/num_devils = 1

	if(tsc)
		num_devils = max(required_candidates, min(round(num_players() / (tsc * 3)) + 2, round(num_players() / (tsc * 1.5))))
	else
		num_devils = max(required_candidates, min(num_players(), devil_limit))

	for(var/j = 0, j < num_devils, j++)
		if (!candidates.len)
			break
		var/mob/devil = pick(candidates)
		assigned += devil
		candidates -= devil
		devil.mind.special_role = ROLE_DEVIL
		devil.mind.restricted_roles = restricted_roles

		log_game("[key_name(devil)] has been selected as a devil")
	return TRUE

/datum/dynamic_ruleset/roundstart/devil/execute()
	for(var/mob/devil in assigned)
		add_devil(devil, ascendable = TRUE)
		add_devil_objectives(devil.mind,2)
	return TRUE

/datum/dynamic_ruleset/roundstart/devil/proc/add_devil_objectives(datum/mind/devil_mind, quantity)
	var/list/validtypes = list(/datum/objective/devil/soulquantity, /datum/objective/devil/soulquality, /datum/objective/devil/sintouch, /datum/objective/devil/buy_target)
	var/datum/antagonist/devil/D = devil_mind.has_antag_datum(/datum/antagonist/devil)
	for(var/i = 1 to quantity)
		var/type = pick(validtypes)
		var/datum/objective/devil/objective = new type(null)
		objective.owner = devil_mind
		D.objectives += objective
		if(!istype(objective, /datum/objective/devil/buy_target))
			validtypes -= type
		else
			objective.find_target()

//////////////////////////////////////////////
//                                          //
//               MONKEY                     //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/monkey
	name = "Monkey"
	antag_flag = ROLE_MONKEY
	antag_datum = /datum/antagonist/monkey/leader
	restricted_roles = list("Cyborg", "AI")
	required_candidates = 1
	weight = 3
	cost = 0
	requirements = list(101,101,101,101,101,101,101,101,101,101)
	high_population_requirement = 101
	var/players_per_carrier = 30
	var/monkeys_to_win = 1
	var/escaped_monkeys = 0
	var/datum/team/monkey/monkey_team

/datum/dynamic_ruleset/roundstart/monkey/pre_execute()
	var/carriers_to_make = max(round(num_players()/players_per_carrier, 1), 1)

	for(var/j = 0, j < carriers_to_make, j++)
		if (!candidates.len)
			break
		var/mob/carrier = pick(candidates)
		assigned += carrier
		candidates -= carrier
		carrier.mind.special_role = "Monkey Leader"
		carrier.mind.restricted_roles = restricted_roles
		log_game("[key_name(carrier)] has been selected as a Jungle Fever carrier")
	return TRUE

/datum/dynamic_ruleset/roundstart/monkey/execute()
	for(var/mob/carrier in assigned)
		var/datum/antagonist/monkey/M = add_monkey_leader(carrier.mind)
		if(M)
			monkey_team = M.monkey_team
	return ..()

/datum/dynamic_ruleset/roundstart/monkey/proc/check_monkey_victory()
	if(SSshuttle.emergency.mode != SHUTTLE_ENDGAME)
		return FALSE
	var/datum/disease/D = new /datum/disease/transformation/jungle_fever()
	for(var/mob/living/carbon/monkey/M in GLOB.alive_mob_list)
		if (M.HasDisease(D))
			if(M.onCentCom() || M.onSyndieBase())
				escaped_monkeys++
	if(escaped_monkeys >= monkeys_to_win)
		return TRUE
	else
		return FALSE

/datum/dynamic_ruleset/roundstart/monkey/round_result()
	if(check_monkey_victory())
		SSticker.mode_result = "win - monkey win"
	else
		SSticker.mode_result = "loss - staff stopped the monkeys"

//////////////////////////////////////////////
//                                          //
//               METEOR                     //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/roundstart/meteor
	name = "Meteor"
	persistent = TRUE
	required_candidates = 0
	weight = 3
	cost = 0
	requirements = list(101,101,101,101,101,101,101,101,101,101)
	high_population_requirement = 101
	var/meteordelay = 1000
	var/nometeors = 0
	var/rampupdelta = 5

/datum/dynamic_ruleset/roundstart/meteor/rule_process()
	if(nometeors || meteordelay > world.time - SSticker.round_start_time)
		return

	var/list/wavetype = GLOB.meteors_normal
	var/meteorminutes = (world.time - SSticker.round_start_time - meteordelay) / 10 / 60

	if (prob(meteorminutes))
		wavetype = GLOB.meteors_threatening

	if (prob(meteorminutes/2))
		wavetype = GLOB.meteors_catastrophic

	var/ramp_up_final = CLAMP(round(meteorminutes/rampupdelta), 1, 10)

	spawn_meteors(ramp_up_final, wavetype)
