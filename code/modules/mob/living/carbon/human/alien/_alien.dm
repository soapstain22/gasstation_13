/mob/living/carbon/human/species/alien
	name = "alien"
	icon = 'icons/mob/alien.dmi'
	race = /datum/species/alien
	gender = FEMALE //All xenos are girls!!
	faction = list(ROLE_ALIEN)
	sight = SEE_MOBS
	bubble_icon = "alien"
	blocks_emissive = EMISSIVE_BLOCK_UNIQUE
	pass_flags = PASSTABLE
	status_flags = (CANUNCONSCIOUS | CANPUSH)
	unique_name = TRUE

	///Xenomorph names, changed overtime through evolution
	var/static/regex/alien_name_regex = new("alien (larva|sentinel|drone|hunter|praetorian|queen)( \\(\\d+\\))?")


/**
 * These should eventually get removed
 */

/mob/living/carbon/human/species/alien/update_damage_overlays() //aliens don't have damage overlays.
	return

/mob/living/carbon/human/species/alien/update_body() // we don't use the bodyparts or body layers for aliens.
	return

/mob/living/carbon/human/species/alien/update_body_parts()//we don't use the bodyparts layer for aliens.
	return



/mob/living/carbon/human/species/alien/spawn_gibs(with_bodyparts)
	if(with_bodyparts)
		new /obj/effect/gibspawner/xeno(drop_location(), src)
	else
		new /obj/effect/gibspawner/xeno/bodypartless(drop_location(), src)

/mob/living/carbon/human/species/alien/assess_threat(judgement_criteria, lasercolor = "", datum/callback/weaponcheck=null) // beepsky won't hunt aliums
	return -10

/mob/living/carbon/human/species/alien/check_breath(datum/gas_mixture/breath)
	if(status_flags & GODMODE)
		return

	if(!breath || (breath.total_moles() == 0))
		//Aliens breathe in vaccuum
		return FALSE

	if(health <= HEALTH_THRESHOLD_CRIT)
		adjustOxyLoss(2)

	var/plasma_used = 0
	var/plas_detect_threshold = 0.02
	var/breath_pressure = (breath.total_moles()*R_IDEAL_GAS_EQUATION*breath.temperature)/BREATH_VOLUME
	var/list/breath_gases = breath.gases

	breath.assert_gases(/datum/gas/plasma, /datum/gas/oxygen)

	//Partial pressure of the plasma in our breath
	var/Plasma_pp = (breath_gases[/datum/gas/plasma][MOLES]/breath.total_moles())*breath_pressure

	if(Plasma_pp > plas_detect_threshold) // Detect plasma in air
		adjustPlasma(breath_gases[/datum/gas/plasma][MOLES]*250)
		throw_alert("alien_plas", /atom/movable/screen/alert/alien_plas)

		plasma_used = breath_gases[/datum/gas/plasma][MOLES]

	else
		clear_alert("alien_plas")

	//Breathe in plasma and out oxygen
	breath_gases[/datum/gas/plasma][MOLES] -= plasma_used
	breath_gases[/datum/gas/oxygen][MOLES] += plasma_used

	breath.garbage_collect()

	//BREATH TEMPERATURE
	handle_breath_temperature(breath)

/mob/living/carbon/human/species/alien/getTrail()
	if(getBruteLoss() < 200)
		return pick (list("xltrails_1", "xltrails2"))
	else
		return pick (list("xttrails_1", "xttrails2"))


/*----------------------------------------
Proc: AddInfectionImages()
Des: Gives the client of the alien an image on each infected mob.
Todo: remove this
----------------------------------------*/
/mob/living/carbon/human/species/alien/proc/AddInfectionImages()
	if(!client)
		return
	for(var/mob/living/L as anything in GLOB.mob_living_list)
		if(!HAS_TRAIT(L, TRAIT_XENO_HOST))
			continue
		var/obj/item/organ/body_egg/alien_embryo/A = L.getorgan(/obj/item/organ/body_egg/alien_embryo)
		if(A)
			var/I = image('icons/mob/alien.dmi', loc = L, icon_state = "infected[A.stage]")
			client.images += I


/*----------------------------------------
Proc: RemoveInfectionImages()
Des: Removes all infected images from the alien.
----------------------------------------*/
/mob/living/carbon/human/species/alien/proc/RemoveInfectionImages()
	if(!client)
		return
	for(var/image/I in client.images)
		var/searchfor = "infected"
		if(findtext(I.icon_state, searchfor, 1, length(searchfor) + 1))
			qdel(I)

/mob/living/carbon/human/species/alien/proc/alien_evolve(mob/living/carbon/human/species/alien/new_xeno)
	to_chat(src, span_noticealien("You begin to evolve!"))
	visible_message(span_alertalien("[src] begins to twist and contort!"))
	new_xeno.setDir(dir)
	if(numba && unique_name)
		new_xeno.numba = numba
		new_xeno.set_name()
	if(!alien_name_regex.Find(name))
		new_xeno.name = name
		new_xeno.real_name = real_name
	if(mind)
		mind.name = new_xeno.real_name
		mind.transfer_to(new_xeno)
	qdel(src)

/mob/living/carbon/human/species/alien/can_hold_items(obj/item/I)
	return (I && (I.item_flags & XENOMORPH_HOLDABLE || ISADVANCEDTOOLUSER(src)) && ..())


/**
 * ALIEN SUBTYPES
 *
 * - Drone
 * - Hunter
 * - Sentinel
 * - Praetorian
 * - Queen
 */

/mob/living/carbon/human/species/alien/humanoid/drone
	name = "alien drone"
	race = /datum/species/alien/drone
	caste = "d"
	maxHealth = 125
	health = 125
	icon_state = "aliend"

/mob/living/carbon/human/species/alien/humanoid/hunter
	name = "alien hunter"
	race = /datum/species/alien/hunter
	caste = "h"
	maxHealth = 125
	health = 125
	icon_state = "alienh"
