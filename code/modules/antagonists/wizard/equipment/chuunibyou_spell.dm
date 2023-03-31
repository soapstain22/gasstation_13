/datum/action/cooldown/spell/chuuni_invocations
	name = "Yuki Starlight's Chuuni Invocations"
	desc = "Gives you an extra spell point, but makes all your spells shout invocations, and the invocations become... stupid. You heal slightly after casting a spell."
	button_icon_state = "chuuni"

	school = SCHOOL_FORBIDDEN
	cooldown_time = 1 SECONDS

	invocation = "By the decree of the dark lord, I invoke the curse of the chuuni. Let all my spells be tainted by the power of delusion. O, Reality! Bend to my will!"
	invocation_type = INVOCATION_SHOUT
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC|SPELL_REQUIRES_STATION|SPELL_REQUIRES_MIND
	antimagic_flags = MAGIC_RESISTANCE|MAGIC_RESISTANCE_HOLY
	spell_max_level = 1

/datum/action/cooldown/spell/chuuni_invocations/cast(mob/living/cast_on)
	. = ..()

	to_chat(cast_on, span_green("You focus your arcane knowledge into a slice-of-life format..."))
	if(!do_after(cast_on, 5 SECONDS))
		to_chat(cast_on, span_warning("Your focus is broken, and the episodic rom-com moments slowly fade."))
		return

	playsound(loc, 'sound/effects/bamf.ogg', 75, TRUE, 5)
	to_chat(cast_on, span_danger("You feel your very essense binding to a slice-of-life format!"))

	cast_on.AddComponent(/datum/component/chuunibyou)

	if(ishuman(cast_on))
		var/mob/living/carbon/human/human_cast_on = cast_on
		human_cast_on.dropItemToGround(human_cast_on.glasses)
		human_cast_on.equip_to_slot_or_del(new /obj/item/clothing/glasses/eyepatch/medical/chuuni(human_cast_on), ITEM_SLOT_EYES)

	qdel(src)
