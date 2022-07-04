/**
 * Component that can be used to clean things.
 * Takes care of duration, cleaning skill and special cleaning interactions.
 * A callback can be set by the datum holding the cleaner to add custom functionality.
 * Soap uses a callback to decrease the amount of uses it has left after cleaning for example.
 */
/datum/component/cleaner
	/// The time it takes to clean something, without reductions from the cleaning skill modifier.
	var/base_cleaning_duration
	/// Offsets the cleaning duration modifier that you get from your cleaning skill, the duration won't be modified to be more than the base duration.
	var/skill_duration_modifier_offset
	/// Determines what this cleaner can wash off, [the available options are found here](code/__DEFINES/cleaning.html).
	var/cleaning_strength
	/// Multiplies the cleaning skill experience gained from cleaning.
	var/experience_gain_modifier
	/// Gets called when something is successfully cleaned.
	var/datum/callback/on_cleaned_callback
	/// Gets invoked asynchronously by the signal handler
	var/datum/callback/cleaning_proc

/datum/component/cleaner/Initialize(base_cleaning_duration, skill_duration_modifier_offset = 0, cleaning_strength = CLEAN_SCRUB, experience_gain_modifier = 1, datum/callback/on_cleaned_callback = null)
	src.base_cleaning_duration = base_cleaning_duration
	src.skill_duration_modifier_offset = skill_duration_modifier_offset
	src.cleaning_strength = cleaning_strength
	src.experience_gain_modifier = experience_gain_modifier
	src.on_cleaned_callback = on_cleaned_callback
	cleaning_proc = CALLBACK(src, .proc/clean)

/datum/component/cleaner/Destroy(force, silent)
	if(on_cleaned_callback)
		QDEL_NULL(on_cleaned_callback)
	QDEL_NULL(cleaning_proc)
	return ..()

/datum/component/cleaner/RegisterWithParent()
	RegisterSignal(parent, COMSIG_START_CLEANING, .proc/on_start_cleaning)

/datum/component/cleaner/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_START_CLEANING)

/**
 * Handles the COMSIG_START_CLEANING signal by calling the clean proc.
 *
 * Arguments
 * * source the datum that sent the signal to start cleaning
 * * target the thing being cleaned
 * * user the person doing the cleaning
 */
/datum/component/cleaner/proc/on_start_cleaning(datum/source, atom/target as obj|turf|area, mob/living/user)
	SIGNAL_HANDLER
	cleaning_proc.InvokeAsync(source, target, user) //signal handlers can't have do_afters inside of them

/**
 * Cleans something using this cleaner.
 * The cleaning duration is modified by the cleaning skill of the user.
 * Successfully cleaning gives cleaning experience to the user and invokes the on_cleaned_callback.
 *
 * Arguments
 * * source the datum that sent the signal to start cleaning
 * * target the thing being cleaned
 * * user the person doing the cleaning
 */
/datum/component/cleaner/proc/clean(datum/source, atom/target as obj|turf|area, mob/living/user)
	//set the cleaning duration
	var/cleaning_duration = base_cleaning_duration
	if(user.mind) //higher cleaning skill can make the duration shorter
		//offsets the multiplier you get from cleaning skill, but doesn't allow the duration to be longer than the base duration
		cleaning_duration = cleaning_duration * min(user.mind.get_skill_modifier(/datum/skill/cleaning, SKILL_SPEED_MODIFIER)+skill_duration_modifier_offset,1)

	//do the cleaning
	user.visible_message(span_notice("[user] starts to clean [target]!"), span_notice("You start to clean [target]..."))
	if(do_after(user, cleaning_duration, target = target))
		user.visible_message(span_notice("[user] finishes cleaning [target]!"), span_notice("You finish cleaning [target]."))
		if(isturf(target)) //cleaning the floor and every bit of filth on top of it
			for(var/obj/effect/decal/cleanable/cleanable_decal in target) //it's important to do this before you wash all of the cleanables off
				user.mind?.adjust_experience(/datum/skill/cleaning, round((cleanable_decal.beauty / CLEAN_SKILL_BEAUTY_ADJUSTMENT) * experience_gain_modifier))
		else if(istype(target, /obj/structure/window)) //window cleaning
			target.set_opacity(initial(target.opacity))
			target.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
			var/obj/structure/window/window = target
			if(window.bloodied)
				for(var/obj/effect/decal/cleanable/blood/iter_blood in window)
					window.vis_contents -= iter_blood
					qdel(iter_blood)
					window.bloodied = FALSE
		user.mind?.adjust_experience(/datum/skill/cleaning, round(CLEAN_SKILL_GENERIC_WASH_XP * experience_gain_modifier))
		target.wash(cleaning_strength)
		on_cleaned_callback?.Invoke(source, target, user)
