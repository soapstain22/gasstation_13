/obj/item/borg/sight
	var/sight_mode = null

/obj/item/borg/sight/on_robot_equip(/mob/living/silicon/robot/user)
	user.sight_mode |= sight_mode
	update_sight()

/obj/item/borg/sight/on_robot_unequip(/mob/living/silicon/robot/user)
	user.sight_mode &= ~sight_mode
	update_sight()

/obj/item/borg/sight/xray
	name = "\proper X-ray vision"
	icon = 'icons/obj/decals.dmi'
	icon_state = "securearea"
	sight_mode = BORGXRAY

/obj/item/borg/sight/thermal
	name = "\proper thermal vision"
	sight_mode = BORGTHERM
	icon_state = "thermal"

/obj/item/borg/sight/meson
	name = "\proper meson vision"
	sight_mode = BORGMESON
	icon_state = "meson"

/obj/item/borg/sight/material
	name = "\proper material vision"
	sight_mode = BORGMATERIAL
	icon_state = "material"

/obj/item/borg/sight/hud
	name = "hud"
	var/obj/item/clothing/glasses/hud/hud = null

/obj/item/borg/sight/hud/Initialize(mapload)
	if (!isnull(hud))
		hud = new hud(src)
	return ..()

/obj/item/borg/sight/hud/med
	name = "medical hud"
	icon_state = "healthhud"
	hud = /obj/item/clothing/glasses/hud/health

/obj/item/borg/sight/hud/sec
	name = "security hud"
	icon_state = "securityhud"
	hud = /obj/item/clothing/glasses/hud/security
