// If an item has the dunkable component, it's able to be dunked into reagent containers like beakers and drinks.
// Dunking the item into a container will transfer reagents from the container to the item.
/datum/component/dunkable
	var/dunk_amount // the amount of reagents that will be transfered from the container to the item on each click

/datum/component/dunkable/Initialize(amount_per_dunk)
	if(isitem(parent))
		dunk_amount = amount_per_dunk
		RegisterSignal(parent, COMSIG_ITEM_AFTERATTACK, .proc/get_dunked)
	else
		return COMPONENT_INCOMPATIBLE

/datum/component/dunkable/proc/get_dunked(datum/source, atom/target, mob/user, proximity_flag)
	if(!proximity_flag) // if the user is not adjacent to the container
		return
	var/obj/item/reagent_containers/container = target // the container we're trying to dunk into
	if(container.reagent_flags & DUNKABLE) // container should be a valid target for dunking
		if(!container.is_drainable())
			to_chat(user, "<span class='warning'>[container] is unable to be dunked in!</span>")
			return
		var/obj/item/I = source // the item that has the dunkable component
		if(container.reagents.trans_to(I, dunk_amount, transfered_by = user))	//if reagents were transfered, show the message
			to_chat(user, "<span class='notice'>You dunk \the [I] into \the [container].</span>")
			return
		if(!container.reagents.total_volume)
			to_chat(user, "<span class='warning'>[container] is empty!</span>")
		else
			to_chat(user, "<span class='warning'>[I] is full!</span>")
