

/datum/whim/airbud_bball
	name = "Airbud Mode"
	scan_radius = 5
	scan_every = 4
	abandon_rescan_length = 12 SECONDS
	/// If the dog is in possession of a ball, it's stored here, though there's no reason it can't be expanded to other stuff to.
	var/obj/item/carried_bball

/datum/whim/airbud_bball/abandon()
	carried_bball = null
	return ..()

/datum/whim/airbud_bball/inner_can_start()
	var/obj/item/toy/beach_ball/holoball/bball// = locate(/obj/item/toy/beach_ball/holoball in oview(src,  7))

	for(var/i in oview(owner, scan_radius))
		//testing("[owner] searching whim [name], atom [i]")
		if(istype(i, /obj/item/toy/beach_ball/holoball))
			bball = i
			break
		else if(isliving(i))
			var/mob/living/check_mob = i
			bball = (locate(/obj/item/toy/beach_ball/holoball) in check_mob)
			if(bball)
				break

	return bball

/datum/whim/airbud_bball/tick()
	. = ..()
	if(state == WHIM_INACTIVE)
		return

	var/obj/item/toy/beach_ball/holoball/bball = concerned_target
	if(!istype(bball) || (isturf(bball.loc) && get_dist(owner, bball) > 7))
		abandon()
		return

	if(carried_bball && carried_bball == concerned_target)
		kobe()
		return

	if(isliving(bball.loc)) // some poor sucker is about to get taught a lesson they'll never forget
		var/mob/living/bball_player = bball.loc
		owner.visible_message("<span class='warning'>[owner] leaps at [bball_player], trying to steal [bball]!</span>")
		var/datum/callback/ankle_breaking = CALLBACK(src, .proc/ankle_breaker, bball_player)
		owner.throw_at(bball_player, 10, 4, owner, FALSE, FALSE, ankle_breaking)
	else
		owner.visible_message("<span class='warning'>[owner] dashes to [bball], taking possession!</span>")
		carried_bball = bball
		var/datum/callback/kobe_callback = CALLBACK(src, .proc/kobe)
		owner.throw_at(bball, 10, 4, owner, FALSE, FALSE, kobe_callback)

/**
  * This proc is for when air bud steps up his game and destroys some poor assistant
  *
  * If the mob we just tackled to steal the ball from wasn't a carbon, we just take the ball and that's it. Otherwise, we mess them up.
  */
/datum/whim/airbud_bball/proc/ankle_breaker(mob/living/target)
	var/obj/item/toy/beach_ball/holoball/bball = concerned_target
	if(!target || !istype(bball))
		abandon()
		return

	if(!owner.Adjacent(target))
		return

	target.Knockdown(3 SECONDS)
	carried_bball = bball
	carried_bball.forceMove(get_turf(owner))

	if(!iscarbon(target)) // the rest of this is just wound handling
		return

	// I know ankle breaking in basketball is used to describe sick offensive cross dribbles, and not stealing the ball on defense
	// but this is a corgi flying at you, stealing your basketball, then flying 10 ft in the air and slam dunking it. Roll with it.
	var/mob/living/carbon/carbon_target = target
	var/datum/wound/blunt/moderate/broken_ankle/preexisting_condition = (locate(/datum/wound/blunt/moderate/broken_ankle) in carbon_target.all_wounds)

	if(carbon_target.client)
		carbon_target.client.give_award(/datum/award/achievement/misc/airbud, carbon_target)

	// if we've already got a broken ankle, just blast that leg
	if(preexisting_condition)
		var/obj/item/bodypart/ankle = preexisting_condition.limb
		ankle.receive_damage(10, wound_bonus = rand(40,120))
		target.visible_message("<span class='warning'>[owner] steals [bball] with moves so swift that it obliterates [target]'s [ankle.name]!</span>", "<span class='userdanger'>[owner] steals [bball] from you so hard that it obliterates your [ankle.name]!</span>")
		return

	// otherwise, break an ankle
	target.visible_message("<span class='warning'>[owner] steals [bball] with moves so swift, [target] crumples painfully to the ground trying to keep up!</span>", "<span class='userdanger'>[owner] steals [bball] from you so hard that you crumple painfully to the ground!</span>")
	var/obj/item/bodypart/ankle = pick(list(target.get_bodypart(BODY_ZONE_L_LEG), target.get_bodypart(BODY_ZONE_R_LEG))) || target.get_bodypart(BODY_ZONE_L_LEG) || target.get_bodypart(BODY_ZONE_R_LEG)
	if(ankle)
		var/datum/wound/blunt/moderate/broken_ankle/ankle_wound = new
		ankle_wound.apply_wound(ankle)
		ankle.receive_damage(10, wound_bonus = CANT_WOUND)

/// Get ready to shoot/dunk if there's a hoop nearby. If not, we'll just give up and dribble a bit
/datum/whim/airbud_bball/proc/kobe()
	var/obj/item/toy/beach_ball/holoball/bball = carried_bball
	if(!istype(bball))
		abandon()
		return

	var/obj/structure/holohoop/the_hoop = locate(/obj/structure/holohoop) in oview(7, owner)
	if(!the_hoop)
		owner.visible_message("<span class='notice'>[owner] dribbles [bball] for a bit, then seems to grow bored by the lack of hoops.</span>")
		abandon()
		return

	shoot(bball, the_hoop)

/// This is where we actually go to shoot/dunk the ball into our acquired hoop. What type of shot we do depends on our distance
/datum/whim/airbud_bball/proc/shoot(obj/item/toy/beach_ball/holoball/bball, obj/structure/holohoop/the_hoop)
	if(!istype(bball) || !istype(the_hoop))
		abandon()
		return

	var/datum/callback/shot_callback
	var/atom/movable/what_gets_thrown // dunks throw the dog, shots throw the ball

	switch(get_dist(owner, the_hoop))
		if(0 to 2)
			owner.visible_message("<span class='notice'>[owner] grabs insane air as [owner.p_they()] slam[owner.p_s()] [bball] into [the_hoop]! Damn!</span>")
			bball.forceMove(owner)
			what_gets_thrown = owner
			shot_callback = CALLBACK(the_hoop, /obj/structure/holohoop/.proc/dunk, bball, owner)

		if(3 to 5)
			owner.visible_message("<span class='notice'>[owner] does a sick flip while shooting [bball] at [the_hoop]!</span>")
			owner.SpinAnimation(10, 1)
			what_gets_thrown = bball
			shot_callback = CALLBACK(the_hoop, /obj/structure/holohoop/.proc/swish, bball, owner)

		if(6 to INFINITY)
			// behold: the only code ever written that actually references simple mob pronouns
			owner.visible_message("<span class='notice'>[owner] is briefly overcome by grim determination as [owner.p_they()] set[owner.p_s()] on [owner.p_their()] hind legs and shoot[owner.p_s()] [bball] at [the_hoop] from downtown!</span>")
			what_gets_thrown = bball
			shot_callback = CALLBACK(the_hoop, /obj/structure/holohoop/.proc/swish, bball, owner)

	what_gets_thrown.throw_at(get_turf(the_hoop), 10, 3, owner, FALSE, FALSE, shot_callback)
	abandon()




/datum/whim/snacks
	name = "Seek snacks"
	priority = 2

/// See if there's any snacks in the vicinity, if so, set to work after them
/datum/whim/snacks/inner_can_start()
	for(var/obj/item/reagent_containers/food/snacks/S in oview(owner,scan_radius))
		if(isturf(S.loc) || ishuman(S.loc))
			return S

/// A bunch of crappy old code neatened up a bit, this handles the actual moving and eating of snacks
/datum/whim/snacks/tick()
	. = ..()
	if(state == WHIM_INACTIVE)
		return

	if(!concerned_target || isnull(concerned_target.loc) || get_dist(owner, concerned_target.loc) > scan_radius || (!isturf(concerned_target.loc) && !ishuman(concerned_target.loc)))
		abandon()
		return

	// The below sleeps are how dog snack code already was, i'm just preserving it for my own simplicity, feel free to change it later -ryll, 2020
	//Feeding, chasing food, FOOOOODDDD
	step_to(owner,concerned_target,1)
	sleep(3)
	step_to(owner,concerned_target,1)
	sleep(3)
	step_to(owner,concerned_target,1)

	if(!concerned_target)		//Not redundant due to sleeps, Item can be gone in 6 decisecomds
		abandon()
		return

	owner.face_atom(concerned_target)
	if(!owner.Adjacent(concerned_target)) //can't reach food through windows.
		return

	if(isturf(concerned_target.loc))
		concerned_target.attack_animal(owner)
	else if(ishuman(concerned_target.loc))
		if(prob(20))
			owner.manual_emote("stares at [concerned_target.loc]'s [concerned_target] with a sad puppy-face")






/datum/whim/gnaw_bone
	name = "Gnaw bone"
	priority = 1
	scan_radius = 4
	scan_every = 5
	abandon_rescan_length = 30 SECONDS
	var/obj/item/bone

/// See if there's any snacks in the vicinity, if so, set to work after them
/datum/whim/gnaw_bone/inner_can_start()
	for(var/i in oview(owner, scan_radius))
		//testing("[owner] searching whim [name], atom [i]")
		if(isbodypart(i))
			return i

/// A bunch of crappy old code neatened up a bit, this handles the actual moving and eating of snacks
/datum/whim/gnaw_bone/abandon()
	if(bone && owner && bone.loc == owner)
		owner.visible_message("<b>[owner]</b> drops [bone] from [owner.p_their()] mouth.")
		bone.forceMove(owner.drop_location())
	bone = null
	return ..()

/// A bunch of crappy old code neatened up a bit, this handles the actual moving and eating of snacks
/datum/whim/gnaw_bone/tick()
	. = ..()
	if(state == WHIM_INACTIVE)
		return

	if(!concerned_target || !isturf(concerned_target.loc) || get_dist(owner, concerned_target.loc) > scan_radius * 2)
		abandon()
		return

	if(bone && get_dist(owner, concerned_target) < 3) // found a nice place to gnaw (once we have the bone, the concerned_target refers to where we lay down)
		if(prob(15))
			owner.visible_message("<b>[owner]</b> gnaws on [bone].")
		return

	walk_to(owner, get_turf(concerned_target), 0, rand(20,35) * 0.1)

	if(!concerned_target)		//Not redundant due to sleeps, Item can be gone in 6 decisecomds
		abandon()
		return

	owner.face_atom(concerned_target)
	if(!owner.Adjacent(concerned_target) || !isturf(concerned_target.loc)) //can't reach food through windows.
		return

	if(!bone && isbodypart(concerned_target))
		// make this its own proc to pick up the mouse and select a recepient
		owner.visible_message("<b>[owner]</b> picks up [concerned_target] in [owner.p_their()] mouth, then looks around for a place to rest.")
		bone = concerned_target
		bone.forceMove(owner)
		var/list/turf/spots = view(owner, 5)
		concerned_target = pick(spots)
