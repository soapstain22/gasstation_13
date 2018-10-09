
/////////////////////////// DNA DATUM
/datum/dna
	var/unique_enzymes
	var/struc_enzymes
	var/uni_identity
	var/blood_type
	var/datum/species/species = new /datum/species/human //The type of mutant race the player is if applicable (i.e. potato-man)
	var/list/features = list("FFF") //first value is mutant color
	var/real_name //Stores the real name of the person who originally got this dna datum. Used primarely for changelings,
	var/list/mutations = list()   //All mutations are from now on here
	var/list/temporary_mutations = list() //Timers for temporary mutations
	var/list/previous = list() //For temporary name/ui/ue/blood_type modifications
	var/mob/living/holder
	var/delete_species = TRUE //Set to FALSE when a body is scanned by a cloner to fix #38875
	var/mutation_index = list() //List of which mutations this carbon has and its assigned block

/datum/dna/New(mob/living/new_holder)
	if(istype(new_holder))
		holder = new_holder

/datum/dna/Destroy()
	if(iscarbon(holder))
		var/mob/living/carbon/cholder = holder
		if(cholder.dna == src)
			cholder.dna = null
	holder = null

	if(delete_species)
		QDEL_NULL(species)

	mutations.Cut()					//This only references mutations, just dereference.
	temporary_mutations.Cut()		//^
	previous.Cut()					//^

	return ..()

/datum/dna/proc/transfer_identity(mob/living/carbon/destination, transfer_SE = 0)
	if(!istype(destination))
		return
	destination.dna.unique_enzymes = unique_enzymes
	destination.dna.uni_identity = uni_identity
	destination.dna.blood_type = blood_type
	destination.set_species(species.type, icon_update=0)
	destination.dna.features = features.Copy()
	destination.dna.real_name = real_name
	destination.dna.temporary_mutations = temporary_mutations.Copy()
	if(transfer_SE)
		destination.dna.struc_enzymes = struc_enzymes

/datum/dna/proc/copy_dna(datum/dna/new_dna)
	new_dna.unique_enzymes = unique_enzymes
	new_dna.struc_enzymes = struc_enzymes
	new_dna.uni_identity = uni_identity
	new_dna.blood_type = blood_type
	new_dna.features = features.Copy()
	new_dna.species = new species.type
	new_dna.real_name = real_name
	new_dna.mutations = mutations.Copy()

/datum/dna/proc/add_mutation(mutation_name)
	var/datum/mutation/human/HM = GLOB.mutations_list[mutation_name]
	HM.on_acquiring(holder)

/datum/dna/proc/remove_mutation(mutation_name)
	var/datum/mutation/human/HM = GLOB.mutations_list[mutation_name]
	HM.on_losing(holder)

/datum/dna/proc/check_mutation(mutation_name)
	var/datum/mutation/human/HM = GLOB.mutations_list[mutation_name]
	return mutations.Find(HM)

/datum/dna/proc/remove_all_mutations()
	remove_mutation_group(mutations)

/datum/dna/proc/remove_mutation_group(list/group)
	if(!group)
		return
	for(var/datum/mutation/human/HM in group)
		force_lose(HM)

/datum/dna/proc/generate_uni_identity()
	. = ""
	var/list/L = new /list(DNA_UNI_IDENTITY_BLOCKS)

	L[DNA_GENDER_BLOCK] = construct_block((holder.gender!=MALE)+1, 2)
	if(ishuman(holder))
		var/mob/living/carbon/human/H = holder
		if(!GLOB.hair_styles_list.len)
			init_sprite_accessory_subtypes(/datum/sprite_accessory/hair,GLOB.hair_styles_list, GLOB.hair_styles_male_list, GLOB.hair_styles_female_list)
		L[DNA_HAIR_STYLE_BLOCK] = construct_block(GLOB.hair_styles_list.Find(H.hair_style), GLOB.hair_styles_list.len)
		L[DNA_HAIR_COLOR_BLOCK] = sanitize_hexcolor(H.hair_color)
		if(!GLOB.facial_hair_styles_list.len)
			init_sprite_accessory_subtypes(/datum/sprite_accessory/facial_hair, GLOB.facial_hair_styles_list, GLOB.facial_hair_styles_male_list, GLOB.facial_hair_styles_female_list)
		L[DNA_FACIAL_HAIR_STYLE_BLOCK] = construct_block(GLOB.facial_hair_styles_list.Find(H.facial_hair_style), GLOB.facial_hair_styles_list.len)
		L[DNA_FACIAL_HAIR_COLOR_BLOCK] = sanitize_hexcolor(H.facial_hair_color)
		L[DNA_SKIN_TONE_BLOCK] = construct_block(GLOB.skin_tones.Find(H.skin_tone), GLOB.skin_tones.len)
		L[DNA_EYE_COLOR_BLOCK] = sanitize_hexcolor(H.eye_color)

	for(var/i=1, i<=DNA_UNI_IDENTITY_BLOCKS, i++)
		if(L[i])
			. += L[i]
		else
			. += random_string(DNA_BLOCK_SIZE,GLOB.hex_characters)
	return .

/datum/dna/proc/generate_struc_enzymes()
	var/list/sorting = new /list(DNA_STRUC_ENZYMES_BLOCKS)
	var/result = ""
	var/list/mutations_temp = GLOB.good_mutations + GLOB.bad_mutations + GLOB.not_good_mutations
	shuffle_inplace(mutations_temp)
	to_chat(world,"1")
	for(var/i in 1 to DNA_STRUC_ENZYMES_BLOCKS)
		var/datum/mutation/M = mutations_temp[i]
		mutation_index[M.type] = i
		to_chat(world,"2")
	to_chat(world,"3")
	for(var/M in mutation_index)
		to_chat(world,"4-[M]")
		var/datum/mutation/human/A = M
		if(initial(A.name) == RACEMUT && ismonkey(holder))
			to_chat(world,"4.1")
			sorting[mutation_index[A]] = num2hex(initial(A.lowest_value) + rand(0, 256 * 6), DNA_BLOCK_SIZE)
			mutations |= new A()
		else
			to_chat(world,"4.2")
			sorting[mutation_index[A]] = random_string(DNA_BLOCK_SIZE, list("0","1","2","3","4","5","6"))

	for(var/B in sorting)
		result += B
	return result

/datum/dna/proc/generate_unique_enzymes()
	. = ""
	if(istype(holder))
		real_name = holder.real_name
		. += md5(holder.real_name)
	else
		. += random_string(DNA_UNIQUE_ENZYMES_LEN, GLOB.hex_characters)
	return .

/datum/dna/proc/update_ui_block(blocknumber)
	if(!blocknumber || !ishuman(holder))
		return
	var/mob/living/carbon/human/H = holder
	switch(blocknumber)
		if(DNA_HAIR_COLOR_BLOCK)
			setblock(uni_identity, blocknumber, sanitize_hexcolor(H.hair_color))
		if(DNA_FACIAL_HAIR_COLOR_BLOCK)
			setblock(uni_identity, blocknumber, sanitize_hexcolor(H.facial_hair_color))
		if(DNA_SKIN_TONE_BLOCK)
			setblock(uni_identity, blocknumber, construct_block(GLOB.skin_tones.Find(H.skin_tone), GLOB.skin_tones.len))
		if(DNA_EYE_COLOR_BLOCK)
			setblock(uni_identity, blocknumber, sanitize_hexcolor(H.eye_color))
		if(DNA_GENDER_BLOCK)
			setblock(uni_identity, blocknumber, construct_block((H.gender!=MALE)+1, 2))
		if(DNA_FACIAL_HAIR_STYLE_BLOCK)
			setblock(uni_identity, blocknumber, construct_block(GLOB.facial_hair_styles_list.Find(H.facial_hair_style), GLOB.facial_hair_styles_list.len))
		if(DNA_HAIR_STYLE_BLOCK)
			setblock(uni_identity, blocknumber, construct_block(GLOB.hair_styles_list.Find(H.hair_style), GLOB.hair_styles_list.len))

/datum/dna/proc/force_give(datum/mutation/human/HM)
	if(holder)
		var/datum/mutation/human/A = new HM()
		to_chat(world,"6-[A]-[HM]")
		set_block(1, A)
		. = A.on_acquiring(holder)
		if(.)
			qdel(A)

/datum/dna/proc/force_lose(datum/mutation/human/HM)
	if(holder)
		var/datum/mutation/human/A
		if(ispath(HM) && mutations[HM])
			A = mutations[HM]
		else if(!ispath(HM))
			A = HM
		else
			return TRUE
		set_block(holder, 0, HM)
		. = A.on_losing(holder)

/datum/dna/proc/mutations_say_mods(message)
	if(message)
		for(var/datum/mutation/human/M in mutations)
			message = M.say_mod(message)
		return message

/datum/dna/proc/mutations_get_spans()
	var/list/spans = list()
	for(var/datum/mutation/human/M in mutations)
		spans |= M.get_spans()
	return spans

/datum/dna/proc/species_get_spans()
	var/list/spans = list()
	if(species)
		spans |= species.get_spans()
	return spans


/datum/dna/proc/is_same_as(datum/dna/D)
	if(uni_identity == D.uni_identity && struc_enzymes == D.struc_enzymes && real_name == D.real_name)
		if(species.type == D.species.type && features == D.features && blood_type == D.blood_type)
			return 1
	return 0

//used to update dna UI, UE, and dna.real_name.
/datum/dna/proc/update_dna_identity()
	uni_identity = generate_uni_identity()
	unique_enzymes = generate_unique_enzymes()

/datum/dna/proc/initialize_dna(newblood_type)
	if(newblood_type)
		blood_type = newblood_type
	unique_enzymes = generate_unique_enzymes()
	uni_identity = generate_uni_identity()
	struc_enzymes = generate_struc_enzymes()
	features = random_features()


/datum/dna/stored //subtype used by brain mob's stored_dna

/datum/dna/stored/add_mutation(mutation_name) //no mutation changes on stored dna.
	return

/datum/dna/stored/remove_mutation(mutation_name)
	return

/datum/dna/stored/check_mutation(mutation_name)
	return

/datum/dna/stored/remove_all_mutations()
	return

/datum/dna/stored/remove_mutation_group(list/group)
	return

/////////////////////////// DNA MOB-PROCS //////////////////////

/mob/proc/set_species(datum/species/mrace, icon_update = 1)
	return

/mob/living/brain/set_species(datum/species/mrace, icon_update = 1)
	if(mrace)
		if(ispath(mrace))
			stored_dna.species = new mrace()
		else
			stored_dna.species = mrace //not calling any species update procs since we're a brain, not a monkey/human


/mob/living/carbon/set_species(datum/species/mrace, icon_update = TRUE, pref_load = FALSE)
	if(mrace && has_dna())
		var/datum/species/new_race
		if(ispath(mrace))
			new_race = new mrace
		else if(istype(mrace))
			new_race = mrace
		else
			return
		dna.species.on_species_loss(src, new_race, pref_load)
		var/datum/species/old_species = dna.species
		dna.species = new_race
		dna.species.on_species_gain(src, old_species, pref_load)

/mob/living/carbon/human/set_species(datum/species/mrace, icon_update = TRUE, pref_load = FALSE)
	..()
	if(icon_update)
		update_body()
		update_hair()
		update_body_parts()
		update_mutations_overlay()// no lizard with human hulk overlay please.


/mob/proc/has_dna()
	return

/mob/living/carbon/has_dna()
	return dna


/mob/living/carbon/human/proc/hardset_dna(ui, se, newreal_name, newblood_type, datum/species/mrace, newfeatures)

	if(newfeatures)
		dna.features = newfeatures

	if(mrace)
		var/datum/species/newrace = new mrace.type
		newrace.copy_properties_from(mrace)
		set_species(newrace, icon_update=0)

	if(newreal_name)
		real_name = newreal_name
		dna.generate_unique_enzymes()

	if(newblood_type)
		dna.blood_type = newblood_type

	if(ui)
		dna.uni_identity = ui
		updateappearance(icon_update=0)

	if(se)
		dna.struc_enzymes = se
		domutcheck()

	if(mrace || newfeatures || ui)
		update_body()
		update_hair()
		update_body_parts()
		update_mutations_overlay()


/mob/living/carbon/proc/create_dna()
	dna = new /datum/dna(src)
	if(!dna.species)
		var/rando_race = pick(GLOB.roundstart_races)
		dna.species = new rando_race()

//proc used to update the mob's appearance after its dna UI has been changed
/mob/living/carbon/proc/updateappearance(icon_update=1, mutcolor_update=0, mutations_overlay_update=0)
	if(!has_dna())
		return
	gender = (deconstruct_block(getblock(dna.uni_identity, DNA_GENDER_BLOCK), 2)-1) ? FEMALE : MALE

/mob/living/carbon/human/updateappearance(icon_update=1, mutcolor_update=0, mutations_overlay_update=0)
	..()
	var/structure = dna.uni_identity
	hair_color = sanitize_hexcolor(getblock(structure, DNA_HAIR_COLOR_BLOCK))
	facial_hair_color = sanitize_hexcolor(getblock(structure, DNA_FACIAL_HAIR_COLOR_BLOCK))
	skin_tone = GLOB.skin_tones[deconstruct_block(getblock(structure, DNA_SKIN_TONE_BLOCK), GLOB.skin_tones.len)]
	eye_color = sanitize_hexcolor(getblock(structure, DNA_EYE_COLOR_BLOCK))
	facial_hair_style = GLOB.facial_hair_styles_list[deconstruct_block(getblock(structure, DNA_FACIAL_HAIR_STYLE_BLOCK), GLOB.facial_hair_styles_list.len)]
	hair_style = GLOB.hair_styles_list[deconstruct_block(getblock(structure, DNA_HAIR_STYLE_BLOCK), GLOB.hair_styles_list.len)]
	if(icon_update)
		update_body()
		update_hair()
		if(mutcolor_update)
			update_body_parts()
		if(mutations_overlay_update)
			update_mutations_overlay()


/mob/proc/domutcheck()
	return

/mob/living/carbon/domutcheck(force_powers=0) //Set force_powers to 1 to bypass the power chance
	if(!has_dna())
		return


	for(var/datum/mutation/A in dna.mutation_index)
		if(ismob(dna.check_block(force_powers, A)))
			return //we got monkeyized/humanized, this mob will be deleted, no need to continue.

	update_mutations_overlay()

/datum/dna/proc/check_block(force_power=0, datum/mutation/human/A)
	if(check_block_string())
		if(prob(initial(A.get_chance)) || force_power)
			if(ispath(A))
				. = A.on_acquiring(holder)
	else if(!ispath(A))
		. = A.on_losing(holder)

/datum/dna/proc/check_block_string(se_string, datum/mutation/human/A)
	if(!se_string)
		se_string = struc_enzymes
	if(lentext(se_string) < DNA_STRUC_ENZYMES_BLOCKS * DNA_BLOCK_SIZE)
		return 0
	if(hex2num(getblock(se_string, mutation_index[A])) >= initial(A.lowest_value))
		return 1

/datum/dna/proc/set_se(on=TRUE, datum/mutation/human/A)
	if(!struc_enzymes || lentext(struc_enzymes) < DNA_STRUC_ENZYMES_BLOCKS * DNA_BLOCK_SIZE)
		return
	to_chat(world,"8-[A]")
	var/lowest_value = initial(A.lowest_value)
	var/before = copytext(struc_enzymes, 1, ((mutation_index[A] - 1) * DNA_BLOCK_SIZE) + 1)
	var/injection = num2hex(on ? rand(lowest_value, (256 * 16) - 1) : rand(0, lowest_value - 1), DNA_BLOCK_SIZE)
	var/after = copytext(struc_enzymes, (mutation_index[A] * DNA_BLOCK_SIZE) + 1, 0)
	return before + injection + after


/datum/dna/proc/set_block(on=TRUE, datum/mutation/human/A)
	if(holder && holder.has_dna())
		struc_enzymes = set_se(on, A)


/////////////////////////// DNA HELPER-PROCS //////////////////////////////
/proc/getleftblocks(input,blocknumber,blocksize)
	if(blocknumber > 1)
		return copytext(input,1,((blocksize*blocknumber)-(blocksize-1)))

/proc/getrightblocks(input,blocknumber,blocksize)
	if(blocknumber < (length(input)/blocksize))
		return copytext(input,blocksize*blocknumber+1,length(input)+1)

/proc/getblock(input, blocknumber, blocksize=DNA_BLOCK_SIZE)
	return copytext(input, blocksize*(blocknumber-1)+1, (blocksize*blocknumber)+1)

/proc/setblock(istring, blocknumber, replacement, blocksize=DNA_BLOCK_SIZE)
	if(!istring || !blocknumber || !replacement || !blocksize)
		return 0
	return getleftblocks(istring, blocknumber, blocksize) + replacement + getrightblocks(istring, blocknumber, blocksize)

/mob/living/carbon/proc/randmut(list/candidates, difficulty = 2)
	if(!has_dna())
		return
	var/datum/mutation/human/num = pick(candidates)
	. = dna.force_give(num)

/mob/living/carbon/proc/randmutb()
	if(!has_dna())
		return
	var/list/possible = list()
	for(var/A in dna.mutation_index)
		to_chat(world,"1")
		var/datum/mutation/human/HM = A
		to_chat(world,"2-[HM]")
		if(initial(HM.quality) == POSITIVE)
			possible += HM
	if(possible.len)
		. = dna.force_give(pick(possible))
		return TRUE

/mob/living/carbon/proc/randmutg()
	if(!has_dna())
		return
	var/list/possible = list()
	for(var/A in dna.mutation_index)
		to_chat(world,"1")
		var/datum/mutation/human/HM = A
		to_chat(world,"2-[HM]")
		if(initial(HM.quality) == NEGATIVE)
			possible += HM
	if(possible.len)
		. = dna.force_give(pick(possible))
		return TRUE

/mob/living/carbon/proc/randmuti()
	if(!has_dna())
		return
	var/num = rand(1, DNA_UNI_IDENTITY_BLOCKS)
	var/newdna = setblock(dna.uni_identity, num, random_string(DNA_BLOCK_SIZE, GLOB.hex_characters))
	dna.uni_identity = newdna
	updateappearance(mutations_overlay_update=1)

/mob/living/carbon/proc/clean_dna()
	if(!has_dna())
		return
	dna.remove_all_mutations()

/mob/living/carbon/proc/clean_randmut(list/candidates, difficulty = 2)
	clean_dna()
	randmut(candidates, difficulty)

/proc/scramble_dna(mob/living/carbon/M, ui=FALSE, se=FALSE, probability)
	if(!M.has_dna())
		return 0
	if(se)
		for(var/i=1, i<=DNA_STRUC_ENZYMES_BLOCKS, i++)
			if(prob(probability))
				M.dna.struc_enzymes = setblock(M.dna.struc_enzymes, i, random_string(DNA_BLOCK_SIZE, GLOB.hex_characters))
		M.domutcheck()
	if(ui)
		for(var/i=1, i<=DNA_UNI_IDENTITY_BLOCKS, i++)
			if(prob(probability))
				M.dna.uni_identity = setblock(M.dna.uni_identity, i, random_string(DNA_BLOCK_SIZE, GLOB.hex_characters))
		M.updateappearance(mutations_overlay_update=1)
	return 1

//value in range 1 to values. values must be greater than 0
//all arguments assumed to be positive integers
/proc/construct_block(value, values, blocksize=DNA_BLOCK_SIZE)
	var/width = round((16**blocksize)/values)
	if(value < 1)
		value = 1
	value = (value * width) - rand(1,width)
	return num2hex(value, blocksize)

//value is hex
/proc/deconstruct_block(value, values, blocksize=DNA_BLOCK_SIZE)
	var/width = round((16**blocksize)/values)
	value = round(hex2num(value) / width) + 1
	if(value > values)
		value = values
	return value

/////////////////////////// DNA HELPER-PROCS
