SUBSYSTEM_DEF(movement_loop)
	name = "Movement Loop"
	flags = SS_BACKGROUND|SS_POST_FIRE_TIMING|SS_NO_INIT
	wait = 1 //Fire each tick
	///The list of datums we're processing
	var/list/processing = list()
	///Used to make pausing possible
	var/list/currentrun = list()
	///An assoc list of source to movement datum, used for lookups and removal
	var/list/lookup = list()

/**
 * Used to add something to the subsystem
 *
 * Arguments:
 * source - The atom we want to move
 * chasing - The atom we want to move towards
 * delay - How many seconds to wait between fires, defaults to the lowest value, 0.1
 * home - Should we move towards the object at all times? Or launch towards them, but allow walls and such to take us off track
 * timeout - Time in seconds until the moveloop self expires, defaults to infinity
 * override - Should we replace the current loop if it exists.
 *
 * Returns TRUE if the loop sucessfully started, or FALSE if it failed
**/
/datum/controller/subsystem/movement_loop/proc/start_looping(source, chasing, delay, home, timeout, override = FALSE)
	var/datum/move_loop/old = lookup[source]
	if(old)
		if(!override)
			return FALSE
		remove_from_loop(source, old) //Kill it

	var/datum/move_loop/loop = new(source, chasing, delay, home, timeout)
	processing += loop
	currentrun += loop
	lookup[source] = loop //Cache the datum so lookups are cheap
	return TRUE

///Helper proc for homing
/datum/controller/subsystem/movement_loop/proc/home_onto(source, chasing, delay, timeout, override)
	start_looping(source, chasing, delay, TRUE, timeout, override)

///Stops an object from being processed, assuming it is being processed
/datum/controller/subsystem/movement_loop/proc/stop_looping(atom/source)
	var/datum/loop = lookup[source]
	if(loop)
		remove_from_loop(source, lookup[source])
		return TRUE
	return FALSE

///Removes a loop from processing based on the source and the loop itself
/datum/controller/subsystem/movement_loop/proc/remove_from_loop(atom/source, datum/move_loop/loop)
	processing -= loop
	currentrun -= loop
	lookup -= source
	loop.kill()

/datum/controller/subsystem/movement_loop/fire(resumed)
	if(!resumed)
		currentrun = processing.Copy()

	var/list/running = currentrun //Cache for... you've heard this before
	while(running.len)
		var/datum/move_loop/loop = running[running.len]
		running.len--
		loop.process(wait * 0.1) //This shouldn't get nulls, if it does, runtime
		if (MC_TICK_CHECK)
			return

/datum/controller/subsystem/movement_loop/stat_entry(msg)
	msg = "P:[length(processing)]"
	return ..()

///Used as a alternative to walk_towards
/datum/move_loop
	var/atom/source
	///The thing we're moving towards, usually a turf
	var/atom/dest
	///The turf we want to move into, used for course correction
	var/turf/moving_towards
	///Lifetime in seconds, defaults to forever
	var/lifetime = INFINITY
	///Should we try and stay on the path, or is deviation alright
	var/home = FALSE
	///Delay between each move in seconds
	var/delay = 0.1
	///We use this to track the delay between movements
	var/timer = 0
	///The last tick we processed
	var/lasttick = 0
	///When this gets larger then 1 or smaller then -1 we move a turf
	var/x_ticker = 0
	var/y_ticker = 0
	///The rate at which we move, between -1 and 1
	var/x_rate = 1
	var/y_rate = 1

/datum/move_loop/New(atom/source, atom/chasing, delay = 0.1, home = FALSE, timeout = INFINITY)
	if(!isatom(chasing) || !isatom(source))
		handle_delete()
		return
	src.source = source
	dest = chasing
	src.delay = delay
	src.home = home
	lifetime = timeout
	update_slope()
	RegisterSignal(source, COMSIG_PARENT_QDELETING, .proc/handle_delete)
	if(!isturf(dest))
		RegisterSignal(dest, COMSIG_PARENT_QDELETING, .proc/handle_no_target) //Don't do this for turfs, because of reasons
	if(home)
		if(ismovable(dest))
			RegisterSignal(dest, COMSIG_MOVABLE_MOVED, .proc/update_slope) //If it can move, update your slope when it does
		RegisterSignal(source, COMSIG_MOVABLE_MOVED, .proc/handle_move)
	return ..()

/datum/move_loop/proc/kill()
	SHOULD_CALL_PARENT(TRUE)
	if(home)
		if(ismovable(dest))
			UnregisterSignal(dest, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
		UnregisterSignal(source, COMSIG_MOVABLE_MOVED)

/datum/move_loop/proc/handle_delete()
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(source, COMSIG_MOVELOOP_END)
	SSmovement_loop.remove_from_loop(source, src)

/datum/move_loop/process(delta_time)
	timer = round(timer + delta_time, 0.1) //Round up due to floating point shit
	if(timer >= lifetime)
		handle_delete()
		return
	if(timer - delay < lasttick)
		return
	if(SEND_SIGNAL(source, COMSIG_MOVELOOP_PROCESS_CHECK) & MOVELOOP_STOP_PROCESSING) //Chance for the object to react
		return

	lasttick = timer

	//Move our tickers forward a step, we're guaranteed at least one step forward because of how the code is written
	x_ticker += x_rate
	y_ticker += y_rate
	var/atom/movable/thing = source
	var/x = thing.x
	var/y = thing.y
	var/z = thing.z

	moving_towards = locate(x + round(x_ticker), y + round(y_ticker), z)
	//The tickers serve as good methods of tracking remainder
	if(abs(x_ticker) >= 1)
		x_ticker -= (x_ticker > 0) ? 1 : -1
	if(abs(y_ticker) >= 1)
		y_ticker -= (y_ticker > 0) ? 1 : -1
	thing.Move(moving_towards, get_dir(thing, moving_towards))

/datum/move_loop/proc/handle_move(source, atom/OldLoc, Dir, Forced = FALSE)
	SIGNAL_HANDLER
	var/atom/thing = source
	if(thing.loc != moving_towards) //If we didn't go where we should have, update slope to account for the deviation
		update_slope()

/datum/move_loop/proc/handle_no_target()
	SIGNAL_HANDLER
	handle_delete()

/**
 * Recalculates the slope between the source and our target, sets our rates to it
 *
 * The math below is reminiscent of something like y = mx + b
 * Except we don't need to care about axis, since we do all our movement in steps of 1
 * Because of that all that matters is we only move one tile at a time
 * So we take the smaller delta, divide it by the larger one, and get smaller step per large step
 * Then we set the large step to 1, and we're done. This way we're guaranteed to never move more then a tile at once
 * And we can have nice lines
**/
/datum/move_loop/proc/update_slope()
	SIGNAL_HANDLER
	var/atom/thing = source
	var/x = thing.x
	var/y = thing.y

	//You'll notice this is rise over run, except we flip the formula upside down depending on the larger number
	//This is so we never move more then once tile at once
	var/delta_y = dest.y - y
	var/delta_x = dest.x - x
	if(abs(delta_x) >= abs(delta_y))
		if(delta_x == 0) //Just go up/down
			x_rate = 0
			y_rate = (delta_y > 0) ? 1 : -1
			return
		x_rate = (delta_x > 0) ? 1 : -1
		y_rate = delta_y / abs(delta_x) //rise over run, you know the deal
	else
		if(delta_y == 0) //Just go right/left
			y_rate = 0
			x_rate = (delta_x > 0) ? 1 : -1
			return
		y_rate = (delta_y > 0) ? 1 : -1
		x_rate = delta_x / abs(delta_y) //Keep the larger step size at 1
