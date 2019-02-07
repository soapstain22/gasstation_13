/datum/datum_topic/admins_topic/make_antag
	keyword= "makeAntag"
	log = FALSE

/datum/datum_topic/admins_topic/make_antag/TryRun(list/input,var/datum/admins/A)
    if(!check_rights(R_ADMIN))
        return
    if (!SSticker.mode)
        to_chat(usr, "<span class='danger'>Not until the round starts!</span>")
        return
    switch(input["makeAntag"])
        if("traitors")
            if(A.makeTraitors())
                message_admins("[key_name_admin(usr)] created traitors.")
                log_admin("[key_name(usr)] created traitors.")
            else
                message_admins("[key_name_admin(usr)] tried to create traitors. Unfortunately, there were no candidates available.")
                log_admin("[key_name(usr)] failed to create traitors.")
        if("changelings")
            if(A.makeChangelings())
                message_admins("[key_name(usr)] created changelings.")
                log_admin("[key_name(usr)] created changelings.")
            else
                message_admins("[key_name_admin(usr)] tried to create changelings. Unfortunately, there were no candidates available.")
                log_admin("[key_name(usr)] failed to create changelings.")
        if("revs")
            if(A.makeRevs())
                message_admins("[key_name(usr)] started a revolution.")
                log_admin("[key_name(usr)] started a revolution.")
            else
                message_admins("[key_name_admin(usr)] tried to start a revolution. Unfortunately, there were no candidates available.")
                log_admin("[key_name(usr)] failed to start a revolution.")
        if("cult")
            if(A.makeCult())
                message_admins("[key_name(usr)] started a cult.")
                log_admin("[key_name(usr)] started a cult.")
            else
                message_admins("[key_name_admin(usr)] tried to start a cult. Unfortunately, there were no candidates available.")
                log_admin("[key_name(usr)] failed to start a cult.")
        if("wizard")
            message_admins("[key_name(usr)] is creating a wizard...")
            if(A.makeWizard())
                message_admins("[key_name(usr)] created a wizard.")
                log_admin("[key_name(usr)] created a wizard.")
            else
                message_admins("[key_name_admin(usr)] tried to create a wizard. Unfortunately, there were no candidates available.")
                log_admin("[key_name(usr)] failed to create a wizard.")
        if("nukeops")
            message_admins("[key_name(usr)] is creating a nuke team...")
            if(A.makeNukeTeam())
                message_admins("[key_name(usr)] created a nuke team.")
                log_admin("[key_name(usr)] created a nuke team.")
            else
                message_admins("[key_name_admin(usr)] tried to create a nuke team. Unfortunately, there were not enough candidates available.")
                log_admin("[key_name(usr)] failed to create a nuke team.")
        if("ninja")
            message_admins("[key_name(usr)] spawned a ninja.")
            log_admin("[key_name(usr)] spawned a ninja.")
            A.makeSpaceNinja()
        if("aliens")
            message_admins("[key_name(usr)] started an alien infestation.")
            log_admin("[key_name(usr)] started an alien infestation.")
            A.makeAliens()
        if("deathsquad")
            message_admins("[key_name(usr)] is creating a death squad...")
            if(A.makeDeathsquad())
                message_admins("[key_name(usr)] created a death squad.")
                log_admin("[key_name(usr)] created a death squad.")
            else
                message_admins("[key_name_admin(usr)] tried to create a death squad. Unfortunately, there were not enough candidates available.")
                log_admin("[key_name(usr)] failed to create a death squad.")
        if("blob")
            var/strength = input("Set Blob Resource Gain Rate","Set Resource Rate",1) as num|null
            if(!strength)
                return
            message_admins("[key_name(usr)] spawned a blob with base resource gain [strength].")
            log_admin("[key_name(usr)] spawned a blob with base resource gain [strength].")
            new/datum/round_event/ghost_role/blob(TRUE, strength)
        if("centcom")
            message_admins("[key_name(usr)] is creating a CentCom response team...")
            if(A.makeEmergencyresponseteam())
                message_admins("[key_name(usr)] created a CentCom response team.")
                log_admin("[key_name(usr)] created a CentCom response team.")
            else
                message_admins("[key_name_admin(usr)] tried to create a CentCom response team. Unfortunately, there were not enough candidates available.")
                log_admin("[key_name(usr)] failed to create a CentCom response team.")
        if("abductors")
            message_admins("[key_name(usr)] is creating an abductor team...")
            if(A.makeAbductorTeam())
                message_admins("[key_name(usr)] created an abductor team.")
                log_admin("[key_name(usr)] created an abductor team.")
            else
                message_admins("[key_name_admin(usr)] tried to create an abductor team. Unfortunatly there were not enough candidates available.")
                log_admin("[key_name(usr)] failed to create an abductor team.")
        if("clockcult")
            if(A.makeClockCult())
                message_admins("[key_name(usr)] started a clockwork cult.")
                log_admin("[key_name(usr)] started a clockwork cult.")
            else
                message_admins("[key_name_admin(usr)] tried to start a clockwork cult. Unfortunately, there were no candidates available.")
                log_admin("[key_name(usr)] failed to start a clockwork cult.")
        if("revenant")
            if(A.makeRevenant())
                message_admins("[key_name(usr)] created a revenant.")
                log_admin("[key_name(usr)] created a revenant.")
            else
                message_admins("[key_name_admin(usr)] tried to create a revenant. Unfortunately, there were no candidates available.")
                log_admin("[key_name(usr)] failed to create a revenant.")