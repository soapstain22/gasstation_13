// please don't use these defines outside of this file in order to ensure a unified framework. unless you have a really good reason to make them global, then whatever
#define MAJOR_ANNOUNCEMENT_TITLE(string) ("<span class='major_announcement_title'>" + string + "</span>")
#define MAJOR_ANNOUNCEMENT_TEXT(string) ("<span class='major_announcement_text'>" + string + "</span>")

#define MINOR_ANNOUNCEMENT_TITLE(string) ("<span class='minor_announcement_text'>" + string + "</span>")
#define MINOR_ANNOUNCEMENT_TEXT(string) ("<span class='minor_announcement_text'>" + string + "</span>")

/**
 * Make a big red text announcement to
 *
 * Formatted like:
 *
 * " Message from sender "
 *
 * " Title "
 *
 * " Text "
 *
 * Arguments
 * * text - required, the text to announce
 * * title - optional, the title of the announcement.
 * * sound - optional, the sound played accompanying the announcement
 * * type - optional, the type of the announcement, for some "preset" announcement templates. See __DEFINES/announcements.dm
 * * sender_override - optional, modifies the sender of the announcement
 * * has_important_message - is this message critical to the game (and should not be overridden by station traits), or not
 * * players - a list of all players to send the message to. defaults to all players (not including new players)
 * * encode_title - if TRUE, the title will be HTML encoded
 * * encode_text - if TRUE, the text will be HTML encoded
 */
/proc/priority_announce(text, title = "", sound, type, sender_override, has_important_message = FALSE, list/mob/players, encode_title = TRUE, encode_text = TRUE)
	if(!text)
		return

	if(encode_title && title && length(title) > 0)
		title = html_encode(title)
	if(encode_text)
		text = html_encode(text)
		if(!length(text))
			return

	var/list/announcement_strings = list()

	if(!sound)
		sound = SSstation.announcer.get_rand_alert_sound()
	else if(SSstation.announcer.event_sounds[sound])
		sound = SSstation.announcer.event_sounds[sound]

	announcement += "<div class='chat_alert_default'>"

	var/header
	switch(type)
		if(ANNOUNCEMENT_TYPE_PRIORITY)
			header = MAJOR_ANNOUNCEMENT_TITLE("Priority Announcement")
			if(length(title) > 0)
				header += MINOR_ANNOUNCEMENT_TITLE(title)
		if(ANNOUNCEMENT_TYPE_CAPTAIN)
			header = MAJOR_ANNOUNCEMENT_TITLE("Captain's Announcement")
			GLOB.news_network.submit_article(text, "Captain's Announcement", "Station Announcements", null)
		if(ANNOUNCEMENT_TYPE_SYNDICATE)
			header = MAJOR_ANNOUNCEMENT_TITLE("Syndicate Captain's Announcement")
		else
			header += generate_unique_announcement_header(title, sender_override)

	else

		if(!sender_override)
			if(title == "")
				GLOB.news_network.submit_article(text, "Central Command Update", "Station Announcements", null)
			else
				GLOB.news_network.submit_article(title + "<br><br>" + text, "Central Command", "Station Announcements", null)

	///If the announcer overrides alert messages, use that message.
	if(SSstation.announcer.custom_alert_message && !has_important_message)
		announcement += "[span_priorityalert("<br>[SSstation.announcer.custom_alert_message]<br>")]"
	else
		announcement += "[span_priorityalert("<br>[text]<br>")]"

	announcement += "<br>"

	if(!players)
		players = GLOB.player_list

	var/sound_to_play = sound(sound)
	for(var/mob/target in players)
		if(!isnewplayer(target) && target.can_hear())
			to_chat(target, announcement)
			if(target.client.prefs.read_preference(/datum/preference/toggle/sound_announcements))
				SEND_SOUND(target, sound_to_play)

/proc/print_command_report(text = "", title = null, announce=TRUE)
	if(!title)
		title = "Classified [command_name()] Update"

	if(announce)
		priority_announce("A report has been downloaded and printed out at all communications consoles.", "Incoming Classified Message", SSstation.announcer.get_rand_report_sound(), has_important_message = TRUE)

	var/datum/comm_message/message = new
	message.title = title
	message.content = text

	SScommunications.send_message(message)

/// Proc that just generates a custom header based on variables fed into `priority_announce()`.area
/// Will return a string.
/proc/generate_unique_announcement_header(title, sender_override)
	var/list/returnable_strings = list()
	if(isnull(sender_override))
		returnable_strings += MAJOR_ANNOUNCEMENT_TITLE("[command_name()] Update")
	else
		returnable_strings += MAJOR_ANNOUNCEMENT_TITLE(sender_override)

	if(length(title) > 0)
		returnable_strings += MINOR_ANNOUNCEMENT_TITLE(title)

	return returnable_strings.Join("<br>")

/**
 * Sends a minor annoucement to players.
 * Minor announcements are large text, with the title in red and message in white.
 * Only mobs that can hear can see the announcements.
 *
 * message - the message contents of the announcement.
 * title - the title of the announcement, which is often "who sent it".
 * alert - whether this announcement is an alert, or just a notice. Only changes the sound that is played by default.
 * html_encode - if TRUE, we will html encode our title and message before sending it, to prevent player input abuse.
 * players - optional, a list mobs to send the announcement to. If unset, sends to all palyers.
 * sound_override - optional, use the passed sound file instead of the default notice sounds.
 * should_play_sound - Whether the notice sound should be played or not.
 */
/proc/minor_announce(message, title = "Attention:", alert, html_encode = TRUE, list/players = null, sound_override = null, should_play_sound = TRUE)
	if(!message)
		return

	if (html_encode)
		title = html_encode(title)
		message = html_encode(message)

	if(!players)
		players = GLOB.player_list

	for(var/mob/target in players)
		if(isnewplayer(target))
			continue
		if(!target.can_hear())
			continue

		to_chat(target, "<br>[span_minorannounce(title)]<br>")
		to_chat(target, "[span_minoralert(message)]<br><br><br>")
		if(should_play_sound && target.client?.prefs.read_preference(/datum/preference/toggle/sound_announcements))
			var/sound_to_play = sound_override || (alert ? 'sound/misc/notice1.ogg' : 'sound/misc/notice2.ogg')
			SEND_SOUND(target, sound(sound_to_play))
