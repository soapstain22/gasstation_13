/datum/action/cooldown/spell/vow_of_silence
	name = "Speech"
	desc = "Make (or break) a vow of silence."
	background_icon_state = "bg_mime"
	overlay_icon_state = "bg_mime_border"
	button_icon = 'icons/mob/actions/actions_mime.dmi'
	button_icon_state = "mime_speech"
	panel = "Mime"

	school = SCHOOL_MIME
	cooldown_time = 5 MINUTES

	spell_requirements = SPELL_REQUIRES_HUMAN
	spell_max_level = 1

/datum/action/cooldown/spell/vow_of_silence/Grant(mob/grant_to)
	. = ..()
	ADD_TRAIT(grant_to, TRAIT_MIMING, "[type]")

/datum/action/cooldown/spell/vow_of_silence/Remove(mob/living/remove_from)
	. = ..()
	REMOVE_TRAIT(remove_from, TRAIT_MIMING, "[type]")
	remove_from.clear_mood_event("vow")

/datum/action/cooldown/spell/vow_of_silence/cast(mob/living/carbon/human/cast_on)
	. = ..()
	if(HAS_TRAIT(grant_to, TRAIT_MIMING, "[type]"))
		to_chat(cast_on, span_notice("You break your vow of silence."))
		cast_on.add_mood_event("vow", /datum/mood_event/broken_vow)
	else
		to_chat(cast_on, span_notice("You make a vow of silence."))
		cast_on.clear_mood_event("vow")
	cast_on.update_mob_action_buttons()
