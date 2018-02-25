/datum/reagent/drug
	name = "Drug"
	id = "drug"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	taste_description = "bitterness"

/datum/reagent/drug/space_drugs
	name = "Space drugs"
	id = "space_drugs"
	description = "An illegal chemical compound used as drug."
	color = "#60A584" // rgb: 96, 165, 132
	overdose_threshold = 30

/datum/reagent/drug/space_drugs/on_mob_life(mob/living/M)
	M.set_drugginess(15)
	if(isturf(M.loc) && !isspaceturf(M.loc))
		if(M.canmove)
			if(prob(10))
				step(M, pick(GLOB.cardinals))
	if(prob(7))
		M.emote(pick("twitch","drool","moan","giggle"))
	..()

/datum/reagent/drug/space_drugs/overdose_start(mob/living/M)
	to_chat(M, "<span class='userdanger'>You start tripping hard!</span>")


/datum/reagent/drug/space_drugs/overdose_process(mob/living/M)
	if(M.hallucination < volume && prob(20))
		M.hallucination += 5
	..()

/datum/reagent/drug/nicotine
	name = "Nicotine"
	id = "nicotine"
	description = "Slightly reduces stun times. If overdosed it will deal toxin and oxygen damage."
	reagent_state = LIQUID
	color = "#60A584" // rgb: 96, 165, 132
	addiction_threshold = 30
	taste_description = "smoke"

/datum/reagent/drug/nicotine/on_mob_life(mob/living/M)
	if(prob(1))
		var/smoke_message = pick("You feel relaxed.", "You feel calmed.","You feel alert.","You feel rugged.")
		to_chat(M, "<span class='notice'>[smoke_message]</span>")
	M.AdjustStun(-20, 0)
	M.AdjustKnockdown(-20, 0)
	M.AdjustUnconscious(-20, 0)
	M.adjustStaminaLoss(-0.5*REM, 0)
	..()
	. = 1

/datum/reagent/drug/menthol
	name = "Menthol"
	id = "menthol"
	description = "Tastes naturally minty, and imparts a very mild numbing sensation."
	taste_description = "mint"
	reagent_state = LIQUID
	color = "#80AF9C"

/datum/reagent/drug/crank
	name = "Crank"
	id = "crank"
	description = "Reduces stun times by about 200%. If overdosed or addicted it will deal significant Toxin, Brute and Brain damage."
	reagent_state = LIQUID
	color = "#FA00C8"
	overdose_threshold = 20
	addiction_threshold = 10

/datum/reagent/drug/crank/on_mob_life(mob/living/M)
	if(prob(5))
		var/high_message = pick("You feel jittery.", "You feel like you gotta go fast.", "You feel like you need to step it up.")
		to_chat(M, "<span class='notice'>[high_message]</span>")
	M.AdjustStun(-20, 0)
	M.AdjustKnockdown(-20, 0)
	M.AdjustUnconscious(-20, 0)
	..()
	. = 1

/datum/reagent/drug/crank/overdose_process(mob/living/M)
	M.adjustBrainLoss(2*REM)
	M.adjustToxLoss(2*REM, 0)
	M.adjustBruteLoss(2*REM, 0)
	..()
	. = 1

/datum/reagent/drug/crank/addiction_act_stage1(mob/living/M)
	M.adjustBrainLoss(5*REM)
	..()

/datum/reagent/drug/crank/addiction_act_stage2(mob/living/M)
	M.adjustToxLoss(5*REM, 0)
	..()
	. = 1

/datum/reagent/drug/crank/addiction_act_stage3(mob/living/M)
	M.adjustBruteLoss(5*REM, 0)
	..()
	. = 1

/datum/reagent/drug/crank/addiction_act_stage4(mob/living/M)
	M.adjustBrainLoss(3*REM)
	M.adjustToxLoss(5*REM, 0)
	M.adjustBruteLoss(5*REM, 0)
	..()
	. = 1

/datum/reagent/drug/krokodil
	name = "Krokodil"
	id = "krokodil"
	description = "Cools and calms you down. If overdosed it will deal significant Brain and Toxin damage. If addicted it will begin to deal fatal amounts of Brute damage as the subject's skin falls off."
	reagent_state = LIQUID
	color = "#0064B4"
	overdose_threshold = 20
	addiction_threshold = 15


/datum/reagent/drug/krokodil/on_mob_life(mob/living/M)
	var/high_message = pick("You feel calm.", "You feel collected.", "You feel like you need to relax.")
	if(prob(5))
		to_chat(M, "<span class='notice'>[high_message]</span>")
	..()

/datum/reagent/drug/krokodil/overdose_process(mob/living/M)
	M.adjustBrainLoss(0.25*REM)
	M.adjustToxLoss(0.25*REM, 0)
	..()
	. = 1

/datum/reagent/drug/krokodil/addiction_act_stage1(mob/living/M)
	M.adjustBrainLoss(2*REM)
	M.adjustToxLoss(2*REM, 0)
	..()
	. = 1

/datum/reagent/krokodil/addiction_act_stage2(mob/living/M)
	if(prob(25))
		to_chat(M, "<span class='danger'>Your skin feels loose...</span>")
	..()

/datum/reagent/drug/krokodil/addiction_act_stage3(mob/living/M)
	if(prob(25))
		to_chat(M, "<span class='danger'>Your skin starts to peel away...</span>")
	M.adjustBruteLoss(3*REM, 0)
	..()
	. = 1

/datum/reagent/drug/krokodil/addiction_act_stage4(mob/living/carbon/human/M)
	CHECK_DNA_AND_SPECIES(M)
	if(!istype(M.dna.species, /datum/species/krokodil_addict))
		to_chat(M, "<span class='userdanger'>Your skin falls off easily!</span>")
		M.adjustBruteLoss(50*REM, 0) // holy shit your skin just FELL THE FUCK OFF
		M.set_species(/datum/species/krokodil_addict)
	else
		M.adjustBruteLoss(5*REM, 0)
	..()
	. = 1

/datum/reagent/drug/methamphetamine
	name = "Methamphetamine"
	id = "methamphetamine"
	description = "Reduces stun times by about 300%, speeds the user up, and allows the user to quickly recover stamina while dealing a small amount of Brain damage. If overdosed the subject will move randomly, laugh randomly, drop items and suffer from Toxin and Brain damage. If addicted the subject will constantly jitter and drool, before becoming dizzy and losing motor control and eventually suffer heavy toxin damage."
	reagent_state = LIQUID
	color = "#FAFAFA"
	overdose_threshold = 20
	addiction_threshold = 10
	metabolization_rate = 0.75 * REAGENTS_METABOLISM

/datum/reagent/drug/methamphetamine/on_mob_add(mob/M)
	..()
	if(isliving(M))
		var/mob/living/L = M
		L.add_trait(TRAIT_GOTTAGOREALLYFAST, id)

/datum/reagent/drug/methamphetamine/on_mob_delete(mob/M)
	if(isliving(M))
		var/mob/living/L = M
		L.remove_trait(TRAIT_GOTTAGOREALLYFAST, id)
	..()

/datum/reagent/drug/methamphetamine/on_mob_life(mob/living/M)
	var/high_message = pick("You feel hyper.", "You feel like you need to go faster.", "You feel like you can run the world.")
	if(prob(5))
		to_chat(M, "<span class='notice'>[high_message]</span>")
	M.AdjustStun(-40, 0)
	M.AdjustKnockdown(-40, 0)
	M.AdjustUnconscious(-40, 0)
	M.adjustStaminaLoss(-2, 0)
	M.Jitter(2)
	M.adjustBrainLoss(0.25)
	if(prob(5))
		M.emote(pick("twitch", "shiver"))
	..()
	. = 1

/datum/reagent/drug/methamphetamine/overdose_process(mob/living/M)
	if(M.canmove && !ismovableatom(M.loc))
		for(var/i in 1 to 4)
			step(M, pick(GLOB.cardinals))
	if(prob(20))
		M.emote("laugh")
	if(prob(33))
		M.visible_message("<span class='danger'>[M]'s hands flip out and flail everywhere!</span>")
		M.drop_all_held_items()
	..()
	M.adjustToxLoss(1, 0)
	M.adjustBrainLoss(pick(0.5, 0.6, 0.7, 0.8, 0.9, 1))
	. = 1

/datum/reagent/drug/methamphetamine/addiction_act_stage1(mob/living/M)
	M.Jitter(5)
	if(prob(20))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/methamphetamine/addiction_act_stage2(mob/living/M)
	M.Jitter(10)
	M.Dizzy(10)
	if(prob(30))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/methamphetamine/addiction_act_stage3(mob/living/M)
	if(M.canmove && !ismovableatom(M.loc))
		for(var/i = 0, i < 4, i++)
			step(M, pick(GLOB.cardinals))
	M.Jitter(15)
	M.Dizzy(15)
	if(prob(40))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/methamphetamine/addiction_act_stage4(mob/living/carbon/human/M)
	if(M.canmove && !ismovableatom(M.loc))
		for(var/i = 0, i < 8, i++)
			step(M, pick(GLOB.cardinals))
	M.Jitter(20)
	M.Dizzy(20)
	M.adjustToxLoss(5, 0)
	if(prob(50))
		M.emote(pick("twitch","drool","moan"))
	..()
	. = 1

/datum/reagent/drug/bath_salts
	name = "Bath Salts"
	id = "bath_salts"
	description = "Makes you impervious to stuns and grants a stamina regeneration buff, but you will be a nearly uncontrollable tramp-bearded raving lunatic."
	reagent_state = LIQUID
	color = "#FAFAFA"
	overdose_threshold = 20
	addiction_threshold = 10
	taste_description = "salt" // because they're bathsalts?

/datum/reagent/drug/bath_salts/on_mob_add(mob/M)
	..()
	if(isliving(M))
		var/mob/living/L = M
		L.add_trait(TRAIT_STUNIMMUNE, id)
		L.add_trait(TRAIT_SLEEPIMMUNE, id)

/datum/reagent/drug/bath_salts/on_mob_delete(mob/M)
	if(isliving(M))
		var/mob/living/L = M
		L.remove_trait(TRAIT_STUNIMMUNE, id)
		L.remove_trait(TRAIT_SLEEPIMMUNE, id)
	..()

/datum/reagent/drug/bath_salts/on_mob_life(mob/living/M)
	var/high_message = pick("You feel amped up.", "You feel ready.", "You feel like you can push it to the limit.")
	if(prob(5))
		to_chat(M, "<span class='notice'>[high_message]</span>")
	M.adjustStaminaLoss(-5, 0)
	M.adjustBrainLoss(0.5)
	M.adjustToxLoss(0.1, 0)
	M.hallucination += 10
	if(M.canmove && !ismovableatom(M.loc))
		step(M, pick(GLOB.cardinals))
		step(M, pick(GLOB.cardinals))
	..()
	. = 1

/datum/reagent/drug/bath_salts/overdose_process(mob/living/M)
	M.hallucination += 10
	if(M.canmove && !ismovableatom(M.loc))
		for(var/i in 1 to 8)
			step(M, pick(GLOB.cardinals))
	if(prob(20))
		M.emote(pick("twitch","drool","moan"))
	if(prob(33))
		M.drop_all_held_items()
	..()

/datum/reagent/drug/bath_salts/addiction_act_stage1(mob/living/M)
	M.hallucination += 10
	if(M.canmove && !ismovableatom(M.loc))
		for(var/i = 0, i < 8, i++)
			step(M, pick(GLOB.cardinals))
	M.Jitter(5)
	M.adjustBrainLoss(10)
	if(prob(20))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/bath_salts/addiction_act_stage2(mob/living/M)
	M.hallucination += 20
	if(M.canmove && !ismovableatom(M.loc))
		for(var/i = 0, i < 8, i++)
			step(M, pick(GLOB.cardinals))
	M.Jitter(10)
	M.Dizzy(10)
	M.adjustBrainLoss(10)
	if(prob(30))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/bath_salts/addiction_act_stage3(mob/living/M)
	M.hallucination += 30
	if(M.canmove && !ismovableatom(M.loc))
		for(var/i = 0, i < 12, i++)
			step(M, pick(GLOB.cardinals))
	M.Jitter(15)
	M.Dizzy(15)
	M.adjustBrainLoss(10)
	if(prob(40))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/bath_salts/addiction_act_stage4(mob/living/carbon/human/M)
	M.hallucination += 40
	if(M.canmove && !ismovableatom(M.loc))
		for(var/i = 0, i < 16, i++)
			step(M, pick(GLOB.cardinals))
	M.Jitter(50)
	M.Dizzy(50)
	M.adjustToxLoss(5, 0)
	M.adjustBrainLoss(10)
	if(prob(50))
		M.emote(pick("twitch","drool","moan"))
	..()
	. = 1

/datum/reagent/drug/aranesp
	name = "Aranesp"
	id = "aranesp"
	description = "Amps you up and gets you going, fixes all stamina damage you might have but can cause toxin and oxygen damage."
	reagent_state = LIQUID
	color = "#78FFF0"

/datum/reagent/drug/aranesp/on_mob_life(mob/living/M)
	var/high_message = pick("You feel amped up.", "You feel ready.", "You feel like you can push it to the limit.")
	if(prob(5))
		to_chat(M, "<span class='notice'>[high_message]</span>")
	M.adjustStaminaLoss(-18, 0)
	M.adjustToxLoss(0.5, 0)
	if(prob(50))
		M.losebreath++
		M.adjustOxyLoss(1, 0)
	..()
	. = 1

/datum/reagent/drug/catnip
	name = "Nepetalactone"
	id = "catnip"
	description = "On non-mutant humans, acts as a mild relaxant. When exposed to mutant genes, has some... interesting effects."
	reagent_state = LIQUID
	color = "#b3ff99"
	addiction_threshold = 30

/datum/reagent/drug/catnip/on_mob_life(mob/living/M)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(iscatperson(H)) //oh boy it's time for fun
			if(prob(5))
				playsound(get_turf(H), 'sound/effects/meow1.ogg', 65, 1, -1)
				H.visible_message("<span class='warning bold'>[H] meows loudly!</span>")
			else if(prob(5))
				playsound(get_turf(H), 'goon/sound/effects/cat_hiss.ogg', 65, 1, -1)
				H.visible_message("<span class='warning bold'>[H] hisses!</span>")
			else if(prob(2.5))
				H.Stun(25)
				to_chat(H, "<span class='notice'>You think you saw a light in the distance... but it fades away as soon as you notice it.</span>")
			else if(prob(7.5))
				H.Knockdown(37.5)
				H.spin(30, 1)
				H.visible_message("<span class='warning'>[H] rolls around on the floor!</span>", "<span class='notice'>Ahhh... rolling... feels nice.... ahhhhhh....</span>")
		else
			if(prob(10))
				to_chat(H, "<span class='notice'>[pick("You feel relaxed.", "You feel calmed.","You feel alert.","You feel rugged.")]</span>")
			H.adjustStaminaLoss(-rand(0.1, 0.45)*REM, 0)
	..()
	. = 1

/datum/reagent/drug/catnip/addiction_act_stage1(mob/living/M)
	if(!ishuman(M))
		return
	var/mob/living/carbon/human/H = M
	if(!iscatperson(H))
		return
	if(prob(7.5))
		playsound(get_turf(M), 'sound/effects/meow1.ogg', 65, 1, -1)
		M.visible_message("<span class='warning bold'>[M] meows loudly!</span>")
	else if(prob(9))
		playsound(get_turf(M), 'goon/sound/effects/cat_hiss.ogg', 65, 1, -1)
		M.visible_message("<span class='warning bold'>[M] hisses!</span>")
	return ..()

/datum/reagent/drug/catnip/addiction_act_stage2(mob/living/M)
	if(!ishuman(M))
		return
	var/mob/living/carbon/human/H = M
	if(!iscatperson(H))
		return
	if(prob(10))
		M.visible_message("<span class='warning bold'>[M] coughs up a hairball!</span>")
		M.vomit(lost_nutrition = 0, message = FALSE, distance = rand(1,3))
	else if(prob(7.5))
		playsound(get_turf(M), 'sound/effects/meow1.ogg', 65, 1, -1)
		M.visible_message("<span class='warning bold'>[M] meows loudly!</span>")
	else if(prob(9))
		playsound(get_turf(M), 'goon/sound/effects/cat_hiss.ogg', 65, 1, -1)
		M.visible_message("<span class='warning bold'>[M] hisses!</span>")
	return ..()

/datum/reagent/drug/catnip/addiction_act_stage2(mob/living/M)
	if(!ishuman(M))
		return
	var/mob/living/carbon/human/H = M
	if(!iscatperson(H))
		return
	if(prob(15))
		M.visible_message("<span class='warning bold'>[M] coughs up a hairball!</span>")
		M.vomit(lost_nutrition = 0, message = FALSE, distance = rand(1,3))
	if(prob(45))
		playsound(get_turf(M), 'sound/effects/meow1.ogg', 65, 1, -1)
		M.visible_message("<span class='warning bold'>[M] meows loudly!</span>")
	else if(prob(25))
		playsound(get_turf(M), 'goon/sound/effects/cat_hiss.ogg', 65, 1, -1)
		M.visible_message("<span class='warning bold'>[M] hisses!</span>")
	return ..()

/datum/reagent/drug/catnip/addiction_act_stage3(mob/living/M)
	if(!ishuman(M))
		return
	var/mob/living/carbon/human/H = M
	if(!iscatperson(H))
		return
	if(prob(32.5))
		H.Knockdown(75)
		H.spin(75, 2)
		M.visible_message("<span class='warning bold'>[M] starts rolling around on the floor!</span>")
	else if(prob(25))
		M.visible_message("<span class='warning bold'>[M] coughs up a hairball!</span>")
		M.vomit(lost_nutrition = 0, message = FALSE, distance = rand(1,3))
	if(prob(45))
		playsound(get_turf(M), 'sound/effects/meow1.ogg', 65, 1, -1)
		M.visible_message("<span class='warning bold'>[M] meows loudly!</span>")
	else if(prob(25))
		playsound(get_turf(M), 'goon/sound/effects/cat_hiss.ogg', 65, 1, -1)
		M.visible_message("<span class='warning bold'>[M] hisses!</span>")
	return ..()

/datum/reagent/drug/catnip/addiction_act_stage4(mob/living/M)
	return addiction_act_stage3(M)