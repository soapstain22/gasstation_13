/// Belt which can turn you into a beast, once an anomaly core is inserted
/obj/item/polymorph_belt
	name = "polymorphic field inverter"
	desc = "This device can scan and store DNA from other life forms."
	slot_flags = ITEM_SLOT_BELT
	icon = 'icons/obj/clothing/belts.dmi'
	icon_state = "utility"
	inhand_icon_state = "utility"
	worn_icon_state = "utility"
	item_flags = NOBLUDGEON
	/// Typepath of a mob we have scanned, we only store one at a time
	var/stored_mob_type
	/// Have we activated the belt?
	var/active = FALSE
	/// Our current transformation action
	var/datum/action/cooldown/spell/shapeshift/polymorph_belt/transform_action

/obj/item/polymorph_belt/Destroy(force)
	QDEL_NULL(transform_action)
	return ..()

/obj/item/polymorph_belt/examine(mob/user)
	. = ..()
	if (stored_mob_type)
		var/mob/living/will_become = stored_mob_type
		. += span_notice("It contains digitised [initial(will_become.name)] DNA.")
	if (!active)
		. += span_warning("It requires a Bioscrambler Anomaly Core in order to function.")

/obj/item/polymorph_belt/item_action_slot_check(slot, mob/user, datum/action/action)
	return slot & ITEM_SLOT_BELT

/obj/item/polymorph_belt/attackby(obj/item/weapon, mob/user, params)
	if (!istype(weapon, /obj/item/assembly/signaler/anomaly/bioscrambler))
		return ..()
	balloon_alert(user, "inserting...")
	if (!do_after(user, delay = 3 SECONDS, target = src))
		return
	qdel(weapon)
	active = TRUE
	update_transform_action()
	playsound(src, 'sound/machines/crate_open.ogg', 50, FALSE)

/obj/item/polymorph_belt/attack(mob/living/target_mob, mob/living/user, params)
	. = ..()
	if (.)
		return
	if (!isliving(target_mob))
		return
	if (ishuman(target_mob) && !ismonkey(target_mob))
		balloon_alert(user, "target too complex!")
		return
	if (!(target_mob.mob_biotypes & MOB_ORGANIC))
		balloon_alert(user, "organic life only!")
		return
	if (isanimal_or_basicmob(target_mob))
		if (!target_mob.compare_sentience_type(SENTIENCE_ORGANIC))
			balloon_alert(user, "target too intelligent!")
			return
	if (stored_mob_type == target_mob.type)
		balloon_alert(user, "already scanned!")
		return
	if (DOING_INTERACTION_WITH_TARGET(user, target_mob))
		balloon_alert(user, "busy!")
		return
	balloon_alert(user, "scanning...")
	visible_message(span_notice("[user] begins scanning [target_mob] with [src]."))
	if (!do_after(user, delay = 5 SECONDS, target = target_mob))
		return
	visible_message(span_notice("[user] scans [target_mob] with [src]."))
	stored_mob_type = target_mob.type
	update_transform_action()
	playsound(src, 'sound/machines/ping.ogg', 50, FALSE)

/// Make sure we can transform into the scanned target
/obj/item/polymorph_belt/proc/update_transform_action()
	if (isnull(stored_mob_type) || !active)
		return
	if (isnull(transform_action))
		transform_action = add_item_action(/datum/action/cooldown/spell/shapeshift/polymorph_belt)
	transform_action.update_type(stored_mob_type)

/// Functioning polymorph belt
/obj/item/polymorph_belt/functioning
	active = TRUE

/datum/action/cooldown/spell/shapeshift/polymorph_belt
	name = "Invert Polymorphic Field"
	cooldown_time = 30 SECONDS
	school = SCHOOL_UNSET
	invocation_type = INVOCATION_NONE
	spell_requirements = NONE
	/// Amount of time it takes us to transform back or forth
	var/channel_time = 3 SECONDS

/datum/action/cooldown/spell/shapeshift/polymorph_belt/before_cast(mob/living/cast_on)
	. = ..()
	if (. & SPELL_CANCEL_CAST)
		return
	if (channel_time <= 0)
		return
	if (DOING_INTERACTION_WITH_TARGET(cast_on, cast_on))
		return . | SPELL_CANCEL_CAST

	var/old_transform = cast_on.transform

	playsound(cast_on, 'sound/effects/wounds/crack1.ogg', 50)
	animate(cast_on, transform = matrix() * 1.2, time = 0.5 SECONDS, easing = SINE_EASING, loop = -1)
	animate(transform = matrix() * 0.8, time = 0.5 SECONDS, easing = SINE_EASING, loop = -1)

	cast_on.balloon_alert(cast_on, "transforming...")
	if (!do_after(cast_on, delay = channel_time, target = cast_on))
		animate(cast_on, transform = old_transform, time = 0.25 SECONDS, easing = SINE_EASING, loop = 0)
		return . | SPELL_CANCEL_CAST
	cast_on.transform = old_transform
	playsound(cast_on, 'sound/magic/demon_consume.ogg', 50, TRUE)

/datum/action/cooldown/spell/shapeshift/polymorph_belt/Remove(mob/living/remove_from)
	unshift_owner()
	return ..()

/// Update what you are transforming to or from
/datum/action/cooldown/spell/shapeshift/polymorph_belt/proc/update_type(transform_type)
	unshift_owner()
	shapeshift_type = transform_type
	possible_shapes = list(transform_type)
	var/mob/living/will_become = transform_type
	desc = "Assume your [initial(will_become.name)] form!"
	build_all_button_icons(update_flags = UPDATE_BUTTON_NAME)
