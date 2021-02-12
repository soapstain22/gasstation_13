//does brute damage through armor and bio resistance
/datum/blobstrain/reagent/reactive_spines
	name = "Reactive Spines"
	description = "will do high brute damage through armor and bio resistance."
	effectdesc = "will also react when attacked with burn or brute damage, attacking everything in melee range."
	analyzerdescdamage = "Does high brute damage, ignoring armor and bio resistance."
	analyzerdesceffect = "When attacked with burn or brute damage it violently lashes out, attacking everything nearby."
	color = "#9ACD32"
	complementary_color = "#FFA500"
	blobbernaut_message = "stabs"
	message = "The blob stabs you"
	reagent = /datum/reagent/blob/reactive_spines
	COOLDOWN_DECLARE(retaliate_cooldown)

/datum/blobstrain/reagent/reactive_spines/damage_reaction(obj/structure/blob/B, damage, damage_type, damage_flag)
	if(damage && ((damage_type == BRUTE) || (damage_type == BURN)) && B.obj_integrity - damage > 0 && COOLDOWN_FINISHED(src, retaliate_cooldown)) // Is there any damage, is it burn or brute, will we be alive, and has the cooldown finished?
		COOLDOWN_START(src, retaliate_cooldown, 2.5 SECONDS) // 2.5 seconds before auto-retaliate can whack everything within 1 tile again
		B.visible_message("<span class='boldwarning'>The blob retaliates, lashing out!</span>")
		for(var/atom/A in range(1, B))
			if(isliving(A) && !isblobmonster(A)) // Make sure to inject strain-reagents with automatic attacks when needed.
				attack_living(A)
			else
				A.blob_act(B)
	return ..()

/datum/reagent/blob/reactive_spines
	name = "Reactive Spines"
	taste_description = "rock"
	color = "#9ACD32"

/datum/reagent/blob/reactive_spines/return_mob_expose_reac_volume(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message, touch_protection, mob/camera/blob/overmind)
	if(exposed_mob.stat == DEAD || istype(exposed_mob, /mob/living/simple_animal/hostile/blob))
		return 0 //the dead, and blob mobs, don't cause reactions
	return reac_volume

/datum/reagent/blob/reactive_spines/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message, touch_protection, mob/camera/blob/overmind)
	. = ..()
	reac_volume = return_mob_expose_reac_volume(exposed_mob, methods, reac_volume, show_message, touch_protection, overmind)
	exposed_mob.adjustBruteLoss(reac_volume)
