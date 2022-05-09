//Fire
/mob/living/simple_animal/hostile/guardian/fire
	combat_mode = FALSE
	melee_damage_lower = 7
	melee_damage_upper = 7
	attack_sound = 'sound/items/welder.ogg'
	attack_verb_continuous = "ignites"
	attack_verb_simple = "ignite"
	damage_coeff = list(BRUTE = 0.7, BURN = 0.7, TOX = 0.7, CLONE = 0.7, STAMINA = 0, OXY = 0.7)
	range = 7
	playstyle_string = "<span class='holoparasite'>As a <b>chaos</b> type, you have only light damage resistance, but will ignite any enemy you bump into. In addition, your melee attacks will cause human targets to see everyone as you.</span>"
	magic_fluff_string = "<span class='holoparasite'>..And draw the Wizard, bringer of endless chaos!</span>"
	tech_fluff_string = "<span class='holoparasite'>Boot sequence complete. Crowd control modules activated. Holoparasite swarm online.</span>"
	carp_fluff_string = "<span class='holoparasite'>CARP CARP CARP! You caught one! OH GOD, EVERYTHING'S ON FIRE. Except you and the fish.</span>"
	miner_fluff_string = "<span class='holoparasite'>You encounter... Plasma, the bringer of fire.</span>"

/mob/living/simple_animal/hostile/guardian/fire/Initialize(mapload, theme)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = .proc/on_entered,
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/mob/living/simple_animal/hostile/guardian/fire/Life(delta_time = SSMOBS_DT, times_fired)
	. = ..()
	if(summoner)
		summoner.extinguish_mob()
		summoner.adjust_fire_stacks(-10 * delta_time)

/mob/living/simple_animal/hostile/guardian/fire/AttackingTarget()
	. = ..()
	if(!.)
		return
	if(!isliving(target))
		return
	if(target == summoner)
		return
	var/mob/living/living_target = target
	living_target.cause_hallucination(
		/datum/hallucination/delusion,
		"fire holoparasite ([src], owned by [summoner])",
		duration = 20 SECONDS,
		skip_nearby = FALSE,
		custom_icon = icon_state,
		custom_icon_file = icon,
	)

/mob/living/simple_animal/hostile/guardian/fire/proc/on_entered(datum/source, AM as mob|obj)
	SIGNAL_HANDLER
	collision_ignite(AM)

/mob/living/simple_animal/hostile/guardian/fire/Bumped(atom/movable/AM)
	..()
	collision_ignite(AM)

/mob/living/simple_animal/hostile/guardian/fire/Bump(AM as mob|obj)
	..()
	collision_ignite(AM)

/mob/living/simple_animal/hostile/guardian/fire/proc/collision_ignite(AM as mob|obj)
	if(isliving(AM))
		var/mob/living/M = AM
		if(!hasmatchingsummoner(M) && M != summoner && M.fire_stacks < 7)
			M.set_fire_stacks(7)
			M.ignite_mob()
