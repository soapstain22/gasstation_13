/*
 * Holds procs designed to change one type of value, into another.
 * Contains:
 *			hex2num & num2hex
 *			file2list
 *			angle2dir
 *			angle2text
 *			worldtime2text
 *			text2dir_extended & dir2text_short
 */

//Returns an integer given a hex input, supports negative values "-ff"
//skips preceding invalid characters
//breaks when hittin invalid characters thereafter
/proc/hex2num(hex)
	. = 0
	if(istext(hex))
		var/negative = 0
		var/len = length(hex)
		for(var/i=1, i<=len, i++)
			var/num = text2ascii(hex,i)
			switch(num)
				if(48 to 57)
					num -= 48	//0-9
				if(97 to 102)
					num -= 87	//a-f
				if(65 to 70)
					num -= 55	//A-F
				if(45)
					negative = 1//-
				else
					if(num)
						break
					else
						continue
			. *= 16
			. += num
		if(negative)
			. *= -1
	return .

//Returns the hex value of a decimal number
//len == length of returned string
//if len < 0 then the returned string will be as long as it needs to be to contain the data
//Only supports positive numbers
//if an invalid number is provided, it assumes num==0
//Note, unlike previous versions, this one works from low to high <-- that way
/proc/num2hex(num, len=2)
	if(!isnum(num))
		num = 0
	num = round(abs(num))
	. = ""
	var/i=0
	while(1)
		if(len<=0)
			if(!num)
				break
		else
			if(i>=len)
				break
		var/remainder = num/16
		num = round(remainder)
		remainder = (remainder - num) * 16
		switch(remainder)
			if(9,8,7,6,5,4,3,2,1)
				. = "[remainder]" + .
			if(10,11,12,13,14,15)
				. = ascii2text(remainder+87) + .
			else
				. = "0" + .
		i++
	return .

//Splits the text of a file at seperator and returns them in a list.
/world/proc/file2list(filename, seperator="\n", trim = TRUE)
	if (trim)
		return splittext(trim(file2text(filename)),seperator)
	return splittext(file2text(filename),seperator)

//Turns a direction into text
/proc/dir2text(direction)
	switch(direction)
		if(1)
			return "north"
		if(2)
			return "south"
		if(4)
			return "east"
		if(8)
			return "west"
		if(5)
			return "northeast"
		if(6)
			return "southeast"
		if(9)
			return "northwest"
		if(10)
			return "southwest"
		else
	return

//Turns text into proper directions
/proc/text2dir(direction)
	switch(uppertext(direction))
		if("NORTH")
			return 1
		if("SOUTH")
			return 2
		if("EAST")
			return 4
		if("WEST")
			return 8
		if("NORTHEAST")
			return 5
		if("NORTHWEST")
			return 9
		if("SOUTHEAST")
			return 6
		if("SOUTHWEST")
			return 10
		else
	return

//Converts an angle (degrees) into an ss13 direction
/proc/angle2dir(degree)

	degree = SimplifyDegrees(degree)
	switch(degree)
		if(22.5) //if we're right between two possible directions, pick one randomly
			return pick(NORTH, NORTHEAST)
		if(67.5) //these have to come first so they trigger instead of any of the single-direction returns
			return pick(NORTHEAST, EAST)
		if(112.5)
			return pick(EAST, SOUTHEAST)
		if(157.5)
			return pick(SOUTHEAST, SOUTH)
		if(202.5)
			return pick(SOUTH, SOUTHWEST)
		if(247.5)
			return pick(SOUTHWEST, WEST)
		if(292.5)
			return pick(WEST, NORTHWEST)
		if(337.5)
			return pick(NORTHWEST, NORTH)
		if(337.5 to 360, 0 to 22.5) //north requires two angle ranges
			return NORTH
		if(22.5 to 67.5) //each range covers 45 degrees
			return NORTHEAST
		if(67.5 to 112.5)
			return EAST
		if(112.5 to 157.5)
			return SOUTHEAST
		if(157.5 to 202.5)
			return SOUTH
		if(202.5 to 247.5)
			return SOUTHWEST
		if(247.5 to 292.5)
			return WEST
		if(292.5 to 337.5)
			return NORTHWEST

//returns the north-zero clockwise angle in degrees, given a direction

/proc/dir2angle(D)
	switch(D)
		if(NORTH)
			return 0
		if(SOUTH)
			return 180
		if(EAST)
			return 90
		if(WEST)
			return 270
		if(NORTHEAST)
			return 45
		if(SOUTHEAST)
			return 135
		if(NORTHWEST)
			return 315
		if(SOUTHWEST)
			return 225
		else
			return null

//Returns the angle in english
/proc/angle2text(degree)
	return dir2text(angle2dir(degree))

//Converts a blend_mode constant to one acceptable to icon.Blend()
/proc/blendMode2iconMode(blend_mode)
	switch(blend_mode)
		if(BLEND_MULTIPLY)
			return ICON_MULTIPLY
		if(BLEND_ADD)
			return ICON_ADD
		if(BLEND_SUBTRACT)
			return ICON_SUBTRACT
		else
			return ICON_OVERLAY

//Converts a rights bitfield into a string
/proc/rights2text(rights, seperator="", list/adds, list/subs)
	if(rights & R_BUILDMODE)
		. += "[seperator]+BUILDMODE"
	if(rights & R_ADMIN)
		. += "[seperator]+ADMIN"
	if(rights & R_BAN)
		. += "[seperator]+BAN"
	if(rights & R_FUN)
		. += "[seperator]+FUN"
	if(rights & R_SERVER)
		. += "[seperator]+SERVER"
	if(rights & R_DEBUG)
		. += "[seperator]+DEBUG"
	if(rights & R_POSSESS)
		. += "[seperator]+POSSESS"
	if(rights & R_PERMISSIONS)
		. += "[seperator]+PERMISSIONS"
	if(rights & R_STEALTH)
		. += "[seperator]+STEALTH"
	if(rights & R_POLL)
		. += "[seperator]+POLL"
	if(rights & R_VAREDIT)
		. += "[seperator]+VAREDIT"
	if(rights & R_SOUNDS)
		. += "[seperator]+SOUND"
	if(rights & R_SPAWN)
		. += "[seperator]+SPAWN"

	for(var/verbpath in adds)
		. += "[seperator]+[verbpath]"
	for(var/verbpath in subs)
		. += "[seperator]-[verbpath]"
	return .

/proc/ui_style2icon(ui_style)
	switch(ui_style)
		if("Retro")
			return 'icons/mob/screen_retro.dmi'
		if("Plasmafire")
			return 'icons/mob/screen_plasmafire.dmi'
		if("Slimecore")
			return 'icons/mob/screen_slimecore.dmi'
		if("Operative")
			return 'icons/mob/screen_operative.dmi'
		if("Clockwork")
			return 'icons/mob/screen_clockwork.dmi'
		else
			return 'icons/mob/screen_midnight.dmi'

//colour formats
/proc/rgb2hsl(red, green, blue)
	red /= 255;green /= 255;blue /= 255;
	var/max = max(red,green,blue)
	var/min = min(red,green,blue)
	var/range = max-min

	var/hue=0;var/saturation=0;var/lightness=0;
	lightness = (max + min)/2
	if(range != 0)
		if(lightness < 0.5)
			saturation = range/(max+min)
		else
			saturation = range/(2-max-min)

		var/dred = ((max-red)/(6*max)) + 0.5
		var/dgreen = ((max-green)/(6*max)) + 0.5
		var/dblue = ((max-blue)/(6*max)) + 0.5

		if(max==red)
			hue = dblue - dgreen
		else if(max==green)
			hue = dred - dblue + (1/3)
		else
			hue = dgreen - dred + (2/3)
		if(hue < 0)
			hue++
		else if(hue > 1)
			hue--

	return list(hue, saturation, lightness)

/proc/hsl2rgb(hue, saturation, lightness)
	var/red;var/green;var/blue;
	if(saturation == 0)
		red = lightness * 255
		green = red
		blue = red
	else
		var/a;var/b;
		if(lightness < 0.5)
			b = lightness*(1+saturation)
		else
			b = (lightness+saturation) - (saturation*lightness)
		a = 2*lightness - b

		red = round(255 * hue2rgb(a, b, hue+(1/3)))
		green = round(255 * hue2rgb(a, b, hue))
		blue = round(255 * hue2rgb(a, b, hue-(1/3)))

	return list(red, green, blue)

/proc/hue2rgb(a, b, hue)
	if(hue < 0)
		hue++
	else if(hue > 1)
		hue--
	if(6*hue < 1)
		return (a+(b-a)*6*hue)
	if(2*hue < 1)
		return b
	if(3*hue < 2)
		return (a+(b-a)*((2/3)-hue)*6)
	return a

// Very ugly, BYOND doesn't support unix time and rounding errors make it really hard to convert it to BYOND time.
// returns "YYYY-MM-DD" by default
/proc/unix2date(timestamp, seperator = "-")

	if(timestamp < 0)
		return 0 //Do not accept negative values

	var/year = 1970 //Unix Epoc begins 1970-01-01
	var/dayInSeconds = 86400 //60secs*60mins*24hours
	var/daysInYear = 365 //Non Leap Year
	var/daysInLYear = daysInYear + 1//Leap year
	var/days = round(timestamp / dayInSeconds) //Days passed since UNIX Epoc
	var/tmpDays = days + 1 //If passed (timestamp < dayInSeconds), it will return 0, so add 1
	var/monthsInDays = list() //Months will be in here ***Taken from the PHP source code***
	var/month = 1 //This will be the returned MONTH NUMBER.
	var/day //This will be the returned day number.

	while(tmpDays > daysInYear) //Start adding years to 1970
		year++
		if(isLeap(year))
			tmpDays -= daysInLYear
		else
			tmpDays -= daysInYear

	if(isLeap(year)) //The year is a leap year
		monthsInDays = list(-1,30,59,90,120,151,181,212,243,273,304,334)
	else
		monthsInDays = list(0,31,59,90,120,151,181,212,243,273,304,334)

	var/mDays = 0;
	var/monthIndex = 0;

	for(var/m in monthsInDays)
		monthIndex++
		if(tmpDays > m)
			mDays = m
			month = monthIndex

	day = tmpDays - mDays //Setup the date

	return "[year][seperator][((month < 10) ? "0[month]" : month)][seperator][((day < 10) ? "0[day]" : day)]"

/proc/isLeap(y)
	return ((y) % 4 == 0 && ((y) % 100 != 0 || (y) % 400 == 0))



//Turns a Body_parts_covered bitfield into a list of organ/limb names.
//(I challenge you to find a use for this)
/proc/body_parts_covered2organ_names(bpc)
	var/list/covered_parts = list()

	if(!bpc)
		return 0

	if(bpc & FULL_BODY)
		covered_parts |= list("l_arm","r_arm","head","chest","l_leg","r_leg")

	else
		if(bpc & HEAD)
			covered_parts |= list("head")
		if(bpc & CHEST)
			covered_parts |= list("chest")
		if(bpc & GROIN)
			covered_parts |= list("chest")

		if(bpc & ARMS)
			covered_parts |= list("l_arm","r_arm")
		else
			if(bpc & ARM_LEFT)
				covered_parts |= list("l_arm")
			if(bpc & ARM_RIGHT)
				covered_parts |= list("r_arm")

		if(bpc & HANDS)
			covered_parts |= list("l_arm","r_arm")
		else
			if(bpc & HAND_LEFT)
				covered_parts |= list("l_arm")
			if(bpc & HAND_RIGHT)
				covered_parts |= list("r_arm")

		if(bpc & LEGS)
			covered_parts |= list("l_leg","r_leg")
		else
			if(bpc & LEG_LEFT)
				covered_parts |= list("l_leg")
			if(bpc & LEG_RIGHT)
				covered_parts |= list("r_leg")

		if(bpc & FEET)
			covered_parts |= list("l_leg","r_leg")
		else
			if(bpc & FOOT_LEFT)
				covered_parts |= list("l_leg")
			if(bpc & FOOT_RIGHT)
				covered_parts |= list("r_leg")

	return covered_parts



//adapted from http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/
/proc/heat2colour(temp)
	return rgb(heat2colour_r(temp), heat2colour_g(temp), heat2colour_b(temp))


/proc/heat2colour_r(temp)
	temp /= 100
	if(temp <= 66)
		. = 255
	else
		. = max(0, min(255, 329.698727446 * (temp - 60) ** -0.1332047592))


/proc/heat2colour_g(temp)
	temp /= 100
	if(temp <= 66)
		. = max(0, min(255, 99.4708025861 * log(temp) - 161.1195681661))
	else
		. = max(0, min(255, 288.1221685293 * ((temp - 60) ** -0.075148492)))


/proc/heat2colour_b(temp)
	temp /= 100
	if(temp >= 66)
		. = 255
	else
		if(temp <= 16)
			. = 0
		else
			. = max(0, min(255, 138.5177312231 * log(temp - 10) - 305.0447927307))

/proc/color2hex(color)	//web colors
	if(!color)
		return "#000000"

	switch(color)
		if("white")
			return "#FFFFFF"
		if("black")
			return "#000000"
		if("gray")
			return "#808080"
		if("brown")
			return "#A52A2A"
		if("red")
			return "#FF0000"
		if("darkred")
			return "#8B0000"
		if("crimson")
			return "#DC143C"
		if("orange")
			return "#FFA500"
		if("yellow")
			return "#FFFF00"
		if("green")
			return "#008000"
		if("lime")
			return "#00FF00"
		if("darkgreen")
			return "#006400"
		if("cyan")
			return "#00FFFF"
		if("blue")
			return "#0000FF"
		if("navy")
			return "#000080"
		if("teal")
			return "#008080"
		if("purple")
			return "#800080"
		if("indigo")
			return "#4B0082"
		else
			return "#FFFFFF"


//This is a weird one:
//It returns a list of all var names found in the string
//These vars must be in the [var_name] format
//It's only a proc because it's used in more than one place

//Takes a string and a datum
//The string is well, obviously the string being checked
//The datum is used as a source for var names, to check validity
//Otherwise every single word could technically be a variable!
/proc/string2listofvars(var/t_string, var/datum/var_source)
	if(!t_string || !var_source)
		return list()

	. = list()

	var/var_found = findtext(t_string,"\[") //Not the actual variables, just a generic "should we even bother" check
	if(var_found)
		//Find var names

		// "A dog said hi [name]!"
		// splittext() --> list("A dog said hi ","name]!"
		// jointext() --> "A dog said hi name]!"
		// splittext() --> list("A","dog","said","hi","name]!")

		t_string = replacetext(t_string,"\[","\[ ")//Necessary to resolve "word[var_name]" scenarios
		var/list/list_value = splittext(t_string,"\[")
		var/intermediate_stage = jointext(list_value, null)

		list_value = splittext(intermediate_stage," ")
		for(var/value in list_value)
			if(findtext(value,"]"))
				value = splittext(value,"]") //"name]!" --> list("name","!")
				for(var/A in value)
					if(var_source.vars.Find(A))
						. += A

//assumes format #RRGGBB #rrggbb
/proc/color_hex2num(A)
	if(!A)
		return 0
	var/R = hex2num(copytext(A,2,4))
	var/G = hex2num(copytext(A,4,6))
	var/B = hex2num(copytext(A,6,0))
	return R+G+B

//word of warning: using a matrix like this as a color value will simplify it back to a string after being set
/proc/color_hex2color_matrix(string)
	var/length = length(string)
	if(length != 7 && length != 9)
		return color_matrix_identity()
	var/r = hex2num(copytext(string, 2, 4))/255
	var/g = hex2num(copytext(string, 4, 6))/255
	var/b = hex2num(copytext(string, 6, 8))/255
	var/a = 1
	if(length == 9)
		a = hex2num(copytext(string, 8, 10))/255
	if(!isnum(r) || !isnum(g) || !isnum(b) || !isnum(a))
		return color_matrix_identity()
	return list(r,0,0,0, 0,g,0,0, 0,0,b,0, 0,0,0,a, 0,0,0,0)

//will drop all values not on the diagonal
/proc/color_matrix2color_hex(list/the_matrix)
	if(!istype(the_matrix) || the_matrix.len != 20)
		return "#ffffffff"
	return rgb(the_matrix[1]*255, the_matrix[6]*255, the_matrix[11]*255, the_matrix[16]*255)

/proc/type2parent(child)
	var/string_type = "[child]"
	var/last_slash = findlasttext(string_type, "/")
	if(last_slash == 1)
		switch(child)
			if(/datum)
				return null
			if(/obj || /mob)
				return /atom/movable
			if(/area || /turf)
				return /atom
			else
				return /datum
	return text2path(copytext(string_type, 1, last_slash))
