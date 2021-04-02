#define CONSTRUCTION_PANEL_OPEN 1 //Maintenance panel is open, still functioning
#define CONSTRUCTION_NO_CIRCUIT 2 //Circuit board removed, can safely weld apart
#define DEFAULT_STEP_TIME 20 /// default time for each step
#define MINIMUM_TEMPERATURE_TO_BURN_ARMS 500 ///everything above this temperature will start burning unprotected arms
#define TOOLLESS_OPEN_DURATION_SOLO 20 SECONDS ///opening a firelock without a tool takes this long if only one person is doing it

/obj/machinery/door/firedoor
	name = "firelock"
	desc = "Apply crowbar."
	icon = 'icons/obj/doors/Doorfireglass.dmi'
	icon_state = "door_open"
	opacity = FALSE
	density = FALSE
	max_integrity = 300
	resistance_flags = FIRE_PROOF
	heat_proof = TRUE
	glass = TRUE
	sub_door = TRUE
	explosion_block = 1
	safe = FALSE
	layer = BELOW_OPEN_DOOR_LAYER
	closingLayer = CLOSED_FIREDOOR_LAYER
	assemblytype = /obj/structure/firelock_frame
	armor = list(MELEE = 10, BULLET = 30, LASER = 20, ENERGY = 20, BOMB = 30, BIO = 100, RAD = 100, FIRE = 95, ACID = 70)
	interaction_flags_machine = INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON | INTERACT_MACHINE_REQUIRES_SILICON | INTERACT_MACHINE_OPEN
	var/nextstate = null
	var/boltslocked = TRUE
	var/list/affecting_areas
	///the number of people trying to open this firelock without any tools
	var/number_of_people_trying_to_open = 0

/obj/machinery/door/firedoor/Initialize()
	. = ..()
	CalculateAffectingAreas()

/obj/machinery/door/firedoor/examine(mob/user)
	. = ..()
	if(!density)
		. += "<span class='notice'>It is open, but could be <b>pried</b> closed.</span>"
	else if(!welded)
		. += "<span class='notice'>It is closed, but could be <i>pried</i> open. Deconstruction would require it to be <b>welded</b> shut.</span>"
	else if(boltslocked)
		. += "<span class='notice'>It is <i>welded</i> shut. The floor bolts have been locked by <b>screws</b>.</span>"
	else
		. += "<span class='notice'>The bolt locks have been <i>unscrewed</i>, but the bolts themselves are still <b>wrenched</b> to the floor.</span>"

/obj/machinery/door/firedoor/proc/CalculateAffectingAreas()
	remove_from_areas()
	affecting_areas = get_adjacent_open_areas(src) | get_area(src)
	for(var/I in affecting_areas)
		var/area/A = I
		LAZYADD(A.firedoors, src)

/obj/machinery/door/firedoor/closed
	icon_state = "door_closed"
	density = TRUE

//see also turf/AfterChange for adjacency shennanigans

/obj/machinery/door/firedoor/proc/remove_from_areas()
	if(affecting_areas)
		for(var/I in affecting_areas)
			var/area/A = I
			LAZYREMOVE(A.firedoors, src)

/obj/machinery/door/firedoor/Destroy()
	remove_from_areas()
	affecting_areas.Cut()
	return ..()

/obj/machinery/door/firedoor/Bumped(atom/movable/AM)
	if(panel_open || operating)
		return
	if(!density)
		return ..()
	return FALSE

/obj/machinery/door/firedoor/bumpopen(mob/living/user)
	return FALSE //No bumping to open, not even in mechs

/obj/machinery/door/firedoor/power_change()
	. = ..()
	INVOKE_ASYNC(src, .proc/latetoggle)

/obj/machinery/door/firedoor/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(operating || !density)
		return
	if(user.combat_mode)
		user.changeNext_move(CLICK_CD_MELEE)

		user.visible_message("<span class='notice'>[user] bangs on \the [src].</span>", \
			"<span class='notice'>You bang on \the [src].</span>")
		playsound(loc, 'sound/effects/glassknock.ogg', 10, FALSE, frequency = 32000)
	else
		if(user.do_afters)//you get one firelock to open, better pick the right one
			return
		number_of_people_trying_to_open++

		//dont want them to be moved by pressure differences when theyre holding onto the firelock with all their strength
		user.move_resist = MOVE_FORCE_STRONG

		var/starting_health = user.health
		var/starting_time = REALTIMEOFDAY

		///we dont want people with only one hand to have the same visible_message as people with two hands
		var/hand_string = "hands"
		if(iscarbon(user))
			var/mob/living/carbon/user_as_carbon = user
			var/obj/item/bodypart/right_arm = user_as_carbon.get_bodypart(BODY_ZONE_R_ARM)
			var/obj/item/bodypart/left_arm = user_as_carbon.get_bodypart(BODY_ZONE_L_ARM)

			if(!right_arm || right_arm.bodypart_disabled)//this is assuming that you have at least one hand since... this proc is called attack_hand
				hand_string = "hand"
			if(!left_arm || left_arm.bodypart_disabled)
				hand_string = "hand"

		//we want to acknowledge that several people are trying to open the same firelock to encourage them to do it
		//also to signal to people doing it by themselves that its faster with help
		if(number_of_people_trying_to_open == 1)
			user.visible_message("<span class='notice'>[user] tries to open \the [src] with their [hand_string], struggling greatly to open the heavy door by themselves.</span>", \
				"<span class='notice'> You try with all your strength to pry open \the [src] with your [hand_string], barely moving it!</span>")
		else if (number_of_people_trying_to_open == 2)
			user.visible_message("<span class='notice'>[user.name] joins another in trying to open \the [src] with their [hand_string].</span>", \
				"<span class='notice'> You join another in trying to pry open \the [src] with your [hand_string]!</span>")
		else
			user.visible_message("<span class='notice'>[user] joins the others in trying to open \the [src] with their [hand_string]!</span>", \
				"<span class='notice'> You join the others in trying to pry open \the [src] with your [hand_string]!</span>")

		//burn arms in the do_after callback so that its applied continuosly instead of at the start and/or end
		var/datum/callback/burning_callback = CALLBACK(src, .proc/burn_arms, user)

		//this callback adjusts the timer of the do_after_dynamic for each user if the number of people trying to open the door changes
		var/datum/callback/timer_callback = CALLBACK(src, .proc/adjust_do_after_timer)

		///players can team up to open it faster, but only up to a point. 20 seconds -> 13.333 -> 8.88
		var/true_opening_time = TOOLLESS_OPEN_DURATION_SOLO / max((min(3, number_of_people_trying_to_open) * 0.75), 1)

		if(do_after_dynamic(user, true_opening_time, src, extra_checks = burning_callback, dynamic_timer_change = timer_callback))
			user.visible_message("<span class='notice'>[user] opens \the [src] with their [hand_string].</span>", \
				"<span class='notice'>You pry open \the [src] with your [hand_string]!</span>")
			log_game("[key_name(user)] has successfully opened a firelock with their bare hands [number_of_people_trying_to_open > 1 ? "along with [number_of_people_trying_to_open - 1] others" : ""], starting at [starting_health] health and ending at [user.health].")
			open()

		else if(user.stat != CONSCIOUS)
			var/stat_string = "fallen into soft crit"
			switch(user.stat)
				if(UNCONSCIOUS)
					stat_string = "fallen unconscious"
				if(HARD_CRIT)
					stat_string = "fallen into hard crit"
				if(DEAD)
					stat_string = "died"

			log_game("[key_name(user)] has failed to open a firelock with their bare hands [number_of_people_trying_to_open > 1 ? "along with [number_of_people_trying_to_open - 1] others" : ""] because they have [stat_string]. they were trying to open the door for [(REALTIMEOFDAY - starting_time) / 10] seconds")

		number_of_people_trying_to_open = max(0, --number_of_people_trying_to_open)
		user.move_resist = initial(user.move_resist)

/obj/machinery/door/firedoor/attack_paw(mob/living/user, list/modifiers)
	. = ..()
	if(!user.combat_mode)
		attack_hand(user, modifiers)

///deals burn damage to the user depending on whether theyre resistant to heat and how hot the door is, used as a callback in do_after
/obj/machinery/door/firedoor/proc/burn_arms(mob/living/user)
	. = TRUE //we dont want to interrupt the do_after

	//figure out how "hot" the door is with the temperature of the turf we are on and the user touching us, remember we dont conduct heat
	var/heat_of_contact_surface = max(return_air(), user.return_air())

	if(heat_of_contact_surface < MINIMUM_TEMPERATURE_TO_BURN_ARMS)
		return

	var/heat_protected = FALSE
	if(HAS_TRAIT(user, TRAIT_RESISTHEAT) || HAS_TRAIT(user, TRAIT_RESISTHEATHANDS))
		heat_protected = TRUE

	if(!iscarbon(user))
		if(!heat_protected)
			user.adjustFireLoss(0.2, forced = TRUE)
		return

	var/mob/living/carbon/user_as_carbon = user

	if(user_as_carbon.gloves)
		var/obj/item/clothing/gloves/gloves_of_user = user_as_carbon.gloves

		if(gloves_of_user.max_heat_protection_temperature)
			heat_protected = heat_protected ? TRUE : (gloves_of_user.max_heat_protection_temperature >= heat_of_contact_surface)

	if(!heat_protected)
		var/obj/item/bodypart/right_arm = user_as_carbon.get_bodypart(BODY_ZONE_R_ARM)
		var/obj/item/bodypart/left_arm = user_as_carbon.get_bodypart(BODY_ZONE_L_ARM)

		if(prob(10))
			playsound(user_as_carbon, 'sound/effects/wounds/sizzle1.ogg', 70)

		if(right_arm && right_arm.status == BODYPART_ORGANIC && !right_arm.is_pseudopart)
			right_arm.receive_damage(0, pick(0.1, 0.2))
		if(left_arm && left_arm.status == BODYPART_ORGANIC && !left_arm.is_pseudopart)
			left_arm.receive_damage(0, pick(0.1, 0.2))

///used in a callback given to do_after_dynamic to adjust the timer based on how many people are trying to open it barehanded
/obj/machinery/door/firedoor/proc/adjust_do_after_timer(old_delay, multiplicative_action_slowdown)
	if(old_delay == (TOOLLESS_OPEN_DURATION_SOLO / max((min(3, number_of_people_trying_to_open) * 0.5), 1)) * multiplicative_action_slowdown)
		return null
	else
		return (TOOLLESS_OPEN_DURATION_SOLO / max((min(3, number_of_people_trying_to_open) * 0.5), 1)) * multiplicative_action_slowdown

/obj/machinery/door/firedoor/proc/decrement_bare_hand_openers(datum/source)
	SIGNAL_HANDLER
	number_of_people_trying_to_open = max(0, --number_of_people_trying_to_open)

/obj/machinery/door/firedoor/attackby(obj/item/C, mob/user, params)
	add_fingerprint(user)
	if(operating)
		return
	if(welded)
		if(C.tool_behaviour == TOOL_WRENCH)
			if(boltslocked)
				to_chat(user, "<span class='notice'>There are screws locking the bolts in place!</span>")
				return
			C.play_tool_sound(src)
			user.visible_message("<span class='notice'>[user] starts undoing [src]'s bolts...</span>", \
				"<span class='notice'>You start unfastening [src]'s floor bolts...</span>")
			if(!C.use_tool(src, user, DEFAULT_STEP_TIME))
				return
			playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, TRUE)
			user.visible_message("<span class='notice'>[user] unfastens [src]'s bolts.</span>", \
				"<span class='notice'>You undo [src]'s floor bolts.</span>")
			deconstruct(TRUE)
			return
		if(C.tool_behaviour == TOOL_SCREWDRIVER)
			user.visible_message("<span class='notice'>[user] [boltslocked ? "unlocks" : "locks"] [src]'s bolts.</span>", \
				"<span class='notice'>You [boltslocked ? "unlock" : "lock"] [src]'s floor bolts.</span>")
			C.play_tool_sound(src)
			boltslocked = !boltslocked
			return
	return ..()

/obj/machinery/door/firedoor/try_to_activate_door(mob/user)
	return

/obj/machinery/door/firedoor/try_to_weld(obj/item/weldingtool/W, mob/user)
	if(!W.tool_start_check(user, amount=0))
		return
	user.visible_message("<span class='notice'>[user] starts [welded ? "unwelding" : "welding"] [src].</span>", "<span class='notice'>You start welding [src].</span>")
	if(W.use_tool(src, user, DEFAULT_STEP_TIME, volume=50))
		welded = !welded
		to_chat(user, "<span class='danger'>[user] [welded?"welds":"unwelds"] [src].</span>", "<span class='notice'>You [welded ? "weld" : "unweld"] [src].</span>")
		log_game("[key_name(user)] [welded ? "welded":"unwelded"] firedoor [src] with [W] at [AREACOORD(src)]")
		update_appearance()

/obj/machinery/door/firedoor/try_to_crowbar(obj/item/I, mob/user)
	if(welded || operating)
		return

	if(density)
		if(number_of_people_trying_to_open)
			user.visible_message("<span class='notice'>[user] easily opens \the [src] with his crowbar.</span>")
			log_game("[key_name(user)] used a crowbar to open a firedoor when [number_of_people_trying_to_open] people were trying to open it with their hands")
			number_of_people_trying_to_open = 0
		else
			log_game("[key_name(user)] opened a firelock with a crowbar, like a coward")
		open()
	else
		close()

/obj/machinery/door/firedoor/attack_ai(mob/user)
	add_fingerprint(user)
	if(welded || operating || machine_stat & NOPOWER)
		return TRUE
	if(density)
		open()
	else
		close()
	return TRUE

/obj/machinery/door/firedoor/attack_robot(mob/user)
	return attack_ai(user)

/obj/machinery/door/firedoor/attack_alien(mob/user, list/modifiers)
	add_fingerprint(user)
	if(welded)
		to_chat(user, "<span class='warning'>[src] refuses to budge!</span>")
		return
	open()

/obj/machinery/door/firedoor/do_animate(animation)
	switch(animation)
		if("opening")
			flick("door_opening", src)
		if("closing")
			flick("door_closing", src)

/obj/machinery/door/firedoor/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state]_[density ? "closed" : "open"]"

/obj/machinery/door/firedoor/update_overlays()
	. = ..()
	if(!welded)
		return
	. += density ? "welded" : "welded_open"

/obj/machinery/door/firedoor/open()
	. = ..()
	latetoggle()

/obj/machinery/door/firedoor/close()
	. = ..()
	latetoggle()

/obj/machinery/door/firedoor/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		var/turf/T = get_turf(src)
		if(disassembled || prob(40))
			var/obj/structure/firelock_frame/F = new assemblytype(T)
			if(disassembled)
				F.constructionStep = CONSTRUCTION_PANEL_OPEN
			else
				F.constructionStep = CONSTRUCTION_NO_CIRCUIT
				F.obj_integrity = F.max_integrity * 0.5
			F.update_appearance()
		else
			new /obj/item/electronics/firelock (T)
	qdel(src)


/obj/machinery/door/firedoor/proc/latetoggle()
	if(operating || machine_stat & NOPOWER || !nextstate)
		return
	switch(nextstate)
		if(FIREDOOR_OPEN)
			nextstate = null
			open()
		if(FIREDOOR_CLOSED)
			nextstate = null
			close()

/obj/machinery/door/firedoor/border_only
	icon = 'icons/obj/doors/edge_Doorfire.dmi'
	can_crush = FALSE
	flags_1 = ON_BORDER_1
	CanAtmosPass = ATMOS_PASS_PROC
	glass = FALSE

/obj/machinery/door/firedoor/border_only/closed
	icon_state = "door_closed"
	opacity = TRUE
	density = TRUE

/obj/machinery/door/firedoor/border_only/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(!(get_dir(loc, target) == dir)) //Make sure looking at appropriate border
		return TRUE

/obj/machinery/door/firedoor/border_only/CheckExit(atom/movable/mover as mob|obj, turf/target)
	if(get_dir(loc, target) == dir)
		return !density
	return TRUE

/obj/machinery/door/firedoor/border_only/CanAtmosPass(turf/T)
	if(get_dir(loc, T) == dir)
		return !density
	else
		return TRUE

/obj/machinery/door/firedoor/heavy
	name = "heavy firelock"
	icon = 'icons/obj/doors/Doorfire.dmi'
	glass = FALSE
	explosion_block = 2
	assemblytype = /obj/structure/firelock_frame/heavy
	max_integrity = 550


/obj/item/electronics/firelock
	name = "firelock circuitry"
	desc = "A circuit board used in construction of firelocks."
	icon_state = "mainboard"

/obj/structure/firelock_frame
	name = "firelock frame"
	desc = "A partially completed firelock."
	icon = 'icons/obj/doors/Doorfire.dmi'
	icon_state = "frame1"
	base_icon_state = "frame"
	anchored = FALSE
	density = TRUE
	var/constructionStep = CONSTRUCTION_NO_CIRCUIT
	var/reinforced = 0

/obj/structure/firelock_frame/examine(mob/user)
	. = ..()
	switch(constructionStep)
		if(CONSTRUCTION_PANEL_OPEN)
			. += "<span class='notice'>It is <i>unbolted</i> from the floor. The circuit could be removed with a <b>crowbar</b>.</span>"
			if(!reinforced)
				. += "<span class='notice'>It could be reinforced with plasteel.</span>"
		if(CONSTRUCTION_NO_CIRCUIT)
			. += "<span class='notice'>There are no <i>firelock electronics</i> in the frame. The frame could be <b>welded</b> apart .</span>"

/obj/structure/firelock_frame/update_icon_state()
	icon_state = "[base_icon_state][constructionStep]"
	return ..()

/obj/structure/firelock_frame/attackby(obj/item/C, mob/user)
	switch(constructionStep)
		if(CONSTRUCTION_PANEL_OPEN)
			if(C.tool_behaviour == TOOL_CROWBAR)
				C.play_tool_sound(src)
				user.visible_message("<span class='notice'>[user] begins removing the circuit board from [src]...</span>", \
					"<span class='notice'>You begin prying out the circuit board from [src]...</span>")
				if(!C.use_tool(src, user, DEFAULT_STEP_TIME))
					return
				if(constructionStep != CONSTRUCTION_PANEL_OPEN)
					return
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, TRUE)
				user.visible_message("<span class='notice'>[user] removes [src]'s circuit board.</span>", \
					"<span class='notice'>You remove the circuit board from [src].</span>")
				new /obj/item/electronics/firelock(drop_location())
				constructionStep = CONSTRUCTION_NO_CIRCUIT
				update_appearance()
				return
			if(C.tool_behaviour == TOOL_WRENCH)
				if(locate(/obj/machinery/door/firedoor) in get_turf(src))
					to_chat(user, "<span class='warning'>There's already a firelock there.</span>")
					return
				C.play_tool_sound(src)
				user.visible_message("<span class='notice'>[user] starts bolting down [src]...</span>", \
					"<span class='notice'>You begin bolting [src]...</span>")
				if(!C.use_tool(src, user, DEFAULT_STEP_TIME))
					return
				if(locate(/obj/machinery/door/firedoor) in get_turf(src))
					return
				user.visible_message("<span class='notice'>[user] finishes the firelock.</span>", \
					"<span class='notice'>You finish the firelock.</span>")
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, TRUE)
				if(reinforced)
					new /obj/machinery/door/firedoor/heavy(get_turf(src))
				else
					new /obj/machinery/door/firedoor(get_turf(src))
				qdel(src)
				return
			if(istype(C, /obj/item/stack/sheet/plasteel))
				var/obj/item/stack/sheet/plasteel/P = C
				if(reinforced)
					to_chat(user, "<span class='warning'>[src] is already reinforced.</span>")
					return
				if(P.get_amount() < 2)
					to_chat(user, "<span class='warning'>You need more plasteel to reinforce [src].</span>")
					return
				user.visible_message("<span class='notice'>[user] begins reinforcing [src]...</span>", \
					"<span class='notice'>You begin reinforcing [src]...</span>")
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, TRUE)
				if(do_after(user, DEFAULT_STEP_TIME, target = src))
					if(constructionStep != CONSTRUCTION_PANEL_OPEN || reinforced || P.get_amount() < 2 || !P)
						return
					user.visible_message("<span class='notice'>[user] reinforces [src].</span>", \
						"<span class='notice'>You reinforce [src].</span>")
					playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, TRUE)
					P.use(2)
					reinforced = 1
				return
		if(CONSTRUCTION_NO_CIRCUIT)
			if(istype(C, /obj/item/electronics/firelock))
				user.visible_message("<span class='notice'>[user] starts adding [C] to [src]...</span>", \
					"<span class='notice'>You begin adding a circuit board to [src]...</span>")
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, TRUE)
				if(!do_after(user, DEFAULT_STEP_TIME, target = src))
					return
				if(constructionStep != CONSTRUCTION_NO_CIRCUIT)
					return
				qdel(C)
				user.visible_message("<span class='notice'>[user] adds a circuit to [src].</span>", \
					"<span class='notice'>You insert and secure [C].</span>")
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, TRUE)
				constructionStep = CONSTRUCTION_PANEL_OPEN
				return
			if(C.tool_behaviour == TOOL_WELDER)
				if(!C.tool_start_check(user, amount=1))
					return
				user.visible_message("<span class='notice'>[user] begins cutting apart [src]'s frame...</span>", \
					"<span class='notice'>You begin slicing [src] apart...</span>")

				if(C.use_tool(src, user, DEFAULT_STEP_TIME, volume=50, amount=1))
					if(constructionStep != CONSTRUCTION_NO_CIRCUIT)
						return
					user.visible_message("<span class='notice'>[user] cuts apart [src]!</span>", \
						"<span class='notice'>You cut [src] into metal.</span>")
					var/turf/T = get_turf(src)
					new /obj/item/stack/sheet/iron(T, 3)
					if(reinforced)
						new /obj/item/stack/sheet/plasteel(T, 2)
					qdel(src)
				return
			if(istype(C, /obj/item/electroadaptive_pseudocircuit))
				var/obj/item/electroadaptive_pseudocircuit/P = C
				if(!P.adapt_circuit(user, DEFAULT_STEP_TIME * 0.5))
					return
				user.visible_message("<span class='notice'>[user] fabricates a circuit and places it into [src].</span>", \
				"<span class='notice'>You adapt a firelock circuit and slot it into the assembly.</span>")
				constructionStep = CONSTRUCTION_PANEL_OPEN
				update_appearance()
				return
	return ..()

/obj/structure/firelock_frame/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if(the_rcd.mode == RCD_DECONSTRUCT)
		return list("mode" = RCD_DECONSTRUCT, "delay" = 50, "cost" = 16)
	else if((constructionStep == CONSTRUCTION_NO_CIRCUIT) && (the_rcd.upgrade & RCD_UPGRADE_SIMPLE_CIRCUITS))
		return list("mode" = RCD_UPGRADE_SIMPLE_CIRCUITS, "delay" = 20, "cost" = 1)
	return FALSE

/obj/structure/firelock_frame/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	switch(passed_mode)
		if(RCD_UPGRADE_SIMPLE_CIRCUITS)
			user.visible_message("<span class='notice'>[user] fabricates a circuit and places it into [src].</span>", \
			"<span class='notice'>You adapt a firelock circuit and slot it into the assembly.</span>")
			constructionStep = CONSTRUCTION_PANEL_OPEN
			update_appearance()
			return TRUE
		if(RCD_DECONSTRUCT)
			to_chat(user, "<span class='notice'>You deconstruct [src].</span>")
			qdel(src)
			return TRUE
	return FALSE

/obj/structure/firelock_frame/heavy
	name = "heavy firelock frame"
	reinforced = TRUE

#undef TOOLLESS_OPEN_DURATION_SOLO
#undef MINIMUM_TEMPERATURE_TO_BURN_ARMS
#undef CONSTRUCTION_PANEL_OPEN
#undef CONSTRUCTION_NO_CIRCUIT
