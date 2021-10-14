
/datum/ai_behavior/item_move_close_and_attack/cursed
	attack_sound = 'sound/items/haunted/ghostitemattack.ogg'
	max_attempts = 4

/datum/ai_behavior/item_move_close_and_attack/cursed/reset_blackboard(datum/ai_controller/controller, succeeded, target_key, throw_count_key)
	var/atom/throw_target = controller.blackboard[target_key]
	//dropping our target from the blackboard if they are no longer a valid target after the attack behavior
	if(get_dist(throw_target, controller.pawn) > CURSED_VIEW_RANGE)
		controller.blackboard[target_key] = null
