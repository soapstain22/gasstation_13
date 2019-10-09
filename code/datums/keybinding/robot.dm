/datum/keybinding/robot
	category = CATEGORY_ROBOT
	weight = WEIGHT_ROBOT


/datum/keybinding/robot/moduleone
	key = "1"
	name = "module_one"
	full_name = "Toggle module 1"
	description = "Equips or unequips the first module"

/datum/keybinding/robot/moduleone/down(client/user)
	if(!iscyborg(user.mob))
		return FALSE
	var/mob/living/silicon/robot/R = user
	R.toggle_module(1)
	return TRUE

/datum/keybinding/robot/moduletwo
	key = "2"
	name = "module_two"
	full_name = "Toggle module 2"
	description = "Equips or unequips the second module"

/datum/keybinding/robot/moduletwo/down(client/user)
	if(!iscyborg(user.mob))
		return FALSE
	var/mob/living/silicon/robot/R = user
	R.toggle_module(2)
	return TRUE

/datum/keybinding/robot/modulethree
	key = "3"
	name = "module_three"
	full_name = "Toggle module 3"
	description = "Equips or unequips the third module"

/datum/keybinding/robot/modulethree/down(client/user)
	if(!iscyborg(user.mob))
		return FALSE
	var/mob/living/silicon/robot/R = user
	R.toggle_module(3)
	return TRUE

/datum/keybinding/robot/intent_cycle
	key = "4"
	name = "cycle_intent"
	full_name = "Cycle intent left"
	description = "Cycles the intent left"

/datum/keybinding/robot/intent_cycle/down(client/user)
	if(!iscyborg(user.mob))
		return FALSE
	var/mob/living/silicon/robot/R = user
	R.a_intent_change(INTENT_HOTKEY_LEFT)
	return TRUE
	
/datum/keybinding/robot/unequip_module
	key = "Q"
	name = "unequip_module"
	full_name = "Unequip module"
	description = "Unequips the active module"

/datum/keybinding/robot/unequip_module/down(client/user)
	if(!iscyborg(user.mob))
		return FALSE
	var/mob/living/silicon/robot/R = user
	R.uneq_active()
	return TRUE
