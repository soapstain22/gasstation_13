SUBSYSTEM_DEF(atoms)
	name = "Atoms"
	init_order = INIT_ORDER_ATOMS
	flags = SS_NO_FIRE

	var/old_initialized
	/// A count of how many initalize changes we've made. We want to prevent old_initialize being overriden by some other value, breaking init code
	var/initialized_changed = 0

	var/list/late_loaders = list()

	var/list/BadInitializeCalls = list()

	///initAtom() adds the atom its creating to this list iff InitializeAtoms() has been given a list to populate as an argument
	var/list/created_atoms

	/// Atoms that will be deleted once the subsystem is initialized
	var/list/queued_deletions = list()

	var/init_start_time

	#ifdef PROFILE_MAPLOAD_INIT_ATOM
	var/list/mapload_init_times = list()
	#endif

	initialized = INITIALIZATION_INSSATOMS

/datum/controller/subsystem/atoms/Initialize()
	init_start_time = world.time
	setupGenetics() //to set the mutations' sequence

	initialized = INITIALIZATION_INNEW_MAPLOAD
	InitializeAtoms()
	initialized = INITIALIZATION_INNEW_REGULAR

	return SS_INIT_SUCCESS

/datum/controller/subsystem/atoms/proc/InitializeAtoms(list/atoms, list/atoms_to_return)
	if(initialized == INITIALIZATION_INSSATOMS)
		return

	set_tracked_initalized(INITIALIZATION_INNEW_MAPLOAD)

	// This may look a bit odd, but if the actual atom creation runtimes for some reason, we absolutely need to set initialized BACK
	CreateAtoms(atoms, atoms_to_return)
	clear_tracked_initalize()

	if(late_loaders.len)
		for(var/I in 1 to late_loaders.len)
			var/atom/A = late_loaders[I]
			//I hate that we need this
			if(QDELETED(A))
				continue
			A.LateInitialize()
		testing("Late initialized [late_loaders.len] atoms")
		late_loaders.Cut()

	if (created_atoms)
		atoms_to_return += created_atoms
		created_atoms = null

	for (var/queued_deletion in queued_deletions)
		qdel(queued_deletion)

	testing("[queued_deletions.len] atoms were queued for deletion.")
	queued_deletions.Cut()

	#ifdef PROFILE_MAPLOAD_INIT_ATOM
	rustg_file_write(json_encode(mapload_init_times), "[GLOB.log_directory]/init_times.json")
	#endif

/// Actually creates the list of atoms. Exists soley so a runtime in the creation logic doesn't cause initalized to totally break
/datum/controller/subsystem/atoms/proc/CreateAtoms(list/atoms, list/atoms_to_return = null)
	if (atoms_to_return)
		LAZYINITLIST(created_atoms)

	#ifdef TESTING
	var/count
	#endif

	var/list/mapload_arg = list(TRUE)

	if(atoms)
		#ifdef TESTING
		count = atoms.len
		#endif

		for(var/I in 1 to atoms.len)
			var/atom/A = atoms[I]
			if(!(A.flags_1 & INITIALIZED_1))
				CHECK_TICK
				PROFILE_INIT_ATOM_BEGIN()
				InitAtom(A, TRUE, mapload_arg)
				PROFILE_INIT_ATOM_END(A)
	else
		#ifdef TESTING
		count = 0
		#endif

		for(var/atom/A as anything in world)
			if(!(A.flags_1 & INITIALIZED_1))
				PROFILE_INIT_ATOM_BEGIN()
				InitAtom(A, FALSE, mapload_arg)
				PROFILE_INIT_ATOM_END(A)
				#ifdef TESTING
				++count
				#endif
				CHECK_TICK

	testing("Initialized [count] atoms")

/// Init this specific atom
/datum/controller/subsystem/atoms/proc/InitAtom(atom/A, from_template = FALSE, list/arguments)
	var/the_type = A.type

	if(QDELING(A))
		// Check init_start_time to not worry about atoms created before the atoms SS that are cleaned up before this
		if (A.gc_destroyed > init_start_time)
			BadInitializeCalls[the_type] |= BAD_INIT_QDEL_BEFORE
		return TRUE

	// This is handled and battle tested by dreamchecker. Limit to UNIT_TESTS just in case that ever fails.
	#ifdef UNIT_TESTS
	var/start_tick = world.time
	#endif

	var/result = A.Initialize(arglist(arguments))

	#ifdef UNIT_TESTS
	if(start_tick != world.time)
		BadInitializeCalls[the_type] |= BAD_INIT_SLEPT
	#endif

	var/qdeleted = FALSE

	switch(result)
		if (INITIALIZE_HINT_NORMAL)
			// pass
		if(INITIALIZE_HINT_LATELOAD)
			if(arguments[1]) //mapload
				late_loaders += A
			else
				A.LateInitialize()
		if(INITIALIZE_HINT_QDEL)
			qdel(A)
			qdeleted = TRUE
		else
			BadInitializeCalls[the_type] |= BAD_INIT_NO_HINT

	if(!A) //possible harddel
		qdeleted = TRUE
	else if(!(A.flags_1 & INITIALIZED_1))
		BadInitializeCalls[the_type] |= BAD_INIT_DIDNT_INIT
	else
		SEND_SIGNAL(A,COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZE)
		if(created_atoms && from_template && ispath(the_type, /atom/movable))//we only want to populate the list with movables
			created_atoms += A.get_all_contents()

	return qdeleted || QDELING(A)

/datum/controller/subsystem/atoms/proc/map_loader_begin()
	set_tracked_initalized(INITIALIZATION_INSSATOMS)

/datum/controller/subsystem/atoms/proc/map_loader_stop()
	clear_tracked_initalize()

/// Use this to set initialized to prevent error states where old_initialized is overriden. It keeps happening and it's cheesing me off
/datum/controller/subsystem/atoms/proc/set_tracked_initalized(value)
	if(!initialized_changed)
		old_initialized = initialized
		initialized = value
	else
		stack_trace("We started maploading while we were already maploading. You doing something odd?")
	initialized_changed += 1

/datum/controller/subsystem/atoms/proc/clear_tracked_initalize()
	initialized_changed -= 1
	if(!initialized_changed)
		initialized = old_initialized

/// Returns TRUE if anything is currently being initialized
/datum/controller/subsystem/atoms/proc/initializing_something()
	return initialized_changed > 0

/datum/controller/subsystem/atoms/Recover()
	initialized = SSatoms.initialized
	if(initialized == INITIALIZATION_INNEW_MAPLOAD)
		InitializeAtoms()
	old_initialized = SSatoms.old_initialized
	BadInitializeCalls = SSatoms.BadInitializeCalls

/datum/controller/subsystem/atoms/proc/setupGenetics()
	var/list/mutations = subtypesof(/datum/mutation/human)
	shuffle_inplace(mutations)
	for(var/A in subtypesof(/datum/generecipe))
		var/datum/generecipe/GR = A
		GLOB.mutation_recipes[initial(GR.required)] = initial(GR.result)
	for(var/i in 1 to LAZYLEN(mutations))
		var/path = mutations[i] //byond gets pissy when we do it in one line
		var/datum/mutation/human/B = new path ()
		B.alias = "Mutation [i]"
		GLOB.all_mutations[B.type] = B
		GLOB.full_sequences[B.type] = generate_gene_sequence(B.blocks)
		GLOB.alias_mutations[B.alias] = B.type
		if(B.locked)
			continue
		if(B.quality == POSITIVE)
			GLOB.good_mutations |= B
		else if(B.quality == NEGATIVE)
			GLOB.bad_mutations |= B
		else if(B.quality == MINOR_NEGATIVE)
			GLOB.not_good_mutations |= B
		CHECK_TICK

/datum/controller/subsystem/atoms/proc/InitLog()
	. = ""
	for(var/path in BadInitializeCalls)
		. += "Path : [path] \n"
		var/fails = BadInitializeCalls[path]
		if(fails & BAD_INIT_DIDNT_INIT)
			. += "- Didn't call atom/Initialize(mapload)\n"
		if(fails & BAD_INIT_NO_HINT)
			. += "- Didn't return an Initialize hint\n"
		if(fails & BAD_INIT_QDEL_BEFORE)
			. += "- Qdel'd in New()\n"
		if(fails & BAD_INIT_SLEPT)
			. += "- Slept during Initialize()\n"

/// Prepares an atom to be deleted once the atoms SS is initialized.
/datum/controller/subsystem/atoms/proc/prepare_deletion(atom/target)
	if (initialized == INITIALIZATION_INNEW_REGULAR)
		// Atoms SS has already completed, just kill it now.
		qdel(target)
	else
		queued_deletions += WEAKREF(target)

/datum/controller/subsystem/atoms/Shutdown()
	var/initlog = InitLog()
	if(initlog)
		text2file(initlog, "[GLOB.log_directory]/initialize.log")
