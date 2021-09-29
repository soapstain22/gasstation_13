/**
 * # Dispenser
 *
 * Immobile (but not dense) shell that can receive and dispense items.
 */
/obj/structure/dispenser_bot
	name = "dispenser"
	icon = 'icons/obj/wiremod.dmi'
	icon_state = "setup_large"

	density = FALSE
	light_system = MOVABLE_LIGHT
	light_on = FALSE

	var/max_weight = WEIGHT_CLASS_NORMAL
	var/capacity = 20

	var/list/obj/item/stored_items = list()
	var/locked = FALSE

/obj/structure/dispenser_bot/deconstruct(disassembled)
	for(var/obj/item/stored_item as anything in stored_items)
		remove_item(stored_item)
	return ..()

/obj/structure/dispenser_bot/proc/add_item(obj/item/to_add)
	stored_items += to_add
	to_add.forceMove(src)
	RegisterSignal(to_add, COMSIG_MOVABLE_MOVED, .proc/handle_stored_item_moved)
	RegisterSignal(to_add, COMSIG_PARENT_QDELETING, .proc/handle_stored_item_deleted)
	SEND_SIGNAL(src, COMSIG_DISPENSERBOT_ADD_ITEM, to_add)

/obj/structure/dispenser_bot/proc/handle_stored_item_moved(obj/item/moving_item, atom/location)
	SIGNAL_HANDLER
	if(location != src)
		remove_item(moving_item)

/obj/structure/dispenser_bot/proc/handle_stored_item_deleted(obj/item/deleting_item)
	SIGNAL_HANDLER
	remove_item(deleting_item)

/obj/structure/dispenser_bot/proc/remove_item(obj/item/to_remove)
	UnregisterSignal(to_remove, list(
		COMSIG_MOVABLE_MOVED,
		COMSIG_PARENT_QDELETING,
	))
	to_remove.forceMove(drop_location())
	stored_items -= to_remove
	SEND_SIGNAL(src, COMSIG_DISPENSERBOT_REMOVE_ITEM, to_remove)


/obj/structure/dispenser_bot/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/shell, list(
		new /obj/item/circuit_component/dispenser_bot()
	), SHELL_CAPACITY_LARGE)

/obj/structure/dispenser_bot/wrench_act(mob/living/user, obj/item/tool)
	if(locked)
		return
	set_anchored(!anchored)
	tool.play_tool_sound(src)
	balloon_alert(user, "You [anchored?"secure":"unsecure"] [src].")
	return TRUE

/obj/item/circuit_component/dispenser_bot
	display_name = "Dispenser"
	desc = "A dispenser bot that can dispense items "

	/// The list of items
	DEFINE_OUTPUT_PORT(item_list)
	/// The item that was added/removed.
	DEFINE_OUTPUT_PORT(item)
	/// Called when an item is added.
	DEFINE_OUTPUT_PORT(on_item_added)
	/// Called when an item is removed.
	DEFINE_OUTPUT_PORT(on_item_removed)

	ui_buttons = list(
		"plus" = "add_vend_component",
	)

	/// Vendor components attached to this dispenser bot
	var/list/obj/item/circuit_component/vendor_component/vendor_components = list()

	var/max_vendor_components = 20


/obj/item/circuit_component/dispenser_bot/populate_ports()
	item_list = add_output_port("Items", PORT_TYPE_LIST(PORT_TYPE_ATOM))

	item = add_output_port("Item", PORT_TYPE_ATOM)
	on_item_added = add_output_port("On Item Added", PORT_TYPE_SIGNAL)
	on_item_removed = add_output_port("On Item Removed", PORT_TYPE_SIGNAL)

/obj/item/circuit_component/dispenser_bot/register_shell(atom/movable/shell)
	. = ..()
	RegisterSignal(shell, COMSIG_DISPENSERBOT_ADD_ITEM, .proc/on_shell_add_item)
	RegisterSignal(shell, COMSIG_DISPENSERBOT_REMOVE_ITEM, .proc/on_shell_remove_item)

/obj/item/circuit_component/dispenser_bot/unregister_shell(atom/movable/shell)
	UnregisterSignal(shell, list(
		COMSIG_DISPENSERBOT_ADD_ITEM,
		COMSIG_DISPENSERBOT_REMOVE_ITEM,
	))
	return ..()

/obj/item/circuit_component/dispenser_bot/proc/on_shell_add_item(obj/structure/dispenser_bot/source, obj/item/added_item)
	SIGNAL_HANDLER
	item.set_output(added_item)
	item_list.set_output(source.stored_items)
	on_item_added.set_output(COMPONENT_SIGNAL)

/obj/item/circuit_component/dispenser_bot/proc/on_shell_remove_item(obj/structure/dispenser_bot/source, obj/item/added_item)
	SIGNAL_HANDLER
	item.set_output(added_item)
	item_list.set_output(source.stored_items)
	on_item_added.set_output(COMPONENT_SIGNAL)

/obj/item/circuit_component/dispenser_bot/proc/remove_vendor_component(obj/item/circuit_component/vendor_component/vendor_component)
	SIGNAL_HANDLER
	UnregisterSignal(vendor_component, list(
		COMSIG_PARENT_QDELETING,
		COMSIG_CIRCUIT_COMPONENT_REMOVED,
	))
	if(!QDELING(vendor_component))
		qdel(vendor_component)
	vendor_components -= vendor_component

/obj/item/circuit_component/dispenser_bot/ui_perform_action(mob/user, action)
	switch(action)
		if("add_vend_component")
			if(length(vendor_components) >= max_vendor_components)
				balloon_alert(user, "you have hit vendor component limit!")
				return
			var/obj/item/circuit_component/vendor_component/vendor_component = new(parent)
			parent.add_component(parent, user)
			vendor_components += vendor_component
			RegisterSignal(vendor_component, list(
				COMSIG_PARENT_QDELETING,
				COMSIG_CIRCUIT_COMPONENT_REMOVED,
			), .proc/remove_vendor_component)

/obj/item/circuit_component/vendor_component
	display_name = "Vend"
	desc = "A component used to vend out specific objects from the dispenser bot."

	circuit_flags = CIRCUIT_FLAG_OUTPUT_SIGNAL

	var/obj/structure/dispenser_bot/attached_bot

	/// The item this vendor component should vend
	DEFINE_OPTION_PORT(item_to_vend)
	/// Used to vend the item
	DEFINE_INPUT_PORT(vend_item)

/obj/item/circuit_component/vendor_component/register_shell(atom/movable/shell)
	. = ..()
	if(istype(shell, /obj/structure/dispenser_bot))
		attached_bot = shell

/obj/item/circuit_component/vendor_component/unregister_shell(atom/movable/shell)
	attached_bot = null
	return ..()

/obj/item/circuit_component/vendor_component/populate_ports()
	item_to_vend = add_option_port("Item", PORT_TYPE_ATOM)
	vend_item = add_input_port("Vend Item", PORT_TYPE_SIGNAL, .proc/vend_item)

/obj/item/circuit_component/vendor_component/proc/vend_item(datum/port/input/port, list/return_values)
	CIRCUIT_TRIGGER
	if(!attached_bot)
		return

	var/obj/item/vending_item = attached_bot.stored_items[item_to_vend.value]

	if(!vending_item)
		return

	attached_bot.remove_item(vending_item)
