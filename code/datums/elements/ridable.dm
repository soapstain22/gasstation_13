
/datum/element/ridable
	var/last_vehicle_move = 0 //used for move delays
	var/last_move_diagonal = FALSE
	var/vehicle_move_delay = 2 //tick delay between movements, lower = faster, higher = slower
	var/keytype

	var/slowed = FALSE
	var/slowvalue = 1

	///Bool to check if you gain the ridden mob's abilities.
	var/can_use_abilities = FALSE

	var/list/riding_offsets = list()	//position_of_user = list(dir = list(px, py)), or RIDING_OFFSET_ALL for a generic one.
	var/list/directional_vehicle_layers = list()	//["[DIRECTION]"] = layer. Don't set it for a direction for default, set a direction to null for no change.
	var/list/directional_vehicle_offsets = list()	//same as above but instead of layer you have a list(px, py)
	var/list/allowed_turf_typecache
	var/list/forbid_turf_typecache					//allow typecache for only certain turfs, forbid to allow all but those. allow only certain turfs will take precedence.
	var/allow_one_away_from_valid_turf = TRUE		//allow moving one tile away from a valid turf but not more.
	var/override_allow_spacemove = FALSE
	var/drive_verb = "drive"
	/// If we should delete this component when we have nothing left buckled, used for buckling to mobs
	var/del_on_unbuckle_all = FALSE
	/// If the "vehicle" is a mob, respect MOBILITY_MOVE on said mob.
	var/respect_mob_mobility = TRUE

	/// If the rider needs hands free in order to not fall off (fails if they're incap'd or restrained)
	var/rider_holding_on = FALSE
	/// If the ridden needs a hand free to carry the rider (fails if they're incap'd or restrained)
	var/ridden_holding_rider = FALSE


/datum/element/ridable/Attach(atom/movable/target)
	if(!ismovable(target))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(target, COMSIG_MOVABLE_TRY_MOUNTING, .proc/check_mounting)
	//RegisterSignal(target, COMSIG_MOVABLE_UNBUCKLE, .proc/check_unmounting)


//datum/element/ridable/proc/check_unmounting(datum/source, mob/living/rider, force = FALSE)


/datum/element/ridable/proc/check_mounting(atom/movable/target_movable, mob/living/potential_rider, force = FALSE, riding_flags = NONE)
	SIGNAL_HANDLER

	if((riding_flags & RIDING_RIDER_HOLDING_ON) && !equip_buckle_inhands(potential_rider, 2, target_movable)) // hardcode 2 hands for now
		potential_rider.visible_message("<span class='warning'>[potential_rider] can't get a grip on [target_movable] because [potential_rider.p_their()] hands are full!</span>",
			"<span class='warning'>You can't get a grip on [target_movable] because your hands are full!</span>")
		return MOUNTING_HALT_BUCKLE


	var/mob/living/target_living = target_movable

	// need to see if !equip_buckle_inhands() checks are enough to skip any needed incapac/restrain checks
	// ridden_holding_rider shouldn't apply if the ridden isn't even a living mob
	if((target_living & RIDING_RIDDEN_HOLD_RIDER) && !equip_buckle_inhands(target_living, 1, potential_rider, target_movable)) // hardcode 1 hand for now
		target_living.visible_message("<span class='warning'>[target_living] can't get a grip on [potential_rider] because [target_living.p_their()] hands are full!</span>",
			"<span class='warning'>You can't get a grip on [potential_rider] because your hands are full!</span>")
		return MOUNTING_HALT_BUCKLE

	target_living.AddComponent(/datum/component/riding, potential_rider, force, riding_flags)

/datum/element/ridable/proc/equip_buckle_inhands(mob/living/carbon/human/user, amount_required = 1, atom/movable/target_movable, riding_target_override = null)
	var/atom/movable/AM = target_movable
	var/amount_equipped = 0
	for(var/amount_needed = amount_required, amount_needed > 0, amount_needed--)
		var/obj/item/riding_offhand/inhand = new /obj/item/riding_offhand(user)
		if(!riding_target_override)
			inhand.rider = user
		else
			inhand.rider = riding_target_override
		inhand.parent = AM
		for(var/obj/item/I in user.held_items) // delete any hand items like slappers that could still totally be used to grab on
			if((I.obj_flags & HAND_ITEM))
				qdel(I)
		if(user.put_in_hands(inhand, TRUE))
			amount_equipped++
		else
			break

	if(amount_equipped >= amount_required)
		return TRUE
	else
		unequip_buckle_inhands(user, target_movable)
		return FALSE

/datum/element/ridable/proc/unequip_buckle_inhands(mob/living/carbon/user, atom/movable/target_movable)
	var/atom/movable/AM = target_movable
	for(var/obj/item/riding_offhand/O in user.contents)
		if(O.parent != AM)
			CRASH("RIDING OFFHAND ON WRONG MOB")
		if(O.selfdeleting)
			continue
		else
			qdel(O)
	return TRUE
