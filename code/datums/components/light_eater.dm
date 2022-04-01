/**
 * Makes anything it attaches to capable of removing something's ability to produce light until it is destroyed
 *
 * The permanent version of this is [/datum/element/light_eater]
 */
/datum/component/light_eater
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS
	/// Tracks things this light eater has eaten
	var/list/eaten_lights

/datum/component/light_eater/Initialize(list/_eaten)
	if(!isatom(parent) && !istype(parent, /datum/reagent))
		return COMPONENT_INCOMPATIBLE

	. = ..()
	if(!LAZYLEN(_eaten))
		return

	LAZYINITLIST(eaten_lights)
	var/list/cached_eaten_lights = eaten_lights
	for(var/morsel in _eaten)
		LAZYSET(cached_eaten_lights, morsel, TRUE)
		register_signal(morsel, COMSIG_PARENT_QDELETING, .proc/deref_eaten_light)

/datum/component/light_eater/Destroy(force, silent)
	for(var/light in eaten_lights)
		var/atom/eaten_light = light
		eaten_light.remove_element(/datum/element/light_eaten)
		unregister_signal(eaten_light, COMSIG_PARENT_QDELETING)
	eaten_lights = null
	return ..()

/datum/component/light_eater/register_with_parent()
	. = ..()
	register_signal(parent, COMSIG_LIGHT_EATER_DEVOUR, .proc/on_devour)
	parent.add_element(/datum/element/light_eater)

/datum/component/light_eater/unregister_from_parent()
	. = ..()
	parent.remove_element(/datum/element/light_eater)
	unregister_signal(parent, COMSIG_LIGHT_EATER_DEVOUR)

/datum/component/light_eater/inherit_component(datum/component/C, i_am_original, list/_eaten)
	. = ..()
	if(!LAZYLEN(_eaten))
		return

	LAZYINITLIST(eaten_lights)
	var/list/cached_eaten_lights = eaten_lights
	for(var/morsel in _eaten)
		register_signal(morsel, COMSIG_PARENT_QDELETING, .proc/deref_eaten_light)
		LAZYSET(cached_eaten_lights, morsel, TRUE)

/// Handles storing references to lights eaten by the light eater.
/datum/component/light_eater/proc/on_devour(datum/source, atom/morsel)
	SIGNAL_HANDLER
	LAZYSET(eaten_lights, morsel, TRUE)
	register_signal(morsel, COMSIG_PARENT_QDELETING, .proc/deref_eaten_light)
	return NONE

/// Handles dereferencing deleted lights.
/datum/component/light_eater/proc/deref_eaten_light(atom/eaten_light, force)
	SIGNAL_HANDLER
	unregister_signal(eaten_light, COMSIG_PARENT_QDELETING)
	LAZYREMOVE(eaten_lights, eaten_light)
	return NONE
