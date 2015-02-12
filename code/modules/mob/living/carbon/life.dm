//drunkness defines
#define TIPSY 50
#define DRUNK 100
#define VERYDRUNK 175
#define WASTED 250

/mob/living/carbon/proc/get_breath_from_internal(volume_needed)
	if(internal)
		if (!contents.Find(internal))
			internal = null
		if (!wear_mask || !(wear_mask.flags & MASKINTERNALS) )
			internal = null
		if(internal)
			if (internals)
				internals.icon_state = "internal1"
			return internal.remove_air_volume(volume_needed)
		else
			if (internals)
				internals.icon_state = "internal0"
	return

/mob/living/carbon/proc/handle_nausea()
	if(!stat)
		if(getToxLoss() >= 40)
			nausea++
		if(nausea > 0) //so prob isn't rolling on every tick
			if(prob(6)) //slowly reduce nausea over time
				nausea--
			if(nausea >= 12) //not feeling so good
				if(prob(8))
					visible_message("<font color='green'>[src] retches!</font>", \
							"<font color='green'><b>you retch!</b></font>")
			if(nausea >= 25) //vomiting
				Stun(max(2, 6 - (nutrition / 100)))

				visible_message("<span class='danger'>[src] throws up!</span>", \
						"<span class='userdanger'>you throw up!</span>")
				playsound(loc, 'sound/effects/splat.ogg', 50, 1)

				var/turf/location = loc
				if(istype(location, /turf/simulated))
					location.add_vomit_floor(src, 1)

				if(nutrition >= 40)
					nutrition -= 20
				adjustToxLoss(-3)

				//feelin fine after
				nausea = 0

/mob/living/carbon/proc/handle_drunkness()
	if(drunkness > 0)
		if(prob(25))
			drunkness--
			boozeticks++ //metabolization

		if(drunkness >= (TIPSY * boozetolerance))
			jitteriness = max(jitteriness - 5, 0)
			slurring = 4
			Dizzy(5)
			if(prob(7))
				emote("burp")

		if(drunkness >= (DRUNK * boozetolerance))
			if(prob(33))
				confused += 2

		if(drunkness >= (VERYDRUNK * boozetolerance))
			nausea++
			if(prob(7) && !stat && !lying)
				Weaken(2)
				visible_message("<span class='danger'>[src] trips over their own feet!</span>")

		if(drunkness >= (WASTED * boozetolerance))
			adjustToxLoss(1)
			sleeping = min(sleeping + 2, 10)

	if(boozeticks >= (300 * boozetolerance)) //building tolerance
		boozeticks = 0
		boozetolerance = min(boozetolerance + 1, 5)