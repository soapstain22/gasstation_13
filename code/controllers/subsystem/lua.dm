//world/proc/shelleo
#define SHELLEO_ERRORLEVEL 1
#define SHELLEO_STDOUT 2
#define SHELLEO_STDERR 3

#define SSLUA_INIT_FAILED 2

SUBSYSTEM_DEF(lua)
	name = "Lua Scripting"
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT
	wait = 0.1 SECONDS

	/// A list of all lua states
	var/list/datum/lua_state/states = list()

	/// A list of open editors, with each key in the list associated with a list of editors
	var/list/editors

	var/list/sleeps = list()
	var/list/resumes = list()

	var/list/current_run = list()

	/// Protects return values from getting GCed before getting converted to lua values
	var/gc_guard

	/// Auxtools runs procs as usr = null. We use this to proxy `usr` whenever its relevant.
	var/mob/lua_usr

/datum/controller/subsystem/lua/Initialize(start_timeofday)
	try
		AUXTOOLS_CHECK(AUXLUA)
		__lua_set_set_var_wrapper("/proc/wrap_lua_set_var")
		__lua_set_datum_proc_call_wrapper("/proc/wrap_lua_datum_proc_call")
		__lua_set_global_proc_call_wrapper("/proc/wrap_lua_global_proc_call")
		var/here = world.shelleo(world.system_type == MS_WINDOWS ? "cd" : "pwd")[SHELLEO_STDOUT]
		here = replacetext(here, "\n", "")
		var/last_char = copytext_char(here, -1)
		if(last_char != "/" && last_char != "\\")
			here += "/"
		var/list/lua_path = list()
		var/list/config_paths = CONFIG_GET(str_list/lua_path)
		for(var/path in config_paths)
			if(path[1] != "/")
				path = here + path
			lua_path += path
		world.SetConfig("env", "LUAU_PATH", jointext(lua_path, ";"))
		return ..()
	catch(var/exception/e)
		initialized = SSLUA_INIT_FAILED
		can_fire = FALSE
		var/time = (REALTIMEOFDAY - start_timeofday) / 10
		var/msg = "Failed to initialize [name] subsystem after [time] seconds!"
		to_chat(world, span_boldwarning("[msg]"))
		warning(e.name)
		return time

/datum/controller/subsystem/lua/Shutdown()
	AUXTOOLS_SHUTDOWN(AUXLUA)

/datum/controller/subsystem/lua/proc/queue_resume(datum/lua_state/state, index, arguments)
	if(initialized != TRUE)
		return
	if(!istype(state))
		return
	if(!arguments)
		arguments = list()
	else if(!islist(arguments))
		arguments = list(arguments)
	resumes += list(list("state" = state, "index" = index, "arguments" = arguments))

/datum/controller/subsystem/lua/proc/kill_task(datum/lua_state/state, list/task_info)
	if(!istype(state))
		return
	if(!islist(task_info))
		return
	if(!(istext(task_info["name"]) && istext(task_info["status"]) && isnum(task_info["index"])))
		return
	switch(task_info["status"])
		if("sleep")
			var/task_index = task_info["index"]
			var/state_index = 1
			for(var/i in 1 to length(sleeps))
				var/datum/lua_state/sleeping_state = sleeps[i]
				if(sleeping_state == state)
					if(state_index == task_index)
						sleeps.Cut(i, i+1)
						break
					state_index++
		if("yield")
			for(var/i in 1 to length(resumes))
				var/resume = resumes[i]
				if(resume["state"] == state && resume["index"] == task_info["index"])
					resumes.Cut(i, i+1)
					break
	state.kill_task(task_info)

/datum/controller/subsystem/lua/fire(resumed)
	if(!resumed)
		current_run = list("sleeps" = sleeps.Copy(), "resumes" = resumes.Copy())
		sleeps.Cut()
		resumes.Cut()

	var/list/current_sleeps = current_run["sleeps"]
	var/list/affected_states = list()
	while(length(current_sleeps))
		var/datum/lua_state/state = current_sleeps[1]
		current_sleeps.Cut(1,2)
		if(!istype(state))
			continue
		affected_states |= state
		state.awaken()

		if(MC_TICK_CHECK)
			break

	if(!length(current_sleeps))
		var/list/current_resumes = current_run["resumes"]
		while(length(current_resumes))
			var/list/resume_params = current_resumes[1]
			current_resumes.Cut(1,2)
			var/datum/lua_state/state = resume_params["state"]
			if(!istype(state))
				continue
			var/index = resume_params["index"]
			if(isnull(index) || !isnum(index))
				continue
			var/arguments = resume_params["arguments"]
			if(!islist(arguments))
				continue
			affected_states |= state
			state.resume(arglist(list(index) + arguments))

			if(MC_TICK_CHECK)
				break

	for(var/state in affected_states)
		var/list/editor_list = editors["\ref[state]"]
		if(editor_list)
			for(var/datum/lua_editor/editor in editor_list)
				SStgui.update_uis(editor)

//world/proc/shelleo
#undef SHELLEO_ERRORLEVEL
#undef SHELLEO_STDOUT
#undef SHELLEO_STDERR

#undef SSLUA_INIT_FAILED
