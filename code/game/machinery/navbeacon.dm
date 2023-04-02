// Navigation beacon for AI robots
// No longer exists on the radio controller, it is managed by a global list.

/obj/machinery/navbeacon

	icon = 'icons/obj/objects.dmi'
	icon_state = "navbeacon0"
	name = "navigation beacon"
	desc = "A radio beacon used for bot navigation."
	layer = LOW_OBJ_LAYER
	max_integrity = 500
	armor_type = /datum/armor/machinery_navbeacon
	circuit = /obj/item/circuitboard/machine/navbeacon

	/// true if controls are locked
	var/locked = TRUE
	/// location response text
	var/location = ""
	/// associative list of transponder codes
	var/list/codes
	/// codes as set on map: "tag1;tag2" or "tag1=value;tag2=value"
	var/codes_txt = ""

	req_one_access = list(ACCESS_ENGINEERING, ACCESS_ROBOTICS)

/datum/armor/machinery_navbeacon
	melee = 70
	bullet = 70
	laser = 70
	energy = 70
	fire = 80
	acid = 80

/obj/machinery/navbeacon/Initialize(mapload)
	. = ..()

	set_codes()

	glob_lists_register(init=TRUE)

	AddElement(/datum/element/undertile, TRAIT_T_RAY_VISIBLE)

/obj/machinery/navbeacon/Destroy()
	glob_lists_deregister()
	return ..()

/obj/machinery/navbeacon/on_changed_z_level(turf/old_turf, turf/new_turf, same_z_layer, notify_contents)
	if (GLOB.navbeacons["[old_turf?.z]"])
		GLOB.navbeacons["[old_turf?.z]"] -= src
	if (GLOB.navbeacons["[new_turf?.z]"])
		GLOB.navbeacons["[new_turf?.z]"] += src
	return ..()

/obj/machinery/navbeacon/on_construction(mob/user)
	var/turf/our_turf = loc
	if(!isfloorturf(our_turf))
		return
	var/turf/open/floor/floor = our_turf
	floor.remove_tile(null, silent = TRUE, make_tile = TRUE, force_plating = TRUE)


///Set the transponder codes assoc list from codes_txt during initialization
/obj/machinery/navbeacon/proc/set_codes()

	codes = list()

	if(!codes_txt)
		return

	var/list/entries = splittext(codes_txt, ";") // entries are separated by semicolons

	for(var/entry in entries)
		var/index = findtext(entry, "=") // format is "key=value"
		if(index)
			var/key = copytext(entry, 1, index)
			var/val = copytext(entry, index + length(entry[index]))
			codes[key] = val
		else
			codes[entry] = "[TRUE]"

///Removes the nav beacon from the global beacon lists
/obj/machinery/navbeacon/proc/glob_lists_deregister()
	if (GLOB.navbeacons["[z]"])
		GLOB.navbeacons["[z]"] -= src //Remove from beacon list, if in one.
	GLOB.deliverybeacons -= src
	GLOB.deliverybeacontags -= location

///Registers the navbeacon to the global beacon lists
/obj/machinery/navbeacon/proc/glob_lists_register(init=FALSE)
	if(!init)
		glob_lists_deregister()
	if(!codes)
		return
	if(codes[NAVBEACON_PATROL_MODE])
		if(!GLOB.navbeacons["[z]"])
			GLOB.navbeacons["[z]"] = list()
		GLOB.navbeacons["[z]"] += src //Register with the patrol list!
	if(codes[NAVBEACON_DELIVERY_MODE])
		GLOB.deliverybeacons += src
		GLOB.deliverybeacontags += location

/obj/machinery/navbeacon/crowbar_act(mob/living/user, obj/item/I)
	if(default_deconstruction_crowbar(I))
		return TRUE

/obj/machinery/navbeacon/screwdriver_act(mob/living/user, obj/item/tool)
	return default_deconstruction_screwdriver(user, "navbeacon1","navbeacon0",tool)

/obj/machinery/navbeacon/attackby(obj/item/I, mob/user, params)
	var/turf/our_turf = loc
	if(our_turf.underfloor_accessibility < UNDERFLOOR_INTERACTABLE)
		return // prevent intraction when T-scanner revealed

	if (isidcard(I) || istype(I, /obj/item/modular_computer/pda))
		if(!panel_open)
			if (allowed(user))
				locked = !locked
				balloon_alert(user, "controls [locked ? "locked" : "unlocked"]")
				SStgui.update_uis(src)
			else
				balloon_alert(user, "access denied")
		else
			balloon_alert(user, "panel open!")
		return

	return ..()

/obj/machinery/navbeacon/attack_ai(mob/user)
	interact(user)

/obj/machinery/navbeacon/attack_paw(mob/user, list/modifiers)
	return

/obj/machinery/navbeacon/ui_interact(mob/user, datum/tgui/ui)
	. = ..()

	var/turf/our_turf = loc
	if(our_turf.underfloor_accessibility < UNDERFLOOR_INTERACTABLE)
		return // prevent intraction when T-scanner revealed

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NavBeacon")
		ui.set_autoupdate(FALSE)
		ui.open()

/obj/machinery/navbeacon/ui_data(mob/user)
	var/list/data = list()
	data["location"] = location
	data["locked"] = locked
	data["silicon_user"] = issilicon(user)
	data["patrol_enabled"] = codes[NAVBEACON_PATROL_MODE] ? TRUE : FALSE
	data["patrol_next"] = codes[NAVBEACON_PATROL_NEXT]
	data["delivery_enabled"] = codes[NAVBEACON_DELIVERY_MODE] ? TRUE : FALSE
	data["delivery_direction"] = codes[NAVBEACON_DELIVERY_DIRECTION]
	return data

/obj/machinery/navbeacon/ui_act(action, params)
	. = ..()
	if(.)
		return

	if(locked && !issilicon(usr))
		return

	switch(action)
		if("toggle_patrol")
			toggle_code(NAVBEACON_PATROL_MODE)
			return TRUE
		if("toggle_delivery")
			toggle_code(NAVBEACON_DELIVERY_MODE)
			return TRUE
		if("change_location")
			var/input_text = tgui_input_text(usr, "Enter this Beacon's location tag", "Beacon Location", location, 20)
			if (!input_text || location == input_text)
				return
			GLOB.deliverybeacontags -= location
			location = input_text
			GLOB.deliverybeacontags += input_text
			return TRUE
		if("change_patrol_next")
			var/next_patrol = codes[NAVBEACON_PATROL_NEXT]
			var/input_text = tgui_input_text(usr, "Enter the tag of the next patrol location", "Beacon Location", next_patrol, 20)
			if (!input_text || location == input_text)
				return
			codes[NAVBEACON_PATROL_NEXT] = input_text
			return TRUE
		if("change_delivery_direction")
			var/delivery_direction = codes[NAVBEACON_DELIVERY_DIRECTION]
			var/input_text = tgui_input_text(usr, "Enter the direction the M.U.L.E. will deposit their crate", "Beacon Direction", delivery_direction, 20)
			if (!input_text || location == input_text)
				return
			codes[NAVBEACON_DELIVERY_DIRECTION] = input_text
			return TRUE

///Adds or removes a specific code
/obj/machinery/navbeacon/proc/toggle_code(code)
	if(codes[code])
		codes.Remove(code)
	else
		codes[code]="[TRUE]"
	glob_lists_register()
