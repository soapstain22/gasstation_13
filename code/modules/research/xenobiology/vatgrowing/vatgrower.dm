///Used to make mobs from microbiological samples. Grow grow grow.
/obj/machinery/plumbing/growing_vat
	name = "growing vat"
	desc = "Tastes just like the chef's soup."
	icon_state = "growing_vat"
	///List of all microbiological samples in this soup.
	var/datum/biological_sample/biological_sample

///Add that sexy demnand component
/obj/machinery/plumbing/growing_vat/Initialize(mapload, bolt)
	. = ..()
	AddComponent(/datum/component/plumbing/simple_demand, bolt)

///When we process, we make use of our reagents to try and feed the samples we have.
/obj/machinery/plumbing/growing_vat/process()
	if(!is_operational() && !biological_sample)
		return
	if(biological_sample)
		biological_sample.HandleGrowth(src)
		if(prob(30))
			audible_message(pick(list("<span class='notice'>[src] grumbles!</span>", "<span class='notice'>[src] makes a splashing noise!</span>", "<span class='notice'>[src] sloshes!</span>")))

///Handles the petri dish depositing into the vat.
/obj/machinery/plumbing/growing_vat/attacked_by(obj/item/I, mob/living/user)
	if(!istype(I, /obj/item/petri_dish))
		return ..()

	var/obj/item/petri_dish/petri = I

	if(!petri.sample)
		return ..()

	if(biological_sample)
		to_chat(user, "<span class='warning'>There is already a sample in the vat!</span>")
		return

	biological_sample = petri.sample
	petri.sample = null
	petri.update_icon()
	to_chat(user, "<span class='warning'>You put the sample in the vat!</span>")
	update_icon()

///Adds text for when there is a sample in the vat
/obj/machinery/plumbing/growing_vat/examine(mob/user)
	. = ..()
	if(biological_sample)
		. += "<span class='notice'>It seems to have a sample in it!</span>"

/obj/machinery/plumbing/growing_vat/plunger_act(obj/item/plunger/P, mob/living/user, reinforced)
	. = ..()
	QDEL_NULL(biological_sample)

///Call update icon when reagents change to update the reagent content icons
/obj/machinery/plumbing/growing_vat/on_reagent_change(changetype)
	update_icon()
	. = ..()

///Adds overlays to show the reagent contents
/obj/machinery/plumbing/growing_vat/update_overlays()
	. = ..()
	if(!reagents.total_volume)
		return
	var/reagentcolor = mix_color_from_reagents(reagents.reagent_list)
	var/mutable_appearance/base_overlay = mutable_appearance(icon, "vat_reagent")
	base_overlay.appearance_flags = RESET_COLOR
	base_overlay.color = reagentcolor
	. += base_overlay
	if(biological_sample && is_operational())
		var/mutable_appearance/bubbles_overlay = mutable_appearance(icon, "vat_bubbles")
		. += bubbles_overlay

