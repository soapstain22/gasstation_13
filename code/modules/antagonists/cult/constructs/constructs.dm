/datum/antagonist/cult/construct
	name = "\improper Cult Construct"
	show_in_antagpanel = FALSE
	show_name_in_check_antagonists = TRUE
	show_to_ghosts = TRUE
	antagpanel_category = "Eldritch Horrors"

/mob/living/simple_animal/hostile/construct
	name = "Construct"
	real_name = "Construct"
	desc = ""
	gender = NEUTER
	mob_biotypes = NONE
	speak_emote = list("hisses")
	response_help_continuous = "thinks better of touching"
	response_help_simple = "think better of touching"
	response_disarm_continuous = "flails at"
	response_disarm_simple = "flail at"
	response_harm_continuous = "punches"
	response_harm_simple = "punch"
	speak_chance = 1
	icon = 'icons/mob/nonhuman-player/cult.dmi'
	speed = 0
	combat_mode = TRUE
	stop_automated_movement = 1
	status_flags = CANPUSH
	attack_sound = 'sound/weapons/punch1.ogg'
	see_in_dark = 7
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_plas" = 0, "max_plas" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = INFINITY
	healable = 0
	faction = list("cult")
	pressure_resistance = 100
	unique_name = 1
	AIStatus = AI_OFF //normal constructs don't have AI
	loot = list(/obj/item/ectoplasm)
	del_on_death = TRUE
	initial_language_holder = /datum/language_holder/construct
	death_message = "collapses in a shattered heap."
	var/list/construct_spells = list()
	var/playstyle_string = "<span class='big bold'>You are a generic construct!</span><b> Your job is to not exist, and you should probably adminhelp this.</b>"
	var/master = null
	var/seeking = FALSE
	/// Whether this construct can repair other constructs or cult buildings.
	var/can_repair = FALSE
	/// Whether this construct can repair itself. Works independently of can_repair.
	var/can_repair_self = FALSE
	/// Theme controls color. THEME_CULT is red THEME_WIZARD is purple and THEME_HOLY is blue
	var/theme = THEME_CULT

/mob/living/simple_animal/hostile/construct/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/simple_flying)
	ADD_TRAIT(src, TRAIT_HEALS_FROM_CULT_PYLONS, INNATE_TRAIT)
	ADD_TRAIT(src, TRAIT_SPACEWALK, INNATE_TRAIT)
	for(var/spell in construct_spells)
		var/datum/action/new_spell = new spell(src)
		new_spell.Grant(src)

	var/spellnum = 1
	for(var/datum/action/spell as anything in actions)
		if(!(spell.type in construct_spells))
			continue

		var/pos = 2 + spellnum * 31
		if(construct_spells.len >= 4)
			pos -= 31 * (construct_spells.len - 4)
		spell.default_button_position = "6:[pos],4:-2" // Set the default position to this random position
		spellnum++
		update_action_buttons()

	if(icon_state)
		add_overlay("glow_[icon_state]_[theme]")

/mob/living/simple_animal/hostile/construct/Login()
	. = ..()
	if(!. || !client)
		return FALSE
	to_chat(src, playstyle_string)

/mob/living/simple_animal/hostile/construct/examine(mob/user)
	var/t_He = p_they(TRUE)
	var/t_s = p_s()
	var/text_span
	switch(theme)
		if(THEME_CULT)
			text_span = "cult"
		if(THEME_WIZARD)
			text_span = "purple"
		if(THEME_HOLY)
			text_span = "blue"
	. = list("<span class='[text_span]'>This is [icon2html(src, user)] \a <b>[src]</b>!\n[desc]")
	if(health < maxHealth)
		if(health >= maxHealth/2)
			. += span_warning("[t_He] look[t_s] slightly dented.")
		else
			. += span_warning("<b>[t_He] look[t_s] severely dented!</b>")
	. += "</span>"

/mob/living/simple_animal/hostile/construct/attack_animal(mob/living/simple_animal/user, list/modifiers)
	if(isconstruct(user)) //is it a construct?
		var/mob/living/simple_animal/hostile/construct/doll = user
		if(!doll.can_repair || (doll == src && !doll.can_repair_self))
			return ..()
		if(theme != doll.theme)
			return ..()
		if(health < maxHealth)
			adjustHealth(-5)
			if(src != user)
				Beam(user, icon_state="sendbeam", time = 4)
				user.visible_message(span_danger("[user] repairs some of \the <b>[src]'s</b> dents."), \
						   span_cult("You repair some of <b>[src]'s</b> dents, leaving <b>[src]</b> at <b>[health]/[maxHealth]</b> health."))
			else
				user.visible_message(span_danger("[user] repairs some of [p_their()] own dents."), \
						   span_cult("You repair some of your own dents, leaving you at <b>[user.health]/[user.maxHealth]</b> health."))
		else
			if(src != user)
				to_chat(user, span_cult("You cannot repair <b>[src]'s</b> dents, as [p_they()] [p_have()] none!"))
			else
				to_chat(user, span_cult("You cannot repair your own dents, as you have none!"))
	else if(src != user)
		return ..()

/mob/living/simple_animal/hostile/construct/narsie_act()
	return

/mob/living/simple_animal/hostile/construct/electrocute_act(shock_damage, source, siemens_coeff = 1, flags = NONE)
	return 0

