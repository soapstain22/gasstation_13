
/obj
	animate_movement = SLIDE_STEPS
	speech_span = SPAN_ROBOT
	var/obj_flags = CAN_BE_HIT

	/// Extra examine line to describe controls, such as right-clicking, left-clicking, etc.
	var/desc_controls

	/// The context returned when an attack against this object doesnt deal any traditional damage to the object.
	var/no_damage_feedback = "without leaving a mark"
	/// Icon to use as a 32x32 preview in crafting menus and such
	var/icon_preview
	var/icon_state_preview
	/// The vertical pixel offset applied when the object is anchored on a tile with table
	/// Ignored when set to 0 - to avoid shifting directional wall-mounted objects above tables
	var/anchored_tabletop_offset = 0

	var/damtype = BRUTE
	var/force = 0

	/// How good a given object is at causing wounds on carbons. Higher values equal better shots at creating serious wounds.
	var/wound_bonus = 0
	/// If this attacks a human with no wound armor on the affected body part, add this to the wound mod. Some attacks may be significantly worse at wounding if there's even a slight layer of armor to absorb some of it vs bare flesh
	var/bare_wound_bonus = 0

	/// A multiplier to an objecet's force when used against a stucture, vechicle, machine, or robot.
	var/demolition_mod = 1

	/// Custom fire overlay icon, will just use the default overlay if this is null
	var/custom_fire_overlay
	/// Particles this obj uses when burning, if any
	var/burning_particles

	var/drag_slowdown // Amont of multiplicative slowdown applied if pulled. >1 makes you slower, <1 makes you faster.

	/// Map tag for something.  Tired of it being used on snowflake items.  Moved here for some semblance of a standard.
	/// Next pr after the network fix will have me refactor door interactions, so help me god.
	var/id_tag = null

	uses_integrity = TRUE

/obj/vv_edit_var(vname, vval)
	if(vname == NAMEOF(src, obj_flags))
		if ((obj_flags & DANGEROUS_POSSESSION) && !(vval & DANGEROUS_POSSESSION))
			return FALSE
	return ..()

/// A list of all /obj by their id_tag
GLOBAL_LIST_EMPTY(objects_by_id_tag)

/obj/Initialize(mapload)
	. = ..()

	check_on_table()

	if (id_tag)
		GLOB.objects_by_id_tag[id_tag] = src

/obj/Destroy(force)
	if(!ismachinery(src))
		STOP_PROCESSING(SSobj, src) // TODO: Have a processing bitflag to reduce on unnecessary loops through the processing lists
	SStgui.close_uis(src)
	GLOB.objects_by_id_tag -= id_tag
	. = ..()

/obj/attacked_by(obj/item/attacking_item, mob/living/user)
	if(!attacking_item.force)
		return

	var/total_force = (attacking_item.force * attacking_item.demolition_mod)

	var/damage = take_damage(total_force, attacking_item.damtype, MELEE, 1)

	var/damage_verb = "hit"

	if(attacking_item.demolition_mod > 1 && damage)
		damage_verb = "pulverise"
	if(attacking_item.demolition_mod < 1)
		damage_verb = "ineffectively pierce"

	user.visible_message(span_danger("[user] [damage_verb][plural_s(damage_verb)] [src] with [attacking_item][damage ? "." : ", [no_damage_feedback]!"]"), \
		span_danger("You [damage_verb] [src] with [attacking_item][damage ? "." : ", [no_damage_feedback]!"]"), null, COMBAT_MESSAGE_RANGE)
	log_combat(user, src, "attacked", attacking_item)

/obj/assume_air(datum/gas_mixture/giver)
	if(loc)
		return loc.assume_air(giver)
	else
		return null

/obj/remove_air(amount)
	if(loc)
		return loc.remove_air(amount)
	else
		return null

/obj/return_air()
	if(loc)
		return loc.return_air()
	else
		return null

/obj/proc/handle_internal_lifeform(mob/lifeform_inside_me, breath_request)
	//Return: (NONSTANDARD)
	// null if object handles breathing logic for lifeform
	// datum/air_group to tell lifeform to process using that breath return
	//DEFAULT: Take air from turf to give to have mob process

	if(breath_request>0)
		var/datum/gas_mixture/environment = return_air()
		var/breath_percentage = BREATH_VOLUME / environment.return_volume()
		return remove_air(environment.total_moles() * breath_percentage)
	else
		return null

/obj/attack_ghost(mob/user)
	. = ..()
	if(.)
		return
	SEND_SIGNAL(src, COMSIG_ATOM_UI_INTERACT, user)
	ui_interact(user)

/obj/singularity_pull(S, current_size)
	..()
	if(move_resist == INFINITY)
		return
	if(!anchored || current_size >= STAGE_FIVE)
		step_towards(src,S)

/obj/get_dumping_location()
	return get_turf(src)

/obj/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("", "---")
	VV_DROPDOWN_OPTION(VV_HK_MASS_DEL_TYPE, "Delete all of type")
	VV_DROPDOWN_OPTION(VV_HK_OSAY, "Object Say")

/obj/vv_do_topic(list/href_list)
	. = ..()

	if(!.)
		return

	if(href_list[VV_HK_OSAY])
		return SSadmin_verbs.dynamic_invoke_verb(usr, /datum/admin_verb/object_say, src)

	if(href_list[VV_HK_MASS_DEL_TYPE])
		if(!check_rights(R_DEBUG|R_SERVER))
			return
		var/action_type = tgui_alert(usr, "Strict type ([type]) or type and all subtypes?",,list("Strict type","Type and subtypes","Cancel"))
		if(action_type == "Cancel" || !action_type)
			return
		if(tgui_alert(usr, "Are you really sure you want to delete all objects of type [type]?",,list("Yes","No")) != "Yes")
			return
		if(tgui_alert(usr, "Second confirmation required. Delete?",,list("Yes","No")) != "Yes")
			return
		var/O_type = type
		switch(action_type)
			if("Strict type")
				var/i = 0
				for(var/obj/Obj in world)
					if(Obj.type == O_type)
						i++
						qdel(Obj)
					CHECK_TICK
				if(!i)
					to_chat(usr, "No objects of this type exist")
					return
				log_admin("[key_name(usr)] deleted all objects of type [O_type] ([i] objects deleted) ")
				message_admins(span_notice("[key_name(usr)] deleted all objects of type [O_type] ([i] objects deleted) "))
			if("Type and subtypes")
				var/i = 0
				for(var/obj/Obj in world)
					if(istype(Obj,O_type))
						i++
						qdel(Obj)
					CHECK_TICK
				if(!i)
					to_chat(usr, "No objects of this type exist")
					return
				log_admin("[key_name(usr)] deleted all objects of type or subtype of [O_type] ([i] objects deleted) ")
				message_admins(span_notice("[key_name(usr)] deleted all objects of type or subtype of [O_type] ([i] objects deleted) "))

/obj/examine(mob/user)
	. = ..()
	if(desc_controls)
		. += span_notice(desc_controls)
	if(obj_flags & UNIQUE_RENAME)
		. += span_notice("Use a pen on it to rename it or change its description.")


/obj/analyzer_act(mob/living/user, obj/item/analyzer/tool)
	if(atmos_scan(user=user, target=src, silent=FALSE))
		return TRUE
	return ..()

/obj/proc/plunger_act(obj/item/plunger/attacking_plunger, mob/living/user, reinforced)
	return SEND_SIGNAL(src, COMSIG_PLUNGER_ACT, attacking_plunger, user, reinforced)

// Should move all contained objects to it's location.
/obj/proc/dump_contents()
	SHOULD_CALL_PARENT(FALSE)
	CRASH("Unimplemented.")

/obj/handle_ricochet(obj/projectile/P)
	. = ..()
	if(. && receive_ricochet_damage_coeff)
		take_damage(P.damage * receive_ricochet_damage_coeff, P.damage_type, P.armor_flag, 0, REVERSE_DIR(P.dir), P.armour_penetration) // pass along receive_ricochet_damage_coeff damage to the structure for the ricochet

/// Handles exposing an object to reagents.
/obj/expose_reagents(list/reagents, datum/reagents/source, methods=TOUCH, volume_modifier=1, show_message=TRUE)
	. = ..()
	if(. & COMPONENT_NO_EXPOSE_REAGENTS)
		return

	SEND_SIGNAL(source, COMSIG_REAGENTS_EXPOSE_OBJ, src, reagents, methods, volume_modifier, show_message)
	for(var/reagent in reagents)
		var/datum/reagent/R = reagent
		. |= R.expose_obj(src, reagents[R])

/// Attempt to freeze this obj if possible. returns TRUE if it succeeded, FALSE otherwise.
/obj/proc/freeze()
	if(HAS_TRAIT(src, TRAIT_FROZEN))
		return FALSE
	if(resistance_flags & FREEZE_PROOF)
		return FALSE

	AddElement(/datum/element/frozen)
	return TRUE

/// Unfreezes this obj if its frozen
/obj/proc/unfreeze()
	SEND_SIGNAL(src, COMSIG_OBJ_UNFREEZE)

/// If we can unwrench this object; returns SUCCESSFUL_UNFASTEN and FAILED_UNFASTEN, which are both TRUE, or CANT_UNFASTEN, which isn't.
/obj/proc/can_be_unfasten_wrench(mob/user, silent)
	if(!(isfloorturf(loc) || isindestructiblefloor(loc)) && !anchored)
		to_chat(user, span_warning("[src] needs to be on the floor to be secured!"))
		return FAILED_UNFASTEN
	return SUCCESSFUL_UNFASTEN

/// Try to unwrench an object in a WONDERFUL DYNAMIC WAY
/obj/proc/default_unfasten_wrench(mob/user, obj/item/wrench, time = 20)
	if(wrench.tool_behaviour != TOOL_WRENCH)
		return CANT_UNFASTEN

	var/turf/ground = get_turf(src)
	if(!anchored && ground.is_blocked_turf(exclude_mobs = TRUE, source_atom = src))
		to_chat(user, span_notice("You fail to secure [src]."))
		return CANT_UNFASTEN
	var/can_be_unfasten = can_be_unfasten_wrench(user)
	if(!can_be_unfasten || can_be_unfasten == FAILED_UNFASTEN)
		return can_be_unfasten
	if(time)
		to_chat(user, span_notice("You begin [anchored ? "un" : ""]securing [src]..."))
	wrench.play_tool_sound(src, 50)
	var/prev_anchored = anchored
	//as long as we're the same anchored state and we're either on a floor or are anchored, toggle our anchored state
	if(!wrench.use_tool(src, user, time, extra_checks = CALLBACK(src, PROC_REF(unfasten_wrench_check), prev_anchored, user)))
		return FAILED_UNFASTEN
	if(!anchored && ground.is_blocked_turf(exclude_mobs = TRUE, source_atom = src))
		to_chat(user, span_notice("You fail to secure [src]."))
		return CANT_UNFASTEN
	to_chat(user, span_notice("You [anchored ? "un" : ""]secure [src]."))
	set_anchored(!anchored)
	check_on_table()
	playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
	SEND_SIGNAL(src, COMSIG_OBJ_DEFAULT_UNFASTEN_WRENCH, anchored)
	return SUCCESSFUL_UNFASTEN

/// For the do_after, this checks if unfastening conditions are still valid
/obj/proc/unfasten_wrench_check(prev_anchored, mob/user)
	if(anchored != prev_anchored)
		return FALSE
	if(can_be_unfasten_wrench(user, TRUE) != SUCCESSFUL_UNFASTEN) //if we aren't explicitly successful, cancel the fuck out
		return FALSE
	return TRUE

/// Adjusts the vertical pixel offset when the object is anchored on a tile with table
/obj/proc/check_on_table()
	if(anchored_tabletop_offset != 0 && !istype(src, /obj/structure/table) && locate(/obj/structure/table) in loc)
		pixel_y = anchored ? anchored_tabletop_offset : initial(pixel_y)


/**
 * Returns the atom(either itself or an internal module) that can interact correctly with the target
 * For example an object can have differet `tool_behaviours` (e.g borg omni tool) but will return an internal reference of that tool
 * You can use it for general purpose polymorphism if you need a proxy atom to interact in a specific way
 * with a target on behalf on this atom
 *
 * Currently used only in the object melee attack chain but can be used anywhere else or even moved up to the atom level if required
 */
/obj/proc/get_proxy_for(atom/target, mob/user)
	return src
