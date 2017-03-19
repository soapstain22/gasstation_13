

/atom/movable
	var/can_buckle = 0
	var/buckle_lying = -1 //bed-like behaviour, forces mob.lying = buckle_lying if != -1
	var/buckle_requires_restraints = 0 //require people to be handcuffed before being able to buckle. eg: pipes
	var/list/mob/living/buckled_mobs = null //list()
	var/max_buckled_mobs = 1
	var/buckle_prevents_pull = FALSE

//Interaction
/atom/movable/attack_hand(mob/living/user)
	. = ..()
	if(can_buckle && has_buckled_mobs())
		if(buckled_mobs.len > 1)
			var/unbuckled = input(user, "Who do you wish to unbuckle?","Unbuckle Who?") as null|mob in buckled_mobs
			if(user_unbuckle_mob(unbuckled,user))
				return 1
		else
			if(user_unbuckle_mob(buckled_mobs[1],user))
				return 1

/atom/movable/MouseDrop_T(mob/living/M, mob/living/user)
	. = ..()
	if(can_buckle && istype(M))
		if(user_buckle_mob(M, user))
			return 1

//Cleanup
/atom/movable/Destroy()
	. = ..()
	unbuckle_all_mobs(force=1)

/atom/movable/proc/has_buckled_mobs()
	if(!buckled_mobs)
		return FALSE
	if(buckled_mobs.len)
		return TRUE

//procs that handle the actual buckling and unbuckling
/atom/movable/proc/buckle_mob(mob/living/M, force = 0, check_loc = 1)
	if(!buckled_mobs)
		buckled_mobs = list()

	if(!istype(M))
		return 0

	if(check_loc && M.loc != loc)
		return 0

	if((!can_buckle && !force) || M.buckled || (buckled_mobs.len >= max_buckled_mobs) || (buckle_requires_restraints && !M.restrained()) || M == src)
		return 0
	if(!M.can_buckle() && !force)
		if(M == usr)
			to_chat(M, "<span class='warning'>You are unable to buckle yourself to the [src]!</span>")
		else
			to_chat(usr, "<span class='warning'>You are unable to buckle [IDENTITY_SUBJECT(1)] to the [src]!</span>", list(M))
		return 0

	if(M.pulledby && buckle_prevents_pull)
		M.pulledby.stop_pulling()

	if(!check_loc && M.loc != loc)
		M.forceMove(loc)

	M.buckled = src
	M.setDir(dir)
	buckled_mobs |= M
	M.update_canmove()
	M.throw_alert("buckled", /obj/screen/alert/restrained/buckled, new_master = src)
	post_buckle_mob(M)

	return 1

/obj/buckle_mob(mob/living/M, force = 0, check_loc = 1)
	. = ..()
	if(.)
		if(resistance_flags & ON_FIRE) //Sets the mob on fire if you buckle them to a burning atom/movableect
			M.adjust_fire_stacks(1)
			M.IgniteMob()

/atom/movable/proc/unbuckle_mob(mob/living/buckled_mob, force=0)
	if(istype(buckled_mob) && buckled_mob.buckled == src && (buckled_mob.can_unbuckle() || force))
		. = buckled_mob
		buckled_mob.buckled = null
		buckled_mob.anchored = initial(buckled_mob.anchored)
		buckled_mob.update_canmove()
		buckled_mob.clear_alert("buckled")
		buckled_mobs -= buckled_mob

		post_buckle_mob(.)

/atom/movable/proc/unbuckle_all_mobs(force=0)
	if(!has_buckled_mobs())
		return
	for(var/m in buckled_mobs)
		unbuckle_mob(m, force)

//Handle any extras after buckling/unbuckling
//Called on buckle_mob() and unbuckle_mob()
/atom/movable/proc/post_buckle_mob(mob/living/M)
	return


//Wrapper procs that handle sanity and user feedback
/atom/movable/proc/user_buckle_mob(mob/living/M, mob/user, check_loc = 1)
	if(!in_range(user, src) || user.stat || user.restrained())
		return 0

	add_fingerprint(user)

	if(buckle_mob(M, check_loc = check_loc))
		if(M == user)
			M.visible_message(\
				"<span class='notice'>[IDENTITY_SUBJECT(1)] buckles [M.p_them()]self to [IDENTITY_SUBJECT(2)].</span>",\
				"<span class='notice'>You buckle yourself to [IDENTITY_SUBJECT(2)].</span>",\
				"<span class='italics'>You hear metal clanking.</span>", subjects=list(M, src))
		else
			M.visible_message(\
				"<span class='warning'>[IDENTITY_SUBJECT(1)] buckles [IDENTITY_SUBJECT(2)] to [IDENTITY_SUBJECT(3)]!</span>",\
				"<span class='warning'>[IDENTITY_SUBJECT(1)] buckles you to [IDENTITY_SUBJECT(3)]!</span>",\
				"<span class='italics'>You hear metal clanking.</span>", subjects=list(user, M, src))
		return 1


/atom/movable/proc/user_unbuckle_mob(mob/living/buckled_mob, mob/user)
	var/mob/living/M = unbuckle_mob(buckled_mob)
	if(M)
		if(M != user)
			M.visible_message(\
				"<span class='notice'>[IDENTITY_SUBJECT(1)] unbuckles [IDENTITY_SUBJECT(2)] from [IDENTITY_SUBJECT(3)].</span>",\
				"<span class='notice'>[IDENTITY_SUBJECT(1)] unbuckles you from [IDENTITY_SUBJECT(3)].</span>",\
				"<span class='italics'>You hear metal clanking.</span>", subjects=list(user, M, src))
		else
			M.visible_message(\
				"<span class='notice'>[IDENTITY_SUBJECT(1)] unbuckles [M.p_them()]self from [IDENTITY_SUBJECT(2)].</span>",\
				"<span class='notice'>You unbuckle yourself from [IDENTITY_SUBJECT(2)].</span>",\
				"<span class='italics'>You hear metal clanking.</span>", subjects=list(M, src))
		add_fingerprint(user)
	return M


