///Hud type with targetting dol and a nutrition bar
/datum/hud/ooze/New(mob/living/owner)
	..()

	zone_select = new /obj/screen/zone_sel()
	zone_select.icon = ui_style
	zone_select.hud = src
	zone_select.update_icon()
	static_inventory += zone_select

	alien_plasma_display = new /obj/screen/ooze_nutrition_display //Just going to use the alien plasma display because making new vars for each object is braindead.
	alien_plasma_display.hud = src
	infodisplay += alien_plasma_display

///Sets the right hud type for the ooze
/mob/living/simple_animal/hostile/ooze/create_mob_hud()
	hud_type = /datum/hud/ooze


/obj/screen/ooze_nutrition_display
	icon = 'icons/mob/screen_alien.dmi'
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "power_display2"
	name = "plasma stored"
	screen_loc = ui_alienplasmadisplay
