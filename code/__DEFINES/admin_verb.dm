/**
 * This is the only macro you should use to define admin verbs.
 * It will define the verb and the verb holder for you.
 * Using it is very simple:
 *  ADMIN_VERB(verb_path, R_PERM, "Name", "Description", "Admin.Category", args...)
 * This sets up all of the above and also acts as syntatic sugar as a verb delcaration for the verb itself.
 * Note that the verb args have an injected `client/user` argument that is the user that called the verb.
 * Do not use usr in your verb; technically you can but I'll kill you.
 */
#define ADMIN_VERB(verb_path_name, verb_permissions, verb_name, verb_desc, verb_category, verb_args...) \
/datum/admin_verb/##verb_path_name \
{ \
	name = ##verb_name; \
	description = ##verb_desc; \
	category = ##verb_category; \
	permissions = ##verb_permissions; \
	verb_path = /client/proc/__avd_##verb_path_name; \
}; \
/client/proc/__avd_##verb_path_name(##verb_args) \
{ \
	set name = ##verb_name; \
	set desc = ##verb_desc; \
	set hidden = FALSE; /* this is explicitly needed as the proc begins with an underscore */ \
	set category = ##verb_category; \
	var/list/_verb_args = list(usr, /datum/admin_verb/##verb_path_name); \
	_verb_args += args; \
	SSadmin_verbs.dynamic_invoke_verb(arglist(_verb_args)); \
}; \
/datum/admin_verb/##verb_path_name/__avd_do_verb(client/user, ##verb_args)

/// Used to define a special check to determine if the admin verb should exist at all. Useful for verbs such as play sound which require configuration.
#define ADMIN_VERB_CUSTOM_EXIST_CHECK(verb_path_name) \
/datum/admin_verb/##verb_path_name/__avd_check_should_exist()

// These are put here to prevent the "procedure override precedes definition" error.
/datum/admin_verb/proc/__avd_get_verb_path()
	CRASH("__avd_get_verb_path not defined. use the macro")
/datum/admin_verb/proc/__avd_do_verb(...)
	CRASH("__avd_do_verb not defined. use the macro")
/datum/admin_verb/proc/__avd_check_should_exist()
	return TRUE

/*
 * This is an example of how to use the above macro:
 * ```
 * ADMIN_VERB(name_of_verb, R_ADMIN, "Verb Name", "Verb Desc", "Verb Category", mob/target in world)
 *     to_chat(user, "Hello!")
 * ```
 * Note the implied `client/user` argument that is injected into the verb.
 * Also note that byond is shit and you cannot multi-line the macro call.
 */

/// Use this to mark your verb as not having a description. Should ONLY be used if you are also hiding the verb!
#define ADMIN_VERB_NO_DESCRIPTION ""
/// Used to verbs you do not want to show up in the master verb panel.
#define ADMIN_CATEGORY_HIDDEN null

// Admin verb categories
#define ADMIN_CATEGORY_MAIN "Admin"
#define ADMIN_CATEGORY_EVENTS "Admin.Events"
#define ADMIN_CATEGORY_FUN "Admin.Fun"
#define ADMIN_CATEGORY_GAME "Admin.Game"

// Special categories that are seperated
#define ADMIN_CATEGORY_DEBUG "Debug"
#define ADMIN_CATEGORY_SERVER "Server"
#define ADMIN_CATEGORY_OBJECT "Object"
