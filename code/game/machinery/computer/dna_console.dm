#define INJECTOR_TIMEOUT 100
#define NUMBER_OF_BUFFERS 3
#define SCRAMBLE_TIMEOUT 600
#define JOKER_TIMEOUT 12000				//20 minutes
#define JOKER_UPGRADE 3000

#define RADIATION_STRENGTH_MAX 15
#define RADIATION_STRENGTH_MULTIPLIER 1			//larger has more range

#define RADIATION_DURATION_MAX 30
#define RADIATION_ACCURACY_MULTIPLIER 3			//larger is less accurate

#define RADIATION_IRRADIATION_MULTIPLIER 1		//multiplier for how much radiation a test subject receives

#define SCANNER_ACTION_SE 1
#define SCANNER_ACTION_UI 2
#define SCANNER_ACTION_UE 3
#define SCANNER_ACTION_MIXED 4

#define SEARCH_OCCUPANT 1
#define SEARCH_STORED 2
#define SEARCH_DISKETTE 4
#define SEARCH_ADV_INJ 8

//----------------------------------------------------------------------------//
// START TGUI CONSOLE STATE DEFINES                                           //
//----------------------------------------------------------------------------//
// STATE IDENTIFIERS
#define STATE_BASE 1
#define STATE_ST 2
#define STATE_STC 3
#define STATE_STCM 4
#define STATE_STCC 5
#define STATE_STD 6
#define STATE_STDM 7
#define STATE_GS 8

// BASE CONSOLE STATES
// STORAGE
#define TGUI_MODE_ST 1
// SEQUENCER
#define TGUI_MODE_SEQ 2
// ENZYMES
#define TGUI_MODE_ENZ 3
// ADVANCED INJECTORS
#define TGUI_MODE_ADV 4

// STORAGE STATES
// STORAGE > CONSOLE
#define TGUI_ST_CO 1
// STORAGE > DISK
#define TGUI_ST_DI 2

// STORAGE (CONSOLE/DISK) STATES
// STORAGE > MUTATIONS
#define TGUI_ST_MUT 1
// STORAGE > CHROMOSOMES
#define TGUI_ST_CHR 2
// STORAGE > GENETICS
#define TGUI_ST_GEN 3

// STORAGE (MUTATIONS) STATES
// STORAGE > MUTATIONS > INFO
#define TGUI_ST_M_INFO 1
// STORAGE > MUTATIONS > COMBINATION
#define TGUI_ST_M_COMB 2
// STORAGE > MUTATIONS > COMMANDS
#define TGUI_ST_M_COMM 3

// GENE SEQUENCER STATES
#define TGUI_GS_INFO 1
#define TGUI_GS_COMM 2


//----------------------------------------------------------------------------//
// END TGUI CONSOLE STATE DEFINES                                             //
//----------------------------------------------------------------------------//


/obj/machinery/computer/scan_consolenew
	name = "DNA Console"
	desc = "Scan DNA."
	icon_screen = "dna"
	icon_keyboard = "med_key"
	density = TRUE
	circuit = /obj/item/circuitboard/computer/scan_consolenew

	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	active_power_usage = 400
	light_color = LIGHT_COLOR_BLUE

	// TGUI State stuff
	// Console state
	// state

	// Console > Storage state
	// state_st

	// Console > Storage > Console state
	// state_stc

	// Console > Storage > Console > Mutation state
	// state_stcm
	// state_stcm_index

	// Console > Storage > Console > Chromosome state
	// state_stcc_index

	// Console > Storage > Disk state
	// state_std

	// Console > Storage > Disk > Mutation state
	// state_stdm
	// state_stdm_index
	var/list/list/state = list(
		STATE_BASE = list("mode" = TGUI_MODE_ST),
		STATE_ST = list("mode" = TGUI_ST_CO),
		STATE_STC = list("mode" = TGUI_ST_MUT),
		STATE_STCM = list("mode" = TGUI_ST_M_INFO, "index" = 1),
		STATE_STCC = list("index" = 1),
		STATE_STD = list("mode" = TGUI_ST_MUT),
		STATE_STDM = list("mode" = TGUI_ST_M_INFO, "index" = 1),
		STATE_GS = list("mode" = TGUI_GS_INFO, "index" = 1)
	)

	var/list/cheekystate
	var/list/cheekystatelist

	var/datum/techweb/stored_research
	var/max_storage = 6
	var/combine
	var/radduration = 2
	var/radstrength = 1
	var/max_chromosomes = 6
	///Amount of UI/UEs we can store
	var/list/genetic_makeup_buffer[NUMBER_OF_BUFFERS]
	///mutations we have stored
	var/list/stored_mutations = list()
	///chromosomes we have stored
	var/list/stored_chromosomes = list()
	///combinations of injectors for the 'injector selection'. format is list("Elsa" = list(Cryokinesis, Geladikinesis), "The Hulk" = list(Hulk, Gigantism), etc) Glowy and the gang being an initialized datum
	var/list/list/injector_selection = list()
	///max amount of selections you can make
	var/max_injector_selections = 2
	///hard-cap on the advanced dna injector
	var/max_injector_mutations = 10
	///the max instability of the advanced injector.
	var/max_injector_instability = 50

	var/list/genes = list("A","T","G","C","X")
	var/list/reversegenes = list("X","C","G","T","A")

	var/injectorready = 0	//world timer cooldown var
	var/jokerready = 0
	var/scrambleready = 0

	var/obj/item/disk/data/diskette = null

	var/list/delayed_action = null

	var/rad_pulse_index = 0
	var/rad_pulse_timer = 0

	var/can_use_scanner = FALSE
	var/is_viable_occupant = FALSE
	var/is_scramble_ready = FALSE
	var/is_joker_ready = FALSE
	var/is_injector_ready = FALSE
	var/is_pulsing_rads = FALSE
	var/time_to_scramble = 0
	var/time_to_joker = 0
	var/time_to_injector = 0
	var/time_to_pulse = 0
	var/obj/machinery/dna_scannernew/connected_scanner = null
	var/mob/living/carbon/scanner_occupant = null
	var/list/tgui_occupant_mutations = list()
	var/list/tgui_scanner_mutations = list()
	var/list/tgui_diskette_mutations = list()
	var/list/tgui_scanner_chromosomes = list()
	var/list/tgui_genetic_makeup = list()
	var/list/tgui_advinjector_mutations = list()
	var/list/list/tgui_state = list()

/obj/machinery/computer/scan_consolenew/process()
	. = ..()

	// This is for pulsing the UI element with radiation as part of genetic makeup
	// If rad_pulse_index > 0 then it means we're attempting a rad pulse
	if((rad_pulse_index > 0) && (rad_pulse_timer <= world.time))
		rad_pulse()
		return

	// TODO - Periodically check the connected DNA Scanner. Is it still there?
	//  Is it still operational? Should we disconnect from it for any reason?

/obj/machinery/computer/scan_consolenew/attackby(obj/item/I, mob/user, params)
	// Store chromosomes in the console if there's room
	if (istype(I, /obj/item/chromosome))
		if(LAZYLEN(stored_chromosomes) < max_chromosomes)
			I.forceMove(src)
			stored_chromosomes += I
			to_chat(user, "<span class='notice'>You insert [I].</span>")
		else
			to_chat(user, "<span class='warning'>You cannot store any more chromosomes!</span>")
		return

	// Insert data disk if console disk slot is empty
	// Swap data disk if there is one already a disk in the console
	if (istype(I, /obj/item/disk/data)) //INSERT SOME DISKETTES
		if (!user.transferItemToLoc(I,src))
			return
		if(diskette)
			diskette.forceMove(drop_location())
			diskette = null
		diskette = I
		to_chat(user, "<span class='notice'>You insert [I].</span>")
		return

	// Recycle non-activator used injectors
	// Turn activator used injectors (aka research injectors) to chromosomes
	if(istype(I, /obj/item/dnainjector/activator))
		var/obj/item/dnainjector/activator/A = I
		if(A.used)
			to_chat(user,"<span class='notice'>Recycled [I].</span>")
			if(A.research)
				if(prob(60))
					var/c_typepath = generate_chromosome()
					var/obj/item/chromosome/CM = new c_typepath (drop_location())
					if(LAZYLEN(stored_chromosomes) < max_chromosomes)
						CM.forceMove(src)
						stored_chromosomes += CM
						to_chat(user,"<span class='notice'>[capitalize(CM.name)] added to storage.</span>")
					else
						to_chat(user, "<span class='warning'>You cannot store any more chromosomes!</span>")
						to_chat(user, "<span class='notice'>[capitalize(CM.name)] added on top of the console.</span>")
				else
					to_chat(user, "<span class='notice'>There was not enough genetic data to extract a viable chromosome.</span>")
			qdel(I)
			return

	return ..()

/obj/machinery/computer/scan_consolenew/Initialize()
	. = ..()

	// Connect with a nearby DNA Scanner on init
	connect_to_scanner()

	// Set appropriate ready timers and limits for machines functions
	injectorready = world.time + INJECTOR_TIMEOUT
	scrambleready = world.time + SCRAMBLE_TIMEOUT
	jokerready = world.time + JOKER_TIMEOUT

	// Init default states
	tgui_state = list(
		"Storage" = list(
			"Console" = list(
				"Mutation" = list(),
				"Chromo" = list()
			),
			"Disk" = list(
				"Mutation" = list()
			)
		),
		"Sequencer" = list()
	)

	// Link machine with research techweb. Used for discovering and accessing
	//  already discovered mutations
	stored_research = SSresearch.science_tech

/obj/machinery/computer/scan_consolenew/examine(mob/user)
	. = ..()

/obj/machinery/computer/scan_consolenew/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = 0, datum/tgui/master_ui = null, datum/ui_state/state = GLOB.default_state)
	. = ..()

	// Most of ui_interact is spent setting variables for passing to the tgui
	//  interface.
	// We can also do some general state processing here too as it's a good
	//  indication that a player is using the console.

	// EFFICIENCY - Memory/performance tradeoff. Declaring some early vars for
	//  commonly used checks.
	var/scanner_op = scanner_operational()
	var/can_modify_occ = can_modify_occupant()

	// Check for connected AND operational scanner.
	if(scanner_op)
		can_use_scanner = TRUE
	else
		can_use_scanner = FALSE
		connected_scanner = null
		is_viable_occupant = FALSE

	// Check for a viable occupant in the scanner.
	if(can_modify_occ)
		is_viable_occupant = TRUE
	else
		is_viable_occupant = FALSE


	// Populates various buffers for passing to tgui
	build_mutation_list(can_modify_occ)
	build_genetic_makeup_list()
	build_state_list()

	// Populate variables for passing to tgui interface
	is_scramble_ready = (scrambleready < world.time)
	time_to_scramble = round((scrambleready - world.time)/10)

	is_joker_ready = (jokerready < world.time)
	time_to_joker = round((jokerready - world.time)/10)

	is_injector_ready = (injectorready < world.time)
	time_to_injector = round((injectorready - world.time)/10)

	is_pulsing_rads = ((rad_pulse_index > 0) && (rad_pulse_timer > world.time))
	time_to_pulse = round((rad_pulse_timer - world.time)/10)

	// Attempt to update tgui ui, open and update if needed.
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)

	if(!ui)
		ui = new(user, src, ui_key, "scan_consolenew", name, 660, 800, master_ui, state)
		ui.open()

/obj/machinery/computer/scan_consolenew/ui_data(mob/user)
	var/list/data = list()

	data["State"] = tgui_state

	// This block of code generates the huge data structure passed to the tgui
	//  interface for displaying all the various bits of console/scanner data
	// Should all be very self-explanatory
	data["IsScannerConnected"] = can_use_scanner
	if(can_use_scanner)
		data["ScannerOpen"] = connected_scanner.state_open
		data["ScannerLocked"] = connected_scanner.locked
		data["RadStrength"] = radstrength
		data["RadDuration"] = radduration
		data["StdDevStr"] = radstrength*RADIATION_STRENGTH_MULTIPLIER
		switch(RADIATION_ACCURACY_MULTIPLIER/(radduration + (connected_scanner.precision_coeff ** 2)))	//hardcoded values from a z-table for a normal distribution
			if(0 to 0.25)
				data["StdDevAcc"] = ">95 %"
			if(0.25 to 0.5)
				data["StdDevAcc"] = "68-95 %"
			if(0.5 to 0.75)
				data["StdDevAcc"] = "55-68 %"
			else
				data["StdDevAcc"] = "<38 %"

	data["IsViableSubject"] = is_viable_occupant
	if(is_viable_occupant)
		data["SubjectName"] = scanner_occupant.name
		data["SubjectStatus"] = scanner_occupant.stat
		data["SubjectHealth"] = scanner_occupant.health
		data["SubjectRads"] = scanner_occupant.radiation/(RAD_MOB_SAFE/100)
		data["SubjectEnzymes"] = scanner_occupant.dna.unique_enzymes
		data["IsMonkey"] = ismonkey(scanner_occupant)

		var/text_sequence = scanner_occupant.dna.uni_identity
		var/list/list_sequence = list()

		for(var/i in 1 to LAZYLEN(text_sequence))
			list_sequence += text_sequence[i];

		data["SubjectUNI"] = text_sequence
		data["SubjectUNIList"] = list_sequence
		data["SubjectMutations"] = tgui_occupant_mutations
	else
		data["SubjectName"] = null
		data["SubjectStatus"] = null
		data["SubjectHealth"] = null
		data["SubjectRads"] = null
		data["SubjectEnzymes"] = null
		data["SubjectMutations"] = null

	data["HasDelayedAction"] = (delayed_action != null)
	data["IsScrambleReady"] = is_scramble_ready
	data["IsJokerReady"] = is_joker_ready
	data["IsInjectorReady"] = is_injector_ready
	data["ScrambleSeconds"] = time_to_scramble
	data["JokerSeconds"] = time_to_joker
	data["InjectorSeconds"] = time_to_injector
	data["IsPulsingRads"] = is_pulsing_rads
	data["RadPulseSeconds"] = time_to_pulse

	if(diskette != null)
		data["HasDisk"] = TRUE
		data["DiskCapacity"] = diskette.max_mutations - LAZYLEN(diskette.mutations)
		data["DiskReadOnly"] = diskette.read_only
		data["DiskMutations"] = tgui_diskette_mutations
		data["DiskHasMakeup"] = (LAZYLEN(diskette.genetic_makeup_buffer) > 0)
		data["DiskMakeupBuffer"] = diskette.genetic_makeup_buffer.Copy()
	else
		data["HasDisk"] = FALSE
		data["DiskCapacity"] = 0
		data["DiskReadOnly"] = TRUE
		data["DiskMutations"] = null
		data["DiskHasMakeup"] = FALSE
		data["DiskMakeupBuffer"] = null

	data["MutationCapacity"] = max_storage - LAZYLEN(stored_mutations)
	data["MutationStorage"] = tgui_scanner_mutations
	data["ChromoCapacity"] = max_chromosomes - LAZYLEN(stored_chromosomes)
	data["ChromoStorage"] = tgui_scanner_chromosomes
	data["MakeupCapcity"] = NUMBER_OF_BUFFERS
	data["MakeupStorage"] = tgui_genetic_makeup

	data["AdvInjectors"] = tgui_advinjector_mutations
	data["MaxAdvInjectors"] = max_injector_selections

	// These are effectively DEFINES/constants
	data["CONSCIOUS"] = CONSCIOUS
	data["SOFT_CRIT"] = SOFT_CRIT
	data["UNCONSCIOUS"] = UNCONSCIOUS
	data["DEAD"] = DEAD
	data["GENES"] = genes
	data["REVERSEGENES"] = reversegenes
	data["CHROMOSONE_NEVER"] = CHROMOSOME_NEVER
	data["CHROMOSOME_NONE"] = CHROMOSOME_NONE
	data["CHROMOSOME_USED"] = CHROMOSOME_USED
	data["MUT_NORMAL"] = MUT_NORMAL
	data["MUT_EXTRA"] = MUT_EXTRA
	data["MUT_OTHER"] = MUT_OTHER
	data["RADIATION_DURATION_MAX"] = RADIATION_DURATION_MAX
	data["RADIATION_STRENGTH_MAX"] = RADIATION_STRENGTH_MAX
	data["DNA_BLOCK_SIZE"] = DNA_BLOCK_SIZE

	return data

/obj/machinery/computer/scan_consolenew/ui_act(action, var/list/params)
	if(..())
		return TRUE

	. = TRUE

	add_fingerprint(usr)
	usr.set_machine(src)

	switch(action)
		// Connect this DNA Console to a nearby DNA Scanner
		// Usually only activate as an option if there is no connected scanner
		if("connect_scanner")
			connect_to_scanner()
			return

		// Toggle the door open/closed status on attached DNA Scanner
		if("toggle_door")
			// GUARD CHECK - Scanner still connected and operational?
			if(!scanner_operational())
				return

			connected_scanner.toggle_open(usr)
			return

		// Toggle the door bolts on the attached DNA Scanner
		if("toggle_lock")
			// GUARD CHECK - Scanner still connected and operational?
			if(!scanner_operational())
				return

			connected_scanner.locked = !connected_scanner.locked
			return

		// Scramble scanner occupant's DNA
		if("scramble_dna")
			// GUARD CHECK - Can we genetically modify the occupant? Includes scanner
			//  operational guard checks.
			// GUARD CHECK - Is scramble DNA actually ready?
			if(!can_modify_occupant() || !(scrambleready < world.time))
				return

			scanner_occupant.dna.remove_all_mutations(list(MUT_NORMAL, MUT_EXTRA))
			scanner_occupant.dna.generate_dna_blocks()
			scrambleready = world.time + SCRAMBLE_TIMEOUT
			to_chat(usr,"<span class='notice'>DNA scrambled.</span>")
			scanner_occupant.radiation += RADIATION_STRENGTH_MULTIPLIER*50/(connected_scanner.damage_coeff ** 2)
			return

		// Check whether a specific mutation is eligible for discovery within the
		//  scanner occupant
		// This is additionally done when a mutation's tab is selected in the tgui
		//  interface. This is because some mutations, such as Monkified on monkeys,
		//  are infact completed by default but not yet discovered. Likewise, all
		//  mutations can have their sequence completed while Monkified is still an
		//  active mutation and thus won't immediately be discovered but could be
		//  discovered when Monkified is removed
		// ---------------------------------------------------------------------- //
		// params["alias"] - Alias of a mutation. The alias is the "hidden" name of
		//                   the mutation, for example "Mutation 5" or "Mutation 33"
		if("check_discovery")
			// GUARD CHECK - Can we genetically modify the occupant? Includes scanner
			//  operational guard checks.
			if(!can_modify_occupant())
				return

			// GUARD CHECK - Have we somehow cheekily swapped occupants? This is
			//  unexpected.
			if(!(scanner_occupant == connected_scanner.occupant))
				return

			check_discovery(params["alias"])
			return

		// Check all mutations of the occupant and check if any are discovered.
		// This is called when the Genetic Sequencer is selected. It'll do things
		//  like immediately discover Monkified without needing to click through
		//  the mutation tabs and handle cases where mutations are solved but not
		//  discovered due to the Monkified mutation being active then removed.
		if("all_check_discovery")
			// GUARD CHECK - Can we genetically modify the occupant? Includes scanner
			//  operational guard checks.
			if(!can_modify_occupant())
				return

			// GUARD CHECK - Have we somehow cheekily swapped occupants? This is
			//  unexpected.
			if(!(scanner_occupant == connected_scanner.occupant))
				return

			// Go over all standard mutations and check if they've been discovered.
			for(var/mutation_type in scanner_occupant.dna.mutation_index)
				var/datum/mutation/human/HM = GET_INITIALIZED_MUTATION(mutation_type)
				check_discovery(HM.alias)

			return

		// Set a gene in a mutation's genetic sequence. Will also check for mutations
		//  discovery as part of the process.
		// ---------------------------------------------------------------------- //
		// params["alias"] - Alias of a mutation. The alias is the "hidden" name of
		//  the mutation, for example "Mutation 5" or "Mutation 33"
		// params["gene"] - The letter of the new gene
		// params["pos"] - The BYOND index of the letter in the gene sequence to be
		//  changed. Expects a text string from TGUI and will convert to a number
		if("pulse_gene")
			// GUARD CHECK - Can we genetically modify the occupant? Includes scanner
			//  operational guard checks.
			if(!can_modify_occupant())
				return

			// GUARD CHECK - Have we somehow cheekily swapped occupants? This is
			//  unexpected.
			if(!(scanner_occupant == connected_scanner.occupant))
				return

			// Resolve mutation's BYOND path from the alias
			var/alias = params["alias"]
			var/path = GET_MUTATION_TYPE_FROM_ALIAS(alias)

			// Make sure the occupant still has this mutation
			if(!(path in scanner_occupant.dna.mutation_index))
				return

			// Resolve BYOND path to genome sequence of scanner occupant
			var/sequence = GET_GENE_STRING(path, scanner_occupant.dna)

			var/newgene = params["gene"]
			var/genepos = text2num(params["pos"])

			// If the new gene is J, this means we're dealing with a JOKER
			// GUARD CHECK - Is JOKER actually ready?
			if((newgene == "J") && (jokerready < world.time))
				var/truegenes = GET_SEQUENCE(path)
				newgene = truegenes[genepos]
				jokerready = world.time + JOKER_TIMEOUT - (JOKER_UPGRADE * (connected_scanner.precision_coeff-1))

			// Copy genome to scanner occupant and do some basic mutation checks as
			//  we've increased the occupant rads
			sequence = copytext_char(sequence, 1, genepos) + newgene + copytext_char(sequence, genepos + 1)
			scanner_occupant.dna.mutation_index[path] = sequence
			scanner_occupant.radiation += RADIATION_STRENGTH_MULTIPLIER/connected_scanner.damage_coeff
			scanner_occupant.domutcheck()

			// GUARD CHECK - Modifying genetics can lead to edge cases where the
			//  scanner occupant is qdel'd and replaced with a different entity.
			//  Examples of this include adding/removing the Monkified mutation which
			//  qdels the previous entity and creates a brand new one in its place.
			// We should redo all of our occupant modification checks again, although
			//  it is less than ideal.
			if(!can_modify_occupant())
				return

			// Check if we cracked a mutation
			check_discovery(alias)

			return

		// Apply a chromosome to a specific mutation.
		// ---------------------------------------------------------------------- //
		// params["mutref"] - ATOM Ref of specific mutation to apply the chromo to
		// params["chromo"] - Name of the chromosome to apply to the mutation
		if("apply_chromo")
			// GUARD CHECK - Can we genetically modify the occupant? Includes scanner
			//  operational guard checks.
			if(!can_modify_occupant())
				return

			// GUARD CHECK - Have we somehow cheekily swapped occupants? This is
			//  unexpected.
			if(!(scanner_occupant == connected_scanner.occupant))
				return

			var/bref = params["mutref"]

			// GUARD CHECK - Only search occupant for this specific ref, since your
			//  can only apply chromosomes to mutations occupants.
			var/datum/mutation/human/HM = get_mut_by_ref(bref, SEARCH_OCCUPANT)

			// GUARD CHECK - This should not be possible. Unexpected result
			if(!HM)
				return

			// Look through our stored chromos and compare names to find a
			// stored chromo we can apply.
			for(var/obj/item/chromosome/CM in stored_chromosomes)
				if(CM.can_apply(HM) && (CM.name == params["chromo"]))
					stored_chromosomes -= CM
					CM.apply(HM)

			return

		// Print any type of standard injector, limited right now to activators that
		//  activate a dormant mutation and mutators that forcibly create a new
		//  MUT_EXTRA mutation
		// ---------------------------------------------------------------------- //
		// params["mutref"] - ATOM Ref of specific mutation to create an injector of
		// params["is_activator"] - Is this an "Activator" style injector, also
		//  referred to as a "Research" type. Expects a string with 0 or 1, which
		//  then gets converted to a number.
		// params["source"] - The source the request came from.
		//	Expected results:
		//   "sequencer" - From genetic sequencer
		//   "console" - From DNA Console storage
		//   "disk" - From inserted diskette
		if("print_injector")
			// Because printing mutators and activators share a bunch of code,
			//  it makes sense to keep them both together and set unique vars
			//  later in the code

			// As a side note, because mutations can contain unique metadata,
			//  this system uses BYOND Atom Refs to safely and accurately
			//  identify mutations from big ol' lists

			// GUARD CHECK - Is the injector actually ready?
			if(world.time < injectorready)
				return

			var/search_flags = 0

			switch(params["source"])
				if("sequencer")
					// GUARD CHECK - Make sure we can modify the occupant before we
					//  attempt to search them for any given mutation refs. This could
					//  lead to no search flags being passed to get_mut_by_ref and this
					//  is intended functionality to prevent any cheese or abuse
					if(can_modify_occupant())
						search_flags |= SEARCH_OCCUPANT
				if("console")
					search_flags |= SEARCH_STORED
				if("disk")
					search_flags |= SEARCH_DISKETTE

			var/bref = params["mutref"]
			var/datum/mutation/human/HM = get_mut_by_ref(bref, search_flags)

			// GUARD CHECK - This should not be possible. Unexpected result
			if(!HM)
				return

			// Create a new DNA Injector and add the appropriate mutations to it
			var/obj/item/dnainjector/activator/I = new /obj/item/dnainjector/activator(loc)
			I.add_mutations += new HM.type(copymut = HM)

			var/is_activator = text2num(params["is_activator"])

			// Activators are also called "research" injectors and are used to create
			//  chromosomes by recycling at the DNA Console
			if(is_activator)
				I.name = "[HM.name] activator"
				I.research = TRUE
				// If there's an operational connected scanner, we can use its upgrades
				//  to improve our injector's radiation generation
				if(scanner_operational())
					I.damage_coeff = connected_scanner.damage_coeff*4
					injectorready = world.time + INJECTOR_TIMEOUT * (1 - 0.1 * connected_scanner.precision_coeff)
				else
					injectorready = world.time + INJECTOR_TIMEOUT
			else
				I.name = "[HM.name] mutator"
				I.doitanyway = TRUE
				// If there's an operational connected scanner, we can use its upgrades
				//  to improve our injector's radiation generation
				if(scanner_operational())
					I.damage_coeff = connected_scanner.damage_coeff
					injectorready = world.time + INJECTOR_TIMEOUT * 5 * (1 - 0.1 * connected_scanner.precision_coeff)
				else
					injectorready = world.time + INJECTOR_TIMEOUT * 5

			return

		// Save a mutation to the console's storage buffer.
		// ---------------------------------------------------------------------- //
		// params["mutref"] - ATOM Ref of specific mutation to store
		// params["source"] - The source the request came from.
		//	Expected results:
		//   "sequencer" - From genetic sequencer
		//   "disk" - From inserted diskette
		if("save_console")
			var/search_flags = 0

			switch(params["source"])
				if("sequencer")
					// GUARD CHECK - Make sure we can modify the occupant before we
					//  attempt to search them for any given mutation refs. This could
					//  lead to no search flags being passed to get_mut_by_ref and this
					//  is intended functionality to prevent any cheese or abuse
					if(can_modify_occupant())
						search_flags |= SEARCH_OCCUPANT
				if("disk")
					search_flags |= SEARCH_DISKETTE

			// GUARD CHECK - Is mutation storage full?
			if(LAZYLEN(stored_mutations) >= max_storage)
				to_chat(usr,"<span class='warning'>Mutation storage is full.</span>")
				return

			var/bref = params["mutref"]
			var/datum/mutation/human/HM = get_mut_by_ref(bref, search_flags)

			// GUARD CHECK - This should not be possible. Unexpected result
			if(!HM)
				return

			var/datum/mutation/human/A = new HM.type()
			A.copy_mutation(HM)
			stored_mutations += A
			to_chat(usr,"<span class='notice'>Mutation successfully stored.</span>")
			return

		// Save a mutation to the diskette's storage buffer.
		// ---------------------------------------------------------------------- //
		// params["mutref"] - ATOM Ref of specific mutation to store
		// params["source"] - The source the request came from
		//	Expected results:
		//   "sequencer" - From genetic sequencer
		//   "console" - From DNA Console storage
		if("save_disk")
			// GUARD CHECK - This code shouldn't even be callable without a diskette
			//  inserted. Unexpected result
			if(!diskette)
				return

			// GUARD CHECK - Make sure the disk is not full
			if(LAZYLEN(diskette.mutations) >= diskette.max_mutations)
				to_chat(usr,"<span class='warning'>Disk storage is full.</span>")
				return

			// GUARD CHECK - Make sure the disk isn't set to read only, as we're
			//  attempting to write to it
			if(diskette.read_only)
				to_chat(usr,"<span class='warning'>Disk is set to read only mode.</span>")
				return

			var/search_flags = 0

			switch(params["source"])
				if("sequencer")
					// GUARD CHECK - Make sure we can modify the occupant before we
					//  attempt to search them for any given mutation refs. This could
					//  lead to no search flags being passed to get_mut_by_ref and this
					//  is intended functionality to prevent any cheese or abuse
					if(can_modify_occupant())
						search_flags |= SEARCH_OCCUPANT
				if("console")
					search_flags |= SEARCH_STORED

			var/bref = params["mutref"]
			var/datum/mutation/human/HM = get_mut_by_ref(bref, search_flags)

			// GUARD CHECK - This should not be possible. Unexpected result
			if(!HM)
				return

			var/datum/mutation/human/A = new HM.type()
			A.copy_mutation(HM)
			diskette.mutations += A
			to_chat(usr,"<span class='notice'>Mutation successfully stored to disk.</span>")
			return

		// Completely removes a MUT_EXTRA mutation or mutation with corrupt gene
		//  sequence from the scanner occupant
		// ---------------------------------------------------------------------- //
		// params["mutref"] - ATOM Ref of specific mutation to nullify
		if("nullify")
			// GUARD CHECK - Can we genetically modify the occupant? Includes scanner
			//  operational guard checks.
			if(!can_modify_occupant())
				return

			var/bref = params["mutref"]
			var/datum/mutation/human/HM = get_mut_by_ref(bref, SEARCH_OCCUPANT)

			// GUARD CHECK - This should not be possible. Unexpected result
			if(!HM)
				return

			// GUARD CHECK - Nullify should only be used on scrambled or "extra"
			//  mutations.
			if(!HM.scrambled && !(HM.class == MUT_EXTRA))
				return

			scanner_occupant.dna.remove_mutation(HM.type)
			return

		// Deletes saved mutation from console buffer.
		// ---------------------------------------------------------------------- //
		// params["mutref"] - ATOM Ref of specific mutation to delete
		if("delete_console_mut")
			var/bref = params["mutref"]
			var/datum/mutation/human/HM = get_mut_by_ref(bref, SEARCH_STORED)

			if(HM)
				stored_mutations.Remove(HM)
				qdel(HM)

			return

		// Deletes saved mutation from disk buffer.
		// ---------------------------------------------------------------------- //
		// params["mutref"] - ATOM Ref of specific mutation to delete
		if("delete_disk_mut")
			// GUARD CHECK - This code shouldn't even be callable without a diskette
			//  inserted. Unexpected result
			if(!diskette)
				return

			// GUARD CHECK - Make sure the disk isn't set to read only, as we're
			//  attempting to write to it (via deletion)
			if(diskette.read_only)
				to_chat(usr,"<span class='warning'>Disk is set to read only mode.</span>")
				return

			var/bref = params["mutref"]
			var/datum/mutation/human/HM = get_mut_by_ref(bref, SEARCH_DISKETTE)

			if(HM)
				diskette.mutations.Remove(HM)
				qdel(HM)

			return

		// Ejects a stored chromosome from the DNA Console
		// ---------------------------------------------------------------------- //
		// params["chromo"] - Text string of the chromosome name
		if("eject_chromo")
			var/chromname = params["chromo"]

			for(var/obj/item/chromosome/CM in stored_chromosomes)
				if(chromname == CM.name)
					CM.forceMove(drop_location())
					adjust_item_drop_location(CM)
					stored_chromosomes -= CM
					return

			return

		// Combines two mutations from the console to try and create a new mutation
		// ---------------------------------------------------------------------- //
		// params["srctype"] - Text string of the BYOND type path for first mutation
		// params["desttype"] - Text string of the BYOND type path for the second
		//  mutation
		if("combine_console")
			// GUaRD CHECK - Make sure mutation storage isn't full. If it is, we won't
			//  be able to store the new combo mutation
			if(LAZYLEN(stored_mutations) >= max_storage)
				to_chat(usr,"<span class='warning'>Mutation storage is full.</span>")
				return

			// GUARD CHECK - We're running a research-type operation. If, for some
			// reason, somehow the DNA Console has been disconnected from the research
			// network - Or was never in it to begin with - don't proceed
			if(!stored_research)
				return

			// Attempt to mix the two mutations to get a new type
			var/result_path = get_mixed_mutation(params["srctype"], params["desttype"])

			if(!result_path)
				return

			// If we got a new type, add it to our storage
			stored_mutations += new result_path()
			to_chat(usr, "<span class='boldnotice'>Success! New mutation has been added to storage</span>")

			// If it's already discovered, end here. Otherwise, add it to the list of
			//  discovered mutations.
			// We've already checked for stored_research earlier
			if(result_path in stored_research.discovered_mutations)
				return

			stored_research.discovered_mutations += result_path
			return

		// Combines two mutations from the disk to try and create a new mutation
		// ---------------------------------------------------------------------- //
		// params["srctype"] - Text string of the BYOND type path for first mutation
		// params["desttype"] - Text string of the BYOND type path for the second
		//  mutation
		if("combine_disk")
			// GUARD CHECK - This code shouldn't even be callable without a diskette
			//  inserted. Unexpected result
			if(!diskette)
				return

			// GUARD CHECK - Make sure the disk is not full.
			if(LAZYLEN(diskette.mutations) >= diskette.max_mutations)
				to_chat(usr,"<span class='warning'>Disk storage is full.</span>")
				return

			// GUARD CHECK - Make sure the disk isn't set to read only, as we're
			//  attempting to write to it
			if(diskette.read_only)
				to_chat(usr,"<span class='warning'>Disk is set to read only mode.</span>")
				return

			// GUARD CHECK - We're running a research-type operation. If, for some
			// reason, somehow the DNA Console has been disconnected from the research
			// network - Or was never in it to begin with - don't proceed
			if(!stored_research)
				return

			// Attempt to mix the two mutations to get a new type
			var/result_path = get_mixed_mutation(params["srctype"], params["desttype"])

			if(!result_path)
				return

			// If we got a new type, add it to our storage
			diskette.mutations += new result_path()
			to_chat(usr, "<span class='boldnotice'>Success! New mutation has been added to the disk.</span>")

			// If it's already discovered, end here. Otherwise, add it to the list of
			//  discovered mutations
			// We've already checked for stored_research earlier
			if(result_path in stored_research.discovered_mutations)
				return

			stored_research.discovered_mutations += result_path
			return

		// Sets the Genetic Makeup pulse strength.
		// ---------------------------------------------------------------------- //
		// params["val"] - New strength value as text string, converted to number
		//  later on in code
		if("set_pulse_strength")
			var/value = round(text2num(params["val"]))
			radstrength = WRAP(value, 1, RADIATION_STRENGTH_MAX+1)
			return

		// Sets the Genetic Makeup pulse duration
		// ---------------------------------------------------------------------- //
		// params["val"] - New strength value as text string, converted to number
		//  later on in code
		if("set_pulse_duration")
			var/value = round(text2num(params["val"]))
			radduration = WRAP(value, 1, RADIATION_DURATION_MAX+1)
			return

		// Saves Genetic Makeup information to disk
		// ---------------------------------------------------------------------- //
		// params["index"] - The BYOND index of the console genetic makeup buffer to
		//  copy to disk
		if("save_makeup_disk")
			// GUARD CHECK - This code shouldn't even be callable without a diskette
			//  inserted. Unexpected result
			if(!diskette)
				return

			// GUARD CHECK - Make sure the disk isn't set to read only, as we're
			//  attempting to write to it
			if(diskette.read_only)
				to_chat(usr,"<span class='warning'>Disk is set to read only mode.</span>")
				return

			// Convert the index to a number and clamp within the array range
			var/buffer_index = text2num(params["index"])
			buffer_index = clamp(buffer_index, 1, NUMBER_OF_BUFFERS)

			var/list/buffer_slot = genetic_makeup_buffer[buffer_index]

			// GUARD CHECK - This should not be possible to activate on a buffer slot
			//  that doesn't have any genetic data. Unexpected result
			if(!istype(buffer_slot))
				return

			diskette.genetic_makeup_buffer = buffer_slot.Copy()
			return

		// Loads Genetic Makeup from disk to a console buffer
		// ---------------------------------------------------------------------- //
		// params["index"] - The BYOND index of the console genetic makeup buffer to
		//  copy to. Expected as text string, converted to number later
		if("load_makeup_disk")
			// GUARD CHECK - This code shouldn't even be callable without a diskette
			//  inserted. Unexpected result
			if(!diskette)
				return

			// GUARD CHECK - This should not be possible to activate on a diskette
			//  that doesn't have any genetic data. Unexpected result
			if(LAZYLEN(diskette.genetic_makeup_buffer) == 0)
				return

			// Convert the index to a number and clamp within the array range, then
			//  copy the data from the disk to that buffer
			var/buffer_index = text2num(params["index"])
			buffer_index = clamp(buffer_index, 1, NUMBER_OF_BUFFERS)
			genetic_makeup_buffer[buffer_index] = diskette.genetic_makeup_buffer.Copy()
			return

		// Deletes genetic makeup buffer from the inserted diskette
		if("del_makeup_disk")
			// GUARD CHECK - This code shouldn't even be callable without a diskette
			//  inserted. Unexpected result
			if(!diskette)
				return

			// GUARD CHECK - Make sure the disk isn't set to read only, as we're
			//  attempting to write (via deletion) to it
			if(diskette.read_only)
				to_chat(usr,"<span class='warning'>Disk is set to read only mode.</span>")
				return

			diskette.genetic_makeup_buffer.Cut()
			return

		// UNUSED
		/*
		// Modifies the label of a genetic makeup buffer entry
		// ---------------------------------------------------------------------- //
		// params["index"] - The BYOND index of the console genetic makeup buffer to
		//  modify the label of. Expected as text string, converted to number later
		// params["label"] - The new label to apply
		if("set_makeup_label")
			var/buffer_index = text2num(params["index"])
			buffer_index = clamp(buffer_index, 1, NUMBER_OF_BUFFERS)

			var/list/buffer_slot = genetic_makeup_buffer[buffer_index]

			// GUARD CHECK - This shouldn't be possible to execute this on a null
			//  buffer. Unexpected resut
			if(!istype(buffer_slot))
				return

			buffer_slot[buffer_index]["label"] = trim(sanitize(params["label"]))
			return
		*/

		// Saves the scanner occupant's genetic makeup to a given console buffer
		// ---------------------------------------------------------------------- //
		// params["index"] - The BYOND index of the console genetic makeup buffer to
		//  save the new genetic data to. Expected as text string, converted to
		//  number later
		if("save_makeup_console")
			// GUARD CHECK - Can we genetically modify the occupant? Includes scanner
			//  operational guard checks.
			if(!can_modify_occupant())
				return

			// Convert the index to a number and clamp within the array range, then
			//  copy the data from the disk to that buffer
			var/buffer_index = text2num(params["index"])
			buffer_index = clamp(buffer_index, 1, NUMBER_OF_BUFFERS)

			// Set the new information
			genetic_makeup_buffer[buffer_index] = list(
				"label"="Slot [buffer_index]:[scanner_occupant.real_name]",
				"UI"=scanner_occupant.dna.uni_identity,
				"UE"=scanner_occupant.dna.unique_enzymes,
				"name"=scanner_occupant.real_name,
				"blood_type"=scanner_occupant.dna.blood_type)

			return

		// Deleted genetic makeup data from a console buffer slot
		// ---------------------------------------------------------------------- //
		// params["index"] - The BYOND index of the console genetic makeup buffer to
		//  delete the genetic data from. Expected as text string, converted to
		//  number later
		if("del_makeup_console")
			// Convert the index to a number and clamp within the array range, then
			//  copy the data from the disk to that buffer
			var/buffer_index = text2num(params["index"])
			buffer_index = clamp(buffer_index, 1, NUMBER_OF_BUFFERS)
			var/list/buffer_slot = genetic_makeup_buffer[buffer_index]

			// GUARD CHECK - This shouldn't be possible to execute this on a null
			//  buffer. Unexpected resut
			if(!istype(buffer_slot))
				return

			genetic_makeup_buffer[buffer_index] = null
			return

		// Eject stored diskette from console
		if("eject_disk")
			// GUARD CHECK - This code shouldn't even be callable without a diskette
			//  inserted. Unexpected result
			if(!diskette)
				return

			diskette.forceMove(drop_location())
			diskette = null
			return

		// Create a Genetic Makeup injector. These injectors are timed and thus are
		//  only temporary
		// ---------------------------------------------------------------------- //
		// params["index"] - The BYOND index of the console genetic makeup buffer to
		//  create the makeup injector from. Expected as text string, converted to
		//  number later
		// params["type"] - Type of injector to create
		//  Expected results:
		//   "ue" - Unique Enzyme, changes name and blood type
		//	 "ui" - Unique Identity, changes looks
		//	 "mixed" - Combination of both ue and ui
		if("makeup_injector")
			// Convert the index to a number and clamp within the array range, then
			//  copy the data from the disk to that buffer
			var/buffer_index = text2num(params["index"])
			buffer_index = clamp(buffer_index, 1, NUMBER_OF_BUFFERS)
			var/list/buffer_slot = genetic_makeup_buffer[buffer_index]

			// GUARD CHECK - This shouldn't be possible to execute this on a null
			//  buffer. Unexpected resut
			if(!istype(buffer_slot))
				return

			var/type = params["type"]
			var/obj/item/dnainjector/timed/I

			switch(type)
				if("ui")
					// GUARD CHECK - There's currently no way to save partial genetic data.
					//  However, if this is the case, we can't make a complete injector and
					//  this catches that edge case
					if(!buffer_slot["UI"])
						to_chat(usr,"<span class='warning'>Genetic data corrupted, unable to create injector.</span>")
						return

					I = new /obj/item/dnainjector/timed(loc)
					I.fields = list("UI"=buffer_slot["UI"])

					// If there is a connected scanner, we can use its upgrades to reduce
					//  the radiation generated by this injector
					if(scanner_operational())
						I.damage_coeff = connected_scanner.damage_coeff
					return
				if("ue")
					// GUARD CHECK - There's currently no way to save partial genetic data.
					//  However, if this is the case, we can't make a complete injector and
					//  this catches that edge case
					if(!buffer_slot["name"] || !buffer_slot["UE"] || !buffer_slot["blood_type"])
						to_chat(usr,"<span class='warning'>Genetic data corrupted, unable to create injector.</span>")
						return

					I = new /obj/item/dnainjector/timed(loc)
					I.fields = list("name"=buffer_slot["name"], "UE"=buffer_slot["UE"], "blood_type"=buffer_slot["blood_type"])

					// If there is a connected scanner, we can use its upgrades to reduce
					//  the radiation generated by this injector
					if(scanner_operational())
						I.damage_coeff  = connected_scanner.damage_coeff
					return
				if("mixed")
					// GUARD CHECK - There's currently no way to save partial genetic data.
					//  However, if this is the case, we can't make a complete injector and
					//  this catches that edge case
					if(!buffer_slot["UI"] || !buffer_slot["name"] || !buffer_slot["UE"] || !buffer_slot["blood_type"])
						to_chat(usr,"<span class='warning'>Genetic data corrupted, unable to create injector.</span>")
						return

					I = new /obj/item/dnainjector/timed(loc)
					I.fields = list("UI"=buffer_slot["UI"],"name"=buffer_slot["name"], "UE"=buffer_slot["UE"], "blood_type"=buffer_slot["blood_type"])

					// If there is a connected scanner, we can use its upgrades to reduce
					//  the radiation generated by this injector
					if(scanner_operational())
						I.damage_coeff = connected_scanner.damage_coeff
					return

			// If we successfully created an injector, don't forget to set the new
			//  ready timer.
			if(I)
				injectorready = world.time + INJECTOR_TIMEOUT

			return

		// Applies a genetic makeup buffer to the scanner occupant
		// ---------------------------------------------------------------------- //
		// params["index"] - The BYOND index of the console genetic makeup buffer to
		//  apply to the scanner occupant. Expected as text string, converted to
		//  number later
		// params["type"] - Type of genetic makeup copy to implement
		//  Expected results:
		//   "ue" - Unique Enzyme, changes name and blood type
		//	 "ui" - Unique Identity, changes looks
		//	 "mixed" - Combination of both ue and ui
		if("makeup_apply")
			// GUARD CHECK - Can we genetically modify the occupant? Includes scanner
			//  operational guard checks.
			if(!can_modify_occupant())
				return

			// Convert the index to a number and clamp within the array range, then
			//  copy the data from the disk to that buffer
			var/buffer_index = text2num(params["index"])
			buffer_index = clamp(buffer_index, 1, NUMBER_OF_BUFFERS)
			var/list/buffer_slot = genetic_makeup_buffer[buffer_index]

			// GUARD CHECK - This shouldn't be possible to execute this on a null
			//  buffer. Unexpected resut
			if(!istype(buffer_slot))
				return

			var/type = params["type"]

			apply_genetic_makeup(type, buffer_slot)
			return

		// Applies a genetic makeup buffer to the next scanner occupant. This sets
		//  some code that will run when the connected DNA Scanner door is next
		//  closed
		// This allows people to self-modify their genetic makeup, as tgui
		//  interfaces can not be accessed while inside the DNA Scanner and genetic
		//  makeup injectors are only temporary
		// ---------------------------------------------------------------------- //
		// params["index"] - The BYOND index of the console genetic makeup buffer to
		//  apply to the scanner occupant. Expected as text string, converted to
		//  number later
		// params["type"] - Type of genetic makeup copy to implement
		//  Expected results:
		//   "ue" - Unique Enzyme, changes name and blood type
		//	 "ui" - Unique Identity, changes looks
		//	 "mixed" - Combination of both ue and ui
		if("makeup_delay")
			// Convert the index to a number and clamp within the array range, then
			//  copy the data from the disk to that buffer
			var/buffer_index = text2num(params["index"])
			buffer_index = clamp(buffer_index, 1, NUMBER_OF_BUFFERS)
			var/list/buffer_slot = genetic_makeup_buffer[buffer_index]

			// GUARD CHECK - This shouldn't be possible to execute this on a null
			//  buffer. Unexpected resut
			if(!istype(buffer_slot))
				return

			var/type = params["type"]

			// Set the delayed action. The next time the scanner door is closed,
			//  unless this is cancelled in the UI, the action will happen
			delayed_action = list("type" = type, "buffer_slot" = buffer_slot)
			return

		// Attempts to modify the indexed element of the Unique Identity string
		// This is a time delayed action that is handled in process()
		// ---------------------------------------------------------------------- //
		// params["index"] - The BYOND index of the Unique Identity string to
		//  attempt to modify
		if("makeup_pulse")
			// GUARD CHECK - Can we genetically modify the occupant? Includes scanner
			//  operational guard checks.
			if(!can_modify_occupant())
				return

			// Set the appropriate timer and index to pulse. This is then managed
			//  later on in process()
			var/len = length_char(scanner_occupant.dna.uni_identity)
			rad_pulse_timer = world.time + (radduration*10)
			rad_pulse_index = WRAP(text2num(params["index"]), 1, len+1)
			return

		// Cancels the delayed action - In this context it is not the radiation
		//  pulse from "makeup_pulse", which can not be cancelled. It is instead
		//  the delayed genetic transfer from "makeup_delay"
		if("cancel_delay")
			delayed_action = null
			return

		// Creates a new advanced injector storage buffer in the console
		// ---------------------------------------------------------------------- //
		// params["name"] - The name to apply to the new injector
		if("new_adv_inj")
			// GUARD CHECK - Make sure we can make a new injector. This code should
			//  not be called if we're already maxed out and this is an Unexpected
			//  result
			if(!(LAZYLEN(injector_selection) < max_injector_selections))
				return

			// GUARD CHECK - Sanitise and trim the proposed name. This prevents HTML
			//  injection and equivalent as tgui input is not stripped
			var/inj_name = params["name"]
			inj_name = trim(sanitize(inj_name))

			// GUARD CHECK - If the name is null or blank, or the name is already in
			//  the list of advanced injectors, we want to reject it as we can't have
			//  duplicate named advanced injectors
			if(!inj_name || (inj_name in injector_selection))
				return

			injector_selection[inj_name] = list()
			return

		// Deleted an advanced injector storage buffer from the console
		// ---------------------------------------------------------------------- //
		// params["name"] - The name of the injector to delete
		if("del_adv_inj")
			var/inj_name = params["name"]

			// GUARD CHECK - If the name is null or blank, reject.
			// GUARD CHECK - If the name isn't in the list of advanced injectors, we
			//  want to reject this as it shouldn't be possible ever do this.
			//	Unexpected result
			if(!inj_name || !(inj_name in injector_selection))
				return

			injector_selection.Remove(inj_name)
			return

		// Creates an injector from an advanced injector buffer
		// ---------------------------------------------------------------------- //
		// params["name"] - The name of the injector to print
		if("print_adv_inj")
			// As a side note, because mutations can contain unique metadata,
			// this system uses BYOND Atom Refs to safely and accurately
			// identify mutations from big ol' lists.

				// GUARD CHECK - Is the injector actually ready?
			if(world.time < injectorready)
				return

			var/inj_name = params["name"]

			// GUARD CHECK - If the name is null or blank, reject.
			// GUARD CHECK - If the name isn't in the list of advanced injectors, we
			//  want to reject this as it shouldn't be possible ever do this.
			//	Unexpected result
			if(!inj_name || !(inj_name in injector_selection))
				return

			var/list/injector = injector_selection[inj_name]
			var/obj/item/dnainjector/activator/I = new /obj/item/dnainjector/activator(loc)

			// Run through each mutation in our Advanced Injector and add them to a
			//  new injector
			for(var/A in injector)
				var/datum/mutation/human/HM = A
				I.add_mutations += new HM.type(copymut=HM)

			// Force apply any mutations, this is functionality similar to mutators
			I.doitanyway = TRUE
			I.name = "Advanced [inj_name] injector"

			// If there's an operational connected scanner, we can use its upgrades
			//  to improve our injector's radiation generation
			if(scanner_operational())
				I.damage_coeff = connected_scanner.damage_coeff
				injectorready = world.time + INJECTOR_TIMEOUT * 8 * (1 - 0.1 * connected_scanner.precision_coeff)
			else
				injectorready = world.time + INJECTOR_TIMEOUT * 8

			return

		// Adds a mutation to an advanced injector
		// ---------------------------------------------------------------------- //
		// params["mutref"] - ATOM Ref of specific mutation to add to the injector
		// params["advinj"] - Name of the advanced injector to add the mutation to
		if("add_adv_mut")
			// GUARD CHECK - Can we genetically modify the occupant? Includes scanner
			//  operational guard checks.
			// 	This is needed because this operation can only be completed from the
			//  genetic sequencer.
			if(!can_modify_occupant())
				return

			var/adv_inj = params["advinj"]

			// GUARD CHECK - Make sure our advanced injector actually exists. This
			//  should not be possible. Unexpected result
			if(!(adv_inj in injector_selection))
				return

			// GUARD CHECK - Make sure we limit the number of mutations appropriately
			if(LAZYLEN(injector_selection[adv_inj]) >= max_injector_mutations)
				to_chat(usr,"<span class='warning'>Advanced injector mutation storage is full.</span>")
				return

			var/bref = params["mutref"]
			// We've already made sure we can modify the occupant, so this is safe to
			//  call
			var/datum/mutation/human/HM = get_mut_by_ref(bref, SEARCH_OCCUPANT)

			// GUARD CHECK - This should not be possible. Unexpected result
			if(!HM)
				return

			// We want to make sure we stick within the instability limit.
			// We start with the instability of the mutation we're intending to add.
			var/instability_total = HM.instability

			// We then add the instabilities of all other mutations in the injector,
			//  remembering to apply the Stabilizer chromosome modifiers
			for(var/datum/mutation/human/I in injector_selection[adv_inj])
				instability_total += I.instability * GET_MUTATION_STABILIZER(I)

			// If this would take us over the max instability, we inform the user.
			if(instability_total > max_injector_instability)
				to_chat(usr,"<span class='warning'>Extra mutation would make the advanced injector too instable.</span>")
				return

			// If we've got here, all our checks are passed and we can successfully
			//  add the mutation to the advanced injector.
			var/datum/mutation/human/A = new HM.type()
			A.copy_mutation(HM)
			injector_selection[adv_inj] += A
			to_chat(usr,"<span class='notice'>Mutation successfully added to advanced injector.</span>")
			return

		// Deletes a mutation from an advanced injector
		// ---------------------------------------------------------------------- //
		// params["mutref"] - ATOM Ref of specific mutation to del from the injector
		// params["advinj"] - Name of the advanced injector to del the mutation from
		if("del_adv_mut")
			var/adv_inj = params["advinj"]

			// GUARD CHECK - Make sure our advanced injector actually exists. This
			//  should not be possible. Unexpected result
			if(!(adv_inj in injector_selection))
				return

			var/bref = params["mutref"]
			var/datum/mutation/human/HM = get_mut_by_ref(bref, SEARCH_ADV_INJ)

			// GUARD CHECK - This should not be possible. Unexpected result
			if(!HM)
				return

			injector_selection[adv_inj].Remove(HM)
			qdel(HM)
			return

		// Sets a new tgui state
		// ---------------------------------------------------------------------- //
		// params["id"] - Key for the state to set
		// params[...] - Every other element is used to set state variables
		if("set_state")
			// Get our state index the sanitise the param list, removing the id and
			//  src elements which we won't use.
			var/index = text2num(params["id"])
			var/list/new_state = (params - "id") - "src"

			for(var/key in new_state)
				state[index][key] = text2num(new_state[key])

			return
	return FALSE

// Applies the type of a specific genetic makeup buffer to the current scanner
//  occupant
/obj/machinery/computer/scan_consolenew/proc/apply_genetic_makeup(type, buffer_slot)
	// Note - This proc is only called from code that has already performed the
	//  necessary occupant guard checks. If you call this code yourself, please
	//  apply can_modify_occupant() or equivalent checks first.

	// Pre-calc the rad increase since we'll be using it in all the possible
	//  operations
	var/rad_increase = rand(100/(connected_scanner.damage_coeff ** 2),250/(connected_scanner.damage_coeff ** 2))

	switch(type)
		if("ui")
			// GUARD CHECK - There's currently no way to save partial genetic data.
			//  However, if this is the case, we can't make a complete injector and
			//  this catches that edge case
			if(!buffer_slot["UI"])
				to_chat(usr,"<span class='warning'>Genetic data corrupted, unable to apply genetic data.</span>")
				return
			scanner_occupant.dna.uni_identity = buffer_slot["UI"]
			scanner_occupant.updateappearance(mutations_overlay_update=1)
			scanner_occupant.radiation += rad_increase
			scanner_occupant.domutcheck()
			return
		if("ue")
			// GUARD CHECK - There's currently no way to save partial genetic data.
			//  However, if this is the case, we can't make a complete injector and
			//  this catches that edge case
			if(!buffer_slot["name"] || !buffer_slot["UE"] || !buffer_slot["blood_type"])
				to_chat(usr,"<span class='warning'>Genetic data corrupted, unable to apply genetic data.</span>")
				return
			scanner_occupant.real_name = buffer_slot["name"]
			scanner_occupant.name = buffer_slot["name"]
			scanner_occupant.dna.unique_enzymes = buffer_slot["UE"]
			scanner_occupant.dna.blood_type = buffer_slot["blood_type"]
			scanner_occupant.radiation += rad_increase
			scanner_occupant.domutcheck()
			return
		if("mixed")
			// GUARD CHECK - There's currently no way to save partial genetic data.
			//  However, if this is the case, we can't make a complete injector and
			//  this catches that edge case
			if(!buffer_slot["UI"] || !buffer_slot["name"] || !buffer_slot["UE"] || !buffer_slot["blood_type"])
				to_chat(usr,"<span class='warning'>Genetic data corrupted, unable to apply genetic data.</span>")
				return
			scanner_occupant.dna.uni_identity = buffer_slot["UI"]
			scanner_occupant.updateappearance(mutations_overlay_update=1)
			scanner_occupant.real_name = buffer_slot["name"]
			scanner_occupant.name = buffer_slot["name"]
			scanner_occupant.dna.unique_enzymes = buffer_slot["UE"]
			scanner_occupant.dna.blood_type = buffer_slot["blood_type"]
			scanner_occupant.radiation += rad_increase
			scanner_occupant.domutcheck()
			return

// Checks if there is a connected DNA Scanner that is operational
/obj/machinery/computer/scan_consolenew/proc/scanner_operational()
	if(!connected_scanner)
		return FALSE

	return (connected_scanner && connected_scanner.is_operational())

// Checks if there is a valid subject in the DNA Scanner that can be genetically
//  modified. Will set the scanner occupant var as part of this check.
// Requires that the scanner can be operated and will return early if it can't
/obj/machinery/computer/scan_consolenew/proc/can_modify_occupant()
	// GUARD CHECK - We always want to perform the scanner operational check as
	//  part of checking if we can modify the occupant.
	// We can never modify the occupant of a broken scanner.
	if(!scanner_operational())
		return FALSE

	if(!connected_scanner.occupant)
		return FALSE

	scanner_occupant = connected_scanner.occupant

		// Check validity of occupent for DNA Modification
		// DNA Modification:
		//   requires DNA
		//	   this DNA can not be bad
		//   is done via radiation bursts, so radiation immune carbons are not viable
		// And the DNA Scanner itself must have a valid scan level
	if(scanner_occupant.has_dna() && !HAS_TRAIT(scanner_occupant, TRAIT_RADIMMUNE) && !HAS_TRAIT(scanner_occupant, TRAIT_BADDNA) || (connected_scanner.scan_level == 3))
		return TRUE

	return FALSE

// Checks for adjacent DNA scanners and connects when it finds a viable one
/obj/machinery/computer/scan_consolenew/proc/connect_to_scanner()
	var/obj/machinery/dna_scannernew/test_scanner = null
	var/obj/machinery/dna_scannernew/broken_scanner = null

	// Look in each cardinal direction and try and find a DNA Scanner
	//   If you find a DNA Scanner, check to see if it broken or working
	//   If it's working, set the current scanner and return early
	//   If it's not working, remember it anyway as a broken scanner
	for(var/direction in GLOB.cardinals)
		test_scanner = locate(/obj/machinery/dna_scannernew, get_step(src, direction))
		if(!isnull(test_scanner))
			if(test_scanner.is_operational())
				connected_scanner = test_scanner
				connected_scanner.linked_console = src
				return
			else
				broken_scanner = test_scanner

	// Ultimately, if we have a broken scanner, we'll attempt to connect to it as
	// a fallback case, but the code above will prefer a working scanner
	if(!isnull(broken_scanner))
		connected_scanner = broken_scanner
		connected_scanner.linked_console = src

// DNA Scanners call this code on their connected DNA Console when they close
/obj/machinery/computer/scan_consolenew/proc/on_scanner_close()
	// Set the appropriate occupant now the scanner is closed
	if(connected_scanner.occupant)
		scanner_occupant = connected_scanner.occupant
	else
		scanner_occupant = null

	// If we have a delayed action - In this case the only delayed action is
	//  applying a genetic makeup buffer the next time the DNA Scanner is closed -
	//  we want to perform it.
	// GUARD CHECK - Make sure we can modify the occupant, apply_genetic_makeup()
	//  assumes we've already done this.
	if(delayed_action && can_modify_occupant())
		// TODO - This chat message can still trigger even if apply_genetic_makeup
		// fails. This is not ideal.
		to_chat(connected_scanner.occupant, "<span class='notice'>[src] activates!</span>")
		var/type = delayed_action["type"]
		var/buffer_slot = delayed_action["buffer_slot"]
		apply_genetic_makeup(type, buffer_slot)
		delayed_action = null

// Called by DNA Scanners when they open
/obj/machinery/computer/scan_consolenew/proc/on_scanner_open()
	// If we had a radiation pulse action ongoing, we want to stop this.
	// Imagine it being like a microwave stopping when you open the door.
	rad_pulse_index = 0
	rad_pulse_timer = 0
	scanner_occupant = null

// Builds the genetic makeup list which will be sent to tgui interface
/obj/machinery/computer/scan_consolenew/proc/build_genetic_makeup_list()
	// No code will ever null this list, we can safely Cut it.
	tgui_genetic_makeup.Cut()

	for(var/i=1, i <= NUMBER_OF_BUFFERS, i++)
		if(genetic_makeup_buffer[i])
			tgui_genetic_makeup["[i]"] = genetic_makeup_buffer[i].Copy()
		else
			tgui_genetic_makeup["[i]"] = null

// Builds all the genetic mutation information that is sent to tgui interface
/obj/machinery/computer/scan_consolenew/proc/build_mutation_list(can_modify_occ)
	// No code will ever null these lists. We can safely Cut them.
	tgui_occupant_mutations.Cut()
	tgui_diskette_mutations.Cut()
	tgui_scanner_mutations.Cut()
	tgui_scanner_chromosomes.Cut()
	tgui_advinjector_mutations.Cut()

  // ------------------------------------------------------------------------ //
	var/index = 1
	// GUARD CHECK - Can we genetically modify the occupant? This check will have
	//  previously included checks to make sure the DNA Scanner is still
	//  operational
	if(can_modify_occ)
		// ---------------------------------------------------------------------- //
		// Start cataloguing all mutations that the occupant has by default
		for(var/mutation_type in scanner_occupant.dna.mutation_index)
			var/datum/mutation/human/HM = GET_INITIALIZED_MUTATION(mutation_type)

			var/list/mutation_data = list()
			var/text_sequence = scanner_occupant.dna.mutation_index[mutation_type]
			var/list/list_sequence = list()

			// Convert the text sequence to a character array For easier tgui
			//  manioulation.

			// TODO: Use NodeJS methods in the tgui interface instead of doing it at
			//  the BYOND level.
			for(var/i in 1 to LAZYLEN(text_sequence))
				list_sequence += text_sequence[i];

			var/discovered = (stored_research && (mutation_type in stored_research.discovered_mutations))

			mutation_data["Alias"] = HM.alias
			mutation_data["Sequence"] = text_sequence
			mutation_data["SeqList"] = list_sequence
			mutation_data["Discovered"] = discovered

			// We only want to pass this information along to the tgui interface if
			//  the mutation has been discovered. Prevents people being able to cheese
			//  or "hack" their way to figuring out what undiscovered mutations are
			if(discovered)
				mutation_data["Name"] = HM.name
				mutation_data["Description"] = HM.desc
				mutation_data["Instability"] = HM.instability * GET_MUTATION_STABILIZER(HM)

			// Assume the mutation is normal unless assigned otherwise.
			var/mut_class = MUT_NORMAL

			// Check if the mutation is currently activated. If it is, we can add even
			//  MORE information to send to tgui.
			var/datum/mutation/human/A = scanner_occupant.dna.get_mutation(mutation_type)
			if(A)
				mutation_data["Active"] = TRUE
				mutation_data["Scrambled"] = A.scrambled
				mutation_data["Class"] = A.class
				mut_class = A.class
				mutation_data["CanChromo"] = A.can_chromosome
				mutation_data["ByondRef"] = REF(A)
				mutation_data["Type"] = A.type
				if(A.can_chromosome)
					mutation_data["ValidChromos"] = jointext(A.valid_chrom_list, ", ")
					mutation_data["AppliedChromo"] = A.chromosome_name
					mutation_data["ValidStoredChromos"] = build_chrom_list(A)
			else
				mutation_data["Active"] = FALSE
				mutation_data["Scrambled"] = FALSE
				mutation_data["Class"] = MUT_NORMAL

			// Technically NONE of these mutations should be MUT_EXTRA but this will
			//  catch any weird edge cases
			// Assign icons by priority - MUT_EXTRA will ALSO be discovered, so it
			//  has a higher priority for icon/image assignment
			if (mut_class == MUT_EXTRA)
				mutation_data["Image"] = "dna_extra.gif"
			else if(discovered)
				mutation_data["Image"] = "dna_discovered.gif"
			else
				mutation_data["Image"] = "dna_undiscovered.gif"

			tgui_occupant_mutations["[index]"] = mutation_data
			index++

		// ---------------------------------------------------------------------- //
		// Now get additional/"extra" mutations that they shouldn't have by default
		for(var/datum/mutation/human/HM in scanner_occupant.dna.mutations)
			// If it's in the mutation index array, we've already catalogued this
			//  mutation and can safely skip over it. It really shouldn't be, but this
			//  will catch any weird edge cases
			if(HM.type in scanner_occupant.dna.mutation_index)
				break

			var/list/mutation_data = list()
			var/text_sequence = GET_SEQUENCE(HM.type)
			var/list/list_sequence = list()

			// TODO: Use NodeJS methods in the tgui interface instead of doing it at
			//  the BYOND level.
			for(var/i in 1 to LAZYLEN(text_sequence))
				list_sequence += text_sequence[i];

			// These will all be active mutations. They're added by injector and their
			//  sequencing code can't be changed. They can only be nullified, which
			//  completely removes them.
			var/datum/mutation/human/A = GET_INITIALIZED_MUTATION(HM.type)

			mutation_data["Alias"] = A.alias
			mutation_data["Sequence"] = text_sequence
			mutation_data["SeqList"] = list_sequence
			mutation_data["Discovered"] = TRUE

			mutation_data["Name"] = HM.name
			mutation_data["Description"] = HM.desc
			mutation_data["Instability"] = HM.instability * GET_MUTATION_STABILIZER(HM)

			mutation_data["Active"] = TRUE
			mutation_data["Scrambled"] = HM.scrambled
			mutation_data["Class"] = HM.class
			mutation_data["CanChromo"] = HM.can_chromosome
			mutation_data["ByondRef"] = REF(HM)
			mutation_data["Type"] = HM.type

			if(HM.can_chromosome)
				mutation_data["ValidChromos"] = jointext(HM.valid_chrom_list, ", ")
				mutation_data["AppliedChromo"] = HM.chromosome_name
				mutation_data["ValidStoredChromos"] = build_chrom_list(HM)

			// Nothing in this list should be undiscovered. Technically nothing
			// should be anything but EXTRA. But we're just handling some edge cases.
			if (HM.class == MUT_EXTRA)
				mutation_data["Image"] = "dna_extra.gif"
			else
				mutation_data["Image"] = "dna_discovered.gif"

			tgui_occupant_mutations["[index]"] = mutation_data
			index++

	// ------------------------------------------------------------------------ //
	// Build the list of mutations stored within the DNA Console
	index = 1
	for(var/datum/mutation/human/HM in stored_mutations)
		var/list/mutation_data = list()

		var/text_sequence = GET_SEQUENCE(HM.type)
		var/list/list_sequence = list()

		// TODO: Use NodeJS methods in the tgui interface instead of doing it at
		//  the BYOND level.
		for(var/i in 1 to LAZYLEN(text_sequence))
			list_sequence += text_sequence[i];

		var/datum/mutation/human/A = GET_INITIALIZED_MUTATION(HM.type)

		mutation_data["Alias"] = A.alias
		mutation_data["SeqList"] = list_sequence
		mutation_data["Name"] = HM.name
		mutation_data["Description"] = HM.desc
		mutation_data["Instability"] = HM.instability * GET_MUTATION_STABILIZER(HM)
		mutation_data["ByondRef"] = REF(HM)
		mutation_data["Type"] = HM.type

		mutation_data["CanChromo"] = HM.can_chromosome
		if(HM.can_chromosome)
			mutation_data["ValidChromos"] = jointext(HM.valid_chrom_list, ", ")
			mutation_data["AppliedChromo"] = HM.chromosome_name
			mutation_data["ValidStoredChromos"] = build_chrom_list(HM)

		tgui_scanner_mutations["[index]"] = mutation_data
		index++

	index = 1
	for(var/obj/item/chromosome/CM in stored_chromosomes)
		var/list/chromo_data = list()

		chromo_data["Name"] = CM.name
		chromo_data["Description"] = CM.desc

		tgui_scanner_chromosomes["[index]"] = chromo_data
		index++

	// ------------------------------------------------------------------------ //
	// Build the list of mutations stored on any inserted diskettes
	index = 1
	if(diskette)
		for(var/datum/mutation/human/HM in diskette.mutations)
			var/list/mutation_data = list()

			var/text_sequence = GET_SEQUENCE(HM.type)
			var/list/list_sequence = list()

			// TODO: Use NodeJS methods in the tgui interface instead of doing it at
			//  the BYOND level.
			for(var/i in 1 to LAZYLEN(text_sequence))
				list_sequence += text_sequence[i];

			var/datum/mutation/human/A = GET_INITIALIZED_MUTATION(HM.type)

			mutation_data["Alias"] = A.alias
			mutation_data["SeqList"] = list_sequence
			mutation_data["Name"] = HM.name
			mutation_data["Description"] = HM.desc
			mutation_data["Instability"] = HM.instability * GET_MUTATION_STABILIZER(HM)
			mutation_data["ByondRef"] = REF(HM)
			mutation_data["Type"] = HM.type

			mutation_data["CanChromo"] = HM.can_chromosome
			if(HM.can_chromosome)
				mutation_data["ValidChromos"] = jointext(HM.valid_chrom_list, ", ")
				mutation_data["AppliedChromo"] = HM.chromosome_name
				mutation_data["ValidStoredChromos"] = build_chrom_list(HM)

			tgui_diskette_mutations["[index]"] = mutation_data
			index += 1

	index = 1

	// ------------------------------------------------------------------------ //
	// Build the list of mutations stored within any Advanced Injectors
	if(LAZYLEN(injector_selection))
		for(var/I in injector_selection)
			tgui_advinjector_mutations["[I]"] = list()
			for(var/datum/mutation/human/HM in injector_selection[I])
				var/list/mutation_data = list()

				var/datum/mutation/human/A = GET_INITIALIZED_MUTATION(HM.type)

				mutation_data["Alias"] = A.alias
				mutation_data["Name"] = HM.name
				mutation_data["Description"] = HM.desc
				mutation_data["Instability"] = HM.instability * GET_MUTATION_STABILIZER(HM)
				mutation_data["ByondRef"] = REF(HM)
				mutation_data["Type"] = HM.type

				if(HM.can_chromosome)
					mutation_data["AppliedChromo"] = HM.chromosome_name

				tgui_advinjector_mutations["[I]"]["[index]"] = mutation_data
				index += 1


// Builds a list of all chromosomes stored on in the console that can actually
//  be applied to a given mutation
/obj/machinery/computer/scan_consolenew/proc/build_chrom_list(mutation)
	var/list/chromosomes = list()

	for(var/obj/item/chromosome/CM in stored_chromosomes)
		if(CM.can_apply(mutation))
			chromosomes += CM.name

	return chromosomes

	/*
	var/list/list/state = list(
		STATE_BASE = list("mode" = TGUI_MODE_ST),
		STATE_ST = list("mode" = TGUI_ST_CO),
		STATE_STC = list("mode" = TGUI_ST_MUT),
		STATE_STCM = list("mode" = TGUI_ST_M_INFO, "index" = 1),
		STATE_STCC = list("index" = 1),
		STATE_STD = list("mode" = TGUI_ST_MUT),
		STATE_STDM = list("mode" = TGUI_ST_M_INFO, "index" = 1)
	)
	)*/

// Builds the state list for the tgui interface
/obj/machinery/computer/scan_consolenew/proc/build_state_list()
	tgui_state["Mode"] = state[STATE_BASE]["mode"]
	tgui_state["Storage"]["Mode"] = state[STATE_ST]["mode"]
	tgui_state["Storage"]["Console"]["Mode"] = state[STATE_STC]["mode"]
	tgui_state["Storage"]["Console"]["Mutation"]["Mode"] = state[STATE_STCM]["mode"]
	tgui_state["Storage"]["Console"]["Mutation"]["Index"] = state[STATE_STCM]["index"]
	tgui_state["Storage"]["Console"]["Chromo"]["Index"] = state[STATE_STCC]["index"]
	tgui_state["Storage"]["Disk"]["Mode"] = state[STATE_STD]["mode"]
	tgui_state["Storage"]["Disk"]["Mutation"]["Mode"] = state[STATE_STDM]["mode"]
	tgui_state["Storage"]["Disk"]["Mutation"]["Index"] = state[STATE_STDM]["index"]
	tgui_state["Sequencer"]["Mode"] = state[STATE_GS]["mode"]
	tgui_state["Sequencer"]["Index"] = state[STATE_GS]["index"]

// Checks wether
/obj/machinery/computer/scan_consolenew/proc/check_discovery(alias)
	// Note - All code paths that call this have already done checks on the
	//  current occupant to prevent cheese and other abuses. If you call this
	//  proc please also do the following checks first:
	// if(!can_modify_occupant())
	//   return
	// if(!(scanner_occupant == connected_scanner.occupant))
	//   return

	// Turn the alias ("Mutation 1", "Mutation 35") into a mutation path
	var/path = GET_MUTATION_TYPE_FROM_ALIAS(alias)

	// Check to see if this mutation is in the active mutation list. If it isn't,
	//  then the mutation isn't eligible for discovery. If it is but is scrambled,
	//  then the mutation isn't eligible for discovery. Finally, check if the
	//  mutation is in discovered mutations - If it isn't, add it to discover.
	var/datum/mutation/human/M = scanner_occupant.dna.get_mutation(path)
	if(!M)
		return FALSE
	if(M.scrambled)
		return FALSE
	if(stored_research && !(path in stored_research.discovered_mutations))
		stored_research.discovered_mutations += path
		return TRUE

	return FALSE

// Takes an ATOM Ref and searches the appropriate mutation buffers and storage
//  vars to try and find the associated mutation.
/obj/machinery/computer/scan_consolenew/proc/get_mut_by_ref(ref, target_flags)
	var/mutation

	// Assume the occupant is valid and the check has been carried out before
	// 	calling this proc with the relevant flags.
	if(target_flags & SEARCH_OCCUPANT)
		mutation = (locate(ref) in scanner_occupant.dna.mutations)
		if(mutation)
			return mutation

	if(target_flags & SEARCH_STORED)
		mutation = (locate(ref) in stored_mutations)
		if(mutation)
			return mutation

	if(diskette && (target_flags & SEARCH_DISKETTE))
		mutation = (locate(ref) in diskette.mutations)
		if(mutation)
			return mutation

	if(injector_selection && (target_flags & SEARCH_ADV_INJ))
		for(var/I in injector_selection)
			mutation = (locate(ref) in injector_selection["[I]"])
			if(mutation)
				return mutation

	return null

// Randomises the pulse accuracy based on the pulse duration for genetic makeup
//  modification
// This is donor code from the old DNA Console.
/obj/machinery/computer/scan_consolenew/proc/randomize_radiation_accuracy(position, radduration, number_of_blocks)
	var/val = round(gaussian(0, RADIATION_ACCURACY_MULTIPLIER/radduration) + position, 1)
	return WRAP(val, 1, number_of_blocks+1)

// Scrambles a Unique Identifier element as part of genetic makeup modification
// This is donor code from the old DNA Console.
/obj/machinery/computer/scan_consolenew/proc/scramble(input,rs,rd) //hexadecimal genetics. dont confuse with scramble button
	var/length = length(input)
	var/ran = gaussian(0, rs*RADIATION_STRENGTH_MULTIPLIER)
	if(ran == 0)
		ran = pick(-1,1)	//hacky, statistically should almost never happen. 0-chance makes people mad though
	else if(ran < 0)
		ran = round(ran)	//negative, so floor it
	else
		ran = -round(-ran)	//positive, so ceiling it
	return num2hex(WRAP(hex2num(input)+ran, 0, 16**length), length)

// Performs the radiation pulse procedure for modifying Unique Identifiers as a
//  part of genetic makeup.
// This is donor code from the old DNA Console.
/obj/machinery/computer/scan_consolenew/proc/rad_pulse()
	// GUARD CHECK - Can we genetically modify the occupant? Includes scanner
	//  operational guard checks.
	// If we can't, abort the procedure.
	if(!can_modify_occupant())
		rad_pulse_index = 0
		return

	var/len = length_char(scanner_occupant.dna.uni_identity)
	var/num = randomize_radiation_accuracy(rad_pulse_index, radduration + (connected_scanner.precision_coeff ** 2), len) //Each manipulator level above 1 makes randomization as accurate as selected time + manipulator lvl^2																																																		 //Value is this high for the same reason as with laser - not worth the hassle of upgrading if the bonus is low
	var/hex = copytext_char(scanner_occupant.dna.uni_identity, num, num+1)
	hex = scramble(hex, radstrength, radduration)

	scanner_occupant.dna.uni_identity = copytext_char(scanner_occupant.dna.uni_identity, 1, num) + hex + copytext_char(scanner_occupant.dna.uni_identity, num + 1)
	scanner_occupant.updateappearance(mutations_overlay_update=1)

	rad_pulse_index = 0
	return


/////////////////////////// DNA MACHINES
#undef INJECTOR_TIMEOUT
#undef NUMBER_OF_BUFFERS
#undef SCRAMBLE_TIMEOUT
#undef JOKER_TIMEOUT
#undef JOKER_UPGRADE

#undef RADIATION_STRENGTH_MAX
#undef RADIATION_STRENGTH_MULTIPLIER

#undef RADIATION_DURATION_MAX
#undef RADIATION_ACCURACY_MULTIPLIER

#undef RADIATION_IRRADIATION_MULTIPLIER

#undef SCANNER_ACTION_SE
#undef SCANNER_ACTION_UI
#undef SCANNER_ACTION_UE
#undef SCANNER_ACTION_MIXED

#undef SEARCH_OCCUPANT
#undef SEARCH_STORED
#undef SEARCH_DISKETTE
#undef SEARCH_ADV_INJ


//#undef BAD_MUTATION_DIFFICULTY
//#undef GOOD_MUTATION_DIFFICULTY
//#undef OP_MUTATION_DIFFICULTY
