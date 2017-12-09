// Used to manage the Hullrot process.

SUBSYSTEM_DEF(hullrot)
	name = "Hullrot"
	priority = 25
	flags = SS_BACKGROUND
	wait = 2
	init_order = -50  // Very late initialize

	var/const/dll = "hullrot.dll"
	var/const/expected_major = 0  // Major version must be exactly this
	var/const/expected_minor = 0  // Minor version must be at least this
	var/loaded_version  // For VV inspection

	var/currently_playing = -1
	var/checked_events = FALSE

// ----------------------------------------------------------------------------
// Initialization

/datum/controller/subsystem/hullrot/Initialize()
	// Load the DLL and check the version
	var/list/version = get_version()
	if (version == null)
		return abort("[name] could not be loaded and has been disabled.")
	if (version["error"])
		return abort("[name] version check failed: [version["error"]].")
	if (version["major"] != expected_major || version["minor"] < expected_minor)
		return abort("[name] [expected_major].[expected_minor] was expected, but incompatible [version["version"]] was supplied.")
	loaded_version = version["version"]

	var/list/res = debug_decode(call(dll, "hullrot_init")())
	var/error = res["error"] || res["Fatal"] || res["Debug"]
	if (error)
		return abort("[name] failed to initialize: [error]")

	return ..()

/datum/controller/subsystem/hullrot/proc/get_version()
	return debug_decode(call(dll, "hullrot_dll_version")())

// ----------------------------------------------------------------------------
// Shutdown

/datum/controller/subsystem/hullrot/Shutdown()
	if (loaded_version)
		loaded_version = null
		call(dll, "hullrot_stop")()

// because the DLL starts a thread, we have to make *extra* sure to join it
/world/Del()
	if (SShullrot)
		SShullrot.Shutdown()
	..()

// ----------------------------------------------------------------------------
// General processing

/datum/controller/subsystem/hullrot/proc/abort(msg)
	log_world(msg)
	to_chat(world, "<span class='boldannounce'>[msg]</span>")
	can_fire = FALSE

/datum/controller/subsystem/hullrot/proc/debug_decode(result)
	if (result != "\[\]")
		log_world(result)
	return json_decode(result)

/datum/controller/subsystem/hullrot/proc/warn(msg)
	message_admins("[name] warning: [msg]")

/datum/controller/subsystem/hullrot/proc/control(what, data)
	checked_events = TRUE
	var/events
	if (what)
		events = debug_decode(call(dll, "hullrot_control")(json_encode(list("[what]" = data))))
	else
		events = debug_decode(call(dll, "hullrot_control")())
	for (var/event in events)
		message_admins("[name]: event: [json_encode(event)]")
		if ((data = event["Fatal"]))
			abort("Hullrot has crashed: [data]")
		else if ((data = event["Debug"]))
			warn(data)

/datum/controller/subsystem/hullrot/fire()
	checked_events = FALSE

	var/new_playing = (SSticker.current_state == GAME_STATE_PLAYING)
	if (new_playing != currently_playing)
		control("Playing", new_playing)
		currently_playing = new_playing

	if (!checked_events)
		control()

// ----------------------------------------------------------------------------
// Admin management

/datum/controller/subsystem/hullrot/proc/reconnect()
	message_admins("Admin [key_name_admin(usr)] is restarting [name].")
	Shutdown()
	can_fire = TRUE
	currently_playing = initial(currently_playing)  // force a resend
	Initialize(REALTIMEOFDAY)
