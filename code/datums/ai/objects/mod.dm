/datum/ai_controller/mod
	blackboard = list(
		BB_MOD_TARGET = null,
		BB_MOD_IMPLANT = null,
	)
	max_target_distance = 50
	ai_movement = /datum/ai_movement/jps
	var/obj/item/card/id/advanced/id_card

/datum/ai_controller/mod/TryPossessPawn(atom/new_pawn)
	if(!istype(new_pawn, /obj/item/mod/control))
		return AI_CONTROLLER_INCOMPATIBLE
	var/obj/item/mod/control/mod = new_pawn
	id_card = new /obj/item/card/id/advanced/simple_bot()
	id_card.set_access(mod.req_access)
	return ..() //Run parent at end

/datum/ai_controller/mod/UnpossessPawn(destroy)
	QDEL_NULL(id_card)
	return ..() //Run parent at end

/datum/ai_controller/mod/SelectBehaviors(delta_time)
	current_behaviors = list()
	if(blackboard[BB_MOD_TARGET] && blackboard[BB_MOD_IMPLANT])
		queue_behavior(/datum/ai_behavior/mod_attach)

/datum/ai_controller/mod/get_access()
	return id_card

/datum/ai_behavior/mod_attach
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT|AI_BEHAVIOR_MOVE_AND_PERFORM

/datum/ai_behavior/mod_attach/perform(delta_time, datum/ai_controller/controller)
	. = ..()
	if(!controller.pawn.Adjacent(controller.blackboard[BB_MOD_TARGET]))
		return
	var/obj/item/implant/mod/implant = controller.blackboard[BB_MOD_IMPLANT]
	implant.module.attach(controller.blackboard[BB_MOD_TARGET])
	finish_action(controller, TRUE)

/datum/ai_behavior/mod_attach/finish_action(datum/ai_controller/controller, succeeded)
	. = ..()
	controller.blackboard[BB_MOD_TARGET] = null
	var/obj/item/implant/mod/implant = controller.blackboard[BB_MOD_IMPLANT]
	implant.end_recall(succeeded)
