/// Hallucination that plays a fake sound somewhere nearby.
/datum/hallucination/fake_sound
	/// Volume of the fake sound
	var/volume = 50
	/// Whether the fake sound has vary or not
	var/sound_vary = TRUE
	/// A path to a sound, or a list of sounds, that plays when we trigger
	var/sound_type

/datum/hallucination/fake_sound/start()
	var/sound_to_play = islist(sound_type) ? pick(sound_type) : sound_type
	var/turf/source = random_far_turf()
	play_fake_sound(source, sound_to_play)

	qdel(src)
	return TRUE

/// Actually plays the fake sound.
/datum/hallucination/fake_sound/proc/play_fake_sound(turf/source, sound_to_play)
	hallucinator.playsound_local(sound_source, sound_to_play, volume, sound_vary)

/// Used to queue additional, delayed fake sounds via a callback.
/datum/hallucination/fake_sound/proc/queue_fake_sound(turf/source, sound_to_play, volume_override, vary_override, delay)
	if(!delay)
		CRASH("[type] tried a delayed fake sound without a timer.")

	addtimer(CALLBACK(hallucinator, /mob/.proc/playsound_local, source, sound_to_play, volume_override || volume, vary_override || sound_vary), delay)

/datum/hallucination/fake_sound/normal/airlock
	volume = 30
	sound_type = 'sound/machines/airlock.ogg'

/datum/hallucination/fake_sound/normal/airlock_pry
	volume = 100
	sound_type = 'sound/machines/airlock_alien_prying.ogg'

/datum/hallucination/fake_sound/normal/airlock_pry/play_fake_sound(turf/source, sound_to_play)
	. = ..()
	queue_fake_sound(source, 'sound/machines/airlockforced.ogg', 50, TRUE, delay = 5 SECONDS)

/datum/hallucination/fake_sound/normal/console
	volume = 25
	sound_type = 'sound/machines/terminal_prompt.ogg'

/datum/hallucination/fake_sound/normal/boom
	sound_type = list('sound/effects/explosion1.ogg', 'sound/effects/explosion2.ogg')

/datum/hallucination/fake_sound/normal/distant_boom
	sound_type = 'sound/effects/explosionfar.ogg'

/datum/hallucination/fake_sound/normal/glass
	sound_type = list('sound/effects/glassbr1.ogg', 'sound/effects/glassbr2.ogg', 'sound/effects/glassbr3.ogg')

/datum/hallucination/fake_sound/normal/alarm
	volume = 100
	sound_type = 'sound/machines/alarm.ogg'

/datum/hallucination/fake_sound/normal/beepsky
	volume = 35
	sound_type = 'sound/voice/beepsky/freeze.ogg'

/datum/hallucination/fake_sound/normal/mech
	/// The turf the mech started walking from.
	var/turf/mech_source
	/// What dir is the mech walking?
	var/mech_dir = NORTH
	/// How many steps are left in the walk?
	var/steps_left = 0

/datum/hallucination/fake_sound/normal/mech/Destroy()
	mech_source = null
	return ..()

/datum/hallucination/fake_sound/normal/mech/start()
	mech_dir = pick(GLOB.cardinals)
	steps_left = rand(4, 9)
	mech_source = random_far_turf()

	mech_walk()
	return TRUE

/datum/hallucination/fake_sound/normal/mech/proc/mech_walk()
	if(QDELETED(src))
		return

	if(prob(75))
		hallucinator.playsound_local(sound_source, 'sound/mecha/mechstep.ogg', 40, TRUE)
		sound_source = get_step(sound_source, mech_dir)
	else
		hallucinator.playsound_local(sound_source, 'sound/mecha/mechturn.ogg', 40, TRUE)
		mech_dir = pick(GLOB.cardinals)

	if(--steps_left <= 0)
		qdel(src)

	else
		addtimer(CALLBACK(src, .proc/mech_walk), 1 SECONDS)

/datum/hallucination/fake_sound/normal/wall_deconstruction
	sound_type = 'sound/items/welder.ogg'

/datum/hallucination/fake_sound/normal/wall_deconstruction/play_fake_sound(turf/source, sound_to_play)
	. = ..()
	queue_fake_sound(source, 'sound/items/welder2.ogg', delay = 10.5 SECONDS)
	queue_fake_sound(source, 'sound/items/ratchet.ogg', delay = 12 SECONDS)

/datum/hallucination/fake_sound/normal/door_hacking
	sound_type = 'sound/items/screwdriver.ogg'
	volume = 30

/datum/hallucination/fake_sound/normal/door_hacking/play_fake_sound(turf/source, sound_to_play)
	// Make it sound like someone's pulsing a multitool one or multiple times.
	// Screwdriver happens immediately...
	. = ..()

	var/hacking_time = rand(4 SECONDS, 8 SECONDS)
	// Multitool sound.
	queue_fake_sound(source, 'sound/weapons/empty.ogg', delay = 0.8 SECONDS)
	if(hacking_time > 4.5 SECONDS)
		// Another multitool sound if the hacking time is long.
		queue_fake_sound(source, 'sound/weapons/empty.ogg', delay = 3 SECONDS)
		if(prob(50))
			// Bonus multitool sound, rapidly after the last.
			queue_fake_sound(source, 'sound/weapons/empty.ogg', delay = 3.5 SECONDS)

	if(hacking_time > 5.5 SECONDS)
		// A final multitool sound if the hacking time is very long.
		queue_fake_sound(source, 'sound/weapons/empty.ogg', delay = 5 SECONDS)

	// Crowbarring it open.
	queue_fake_sound(source, 'sound/machines/airlockforced.ogg', delay = hacking_time)

/datum/hallucination/fake_sound/weird
	/// if FALSE, we will pass "null" in as the turf source, meaning the sound will just play without direction / etc.
	var/no_source = FALSE

/datum/hallucination/fake_sound/weird/play_fake_sound(turf/source, sound_to_play)
	if(no_source)
		return ..(null, sound_to_play)

	return ..()

/datum/hallucination/fake_sound/weird/phone
	volume = 15
	sound_vary = FALSE
	sound_type = 'sound/weapons/ring.ogg'

/datum/hallucination/fake_sound/weird/phone/play_fake_sound(turf/source, sound_to_play)
	for(var/next_ring in 1 to 3)
		queue_fake_sound(source, sound_to_play, delay = 2.5 SECONDS * next_ring)

	return ..()

/datum/hallucination/fake_sound/weird/hallelujah
	sound_vary = FALSE
	sound_type = 'sound/effects/pray_chaplain.ogg'

/datum/hallucination/fake_sound/weird/hyperspace
	sound_vary = FALSE
	sound_type = 'sound/runtime/hyperspace/hyperspace_begin.ogg'
	no_source = TRUE

/datum/hallucination/fake_sound/weird/highlander
	sound_vary = FALSE
	sound_type = 'sound/misc/highlander.ogg'
	no_source = TRUE

/datum/hallucination/fake_sound/weird/game_over
	sound_vary = FALSE
	sound_type = 'sound/misc/compiler-failure.ogg'

/datum/hallucination/fake_sound/weird/laugher
	sound_type = list(
		'sound/voice/human/womanlaugh.ogg',
		'sound/voice/human/manlaugh1.ogg',
		'sound/voice/human/manlaugh2.ogg',
	)

/datum/hallucination/fake_sound/weird/creepy

/datum/hallucination/fake_sound/weird/creepy/New(mob/living/hallucinator)
	. = ..()
	//These sounds are (mostly) taken from Hidden: Source
	sound_type = GLOB.creepy_ambience

/datum/hallucination/fake_sound/weird/tesloose
	volume = 35
	sound_type = 'sound/magic/lightningbolt.ogg'

/datum/hallucination/fake_sound/weird/tesloose/play_fake_sound(turf/source, sound_to_play)
	. = ..()
	for(var/next_shock in 1 to rand(2, 4))
		queue_fake_sound(source, sound_to_play, volume_override = volume + (15 * next_shock), delay = 3 SECONDS * next_shock)
