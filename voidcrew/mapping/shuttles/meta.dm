/datum/map_template/shuttle/voidcrew/meta
	name = "Meta-class Freighter"
	suffix = "meta"
	short_name = "Meta-Class"
	part_cost = 3

	job_slots = list(
		list(
			name = "Captain",
			officer = TRUE,
			outfit = /datum/outfit/job/captain,
			slots = 1,
		),
		list(
			name = "Quartermaster",
			outfit = /datum/outfit/job/quartermaster,
			slots = 1,
		),
		list(
			name = "Medical Doctor",
			outfit = /datum/outfit/job/doctor,
			slots = 1,
		),
		list(
			name = "Station Engineer",
			outfit = /datum/outfit/job/engineer,
			slots = 1,
		),
		list(
			name = "Cook",
			outfit = /datum/outfit/job/cook,
			slots = 1,
		),
		list(
			name = "Shaft Miner",
			outfit = /datum/outfit/job/miner,
			slots = 2,
		),
		list(
			name = "Assistant",
			outfit = /datum/outfit/job/assistant,
			slots = 3,
		),
	)
