/obj/item/organ/brain
	name = "brain"
	desc = "A piece of juicy meat found in a person's head."
	icon_state = "brain"
	throw_speed = 3
	throw_range = 5
	layer = ABOVE_MOB_LAYER
	zone = "head"
	slot = ORGAN_SLOT_BRAIN
	vital = TRUE
	attack_verb = list("attacked", "slapped", "whacked")
	var/mob/living/brain/brainmob = null
	var/damaged_brain = FALSE //whether the brain organ is damaged.
	var/decoy_override = FALSE	//I apologize to the security players, and myself, who abused this, but this is going to go.

	var/list/datum/brain_trauma/traumas = list()

/obj/item/organ/brain/changeling_brain
	vital = FALSE
	decoy_override = TRUE

/obj/item/organ/brain/Insert(mob/living/carbon/C, special = 0,no_id_transfer = FALSE)
	..()

	name = "brain"

	if(C.mind && C.mind.has_antag_datum(/datum/antagonist/changeling) && !no_id_transfer)	//congrats, you're trapped in a body you don't control
		if(brainmob && !(C.stat == DEAD || (C.status_flags & FAKEDEATH)))
			to_chat(brainmob, "<span class = danger>You can't feel your body! You're still just a brain!</span>")
		loc = C
		C.update_hair()
		return

	if(brainmob)
		if(C.key)
			C.ghostize()

		if(brainmob.mind)
			brainmob.mind.transfer_to(C)
		else
			C.key = brainmob.key

		QDEL_NULL(brainmob)

	for(var/X in traumas)
		var/datum/brain_trauma/BT = X
		BT.owner = owner
		BT.on_gain()

	//Update the body's icon so it doesnt appear debrained anymore
	C.update_hair()

/obj/item/organ/brain/Remove(mob/living/carbon/C, special = 0, no_id_transfer = FALSE)
	..()
	for(var/X in traumas)
		var/datum/brain_trauma/BT = X
		BT.on_lose(TRUE)
		BT.owner = null

	if((!gc_destroyed || (owner && !owner.gc_destroyed)) && !no_id_transfer)
		transfer_identity(C)
	C.update_hair()

/obj/item/organ/brain/prepare_eat()
	return // Too important to eat.

/obj/item/organ/brain/proc/transfer_identity(mob/living/L)
	name = "[L.name]'s brain"
	if(brainmob || decoy_override)
		return
	if(!L.mind)
		return
	brainmob = new(src)
	brainmob.name = L.real_name
	brainmob.real_name = L.real_name
	brainmob.timeofhostdeath = L.timeofdeath
	if(L.has_dna())
		var/mob/living/carbon/C = L
		if(!brainmob.stored_dna)
			brainmob.stored_dna = new /datum/dna/stored(brainmob)
		C.dna.copy_dna(brainmob.stored_dna)
		if(L.disabilities & NOCLONE)
			brainmob.disabilities |= NOCLONE	//This is so you can't just decapitate a husked guy and clone them without needing to get a new body
		var/obj/item/organ/zombie_infection/ZI = L.getorganslot(ORGAN_SLOT_ZOMBIE)
		if(ZI)
			brainmob.set_species(ZI.old_species)	//For if the brain is cloned
	if(L.mind && L.mind.current)
		L.mind.transfer_to(brainmob)
	to_chat(brainmob, "<span class='notice'>You feel slightly disoriented. That's normal when you're just a brain.</span>")

/obj/item/organ/brain/attackby(obj/item/O, mob/user, params)
	user.changeNext_move(CLICK_CD_MELEE)
	if(brainmob)
		O.attack(brainmob, user) //Oh noooeeeee

/obj/item/organ/brain/examine(mob/user)
	..()

	if(brainmob)
		if(brainmob.client)
			if(brainmob.health <= HEALTH_THRESHOLD_DEAD)
				to_chat(user, "It's lifeless and severely damaged.")
			else
				to_chat(user, "You can feel the small spark of life still left in this one.")
		else
			to_chat(user, "This one seems particularly lifeless. Perhaps it will regain some of its luster later.")
	else
		if(decoy_override)
			to_chat(user, "This one seems particularly lifeless. Perhaps it will regain some of its luster later.")
		else
			to_chat(user, "This one is completely devoid of life.")

/obj/item/organ/brain/attack(mob/living/carbon/C, mob/user)
	if(!istype(C))
		return ..()

	add_fingerprint(user)

	if(user.zone_selected != "head")
		return ..()

	if((C.head && (C.head.flags_cover & HEADCOVERSEYES)) || (C.wear_mask && (C.wear_mask.flags_cover & MASKCOVERSEYES)) || (C.glasses && (C.glasses.flags_1 & GLASSESCOVERSEYES)))
		to_chat(user, "<span class='warning'>You're going to need to remove their head cover first!</span>")
		return

//since these people will be dead M != usr

	if(!C.getorgan(/obj/item/organ/brain))
		if(!C.get_bodypart("head") || !C.temporarilyRemoveItemFromInventory(src))
			return
		var/msg = "[C] has [src] inserted into [C.p_their()] head by [user]."
		if(C == user)
			msg = "[user] inserts [src] into [user.p_their()] head!"

		C.visible_message("<span class='danger'>[msg]</span>",
						"<span class='userdanger'>[msg]</span>")

		if(C != user)
			to_chat(C, "<span class='notice'>[user] inserts [src] into your head.</span>")
			to_chat(user, "<span class='notice'>You insert [src] into [C]'s head.</span>")
		else
			to_chat(user, "<span class='notice'>You insert [src] into your head.</span>"	)

		Insert(C)
	else
		..()

/obj/item/organ/brain/proc/get_brain_damage()
	var/brain_damage_threshold = max_integrity * BRAIN_DAMAGE_INTEGRITY_MULTIPLIER
	var/offset_integrity = obj_integrity - (max_integrity - brain_damage_threshold)
	. = (1 - (offset_integrity / brain_damage_threshold)) * BRAIN_DAMAGE_DEATH

/obj/item/organ/brain/proc/adjust_brain_damage(amount, maximum)
	var/adjusted_amount
	if(amount >= 0 && maximum)
		var/brainloss = get_brain_damage()
		var/new_brainloss = Clamp(brainloss + amount, 0, maximum)
		if(brainloss > new_brainloss) //brainloss is over the cap already
			return 0
		adjusted_amount = new_brainloss - brainloss
	else
		adjusted_amount = amount

	adjusted_amount *= BRAIN_DAMAGE_INTEGRITY_MULTIPLIER
	if(adjusted_amount)
		if(adjusted_amount >= 0.1)
			take_damage(adjusted_amount)
		else if(adjusted_amount <= -0.1)
			obj_integrity = min(max_integrity, obj_integrity-adjusted_amount)
	. = adjusted_amount

/obj/item/organ/brain/Destroy() //copypasted from MMIs.
	if(brainmob)
		qdel(brainmob)
		brainmob = null
	return ..()

/obj/item/organ/brain/alien
	name = "alien brain"
	desc = "We barely understand the brains of terrestial animals. Who knows what we may find in the brain of such an advanced species?"
	icon_state = "brain-x"


////////////////////////////////////TRAUMAS////////////////////////////////////////

/obj/item/organ/brain/proc/has_trauma_type(brain_trauma_type, consider_permanent = FALSE)
	for(var/X in traumas)
		var/datum/brain_trauma/BT = X
		if(istype(BT, brain_trauma_type) && (consider_permanent || !BT.permanent))
			return BT


//Add a specific trauma
/obj/item/organ/brain/proc/gain_trauma(datum/brain_trauma/trauma, permanent = FALSE, list/arguments)
	var/trauma_type
	if(ispath(trauma))
		trauma_type = trauma
		traumas += new trauma_type(arglist(list(src, permanent) + arguments))
	else
		traumas += trauma
		trauma.permanent = permanent

//Add a random trauma of a certain subtype
/obj/item/organ/brain/proc/gain_trauma_type(brain_trauma_type = /datum/brain_trauma, permanent = FALSE)
	var/list/datum/brain_trauma/possible_traumas = list()
	for(var/T in subtypesof(brain_trauma_type))
		var/datum/brain_trauma/BT = T
		if(initial(BT.can_gain))
			possible_traumas += BT

	var/trauma_type = pick(possible_traumas)
	traumas += new trauma_type(src, permanent)

//Cure a random trauma of a certain subtype
/obj/item/organ/brain/proc/cure_trauma_type(brain_trauma_type, cure_permanent = FALSE)
	var/datum/brain_trauma/trauma = has_trauma_type(brain_trauma_type)
	if(trauma && (cure_permanent || !trauma.permanent))
		qdel(trauma)

/obj/item/organ/brain/proc/cure_all_traumas(cure_permanent = FALSE)
	for(var/X in traumas)
		var/datum/brain_trauma/trauma = X
		if(cure_permanent || !trauma.permanent)
			qdel(trauma)
