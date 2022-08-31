GLOBAL_LIST_EMPTY(antagonist_teams)

//A barebones antagonist team.
/datum/team
	///Name of the entire Team
	var/name = "\improper Team"
	///What members are considered in the roundend report (ex: 'cultists')
	var/member_name = "member"
	///Whether the team shows up in the roundend report.
	var/show_roundend_report = TRUE

	///List of all members in the team
	var/list/datum/mind/members = list()
	///Common objectives, these won't be added or removed automatically, subtypes handle this, this is here for bookkeeping purposes.
	var/list/datum/objective/objectives = list()

/datum/team/New(starting_members)
	. = ..()
	GLOB.antagonist_teams += src
	if(starting_members)
		if(islist(starting_members))
			for(var/datum/mind/M in starting_members)
				add_member(M)
		else
			add_member(starting_members)

/datum/team/Destroy(force, ...)
	GLOB.antagonist_teams -= src
	members = null
	objectives = null
	return ..()

/datum/team/proc/add_member(datum/mind/new_member)
	members |= new_member

/datum/team/proc/remove_member(datum/mind/member)
	members -= member

/datum/team/proc/add_objective(datum/objective/new_objective, needs_target = FALSE)
	new_objective.team = src
	if(needs_target)
		new_objective.find_target(dupe_search_range = list(src))
	new_objective.update_explanation_text()
	objectives += new_objective

//Display members/victory/failure/objectives for the team
/datum/team/proc/roundend_report()
	var/list/report = list()

	report += "<span class='header'>\The [name]:</span>"
	report += "The [member_name]s were:"
	report += printplayerlist(members)

	if(objectives.len)
		report += "<span class='header'>Team had following objectives:</span>"
		var/win = TRUE
		var/objective_count = 1
		for(var/datum/objective/objective as anything in objectives)
			if(objective.check_completion())
				report += "<B>Objective #[objective_count]</B>: [objective.explanation_text] [span_greentext("Success!")]"
			else
				report += "<B>Objective #[objective_count]</B>: [objective.explanation_text] [span_redtext("Fail.")]"
				win = FALSE
			objective_count++
		if(win)
			report += span_greentext("The [name] was successful!")
		else
			report += span_redtext("The [name] have failed!")


	return "<div class='panel redborder'>[report.Join("<br>")]</div>"

/datum/team/proc/get_team_antags(antag_datum, include_subtypes = TRUE)
	var/datum/list = list()
	for(var/datum/antagonist/antagonists as anything in GLOB.antagonists)
		if(!(antagonists.owner in members))
			continue

		if(include_subtypes && istype(antagonists, antag_datum))
			list += antagonists
		else if(antagonists.type == antag_datum)
			list += antagonists

	return list

//Builds section for the team
/datum/team/proc/antag_listing_entry()
	//NukeOps:
	// Jim (Status) FLW PM TP
	// Joe (Status) FLW PM TP
	//Disk:
	// Deep Space FLW
	var/list/parts = list()
	parts += "<b>[antag_listing_name()]</b><br>"
	parts += "<table cellspacing=5>"
	for(var/datum/antagonist/A in get_team_antags())
		parts += A.antag_listing_entry()
	parts += "</table>"
	return parts.Join()

///Custom names for individuals in a team
/datum/team/proc/antag_listing_name()
	return name

