#define pick_list(FILE, KEY) (pick(strings(FILE, KEY)))
#define pick_list_replacements(FILE, KEY) (strings_replacement(FILE, KEY))
#define json_load(FILE) (json_decode(file2text(FILE)))

GLOBAL_LIST(string_cache)
GLOBAL_VAR(string_filename_current_key)


/proc/strings_replacement(filename, key)
	load_strings_file(filename)

	if((filename in SLOTH.string_cache) && (key in SLOTH.string_cache[filename]))
		var/response = pick(SLOTH.string_cache[filename][key])
		var/regex/r = regex("@pick\\((\\D+?)\\)", "g")
		response = r.Replace(response, /proc/strings_subkey_lookup)
		return response
	else
		CRASH("strings list not found: strings/[filename], index=[key]")

/proc/strings(filename as text, key as text)
	load_strings_file(filename)
	if((filename in SLOTH.string_cache) && (key in SLOTH.string_cache[filename]))
		return SLOTH.string_cache[filename][key]
	else
		CRASH("strings list not found: strings/[filename], index=[key]")

/proc/strings_subkey_lookup(match, group1)
	return pick_list(SLOTH.string_filename_current_key, group1)

/proc/load_strings_file(filename)
	SLOTH.string_filename_current_key = filename
	if(filename in SLOTH.string_cache)
		return //no work to do

	if(!SLOTH.string_cache)
		SLOTH.string_cache = new

	if(fexists("strings/[filename]"))
		SLOTH.string_cache[filename] = json_load("strings/[filename]")
	else
		CRASH("file not found: strings/[filename]")
