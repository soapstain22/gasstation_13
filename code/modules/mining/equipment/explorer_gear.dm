/****************Explorer's Suit and Mask****************/
/obj/item/clothing/suit/hooded/explorer
	name = "explorer suit"
	desc = "An armoured suit for exploring harsh environments."
	icon_state = "explorer"
	item_state = "explorer"
	body_parts_covered = CHEST|GROIN|LEGS|ARMS
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	cold_protection = CHEST|GROIN|LEGS|ARMS
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	heat_protection = CHEST|GROIN|LEGS|ARMS
	hoodtype = /obj/item/clothing/head/hooded/explorer
	armor = list(melee = 30, bullet = 20, laser = 20, energy = 20, bomb = 50, bio = 100, rad = 50, fire = 50, acid = 50)
	allowed = list(/obj/item/device/flashlight, /obj/item/tank/internals, /obj/item/resonator, /obj/item/device/mining_scanner, /obj/item/device/t_scanner/adv_mining_scanner, /obj/item/gun/energy/kinetic_accelerator, /obj/item/pickaxe)
	resistance_flags = FIRE_PROOF

/obj/item/clothing/head/hooded/explorer
	name = "explorer hood"
	desc = "An armoured hood for exploring harsh environments."
	icon_state = "explorer"
	body_parts_covered = HEAD
	flags_inv = HIDEHAIR|HIDEFACE|HIDEEARS
	min_cold_protection_temperature = FIRE_HELM_MIN_TEMP_PROTECT
	max_heat_protection_temperature = FIRE_HELM_MAX_TEMP_PROTECT
	armor = list(melee = 30, bullet = 20, laser = 20, energy = 20, bomb = 50, bio = 100, rad = 50, fire = 50, acid = 50)
	resistance_flags = FIRE_PROOF

/obj/item/clothing/mask/gas/explorer
	name = "explorer gas mask"
	desc = "A military-grade gas mask that can be connected to an air supply."
	icon_state = "gas_mining"
	visor_flags = BLOCK_GAS_SMOKE_EFFECT_1 | MASKINTERNALS_1
	visor_flags_inv = HIDEFACIALHAIR
	visor_flags_cover = MASKCOVERSMOUTH
	actions_types = list(/datum/action/item_action/adjust)
	armor = list(melee = 10, bullet = 5, laser = 5, energy = 5, bomb = 0, bio = 50, rad = 0, fire = 20, acid = 40)
	resistance_flags = FIRE_PROOF

/obj/item/clothing/mask/gas/explorer/attack_self(mob/user)
	adjustmask(user)

/obj/item/clothing/mask/gas/explorer/adjustmask(user)
	..()
	w_class = mask_adjusted ? WEIGHT_CLASS_NORMAL : WEIGHT_CLASS_SMALL

/obj/item/clothing/mask/gas/explorer/folded/New()
	..()
	adjustmask()

/obj/item/clothing/suit/space/hostile_environment
	name = "H.E.C.K. suit"
	desc = "Hostile Environiment Cross-Kinetic Suit: A suit designed to withstand the wide variety of hazards from Lavaland. It wasn't enough for its last owner."
	icon_state = "hostile_env"
	item_state = "hostile_env"
	flags_1 = THICKMATERIAL_1 //not spaceproof
	max_heat_protection_temperature = FIRE_IMMUNITY_SUIT_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | LAVA_PROOF
	slowdown = 0
	armor = list(melee = 50, bullet = 30, laser = 25, energy = 20, bomb = 50, bio = 100, rad = 100, fire = 100, acid = 100)
	allowed = list(/obj/item/device/flashlight, /obj/item/tank/internals, /obj/item/resonator, /obj/item/device/mining_scanner, /obj/item/device/t_scanner/adv_mining_scanner, /obj/item/gun/energy/kinetic_accelerator, /obj/item/pickaxe)
	var/cooldown = 600
	var/next_adrenal = 0

/obj/item/clothing/suit/space/hostile_environment/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/clothing/suit/space/hostile_environment/Destroy()
	. = ..()
	STOP_PROCESSING(SSobj, src)

/obj/item/clothing/suit/space/hostile_environment/process()
	if(world.time < next_adrenal || !iscarbon(loc))
		return
	var/mob/living/carbon/C = loc
	if(C.IsStun() || C.IsKnockdown() || C.IsSleeping() || IsUnconscious())
		C.SetStun(0)
		C.SetKnockdown(0)
		C.SetSleeping(0)
		C.SetUnconscious(0)
		next_adrenal = world.time + cooldown
		to_chat(C, "<span class='userdanger'>You suddenly feel [src] infusing you with energy!</span>")


/obj/item/clothing/suit/space/hostile_environment/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/toy/crayon/spraycan))
		var/obj/item/toy/crayon/spraycan/spraycan = O
		if(spraycan.is_capped)
			to_chat(user, "<span class='warning'>Take the cap off first!</span>")
			return
		if(spraycan.check_empty(user))
			return
		spraycan.use_charges(2)
		add_atom_colour(spraycan.paint_color, FIXED_COLOUR_PRIORITY)
		playsound(get_turf(user), 'sound/effects/spray.ogg', 5, 1, 5)
		to_chat(user, "<span class='notice'>You sprays [spraycan] on [src], painting it.</span>")
	else
		return ..()

/obj/item/clothing/head/helmet/space/hostile_environment
	name = "H.E.C.K. helmet"
	desc = "Hostile Environiment Cross-Kinetic Helmet: A helmet designed to withstand the wide variety of hazards from Lavaland. It wasn't enough for its last owner."
	icon_state = "hostile_env"
	item_state = "hostile_env"
	w_class = WEIGHT_CLASS_NORMAL
	max_heat_protection_temperature = FIRE_IMMUNITY_HELM_MAX_TEMP_PROTECT
	flags_1 = THICKMATERIAL_1 // no space protection
	armor = list(melee = 50, bullet = 30, laser = 25,energy = 20, bomb = 50, bio = 100, rad = 100, fire = 100, acid = 100)
	resistance_flags = FIRE_PROOF | LAVA_PROOF

/obj/item/clothing/head/helmet/space/hostile_environment/Initialize()
	. = ..()
	update_icon()

/obj/item/clothing/head/helmet/space/hostile_environment/update_icon()
	..()
	cut_overlays()
	var/mutable_appearance/glass_overlay = mutable_appearance(icon, "hostile_env_glass")
	glass_overlay.appearance_flags = RESET_COLOR
	add_overlay(glass_overlay)

/obj/item/clothing/head/helmet/space/hostile_environment/worn_overlays(isinhands)
	. = ..()
	if(!isinhands)
		var/mutable_appearance/M = mutable_appearance('icons/mob/head.dmi', "hostile_env_glass")
		M.appearance_flags = RESET_COLOR
		. += M

/obj/item/clothing/head/helmet/space/hostile_environment/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/toy/crayon/spraycan))
		var/obj/item/toy/crayon/spraycan/spraycan = O
		if(spraycan.is_capped)
			to_chat(user, "<span class='warning'>Take the cap off first!</span>")
			return
		if(spraycan.check_empty(user))
			return
		spraycan.use_charges(2)
		add_atom_colour(spraycan.paint_color, FIXED_COLOUR_PRIORITY)
		playsound(get_turf(user), 'sound/effects/spray.ogg', 5, 1, 5)
		to_chat(user, "<span class='notice'>You sprays [spraycan] on [src], painting it.</span>")
	else
		return ..()

