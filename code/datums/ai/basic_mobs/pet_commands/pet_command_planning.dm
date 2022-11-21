/**
 * # Pet Planning
 * Perform behaviour based on what pet commands you have received
 */
/datum/ai_planning_subtree/pet_planning
	/// Key for some kind of mob ability to use
	var/pet_ability_key

/datum/ai_planning_subtree/pet_planning/SelectBehaviors(datum/ai_controller/controller, delta_time)
	var/active_command = controller.blackboard[BB_ACTIVE_PET_COMMAND]
	if (!active_command || active_command == PET_COMMAND_NONE)
		return // Do something else
	if (active_command == PET_COMMAND_IDLE)
		return SUBTREE_RETURN_FINISH_PLANNING // Don't do anything else
	return follow_latest_command(controller, delta_time, active_command)

/// Proc mostly exists so if you extend this you don't need to call the first two checks every time
/datum/ai_planning_subtree/pet_planning/proc/follow_latest_command(datum/ai_controller/controller, delta_time, active_command)
	// We use this in a bunch of commands so we might as well do it here
	var/datum/weakref/weak_target = controller.blackboard[BB_CURRENT_PET_TARGET]
	var/atom/target = weak_target?.resolve()
	switch(active_command)
		if (PET_COMMAND_ATTACK)
			return attack_target(controller, delta_time, target)
		if (PET_COMMAND_USE_ABILITY)
			return use_pet_ability(controller, delta_time, target)
		if (PET_COMMAND_FOLLOW)
			if (QDELETED(target))
				return
			controller.queue_behavior(/datum/ai_behavior/pet_follow_friend, BB_CURRENT_PET_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING

/// Override to use a different attack behaviour or send different keys
/datum/ai_planning_subtree/pet_planning/proc/attack_target(datum/ai_controller/controller, delta_time, atom/target)
	if (QDELETED(target))
		return
	controller.queue_behavior(/datum/ai_behavior/basic_melee_attack, BB_CURRENT_PET_TARGET, BB_TARGETTING_DATUM)
	return SUBTREE_RETURN_FINISH_PLANNING

/// Override to use a different ability behaviour or send different keys
/datum/ai_planning_subtree/pet_planning/proc/use_pet_ability(datum/ai_controller/controller, delta_time, atom/target)
	if (!pet_ability_key)
		return
	if (QDELETED(target))
		return
	var/datum/action/cooldown/using_action = controller.blackboard[pet_ability_key]
	if (QDELETED(using_action))
		return
	if (!using_action.IsAvailable())
		return
	controller.queue_behavior(/datum/ai_behavior/pet_use_ability, pet_ability_key, BB_CURRENT_PET_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING
