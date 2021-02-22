// Ampoule dot colors:
/// The dot color used to indicate the presence of a solvent.
#define AMPOULE_DOT_SOLVENT "white"
/// The dot color used to indicate the presence of a catalyst.
#define AMPOULE_DOT_CATALYST "yellow"
/// The dot color used to indicate the presence of a medicine.
#define AMPOULE_DOT_MEDICINE "blue"
/// The dot color used to indicate the presence of a toxin.
#define AMPOULE_DOT_TOXIN "red"
/// The dot color used to indicate the presence of a disease.
#define AMPOULE_DOT_DISEASE "black"
/// The dot color used to indicate the presence of a radioactive substance.
#define AMPOULE_DOT_RADIATION "green"
/// The dot color used to indicate the presence of an explosive.
#define AMPOULE_DOT_EXPLOSIVE "orange"
/// The dot color used to indicate the presence of an acid.
#define AMPOULE_DOT_ACID "violet"


/**
 *
 *
 * Behaviors:
 * - Sealing/Unsealing
 */
/obj/item/reagent_containers/glass/ampoule
	name = "ampoule"
	desc = "A glass ampoule."
	icon_state = "ampoule"
	base_icon_state = "ampoule"
	inhand_icon_state = "beaker"
	worn_icon_state = "bottle"
	custom_materials = list(/datum/material/glass = 25)
	fill_icon_thresholds = list(0, 20, 30, 45, 60, 70, 85)
	fill_icon_state = "ampoule"
	max_integrity = 10
	integrity_failure = 0.5
	volume = 15
	amount_per_transfer_from_this = 5
	possible_transfer_amounts = list(5, 10, 15)
	/// Are we currently sealed?
	var/sealed = TRUE
	/// Are we curently broken?
	var/broken = FALSE
	/// The gases contained within this ampoule.
	var/datum/gas_mixture/air_contents
	/// The gases this ampoule was originally filled with.
	var/initial_gas_mix
	/// What color this is marked with.
	var/dot_color
	/// What this is labeled as containing.
	var/label_text


/obj/item/reagent_containers/glass/ampoule/Initialize(mapload, vol)
	. = ..()
	air_contents = new(volume * 0.1)
	if(!sealed)
		unseal(FALSE)
		return
	seal(FALSE)
	populate_gases()

/obj/item/reagent_containers/glass/ampoule/Destroy()
	initial_gas_mix = null
	QDEL_NULL(air_contents)
	return ..()

/obj/item/reagent_containers/glass/ampoule/examine(mob/user)
	. = ..()
	if(dot_color && sealed && !broken)
		. += "[p_theyre()] marked with a [dot_color] dot."
	if(!isnull(label_text))
		if(!istext(label_text))
			. += "[p_theyre()] labeled, but the label is illegible."
		else if(!length(label_text))
			. += "[p_theyre()] labeled, but the label is blank."
		else
			. += "[p_theyre()] labeled as containing [label_text]."

/obj/item/reagent_containers/glass/ampoule/update_name(updates)
	if(broken)
		name = "broken [initial(name)]"
	else if(!sealed)
		name = "unsealed [initial(name)]"
	else
		name = "[initial(name)]"
	return ..()

/obj/item/reagent_containers/glass/ampoule/update_icon_state()
	if(broken)
		icon_state = "[base_icon_state]-b"
	else if(!sealed)
		icon_state = "[base_icon_state]-o"
	else
		icon_state = "[base_icon_state]"
	return ..()

/obj/item/reagent_containers/glass/ampoule/update_overlays()
	. = ..()
	if(!isnull(label_text))
		. += "ampoule-label[(!istext(label_text) || length(label_text)) ? "-words" : null]"
	if(dot_color && sealed && !broken)
		var/mutable_appearance/dot = mutable_appearance('icons/obj/chemical.dmi', "ampoule-dot")
		dot.color = color2hex(dot_color)
		. += dot

/obj/item/reagent_containers/glass/ampoule/obj_break(damage_flag)
	if(broken)
		return

	snap()
	broken = TRUE
	sharpness = SHARP_EDGED
	if(!reagents.total_volume)
		return
	chem_splash(get_turf(src), 1, reagents)

/obj/item/reagent_containers/glass/ampoule/assume_air(datum/gas_mixture/giver)
	return sealed ? air_contents.merge(giver) : ..()

/obj/item/reagent_containers/glass/ampoule/remove_air(amount)
	return sealed ? air_contents.remove(amount) : ..()

/obj/item/reagent_containers/glass/ampoule/return_air()
	return sealed ? air_contents : ..()

/obj/item/reagent_containers/glass/ampoule/attack_self(mob/living/user)
	if(!sealed)
		return ..()

	var/clean = TRUE
	if(prob(50))
		clean = FALSE
	else if(HAS_TRAIT(user, TRAIT_CLUMSY) && prob(50))
		clean = FALSE
	else if(HAS_TRAIT(user, TRAIT_CHUNKYFINGERS) && prob(30))
		clean = FALSE
	else if(iscarbon(user))
		var/mob/living/carbon/carbon_user = user
		if(prob(carbon_user.jitteriness))
			clean = FALSE

	if(clean)
		snap()
	else
		obj_break()
	return TRUE

/obj/item/reagent_containers/glass/ampoule/welder_act(mob/living/user, obj/item/tool)
	if(sealed || user.combat_mode)
		return ..()
	var/heat = tool.get_temperature()
	if(heat)
		reagents.expose_temperature(heat)
	try_weld_shut(tool, user)
	return TRUE

/obj/item/reagent_containers/glass/ampoule/wirecutter_act(mob/living/user, obj/item/tool)
	if(!sealed || user.combat_mode)
		return ..()
	var/heat = tool.get_temperature()
	if(heat)
		reagents.expose_temperature(heat, coeff = 0.01)
	try_cut_open(tool, user)
	return TRUE

/obj/item/reagent_containers/glass/ampoule/attackby(obj/item/tool, mob/living/user, params)
	if(!sealed || !tool.force || !tool.sharpness || user.combat_mode)
		return ..()
	var/heat = tool.get_temperature()
	if(heat)
		reagents.expose_temperature(heat, coeff = 0.01)
	try_cut_open(tool, user)
	return TRUE

/obj/item/reagent_containers/glass/ampoule/try_splash(mob/user, atom/target)
	if(sealed)
		if(prob(20))
			snap()
		else
			obj_break()
	return ..()

/obj/item/reagent_containers/glass/ampoule/process(delta_time)
	var/datum/gas_mixture/env = loc?.return_air()
	if(env)
		air_contents.archive()
		air_contents.temperature_share(env)

	air_contents.react(src)
	reagents.expose_temperature(air_contents.temperature)
	if(air_contents.return_pressure() > TANK_LEAK_PRESSURE)
		obj_break(BOMB)

/**
 * Populates the internal gas mixture of the ampoule.
 */
/obj/item/reagent_containers/glass/ampoule/proc/populate_gases(source = initial_gas_mix)
	if(!source)
		return FALSE

	if(istext(source))
		air_contents.parse_gas_string(source)
	else if(istype(source, /datum/gas_mixture))
		var/datum/gas_mixture/source_mix = source
		air_contents.copy_from(source_mix, air_contents.volume / source_mix.volume)
	else if(islist(source))
		var/list/source_list = source
		var/list/cached_gas = air_contents.gases
		cached_gas &= source_list
		for(var/gas_id in source_list)
			if(gas_id == "TEMP")
				air_contents.temperature = source_list[gas_id]
				continue
			ADD_GAS(gas_id, cached_gas)
			cached_gas[gas_id][MOLES] = source_list[MOLES]
	else
		CRASH("Invalid source - [isnull(source) ? "NULL" : source] - passed to ampoule.populate_gas() .")

	START_PROCESSING(SSobj, src)
	return TRUE

/**
 * Seals this ampoule.
 *
 * Makes the ampoule incapable of being poured out/into.
 * Internalizes some of the gases from the environment outside of the ampoule.
 *
 * Arguments:
 * - assume_env: Whether the ampoule should bottle up some of the gases in the environment.
 */
/obj/item/reagent_containers/glass/ampoule/proc/seal(assume_env = TRUE)
	sealed = TRUE
	spillable = FALSE
	reagent_flags &= ~OPENCONTAINER
	reagent_flags &= ~OPENCONTAINER
	update_appearance()
	if(!assume_env)
		return

	/// Seal up some gases
	var/atom/location = loc
	var/datum/gas_mixture/env = loc?.return_air()
	if(!env)
		return

	var/datum/gas_mixture/removed_gas = env.remove_ratio((volume * 0.1) / env.volume)
	air_contents.merge(removed_gas)
	location.air_update_turf(FALSE, FALSE)
	START_PROCESSING(SSobj, src)

/**
 * Unseals this ampoule.
 *
 * Makes the ampoule able to be poured out/poured into.
 * Merges the gases inside the ampoule with the environment outside of the ampoule.
 *
 * Arguments:
 * - spill_gases: Whether the ampoule should release the gases in it into the environment.
 */
/obj/item/reagent_containers/glass/ampoule/proc/unseal(spill_gases = TRUE)
	sealed = FALSE
	spillable = TRUE
	reagent_flags |= OPENCONTAINER
	reagents.flags |= OPENCONTAINER
	dot_color = null
	update_appearance()
	if(!spill_gases)
		return

	STOP_PROCESSING(SSobj, src)
	var/datum/gas_mixture/released_gases = air_contents.remove_ratio(1)
	var/atom/location = loc
	if(!location)
		return
	location.assume_air(released_gases)
	location.air_update_turf(FALSE, FALSE)

/**
 * Handles a mob attempting to cut this ampoule open.
 *
 * Arguments:
 * - [tool][/mob/living]: The tool being used to score the ampoule.
 * - [user][/mob/living]: The mob trying to open the ampoule.
 */
/obj/item/reagent_containers/glass/ampoule/proc/try_cut_open(obj/item/tool, mob/living/user)
	if(!sealed)
		return

	var/extra_delay = 1
	if(HAS_TRAIT(user, TRAIT_CLUMSY))
		extra_delay *= 2
	if(HAS_TRAIT(user, TRAIT_CHUNKYFINGERS))
		extra_delay *= 1.5
	if(iscarbon(user))
		var/mob/living/carbon/carbon_user = user
		if(carbon_user.jitteriness > 0)
			extra_delay *= 1 + (carbon_user.jitteriness / 30)

	to_chat(user, "<span class='notice'>You begin to score [src] with [tool]...</span>")
	if(!tool.use_tool(src, user, 1 SECONDS * extra_delay))
		to_chat(user, "<span class='warning'>You can't keep [tool] steady enough and break [src]!</span>")
		obj_break(MELEE)
		return FALSE

	to_chat(user, "<span class='notice'>You unseal [src].</span>")
	snap()
	return TRUE

/**
 * Used to attempt to weld the ampoule shut.
 *
 * Arguments:
 * - [tool][/obj/item]: The tool being used to weld the ampoule shut.
 * - [user][/mob/living]: The mob trying to weld the ampoule shut.
 */
/obj/item/reagent_containers/glass/ampoule/proc/try_weld_shut(obj/item/tool, mob/living/user)
	if(sealed)
		return FALSE
	if(broken)
		to_chat(user, "<span class='warning'>[src] is broken and can't be resealed!</span>")
		return FALSE

	to_chat(user, "<span class='notice'>You start to soften [src] with [tool]...</span>")
	if(!tool.use_tool(src, user, 5 SECONDS))
		return FALSE

	to_chat(user, "<span class='notice'>You seal up [src]!</span>")
	seal()
	return TRUE

/**
 * Snaps the ampoule.
 */
/obj/item/reagent_containers/glass/ampoule/proc/snap()
	unseal()
	playsound(src, 'sound/effects/snap.ogg', 50, TRUE)
	return TRUE

// Variants:

/obj/item/reagent_containers/glass/ampoule/open
	sealed = FALSE

/obj/item/reagent_containers/glass/ampoule/open/broken
	broken = TRUE

/// Medical ampoules. Used to contain medicines.
/obj/item/reagent_containers/glass/ampoule/medical
	name = "medical ampoule"
	desc = "A medical ampoule."
	icon_state = "ampoule-blue"
	base_icon_state = "ampoule-blue"
	dot_color = AMPOULE_DOT_MEDICINE

/obj/item/reagent_containers/glass/ampoule/medical/open
	sealed = FALSE

/obj/item/reagent_containers/glass/ampoule/medical/open/broken
	broken = TRUE

/// Plastic ampoules for construction at the autolathe.
/obj/item/reagent_containers/glass/ampoule/plastic
	name = "plastic ampoule"
	desc = "A plastic ampoule."
	icon_state = "ampoule-white"
	base_icon_state = "ampoule-white"
	custom_materials = list(/datum/material/plastic)

/obj/item/reagent_containers/glass/ampoule/plastic/open
	sealed = FALSE

/obj/item/reagent_containers/glass/ampoule/plastic/open/broken
	broken = TRUE

/// Old ampoules for use in ruins.
/obj/item/reagent_containers/glass/ampoule/old
	name = "old ampoule"
	desc = "An old ampoule."
	icon_state = "ampoule-brown"
	base_icon_state = "ampoule-brown"
	label_text = TRUE

/obj/item/reagent_containers/glass/ampoule/old/open
	sealed = FALSE

/obj/item/reagent_containers/glass/ampoule/old/open/broken
	broken = TRUE

/// Syndicate ampoules.
/obj/item/reagent_containers/glass/ampoule/syndie
	name = "red ampoule"
	desc = "A suspicious ampoule."
	icon_state = "ampoule-red"
	base_icon_state = "ampoule-red"
