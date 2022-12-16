//Healer
/mob/living/simple_animal/hostile/guardian/healer
	combat_mode = TRUE
	friendly_verb_continuous = "heals"
	friendly_verb_simple = "heal"
	speed = 0
	damage_coeff = list(BRUTE = 0.7, BURN = 0.7, TOX = 0.7, CLONE = 0.7, STAMINA = 0, OXY = 0.7)
	melee_damage_lower = 15
	melee_damage_upper = 15
	playstyle_string = span_holoparasite("As a <b>support</b> type, you may toggle your basic attacks to a healing mode. In addition, right-clicking on an adjacent object or mob will warp them to your bluespace beacon after a short delay.")
	magic_fluff_string = span_holoparasite("..And draw the CMO, a potent force of life... and death.")
	carp_fluff_string = span_holoparasite("CARP CARP CARP! You caught a support carp. It's a kleptocarp!")
	tech_fluff_string = span_holoparasite("Boot sequence complete. Support modules active. Holoparasite swarm online.")
	miner_fluff_string = span_holoparasite("You encounter... Bluespace, the master of support.")
	toggle_button_type = /atom/movable/screen/guardian/toggle_mode
	/// Is it in healing mode?
	var/toggle = FALSE
	/// How much we heal per hit.
	var/healing_amount = 5
	/// Our teleportation beacon.
	var/obj/structure/receiving_pad/beacon
	/// Time it takes to teleport.
	var/teleporting_time = 6 SECONDS
	/// Time between the beacon uses.
	var/beacon_cooldown_time = 5 MINUTES
	/// Cooldown between using the beacon.
	COOLDOWN_DECLARE(beacon_cooldown)

/mob/living/simple_animal/hostile/guardian/healer/Initialize(mapload)
	. = ..()
	var/datum/atom_hud/medsensor = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
	medsensor.show_to(src)

/mob/living/simple_animal/hostile/guardian/healer/get_status_tab_items()
	. = ..()
	if(!COOLDOWN_FINISHED(src, beacon_cooldown))
		. += "Beacon Cooldown Remaining: [DisplayTimeText(beacon_cooldown - world.time)]"

/mob/living/simple_animal/hostile/guardian/healer/AttackingTarget(atom/attacked_target)
	. = ..()
	if(!is_deployed() || !toggle || !isliving(target))
		return
	var/mob/living/carbon/living_target = target
	living_target.adjustBruteLoss(-healing_amount)
	living_target.adjustFireLoss(-healing_amount)
	living_target.adjustOxyLoss(-healing_amount)
	living_target.adjustToxLoss(-healing_amount)
	var/obj/effect/temp_visual/heal/heal_effect = new /obj/effect/temp_visual/heal(get_turf(living_target))
	if(guardian_color)
		heal_effect.color = guardian_color
	if(living_target == summoner)
		update_health_hud()
		med_hud_set_health()
		med_hud_set_status()

/mob/living/simple_animal/hostile/guardian/healer/ToggleMode()
	if(loc == summoner)
		if(toggle)
			set_combat_mode(TRUE)
			speed = 0
			damage_coeff = list(BRUTE = 0.7, BURN = 0.7, TOX = 0.7, CLONE = 0.7, STAMINA = 0, OXY = 0.7)
			melee_damage_lower = initial(melee_damage_lower)
			melee_damage_upper = initial(melee_damage_upper)
			to_chat(src, span_bolddanger("You switch to combat mode."))
			toggle = FALSE
		else
			set_combat_mode(FALSE)
			speed = 1
			damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 1)
			melee_damage_lower = 0
			melee_damage_upper = 0
			to_chat(src, span_bolddanger("You switch to healing mode."))
			toggle = TRUE
	else
		to_chat(src, span_bolddanger("You have to be recalled to toggle modes!"))


/mob/living/simple_animal/hostile/guardian/healer/verb/Beacon()
	set name = "Place Bluespace Beacon"
	set category = "Guardian"
	set desc = "Mark a floor as your beacon point, allowing you to warp targets to it. Your beacon will not work at extreme distances."

	if(beacon_cooldown >= world.time)
		to_chat(src, span_bolddanger("Your power is on cooldown. You must wait five minutes between placing beacons."))
		return

	var/turf/beacon_loc = get_turf(src.loc)
	if(!isfloorturf(beacon_loc))
		return

	if(beacon)
		beacon.disappear()
		beacon = null

	beacon = new(beacon_loc, src)

	to_chat(src, span_bolddanger("Beacon placed! You may now warp targets and objects to it, including your user, via Alt+Click."))

	COOLDOWN_START(src, beacon_cooldown, beacon_cooldown_time)

/obj/structure/receiving_pad
	name = "bluespace receiving pad"
	icon = 'icons/turf/floors.dmi'
	desc = "A receiving zone for bluespace teleportations."
	icon_state = "light_on-8"
	light_range = MINIMUM_USEFUL_LIGHT_RANGE
	density = FALSE
	anchored = TRUE
	plane = FLOOR_PLANE
	layer = ABOVE_OPEN_TURF_LAYER

/obj/structure/receiving_pad/New(loc, mob/living/simple_animal/hostile/guardian/healer/spawning_guardian)
	. = ..()
	if(spawning_guardian?.guardian_color)
		add_atom_colour(spawning_guardian.guardian_color, FIXED_COLOUR_PRIORITY)

/obj/structure/receiving_pad/proc/disappear()
	visible_message(span_notice("[src] vanishes!"))
	qdel(src)

/mob/living/simple_animal/hostile/guardian/healer/UnarmedAttack(atom/attack_target, proximity_flag, list/modifiers)
	if(LAZYACCESS(modifiers, RIGHT_CLICK) && proximity_flag && ismovable(attack_target))
		teleport_to_beacon(attack_target)
		return
	return ..()

/mob/living/simple_animal/hostile/guardian/healer/proc/teleport_to_beacon(atom/movable/teleport_target)
	if(!beacon)
		to_chat(src, span_bolddanger("You need a beacon placed to warp things!"))
		return
	if(teleport_target.anchored)
		to_chat(src, span_bolddanger("Your target is anchored!"))
		return

	var/turf/target_turf = get_turf(teleport_target)
	if(beacon.z != target_turf.z)
		to_chat(src, span_bolddanger("The beacon is too far away to warp to!"))
		return

	to_chat(src, span_bolddanger("You begin to warp [teleport_target]."))
	teleport_target.visible_message(span_danger("[teleport_target] starts to glow faintly!"), \
	span_userdanger("You start to faintly glow, and you feel strangely weightless!"))
	do_attack_animation(teleport_target)

	if(!do_mob(src, teleport_target, teleporting_time)) //now start the channel
		to_chat(src, span_bolddanger("You need to hold still!"))
		return

	new /obj/effect/temp_visual/guardian/phase/out(target_turf)
	if(isliving(teleport_target))
		var/mob/living/living_target = teleport_target
		living_target.flash_act()
	teleport_target.visible_message(
		span_danger("[teleport_target] disappears in a flash of light!"), \
		span_userdanger("Your vision is obscured by a flash of light!"), \
	)
	do_teleport(teleport_target, beacon, 0, channel = TELEPORT_CHANNEL_BLUESPACE)
	new /obj/effect/temp_visual/guardian/phase(get_turf(teleport_target))
