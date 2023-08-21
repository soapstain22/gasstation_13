/**
 * Fluff book to hint at the cheesy grand ritual. If the user isn't a dovak- a magic user, blinds them.
 */
/obj/item/book/manual/ancient_parchment
	name = "ancient parchment"
	icon = 'icons/obj/scrolls.dmi'
	icon_state ="scroll-ancient"
	unique = TRUE
	w_class = WEIGHT_CLASS_SMALL
	starting_author = "Pelagius the Mad"
	starting_title = "Worship and Reverence of the Divine Insanity"
	starting_content = {"<html>
			<head>
			<meta http-equiv='Content-Type' content='text/html; charset=UTF-8'>
			</head>
			<body>
			<i>Most of the scroll's contents are unintelligible, plagued with mold, milk stains and a stench of spolied goat cheese so potent,</i><br>
			<i>you can barely resist turning your head to retch. What's left of the writings is vague and abstract, as if the author</i><br>
			<i>was in a mad dash to pass on their findings.</i><br><br>
			<i>However, the runes they have managed to scribe onto the parchment are oddly untouched by time, and remain distinct.</i><br>
			<i>You also discover a schema for a more widely-used Grand Ritual rune, however it is dotted with yellow circles, which in turn are</i><br>
			<i>filled with black dots. Are these supposed to be... <b>cheese wheels?..</b></i><br><br>
			<i>As you finish skimming through the wreck that is this scroll, you hear a faint snicker somewhere beyond your mind's eye...</i><br>
			</body>
			</html>"}

/obj/item/book/manual/ancient_parchment/try_reading_effect(mob/user)
	if(HAS_TRAIT(user, TRAIT_MAGICALLY_GIFTED))
		return TRUE
	if(!isliving(user))
		return TRUE
	var/mob/living/living_user = user
	if(!living_user.flash_act(intensity = 3))
		return TRUE
	return FALSE
