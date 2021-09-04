/proc/circuit_signal_response(name, bitflag)
	SHOULD_BE_PURE(TRUE)
	return list(
		"name" = name,
		"bitflag" = bitflag,
		"is_response" = TRUE
	)

/proc/circuit_signal_param(name, type)
	SHOULD_BE_PURE(TRUE)
	return list(
		"name" = name,
		"type" = type,
		"is_response" = FALSE
	)

GLOBAL_LIST_INIT(integrated_circuit_signal_ids, generate_circuit_signal_list())

/proc/generate_circuit_signal_list()
	var/cancel_attack = circuit_signal_response("Cancel Attack", COMPONENT_CANCEL_ATTACK_CHAIN)
	var/target = circuit_signal_param("Target", PORT_TYPE_ATOM)
	var/user = circuit_signal_param("User", PORT_TYPE_ATOM)
	var/item = circuit_signal_param("Item", PORT_TYPE_ATOM)
	var/entity = circuit_signal_param("Entity", PORT_TYPE_ATOM)

	return list(
		COMSIG_PARENT_QDELETING = list(),
		COMSIG_PARENT_ATTACKBY = list(circuit_signal_response("Cancel Attack", COMPONENT_NO_AFTERATTACK), item, user),
		COMSIG_PARENT_ATTACKBY_SECONDARY = list(circuit_signal_response("Cancel Attack", COMPONENT_NO_AFTERATTACK), item, user),
		COMSIG_PARENT_EXAMINE = list(user),

		COMSIG_ATOM_ATTACK_HAND = list(cancel_attack, user),
		COMSIG_ATOM_ATTACK_GHOST = list(cancel_attack, user),
		COMSIG_ATOM_BUMPED = list(entity),
		COMSIG_ATOM_HITBY = list(entity),

		COMSIG_ITEM_ATTACK = list(cancel_attack, target, user),
		COMSIG_ITEM_PRE_ATTACK = list(cancel_attack, target, user),
		COMSIG_ITEM_AFTERATTACK = list(cancel_attack, target, user),
		COMSIG_ITEM_ATTACK_SECONDARY = list(circuit_signal_response("Cancel Attack", COMPONENT_SECONDARY_CANCEL_ATTACK_CHAIN), target, user),
		COMSIG_ITEM_ATTACK_SELF = list(cancel_attack, user),
		COMSIG_ITEM_ATTACK_SELF_SECONDARY = list(cancel_attack, user),
	)

/obj/item/circuit_component/signal_handler/ui_state(mob/user)
	return GLOB.admin_state

/obj/item/circuit_component/signal_handler/ui_static_data(mob/user)
	. = list()
	.["global_port_types"] = GLOB.wiremod_fundamental_types


/obj/item/circuit_component/signal_handler/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CircuitSignalHandler", name)
		ui.open()
		ui.set_autoupdate(FALSE)

/obj/item/circuit_component/signal_handler/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	var/signal_id = params["signal_id"]

	if(!istext(signal_id))
		return

	var/list/responses = params["responses"]
	var/list/parameters = params["parameters"]
	if(!islist(responses) || !islist(parameters))
		return

	var/list/sanitized_data = list()

	for(var/list/data as anything in responses)
		sanitized_data += list(circuit_signal_response(data["name"], text2num(data["bitflag"])))
	for(var/list/data as anything in parameters)
		sanitized_data += list(circuit_signal_param(data["name"], data["datatype"]))

	GLOB.integrated_circuit_signal_ids[signal_id] = sanitized_data
	balloon_alert(usr, "successfully added [signal_id]")
