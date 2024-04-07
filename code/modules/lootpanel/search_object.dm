/**
 * ## Search Object
 * An object for content lists. Compacted item data.
 */
/datum/search_object
	/// A string representation of the object's icon
	var/icon
	/// The name of the object
	var/name
	/// The STRING reference of the object for indexing purposes
	var/string_ref
	/// Weakref to the original object
	var/datum/weakref/item_ref
	/// Client attached to the search_object
	var/client/user_client


/datum/search_object/New(mob/user, atom/item)
	. = ..()

	item_ref = WEAKREF(item)
	name = item.name
	string_ref = REF(item)
	user_client = user.client


/datum/search_object/Destroy(force)
	icon = null
	name = null
	string_ref = null
	user_client = null

	return ..()


/// Generates the icon for the search object. This is the expensive part.
/datum/search_object/proc/generate_icon()
	var/atom/item = item_ref?.resolve()
	if(isnull(item))
		qdel(src)

	if(ismob(item) || length(item.overlays) > 2)
		icon = costly_icon2html(item, user_client, sourceonly = TRUE)
	else
		icon = icon2html(item, user_client, sourceonly = TRUE)

	if(icon)
		return TRUE
