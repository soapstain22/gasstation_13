/datum/space_level
	var/name = "Your config settings failed, you need to fix this for the datum space levels to work"
	var/list/neigbours = list()
	var/list/traits
	var/z_value = 1 //actual z placement
	var/linkage = SELFLOOPING
	var/xi
	var/yi   //imaginary placements on the grid

/datum/space_level/New(new_z, new_name, new_linkage = SELFLOOPING, list/new_traits = list())
	z_value = new_z
	name = new_name
	traits = new_traits
	set_linkage(new_linkage)
