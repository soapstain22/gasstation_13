/datum/surgery/embedded_removal
	name = "removal of embedded objects"
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/clamp_bleeders, /datum/surgery_step/retract_skin, /datum/surgery_step/remove_object)
	possible_locs = list("r_arm","l_arm","r_leg","l_leg","chest","head")


/datum/surgery_step/remove_object
	name = "remove embedded objects"
	time = 32
	accept_hand = 1
	var/obj/item/bodypart/L = null


/datum/surgery_step/remove_object/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	L = surgery.operated_bodypart
	if(L)
		user.visible_message("[user] looks for objects embedded in [target]'s [parse_zone(user.zone_selected)].", "<span class='notice'>You look for objects embedded in [target]'s [parse_zone(user.zone_selected)]...</span>")
	else
		user.visible_message("[user] looks for [target]'s [parse_zone(user.zone_selected)].", "<span class='notice'>You look for [target]'s [parse_zone(user.zone_selected)]...</span>")


/datum/surgery_step/remove_object/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(L)
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			var/objects = 0
			for(var/obj/item/I in L.embedded_objects)
				objects++
				I.loc = get_turf(H)
				L.embedded_objects -= I

			//Handle possessive brain borers.
			if(H.has_brain_worms() && target_zone == "head")//remove worms outside the loop
				var/mob/living/simple_animal/borer/worm = H.has_brain_worms()
				if(worm.controlling)
					target.release_control()
				worm.detatch()
				worm.leave_victim()
				user.visible_message("A slug-like creature wriggles out of [H]'s [target_zone]!")

			if(objects > 0)
				user.visible_message("[user] sucessfully removes [objects] objects from [H]'s [L]!", "<span class='notice'>You successfully remove [objects] objects from [H]'s [L.name].</span>")
			else
				user << "<span class='warning'>You find no objects embedded in [H]'s [L]!</span>"

	else
		user << "<span class='warning'>You can't find [target]'s [parse_zone(user.zone_selected)], let alone any objects embedded in it!</span>"

	return 1