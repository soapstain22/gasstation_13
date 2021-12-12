/datum/traitor_objective
	/// The name of the traitor objective
	var/name = "traitor objective"
	/// The description of the traitor objective
	var/description = "this is a traitor objective"
	/// The uplink handler holder to give the progression and telecrystals to.
	var/datum/uplink_handler/handler
	/// The minimum required progression points for this objective
	var/progression_minimum = 0 MINUTES
	/// The maximum progression before this objective cannot appear anymore
	var/progression_maximum = INFINITY
	/// The progression that is rewarded from completing this traitor objective. Can either be a list of list(min, max) or a direct value
	var/progression_reward = 0 MINUTES
	/// The telecrystals that are rewarded from completing this traitor objective. Can either be a list of list(min,max) or a direct value
	var/telecrystal_reward = 0
	/// The weight of this objective being picked.
	var/weight = 1
	/// The current state of this objective
	var/objective_state = OBJECTIVE_STATE_INACTIVE

	/// Determines how influential global progression will affect this objective. Set to 0 to disable.
	var/global_progression_influence_intensity = 1
	/// Determines the minimum and maximum progression this objective can be worth as a result of being influenced by global progression
	/// Should only be smaller than or equal to 1
	var/global_progression_limit_coeff = 0.5
	/// The deviance coefficient used to determine the randomness of the progression rewards.
	var/progression_cost_coeff_deviance = 0.05
	/// This gets added onto the coeff when calculating the updated progression cost. Used for variability and a slight bit of randomness
	var/progression_cost_coeff = 0
	/// The percentage that this objective has been increased or decreased by as a result of progression. Used by the UI
	var/original_progression = 0
	/// Abstract type that won't be included as a possible objective
	var/abstract_type = /datum/traitor_objective

/// Replaces a word in the name of the proc. Also does it for the description
/datum/traitor_objective/proc/replace_in_name(replace, word)
	name = replacetext(name, replace, word)
	description = replacetext(description, replace, word)

/datum/traitor_objective/New(datum/uplink_handler/handler)
	. = ..()
	src.handler = handler
	if(islist(telecrystal_reward))
		telecrystal_reward = rand(telecrystal_reward[1], telecrystal_reward[2])

	if(islist(progression_reward))
		progression_reward = rand(progression_reward[1], progression_reward[2])
	progression_cost_coeff = (rand()*2 - 1) * progression_cost_coeff_deviance

/// Updates the progression cost, scaling it depending on their current progression compared against the global progression
/datum/traitor_objective/proc/update_progression_cost()
	progression_reward = original_progression
	if(global_progression_influence_intensity <= 0)
		return
	var/minimum_progression = progression_reward * global_progression_limit_coeff
	var/maximum_progression = global_progression_limit_coeff != 0? progression_reward / global_progression_limit_coeff : INFINITY
	var/deviance = (SStraitor.current_global_progression - handler.progression_points) / SStraitor.progression_scaling_deviance
	var/coeff = global_progression_influence_intensity * deviance
	// This has less of an effect as the coeff gets nearer to 1. Is linear
	coeff += progression_cost_coeff * (1 - coeff)

	progression_reward = clamp(
		progression_reward + progression_reward * coeff,
		minimum_progression,
		maximum_progression
	)

/datum/traitor_objective/Destroy(force, ...)
	handler = null
	return ..()

/// Called when the objective should be generated. Should return if the objective has been successfully generated.
/// If false is returned, the objective will be removed as a potential objective for the traitor it is being generated for.
/// This is only temporary, it will run the proc again when objectives are generated for the traitor again.
/datum/traitor_objective/proc/generate_objective(datum/mind/generating_for, list/possible_duplicates)
	return FALSE

/// Used to clean up signals and stop listening to states.
/datum/traitor_objective/proc/ungenerate_objective()
	return

/// Used to handle cleaning up the objective.
/datum/traitor_objective/proc/handle_cleanup()
	ungenerate_objective()
	if(objective_state == OBJECTIVE_STATE_INACTIVE)
		handler.complete_objective(src) // Remove this objective immediately, no reason to keep it around. It isn't even active

/// Used to fail objectives. Players can clear completed objectives in the UI
/datum/traitor_objective/proc/fail_objective()
	SEND_SIGNAL(src, COMSIG_TRAITOR_OBJECTIVE_FAILED)
	handle_cleanup()
	objective_state = OBJECTIVE_STATE_FAILED
	handler.on_update() // Trigger an update to the UI

/// Used to succeed objectives. Allows the player to cash it out in the UI.
/datum/traitor_objective/proc/succeed_objective()
	SEND_SIGNAL(src, COMSIG_TRAITOR_OBJECTIVE_COMPLETED)
	handle_cleanup()
	objective_state = OBJECTIVE_STATE_COMPLETED
	handler.on_update() // Trigger an update to the UI

/// Called by player input, do not call directly. Validates whether the objective is finished and pays out the handler if it is.
/datum/traitor_objective/proc/finish_objective()
	switch(objective_state)
		if(OBJECTIVE_STATE_FAILED)
			return TRUE
		if(OBJECTIVE_STATE_COMPLETED)
			completion_payout()
			return TRUE
	return FALSE

/// Called when rewards should be given to the user.
/datum/traitor_objective/proc/completion_payout()
	handler.progression_points += progression_reward
	handler.telecrystals += telecrystal_reward

/// Determines whether this objective is a duplicate. objective_to_compare is always of the type it is being called on.
/datum/traitor_objective/proc/is_duplicate(datum/traitor_objective/objective_to_compare)
	return TRUE

/// Used for sending data to the uplink UI
/datum/traitor_objective/proc/uplink_ui_data(mob/user)
	return list(
		"name" = name,
		"description" = description,
		"progression_minimum" = progression_minimum,
		"progression_reward" = progression_reward,
		"telecrystal_reward" = telecrystal_reward,
		"ui_buttons" = generate_ui_buttons(user),
		"objective_state" = objective_state,
		"original_progression" = original_progression,
	)

/// Used for generating the UI buttons for the UI. Use ui_perform_action to respond to clicks.
/datum/traitor_objective/proc/generate_ui_buttons(mob/user)
	return

/datum/traitor_objective/proc/add_ui_button(name, tooltip, icon, action)
	return list(list(
		"name" = name,
		"tooltip" = tooltip,
		"icon" = icon,
		"action" = action,
	))

/// Return TRUE to trigger a UI update
/datum/traitor_objective/proc/ui_perform_action(mob/user, action)
	return TRUE
