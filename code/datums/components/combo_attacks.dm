/datum/component/combo_attacks
	var/max_combo_length
	var/work_on_corpses
	var/work_on_self
	var/examine_message
	var/reset_message
	var/needed_stat
	var/timerid
	var/list/input_list = list()
	var/list/combo_strings = list()
	var/list/combo_list = list()

/datum/component/combo_attacks/Initialize(combos, examine_message, reset_message, max_combo_length, work_on_corpses = FALSE, work_on_self = FALSE)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	combo_list = combos
	for(var/combo in combo_list)
		var/list/combo_specifics = combo_list[combo]
		var/step_string = english_list(combo_specifics[COMBO_STEPS])
		combo_strings += span_notice("<b>[combo]</b> - [step_string]")
	src.examine_message = examine_message
	src.reset_message = reset_message
	src.max_combo_length = max_combo_length
	src.work_on_corpses = work_on_corpses
	src.work_on_self = work_on_self
	return ..()

/datum/component/combo_attacks/RegisterWithParent()
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE_MORE, PROC_REF(on_examine_more))
	RegisterSignal(parent, COMSIG_ITEM_ATTACK_SELF, PROC_REF(on_attack_self))
	RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(on_drop))
	RegisterSignal(parent, COMSIG_ITEM_ATTACK, PROC_REF(on_attack))

/datum/component/combo_attacks/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_PARENT_EXAMINE, COMSIG_PARENT_EXAMINE_MORE, COMSIG_ITEM_ATTACK_SELF, COMSIG_ITEM_DROPPED, COMSIG_ITEM_ATTACK))

/datum/component/combo_attacks/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	if(!examine_message)
		return
	examine_list += examine_message

/datum/component/combo_attacks/proc/on_examine_more(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	examine_list += combo_strings

/datum/component/combo_attacks/proc/on_attack_self(obj/item/source, mob/user)
	SIGNAL_HANDLER

	reset_inputs(user, deltimer = TRUE)

/datum/component/combo_attacks/proc/on_drop(datum/source, mob/dropper)
	SIGNAL_HANDLER

	reset_inputs(user = null, deltimer = TRUE)

/datum/component/combo_attacks/proc/check_input(mob/living/target, mob/user)
	for(var/combo in combo_list)
		var/list/combo_specifics = combo_list[combo]
		if(compare_list(input_list, combo_specifics[COMBO_STEPS]))
			INVOKE_ASYNC(parent, combo_specifics[COMBO_PROC], target, user)
			return TRUE
	return FALSE

/datum/component/combo_attacks/proc/reset_inputs(mob/user, deltimer)
	var/atom/atom_parent = parent
	input_list.Cut()
	if(user)
		atom_parent.balloon_alert(user, reset_message)
	if(deltimer && timerid)
		deltimer(timerid)

/datum/component/combo_attacks/proc/on_attack(datum/source, mob/living/target, mob/user, click_parameters)
	SIGNAL_HANDLER

	if((target.stat == DEAD  && !work_on_corpses) || (target == user && !work_on_self) || HAS_TRAIT(user, TRAIT_PACIFISM))
		return NONE
	var/list/modifiers = params2list(click_parameters)
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		input_list += RIGHT_ATTACK
	if(LAZYACCESS(modifiers, LEFT_CLICK))
		input_list += LEFT_ATTACK
	if(length(input_list) > max_combo_length)
		reset_inputs(user, deltimer = TRUE)
	if(check_input(target, user))
		reset_inputs(user = null, deltimer = TRUE)
		return COMPONENT_SKIP_ATTACK
	timerid = addtimer(CALLBACK(src, PROC_REF(reset_inputs), user, FALSE), 5 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_STOPPABLE)
	return NONE
