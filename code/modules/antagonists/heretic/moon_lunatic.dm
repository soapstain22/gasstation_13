// A type of antagonist created by the moon ascension
/datum/antagonist/lunatic
	name = "\improper Lunatic"
	hijack_speed = 0
	antagpanel_category = ANTAG_GROUP_HORRORS
	show_in_antagpanel = FALSE
	suicide_cry = "PRAISE THE RINGLEADER!!"
	antag_moodlet = /datum/mood_event/heretics/lunatic
	can_assign_self_objectives = FALSE
	hardcore_random_bonus = FALSE
	// The mind of the ascended heretic who created us
	var/datum/mind/ascended_heretic
	// The body of the ascended heretic who created us
	var/mob/living/carbon/human/ascended_body


/// Runs when the moon heretic creates us, used to give the lunatic a master
/datum/antagonist/lunatic/proc/set_master(datum/mind/heretic_master, mob/living/carbon/human/heretic_body)
	src.ascended_heretic = heretic_master
	src.ascended_body = heretic_body

	var/datum/objective/master_obj = new()
	master_obj.explanation_text = "Assist your master [heretic_master]."

	to_chat(owner, span_boldnotice("Ruin the lie, save the truth through obeying [heretic_master] the ringleader!"))


/datum/antagonist/lunatic/on_gain()
	owner.current.playsound_local(get_turf(owner.current), 'sound/effects/moon_parade.ogg', 100, FALSE, pressure_affected = FALSE, use_reverb = FALSE)//subject to change

	var/datum/action/cooldown/track_target/lunatic/moon_track = new/datum/action/cooldown/track_target/lunatic()
	var/datum/action/cooldown/spell/touch/mansus_grasp/mansus_grasp = new/datum/action/cooldown/spell/touch/mansus_grasp()

	mansus_grasp.Grant(owner)
	moon_track.Grant(owner)
	return ..()


/datum/antagonist/lunatic/apply_innate_effects(mob/living/mob_override)
	var/mob/living/our_mob = mob_override || owner.current
	handle_clown_mutation(our_mob, "Ancient knowledge described to you has allowed you to overcome your clownish nature, allowing you to wield weapons without harming yourself.")
	our_mob.faction |= FACTION_HERETIC

/datum/antagonist/lunatic/remove_innate_effects(mob/living/mob_override)
	var/mob/living/our_mob = mob_override || owner.current
	handle_clown_mutation(our_mob, removing = FALSE)
	our_mob.faction -= FACTION_HERETIC

// Mood event given to moon acolytes
/datum/mood_event/heretics/lunatic
	description = "THE TRUTH REVEALED, THE LIE SLAIN."
	mood_change = 10

