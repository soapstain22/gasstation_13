/obj/item/skillchip
	name = "skillchip"
	desc = "This biochip integrates with user's brain to enable mastery of specific skill. Consult certified Nanotrasen neurosurgeon before use."

	icon = 'icons/obj/card.dmi'
	icon_state = "data_3"
	custom_price = 500
	w_class = WEIGHT_CLASS_SMALL

	/// Trait automatically granted by this chip, optional
	var/auto_trait
	/// Skill name shown on UI
	var/skill_name
	/// Skill description shown on UI
	var/skill_description
	/// Category string. Used alongside SKILLCHIP_RESTRICTED_CATEGORIES flag to make a chip incompatible with chips from another category.
	var/chip_category = "general"
	/// List of any incompatible categories.
	var/list/incompatibility_list
	/// Fontawesome icon show on UI, list of possible icons https://fontawesome.com/icons?d=gallery&m=free
	var/skill_icon = "brain"
	/// Message shown when activating the chip
	var/activate_message
	/// Message shown when deactivating the chip
	var/deactivate_message
	//If set to FALSE, trying to extract the chip will destroy it instead
	var/removable = TRUE
	/// How many skillslots this one takes
	var/slot_cost = 1
	/// Variable for flags. DANGEROUS - Child types overwrite flags instead of adding to them. If you change this, make sure all child types have the appropriate flags set too.
	var/skillchip_flags = NONE
	/// Cooldown before the skillchip can be extracted after it has been implanted.
	var/cooldown = 5 MINUTES
	/// Cooldown for chip extractability
	COOLDOWN_DECLARE(extract_cooldown)
	/// Used to determine if this is an abstract type or not. If this is meant to be an abstract type, set it to the type's path. Will be overridden by subsequent abstract parents. See /datum/action/item_action/chameleon/change/skillchip/initialize_disguises()
	var/abstract_parent_type = /obj/item/skillchip
	/// Set to TRUE when the skill chip's effects are applied. Set to FALSE when they're not.
	var/active = FALSE

/obj/item/skillchip/Initialize(is_removable = TRUE)
	. = ..()
	removable = is_removable

/**
  * Called when a skillchip is inserted in the user's brain.
  *
  * Arguments:
  * * user - The user to apply skillchip effects to.
  * * silent - Boolean. Whether or not an activation message should be shown to the user.
  * * activate - Boolean. Whether or not to activate the skillchip's effects.
  */
/obj/item/skillchip/proc/on_implant(mob/living/carbon/user, silent=TRUE, activate=TRUE)
	if(activate)
		on_activate(user, silent)

	user.used_skillchip_slots += slot_cost

/**
  * Called when a skillchip is activated.
  *
  * Arguments:
  * * user - The user to apply skillchip effects to.
  * * silent - Boolean. Whether or not an activation message should be shown to the user.
  */
/obj/item/skillchip/proc/on_activate(mob/living/carbon/user, silent=TRUE)
	if(!silent && activate_message)
		to_chat(user, activate_message)

	if(auto_trait)
		ADD_TRAIT(user, auto_trait, SKILLCHIP_TRAIT)

	active = TRUE
	COOLDOWN_START(src, extract_cooldown, cooldown)

/**
  * Called when a skillchip is removed from the user's brain or the brain is removed from the user's body.
  *
  * Always deactivates the skillchip.
  * Arguments:
  * * user - The user to remove skillchip effects from.
  * * silent - Boolean. Whether or not a deactivation message should be shown to the user.
  */
/obj/item/skillchip/proc/on_removal(mob/living/carbon/user, silent=TRUE)
	on_deactivate(user, silent)

	user.used_skillchip_slots -= slot_cost

/**
  * Called when a skillchip is deactivated.
  *
  * Arguments:
  * * user - The user to remove skillchip effects from.
  * * silent - Boolean. Whether or not a deactivation message should be shown to the user.
  */
/obj/item/skillchip/proc/on_deactivate(mob/living/carbon/user, silent=TRUE)
	if(!silent && deactivate_message)
		to_chat(user, deactivate_message)

	if(auto_trait)
		REMOVE_TRAIT(user, auto_trait, SKILLCHIP_TRAIT)

	active = FALSE
	COOLDOWN_RESET(src, extract_cooldown)

/**
  * Checks for skillchip incompatibility with another chip.
  *
  * Override this with any snowflake chip-vs-chip incompatibility checks.
  * Returns a string with an incompatibility explanation if the chip is not compatible, returns FALSE
  * if it is compatible.
  * Arguments:
  * * skillchip - The skillchip to test for incompatability.
  */
/obj/item/skillchip/proc/has_skillchip_incompatibility(obj/item/skillchip/skillchip)
	// If this is a SKILLCHIP_UNIQUE_IN_CATEGORY it is incompatible with chips of the same category.
	if((skillchip_flags & SKILLCHIP_RESTRICTED_CATEGORIES) && (skillchip.chip_category in incompatibility_list))
		return "Incompatible with other [chip_category] chip: [skillchip.name]"

	// Only allow multiple copies of a type if SKILLCHIP_ALLOWS_MULTIPLE flag is set
	if(!(skillchip_flags & SKILLCHIP_ALLOWS_MULTIPLE) && (skillchip.type == type))
		return "Duplicate chip detected."

	return FALSE

/**
  * Performs a full sweep of checks that dictate if this chip can be implanted in a given target.
  *
  * Override this with any snowflake chip checks. An example of which would be checking if a target is
  * mindshielded if you've got a special security skillchip.
  * Returns a string with an incompatibility explanation if the chip is not compatible, returns FALSE
  * if it is compatible.
  * Arguments:
  * * target - The mob to check for implantability with.
  */
/obj/item/skillchip/proc/has_mob_incompatibility(mob/living/carbon/target)
	// No carbon/carbon of incorrect type
	if(!istype(target))
		return "Incompatible lifeform detected."

	// No brain
	var/obj/item/organ/brain/brain = target.getorganslot(ORGAN_SLOT_BRAIN)
	if(QDELETED(brain))
		return "No brain detected."

	// No skill slots left
	if(target.used_skillchip_slots + slot_cost > target.max_skillchip_slots)
		return "Complexity limit exceeded."

	// Check brain incompatibility. This also performs skillchip-to-skillchip incompatibility checks.
	var/brain_message = has_brain_incompatibility(brain)
	if(brain_message)
		return brain_message

	return FALSE

/**
  * Performs a full sweep of checks that dictate if this chip can be implanted in a given brain.
  *
  * Override this with any snowflake chip checks.
  * Returns TRUE if the chip is fully compatible, FALSE otherwise.
  * Arguments:
  * * brain - The brain to check for implantability with.
  */
/obj/item/skillchip/proc/has_brain_incompatibility(obj/item/organ/brain/brain)
	if(!istype(brain))
		stack_trace("Attempted to check incompatibility with invalid brain object [brain].")
		return "Incompatible brain."

	var/chip_message

	// Check if this chip is incompatible with any other chips in the brain.
	for(var/skillchip in brain.skillchips)
		chip_message = has_skillchip_incompatibility(skillchip)
		if(chip_message)
			return chip_message

	return FALSE

/**
  * Returns whether the chip is able to be removed safely.
  *
  * This does not mean the chip should be impossible to remove. It's up to each individual
  * piece of code to decide what it does with the result of this proc.
  *
  * Returns FALSE if the chip's extraction cooldown hasn't yet passed.
  */
/obj/item/skillchip/proc/can_remove_safely()
	if(!COOLDOWN_FINISHED(src, extract_cooldown))
		return FALSE

	return TRUE

/**
  * Returns a list of basic chip info. Used by the skill station.
  */
/obj/item/skillchip/proc/get_chip_data()
	return list(
		"name" = skill_name,
		"icon" = skill_icon,
		"cost" = slot_cost,
		"ref" = REF(src),
		"active" = active,
		"cooldown" = COOLDOWN_TIMELEFT(src, extract_cooldown),
		"removable" = can_remove_safely())

/obj/item/skillchip/basketweaving
	name = "Basketsoft 3000 skillchip"
	desc = "Underwater edition."
	auto_trait = TRAIT_UNDERWATER_BASKETWEAVING_KNOWLEDGE
	skill_name = "Underwater Basketweaving"
	skill_description = "Master intricate art of using twine to create perfect baskets while submerged."
	skill_icon = "shopping-basket"
	activate_message = "<span class='notice'>You're one with the twine and the sea.</span>"
	deactivate_message = "<span class='notice'>Higher mysteries of underwater basketweaving leave your mind.</span>"

/obj/item/skillchip/wine_taster
	name = "WINE skillchip"
	desc = "Wine.Is.Not.Equal version 5."
	auto_trait = TRAIT_WINE_TASTER
	skill_name = "Wine Tasting"
	skill_description = "Recognize wine vintage from taste alone. Never again lack an opinion when presented with an unknown drink."
	skill_icon = "wine-bottle"
	activate_message = "<span class='notice'>You recall wine taste.</span>"
	deactivate_message = "<span class='notice'>Your memories of wine evaporate.</span>"

/obj/item/skillchip/bonsai
	name = "Hedge 3 skillchip"
	auto_trait = TRAIT_BONSAI
	skill_name = "Hedgetrimming"
	skill_description = "Trim hedges and potted plants into marvelous new shapes with any old knife. Not applicable to plastic plants."
	skill_icon = "spa"
	activate_message = "<span class='notice'>Your mind is filled with plant arrangments.</span>"
	deactivate_message = "<span class='notice'>Your can't remember how a hedge looks like anymore.</span>"

/obj/item/skillchip/useless_adapter
	name = "Skillchip adapter"
	skill_name = "Useless adapter"
	skill_description = "Allows you to insert another identical skillchip into this adapter, but the adapter also takes a slot ..."
	skill_icon = "plug"
	activate_message = "<span class='notice'>You can now implant another chip into this adapter, but the adapter also took up an existing slot ...</span>"
	deactivate_message = "<span class='notice'>You no longer have the useless skillchip adapter.</span>"
	skillchip_flags = SKILLCHIP_ALLOWS_MULTIPLE | SKILLCHIP_CHAMELEON_INCOMPATIBLE
	slot_cost = 0

/obj/item/skillchip/useless_adapter/on_implant(mob/living/carbon/user, silent, activate)
	. = ..()
	user.max_skillchip_slots++
	user.used_skillchip_slots++

/obj/item/skillchip/useless_adapter/on_removal(mob/living/carbon/user, silent)
	user.max_skillchip_slots--
	user.used_skillchip_slots--
	return ..()
