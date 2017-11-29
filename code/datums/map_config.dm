//used for holding information about unique properties of maps
//feed it json files that match the datum layout
//defaults to box
//  -Cyberboss

/datum/map_config
	var/config_filename = "_maps/boxstation.json"
	var/map_name = "Box Station"
	var/map_path = "map_files/BoxStation"
	var/map_file = "BoxStation.dmm"

	var/minetype = "lavaland"

	//Order matters here.
	var/list/traits = STATION_TRAITS
	var/defaulted = TRUE    //if New failed

	var/config_max_users = 0
	var/config_min_users = 0
	var/voteweight = 1
	var/allow_custom_shuttles = TRUE

/datum/map_config/New(filename = "data/next_map.json", default_to_box, delete_after)
	if(default_to_box)
		return
	LoadConfig(filename)
	if(delete_after)
		fdel(filename)

/datum/map_config/proc/LoadConfig(filename)
	if(!fexists(filename))
		log_world("map_config not found: [filename]")
		return

	var/json = file(filename)
	if(!json)
		log_world("Could not open map_config: [filename]")
		return

	json = file2text(json)
	if(!json)
		log_world("map_config is not text: [filename]")
		return

	json = json_decode(json)
	if(!json)
		log_world("map_config is not json: [filename]")
		return

	if(!ValidateJSON(json))
		log_world("map_config failed to validate for above reason: [filename]")
		return

	config_filename = filename

	map_name = json["map_name"]
	map_path = json["map_path"]
	map_file = json["map_file"]

	minetype = json["minetype"] || minetype
	allow_custom_shuttles = json["allow_custom_shuttles"] != FALSE

	var/list/jtcl = json["traits"]

	if(jtcl && jtcl != "default")
		traits.Cut()
		for(var/I in jtcl)
			traits[I] = TRUE

	defaulted = FALSE

#define CHECK_EXISTS(X) if(!istext(json[X])) { log_world(X + "missing from json!"); return; }
/datum/map_config/proc/ValidateJSON(list/json)
	CHECK_EXISTS("map_name")
	CHECK_EXISTS("map_path")
	CHECK_EXISTS("map_file")

	var/path = GetFullMapPath(json["map_path"], json["map_file"])
	if(!fexists(path))
		log_world("Map file ([path]) does not exist!")
		return
	return TRUE
#undef CHECK_EXISTS

/datum/map_config/proc/GetFullMapPath(mp = map_path, mf = map_file)
	return "_maps/[mp]/[mf]"

/datum/map_config/proc/MakeNextMap()
	return config_filename == "data/next_map.json" || fcopy(config_filename, "data/next_map.json")
