 //Fermichem!!
//Fun chems for all the family

/datum/reagent/fermi
	name = "Fermi" //This should never exist, but it does so that it can exist in the case of errors..
	taste_description = "gamebreaking bugs and fourth-wall breaks"
	can_synth = FALSE

//This should process fermichems to find out how pure they are and what effect to do.
/datum/reagent/fermi/on_mob_add(mob/living/carbon/M, amount)
	. = ..()
	if(!M)
		return
	if(purity < 0)
		CRASH("Purity below 0 for chem : [type], yell at coders")
	if (purity == 1 || DoNotSplit == TRUE)
		log_game("FERMICHEM: [M] ckey: [M.key] has ingested [volume]u of [type]")
		return
	else if (InverseChemVal > purity)//Turns all of a added reagent into the inverse chem
		M.reagents.remove_reagent(type, amount, FALSE)
		M.reagents.add_reagent(InverseChem, amount, FALSE, other_purity = 1)
		log_game("FERMICHEM: [M] ckey: [M.key] has ingested [volume]u of [InverseChem]")
		return
	else
		var/impureVol = amount * (1 - purity) //turns impure ratio into impure chem
		M.reagents.remove_reagent(type, (impureVol), FALSE)
		M.reagents.add_reagent(ImpureChem, impureVol, FALSE, other_purity = 1)
		log_game("FERMICHEM: [M] ckey: [M.key] has ingested [volume - impureVol]u of [type]")
		log_game("FERMICHEM: [M] ckey: [M.key] has ingested [volume]u of [ImpureChem]")
	return


///////////////////////////////////////////////////////////////////////////////////////////////
//				MISC FERMICHEM CHEMS FOR SPECIFIC INTERACTIONS ONLY
///////////////////////////////////////////////////////////////////////////////////////////////

/datum/reagent/acidvapour
	name = "Acid vapour"
	description = "Someone didn't do like an otter, and add acid to water."
	taste_description = "acid burns"
	color = "#FFFFFF"
	pH = 0
	can_synth = FALSE

/datum/reagent/acidvapour/reaction_mob(mob/living/carbon/C, method)
	var/target = C.get_bodypart(BODY_ZONE_CHEST)
	var/acidstr
	if(!C.reagents.pH || C.reagents.pH >5)
		acidstr = 3
	else
		acidstr = ((5-C.reagents.pH)*2) //runtime - null.pH ?
	C.adjustFireLoss(acidstr/2,0)
	if((method==VAPOR) && (!C.wear_mask))
		if(prob(20))
			to_chat(C, "<span class='warning'>You can feel an intense burning sensation in your lungs!</b></span>")
		C.adjustOrganLoss(ORGAN_SLOT_LUNGS, -2)
		C.apply_damage(acidstr/5, BURN, target)
	C.acid_act(acidstr, volume)
	..()

/datum/reagent/acidvapour/reaction_obj(obj/O, reac_volume)
	if(ismob(O.loc)) //handled in human acid_act()
		return
	if((holder.pH > 5) || (volume < 0.1)) //Shouldn't happen, but just in case
		return
	reac_volume = round(volume,0.1)
	var/acidstr = (5-holder.pH)*2 //(max is 10)
	O.acid_act(acidstr, volume)
	..()

/datum/reagent/acidvapour/reaction_turf(turf/T, reac_volume)
	if (!istype(T))
		return
	reac_volume = round(volume,0.1)
	var/acidstr = (5-holder.pH)
	T.acid_act(acidstr, volume)
	..()

/datum/reagent/acidic_buffer
	name = "Acidic buffer"
	description = "This reagent will consume itself and move the pH of a beaker towards acidity when added to another."
	color = "#fbc314"
	pH = 0
	can_synth = TRUE

//Consumes self on addition and shifts pH
/datum/reagent/acidic_buffer/on_new(datapH)
	data = datapH
	if(LAZYLEN(holder.reagent_list) == 1)
		return
	holder.pH = ((holder.pH * holder.total_volume)+(pH * (volume)))/(holder.total_volume + (volume))
	var/list/seen = viewers(5, get_turf(holder))
	for(var/mob/M in seen)
		to_chat(M, "<span class='warning'>The beaker fizzes as the pH changes!</b></span>")
	playsound(get_turf(holder.my_atom), 'sound/FermiChem/bufferadd.ogg', 50, 1)
	holder.remove_reagent(type, volume, ignore_pH = TRUE)
	..()

/datum/reagent/basic_buffer
	name = "Basic buffer"
	description = "This reagent will consume itself and move the pH of a beaker towards alkalinity when added to another."
	color = "#3853a4"
	pH = 14
	can_synth = TRUE

/datum/reagent/basic_buffer/on_new(datapH)
	data = datapH
	if(LAZYLEN(holder.reagent_list) == 1)
		return
	holder.pH = ((holder.pH * holder.total_volume)+(pH * (volume)))/(holder.total_volume + (volume))
	var/list/seen = viewers(5, get_turf(holder))
	for(var/mob/M in seen)
		to_chat(M, "<span class='warning'>The beaker froths as the pH changes!</b></span>")
	playsound(get_turf(holder.my_atom), 'sound/FermiChem/bufferadd.ogg', 50, 1)
	holder.remove_reagent(type, volume, ignore_pH = TRUE)
	..()
