/datum/eldritch_knowledge/base_flesh
	name = "Principle of Hunger"
	desc = "Opens up the path of flesh to you. Allows you to transmute a pool of blood with a kitchen knife into a Flesh Blade"
	gain_text = "Hundred's of us starved, but I.. I found the strength in my greed."
	banned_knowledge = list(/datum/eldritch_knowledge/base_ash,/datum/eldritch_knowledge/base_rust,/datum/eldritch_knowledge/ash_final,/datum/eldritch_knowledge/rust_final)
	next_knowledge = list(/datum/eldritch_knowledge/flesh_grasp)
	required_atoms = list(/obj/item/kitchen/knife,/obj/effect/decal/cleanable/blood)
	result_atoms = list(/obj/item/melee/sickly_blade/flesh)
	cost = 1
	route = "Flesh"

/datum/eldritch_knowledge/flesh_ghoul
	name = "Imperfect Ritual"
	desc = "Allows you to resurrect the dead as voiceless dead by sacrificing them on the transmutation rune with a poppy. Voiceless dead are mute and have 50 HP. You can only have 2 at a time."
	gain_text = "I found notes.. notes of a ritual, it was unfinished and yet i still did it."
	cost = 1
	required_atoms = list(/mob/living/carbon/human,/obj/item/reagent_containers/food/snacks/grown/poppy)
	next_knowledge = list(/datum/eldritch_knowledge/flesh_mark,/datum/eldritch_knowledge/armor,/datum/eldritch_knowledge/ashen_eyes)
	route = "Flesh"
	var/max_amt = 2
	var/current_amt = 0
	var/list/ghouls = list()

/datum/eldritch_knowledge/flesh_ghoul/on_finished_recipe(mob/living/user,list/atoms,loc)
	var/mob/living/carbon/human/H
	for(var/mob/living/carbon/human/humie in atoms)
		H = humie
	if(!H)
		return
	var/mob/dead/observer/G
	for(var/mob/dead/observer/ghost in GLOB.dead_mob_list) //we are just looking for the owner of the body
		if(ghost.mind && ghost.mind.current == H && ghost.client)  //the dead mobs list can contain clientless mobs
			G = ghost
			break
	if(!G.reenter_corpse())
		var/list/mob/dead/observer/candidates = pollCandidatesForMob("Do you want to play as a [H.real_name], a voiceless dead", ROLE_HERETIC, null, ROLE_HERETIC, 50,H)
		if(!LAZYLEN(candidates))
			return
		var/mob/dead/observer/C = pick(candidates)
		message_admins("[key_name_admin(C)] has taken control of ([key_name_admin(H)]) to replace an AFK player.")
		H.ghostize(0)
		H.key = C.key
	if(!H.mind || !H.client)
		to_chat(user, "<span class='warning'>There is no soul connected to this body...</span>")
		return

	if(!check_ghouls(user) || HAS_TRAIT(H,TRAIT_HUSK))
		return

	ADD_TRAIT(H,TRAIT_MUTE,MAGIC_TRAIT)

	H.revive(full_heal = TRUE, admin_revive = TRUE)
	H.setMaxHealth(50)
	H.health = 50 // Voiceless dead are much tougher than ghouls
	H.become_husk()
	H.faction |= "e_cult"
	H.fully_replace_character_name(H.real_name,"Voiceless [H.real_name]")
	to_chat(H, "<span class='userdanger'>You have been revived by </span><B>[user.real_name]!</B>")
	to_chat(H, "<span class='userdanger'>[user.p_theyre(TRUE)] your master now, assist [user.p_them()] even if it costs you your new life!</span>")
	atoms -= H
	ghouls += H

/datum/eldritch_knowledge/flesh_ghoul/proc/check_ghouls(mob/living/user)

	listclearnulls(ghouls)

	for(var/mob/living/carbon/human/ghoul in ghouls)
		if(ghoul.stat == DEAD)
			to_chat(user, "<span class='big bold'>You feel the evil influence leave your body... you are no longer enslaved to [user.real_name]</span>")
			ghouls -= ghoul
			current_amt--

	if(current_amt >= max_amt)
		return FALSE
	return TRUE

/datum/eldritch_knowledge/flesh_grasp
	name = "Grasp of Flesh"
	gain_text = "My new found desire, it drove me to do great things! The Priest said."
	desc = "Empowers your mansus grasp to be able to create a single ghoul out of a dead person. Ghouls have only 25 HP and look like husks."
	cost = 1
	next_knowledge = list(/datum/eldritch_knowledge/flesh_ghoul)
	var/ghoul_amt = 1
	var/list/spooky_scaries
	route = "Flesh"

/datum/eldritch_knowledge/flesh_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!ishumanbasic(target))
		return
	var/mob/living/carbon/human/H = target
	var/datum/status_effect/eldritch/E = H.has_status_effect(/datum/status_effect/eldritch/rust) || H.has_status_effect(/datum/status_effect/eldritch/ash) || H.has_status_effect(/datum/status_effect/eldritch/flesh)
	if(E)
		E.on_effect()
		H.bleed_rate = min(H.bleed_rate + 4, 8)
	if(H.stat != DEAD)
		to_chat(user, "<span class='warning'>This spell can only affect the dead!</span>")
		return

	for(var/mob/dead/observer/ghost in GLOB.dead_mob_list) //excludes new players
		if(ghost.mind && ghost.mind.current == H && ghost.client)  //the dead mobs list can contain clientless mobs
			ghost.reenter_corpse()
			break

	if(!H.mind || !H.client)
		to_chat(user, "<span class='warning'>There is no soul connected to this body...</span>")
		return

	check_ghouls(user)
	if(HAS_TRAIT(H,TRAIT_HUSK))
		to_chat(user, "<span class='warning'>You cannot revive a dead ghoul!</span>")
		return

	if(LAZYLEN(spooky_scaries) >= ghoul_amt)
		to_chat(user, "<span class='warning'>Your patron cannot support more ghouls on this plane!</span>")
		return

	LAZYADD(spooky_scaries,H)


	H.revive(full_heal = TRUE, admin_revive = TRUE)
	H.setMaxHealth(25)
	H.health = 25
	H.become_husk()
	H.faction |= "e_cult"
	H.fully_replace_character_name(H.real_name,"Ghouled [H.real_name]")
	to_chat(H, "<span class='userdanger'>You have been revived by </span><B>[user.real_name]!</B>")
	to_chat(H, "<span class='userdanger'>[user.p_theyre(TRUE)] your master now, assist [user.p_them()] even if it costs you your new life!</span>")
	return

/datum/eldritch_knowledge/flesh_grasp/proc/check_ghouls(mob/user)
	if(LAZYLEN(spooky_scaries) == 0)
		return

	for(var/X in spooky_scaries)
		if(!ishuman(X))
			LAZYREMOVE(spooky_scaries,X)
			continue
		var/mob/living/carbon/human/H = X
		if(H.stat == DEAD)
			to_chat(user, "<span class='big bold'>You feel the evil influence leave your body... you are no longer enslaved to [user.real_name]</span>")
			LAZYREMOVE(spooky_scaries,X)
			continue

	listclearnulls(spooky_scaries)

/datum/eldritch_knowledge/flesh_mark
	name = "Mark of flesh"
	gain_text = "I saw them, the marked ones. The screams.. the silence."
	desc = "Your sickly blade now applies mark of flesh status effect. To proc the mark, use your mansus grasp on the marked. Mark of flesh when procced causeds additional bleeding."
	cost = 2
	next_knowledge = list(/datum/eldritch_knowledge/summon/raw_prophet)
	banned_knowledge = list(/datum/eldritch_knowledge/rust_mark,/datum/eldritch_knowledge/ash_mark)
	route = "Flesh"

/datum/eldritch_knowledge/flesh_mark/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(istype(target,/mob/living))
		var/mob/living/L = target
		L.apply_status_effect(/datum/status_effect/eldritch/flesh)

/datum/eldritch_knowledge/flesh_blade_upgrade
	name = "Bleeding Steel"
	gain_text = "It rained blood, that's when i understood the gravekeeper's advice."
	desc = "Your blade will now cause additional bleeding."
	cost = 2
	next_knowledge = list(/datum/eldritch_knowledge/summon/stalker)
	banned_knowledge = list(/datum/eldritch_knowledge/ash_blade_upgrade,/datum/eldritch_knowledge/rust_blade_upgrade)
	route = "Flesh"

/datum/eldritch_knowledge/flesh_blade_upgrade/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(ishuman(target))
		var/mob/living/carbon/human/C = target
		C.bleed_rate += 3
		C.blood_volume -= 10

/datum/eldritch_knowledge/summon/raw_prophet
	name = "Raw Ritual"
	gain_text = "Uncanny man, walks alone in the valley, I was able to call his aid."
	desc = "You can now summon a Raw Prophet using eyes, a left arm, right arm and a pool of blood. Raw prophets have increased seeing range, as well as Xray. But are very fragile and weak."
	cost = 1
	required_atoms = list(/obj/item/organ/eyes,/obj/item/bodypart/l_arm,/obj/item/bodypart/r_arm,/obj/effect/decal/cleanable/blood)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/raw_prophet
	next_knowledge = list(/datum/eldritch_knowledge/flesh_blade_upgrade,/datum/eldritch_knowledge/spell/cleave,/datum/eldritch_knowledge/curse/paralysis)
	route = "Flesh"

/datum/eldritch_knowledge/summon/stalker
	name = "Lonely Ritual"
	gain_text = "I was able to combine my greed and desires to summon an eldritch beast i have not seen before."
	desc = "You can now summon a Stalker using a knife, a flower, a pen and a piece of paper. Stalkers can shapeshift into harmeless animals and get close to the victim."
	cost = 1
	required_atoms = list(/obj/item/kitchen/knife,/obj/item/reagent_containers/food/snacks/grown/poppy,/obj/item/pen,/obj/item/paper)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/stalker
	next_knowledge = list(/datum/eldritch_knowledge/summon/ashy,/datum/eldritch_knowledge/summon/rusty,/datum/eldritch_knowledge/flesh_final)
	route = "Flesh"

/datum/eldritch_knowledge/summon/ashy
	name = "Ashen Ritual"
	gain_text = "I combined principle of hunger with desire of destruction. The eyeful lords have noticed me."
	desc = "You can now summon an Ash Man by transmutating a pile of ash , a head and a book."
	cost = 1
	required_atoms = list(/obj/effect/decal/cleanable/ash,/obj/item/bodypart/head,/obj/item/book)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/ash_spirit
	next_knowledge = list(/datum/eldritch_knowledge/summon/stalker,/datum/eldritch_knowledge/spell/rust_wave)

/datum/eldritch_knowledge/summon/rusty
	name = "Rusted Ritual"
	gain_text = "I combined principle of hunger with desire of corruption. The rusted hills call my name."
	desc = "You can now summon a Rust Walker transmutating vomit pool, a head and a book."
	cost = 1
	required_atoms = list(/obj/effect/decal/cleanable/vomit,/obj/item/bodypart/head,/obj/item/book)
	mob_to_summon = /mob/living/simple_animal/hostile/eldritch/rust_spirit
	next_knowledge = list(/datum/eldritch_knowledge/summon/stalker,/datum/eldritch_knowledge/spell/mad_touch)

/datum/eldritch_knowledge/spell/blood_siphon
	name = "Blood Siphon"
	gain_text = "Our blood is all the same after all, the owl told me."
	desc = "You gain a spell that drains enemies health and restores yours."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/targeted/touch/ash_leech
	next_knowledge = list(/datum/eldritch_knowledge/spell/rust_wave,/datum/eldritch_knowledge/spell/mad_touch)

/datum/eldritch_knowledge/flesh_final
	name = "Priest's Final Hymn"
	gain_text = "Man of this world. Hear me! For the time of the lord of arms has come!"
	desc = "Bring 3 bodies onto a transmutation rune to either ascend as a terror of the night prime or you can summon a regular terror of the night."
	required_atoms = list(/mob/living/carbon/human)
	cost = 3
	route = "Flesh"
	var/is_summoned = FALSE

/datum/eldritch_knowledge/flesh_final/recipe_snowflake_check(list/atoms, loc,list/selected_atoms)
	if(is_summoned)
		return FALSE
	var/counter = 0
	for(var/mob/living/carbon/human/H in atoms)
		selected_atoms |= H
		counter++
		if(counter == 3)
			return TRUE
	return FALSE

/datum/eldritch_knowledge/flesh_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	is_summoned = TRUE // you got one chance
	var/alert_ = alert(user,"Do you want to ascend as the lord of the night or just summon a terror of the night?","...","Yes","No")
	user.SetImmobilized(10 HOURS) // no way someone will stand 10 hours in a spot, just so he can move while the alert is still showing.
	switch(alert_)
		if("No")

			var/mob/living/summoned = new /mob/living/simple_animal/hostile/eldritch/armsy(loc)
			message_admins("[summoned.name] is being summoned by [user.real_name] in [loc]")
			var/list/mob/dead/observer/candidates = pollCandidatesForMob("Do you want to play as a [summoned.real_name]", ROLE_HERETIC, null, ROLE_HERETIC, 50,summoned)
			if(!LAZYLEN(candidates))
				return
			var/mob/dead/observer/C = pick(candidates)
			priority_announce("$^@&#*$^@(#&$(@&#^$&#^@# Fear the dark, for vassal of arms has ascended! Terror of the night has come! $^@&#*$^@(#&$(@&#^$&#^@#","#$^@&#*$^@(#&$(@&#^$&#^@#", 'sound/ai/spanomalies.ogg')
			message_admins("[key_name_admin(C)] has taken control of ([key_name_admin(summoned)]).")
			summoned.ghostize(0)
			summoned.key = C.key
			user.SetImmobilized(0)


			to_chat(summoned,"<span class='warning'>You are bound to [user.real_name]'s' will! Don't let your master die, protect him at all cost!</span>")
		if("Yes")
			var/mob/living/summoned = new /mob/living/simple_animal/hostile/eldritch/armsy/prime(loc,spawn_more = TRUE,len = 10)
			summoned.ghostize(0)
			user.SetImmobilized(0)
			priority_announce("$^@&#*$^@(#&$(@&#^$&#^@# Fear the dark, for king of arms has ascended! Lord of the night has come! $^@&#*$^@(#&$(@&#^$&#^@#","#$^@&#*$^@(#&$(@&#^$&#^@#", 'sound/ai/spanomalies.ogg')
			var/mob/living/carbon/C = user
			C.mind.transfer_to(summoned,TRUE)
			C.gib()
	return ..()
