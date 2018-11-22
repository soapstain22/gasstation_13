//Cold Resistance gives your entire body an orange halo, and makes you immune to the effects of vacuum and cold.
/datum/mutation/human/space_adaptation
	name = "Space Adaptation"
	desc = "A strange mutation that renders the host immune to the vacuum if space. Will still need an oxygen supply."
	quality = POSITIVE
	difficulty = 16
	text_gain_indication = "<span class='notice'>Your body feels warm!</span>"
	time_coeff = 5
	instability = 30

/datum/mutation/human/space_adaptation/New()
	..()
	if(!LAZYLEN(visual_indicators))
		visual_indicators |= mutable_appearance('icons/effects/genetics.dmi', "fire", -MUTATIONS_LAYER)

/datum/mutation/human/space_adaptation/get_visual_indicator()
	return visual_indicators[1]

/datum/mutation/human/space_adaptation/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return
	owner.add_trait(TRAIT_RESISTCOLD, "space_adaptation")
	owner.add_trait(TRAIT_RESISTLOWPRESSURE, "space_adaptation")

/datum/mutation/human/space_adaptation/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	owner.remove_trait(TRAIT_RESISTCOLD, "space_adaptation")
	owner.remove_trait(TRAIT_RESISTLOWPRESSURE, "space_adaptation")

