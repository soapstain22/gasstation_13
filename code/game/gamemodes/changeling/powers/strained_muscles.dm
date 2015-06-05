//Strained Muscles: Ignore slowdowns at the cost of rapid damage
//Limited because of hardsuits and such; ideally, used for a quick getaway

/obj/effect/proc_holder/changeling/strained_muscles
	name = "Strained Muscles"
	desc = "We evolve the ability to reduce the acid buildup in our muscles, allowing us to move at a normal speed regardless of weight and injuries."
	helptext = "The strain will make us tired, and we will rapidly become fatigued. Cannot be used in lesser form."
	chemical_cost = 0
	dna_cost = 1
	req_human = 1
	var/stacks = 0 //Increments every 5 seconds; damage increases over time
	var/active = 0 //Whether or not you are a hedgehog

/obj/effect/proc_holder/changeling/strained_muscles/sting_action(var/mob/living/carbon/user)
	active = !active
	if(active)
		user << "<span class='notice'>Our muscles tense and strengthen.</span>"
	else
		user.status_flags -= IGNORESLOWDOWN
		user << "<span class='notice'>Our muscles relax.</span>"
		if(stacks >= 10)
			user << "<span class='danger'>We collapse in exhaustion.</span>"
			user.Weaken(3)
			user.emote("gasp")

	while(active)
		user.status_flags |= IGNORESLOWDOWN
		if(user.stat != CONSCIOUS || user.staminaloss >= 90)
			active = !active
			user << "<span class='notice'>Our muscles relax without the energy to strengthen them.</span>"
			user.Weaken(2)
			user.status_flags -= IGNORESLOWDOWN
			break

		stacks++
		//user.take_organ_damage(stacks * 0.03, 0)
		user.staminaloss += stacks * 1.3 //At first the changeling may regenerate stamina fast enough to nullify fatigue, but it will stack

		if(stacks == 11) //Warning message that the stacks are getting too high
			user << "<span class='warning'>Our legs are really starting to hurt...</span>"

		sleep(40)

	while(!active) //Damage stacks decrease fairly rapidly while not in sanic mode
		if(stacks >= 1)
			stacks--
		sleep(20)

	feedback_add_details("changeling_powers","SANIC")
	return 1
