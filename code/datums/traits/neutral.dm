//traits with no real impact that can be taken freely
//MAKE SURE THESE DO NOT MAJORLY IMPACT GAMEPLAY. those should be positive or negative traits.

/datum/quirk/no_taste
	name = "Ageusia"
	desc = "You can't taste anything! Toxic food will still poison you."
	value = 0
	mob_trait = TRAIT_AGEUSIA
	gain_text = "<span class='notice'>You can't taste anything!</span>"
	lose_text = "<span class='notice'>You can taste again!</span>"
	medical_record_text = "Patient suffers from ageusia and is incapable of tasting food or reagents."

/datum/quirk/foreigner
	name = "Foreigner"
	desc = "You're not from around here. You don't know Galactic Common!"
	value = 0
	gain_text = "<span class='notice'>The words being spoken around you don't make any sense."
	lose_text = "<span class='notice'>You've developed fluency in Galactic Common."
	medical_record_text = "Patient does not speak Galactic Common and may require an interpreter."

/datum/quirk/foreigner/add()
	var/mob/living/carbon/human/H = quirk_holder
	H.add_blocked_language(/datum/language/common)
	if(ishumanbasic(H))
		H.grant_language(/datum/language/uncommon)

/datum/quirk/foreigner/remove()
	var/mob/living/carbon/human/H = quirk_holder
	H.remove_blocked_language(/datum/language/common)
	if(ishumanbasic(H))
		H.remove_language(/datum/language/uncommon)

/datum/quirk/vegetarian
	name = "Vegetarian"
	desc = "You find the idea of eating meat morally and physically repulsive."
	value = 0
	gain_text = "<span class='notice'>You feel repulsion at the idea of eating meat.</span>"
	lose_text = "<span class='notice'>You feel like eating meat isn't that bad.</span>"
	medical_record_text = "Patient reports a vegetarian diet."

/datum/quirk/vegetarian/add()
	var/mob/living/carbon/human/H = quirk_holder
	var/datum/species/species = H.dna.species
	species.liked_food &= ~MEAT
	species.disliked_food |= MEAT

/datum/quirk/vegetarian/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H)
		var/datum/species/species = H.dna.species
		if(initial(species.liked_food) & MEAT)
			species.liked_food |= MEAT
		if(!initial(species.disliked_food) & MEAT)
			species.disliked_food &= ~MEAT

/datum/quirk/snob
	name = "Snob"
	desc = "You care about the finer things, if a room doesn't look nice its just not really worth it, is it?"
	value = 0
	gain_text = "<span class='notice'>You feel like you understand what things should look like.</span>"
	lose_text = "<span class='notice'>Well who cares about deco anyways?</span>"
	medical_record_text = "Patient seems to be rather stuck up."
	mob_trait = TRAIT_SNOB

/datum/quirk/pineapple_liker
	name = "Ananas Affinity"
	desc = "You find yourself greatly enjoying fruits of the ananas genus. You can't seem to ever get enough of their sweet goodness!"
	value = 0
	gain_text = "<span class='notice'>You feel an intense craving for pineapple.</span>"
	lose_text = "<span class='notice'>Your feelings towards pineapples seem to return to a lukewarm state.</span>"
	medical_record_text = "Patient demonstrates a pathological love of pineapple."

/datum/quirk/pineapple_liker/add()
	var/mob/living/carbon/human/H = quirk_holder
	var/datum/species/species = H.dna.species
	species.liked_food |= PINEAPPLE

/datum/quirk/pineapple_liker/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H)
		var/datum/species/species = H.dna.species
		species.liked_food &= ~PINEAPPLE

/datum/quirk/pineapple_hater
	name = "Ananas Aversion"
	desc = "You find yourself greatly detesting fruits of the ananas genus. Serious, how the hell can anyone say these things are good? And what kind of madman would even dare putting it on a pizza!?"
	value = 0
	gain_text = "<span class='notice'>You find yourself pondering what kind of idiot actually enjoys pineapples...</span>"
	lose_text = "<span class='notice'>Your feelings towards pineapples seem to return to a lukewarm state.</span>"
	medical_record_text = "Patient is correct to think that pineapple is disgusting."

/datum/quirk/pineapple_hater/add()
	var/mob/living/carbon/human/H = quirk_holder
	var/datum/species/species = H.dna.species
	species.disliked_food |= PINEAPPLE

/datum/quirk/pineapple_hater/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H)
		var/datum/species/species = H.dna.species
		species.disliked_food &= ~PINEAPPLE

/datum/quirk/deviant_tastes
	name = "Deviant Tastes"
	desc = "You dislike food that most people enjoy, and find delicious what they don't."
	value = 0
	gain_text = "<span class='notice'>You start craving something that tastes strange.</span>"
	lose_text = "<span class='notice'>You feel like eating normal food again.</span>"
	medical_record_text = "Patient demonstrates irregular nutrition preferences."

/datum/quirk/deviant_tastes/add()
	var/mob/living/carbon/human/H = quirk_holder
	var/datum/species/species = H.dna.species
	var/liked = species.liked_food
	species.liked_food = species.disliked_food
	species.disliked_food = liked

/datum/quirk/deviant_tastes/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H)
		var/datum/species/species = H.dna.species
		species.liked_food = initial(species.liked_food)
		species.disliked_food = initial(species.disliked_food)

/datum/quirk/monochromatic
	name = "Monochromacy"
	desc = "You suffer from full colorblindness, and perceive nearly the entire world in blacks and whites."
	value = 0
	medical_record_text = "Patient is afflicted with almost complete color blindness."

/datum/quirk/monochromatic/add()
	quirk_holder.add_client_colour(/datum/client_colour/monochrome)

/datum/quirk/monochromatic/post_add()
	if(quirk_holder.mind.assigned_role == "Detective")
		to_chat(quirk_holder, "<span class='boldannounce'>Mmm. Nothing's ever clear on this station. It's all shades of gray...</span>")
		quirk_holder.playsound_local(quirk_holder, 'sound/ambience/ambidet1.ogg', 50, FALSE)

/datum/quirk/monochromatic/remove()
	if(quirk_holder)
		quirk_holder.remove_client_colour(/datum/client_colour/monochrome)

/datum/quirk/phobia
	name = "Phobia"
	desc = "You are irrationally afraid of something."
	value = 0
	medical_record_text = "Patient has an irrational fear of something."

/datum/quirk/phobia/post_add()
	var/mob/living/carbon/human/H = quirk_holder
	H.gain_trauma(new /datum/brain_trauma/mild/phobia(H.client?.prefs.phobia), TRAUMA_RESILIENCE_ABSOLUTE)

/datum/quirk/phobia/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H)
		H.cure_trauma_type(/datum/brain_trauma/mild/phobia, TRAUMA_RESILIENCE_ABSOLUTE)

/datum/quirk/needswayfinder
	name = "Navigationally Challenged"
	desc = "Lacking familiarity with certain stations, you start with a wayfinding pinpointer where available."
	value = 0
	medical_record_text = "Patient demonstrates a keen ability to get lost."

	var/obj/item/pinpointer/wayfinding/wayfinder
	var/where

/datum/quirk/needswayfinder/on_spawn()
	if(!GLOB.wayfindingbeacons.len)
		return
	var/mob/living/carbon/human/H = quirk_holder

	wayfinder = new /obj/item/pinpointer/wayfinding
	wayfinder.owner = H.real_name
	wayfinder.roundstart = TRUE

	var/list/slots = list(
		"in your left pocket" = ITEM_SLOT_LPOCKET,
		"in your right pocket" = ITEM_SLOT_RPOCKET,
		"in your backpack" = ITEM_SLOT_BACKPACK
	)
	where = H.equip_in_one_of_slots(wayfinder, slots, FALSE) || "at your feet"

/datum/quirk/needswayfinder/post_add()
	if(!GLOB.wayfindingbeacons.len)
		return
	if(where == "in your backpack")
		var/mob/living/carbon/human/H = quirk_holder
		SEND_SIGNAL(H.back, COMSIG_TRY_STORAGE_SHOW, H)

	to_chat(quirk_holder, "<span class='notice'>There is a pinpointer [where], which can help you find your way around. Click in-hand to activate.</span>")

/datum/quirk/bald
	name = "Smooth-Headed"
	desc = "You have no hair and are quite insecure about it! Keep your wig on, or at least your head covered up."
	value = 0
	mob_trait = TRAIT_BALD
	gain_text = "<span class='notice'>Your head is as smooth as can be, it's terrible.</span>"
	lose_text = "<span class='notice'>Your head itches, could it be... growing hair?!</span>"
	medical_record_text = "Patient starkly refused to take off headwear during examination."
	///The user's starting hairstyle
	var/old_hair

/datum/quirk/bald/add()
	var/mob/living/carbon/human/H = quirk_holder
	old_hair = H.hairstyle
	H.hairstyle = "Bald"
	H.update_hair()
	RegisterSignal(H, COMSIG_CARBON_EQUIP_HAT, .proc/equip_hat)
	RegisterSignal(H, COMSIG_CARBON_UNEQUIP_HAT, .proc/unequip_hat)

/datum/quirk/bald/remove()
	var/mob/living/carbon/human/H = quirk_holder
	H.hairstyle = old_hair
	H.update_hair()
	UnregisterSignal(H, list(COMSIG_CARBON_EQUIP_HAT, COMSIG_CARBON_UNEQUIP_HAT))
	SEND_SIGNAL(H, COMSIG_CLEAR_MOOD_EVENT, "bad_hair_day")

/datum/quirk/bald/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	var/obj/item/clothing/head/wig/natural/W = new(get_turf(H))
	if (old_hair == "Bald")
		W.hairstyle = pick(GLOB.hairstyles_list - "Bald")
	else
		W.hairstyle = old_hair
	W.update_icon()
	var/list/slots = list (
		"head" = ITEM_SLOT_HEAD,
		"backpack" = ITEM_SLOT_BACKPACK,
		"hands" = ITEM_SLOT_HANDS,
	)
	H.equip_in_one_of_slots(W, slots , qdel_on_fail = TRUE)

///Checks if the headgear equipped is a wig and sets the mood event accordingly
/datum/quirk/bald/proc/equip_hat(mob/user, obj/item/hat)
	SIGNAL_HANDLER

	if(istype(hat, /obj/item/clothing/head/wig))
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "bad_hair_day", /datum/mood_event/confident_mane) //Our head is covered, but also by a wig so we're happy.
	else
		SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, "bad_hair_day") //Our head is covered

///Applies a bad moodlet for having an uncovered head
/datum/quirk/bald/proc/unequip_hat(mob/user, obj/item/clothing, force, newloc, no_move, invdrop, silent)
	SIGNAL_HANDLER

	SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "bad_hair_day", /datum/mood_event/bald)

/datum/quirk/longtimer
	name = "Longtimer"
	desc = "You've been around for a long time and seen more than your fair share of action, suffering some pretty nasty scars along the way. For whatever reason, you've declined to get them removed or augmented."
	value = 0
	gain_text = "<span class='notice'>Your body has seen better days.</span>"
	lose_text = "<span class='notice'>Your sins may wash away, but those scars are here to stay...</span>"
	medical_record_text = "Patient has withstood significant physical trauma and declined plastic surgery procedures to heal scarring."
	/// the minimum amount of scars we can generate
	var/min_scars = 3
	/// the maximum amount of scars we can generate
	var/max_scars = 7

/datum/quirk/longtimer/on_spawn()
	var/mob/living/carbon/C = quirk_holder
	C.generate_fake_scars(rand(min_scars, max_scars))

/datum/quirk/tongue_tied
	name = "Tongue Tied"
	desc = "Due to a past incident, your ability to communicate has been relegated to your hands."
	value = 0
	medical_record_text = "During physical examination, patient's tongue was found to be uniquely damaged."

//Adds tongue & gloves
/datum/quirk/tongue_tied/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	var/obj/item/organ/tongue/old_tongue = locate() in H.internal_organs
	var/obj/item/organ/tongue/tied/new_tongue = new(get_turf(H))
	var/obj/item/clothing/gloves/radio/gloves = new(get_turf(H))
	old_tongue.Remove(H)
	new_tongue.Insert(H)
	qdel(old_tongue)
	H.put_in_hands(gloves)
	H.equip_to_slot(gloves, ITEM_SLOT_GLOVES)
	H.regenerate_icons()

/datum/quirk/tongue_tied/post_add()
	to_chat(quirk_holder, "<span class='boldannounce'>Because you speak with your hands, having them full hinders your ability to communicate!</span>")

//Short lol
/datum/quirk/short
	name = "Short"
	desc = "Due to either being a child or from some medical defect, you are not as stanced as you'd hope you'd be."
	value = 0
	medical_record_text = "Patient is short."

/datum/quirk/short/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	H.resize = 0.85

/datum/quirk/robotic_talk
	name = "Robotongue"
	desc = "you sound like a kickass robot."
	value = 0
	medical_record_text = "During physical examination, patient's tongue was found to be uniquely damaged."

/datum/quirk/robotic_talk/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	var/obj/item/organ/tongue/old_tongue = locate() in H.internal_organs
	var/obj/item/organ/tongue/robot/new_tongue = new(get_turf(H))
	old_tongue.Remove(H)
	new_tongue.Insert(H)
	qdel(old_tongue)
	H.regenerate_icons()

/datum/quirk/faux
	name = "Faux Mask"
	desc = "For the sake of RP, please do not use this trait. Thank you for understanding."
	value = 0

/datum/quirk/faux/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	var/obj/item/clothing/glasses/fox/glasses = new(get_turf(H))
	H.put_in_hands(glasses)
	H.equip_to_slot(glasses, ITEM_SLOT_EYES)
	H.regenerate_icons() //this is to remove the inhand icon, which persists even if it's not in their hands
	H.AddSpell(new /obj/effect/proc_holder/spell/aimed/fireball(null))
	H.AddSpell(new /obj/effect/proc_holder/spell/targeted/ethereal_jaunt(null))

/datum/quirk/unholy
	name = "Borrowed Time"
	desc = "You feel your heart squeezing onto its last fibres of life."
	value = 0
	mob_trait = TRAIT_UNHOLY

/datum/quirk/unholy/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	H.AddElement(/datum/element/unholy)
