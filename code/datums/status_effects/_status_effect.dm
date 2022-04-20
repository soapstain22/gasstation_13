/// Status effects are used to apply temporary or permanent effects to mobs.
/// This file contains their code, plus code for applying and removing them.
/datum/status_effect
	/// The ID of the effect. ID is used in adding and removing effects to check for duplicates, among other things.
	var/id = "effect"
	/// How long the status effect lasts in deciseconds.
	// -1 = infinite.
	var/duration = -1
	/// How many deciseconds between "ticks", approximately.
	/// Leave at 10 for once every second.
	/// -1 = will stop processing (if duration is also unlimited).
	var/tick_interval = 10
	/// The mob affected by the status effect.
	var/mob/living/owner
	/// How many of the effect can be on one mob, and/or what happens when you try to add a duplicate.
	var/status_type = STATUS_EFFECT_UNIQUE
	/// If TRUE, we call on_remove() when owner is deleted. Otherwise, we call be_replaced().
	var/on_remove_on_mob_delete = FALSE
	/// If defined, this text will appear when the mob is examined
	/// To use he, she etc. use "SUBJECTPRONOUN" and replace it in the examines themselves
	var/examine_text
	/// The typepath to the alert thrown by the status effect when created.
	/// Status effect "name"s and "description"s are shown here
	var/alert_type = /atom/movable/screen/alert/status_effect
	/// The alert itself, created in on_creation() if alert_type is specified
	var/atom/movable/screen/alert/status_effect/linked_alert
	/// Processing speed - used to define if the status effect should be using SSfastprocess or SSprocessing
	var/processing_speed = STATUS_EFFECT_FAST_PROCESS

/datum/status_effect/New(list/arguments)
	on_creation(arglist(arguments))

/// Called from New() with any supplied status effect arguments.
/// Not guaranteed to exist by the end.
/// Returning FALSE from on_apply will stop on_creation and self-delete the effect.
/datum/status_effect/proc/on_creation(mob/living/new_owner, ...)
	if(new_owner)
		owner = new_owner
	if(QDELETED(owner) || !on_apply())
		qdel(src)
		return
	if(owner)
		LAZYADD(owner.status_effects, src)

	if(duration != -1)
		duration = world.time + duration
	tick_interval = world.time + tick_interval

	if(alert_type)
		var/atom/movable/screen/alert/status_effect/new_alert = owner.throw_alert(id, alert_type)
		new_alert.attached_effect = src //so the alert can reference us, if it needs to
		linked_alert = new_alert //so we can reference the alert, if we need to

	if(duration > 0 || initial(tick_interval) > 0) //don't process if we don't care
		switch(processing_speed)
			if(STATUS_EFFECT_FAST_PROCESS)
				START_PROCESSING(SSfastprocess, src)
			if (STATUS_EFFECT_NORMAL_PROCESS)
				START_PROCESSING(SSprocessing, src)

	return TRUE

/datum/status_effect/Destroy()
	switch(processing_speed)
		if(STATUS_EFFECT_FAST_PROCESS)
			STOP_PROCESSING(SSfastprocess, src)
		if (STATUS_EFFECT_NORMAL_PROCESS)
			STOP_PROCESSING(SSprocessing, src)
	if(owner)
		linked_alert = null
		owner.clear_alert(id)
		LAZYREMOVE(owner.status_effects, src)
		on_remove()
		owner = null
	return ..()

/datum/status_effect/process()
	if(!owner)
		qdel(src)
		return
	if(tick_interval < world.time)
		tick()
		tick_interval = world.time + initial(tick_interval)
	if(duration != -1 && duration < world.time)
		qdel(src)

/// Called whenever the effect is applied in on_created
/// Returning FALSE will cause it to delete itself during creation instead.
/datum/status_effect/proc/on_apply()
	return TRUE

/// Called every tick from process().
/datum/status_effect/proc/tick()
	return

/// Called whenever the buff expires or is removed (qdeleted)
/// Note that at the point this is called, it is out of the
/// owner's status_effects list, but owner is not yet null
/datum/status_effect/proc/on_remove()
	return

/// Called instead of on_remove when a status effect
/// of type STATUS_EFFECT_REPLACE is replaced by itself
/// or when a status effect with on_remove_on_mob_delete
/// set to FALSE has its mob deleted
/datum/status_effect/proc/be_replaced()
	owner.clear_alert(id)
	LAZYREMOVE(owner.status_effects, src)
	owner = null
	qdel(src)

/// Called before being fully removed (before on_remove)
/// Returning FALSE will cancel removal
/datum/status_effect/proc/before_remove()
	return TRUE

/// Called when a status effect of type type STATUS_EFFECT_REFRESH
/// has its duration refreshed in apply_status_effect - is passed New() args
/datum/status_effect/proc/refresh(effect, ...)
	var/original_duration = initial(duration)
	if(original_duration == -1)
		return
	duration = world.time + original_duration

/// Adds nextmove modifier multiplicatively while applied
/datum/status_effect/proc/nextmove_modifier()
	return 1

/// Adds nextmove adjustment additiviely while applied
/datum/status_effect/proc/nextmove_adjust()
	return 0

/// Alert base type for status effect alerts
/atom/movable/screen/alert/status_effect
	name = "Curse of Mundanity"
	desc = "You don't feel any different..."
	/// The status effect we're linked to
	var/datum/status_effect/attached_effect

/atom/movable/screen/alert/status_effect/Destroy()
	attached_effect = null //Don't keep a ref now
	return ..()
