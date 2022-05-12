/** This structure acts as a source of moisture loving cell lines,
as well as a location where a hidden item can somtimes be retrieved
at the cost of risking a vicious bite.**/
/obj/structure/moisture_trap
	name = "moisture trap"
	desc = "A device installed in order to control moisture in poorly ventilated areas.\nThe stagnant water inside basin seems to produce serious biofouling issues when improperly maintained.\nThis unit in particular seems to be teeming with life!\nWho thought mother Gaia could assert herself so vigoriously in this sterile and desolate place?"
	icon_state = "moisture_trap"
	anchored = TRUE
	density = FALSE
	///This var stores the hidden item that might be able to be retrieved from the trap
	var/obj/item/hidden_item
	///This var determines if there is a chance to recieve a bite when sticking your hand into the water.
	var/critter_infested = TRUE
	///weighted loot table for what loot you can find inside the moisture trap.
	///the actual loot isn't that great and should probably be improved and expanded later.
	var/static/list/loot_table = list(
		/obj/item/food/meat/slab/human/mutant/skeleton = 35,
		/obj/item/food/meat/slab/human/mutant/zombie = 15,
		/obj/item/trash/can = 15,
		/obj/item/clothing/head/helmet/skull = 10,
		/obj/item/restraints/handcuffs = 4,
		/obj/item/restraints/handcuffs/cable/red = 1,
		/obj/item/restraints/handcuffs/cable/blue = 1,
		/obj/item/restraints/handcuffs/cable/green = 1,
		/obj/item/restraints/handcuffs/cable/pink = 1,
		/obj/item/restraints/handcuffs/alien = 2,
		/obj/item/coin/bananium = 9,
		/obj/item/fish/ratfish = 10,
		/obj/item/knife/butcher = 5,
		/obj/item/coin/mythril = 1,
	)


/obj/structure/moisture_trap/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_FISH_SAFE_STORAGE, TRAIT_GENERIC)
	AddElement(/datum/element/swabable, CELL_LINE_TABLE_MOIST, CELL_VIRUS_TABLE_GENERIC, rand(2,4), 20)
	if(prob(40))
		critter_infested = FALSE
	if(prob(75))
		var/picked_item = pick_weight(loot_table)
		hidden_item = new picked_item(src)


/obj/structure/moisture_trap/Destroy()
	if(hidden_item)
		QDEL_NULL(hidden_item)
	return ..()


///This proc checks if we are able to reach inside the trap to interact with it.
/obj/structure/moisture_trap/proc/CanReachInside(mob/user)
	if(!isliving(user))
		return FALSE
	var/mob/living/living_user = user
	if(living_user.body_position == STANDING_UP && ishuman(living_user)) //I dont think monkeys can crawl on command.
		return FALSE
	return TRUE


/obj/structure/moisture_trap/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(iscyborg(user) || isalien(user))
		return
	if(!CanReachInside(user))
		to_chat(user, span_warning("You need to lie down to reach into [src]."))
		return
	to_chat(user, span_notice("You reach down into the cold water of the basin."))
	if(!do_after(user, 2 SECONDS, target = src))
		return
	if(hidden_item)
		user.put_in_hands(hidden_item)
		to_chat(user, span_notice("As you poke around inside [src] you feel the contours of something hidden below the murky waters.</span>\n<span class='nicegreen'>You retrieve [hidden_item] from [src]."))
		hidden_item = null
		return
	if(critter_infested && prob(50) && iscarbon(user))
		var/mob/living/carbon/bite_victim = user
		var/obj/item/bodypart/affecting = bite_victim.get_bodypart("[(user.active_hand_index % 2 == 0) ? "r" : "l" ]_arm")
		to_chat(user, span_danger("You feel a sharp pain as an unseen creature sinks it's [pick("fangs", "beak", "proboscis")] into your arm!"))
		if(affecting?.receive_damage(30))
			bite_victim.update_damage_overlays()
			playsound(src,'sound/weapons/bite.ogg', 70, TRUE)
			return
	to_chat(user, span_warning("You find nothing of value..."))

/obj/structure/moisture_trap/attackby(obj/item/I, mob/user, params)
	if(iscyborg(user) || isalien(user) || !CanReachInside(user))
		return ..()
	add_fingerprint(user)
	if(istype(I, /obj/item/reagent_containers))
		if(istype(I, /obj/item/food/monkeycube))
			var/obj/item/food/monkeycube/cube = I
			cube.Expand()
			return
		var/obj/item/reagent_containers/reagent_container = I
		if(reagent_container.is_open_container())
			reagent_container.reagents.add_reagent(/datum/reagent/water, min(reagent_container.volume - reagent_container.reagents.total_volume, reagent_container.amount_per_transfer_from_this))
			to_chat(user, span_notice("You fill [reagent_container] from [src]."))
			return
	if(hidden_item)
		to_chat(user, span_warning("There is already something inside [src]."))
		return
	if(!user.transferItemToLoc(I, src))
		to_chat(user, span_warning("\The [I] is stuck to your hand, you cannot put it in [src]!"))
		return
	hidden_item = I
	to_chat(user, span_notice("You hide [I] inside the basin."))

/**
 * Spawns in maint shafts, and blocks lines of sight perodically when active.
 */
/obj/structure/steam_vent
	name = "steam vent"
	desc = "A device periodically filtering out moisture particles from the nearby walls and windows. It's only possible due to the moisture traps nearby."
	icon_state = "steam_vent"
	anchored = TRUE
	density = FALSE
	/// How often does the vent reset the blow_steam callback loop.
	var/steam_speed = 15 SECONDS
	/// Is the steam vent active?
	var/vent_active = TRUE
	///The cooldown for toggling the steam vent to prevent infinite steam vent looping.
	COOLDOWN_DECLARE(steam_vent_interact)

/obj/structure/steam_vent/Initialize(mapload)
	. = ..()
	if(prob(75))
		vent_active = FALSE
	var/timer = (steam_speed - (rand(1,5) SECONDS))
	addtimer(CALLBACK(src, .proc/blow_steam), timer)
	update_icon_state()

/obj/structure/steam_vent/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(!COOLDOWN_FINISHED(src, steam_vent_interact))
		to_chat(user, span_notice("\The [src] isn't ready to be adjusted yet."))
		return
	vent_active = !vent_active
	if(vent_active)
		to_chat(user, span_notice("\The [src] is now on."))
	else
		to_chat(user, span_notice("\The [src] is now off."))
		return
	addtimer(CALLBACK(src, .proc/blow_steam), 1 SECONDS)
	COOLDOWN_START(src, steam_vent_interact, 20 SECONDS)

/**
 * Actively looped proc that creates smoke, and determines when the vent needs to block line of sight via reset_opacity.
 */
/obj/structure/steam_vent/proc/blow_steam()
	if(!vent_active)
		return
	new /obj/effect/particle_effect/smoke(loc)
	set_opacity(TRUE)
	addtimer(CALLBACK(src, .proc/reset_opacity), 9 SECONDS)
	addtimer(CALLBACK(src, .proc/blow_steam), steam_speed)

/**
 * Simply handles resetting the opacity of the vent to simulate the smoke blocking line of sight.
 */
/obj/structure/steam_vent/proc/reset_opacity()
	set_opacity(FALSE)

/obj/structure/steam_vent/update_icon_state()
	. = ..()
	switch(vent_active)
		if(TRUE)
			icon_state = "steam_vent"
		if(FALSE)
			icon_state = "steam_vent_off"

/obj/structure/steam_vent/fast
	desc = "A device periodically filtering out moisture particles from the nearby walls and windows. It's only possible due to the moisture traps nearby. It's faster than most."
	steam_speed = 10 SECONDS
