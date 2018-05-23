/datum/admins/key_down(datum/keyinfo/I, client/user)
	switch(I.action)
		if(ACTION_ASAY)
			user.get_admin_say()
			return
		if(ACTION_AGHOST)
			user.admin_ghost()
			return
		if(ACTION_PLAYERPANEL)
			player_panel_new()
			return
		if(ACTION_BUILDMODE)
			user.togglebuildmodeself()
			return
		if(ACTION_STEALTHMIN)
			if(user.prefs.bindings.isheld_key("Ctrl"))
				user.stealth()
			else
				user.invisimin()
			return
		if(ACTION_DSAY)
			user.get_dead_say()
			return
	..()
