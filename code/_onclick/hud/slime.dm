/datum/hud/slime
	ui_style = 'icons/mob/screen_slime.dmi'

/datum/hud/slime/New(mob/living/simple_animal/slime/owner)
	..()

	pull_icon = new /obj/screen/pull()
	pull_icon.icon = ui_style
	pull_icon.update_icon()
	pull_icon.screen_loc = ui_living_pull
	pull_icon.hud = src
	static_inventory += pull_icon

	healthdoll = new /obj/screen/healthdoll/slime()
	healthdoll.hud = src
	infodisplay += healthdoll
