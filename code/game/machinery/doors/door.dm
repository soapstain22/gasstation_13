#define DOOR_CLOSE_WAIT 60 ///Default wait until doors autoclose
#define DOOR_VISION_DISTANCE 11 ///The maximum distance a door will see out to
/obj/machinery/door
	name = "door"
	desc = "It opens and closes."
	icon = 'icons/obj/doors/Doorint.dmi'
	icon_state = "door1"
	base_icon_state = "door"
	opacity = TRUE
	density = TRUE
	move_resist = MOVE_FORCE_VERY_STRONG
	layer = OPEN_DOOR_LAYER
	power_channel = AREA_USAGE_ENVIRON
	pass_flags_self = PASSDOORS
	max_integrity = 350
	armor = list(MELEE = 30, BULLET = 30, LASER = 20, ENERGY = 20, BOMB = 10, BIO = 100, FIRE = 80, ACID = 70)
	can_atmos_pass = ATMOS_PASS_DENSITY
	flags_1 = PREVENT_CLICK_UNDER_1
	receive_ricochet_chance_mod = 0.8
	damage_deflection = 10

	interaction_flags_atom = INTERACT_ATOM_UI_INTERACT
	blocks_emissive = EMISSIVE_BLOCK_UNIQUE

	var/secondsElectrified = MACHINE_NOT_ELECTRIFIED
	var/shockedby
	var/visible = TRUE
	var/operating = FALSE
	var/glass = FALSE
	var/welded = FALSE
	var/normalspeed = 1
	/// For reinforced glass-windowed airlocks and firedoors.
	var/heat_proof = FALSE
	/// If TRUE, the door can be opened without access.
	var/emergency = FALSE
	/// TRUE if it's meant to go under another door, e.g. firelocks.
	var/sub_door = FALSE
	var/closingLayer = CLOSED_DOOR_LAYER
	/// Does it automatically close after some time?
	var/autoclose = FALSE
	/// Whether the door detects things and mobs in its way. If TRUE, reopens when it does. If FALSE, closes and crushes them.
	var/safe = TRUE
	/// Whether the door is bolted or not.
	var/locked = FALSE
	/// The type of door frame to drop during deconstruction.
	var/assemblytype
	var/datum/effect_system/spark_spread/spark_system
	/// Ignore this, just use explosion_block.
	var/real_explosion_block
	/// If TRUE, this door will always open on red alert.
	var/red_alert_access = FALSE
	/// Unrestricted sides. A bitflag for which direction(s) (if any) can open the door with no access.
	var/unres_sides = 0
	/// Whether or not the door can crush mobs.
	var/can_crush = TRUE
	/// This ID is set by the cyclelink_helper_multi mapping helper or players using airlock electronics. Used to maintain a list of airlocks with the same ID to close when this one opens.
	var/close_others_ID
	/// Doors to close when this one opens.
	var/list/close_others
	/// Direction it looks for another door with the opposite close_other_dir to pair with. Set by cyclelink_helper mapping helper at mapload.
	var/close_other_dir = 0
	/// Door it cycles with, only set if it finds one to pair with.
	var/obj/machinery/door/close_other
	/// Used by shuttle airlocks with external station airlocks near them to bypass the airlocks' access requirements and override cycling when the shuttle is docked.
	var/shuttledocked = FALSE
	/// TRUE means the door will automatically close the next time it's opened.
	var/delayed_close_requested = FALSE
	/// Does this door use airlock electronics? If so, give it a set based on its access settings in Initialize() if it wasn't built by a player.
	var/uses_electronics = FALSE
	/// Airlock electronics it drops when deconstructed (if it uses them). Added by create_electronics_from_door() if spawned or set_access_from_electronics() if built.
	var/obj/item/electronics/airlock/electronics = null

/obj/machinery/door/examine(mob/user)
	. = ..()
	if(close_others_ID)
		. += span_warning("This door cycles on ID: [sanitize(close_others_ID)].")
	if(red_alert_access)
		if(SSsecurity_level.current_level >= SEC_LEVEL_RED)
			. += span_notice("Due to a security threat, its access requirements have been lifted!")
		else
			. += span_notice("In the event of a red alert, its access requirements will automatically lift.")
	. += span_notice("Its maintenance panel is [panel_open ? "open" : "<b>screwed</b> in place"].")

/obj/machinery/door/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()

	if(isaicamera(user) || issilicon(user))
		return .

	if (isnull(held_item) && Adjacent(user))
		context[SCREENTIP_CONTEXT_LMB] = "Open"
		return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/door/check_access_list(list/access_list)
	if(red_alert_access && SSsecurity_level.current_level >= SEC_LEVEL_RED)
		return TRUE
	return ..()

/obj/machinery/door/Initialize(mapload, constructed = FALSE)
	. = ..()
	set_init_door_layer()
	update_freelook_sight()
	air_update_turf(TRUE, TRUE)
	register_context()
	if(!constructed)
		create_electronics_from_door()
	GLOB.airlocks += src
	spark_system = new /datum/effect_system/spark_spread
	spark_system.set_up(2, 1, src)
	if(density)
		flags_1 |= PREVENT_CLICK_UNDER_1
	else
		flags_1 &= ~PREVENT_CLICK_UNDER_1

	//doors only block while dense though so we have to use the proc
	real_explosion_block = explosion_block
	explosion_block = EXPLOSION_BLOCK_PROC
	RegisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED, .proc/check_security_level)

/obj/machinery/door/LateInitialize()
	. = ..()
	if(close_others_ID)
		create_close_others_list()
	if(close_other_dir)
		find_close_other()

/obj/machinery/door/proc/set_access_from_electronics(obj/item/electronics/airlock/passed_electronics, move_to_door = FALSE)
	if(!passed_electronics)
		return
	if(!istype(passed_electronics))
		return
	if(electronics)
		qdel(electronics) //this shouldn't be happening, but just in case

	if(move_to_door)
		electronics = passed_electronics
	else
		electronics = passed_electronics.Clone()
	electronics.forceMove(src)

	if(electronics.one_access)
		req_one_access = electronics.accesses
	else
		req_access = electronics.accesses

	if(electronics.passed_name)
		name = electronics.passed_name

	if(electronics.unres_sides)
		unres_sides = electronics.unres_sides
		update_unres_sides()

	if(electronics.passed_cycle_id)
		close_others_ID = electronics.passed_cycle_id
		create_close_others_list()

/obj/machinery/door/proc/create_electronics_from_door()
	if(!uses_electronics)
		return

	electronics = new(src)

	if(length(req_access))
		electronics.one_access = FALSE
		electronics.accesses += req_access.Copy()

	else if(length(req_one_access))
		electronics.one_access = TRUE
		electronics.accesses += req_one_access.Copy()

	if(name)
		electronics.passed_name = name

	if(unres_sides)
		electronics.unres_sides = unres_sides

	if(close_others_ID)
		electronics.passed_cycle_id = close_others_ID

/obj/machinery/door/proc/create_close_others_list()
	for(var/obj/machinery/door/door in GLOB.airlocks)
		if(door == src)
			continue
		LAZYINITLIST(close_others)
		if(LAZYFIND(close_others, door))
			continue
		if(door.close_others_ID == close_others_ID)
			LAZYADD(close_others, door)
			LAZYADD(door.close_others, src)

/obj/machinery/door/proc/update_unres_sides()
	if(!unres_sides)
		return
	update_appearance(UPDATE_ICON)

/obj/machinery/door/proc/set_init_door_layer()
	if(density)
		layer = closingLayer
	else
		layer = initial(layer)

/obj/machinery/door/Destroy()
	update_freelook_sight()
	GLOB.airlocks -= src
	if(spark_system)
		qdel(spark_system)
		spark_system = null
	air_update_turf(TRUE, FALSE)
	if(LAZYLEN(close_others)) //remove this door from the list of every linked door
		close_others_ID = null
		for(var/obj/machinery/door/other_door as anything in close_others)
			LAZYREMOVE(other_door.close_others, src)
		LAZYNULL(close_others)
	return ..()

/**
 * Signal handler for checking if we notify our surrounding that access requirements are lifted accordingly to a newly set security level
 *
 * Arguments:
 * * source The datum source of the signal
 * * new_level The new security level that is in effect
 */
/obj/machinery/door/proc/check_security_level(datum/source, new_level)
	SIGNAL_HANDLER

	if(new_level <= SEC_LEVEL_BLUE)
		return
	if(!red_alert_access)
		return
	audible_message(span_notice("[src] whirr[p_s()] as [p_they()] automatically lift[p_s()] access requirements!"))
	playsound(src, 'sound/machines/boltsup.ogg', 50, TRUE)

/obj/machinery/door/proc/try_safety_unlock(mob/user)
	return FALSE

/**
 * Called when attempting to remove the seal from an airlock
 *
 * Here because we need to call it and return if there was a seal so we don't try to open the door
 * or try its safety lock while it's sealed
 * Arguments:
 * * user - the mob attempting to remove the seal
 */
/obj/machinery/door/proc/try_remove_seal(mob/user)
	return

/obj/machinery/door/Bumped(atom/movable/AM)
	. = ..()
	if(operating || (obj_flags & EMAGGED))
		return
	if(ismob(AM))
		var/mob/B = AM
		if((isdrone(B) || iscyborg(B)) && B.stat)
			return
		if(isliving(AM))
			var/mob/living/M = AM
			if(world.time - M.last_bumped <= 10)
				return //Can bump-open one airlock per second. This is to prevent shock spam.
			M.last_bumped = world.time
			if(HAS_TRAIT(M, TRAIT_HANDS_BLOCKED) && !check_access(null) && !emergency)
				return
			if(try_safety_unlock(M))
				return
			bumpopen(M)
			return
		return

	if(isitem(AM))
		var/obj/item/I = AM
		if(!density || (I.w_class < WEIGHT_CLASS_NORMAL && !LAZYLEN(I.GetAccess())))
			return
		if(check_access(I))
			open()
		else
			do_animate("deny")
		return

/obj/machinery/door/Move()
	var/turf/T = loc
	. = ..()
	if(density) //Gotta be closed my friend
		move_update_air(T)

/obj/machinery/door/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(.)
		return
	// Snowflake handling for PASSGLASS.
	if(istype(mover) && (mover.pass_flags & PASSGLASS))
		return !opacity

/obj/machinery/door/proc/bumpopen(mob/user)
	if(operating)
		return
	add_fingerprint(user)
	if(!density || (obj_flags & EMAGGED))
		return

	if(requiresID() && allowed(user))
		open()
	else
		do_animate("deny")

/obj/machinery/door/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(try_remove_seal(user))
		return
	if(try_safety_unlock(user))
		return
	return try_to_activate_door(user)


/obj/machinery/door/attack_tk(mob/user)
	if(requiresID() && !allowed(null))
		return
	return ..()


/obj/machinery/door/proc/try_to_activate_door(mob/user, access_bypass = FALSE)
	add_fingerprint(user)
	if(operating || (obj_flags & EMAGGED))
		return
	access_bypass |= !requiresID()
	if(access_bypass || allowed(user))
		if(density)
			open()
		else
			close()
		return TRUE
	if(density)
		do_animate("deny")

/obj/machinery/door/allowed(mob/M)
	if(emergency)
		return TRUE
	if(unrestricted_side(M))
		return TRUE
	return ..()

/obj/machinery/door/proc/unrestricted_side(mob/opener) //Allows for specific side of airlocks to be unrestrected (IE, can exit maint freely, but need access to enter)
	return get_dir(src, opener) & unres_sides

/obj/machinery/door/proc/try_to_weld(obj/item/weldingtool/W, mob/user)
	return

/// Called when the user right-clicks on the door with a welding tool.
/obj/machinery/door/proc/try_to_weld_secondary(obj/item/weldingtool/tool, mob/user)
	return


/obj/machinery/door/proc/try_to_crowbar(obj/item/acting_object, mob/user)
	return

/// Called when the user right-clicks on the door with a crowbar.
/obj/machinery/door/proc/try_to_crowbar_secondary(obj/item/acting_object, mob/user)
	return

/obj/machinery/door/attackby(obj/item/I, mob/living/user, params)
	if(!user.combat_mode && (I.tool_behaviour == TOOL_CROWBAR || istype(I, /obj/item/fireaxe)))
		var/forced_open = FALSE
		if(istype(I, /obj/item/crowbar))
			var/obj/item/crowbar/C = I
			forced_open = C.force_opens
		try_to_crowbar(I, user, forced_open)
		return TRUE
	else if(I.tool_behaviour == TOOL_WELDER)
		try_to_weld(I, user, params)
		return TRUE
	else if((!(I.item_flags & NOBLUDGEON) && !user.combat_mode) && try_to_activate_door(user))
		return TRUE
	return ..()

/obj/machinery/door/attackby_secondary(obj/item/weapon, mob/user, params)
	if (weapon.tool_behaviour == TOOL_WELDER)
		try_to_weld_secondary(weapon, user)

		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	if (weapon.tool_behaviour == TOOL_CROWBAR)
		var/forced_open = FALSE
		if(istype(weapon, /obj/item/crowbar))
			var/obj/item/crowbar/crowbar = weapon
			forced_open = crowbar.force_opens
		try_to_crowbar_secondary(weapon, user, forced_open)

		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	..()
	return SECONDARY_ATTACK_CONTINUE_CHAIN

/obj/machinery/door/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	. = ..()
	if(. && atom_integrity > 0)
		if(damage_amount >= 10 && prob(30))
			spark_system.start()

/obj/machinery/door/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			if(glass)
				playsound(loc, 'sound/effects/glasshit.ogg', 90, TRUE)
			else if(damage_amount)
				playsound(loc, 'sound/weapons/smash.ogg', 50, TRUE)
			else
				playsound(src, 'sound/weapons/tap.ogg', 50, TRUE)
		if(BURN)
			playsound(src.loc, 'sound/items/welder.ogg', 100, TRUE)

/obj/machinery/door/emp_act(severity)
	. = ..()
	if (. & EMP_PROTECT_SELF)
		return
	if(prob(20/severity) && (istype(src, /obj/machinery/door/airlock) || istype(src, /obj/machinery/door/window)) )
		INVOKE_ASYNC(src, .proc/open)
	if(prob(severity*10 - 20))
		if(secondsElectrified == MACHINE_NOT_ELECTRIFIED)
			secondsElectrified = MACHINE_ELECTRIFIED_PERMANENT
			LAZYADD(shockedby, "\[[time_stamp()]\]EM Pulse")
			addtimer(CALLBACK(src, .proc/unelectrify), 300)

/obj/machinery/door/proc/unelectrify()
	secondsElectrified = MACHINE_NOT_ELECTRIFIED

/obj/machinery/door/update_icon_state()
	icon_state = "[base_icon_state][density]"
	return ..()

/obj/machinery/door/proc/do_animate(animation)
	switch(animation)
		if("opening")
			if(panel_open)
				flick("o_doorc0", src)
			else
				flick("doorc0", src)
		if("closing")
			if(panel_open)
				flick("o_doorc1", src)
			else
				flick("doorc1", src)
		if("deny")
			if(!machine_stat)
				flick("door_deny", src)


/obj/machinery/door/proc/open()
	if(!density)
		return TRUE
	if(operating)
		return
	operating = TRUE
	do_animate("opening")
	set_opacity(0)
	sleep(5)
	set_density(FALSE)
	flags_1 &= ~PREVENT_CLICK_UNDER_1
	sleep(5)
	layer = initial(layer)
	update_appearance()
	set_opacity(0)
	operating = FALSE
	air_update_turf(TRUE, FALSE)
	update_freelook_sight()
	if(autoclose)
		autoclose_in(DOOR_CLOSE_WAIT)
	return 1

/obj/machinery/door/proc/close()
	if(density)
		return TRUE
	if(operating || welded)
		return
	if(safe)
		for(var/atom/movable/M in get_turf(src))
			if(M.density && M != src) //something is blocking the door
				if(autoclose)
					autoclose_in(DOOR_CLOSE_WAIT)
				return

	operating = TRUE

	do_animate("closing")
	layer = closingLayer
	sleep(5)
	set_density(TRUE)
	flags_1 |= PREVENT_CLICK_UNDER_1
	sleep(5)
	update_appearance()
	if(visible && !glass)
		set_opacity(1)
	operating = FALSE
	air_update_turf(TRUE, TRUE)
	update_freelook_sight()

	if(!can_crush)
		return TRUE
	if(safe)
		CheckForMobs()
	else
		crush()
	return TRUE

/obj/machinery/door/proc/try_close_others()
	if(emergency)
		return

	for(var/obj/machinery/door/other_door as anything in close_others)
		if(other_door.emergency)
			continue
		if(other_door.operating)
			other_door.delayed_close_requested = TRUE
		else
			addtimer(CALLBACK(other_door, .proc/close), 2)

	if(!close_other || shuttledocked)
		return

	if(close_other.shuttledocked || close_other.emergency)
		return

	if(close_other.operating)
		close_other.delayed_close_requested = TRUE
	else
		addtimer(CALLBACK(close_other, .proc/close), 2)

/obj/machinery/door/proc/find_close_other()
	if (close_other)
		close_other.close_other = null
		close_other = null
	if (!close_other_dir)
		return
	var/limit = DOOR_VISION_DISTANCE
	var/turf/T = get_turf(src)
	var/obj/machinery/door/FoundDoor = locate(/obj/machinery/door/window) in T //first look for a windoor on our turf, e.g. opposite desk windoor
	do
		if(!FoundDoor)
			T = get_step(T, close_other_dir)
			FoundDoor = locate(/obj/machinery/door/airlock) in T
			if(!FoundDoor)
				FoundDoor = locate(/obj/machinery/door/window) in T
		if (FoundDoor && FoundDoor.close_other_dir != get_dir(FoundDoor, src))
			FoundDoor = null
		limit--
	while(!FoundDoor && limit)
	if (!FoundDoor)
		log_mapping("[src] at [AREACOORD(src)] failed to find a valid door to cyclelink with!")
		return
	FoundDoor.close_other = src
	close_other = FoundDoor

/obj/machinery/door/proc/CheckForMobs()
	if(locate(/mob/living) in get_turf(src))
		sleep(1)
		open()

/obj/machinery/door/proc/crush()
	for(var/mob/living/L in get_turf(src))
		L.visible_message(span_warning("[src] closes on [L], crushing [L.p_them()]!"), span_userdanger("[src] closes on you and crushes you!"))
		SEND_SIGNAL(L, COMSIG_LIVING_DOORCRUSHED, src)
		if(isalien(L))  //For xenos
			L.adjustBruteLoss(DOOR_CRUSH_DAMAGE * 1.5) //Xenos go into crit after aproximately the same amount of crushes as humans.
			L.emote("roar")
		else if(ishuman(L)) //For humans
			L.adjustBruteLoss(DOOR_CRUSH_DAMAGE)
			L.emote("scream")
			L.Paralyze(100)
		else //for simple_animals & borgs
			L.adjustBruteLoss(DOOR_CRUSH_DAMAGE)
		var/turf/location = get_turf(src)
		//add_blood doesn't work for borgs/xenos, but add_blood_floor does.
		L.add_splatter_floor(location)
		log_combat(src, L, "crushed")
	for(var/obj/vehicle/sealed/mecha/M in get_turf(src))
		M.take_damage(DOOR_CRUSH_DAMAGE)
		log_combat(src, M, "crushed")

/obj/machinery/door/proc/autoclose()
	if(!QDELETED(src) && !density && !operating && !locked && !welded && autoclose)
		close()

/obj/machinery/door/proc/autoclose_in(wait)
	addtimer(CALLBACK(src, .proc/autoclose), wait, TIMER_UNIQUE | TIMER_NO_HASH_WAIT | TIMER_OVERRIDE)

/obj/machinery/door/proc/requiresID()
	return 1

/obj/machinery/door/proc/hasPower()
	return !(machine_stat & NOPOWER)

/obj/machinery/door/proc/update_freelook_sight()
	if(!glass && GLOB.cameranet)
		GLOB.cameranet.updateVisibility(src, 0)

/obj/machinery/door/block_superconductivity() // All non-glass airlocks block heat, this is intended.
	if(opacity || heat_proof)
		return 1
	return 0

/obj/machinery/door/morgue
	icon = 'icons/obj/doors/doormorgue.dmi'

/obj/machinery/door/get_dumping_location()
	return null

/obj/machinery/door/proc/lock()
	return

/obj/machinery/door/proc/unlock()
	return

/obj/machinery/door/proc/hostile_lockdown(mob/origin)
	if(!machine_stat) //So that only powered doors are closed.
		close() //Close ALL the doors!

/obj/machinery/door/proc/disable_lockdown()
	if(!machine_stat) //Opens only powered doors.
		open() //Open everything!

/obj/machinery/door/ex_act(severity, target)
	//if it blows up a wall it should blow up a door
	return ..(severity ? min(EXPLODE_DEVASTATE, severity + 1) : EXPLODE_NONE, target)

/obj/machinery/door/GetExplosionBlock()
	return density ? real_explosion_block : 0

/obj/machinery/door/power_change()
	. = ..()
	if(. && !(machine_stat & NOPOWER))
		autoclose_in(DOOR_CLOSE_WAIT)

/obj/machinery/door/zap_act(power, zap_flags)
	zap_flags &= ~ZAP_OBJ_DAMAGE
	. = ..()


#undef DOOR_CLOSE_WAIT
#undef DOOR_VISION_DISTANCE
