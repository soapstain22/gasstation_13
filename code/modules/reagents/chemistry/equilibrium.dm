/*
* #/datum/equilibrium
*
* A dynamic reaction object that processes the reaction that it is set within it. Relies on a reagents holder to call and operate the functions.
*
* An object/datum to contain the vars for each of the reactions currently ongoing in a holder/reagents datum
* This way all information is kept within one accessable object
* equilibrium is a unique name as reaction is already too close to chemical_reaction
* This is set up this way to reduce holder.dm bloat as well as reduce confusing list overhead
* The crux of the fermimechanics are handled here
* Instant reactions AREN'T handled here. See holder.dm
*/
/datum/equilibrium
	///The chemical reaction that is presently being processed
	var/datum/chemical_reaction/reaction 
	///The location/reagents datum the processing is taking place
	var/datum/reagents/holder 
	///How much product we can make multiplied by the input recipe's products/required_reagents numerical values
	var/multiplier = INFINITY
	///The sum total of each of the product's numerical's values. This is so the addition/deletion is kept at the right values for multiple product reactions
	var/product_ratio = 0
	///The target volume the reaction is headed towards. This is updated every tick, so isn't the total value for the reaction, it's just a way to ensure we can't make more than is possible.
	var/target_vol = INFINITY
	///How much of the reaction has been made so far. Mostly used for subprocs, but it keeps track across the whole reaction and is added to every step.
	var/reacted_vol = 0 
	///If we're done with this reaction so that holder can clear it.
	var/to_delete = FALSE 

/* 
* Creates and sets up a new equlibrium object
* 
* Arguments:
* * input_reaction - the chemical_reaction datum that will be processed
* * input_holder - the reagents datum that the output will be put into
*/
/datum/equilibrium/New(datum/chemical_reaction/input_reaction, datum/reagents/input_holder)
	reaction = input_reaction
	holder = input_holder
	if(!holder || !reaction)
		CRASH("A new [type] was set up, with incorrect/null input vars!")
	if(!check_inital_conditions()) //If we're outside of the scope of the reaction vars
		to_delete = TRUE
		return
	/*if(!length(reaction.results)) //DO NOT FORGET TO ENABLE THIS CHECK - Come back to and revise the affected reactions in the next PR, this is a sloppy fix.
		holder.instant_react(reaction)
		to_delete = TRUE
		return*/
	reaction.on_reaction(holder, multiplier)
	SSblackbox.record_feedback("tally", "chemical_reaction", 1, "[reaction.type] attempts")
	react_timestep(1)//Get an initial step going so there's not a delay between setup and start
	

/datum/equilibrium/Destroy()
	LAZYREMOVE(holder.reaction_list, src)
	holder = null
	reaction = null
	return ..()

/* 
* Check to make sure our input vars are sensible - truncated version of check_reagent_properties() 
* 
* (as the setup in holder.dm checks for that already - this is a way to reduce calculations on New())
* Don't call this unless you know what you're doing, this is an internal proc
*/
/datum/equilibrium/proc/check_inital_conditions()
	//These temp checks might not be needed
	/*if(!reaction.is_cold_recipe)
		if(holder.chem_temp < reaction.required_temp) 
			return FALSE //Not hot enough
	else
		if(holder.chem_temp > reaction.required_temp)
			return FALSE //Not cold enough
	*/
	//Make sure we have the right multipler for on_reaction()
	for(var/B in reaction.required_reagents)
		multiplier = min(multiplier, round((holder.get_reagent_amount(B) / reaction.required_reagents[B]), CHEMICAL_QUANTISATION_LEVEL))
	if(multiplier == INFINITY)
		return FALSE
	//Consider purity gating too? - probably not, purity is hard to determine
	//To prevent reactions outside of the pH window from starting.
	if(! ((holder.pH >= (reaction.optimal_pH_min - reaction.determin_pH_range)) && (holder.pH <= (reaction.optimal_pH_max + reaction.determin_pH_range)) ))
		return FALSE
	return TRUE

/* 
* Check to make sure our input vars are sensible - is the holder overheated? does it have the required reagents? Does it have the required calalysts?
*
* If you're adding more checks for reactions, this is the proc to edit
* otherwise, generally, don't call this directed except internally
*/
/datum/equilibrium/proc/check_reagent_properties()
	//Have we exploded?
	if(!holder.my_atom || holder.reagent_list.len == 0)
		return FALSE
	//Are we overheated?
	if(holder.chem_temp > reaction.overheat_temp) //This is before the process - this is here so that overly_impure and overheated() share the same code location (and therefore vars) for calls.
		SSblackbox.record_feedback("tally", "chemical_reaction", 1, "[reaction.type] overheated reaction steps")
		reaction.overheated(holder, src)

	//set up catalyst checks
	var/total_matching_catalysts = 0
	//Reagents check should be handled in the calculate_yield() from multiplier

	//If the product/reactants are too impure
	for(var/r in holder.reagent_list)
		var/datum/reagent/R = r
		if (R.purity < reaction.purity_min)//If purity is below the min, call the proc
			SSblackbox.record_feedback("tally", "chemical_reaction", 1, "[reaction.type] overly impure reaction steps")
			reaction.overly_impure(holder, src)
		//this is done this way to reduce processing compared to holder.has_reagent(P)
		for(var/P in reaction.required_catalysts)
			var/datum/reagent/R0 = P
			if(R0 == R.type)
				total_matching_catalysts++

	if(!(total_matching_catalysts == reaction.required_catalysts.len))
		return FALSE

	//All good!
	return TRUE

/*
* Calculates how much we're aiming to create
*
* Specifically calcuates multiplier, product_ratio, target_vol
* Also checks to see if these numbers are sane, returns a TRUE/FALSE
* Generally an internal proc
*/
/datum/equilibrium/proc/calculate_yield()
	if(to_delete)
		return FALSE
	if(!reaction)
		stack_trace("Tried to calculate an equlibrium for reaction [reaction.type], but there was no reaction set for the datum")
		return FALSE
	multiplier = INFINITY
	product_ratio = 0
	target_vol = 0
	for(var/B in reaction.required_reagents)
		multiplier = min(multiplier, round((holder.get_reagent_amount(B) / reaction.required_reagents[B]), CHEMICAL_QUANTISATION_LEVEL))
	for(var/P in reaction.results)
		target_vol += (reaction.results[P]*multiplier)
		product_ratio += reaction.results[P]
	if(target_vol == 0 || multiplier == INFINITY)
		return FALSE
	return TRUE
/*
* Main reaction processor - Increments the reaction by a timestep
*
* First checks the holder to make sure it can continue
* Then calculates the purity and volume produced.TRUE
* Then adds/removes reagents
* Then alters the holder pH and temperature, and calls reaction_step
* Arguments:
* * delta_time - the time displacement between the last call and the current
*/
/datum/equilibrium/proc/react_timestep(delta_time)
	if(!calculate_yield())
		to_delete = TRUE
		return
	if(!check_reagent_properties())
		to_delete = TRUE
		return
	
	var/deltaT = 0 //how far off optimal temp we care
	var/deltapH = 0 //How far off the pH we are
	var/cached_pH = holder.pH
	var/cached_temp = holder.chem_temp
	var/purity = 1 //purity of the current step

	//Begin checks
	//Calculate DeltapH (Deviation of pH from optimal)
	//Within mid range
	if (cached_pH >= reaction.optimal_pH_min  && cached_pH <= reaction.optimal_pH_max)
		deltapH = 1
	//Lower range
	else if (cached_pH < reaction.optimal_pH_min)
		if (cached_pH < (reaction.optimal_pH_min - reaction.determin_pH_range))
			deltapH = 0
			//If outside pH range, 0
		else
			deltapH = (((cached_pH - (reaction.optimal_pH_min - reaction.determin_pH_range))**reaction.pH_exponent_factor)/((reaction.determin_pH_range**reaction.pH_exponent_factor))) //main pH calculation
	//Upper range
	else if (cached_pH > reaction.optimal_pH_max)
		if (cached_pH > (reaction.optimal_pH_max + reaction.determin_pH_range))
			deltapH = 0
			//If outside pH range, 0
		else
			deltapH = (((- cached_pH + (reaction.optimal_pH_max + reaction.determin_pH_range))**reaction.pH_exponent_factor)/(reaction.determin_pH_range**reaction.pH_exponent_factor))//Reverse - to + to prevent math operation failures.
	
	//This should never proc, but it's a catch incase someone puts in incorrect values
	else
		stack_trace("[holder.my_atom] attempted to determine FermiChem pH for '[reaction.type]' which had an invalid pH of [cached_pH] for set recipie pH vars. It's likely the recipe vars are wrong.")

	//Calculate DeltaT (Deviation of T from optimal)
	if(!reaction.is_cold_recipe)
		if (cached_temp < reaction.optimal_temp && cached_temp >= reaction.required_temp)
			deltaT = (((cached_temp - reaction.required_temp)**reaction.temp_exponent_factor)/((reaction.optimal_temp - reaction.required_temp)**reaction.temp_exponent_factor))
		else if (cached_temp >= reaction.optimal_temp)
			deltaT = 1
		else //too hot
			deltaT = 0
			to_delete = TRUE
			return
	else
		if (cached_temp > reaction.optimal_temp && cached_temp <= reaction.required_temp)
			deltaT = (((cached_temp - reaction.required_temp)**reaction.temp_exponent_factor)/((reaction.optimal_temp - reaction.required_temp)**reaction.temp_exponent_factor))
		else if (cached_temp <= reaction.optimal_temp)
			deltaT = 1
		else //Too cold
			deltaT = 0
			to_delete = TRUE
			return

	purity = deltapH//set purity equal to pH offset

	//Then adjust purity of result with beaker reagent purity. 
	purity *= reactant_purity(reaction)

	//Now we calculate how much to add - this is normalised to the rate up limiter
	var/delta_chem_factor = (reaction.rate_up_lim*deltaT)*delta_time//add/remove factor
	var/total_step_added = 0
	//keep limited
	if(delta_chem_factor > target_vol)
		delta_chem_factor = target_vol
	else if (delta_chem_factor < CHEMICAL_VOLUME_MINIMUM)
		delta_chem_factor = CHEMICAL_VOLUME_MINIMUM
	delta_chem_factor = round(delta_chem_factor, CHEMICAL_QUANTISATION_LEVEL)

	//Calculate how much product to make and how much reactant to remove factors..
	for(var/B in reaction.required_reagents)
		holder.remove_reagent(B, ((delta_chem_factor/product_ratio) * reaction.required_reagents[B]), safety = TRUE)
		//Apply pH changes
		holder.adjust_specific_reagent_pH(B, ((delta_chem_factor/product_ratio) * reaction.required_reagents[B])*reaction.H_ion_release)

	for(var/P in reaction.results)
		//create the products
		var/step_add = (delta_chem_factor/product_ratio) * reaction.results[P]
		holder.add_reagent(P, step_add, null, cached_temp, purity, override_base_pH = TRUE)
		//Apply pH changes
		holder.adjust_specific_reagent_pH(P, step_add*reaction.H_ion_release)
		reacted_vol += step_add
		total_step_added += step_add

	#ifdef TESTING //Kept in so that people who want to write fermireactions can contact me with this log so I can help them
	debug_world("Reaction vars: PreReacted:[reacted_vol] of [target_vol]. deltaT [deltaT], multiplier [multiplier], delta_chem_factor [delta_chem_factor] Pfactor [product_ratio], purity of [purity] from a deltapH of [deltapH]. DeltaTime: [delta_time]")
	#endif
		
	//Apply thermal output of reaction to beaker
	holder.chem_temp = round(cached_temp + (reaction.thermic_constant* total_step_added))
	//Call any special reaction steps
	reaction.reaction_step(src, total_step_added, purity)//proc that calls when step is done

	//Give a chance of sounds
	if (prob(20))
		holder.my_atom.visible_message("<span class='notice'>[icon2html(holder.my_atom, viewers(DEFAULT_MESSAGE_RANGE, src))] [reaction.mix_message]</span>")
		if(reaction.mix_sound)
			playsound(get_turf(holder.my_atom), reaction.mix_sound, 80, TRUE)

	//Make sure things are limited
	holder.update_total()//do NOT recalculate reactions

/*
* Calculates the total sum normalised purity of ALL reagents in a holder
*
* Currently calculates it irrespective of required reagents at the start, but this should be changed if this is powergamed to required reagents
* It's not currently because overly_impure affects all reagents
*/
/datum/equilibrium/proc/reactant_purity(datum/chemical_reaction/C)
	var/list/cached_reagents = holder.reagent_list
	var/i = 0
	var/cached_purity
	for(var/datum/reagent/R in holder.reagent_list)
		if (R in cached_reagents)
			cached_purity += R.purity
			i++
	if(!i)//I've never seen it get here with 0, but in case
		CRASH("No reactants found mid reaction for [C.type]. Beaker: [holder.my_atom]")
	return cached_purity/i

/datum/equilibrium/proc/get_total(datum/chemical_reaction/C)
