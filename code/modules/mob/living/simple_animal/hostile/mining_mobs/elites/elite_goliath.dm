/*

Elite goliath

The elite goliath is a simple test of keeping a constant eye on the foe and your surrondings.  His attacks are as follows:

- The elite goliath's tentacles deal 10 ticks of stun and 20 to 25 damage, balancing how often they're used.
- 3x3 of tentacles spawn underneath the target, giving 1.5 seconds of OnFire cooldown.
- A line of tentacles go from the goliath to the target at max range of 7, also giving 1.5 seconds of OnFire cooldown.
- The goliath turns red and emits a sound, suddenly becoming much faster than before.  This effect lasts for 5 seconds with a 7 second OnFire cooldown.
- The goliath brings up 3 fragile, explosive mushrooms one after another by the target area.  The mushrooms have an arming time of 2 seconds, any attack which destroys them afterwards will cause a fiery explosion in a 5x5 radius.
The elite goliath's tentacles will also detonate them.  This attack has a 4 second onFire cooldown.
- Does 30 damage in melee.
- Once below half health, every 3 seconds 4 random tentacles will attempt to spawn in a 5-tile radius around the goliath.  If below 25%, 8 random tentacles will spawn.

While one of the more basic elites, this fight encourages keeping an eye out for the goliath's tentacles, while making sure not to stray too close to the goliath in case of a rage.  Simple enough to fight
without too much knowledge of the mechanics, with low health tentacles adding extra things to dodge later into the fight.  Considering the official fight happens in an enclosed space, one must make sure the goliath doesn't
corner their movement options with mushrooms.

The AI version isn't too complicated of a fight, as the AI can't consistently capitalize on the player's mistakes nor place tentacles with foresight of the player's movements, however, the player-controlled
variant has potential to be very robust, manipulating the target with tentacles to bait them into a mushroom setup or a rage.

*/

/mob/living/simple_animal/hostile/asteroid/elite/goliath
	name = "elite goliath"
	desc = "A hulking, armor-plated beast with long tendrils arching from its back.  This one seems extra tough."
	icon_state = "elite_goliath"
	icon_living = "elite_goliath"
	icon_aggro = "elite_goliath"
	icon_dead = "elite_goliath_dead"
	icon_gib = "syndicate_gib"
	maxHealth = 800
	health = 800
	melee_damage_lower = 30
	melee_damage_upper = 30
	attacktext = "pulverizes"
	attack_sound = 'sound/weapons/punch1.ogg'
	throw_message = "does nothing to the rocky hide of the"
	speed = 2
	move_to_delay = 5
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mouse_opacity = MOUSE_OPACITY_ICON

	attack_action_types = list(/datum/action/innate/elite_attack/tentacle_square,
								/datum/action/innate/elite_attack/tentacle_line,
								/datum/action/innate/elite_attack/rage,
								/datum/action/innate/elite_attack/explosive_shroom)
	
	var/rand_tent = 0
	
/datum/action/innate/elite_attack/tentacle_square
	name = "Tentacle Square"
	icon_icon = 'icons/obj/wizard.dmi'
	button_icon_state = ""
	chosen_message = "<span class='colossus'>You are now attacking with a 3x3 of tentacles.</span>"
	chosen_attack_num = 1
	
/datum/action/innate/elite_attack/tentacle_line
	name = "Tentacle Line"
	icon_icon = 'icons/obj/wizard.dmi'
	button_icon_state = ""
	chosen_message = "<span class='colossus'>You are now attacking with a line of tentacles.</span>"
	chosen_attack_num = 2
	
/datum/action/innate/elite_attack/rage
	name = "Rage"
	icon_icon = 'icons/obj/wizard.dmi'
	button_icon_state = ""
	chosen_message = "<span class='colossus'>You will temporarily increase your movement speed.</span>"
	chosen_attack_num = 3
	
/datum/action/innate/elite_attack/explosive_shroom
	name = "Spawn Explosive Shrooms"
	icon_icon = 'icons/obj/wizard.dmi'
	button_icon_state = ""
	chosen_message = "<span class='colossus'>You will spawn 3 random explosive shrooms by the target.</span>"
	chosen_attack_num = 4
	
/mob/living/simple_animal/hostile/asteroid/elite/goliath/OpenFire()
	if(client)
		switch(chosen_attack)
			if(1)
				tentacle_square(target)
			if(2)
				tentacle_line(target)
			if(3)
				rage()
			if(4)
				explosive_shroom(target)
		return
	
	var/aiattack = rand(1,4)
	switch(aiattack)
		if(1)
			tentacle_square(target)
		if(2)
			tentacle_line(target)
		if(3)
			rage()
		if(4)
			explosive_shroom(target)
		
	
//Tentacles have less stun time compared to regular variant, to balance being able to use them much more often.  Also, 10 more damage.
/obj/effect/temp_visual/goliath_tentacle/elite/trip()
	var/latched = FALSE
	for(var/obj/structure/explosive_shroom/S in loc)
		S.take_damage(5)
	for(var/mob/living/L in loc)
		if((!QDELETED(spawner) && spawner.faction_check_mob(L)) || L.stat == DEAD)
			continue
		visible_message("<span class='danger'>[src] grabs hold of [L]!</span>")
		L.Stun(10)
		L.adjustBruteLoss(rand(20,25))
		latched = TRUE
	if(!latched)
		retract()
	else
		deltimer(timerid)
		timerid = addtimer(CALLBACK(src, .proc/retract), 10, TIMER_STOPPABLE)
	
/mob/living/simple_animal/hostile/asteroid/elite/goliath/proc/tentacle_square(var/target)	
	ranged_cooldown = world.time + 15
	var/tturf = get_turf(target)
	if(!isturf(tturf))
		return
	if(get_dist(src, target) <= 7)//Screen range check, so it can't attack people off-screen
		visible_message("<span class='warning'>[src] digs its tentacles under [target]!</span>")
		new /obj/effect/temp_visual/goliath_tentacle/elite/square(tturf, src)
		
/obj/effect/temp_visual/goliath_tentacle/elite/square/Initialize(mapload, new_spawner)
	. = ..()
	var/list/directions = GLOB.cardinals.Copy() + GLOB.diagonals.Copy()
	for(var/i in 1 to 8)
		var/spawndir = pick_n_take(directions)
		var/turf/T = get_step(src, spawndir)
		if(T)
			new /obj/effect/temp_visual/goliath_tentacle/elite(T, spawner)
	
/mob/living/simple_animal/hostile/asteroid/elite/goliath/proc/line_target(var/offset, var/range, var/atom/at = target)
	if(!at)
		return
	var/angle = ATAN2(at.x - src.x, at.y - src.y) + offset
	var/turf/T = get_turf(src)
	for(var/i in 1 to range)
		var/turf/check = locate(src.x + cos(angle) * i, src.y + sin(angle) * i, src.z)
		if(!check)
			break
		T = check
	return (getline(src, T) - get_turf(src))
	
/mob/living/simple_animal/hostile/asteroid/elite/goliath/proc/tentacle_line(var/target)	
	ranged_cooldown = world.time + 15
	var/tturf = get_turf(target)
	if(!isturf(tturf))
		return
	if(get_dist(src, target) <= 7)//Screen range check, so it can't attack off-screen
		visible_message("<span class='warning'>[src] digs its tentacles in a line towards [target]!</span>")
		new /obj/effect/temp_visual/goliath_tentacle/elite(tturf, src)
	var/list/turfs = line_target(0, 7, target)
	for(var/t in turfs)
		new /obj/effect/temp_visual/goliath_tentacle/elite(t, src)
		
/mob/living/simple_animal/hostile/asteroid/elite/goliath/proc/rage()
	ranged_cooldown = world.time + 70
	playsound(src,'sound/spookoween/insane_low_laugh.ogg', 200, 1)
	visible_message("<span class='warning'>[src] starts picking up speed!</span>")
	color = rgb(150,0,0)
	src.set_varspeed(0)
	src.move_to_delay = 3
	sleep(50)
	color = rgb(255, 255, 255)
	src.set_varspeed(2)
	src.move_to_delay = 5
	
/obj/structure/explosive_shroom
	name = "explosive shroom"
	icon = 'icons/mob/lavaland/elite_lavaland_monsters.dmi'
	icon_state = "explosive_shroom_active"
	max_integrity = 5
	move_resist = MOVE_FORCE_EXTREMELY_STRONG
	anchored = TRUE
	density = TRUE
	light_range = 2
	light_color = LIGHT_COLOR_RED
	
	var/armed = 0

/obj/structure/explosive_shroom/Initialize()
	. = ..()
	if(ismineralturf(loc))
		var/turf/closed/mineral/M = loc
		M.gets_drilled()
	playsound(src, 'sound/effects/bamf.ogg', 100, 1)
	icon_state = "explosive_shroom_activate"
	sleep(20)
	icon_state = "explosive_shroom_active"
	armed = 1

	
/obj/structure/explosive_shroom/deconstruct(disassembled)
	if(armed)
		visible_message("<span class='warning'>[src] explodes!</span>")
		explosion(get_turf(loc),0,0,0,flame_range = 3, adminlog = FALSE)
	else
		playsound(src, 'sound/effects/hit_kick.ogg', 100, 1)
	. = ..()
		
/mob/living/simple_animal/hostile/asteroid/elite/goliath/proc/explosive_shroom(var/target)	
	ranged_cooldown = world.time + 40
	var/tturf = get_turf(target)
	if(get_dist(src, target) <= 7)//Screen range check, so it can't attack people off-screen
		visible_message("<span class='warning'>[src]'s tentacles force strange mushrooms to appear near [target]!</span>")
		var/list/directions = GLOB.cardinals.Copy()
		for(var/i in 1 to 3)
			var/spawndir = pick_n_take(directions)
			var/turf/T = get_step(tturf, spawndir)
			if(T && T.CanPass(src, T))
				new /obj/structure/explosive_shroom(T, src)
				
/mob/living/simple_animal/hostile/asteroid/elite/goliath/Life()
	. = ..()	
	if(health < maxHealth * 0.5 && rand_tent < world.time && stat != DEAD)
		rand_tent = world.time + 30
		var/tentacle_amount = 4
		if(health < maxHealth * 0.5)
			tentacle_amount = 8
		var/tentacle_loc = spiral_range_turfs(5, get_turf(src))
		for(var/i in 1 to tentacle_amount)
			var/turf/t = pick_n_take(tentacle_loc)
			new /obj/effect/temp_visual/goliath_tentacle/elite(t, src)	