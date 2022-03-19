/obj/item/spellbook
	name = "spell book"
	desc = "An unearthly tome that glows with power."
	icon = 'icons/obj/library.dmi'
	icon_state ="book"
	worn_icon_state = "book"
	throw_speed = 2
	throw_range = 5
	w_class = WEIGHT_CLASS_TINY

	/// The number of book charges we have to buy spells
	var/uses = 10
	/// The bonus that you get from going semi-random.
	var/semi_random_bonus = 2
	/// The bonus that you get from going full random.
	var/full_random_bonus = 5
	/// Determines if this spellbook can refund anything.
	var/refunds_allowed = TRUE
	/// A ref to the owner of the book
	var/mob/living/carbon/human/owner
	/// A list to all spellbook entries within
	var/list/entries = list()

/obj/item/spellbook/Initialize(mapload)
	. = ..()
	prepare_spells()

/obj/item/spellbook/Destroy(force)
	owner = null
	entries.Cut()
	return ..()

/// Clears our reference when our owner is deleted.
/// Also destroys the book itself, to prevent other people from binding it to them.
/obj/item/spellbook/proc/destroy_book_on_owner_deletion(datum/source)
	SIGNAL_HANDLER

	owner = null
	visible_message(span_warning("[src] suddenly combusts, burning into a pile of cinders!"))
	new /obj/effect/decal/cleanable/ash(get_turf(src))
	qdel(src)

/obj/item/spellbook/examine(mob/user)
	. = ..()
	if(owner)
		. += {"There is a small signature on the front cover: "[owner]"."}
	else
		. += "It appears to have no author."

/obj/item/spellbook/attack_self(mob/user)
	if(!owner)
		to_chat(user, span_notice("You bind [src] to yourself."))
		owner = user
		RegisterSignal(owner, COMSIG_PARENT_QDELETING, .proc/destroy_book_on_owner_deletion)
		return

	if(user != owner)
		if(user.mind?.special_role == ROLE_WIZARD_APPRENTICE)
			to_chat(user, "If you got caught sneaking a peek from your teacher's spellbook, you'd likely be expelled from the Wizard Academy. Better not.")
		else
			to_chat(user, span_warning("[src] does not recognize you as its owner and refuses to open!"))
		return

	return ..()

/obj/item/spellbook/attackby(obj/item/O, mob/user, params)
	// This can be generalized in the future, but for now it stays
	if(istype(O, /obj/item/antag_spawner/contract))
		var/datum/spellbook_entry/item/contract/contract_entry = locate() in entries
		if(!istype(contract_entry))
			to_chat(user, span_warning("[src] doesn't seem to want to refund [O]."))
			return
		if(!contract_entry.can_refund(user, src))
			to_chat(user, span_warning("You can't refund [src]."))
			return
		var/obj/item/antag_spawner/contract/contract = O
		if(contract.used)
			to_chat(user, span_warning("The contract has been used, you can't get your points back now!"))
			return

		to_chat(user, span_notice("You feed the contract back into the spellbook, refunding your points."))
		uses += contract_entry.cost
		contract_entry.times--
		qdel(O)

	else if(istype(O, /obj/item/antag_spawner/slaughter_demon/laughter))
		var/datum/spellbook_entry/item/hugbottle/demon_entry = locate() in entries
		if(!istype(demon_entry))
			to_chat(user, span_warning("[src] doesn't seem to want to refund [O]."))
			return
		if(!demon_entry.can_refund(user, src))
			to_chat(user, span_warning("You can't refund [O]."))
			return

		to_chat(user, span_notice("On second thought, maybe summoning a demon isn't a funny idea. You refund your points."))
		uses += demon_entry.cost
		demon_entry.times--
		qdel(O)

	else if(istype(O, /obj/item/antag_spawner/slaughter_demon))
		var/datum/spellbook_entry/item/bloodbottle/demon_entry = locate() in entries
		if(!istype(demon_entry))
			to_chat(user, span_warning("[src] doesn't seem to want to refund [O]."))
			return
		if(!demon_entry.can_refund(user, src))
			to_chat(user, span_warning("You can't refund [O]."))
			return

		to_chat(user, span_notice("On second thought, maybe summoning a demon is a bad idea. You refund your points."))
		uses += demon_entry.cost
		demon_entry.times--
		qdel(O)

	return ..()

/// Instantiates our list of spellbook entries.
/obj/item/spellbook/proc/prepare_spells()
	var/entry_types = subtypesof(/datum/spellbook_entry)
	for(var/type in entry_types)
		var/datum/spellbook_entry/possible_entry = new type()
		if(!possible_entry.can_be_purchased())
			qdel(possible_entry)
			continue

		possible_entry.set_spell_info() //loads up things for the entry that require checking spell instance.
		entries |= possible_entry

/obj/item/spellbook/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Spellbook")
		ui.open()

/obj/item/spellbook/ui_data(mob/user)
	var/list/data = list()
	data["owner"] = owner
	data["points"] = uses
	data["semi_random_bonus"] = initial(uses) + semi_random_bonus
	data["full_random_bonus"] = initial(uses) + full_random_bonus
	return data

//This is a MASSIVE amount of data, please be careful if you remove it from static.
/obj/item/spellbook/ui_static_data(mob/user)
	var/list/data = list()
	// Collect all info from each intry.
	var/list/entry_data = list()
	for(var/datum/spellbook_entry/entry as anything in entries)
		var/list/individual_entry_data = list()
		individual_entry_data["name"] = entry.name
		individual_entry_data["desc"] = entry.desc
		individual_entry_data["ref"] = REF(entry)
		individual_entry_data["requires_wizard_garb"] = entry.requires_wizard_garb
		individual_entry_data["cost"] = entry.cost
		individual_entry_data["times"] = entry.times
		individual_entry_data["cooldown"] = entry.cooldown
		individual_entry_data["cat"] = entry.category
		individual_entry_data["refundable"] = entry.refundable
		individual_entry_data["buyword"] = entry.buy_word
		entry_data += list(individual_entry_data)

	data["entries"] = entry_data
	return data

/obj/item/spellbook/ui_act(action, params)
	. = ..()
	if(.)
		return
	var/mob/living/carbon/human/wizard = usr
	if(!istype(wizard))
		to_chat(wizard, span_warning("The book doesn't seem to listen to lower life forms."))
		return FALSE

	// Actions that are always available
	switch(action)
		if("purchase")
			var/datum/spellbook_entry/entry = locate(params["spellref"]) in entries
			return purchase_entry(entry, wizard)

		if("refund")
			var/datum/spellbook_entry/entry = locate(params["spellref"]) in entries
			if(!istype(entry))
				CRASH("[type] had an invalid ref to a spell passed in refund.")
			if(!entry.can_refund(wizard, src))
				return FALSE
			var/result = entry.refund_spell(wizard, src)
			if(result <= 0)
				return FALSE

			entry.times = 0
			uses += result
			return TRUE

	if(uses < initial(uses))
		to_chat(wizard, span_warning("You need to have all your spell points to do this!"))
		return FALSE

	// Actions that are only available if you have full spell points
	switch(action)
		if("semirandomize")
			semirandomize(wizard, semi_random_bonus)
			return TRUE

		if("randomize")
			randomize(wizard, full_random_bonus)
			return TRUE

		if("purchase_loadout")
			wizard_loadout(wizard, locate(params["id"]))
			return TRUE

/// Attempts to purchased the passed entry [to_buy] for [user].
/obj/item/spellbook/proc/purchase_entry(datum/spellbook_entry/to_buy, mob/living/carbon/human/user)
	if(!istype(to_buy))
		CRASH("Spellbook attempted to buy an invalid entry. Got: [to_buy ? "[to_buy] ([to_buy.type])" : "null"]")
	if(!to_buy.can_buy(user, src))
		return FALSE
	if(!to_buy.buy_spell(user, src))
		return FALSE

	to_buy.times++
	uses -= to_buy.cost
	return TRUE

/// Purchases a wizard loadout [loadout] for [wizard].
/obj/item/spellbook/proc/wizard_loadout(mob/living/carbon/human/wizard, loadout)
	var/list/wanted_spell_names
	switch(loadout)
		if(WIZARD_LOADOUT_CLASSIC) //(Fireball>2, MM>2, Smite>2, Jauntx2>4) = 10
			wanted_spell_names = list(
				"Fireball" = 1,
				"Magic Missile" = 1,
				"Smite" = 1,
				"Ethereal Jaunt" = 2,
			)
		if(WIZARD_LOADOUT_MJOLNIR) //(Mjolnir>2, Summon Itemx3>3, Mutate>2, Force Wall>1, Blink>2) = 10
			wanted_spell_names = list(
				"Mjolnir" = 1,
				"Summon Item" = 3,
				"Mutate" = 1,
				"Force Wall" = 1,
				"Blink" = 1,
			)
		if(WIZARD_LOADOUT_WIZARMY) //(Soulstones>2, Staff of Change>2, A Necromantic Stone>2, Teleport>2, Ethereal Jaunt>2) = 10
			wanted_spell_names = list(
				"Soulstone Shard Kit" = 1,
				"Staff of Change" = 1,
				"A Necromantic Stone" = 1,
				"Teleport" = 1,
				"Ethereal Jaunt" = 1,
			)
		if(WIZARD_LOADOUT_SOULTAP) //(Soul Tap>1, Smite>2, Flesh to Stone>2, Mindswap>2, Knock>1, Teleport>2) = 10
			wanted_spell_names = list(
				"Soul Tap" = 1,
				"Smite" = 1,
				"Flesh to Stone" = 1,
				"Mindswap" = 1,
				"Knock" = 1,
				"Teleport" = 1,
			)

	if(!length(wanted_spell_names))
		stack_trace("Wizard Loadout \"[loadout]\" did not find a loadout that existed.")
		return

	for(var/datum/spellbook_entry/entry as anything in entries)
		if(!(entry.name in wanted_spell_names))
			continue
		if(entry.can_buy(wizard, src))
			var/purchase_count = wanted_spell_names[entry.name]
			wanted_spell_names -= entry.name
			for(var/i in 1 to purchase_count)
				purchase_entry(entry, wizard)
		if(!length(wanted_spell_names))
			break

	refunds_allowed = FALSE

	if(length(wanted_spell_names))
		stack_trace("Wizard Loadout \"[loadout]\" could not find valid spells to buy in the spellbook.")

	if(uses > 0)
		stack_trace("Wizard Loadout \"[loadout]\" does not use 10 wizard spell slots. Stop scamming players out.")

/// Purchases a semi-random wizard loadout for [wizard]
/// If passed a number [bonus_to_give], the wizard is given additional uses on their spellbook, used in randomization.
/obj/item/spellbook/proc/semirandomize(mob/living/carbon/human/wizard, bonus_to_give = 0)
	var/list/needed_cats = list("Offensive", "Mobility")
	var/list/shuffled_entries = shuffle(entries)
	for(var/i in 1 to 2)
		for(var/datum/spellbook_entry/entry as anything in shuffled_entries)
			if(!(entry.category in needed_cats))
				continue
			if(!purchase_entry(entry, wizard))
				continue
			needed_cats -= entry.category //so the next loop doesn't find another offense spell
			break

	refunds_allowed = FALSE
	//we have given two specific category spells to the wizard. the rest are completely random!
	randomize(wizard, bonus_to_give = bonus_to_give)

/// Purchases a fully random wizard loadout for [wizard], with a point bonus [bonus_to_give].
/// If passed a number [bonus_to_give], the wizard is given additional uses on their spellbook, used in randomization.
/obj/item/spellbook/proc/randomize(mob/living/carbon/human/wizard, bonus_to_give = 0)
	var/list/entries_copy = entries.Copy()
	uses += bonus_to_give
	while(uses > 0 && length(entries_copy))
		var/datum/spellbook_entry/entry = pick(entries_copy)
		if(!purchase_entry(entry, wizard))
			continue
		entries_copy -= entry

	refunds_allowed = FALSE
