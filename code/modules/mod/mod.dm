/// MODsuits, trade-off between armor and utility
/obj/item/mod
	name = "Base MOD"
	desc = "You should not see this, yell at a coder!"
	icon = 'icons/obj/mod.dmi'
	icon_state = "mod_shell"
	worn_icon = 'icons/mob/mod.dmi'

/obj/item/mod/control
	name = "MOD control module"
	desc = "The control piece of a Modular Outerwear Device, a special powered suit that protects against various environments. Wear it on your back, deploy it and activate it to learn the extend of technology."
	icon_state = "control"
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	slowdown = 2
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, RAD = 0, FIRE = 30, ACID = 75, WOUND = 0)
	actions_types = list(/datum/action/item_action/mod/deploy, /datum/action/item_action/mod/activate, /datum/action/item_action/mod/panel)
	resistance_flags = NONE
	max_heat_protection_temperature = SPACE_SUIT_MAX_TEMP_PROTECT
	min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT
	gas_transfer_coefficient = 0.01
	permeability_coefficient = 0.01
	siemens_coefficient = 0.5
	/// The MOD's theme, decides on some stuff like armor and statistics
	var/datum/mod_theme/theme = /datum/mod_theme
	/// Looks of the MOD
	var/skin = "standard"
	/// If the suit is deployed and turned on
	var/active = FALSE
	/// If the suit wire/module hatch is open
	var/open = FALSE
	/// If the suit is ID locked
	var/locked = TRUE
	/// If the suit is malfunctioning
	var/malfunctioning = FALSE
	/// If the suit has EMP protection
	var/emp_protection = FALSE
	/// If the suit is currently activating/deactivating
	var/activating = FALSE
	/// How long the MOD is electrified for
	var/seconds_electrified = MACHINE_NOT_ELECTRIFIED
	/// If the suit interface is broken
	var/interface_break = FALSE
	/// How much modules can this MOD carry without malfunctioning
	var/complexity_max = DEFAULT_MAX_COMPLEXITY
	/// How much modules this MOD is carrying
	var/complexity = 0
	/// Power usage of the MOD.
	var/cell_drain = 0
	/// Slowdown when active
	var/slowdown_active = 1
	/// MOD cell
	var/obj/item/stock_parts/cell/cell = /obj/item/stock_parts/cell/high
	/// MOD helmet
	var/obj/item/clothing/head/helmet/space/mod/helmet = /obj/item/clothing/head/helmet/space/mod
	/// MOD chestplate
	var/obj/item/clothing/suit/armor/mod/chestplate = /obj/item/clothing/suit/armor/mod
	/// MOD gauntlets
	var/obj/item/clothing/gloves/mod/gauntlets = /obj/item/clothing/gloves/mod
	/// MOD boots
	var/obj/item/clothing/shoes/mod/boots = /obj/item/clothing/shoes/mod
	/// List of parts
	var/list/mod_parts
	/// Modules the MOD currently possesses
	var/list/modules
	/// Currently used module
	var/obj/item/mod/module/selected_module
	/// AI mob inhabiting the MOD
	var/mob/living/silicon/ai/AI
	/// Delay between moves as AI
	var/movedelay = 0
	/// Cooldown for AI moves
	COOLDOWN_DECLARE(cooldown_mod_move)
	/// Person wearing the MODsuit
	var/mob/living/carbon/human/wearer

/obj/item/mod/control/Initialize()
	. = ..()
	if(!ispath(theme))
		CRASH("A MODsuit spawned without a proper theme.")
	theme = GLOB.mod_themes[theme]
	slowdown = theme.slowdown_unactive
	complexity_max = theme.complexity_max
	skin = theme.default_skin
	req_access = theme.req_access.Copy()
	cell_drain = theme.cell_usage
	wires = new /datum/wires/mod(src)
	if(!req_access.len)
		locked = FALSE
	if(ispath(cell))
		cell = new cell(src)
	if(ispath(helmet))
		helmet = new helmet(src)
		helmet.mod = src
		LAZYADD(mod_parts, helmet)
	if(ispath(chestplate))
		chestplate = new chestplate(src)
		chestplate.mod = src
		LAZYADD(mod_parts, chestplate)
	if(ispath(gauntlets))
		gauntlets = new gauntlets(src)
		gauntlets.mod = src
		LAZYADD(mod_parts, gauntlets)
	if(ispath(boots))
		boots = new boots(src)
		boots.mod = src
		LAZYADD(mod_parts, boots)
	if(LAZYLEN(mod_parts))
		var/all_parts = mod_parts.Copy() + src
		for(var/obj/item/piece in all_parts)
			piece.name = "[theme.name] [piece.name]"
			piece.desc = "[piece.desc] [theme.desc]"
			piece.armor = theme.armor
			piece.resistance_flags = theme.resistance_flags
			piece.max_heat_protection_temperature = theme.max_heat_protection_temperature
			piece.min_cold_protection_temperature = theme.min_cold_protection_temperature
			piece.gas_transfer_coefficient = theme.gas_transfer_coefficient
			piece.permeability_coefficient = theme.permeability_coefficient
			piece.siemens_coefficient = theme.siemens_coefficient
			piece.icon_state = "[skin]-[piece.icon_state]"
	if(theme.initial_modules.len)
		for(var/obj/item/mod/module/module in theme.initial_modules)
			module = new module(src)
			install(module, TRUE)
	movedelay = CONFIG_GET(number/movedelay/run_delay)
	START_PROCESSING(SSobj,src)


/obj/item/mod/control/Destroy()
	..()
	STOP_PROCESSING(SSobj, src)
	QDEL_NULL(wires)
	if(cell)
		QDEL_NULL(cell)
	if(helmet)
		helmet.mod = null
		QDEL_NULL(helmet)
	if(chestplate)
		chestplate.mod = null
		QDEL_NULL(chestplate)
	if(gauntlets)
		gauntlets.mod = null
		QDEL_NULL(gauntlets)
	if(boots)
		boots.mod = null
		QDEL_NULL(boots)
	for(var/obj/item/mod/module/thingy in modules)
		thingy.mod = null
		QDEL_NULL(thingy)

/obj/item/mod/control/process(delta_time)
	if(seconds_electrified > MACHINE_NOT_ELECTRIFIED)
		seconds_electrified--
	if(!(cell && cell.charge > 0 && active && cell_drain))
		return
	if((cell.charge -= cell_drain) < 0)
		cell.charge = 0

/obj/item/mod/control/equipped(mob/user, slot)
	..()
	if(slot == ITEM_SLOT_BACK)
		wearer = user
	else
		wearer = null

/obj/item/mod/control/dropped(mob/user)
	..()
	wearer = null

/obj/item/mod/control/item_action_slot_check(slot)
	if(slot == ITEM_SLOT_BACK)
		return TRUE

/obj/item/mod/control/allow_attack_hand_drop(mob/user)
	if(iscarbon(user))
		var/mob/living/carbon/guy = user
		if(src == guy.back)
			for(var/obj/item/part in mod_parts)
				if(part.loc != src)
					to_chat(guy, "<span class='warning'>ERROR: At least one of the parts are still on your body, please retract them and try again.</span>")
					playsound(src, 'sound/machines/scanbuzz.ogg', 25, FALSE)
					return FALSE
	return ..()

/obj/item/mod/control/MouseDrop(atom/over_object)
	if(src == wearer?.back && istype(over_object, /atom/movable/screen/inventory/hand))
		for(var/obj/item/part in mod_parts)
			if(part.loc != src)
				to_chat(wearer, "<span class='warning'>ERROR: At least one of the parts are still on your body, please retract them and try again.</span>")
				playsound(src, 'sound/machines/scanbuzz.ogg', 25, FALSE)
				return
		if(!wearer.incapacitated())
			var/atom/movable/screen/inventory/hand/H = over_object
			if(wearer.putItemFromInventoryInHandIfPossible(src, H.held_index))
				add_fingerprint(usr)
	return ..()

/obj/item/mod/control/attack_hand(mob/user)
	if(seconds_electrified && cell.charge)
		if(shock(user, 100))
			return
	if(open && cell && loc == user)
		to_chat(user, "<span class='notice'>You start removing [cell].</span>")
		if(do_after(user, 50, target = src))
			to_chat(user, "<span class='notice'>You remove [cell].</span>")
			user.put_in_hands(cell)
			cell = null
		return
	..()

/obj/item/mod/control/screwdriver_act(mob/living/user, obj/item/I)
	if(..())
		return TRUE
	if(active || activating)
		to_chat(user, "<span class='warning'>ERROR: Suit activated. Deactivate before further action.</span>")
		playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE)
		return FALSE
	to_chat(user, "<span class='notice'>You start to [open ? "screw the panel back on" : "unscrew the panel"]...</span>")
	I.play_tool_sound(src, 100)
	if(I.use_tool(src, user, 20))
		I.play_tool_sound(src, 100)
		user.visible_message("<span class='notice'>[user] [open ? "screws the panel back on" : "unscrews the panel"].</span>",
			"<span class='notice'>You [open ? "screw the panel back on" : "unscrew the panel"].</span>",
			"<span class='hear'>You hear metal noises.</span>")
		open = !open
	return TRUE

/obj/item/mod/control/crowbar_act(mob/living/user, obj/item/I)
	. = ..()
	if(!open)
		to_chat(user, "<span class='warning'>ERROR: Suit panel not open.</span>")
		playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE)
		return FALSE
	if(modules.len)
		for(var/obj/item/mod/module/thingy in modules)
			if(thingy.removable)
				uninstall(thingy)
		I.play_tool_sound(src, 100)
		return TRUE
	to_chat(user, "<span class='warning'>ERROR: There's no modules on [src]!</span>")
	playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE)
	return FALSE

/obj/item/mod/control/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/mod/module))
		if(open && !active && !activating)
			install(I, FALSE)
			return TRUE
		else
			audible_message("<span class='warning'>[src] indicates that something prevents installing [I].</span>")
			playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE)
			return FALSE
	else if(istype(I, /obj/item/stock_parts/cell))
		if(open && !active && !activating && !cell)
			I.forceMove(src)
			cell = I
			audible_message("<span class='notice'>[src] indicates that [cell] has been succesfully installed.</span>")
			playsound(src, 'sound/machines/click.ogg', 50, TRUE)
			return TRUE
		else
			audible_message("<span class='warning'>[src] indicates that something prevents installing [I].</span>")
			playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE)
			return FALSE
	else if(is_wire_tool(I) && open)
		wires.interact(user)
	else if(istype(I, /obj/item/mod/paint))
		paint()
		qdel(I)
	..()

/obj/item/mod/control/proc/paint()
	wearer.update_icons()

/obj/item/mod/control/proc/shock(mob/living/user)
	if(!istype(user) || cell.charge < 1)
		return FALSE
	do_sparks(5, TRUE, src)
	var/check_range = TRUE
	if(electrocute_mob(user, get_area(src), src, 0.7, check_range))
		return TRUE
	else
		return FALSE

/obj/item/mod/control/proc/install(module, starting_module = FALSE)
	var/obj/item/mod/module/thingy = module
	if(theme.module_blacklist.Find(thingy))
		if(!starting_module)
			audible_message("<span class='warning'>[src] indicates that it rejects the module.</span>")
			playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE)
		return
	var/complexity_with_thingy = complexity
	complexity_with_thingy += thingy.complexity
	if(complexity_with_thingy > complexity_max)
		if(!starting_module)
			audible_message("<span class='warning'>[src] indicates that the module would make it too complex.</span>")
			playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE)
		return
	thingy.forceMove(src)
	LAZYADD(modules, thingy)
	complexity += thingy.complexity
	cell_drain += thingy.idle_power_use
	thingy.mod = src
	thingy.on_install()
	if(!starting_module)
		audible_message("<span class='notice'>[src] indicates that the module has been installed successfully.</span>")
		playsound(src, 'sound/machines/click.ogg', 50, TRUE)

/obj/item/mod/control/proc/uninstall(module)
	var/obj/item/mod/module/thingy = module
	if(!thingy.removable)
		audible_message("<span class='warning'>[src] indicates that the module cannot be removed.</span>")
		playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE)
		return
	thingy.forceMove(get_turf(src))
	LAZYREMOVE(modules, thingy)
	complexity -= thingy.complexity
	cell_drain -= thingy.idle_power_use
	thingy.on_uninstall()
	thingy.mod = null

/obj/item/mod/control/proc/update_access()
	if(!allowed(wearer))
		to_chat(wearer, "<span class='warning'>ERROR: Access denied.</span>")
		playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE)
		return
	req_access = wearer.wear_id?.GetID()
	to_chat(wearer, "<span class='notice'>Access levels updated.</span>")

/obj/item/clothing/head/helmet/space/mod
	name = "MOD helmet"
	desc = "A helmet for a MODsuit."
	icon = 'icons/obj/mod.dmi'
	icon_state = "helmet"
	worn_icon = 'icons/mob/mod.dmi'
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, RAD = 0, FIRE = 30, ACID = 75, WOUND = 0)
	flash_protect = FLASH_PROTECTION_NONE
	resistance_flags = NONE
	clothing_flags = THICKMATERIAL | SNUG_FIT
	flags_inv = HIDEFACIALHAIR
	flags_cover = HEADCOVERSMOUTH
	visor_flags = STOPSPRESSUREDAMAGE
	visor_flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR
	visor_flags_cover = HEADCOVERSEYES|PEPPERPROOF
	alternate_worn_layer = NECK_LAYER
	var/obj/item/mod/control/mod

/obj/item/clothing/head/helmet/space/mod/Destroy()
	..()
	if(mod)
		mod.helmet = null
		QDEL_NULL(mod)

/obj/item/clothing/suit/armor/mod
	name = "MOD chestplate"
	desc = "A chestplate for a MODsuit."
	icon = 'icons/obj/mod.dmi'
	icon_state = "chestplate"
	worn_icon = 'icons/mob/mod.dmi'
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, RAD = 0, FIRE = 30, ACID = 75, WOUND = 0)
	body_parts_covered = CHEST|GROIN|LEGS|ARMS
	heat_protection = CHEST|GROIN|LEGS|ARMS
	cold_protection = CHEST|GROIN|LEGS|ARMS
	max_heat_protection_temperature = SPACE_SUIT_MAX_TEMP_PROTECT
	min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT
	clothing_flags = THICKMATERIAL
	visor_flags = STOPSPRESSUREDAMAGE
	visor_flags_inv = HIDEJUMPSUIT
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals)
	resistance_flags = NONE
	var/obj/item/mod/control/mod

/obj/item/clothing/suit/armor/mod/Destroy()
	..()
	if(mod)
		mod.chestplate = null
		QDEL_NULL(mod)

/obj/item/clothing/gloves/mod
	name = "MOD gauntlets"
	desc = "A pair of gauntlets for a MODsuit."
	icon = 'icons/obj/mod.dmi'
	icon_state = "gauntlets"
	worn_icon = 'icons/mob/mod.dmi'
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, RAD = 0, FIRE = 30, ACID = 75, WOUND = 0)
	resistance_flags = NONE
	var/obj/item/mod/control/mod
	var/obj/item/clothing/overslot

/obj/item/clothing/gloves/mod/Destroy()
	overslot.forceMove(drop_location())
	..()
	if(mod)
		mod.gauntlets = null
		QDEL_NULL(mod)
	if(isliving(loc))
		show_overslot(loc)

/obj/item/clothing/gloves/mod/proc/show_overslot(mob/user)
	if(!overslot)
		return
	if(user.equip_to_slot_if_possible(overslot,overslot.slot_flags,0,0,1))
		overslot = null

/obj/item/clothing/shoes/mod
	name = "MOD boots"
	desc = "A pair of boots for a MODsuit."
	icon = 'icons/obj/mod.dmi'
	icon_state = "boots"
	worn_icon = 'icons/mob/mod.dmi'
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, RAD = 0, FIRE = 30, ACID = 75, WOUND = 0)
	resistance_flags = NONE
	var/obj/item/mod/control/mod
	var/obj/item/clothing/overslot

/obj/item/clothing/shoes/mod/Destroy()
	overslot.forceMove(drop_location())
	..()
	if(mod)
		mod.boots = null
		QDEL_NULL(mod)
	if(isliving(loc))
		show_overslot(loc)

/obj/item/clothing/shoes/mod/proc/show_overslot(mob/user)
	if(!overslot)
		return
	if(user.equip_to_slot_if_possible(overslot,overslot.slot_flags,0,0,1))
		overslot = null

/obj/item/mod/control/engineering
	theme = /datum/mod_theme/engineering
