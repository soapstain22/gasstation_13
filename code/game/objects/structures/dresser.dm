/obj/structure/dresser
	name = "dresser"
	desc = "A nicely-crafted wooden dresser. It's filled with lots of undies."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "dresser"
	density = 1
	anchored = 1

/obj/structure/dresser/attack_hand(mob/user)
	if(!Adjacent(user))//no tele-grooming
		return
	if(ishuman(user))
		var/mob/living/carbon/human/H = user

		var/choice = tginput(user, "Underwear, Undershirt, or Socks?", "Changing", nullable = TRUE, choices = list("Underwear","Undershirt","Socks"))

		if(!Adjacent(user))
			return
		switch(choice)
			if("Underwear")
				var/new_undies = tginput(user, "Select your underwear", "Changing", nullable = TRUE, choices = underwear_list)
				if(new_undies)
					H.underwear = new_undies

			if("Undershirt")
				var/new_undershirt = tginput(user, "Select your undershirt", "Changing", nullable = TRUE, choices = undershirt_list)
				if(new_undershirt)
					H.undershirt = new_undershirt
			if("Socks")
				var/new_socks = tginput(user, "Select your socks", "Changing", nullable = TRUE, choices = socks_list)
				if(new_socks)
					H.socks= new_socks

		add_fingerprint(H)
		H.update_body()