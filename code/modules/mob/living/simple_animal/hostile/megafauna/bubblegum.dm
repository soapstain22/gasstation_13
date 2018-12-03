/*

BUBBLEGUM

Bubblegum spawns randomly wherever a lavaland creature is able to spawn. It is the most powerful slaughter demon in existence.
Bubblegum's footsteps are heralded by shaking booms, proving its tremendous size.

It acts as a melee creature, chasing down and attacking its target while also using different attacks to augment its power that increase as it takes damage.

It tries to strike at its target through any bloodpools under them; if it fails to do that, it will spray blood and then attempt to warp to a bloodpool near the target.
If it fails to warp to a target, it may summon up to 6 slaughterlings from the blood around it.
If it does not summon all 6 slaughterlings, it will instead charge at its target, dealing massive damage to anything it hits and spraying a stream of blood.
At half health, it will either charge three times or warp, then charge, instead of doing a single charge.

When Bubblegum dies, it leaves behind a H.E.C.K. mining suit as well as a chest that can contain three things:
 1. A bottle that, when activated, drives everyone nearby into a frenzy
 2. A contract that marks for death the chosen target
 3. A spellblade that can slice off limbs at range

Difficulty: Hard

*/

/mob/living/simple_animal/hostile/megafauna/bubblegum
	name = "bubblegum"
	desc = "In what passes for a hierarchy among slaughter demons, this one is king."
	health = 2500
	maxHealth = 2500
	attacktext = "rends"
	attack_sound = 'sound/magic/demon_attack1.ogg'
	icon_state = "bubblegum"
	icon_living = "bubblegum"
	icon_dead = ""
	friendly = "stares down"
	icon = 'icons/mob/lavaland/96x96megafauna.dmi'
	speak_emote = list("gurgles")
	armour_penetration = 40
	melee_damage_lower = 40
	melee_damage_upper = 40
	speed = 1
	move_to_delay = 7.5
	retreat_distance = 5
	minimum_distance = 5
	rapid_melee = 8 // every 1/4 second
	melee_queue_distance = 20 // as far as possible really, need this because of blood warp
	ranged = 1
	pixel_x = -32
	del_on_death = 1
	crusher_loot = list(/obj/structure/closet/crate/necropolis/bubblegum/crusher)
	loot = list(/obj/structure/closet/crate/necropolis/bubblegum)
	blood_volume = BLOOD_VOLUME_MAXIMUM //BLEED FOR ME
	var/charging = 0
	var/enrage_till = null
	medal_type = BOSS_MEDAL_BUBBLEGUM
	score_type = BUBBLEGUM_SCORE
	deathmessage = "sinks into a pool of blood, fleeing the battle. You've won, for now... "
	deathsound = 'sound/magic/enter_blood.ogg'

/obj/item/gps/internal/bubblegum
	icon_state = null
	gpstag = "Bloody Signal"
	desc = "You're not quite sure how a signal can be bloody."
	invisibility = 100

/mob/living/simple_animal/hostile/megafauna/bubblegum/adjustBruteLoss(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(. > 0 && prob(25))
		var/obj/effect/decal/cleanable/blood/gibs/bubblegum/B = new /obj/effect/decal/cleanable/blood/gibs/bubblegum(loc)
		if(prob(40))
			step(B, pick(GLOB.cardinals))
		else
			B.setDir(pick(GLOB.cardinals))

/obj/effect/decal/cleanable/blood/gibs/bubblegum
	name = "thick blood"
	desc = "Thick, splattered blood."
	random_icon_states = list("gib3", "gib5", "gib6")
	bloodiness = 20

/obj/effect/decal/cleanable/blood/gibs/bubblegum/can_bloodcrawl_in()
	return TRUE

/mob/living/simple_animal/hostile/megafauna/bubblegum/Life()
	..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/OpenFire()
	anger_modifier = CLAMP(((maxHealth - health)/60),0,20)
	if(charging)
		return
	ranged_cooldown = world.time + ranged_cooldown_time

	if(!try_bloodattack())
		INVOKE_ASYNC(src, .proc/blood_spray)
		blood_warp()

	if(health > maxHealth * 0.5)
		if(prob(50))
			charge()
		else
			hallucination_charge_around(pick(GLOB.cardinals, GLOB.diagonals))
	else
		if(prob(50))
			charge()
		else
			hallucination_charge_around(GLOB.cardinals + GLOB.diagonals)

/mob/living/simple_animal/hostile/megafauna/bubblegum/Initialize()
	. = ..()
	if(istype(src, /mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination))
		return
	for(var/mob/living/simple_animal/hostile/megafauna/bubblegum/B in GLOB.mob_living_list)
		if(B != src)
			return INITIALIZE_HINT_QDEL //There can be only one
	var/obj/effect/proc_holder/spell/bloodcrawl/bloodspell = new
	AddSpell(bloodspell)
	if(istype(loc, /obj/effect/dummy/phased_mob/slaughter))
		bloodspell.phased = TRUE
	internal = new/obj/item/gps/internal/bubblegum(src)

/mob/living/simple_animal/hostile/megafauna/bubblegum/grant_achievement(medaltype,scoretype)
	. = ..()
	if(.)
		SSshuttle.shuttle_purchase_requirements_met |= "bubblegum"

/mob/living/simple_animal/hostile/megafauna/bubblegum/do_attack_animation(atom/A, visual_effect_icon)
	if(!charging)
		..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/AttackingTarget()
	if(!charging)
		. = ..()
		if(.)
			recovery_time = world.time + 20 // can only attack melee once every 2 seconds but rapid_melee gives higher priority

/mob/living/simple_animal/hostile/megafauna/bubblegum/bullet_act(obj/item/projectile/P)
	if(is_enraged())
		visible_message("<span class='danger'>[src] deflects the projectile; [p_they()] can't be hit with ranged weapons while enraged!</span>", "<span class='userdanger'>You deflect the projectile!</span>")
		playsound(src, pick('sound/weapons/bulletflyby.ogg', 'sound/weapons/bulletflyby2.ogg', 'sound/weapons/bulletflyby3.ogg'), 300, 1)
		return 0
	return ..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/ex_act(severity, target)
	if(severity >= EXPLODE_LIGHT)
		return
	severity = EXPLODE_LIGHT // puny mortals
	return ..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/CanPass(atom/movable/mover, turf/target)
	if(istype(mover, /mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination))
		return 1
	return ..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/Goto(target, delay, minimum_distance)
	if(!charging)
		..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/MoveToTarget(list/possible_targets)
	if(!charging)
		..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/Move()
	if(charging)
		new /obj/effect/temp_visual/decoy/fading(loc,src)
		DestroySurroundings()
	..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/Moved()
	if(charging)
		DestroySurroundings()
	if(is_enraged())
		INVOKE_ASYNC(src, .proc/ground_slam)
	else
		playsound(src, 'sound/effects/meteorimpact.ogg', 200, 1, 2, 1)
	return ..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/charge(var/atom/chargeat = target, var/delay = 3)
	if(!chargeat)
		return
	var/dir = get_dir(src, chargeat)
	var/turf/T = get_ranged_target_turf(get_turf(chargeat), dir, 2)
	if(!T)
		return
	new /obj/effect/temp_visual/dragon_swoop/bubblegum(T)
	charging = 1
	DestroySurroundings()
	walk(src, 0)
	setDir(dir)
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(loc,src)
	animate(D, alpha = 0, color = "#FF0000", transform = matrix()*2, time = 3)
	sleep(delay)
	var/movespeed = 0.7
	walk_towards(src, T, movespeed)
	sleep(get_dist(src, T) * movespeed)
	try_bloodattack()
	charging = 0
	if(target)
		MoveToTarget(target) // get moving nerd

/mob/living/simple_animal/hostile/megafauna/bubblegum/Bump(atom/A)
	if(charging)
		if(isturf(A) || isobj(A) && A.density)
			A.ex_act(EXPLODE_HEAVY)
		DestroySurroundings()
		if(isliving(A) && !is_enraged())
			var/mob/living/L = A
			L.visible_message("<span class='danger'>[src] slams into [L]!</span>", "<span class='userdanger'>[src] tramples you into the ground!</span>")
			src.forceMove(get_turf(L))
			L.apply_damage(40, BRUTE)
			playsound(get_turf(L), 'sound/effects/meteorimpact.ogg', 100, 1)
			shake_camera(L, 4, 3)
			shake_camera(src, 2, 3)
	..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/get_mobs_on_blood()
	var/list/targets = ListTargets()
	. = list()
	for(var/mob/living/L in targets)
		var/list/bloodpool = get_pools(get_turf(L), 0)
		if(bloodpool.len && (!faction_check_mob(L) || L.stat == DEAD))
			. += L

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/try_bloodattack()
	var/list/targets = get_mobs_on_blood()
	if(targets.len)
		INVOKE_ASYNC(src, .proc/bloodattack, targets, prob(50))
		return TRUE
	return FALSE

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/bloodattack(list/targets, handedness)
	var/mob/living/target_one = pick_n_take(targets)
	var/turf/target_one_turf = get_turf(target_one)
	var/mob/living/target_two
	if(targets.len)
		target_two = pick_n_take(targets)
		var/turf/target_two_turf = get_turf(target_two)
		if(target_two.stat != CONSCIOUS || prob(10))
			bloodgrab(target_two_turf, handedness)
		else
			bloodsmack(target_two_turf, handedness)

	if(target_one)
		var/list/pools = get_pools(get_turf(target_one), 0)
		if(pools.len)
			target_one_turf = get_turf(target_one)
			if(target_one_turf)
				if(target_one.stat != CONSCIOUS || prob(10))
					bloodgrab(target_one_turf, !handedness)
				else
					bloodsmack(target_one_turf, !handedness)

	if(!target_two && target_one)
		var/list/poolstwo = get_pools(get_turf(target_one), 0)
		if(poolstwo.len)
			target_one_turf = get_turf(target_one)
			if(target_one_turf)
				if(target_one.stat != CONSCIOUS || prob(10))
					bloodgrab(target_one_turf, handedness)
				else
					bloodsmack(target_one_turf, handedness)

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/bloodsmack(turf/T, handedness)
	if(handedness)
		new /obj/effect/temp_visual/bubblegum_hands/rightsmack(T)
	else
		new /obj/effect/temp_visual/bubblegum_hands/leftsmack(T)
	sleep(2.5)
	for(var/mob/living/L in T)
		if(!faction_check_mob(L))
			to_chat(L, "<span class='userdanger'>[src] rends you!</span>")
			playsound(T, attack_sound, 100, 1, -1)
			var/limb_to_hit = L.get_bodypart(pick(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG))
			L.apply_damage(25, BRUTE, limb_to_hit, L.run_armor_check(limb_to_hit, "melee", null, null, armour_penetration))
	sleep(3)

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/bloodgrab(turf/T, handedness)
	if(handedness)
		new /obj/effect/temp_visual/bubblegum_hands/rightpaw(T)
		new /obj/effect/temp_visual/bubblegum_hands/rightthumb(T)
	else
		new /obj/effect/temp_visual/bubblegum_hands/leftpaw(T)
		new /obj/effect/temp_visual/bubblegum_hands/leftthumb(T)
	sleep(6)
	for(var/mob/living/L in T)
		if(!faction_check_mob(L))
			to_chat(L, "<span class='userdanger'>[src] drags you through the blood!</span>")
			playsound(T, 'sound/magic/enter_blood.ogg', 100, 1, -1)
			var/turf/targetturf = get_step(src, dir)
			L.forceMove(targetturf)
			playsound(targetturf, 'sound/magic/exit_blood.ogg', 100, 1, -1)
			if(L.stat != CONSCIOUS)
				addtimer(CALLBACK(src, .proc/devour, L), 2)
	sleep(1)

/obj/effect/temp_visual/dragon_swoop/bubblegum
	duration = 10

/obj/effect/temp_visual/bubblegum_hands
	icon = 'icons/effects/bubblegum.dmi'
	duration = 9

/obj/effect/temp_visual/bubblegum_hands/rightthumb
	icon_state = "rightthumbgrab"

/obj/effect/temp_visual/bubblegum_hands/leftthumb
	icon_state = "leftthumbgrab"

/obj/effect/temp_visual/bubblegum_hands/rightpaw
	icon_state = "rightpawgrab"
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/bubblegum_hands/leftpaw
	icon_state = "leftpawgrab"
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/bubblegum_hands/rightsmack
	icon_state = "rightsmack"

/obj/effect/temp_visual/bubblegum_hands/leftsmack
	icon_state = "leftsmack"

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/ground_slam(var/range = 1)
	var/turf/orgin = get_turf(src)
	var/list/hitby = list()
	for(var/i = 0 to range)
		for(var/turf/T in RANGE_TURFS(i, orgin))
			playsound(T,'sound/effects/bamf.ogg', 600, 1, 10)
			if(ismineralturf(T))
				var/turf/closed/mineral/M = T
				M.gets_drilled()
			new /obj/effect/temp_visual/small_smoke/halfsecond(T)
			for(var/mob/living/L in T)
				if(istype(L, /mob/living/simple_animal/hostile/megafauna/bubblegum) || L.throwing)
					continue
				hitby += L
				to_chat(L, "<span class='userdanger'>[src]'s ground slam shockwave sends you flying!</span>")
				var/turf/thrownat = get_ranged_target_turf(L, get_dir(orgin, L), 4)
				L.throw_at(thrownat, get_dist(L, thrownat), 2, L, 1)
				L.apply_damage(20, BRUTE)
				shake_camera(L, 2, 1)
		sleep(2)
	return

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/blood_warp()
	if(Adjacent(target) || (enrage_till + 30 > world.time))
		return FALSE
	var/list/can_jaunt = get_pools(get_turf(src), 1)
	if(!can_jaunt.len)
		return FALSE

	var/list/pools = get_pools(get_turf(target), 2)
	var/list/pools_to_remove = get_pools(get_turf(target), 1)
	pools -= pools_to_remove
	if(!pools.len)
		return FALSE

	var/obj/effect/temp_visual/decoy/DA = new /obj/effect/temp_visual/decoy(loc,src)
	DA.color = "#FF0000"
	var/oldtransform = DA.transform
	DA.transform = matrix()*2
	animate(DA, alpha = 255, color = initial(DA.color), transform = oldtransform, time = 3)
	sleep(3)
	qdel(DA)

	var/obj/effect/decal/cleanable/blood/found_bloodpool
	pools = get_pools(get_turf(target), 2)
	pools_to_remove = get_pools(get_turf(target), 1)
	pools -= pools_to_remove
	if(pools.len)
		shuffle_inplace(pools)
		found_bloodpool = pick(pools)
	if(found_bloodpool)
		visible_message("<span class='danger'>[src] sinks into the blood...</span>")
		playsound(get_turf(src), 'sound/magic/enter_blood.ogg', 100, 1, -1)
		forceMove(get_turf(found_bloodpool))
		playsound(get_turf(src), 'sound/magic/exit_blood.ogg', 100, 1, -1)
		visible_message("<span class='danger'>And springs back out!</span>")
		blood_enrage()
		return TRUE
	return FALSE

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/blood_enrage(var/boost_time = 30)
	enrage_till = world.time + boost_time
	retreat_distance = null
	minimum_distance = 1
	change_move_delay(initial(move_to_delay) / 2) // double move speed
	var/newcolor = rgb(149, 10, 10)
	add_atom_colour(newcolor, TEMPORARY_COLOUR_PRIORITY)
	var/datum/callback/cb = CALLBACK(src, .proc/blood_enrage_end)
	addtimer(cb, boost_time)

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/blood_enrage_end(var/newcolor = rgb(149, 10, 10))
	retreat_distance = initial(retreat_distance)
	minimum_distance = initial(minimum_distance)
	change_move_delay()
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, newcolor)

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/is_enraged()
	return (enrage_till > world.time)

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/change_move_delay(var/newmove = initial(move_to_delay))
	move_to_delay = newmove
	handle_automated_action() // need to recheck movement otherwise move_to_delay won't update until the next checking aka will be wrong speed for a bit

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/blood_spray(var/range = 25, var/atom/shootat = target)
	if(!shootat)
		return
	var/angle = ATAN2(shootat.x - src.x, shootat.y - src.y) // angle to the target
	var/turf/end = get_turf(src)
	for(var/i = 1 to range)
		var/turf/check = locate(src.x + cos(angle) * i, src.y + sin(angle) * i, src.z)
		if(!check)
			break
		end = check
	var/list/toaffect = getline(src, end)
	if(!toaffect.len || toaffect.len < 2)
		return
	visible_message("<span class='danger'>[src] sprays a stream of gore!</span>")
	for(var/i = 2 to toaffect.len)
		var/turf/J = toaffect[i]
		var/turf/previousturf = toaffect[i - 1]
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(previousturf, get_dir(previousturf, J))
		playsound(J,'sound/effects/splat.ogg', 100, 1, -1)
		new /obj/effect/decal/cleanable/blood(J)
		sleep((previousturf.x - J.x == 0 || previousturf.y - J.y == 0) ? 1 : 2) // diagonals take longer

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/get_pools(turf/T, range)
	. = list()
	for(var/obj/effect/decal/cleanable/nearby in view(T, range))
		if(nearby.can_bloodcrawl_in())
			. += nearby

/obj/effect/decal/cleanable/blood/bubblegum
	bloodiness = 0

/obj/effect/decal/cleanable/blood/bubblegum/can_bloodcrawl_in()
	return TRUE

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/hallucination_charge_around(var/list/directions = GLOB.cardinals)
	if(!target || !directions.len)
		return
	charging = 1
	var/turf/chargeat = get_turf(target)
	var/distance = directions.len
	var/realspawn = pick(directions)
	var/tocharge = list()
	var/waittime = 6 + directions.len * 0.4
	for(var/dir in (directions - realspawn))
		var/turf/place = get_ranged_target_turf(chargeat, dir, distance)
		var/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/B = new /mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination(src.loc)
		B.forceMove(place)
		tocharge += B
	for(var/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/B in tocharge)
		INVOKE_ASYNC(B, .proc/charge, chargeat, waittime)
	var/turf/place = get_ranged_target_turf(chargeat, realspawn, distance)
	forceMove(place)
	charge(chargeat, waittime)
	charging = 0


/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination
	name = "bubblegum's hallucination"
	desc = "Is that really just a hallucination?"
	health = 1
	maxHealth = 1
	alpha = 127.5
	crusher_loot = null
	loot = null
	medal_type = null
	score_type = null
	deathmessage = "Explodes into a pool of blood!"
	deathsound = 'sound/effects/splat.ogg'

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/Initialize()
	..()
	toggle_ai(AI_OFF)

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/charge(var/atom/chargeat = target)
	..()
	qdel(src)

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/Destroy()
	new /obj/effect/decal/cleanable/blood(get_turf(src))
	. = ..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/CanPass(atom/movable/mover, turf/target)
	if(istype(mover, /mob/living/simple_animal/hostile/megafauna/bubblegum)) // hallucinations should not be stopping bubblegum or eachother
		return 1
	return ..()

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/Life()
	return

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/adjustBruteLoss(amount, updating_health = TRUE, forced = FALSE)
	return

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/OpenFire()
	return

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/AttackingTarget()
	return

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/try_bloodattack()
	return

/mob/living/simple_animal/hostile/megafauna/bubblegum/hallucination/grant_achievement(medaltype,scoretype)
	return

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/slaughterlings()
	visible_message("<span class='danger'>[src] summons a shoal of slaughterlings!</span>")
	var/max_amount = 6
	for(var/H in get_pools(get_turf(src), 1))
		if(!max_amount)
			break
		max_amount--
		var/obj/effect/decal/cleanable/blood/B = H
		new /mob/living/simple_animal/hostile/asteroid/hivelordbrood/slaughter(B.loc)
	return max_amount

/mob/living/simple_animal/hostile/asteroid/hivelordbrood/slaughter
	name = "slaughterling"
	desc = "Though not yet strong enough to create a true physical form, it's nonetheless determined to murder you."
	icon_state = "bloodbrood"
	icon_living = "bloodbrood"
	icon_aggro = "bloodbrood"
	attacktext = "pierces"
	color = "#C80000"
	density = FALSE
	faction = list("mining", "boss")
	weather_immunities = list("lava","ash")

/mob/living/simple_animal/hostile/asteroid/hivelordbrood/slaughter/CanPass(atom/movable/mover, turf/target)
	if(istype(mover, /mob/living/simple_animal/hostile/megafauna/bubblegum))
		return 1
	return 0