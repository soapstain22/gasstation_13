//How often to check for promotion possibility
#define HEAD_UPDATE_PERIOD 300

/datum/antagonist/rev
	name = "Revolutionary"
	roundend_category = "revolutionaries" // if by some miracle revolutionaries without revolution happen
	panel_category = "revolution"
	job_rank = ROLE_REV
	var/hud_type = "rev"
	var/datum/team/revolution/rev_team

/datum/antagonist/rev/can_be_owned(datum/mind/new_owner)
	. = ..()
	if(new_owner.assigned_role in GLOB.command_positions)
		return FALSE
	if(new_owner.unconvertable)
		return FALSE

/datum/antagonist/rev/apply_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	update_rev_icons_added(M)

/datum/antagonist/rev/remove_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	update_rev_icons_removed(M)

/datum/antagonist/rev/proc/equip_rev()
	return

/datum/antagonist/rev/New()
	. = ..()

/datum/antagonist/rev/on_gain()
	. = ..()
	create_objectives()
	equip_rev()
	owner.current.log_message("<font color='red'>Has been converted to the revolution!</font>", INDIVIDUAL_ATTACK_LOG)

/datum/antagonist/rev/on_removal()
	remove_objectives()
	. = ..()

/datum/antagonist/rev/greet()
	to_chat(owner, "<span class='userdanger'>You are now a revolutionary! Help your cause. Do not harm your fellow freedom fighters. You can identify your comrades by the red \"R\" icons, and your leaders by the blue \"R\" icons. Help them kill the heads to win the revolution!</span>")
	owner.announce_objectives()

/datum/antagonist/rev/create_team(datum/team/revolution/new_team)
	if(!new_team)
		//For now only one revolution at a time
		for(var/datum/antagonist/rev/head/H in GLOB.antagonists)
			if(H.rev_team)
				rev_team = H.rev_team
				return
		rev_team = new /datum/team/revolution
		rev_team.update_objectives()
		rev_team.update_heads()
		return
	if(!istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	rev_team = new_team

/datum/antagonist/rev/get_team()
	return rev_team

/datum/antagonist/rev/proc/create_objectives()
	owner.objectives |= rev_team.objectives

/datum/antagonist/rev/proc/remove_objectives()
	owner.objectives -= rev_team.objectives

//Bump up to head_rev
/datum/antagonist/rev/proc/promote()
	var/old_team = rev_team
	var/datum/mind/old_owner = owner
	silent = TRUE
	owner.remove_antag_datum(/datum/antagonist/rev)
	var/datum/antagonist/rev/head/new_revhead = new(old_owner)
	new_revhead.silent = TRUE
	old_owner.add_antag_datum(new_revhead,old_team)
	new_revhead.silent = FALSE
	to_chat(old_owner, "<span class='userdanger'>You have proved your devotion to revolution! You are a head revolutionary now!</span>")


/datum/antagonist/rev/head
	name = "Head Revolutionary"
	hud_type = "rev_head"
	var/remove_clumsy = FALSE
	var/give_flash = FALSE
	var/give_hud = TRUE

/datum/antagonist/rev/proc/update_rev_icons_added(mob/living/M)
	var/datum/atom_hud/antag/revhud = GLOB.huds[ANTAG_HUD_REV]
	revhud.join_hud(M)
	set_antag_hud(M,hud_type)

/datum/antagonist/rev/proc/update_rev_icons_removed(mob/living/M)
	var/datum/atom_hud/antag/revhud = GLOB.huds[ANTAG_HUD_REV]
	revhud.leave_hud(M)
	set_antag_hud(M, null)

/datum/antagonist/rev/proc/can_be_converted(mob/living/candidate)
	if(!candidate.mind)
		return FALSE
	if(!can_be_owned(candidate.mind))
		return FALSE
	var/mob/living/carbon/C = candidate //Check to see if the potential rev is implanted
	if(!istype(C)) //Can't convert simple animals
		return FALSE
	if(C.isloyal())
		return FALSE
	return TRUE

/datum/antagonist/rev/proc/add_revolutionary(datum/mind/rev_mind,stun = TRUE)
	if(!can_be_converted(rev_mind.current))
		return FALSE
	if(stun)
		if(iscarbon(rev_mind.current))
			var/mob/living/carbon/carbon_mob = rev_mind.current
			carbon_mob.silent = max(carbon_mob.silent, 5)
			carbon_mob.flash_act(1, 1)
		rev_mind.current.Stun(100)
	rev_mind.add_antag_datum(/datum/antagonist/rev,rev_team)
	rev_mind.special_role = "Revolutionary"
	return TRUE

/datum/antagonist/rev/head/proc/demote()
	var/datum/mind/old_owner = owner
	var/old_team = rev_team
	silent = TRUE
	owner.remove_antag_datum(/datum/antagonist/rev/head)
	var/datum/antagonist/rev/new_rev = new /datum/antagonist/rev(old_owner)
	new_rev.silent = TRUE
	old_owner.add_antag_datum(new_rev,old_team)
	new_rev.silent = FALSE
	to_chat(old_owner, "<span class='userdanger'>Revolution has been disappointed of your leader traits! You are a regular revolutionary now!</span>")

/datum/antagonist/rev/farewell()
	if(ishuman(owner.current))
		owner.current.visible_message("<span class='deconversion_message'>[owner.current] looks like they just remembered their real allegiance!</span>", ignored_mob = owner.current)
		to_chat(owner, "<span class='userdanger'>You are no longer a brainwashed revolutionary! Your memory is hazy from the time you were a rebel...the only thing you remember is the name of the one who brainwashed you...</span>")
	else if(issilicon(owner.current))
		owner.current.visible_message("<span class='deconversion_message'>The frame beeps contentedly, purging the hostile memory engram from the MMI before initalizing it.</span>", ignored_mob = owner.current)
		to_chat(owner, "<span class='userdanger'>The frame's firmware detects and deletes your neural reprogramming! You remember nothing but the name of the one who flashed you.</span>")

/datum/antagonist/rev/proc/remove_revolutionary(borged, deconverter)
	log_attack("[owner.current] (Key: [key_name(owner.current)]) has been deconverted from the revolution by [deconverter] (Key: [key_name(deconverter)])!")
	if(borged)
		message_admins("[ADMIN_LOOKUPFLW(owner.current)] has been borged while being a [name]")
	owner.special_role = null
	if(iscarbon(owner.current))
		var/mob/living/carbon/C = owner.current
		C.Unconscious(100)
	owner.remove_antag_datum(type)

/datum/antagonist/rev/head/remove_revolutionary(borged,deconverter)
	if(!borged)
		return
	. = ..()

/datum/antagonist/rev/head/equip_rev()
	var/mob/living/carbon/human/H = owner.current
	if(!istype(H))
		return

	if(remove_clumsy && owner.assigned_role == "Clown")
		to_chat(owner, "Your training has allowed you to overcome your clownish nature, allowing you to wield weapons without harming yourself.")
		H.dna.remove_mutation(CLOWNMUT)

	if(give_flash)
		var/obj/item/device/assembly/flash/T = new(H)
		var/list/slots = list (
			"backpack" = slot_in_backpack,
			"left pocket" = slot_l_store,
			"right pocket" = slot_r_store
		)
		var/where = H.equip_in_one_of_slots(T, slots)
		if (!where)
			to_chat(H, "The Syndicate were unfortunately unable to get you a flash.")
		else
			to_chat(H, "The flash in your [where] will help you to persuade the crew to join your cause.")

	if(give_hud)
		var/obj/item/organ/cyberimp/eyes/hud/security/syndicate/S = new(H)
		S.Insert(H, special = FALSE, drop_if_replaced = FALSE)
		to_chat(H, "Your eyes have been implanted with a cybernetic security HUD which will help you keep track of who is mindshield-implanted, and therefore unable to be recruited.")

/datum/team/revolution
	name = "Revolution"
	var/max_headrevs = 3

/datum/team/revolution/proc/update_objectives(initial = FALSE)
	var/untracked_heads = SSjob.get_all_heads()
	for(var/datum/objective/mutiny/O in objectives)
		untracked_heads -= O.target
	for(var/datum/mind/M in untracked_heads)
		var/datum/objective/mutiny/new_target = new()
		new_target.team = src
		new_target.target = M
		new_target.update_explanation_text()
		objectives += new_target
	for(var/datum/mind/M in members)
		M.objectives |= objectives

	addtimer(CALLBACK(src,.proc/update_objectives),HEAD_UPDATE_PERIOD,TIMER_UNIQUE)

/datum/team/revolution/proc/head_revolutionaries()
	. = list()
	for(var/datum/mind/M in members)
		if(M.has_antag_datum(/datum/antagonist/rev/head))
			. += M

/datum/team/revolution/proc/update_heads()
	if(SSticker.HasRoundStarted())
		var/list/datum/mind/head_revolutionaries = head_revolutionaries()
		var/list/datum/mind/heads = SSjob.get_all_heads()
		var/list/sec = SSjob.get_all_sec()

		if(head_revolutionaries.len < max_headrevs && head_revolutionaries.len < round(heads.len - ((8 - sec.len) / 3)))
			var/list/datum/mind/non_heads = members - head_revolutionaries
			var/list/datum/mind/promotable = list()
			for(var/datum/mind/khrushchev in non_heads)
				if(khrushchev.current && !khrushchev.current.incapacitated() && !khrushchev.current.restrained() && khrushchev.current.client && khrushchev.current.stat != DEAD)
					if(ROLE_REV in khrushchev.current.client.prefs.be_special)
						promotable += khrushchev
			if(promotable.len)
				var/datum/mind/new_leader = pick(promotable)
				var/datum/antagonist/rev/rev = new_leader.has_antag_datum(/datum/antagonist/rev)
				rev.promote()

	addtimer(CALLBACK(src,.proc/update_heads),HEAD_UPDATE_PERIOD,TIMER_UNIQUE)


/datum/team/revolution/roundend_report()
	if(!members.len)
		return

	var/list/result = list()

	result += "<div class='panel redborder'>"

	var/num_revs = 0
	var/num_survivors = 0
	for(var/mob/living/carbon/survivor in GLOB.alive_mob_list)
		if(survivor.ckey)
			num_survivors++
			if(survivor.mind)
				if(is_revolutionary(survivor))
					num_revs++
	if(num_survivors)
		result += "Command's Approval Rating: <B>[100 - round((num_revs/num_survivors)*100, 0.1)]%</B><br>"


	var/list/targets = list()
	var/list/datum/mind/headrevs = get_antagonists(/datum/antagonist/rev/head)
	var/list/datum/mind/revs = get_antagonists(/datum/antagonist/rev,TRUE)
	if(headrevs.len)
		var/list/headrev_part = list()
		headrev_part += "<span class='header'>The head revolutionaries were:</span>"
		headrev_part += printplayerlist(headrevs,TRUE)
		result += headrev_part.Join("<br>")

	if(revs.len)
		var/list/rev_part = list()
		rev_part += "<span class='header'>The revolutionaries were:</span>"
		rev_part += printplayerlist(revs,TRUE)
		result += rev_part.Join("<br>")

	var/list/heads = SSjob.get_all_heads()
	if(heads.len)
		var/head_text = "<span class='header'>The heads of staff were:</span>"
		head_text += "<ul class='playerlist'>"
		for(var/datum/mind/head in heads)
			var/target = (head in targets)
			head_text += "<li>"
			if(target)
				head_text += "<span class='redtext'>Target</span>"
			head_text += "[printplayer(head, 1)]</li>"
		head_text += "</ul><br>"
		result += head_text

	result += "</div>"

	return result.Join()

/datum/antagonist/rev/antag_panel_section(datum/mind/mind, mob/current)
	if(!iscarbon(current))
		return FALSE
	var/text = "revolution"
	if(SSticker.mode.config_tag == "revolution")
		text = uppertext(text)
	text = "<i><b>[text]</b></i>: "
	if (mind.assigned_role in GLOB.command_positions)
		text += "<b>HEAD</b> | not mindshielded | employee | headrev | rev"
	else if (mind.has_antag_datum(/datum/antagonist/rev/head))
		var/datum/antagonist/rev/head = mind.has_antag_datum(/datum/antagonist/rev/head)
		var/last_healthy_headrev = TRUE
		for(var/datum/mind/I in head.rev_team.head_revolutionaries())
			if(I == src)
				continue
			var/mob/M = I.current
			if(M && (M.z in GLOB.station_z_levels) && !M.stat)
				last_healthy_headrev = FALSE
				break
		text += "head | not mindshielded | <a href='?src=[REF(mind)];revolution=clear'>employee</a> | <b>[last_healthy_headrev ? "<font color='red'>LAST </font> " : ""]HEADREV</b> | <a href='?src=[REF(mind)];revolution=rev'>rev</a>"
		text += "<br>Flash: <a href='?src=[REF(mind)];revolution=flash'>give</a>"

		var/list/L = current.get_contents()
		var/obj/item/device/assembly/flash/flash = locate() in L
		if (flash)
			if(!flash.crit_fail)
				text += " | <a href='?src=[REF(mind)];revolution=takeflash'>take</a>."
			else
				text += " | <a href='?src=[REF(mind)];revolution=takeflash'>take</a> | <a href='?src=[REF(mind)];revolution=repairflash'>repair</a>."
		else
			text += "."

		text += " <a href='?src=[REF(mind)];revolution=reequip'>Reequip</a> (gives traitor uplink)."
		if (mind.objectives.len==0)
			text += "<br>Objectives are empty! <a href='?src=[REF(mind)];revolution=autoobjectives'>Set to kill all heads</a>."
	else if(current.isloyal())
		text += "head | <b>MINDSHIELDED</b> | employee | <a href='?src=[REF(mind)];revolution=headrev'>headrev</a> | rev"
	else if (mind.has_antag_datum(/datum/antagonist/rev))
		text += "head | not mindshielded | <a href='?src=[REF(mind)];revolution=clear'>employee</a> | <a href='?src=[REF(mind)];revolution=headrev'>headrev</a> | <b>REV</b>"
	else
		text += "head | not mindshielded | <b>EMPLOYEE</b> | <a href='?src=[REF(mind)];revolution=headrev'>headrev</a> | <a href='?src=[REF(mind)];revolution=rev'>rev</a>"

	if(current && current.client && (ROLE_REV in current.client.prefs.be_special))
		text += " | Enabled in Prefs"
	else
		text += " | Disabled in Prefs"
	return text

/datum/antagonist/rev/antag_panel_href(href, datum/mind/mind, mob/current)
	switch(href)
		if("clear")
			mind.remove_rev()
			message_admins("[key_name_admin(usr)] has de-rev'ed [current].")
			log_admin("[key_name(usr)] has de-rev'ed [current].")
		if("rev")
			if(mind.has_antag_datum(/datum/antagonist/rev/head))
				var/datum/antagonist/rev/head/head = mind.has_antag_datum(/datum/antagonist/rev/head)
				head.demote()
			else if(!mind.has_antag_datum(/datum/antagonist/rev))
				mind.add_antag_datum(/datum/antagonist/rev)
				mind.special_role = "Revolutionary"
				message_admins("[key_name_admin(usr)] has rev'ed [current].")
				log_admin("[key_name(usr)] has rev'ed [current].")
			else
				return
		if("headrev")
			if(mind.has_antag_datum(/datum/antagonist/rev))
				var/datum/antagonist/rev/rev = mind.has_antag_datum(/datum/antagonist/rev)
				rev.promote()
			else if(!mind.has_antag_datum(/datum/antagonist/rev/head))
				//what about the team here.
				var/datum/antagonist/rev/head/new_head = new /datum/antagonist/rev/head(src)
				new_head.give_flash = TRUE
				new_head.give_hud = TRUE
				new_head.remove_clumsy = TRUE
				mind.add_antag_datum(new_head)
				to_chat(current, "<span class='userdanger'>You are a member of the revolutionaries' leadership now!</span>")
			else
				return
			mind.special_role = "Head Revolutionary"
			message_admins("[key_name_admin(usr)] has head-rev'ed [current].")
			log_admin("[key_name(usr)] has head-rev'ed [current].")
		if("flash")
			var/datum/antagonist/rev/head/head = mind.has_antag_datum(/datum/antagonist/rev/head)
			if(!head.equip_rev())
				to_chat(usr, "<span class='danger'>Spawning flash failed!</span>")
		if("takeflash")
			var/list/L = current.get_contents()
			var/obj/item/device/assembly/flash/flash = locate() in L
			if (!flash)
				to_chat(usr, "<span class='danger'>Deleting flash failed!</span>")
			qdel(flash)
		if("repairflash")
			var/list/L = current.get_contents()
			var/obj/item/device/assembly/flash/flash = locate() in L
			if (!flash)
				to_chat(usr, "<span class='danger'>Repairing flash failed!</span>")
			else
				flash.crit_fail = FALSE
				flash.update_icon()