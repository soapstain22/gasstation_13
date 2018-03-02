//////////////////////////////////////////////
//////////     SLIME CROSSBREEDS    //////////
//////////////////////////////////////////////
// A system of combining two extract types. //
// Performed by feeding a slime 20 of an    //
// extract color.                           //
//////////////////////////////////////////////
/*==========================================*\
To add a crossbreed:
	The file name is automatically selected
	by the crossbreeding effect, which uses
	the format slimecross/[modifier]/[color].

	If a crossbreed doesn't exist, don't
	worry. If no file is found at that
	location, it will simple display that
	the crossbreed was too unstable.

	As a result, do not feel the need to
	try to add all of the crossbred
	effects at once, if you're here and
	trying to make a new slime type. Just
	get your slimetype in the codebase and
	get around to the crossbreeds eventually!
\*==========================================*/

/obj/item/slimecross //The base type for crossbred extracts. Mostly here for posterity, and to set base case things.
	name = "crossbred slime extract"
	desc = "An extremely potent slime extract, formed through crossbreeding."
	var/colour = "null"
	force = 0
	w_class = WEIGHT_CLASS_TINY
	throwforce = 0
	throw_speed = 3
	throw_range = 6

/obj/item/slimecross/Initialize()
	..()
	name = colour + " " + name

/obj/item/slimecrossbeaker //To be used as a result for extract reactions that make chemicals.
	name = "result extract"
	desc = "You shouldn't see this."
	var/del_on_empty = TRUE
	container_type = INJECTABLE | DRAWABLE
	var/list/list_reagents

/obj/item/slimecrossbeaker/Initialize()
	..()
	create_reagents(50)
	if(list_reagents)
		for(var/reagent in list_reagents)
			reagents.add_reagent(reagent, list_reagents[reagent])
	if(del_on_empty)
		START_PROCESSING(SSobj,src)

/obj/item/slimecrossbeaker/Destroy()
	STOP_PROCESSING(SSobj,src)
	return ..()

/obj/item/slimecrossbeaker/process()
	if(!reagents.total_volume)
		src.visible_message("<span class='notice'>[src] has been drained completely, and melts away.</span>")
		qdel(src)

/obj/item/slimecrossbeaker/bloodpack //Pack of 50u blood. Deletes on empty.
	name = "blood extract"
	desc = "A sphere of liquid blood, somehow managing to stay together."
	list_reagents = list("blood" = 50)

/obj/item/slimecrossbeaker/autoinjector //As with the above, but automatically injects whomever it is used on with contents.
	container_type = DRAWABLE //Cannot be refilled, since it's basically an autoinjector!
	var/ignore_flags = FALSE
	var/self_use_only = FALSE

/obj/item/slimecrossbeaker/autoinjector/attack(mob/living/M, mob/user)
	if(!reagents.total_volume)
		to_chat(user, "<span class='warning'>[src] is empty!</span>")
		return
	if(!iscarbon(M))
		return
	if(self_use_only && M != user)
		to_chat(user, "<span class='warning'>This can only be used on yourself.</span>")
		return
	if(reagents.total_volume && (ignore_flags || M.can_inject(user, 1)))
		reagents.trans_to(M, reagents.total_volume)
		if(user != M)
			to_chat(M, "<span class='warning'>[user] presses [src] against you!</span>")
			to_chat(user, "<span class='notice'>You press [src] against [M], injecting them.</span>")
		else
			to_chat(user, "<span class='notice'>You press [src] against yourself, and it flattens against you!</span>")
	else
		to_chat(user, "<span class='warning'>There's no place to stick [src]!</span>")

/obj/item/slimecrossbeaker/autoinjector/regenpack
	ignore_flags = TRUE //It is, after all, intended to heal.
	name = "mending solution"
	desc = "A strange glob of sweet-smelling semifluid, which seems to stick to skin rather easily."
	list_reagents = list("regen_jelly" = 20)

/obj/item/slimecrossbeaker/autoinjector/slimejelly //Primarily for slimepeople, but you do you.
	self_use_only = TRUE
	ignore_flags = TRUE
	name = "slime jelly bubble"
	desc = "A sphere of slime jelly. It seems to stick to your skin, but avoids other surfaces."
	list_reagents = list("slimejelly" = 50)

/obj/item/slimecrossbeaker/autoinjector/peaceandlove
	container_type = null //It won't be *that* easy to get your hands on pax.
	name = "peaceful distillation"
	desc = "A light pink gooey sphere. Simply touching it makes you a little dizzy."
	list_reagents = list("synthpax" = 10, "space_drugs" = 15) //Peace, dudes