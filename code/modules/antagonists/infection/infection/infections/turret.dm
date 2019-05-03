/obj/structure/infection/turret
	name = "infection turret"
	icon = 'icons/mob/blob.dmi'
	icon_state = "blob"
	desc = "A solid wall with a radiating material on the inside."
	max_integrity = 150
	point_return = 4
	armor = list("melee" = 0, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 90, "acid" = 90)
	var/frequency = 1 // amount of times the turret will fire per process tick (1 second)
	var/scan_range = 7 // range to search for targets
	var/projectile_type = /obj/item/projectile/bullet/infection // the bullet fired for this turret
	upgrade_types = list(/datum/component/infection/upgrade/turret/resistant_turret,
						 /datum/component/infection/upgrade/turret/infernal_turret,
						 /datum/component/infection/upgrade/turret/homing_turret)

/obj/structure/infection/turret/Initialize()
	START_PROCESSING(SSobj, src)
	. = ..()

/obj/structure/infection/turret/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/infection/turret/update_icon()
	cut_overlays()
	color = null
	var/mutable_appearance/infection_overlay = mutable_appearance('icons/mob/blob.dmi', "blob")
	if(overmind)
		infection_overlay.color = overmind.infection_color
	add_overlay(infection_overlay)
	add_overlay(mutable_appearance('icons/mob/blob.dmi', "infection_turret"))

/obj/structure/infection/turret/Life()
	if(!overmind)
		return
	var/list/targets = list()
	for(var/mob/A in view(scan_range, src))
		if(A.invisibility > SEE_INVISIBLE_LIVING)
			continue

		if(isanimal(A))
			var/mob/living/simple_animal/SA = A
			if(SA.stat || in_faction(SA)) //don't target if dead or in faction
				continue
			targets += SA
			continue

		if(issilicon(A))
			var/mob/living/silicon/sillycone = A

			if(ispAI(A))
				continue

			if(sillycone.stat || in_faction(sillycone))
				continue

			targets += sillycone
			continue

		if(iscarbon(A))
			var/mob/living/carbon/C = A

			if(C.stat == DEAD)
				continue

			if(!in_faction(C))
				targets += C

	for(var/A in GLOB.mechas_list)
		if((get_dist(A, src) < scan_range) && can_see(src, A, scan_range))
			targets += A

	if(targets.len)
		tryToShootAt(targets)

/obj/structure/infection/turret/proc/in_faction(mob/target)
	if(ROLE_INFECTION in target.faction)
		return TRUE
	return FALSE

/obj/structure/infection/turret/proc/tryToShootAt(list/atom/movable/targets)
	while(targets.len > 0)
		var/atom/movable/M = pick(targets)
		targets -= M
		if(target(M))
			return 1

/obj/structure/infection/turret/proc/target(atom/movable/target)
	if(target && frequency)
		var/diffTime = SSprocessing.wait / frequency
		var/timePassed = 0
		while(timePassed < SSprocessing.wait)
			setDir(get_dir(src, target)) //even if you can't shoot, follow the target
			addtimer(CALLBACK(src, .proc/shootAt, target), timePassed)
			timePassed += diffTime
		return 1
	return

/obj/structure/infection/turret/proc/shootAt(atom/movable/target)
	var/turf/T = get_turf(src)
	var/turf/U = get_turf(target)
	if(!istype(T) || !istype(U))
		return

	update_icon()
	var/obj/item/projectile/bullet/infection/A = new projectile_type(T)
	playsound(loc, 'sound/weapons/gunshot_smg.ogg', 75, 1)

	//Shooting Code:
	A.preparePixelProjectile(target, T)
	A.firer = src
	A.fire()
	return A

/*
//
// Projectiles
//
*/

/obj/item/projectile/bullet/infection
	name = "bulky spore"
	icon = 'icons/mob/blob.dmi'
	icon_state = "bullet"
	layer = ABOVE_MOB_LAYER
	damage = 20
	speed = 5
	damage_type = BRUTE
	pass_flags = PASSTABLE | PASSBLOB
	nodamage = FALSE
	flag = "bullet"
	hitsound_wall = "ricochet"
	impact_effect_type = /obj/effect/temp_visual/impact_effect

/obj/item/projectile/bullet/infection/core
	name = "strong spore"
	damage = 20
	armour_penetration = 45
	speed = 0.8

/obj/item/projectile/bullet/infection/infernal
	name = "burning spore"
	icon = 'icons/mob/blob.dmi'
	icon_state = "fire_bullet"
	speed = 1
	damage_type = BURN
	flag = "laser"

/obj/item/projectile/bullet/infection/homing
	name = "tracking spore"
	icon = 'icons/mob/blob.dmi'
	icon_state = "tracking_bullet"
	range = 150
	homing_turn_speed = 15

/obj/item/projectile/bullet/infection/flak
	name = "flak spore"
	icon = 'icons/mob/blob.dmi'
	icon_state = "flak_bullet"
	damage = 8
	range = 2
	speed = 2

/*
//
// Turrets
//
*/

/obj/structure/infection/turret/resistant
	name = "resistant turret"
	desc = "A very bulky turret fit for a war of attrition."
	max_integrity = 300
	upgrade_types = list(/datum/component/infection/upgrade/turret/knockback,
						 /datum/component/infection/upgrade/turret/shield_creator,
						 /datum/component/infection/upgrade/turret/spore_bullets)

/obj/structure/infection/turret/resistant/core
	name = "core turret"
	point_return = 0
	projectile_type = /obj/item/projectile/bullet/infection/core

/obj/structure/infection/turret/infernal
	name = "infernal turret"
	desc = "A fiery turret intent on disintegrating its enemies."
	projectile_type = /obj/item/projectile/bullet/infection/infernal // the bullet fired for this turret
	upgrade_types = list(/datum/component/infection/upgrade/turret/burning_spores,
						 /datum/component/infection/upgrade/turret/fire_rate,
						 /datum/component/infection/upgrade/turret/armour_penetration)
	scan_range = 5

/obj/structure/infection/turret/homing
	name = "homing turret"
	desc = "A frail looking turret that seems to track your every movement."
	max_integrity = 75
	projectile_type = /obj/item/projectile/bullet/infection/homing // the bullet fired for this turret
	upgrade_types = list(/datum/component/infection/upgrade/turret/home_target,
						 /datum/component/infection/upgrade/turret/turn_speed,
						 /datum/component/infection/upgrade/turret/flak_homing,
						 /datum/component/infection/upgrade/turret/stamina_damage)

