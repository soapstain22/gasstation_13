/*********************Mining Hammer****************/
/obj/item/weapon/twohanded/required/mining_hammer
	icon = 'icons/obj/mining.dmi'
	icon_state = "mining_hammer1"
	item_state = "mining_hammer1"
	name = "proto-kinetic crusher"
	desc = "An early design of the proto-kinetic accelerator, it is little more than an combination of various mining tools cobbled together, forming a high-tech club. \
	While it is an effective mining tool, it did little to aid any but the most skilled and/or suicidal miners against local fauna."
	force = 20 //As much as a bone spear, but this is significantly more annoying to carry around due to requiring the use of both hands at all times
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = SLOT_BACK
	force_unwielded = 20 //It's never not wielded so these are the same
	force_wielded = 20
	throwforce = 5
	throw_speed = 4
	luminosity = 4
	armour_penetration = 10
	materials = list(MAT_METAL=1150, MAT_GLASS=2075)
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("smashed", "crushed", "cleaved", "chopped", "pulped")
	sharpness = IS_SHARP
	var/list/trophies = list()
	var/charged = TRUE
	var/charge_time = 14

/obj/item/weapon/twohanded/required/mining_hammer/Destroy()
	for(var/a in trophies)
		qdel(a)
	trophies = null
	return ..()

/obj/item/weapon/twohanded/required/mining_hammer/examine(mob/user)
	..()
	to_chat(user, "<span class='notice'>Mark a large creature with the destabilizing force, then hit them in melee to do <b>50</b> damage.</span>")
	to_chat(user, "<span class='notice'>Does <b>80</b> damage if the target is backstabbed, instead of <b>50</b>.</span>")
	for(var/t in trophies)
		var/obj/item/crusher_trophy/T = t
		to_chat(user, "<span class='notice'>It has \a [T] attached, which causes [T.effect_desc()].</span>")

/obj/item/weapon/twohanded/required/mining_hammer/attackby(obj/item/A, mob/user)
	if(istype(A, /obj/item/weapon/crowbar))
		if(LAZYLEN(trophies))
			to_chat(user, "<span class='notice'>You remove [src]'s trophies.</span>")
			playsound(loc, A.usesound, 100, 1)
			for(var/t in trophies)
				var/obj/item/crusher_trophy/T = t
				T.remove_from(src, user)
		else
			to_chat(user, "<span class='warning'>There are no trophies on [src].</span>")
	else if(istype(A, /obj/item/crusher_trophy))
		var/obj/item/crusher_trophy/T = A
		T.add_to(src, user)
	else
		return ..()

/obj/item/weapon/twohanded/required/mining_hammer/attack(mob/living/target, mob/living/carbon/user)
	var/datum/status_effect/crusher_damage/C = target.has_status_effect(STATUS_EFFECT_CRUSHERDAMAGETRACKING)
	var/target_health = target.health
	..()
	if(!QDELETED(C) && !QDELETED(target))
		C.total_damage += target_health - target.health //we did some damage, but let's not assume how much we did

/obj/item/weapon/twohanded/required/mining_hammer/afterattack(atom/target, mob/user, proximity_flag)
	if(!proximity_flag && charged)//Mark a target, or mine a tile.
		var/turf/proj_turf = user.loc
		if(!isturf(proj_turf))
			return
		var/obj/item/projectile/destabilizer/D = new /obj/item/projectile/destabilizer(proj_turf)
		for(var/t in trophies)
			var/obj/item/crusher_trophy/T = t
			T.on_projectile_fire(D, user)
		D.preparePixelProjectile(target, get_turf(target), user)
		D.firer = user
		D.hammer_synced = src
		playsound(user, 'sound/weapons/plasma_cutter.ogg', 100, 1)
		D.fire()
		charged = FALSE
		icon_state = "mining_hammer1_uncharged"
		addtimer(CALLBACK(src, .proc/Recharge), charge_time)
		return
	if(proximity_flag && isliving(target))
		var/mob/living/L = target
		var/datum/status_effect/crusher_mark/CM = L.has_status_effect(STATUS_EFFECT_CRUSHERMARK)
		if(!CM || CM.hammer_synced != src || !L.remove_status_effect(STATUS_EFFECT_CRUSHERMARK))
			return
		var/datum/status_effect/crusher_damage/C = L.has_status_effect(STATUS_EFFECT_CRUSHERDAMAGETRACKING)
		var/target_health = L.health
		for(var/t in trophies)
			var/obj/item/crusher_trophy/T = t
			T.on_mark_detonation(target, user)
		new /obj/effect/temp_visual/kinetic_blast(get_turf(L))
		var/backstab_dir = get_dir(user, L)
		var/def_check = L.getarmor(type = "bomb")
		if((user.dir & backstab_dir) && (L.dir & backstab_dir))
			L.apply_damage(80, BRUTE, blocked = def_check)
			playsound(user, 'sound/weapons/Kenetic_accel.ogg', 100, 1) //Seriously who spelled it wrong
		else
			L.apply_damage(50, BRUTE, blocked = def_check)
		if(!QDELETED(C) && !QDELETED(L))
			C.total_damage += target_health - L.health //we did some damage, but let's not assume how much we did

/obj/item/weapon/twohanded/required/mining_hammer/proc/Recharge()
	if(!charged)
		charged = TRUE
		icon_state = "mining_hammer1"
		playsound(src.loc, 'sound/weapons/kenetic_reload.ogg', 60, 1)

//destablizing force
/obj/item/projectile/destabilizer
	name = "destabilizing force"
	icon_state = "pulse1"
	nodamage = TRUE
	damage = 0 //We're just here to mark people. This is still a melee weapon.
	damage_type = BRUTE
	flag = "bomb"
	range = 6
	log_override = TRUE
	var/obj/item/weapon/twohanded/required/mining_hammer/hammer_synced

/obj/item/projectile/destabilizer/Destroy()
	hammer_synced = null
	return ..()

/obj/item/projectile/destabilizer/on_hit(atom/target, blocked = 0)
	if(isliving(target))
		var/mob/living/L = target
		var/had_effect = (L.has_status_effect(STATUS_EFFECT_CRUSHERMARK)) //used as a boolean
		var/datum/status_effect/crusher_mark/CM = L.apply_status_effect(STATUS_EFFECT_CRUSHERMARK)
		if(hammer_synced)
			CM.hammer_synced = hammer_synced
			for(var/t in hammer_synced.trophies)
				var/obj/item/crusher_trophy/T = t
				T.on_mark_application(target, CM, had_effect)
	var/target_turf = get_turf(target)
	if(ismineralturf(target_turf))
		var/turf/closed/mineral/M = target_turf
		new /obj/effect/temp_visual/kinetic_blast(M)
		M.gets_drilled(firer)
	..()

//trophies
/obj/item/crusher_trophy
	name = "tail spike"
	desc = "A strange spike with no usage."
	icon = 'icons/obj/lavaland/artefacts.dmi'
	icon_state = "tail_spike"
	var/denied_type = /obj/item/crusher_trophy

/obj/item/crusher_trophy/examine(mob/user)
	..()
	to_chat(user, "<span class='notice'>Causes [effect_desc()] when attached to a kinetic crusher.</span>")

/obj/item/crusher_trophy/proc/effect_desc()
	return "errors"

/obj/item/crusher_trophy/attackby(obj/item/A, mob/user)
	if(istype(A, /obj/item/weapon/twohanded/required/mining_hammer))
		add_to(A, user)
	else
		..()

/obj/item/crusher_trophy/proc/add_to(obj/item/weapon/twohanded/required/mining_hammer/H, mob/user)
	for(var/t in H.trophies)
		var/obj/item/crusher_trophy/T = t
		if(istype(T, denied_type) || istype(src, T.denied_type))
			to_chat(user, "<span class='warning'>You can't seem to attach [src] to [H]. Maybe remove a few trophies?</span>")
			return FALSE
	H.trophies += src
	forceMove(H)
	to_chat(user, "<span class='notice'>You attach [src] to [H].</span>")
	return TRUE

/obj/item/crusher_trophy/proc/remove_from(obj/item/weapon/twohanded/required/mining_hammer/H, mob/user)
	forceMove(get_turf(H))
	H.trophies -= src
	return TRUE

/obj/item/crusher_trophy/proc/on_projectile_fire(obj/item/projectile/destabilizer/marker, mob/user) //the projectile fired and the user
/obj/item/crusher_trophy/proc/on_mark_application(mob/living/target, datum/status_effect/crusher_mark/mark, had_mark) //the target, the mark applied, and if the target had a mark before
/obj/item/crusher_trophy/proc/on_mark_detonation(mob/living/target, mob/user) //the target and the user

/obj/item/crusher_trophy/tail_spike
	desc = "A spike taken from a ash drake's tail."
	denied_type = /obj/item/crusher_trophy/tail_spike

/obj/item/crusher_trophy/tail_spike/effect_desc()
	return "you to push back the target when detonating a mark"

/obj/item/crusher_trophy/tail_spike/on_mark_detonation(mob/living/target, mob/user)
	playsound(target, 'sound/magic/Fireball.ogg', 25, 1)
	new /obj/effect/temp_visual/fire(target.loc)
	addtimer(CALLBACK(src, .proc/pushback, target, user), 1) //no free backstabs, we push AFTER module stuff is done

/obj/item/crusher_trophy/tail_spike/proc/pushback(mob/living/target, mob/user)
	step(target, get_dir(user, target))

/obj/item/crusher_trophy/demon_claws
	name = "demon claws"
	desc = "A set of blood-drenched claws from a massive demon's hand."
	icon_state = "demon_claws"
	gender = PLURAL
	denied_type = /obj/item/crusher_trophy/demon_claws
	var/bonus_damage = 5

/obj/item/crusher_trophy/demon_claws/effect_desc()
	return "you to do <b>[bonus_damage]</b> more damage when detonating a mark"

/obj/item/crusher_trophy/demon_claws/on_mark_detonation(mob/living/target, mob/user)
	target.adjustBruteLoss(bonus_damage)

/obj/item/crusher_trophy/blaster_tubes
	name = "blaster tubes"
	desc = "The blaster tubes from a colossus's arm."
	icon_state = "blaster_tubes"
	gender = PLURAL
	denied_type = /obj/item/crusher_trophy/blaster_tubes
	var/deadly_shot = FALSE
	var/bonus_damage = 5

/obj/item/crusher_trophy/blaster_tubes/effect_desc()
	return "your next destabilizer shot after detonating a mark to deal <b>[bonus_damage]</b> damage"

/obj/item/crusher_trophy/blaster_tubes/on_projectile_fire(obj/item/projectile/destabilizer/marker, mob/user)
	if(deadly_shot)
		marker.name = "deadly [marker.name]"
		marker.icon_state = "chronobolt"
		marker.damage = bonus_damage
		marker.nodamage = FALSE
		deadly_shot = FALSE

/obj/item/crusher_trophy/blaster_tubes/on_mark_detonation(mob/living/target, mob/user)
	deadly_shot = TRUE
	addtimer(CALLBACK(src, .proc/reset_deadly_shot), 300)

/obj/item/crusher_trophy/blaster_tubes/proc/reset_deadly_shot()
	deadly_shot = FALSE

/obj/item/crusher_trophy/vortex_talisman
	name = "vortex talisman"
	desc = "A glowing trinket that was originally the Hierophant's beacon."
	icon_state = "vortex_talisman"
	denied_type = /obj/item/crusher_trophy/vortex_talisman

/obj/item/crusher_trophy/vortex_talisman/effect_desc()
	return "you to create a barrier you can pass when detonating a mark"

/obj/item/crusher_trophy/vortex_talisman/on_mark_detonation(mob/living/target, mob/user)
	new /obj/effect/temp_visual/hierophant/wall/crusher(get_turf(user), user) //a wall only you can pass!

/obj/effect/temp_visual/hierophant/wall/crusher
	duration = 75
