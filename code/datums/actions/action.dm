/**
 * # Action system
 *
 * A simple base for an modular behavior attached to atom or datum.
 */
/datum/action
	/// The name of the action
	var/name = "Generic Action"
	/// The description of what the action does
	var/desc
	/// The target the action is attached to. If the target datum is deleted, the action is as well.
	/// Set in New() via the proc link_to(). PLEASE set a target if you're making an action
	var/datum/target
	/// The screen button shown on our owner's actual screen. What they click to call Trigger() on the action.
	var/atom/movable/screen/movable/action_button/button = null
	/// This is who currently owns the action, and most often, this is who is using the action if it is triggered
	/// This can be the same as "target" but is not ALWAYS the same - this is set and unset with Grant() and Remove()
	var/mob/owner
	/// Flags that will determine of the owner / user of the action can... use the action
	var/check_flags = NONE
	/// The style the button's tooltips appear to be
	var/buttontooltipstyle = ""
	/// Whether the button becomes transparent when it can't be used or just reddened
	var/transparent_when_unavailable = TRUE
	/// This is the file for the BACKGROUND icon of the button
	var/button_icon = 'icons/mob/actions/backgrounds.dmi'
	/// This is the icon state state for the BACKGROUND icon of the button
	var/background_icon_state = ACTION_BUTTON_DEFAULT_BACKGROUND
	/// This is the file for the icon that appears OVER the button background
	var/icon_icon = 'icons/hud/actions.dmi'
	/// This is the icon state for the icon that appears OVER the button background
	var/button_icon_state = "default"

/datum/action/New(Target)
	link_to(Target)
	button = new
	button.linked_action = src
	button.name = name
	button.actiontooltipstyle = buttontooltipstyle
	if(desc)
		button.desc = desc

/// Links the passed target to our action, registering any relevant signals
/datum/action/proc/link_to(Target)
	target = Target
	RegisterSignal(target, COMSIG_PARENT_QDELETING, .proc/clear_ref, override = TRUE)

	if(isatom(target))
		RegisterSignal(target, COMSIG_ATOM_UPDATED_ICON, .proc/on_target_update_icon)

	if(istype(target, /datum/mind))
		RegisterSignal(target, COMSIG_MIND_TRANSFERRED, .proc/on_target_mind_swapped)

/datum/action/Destroy()
	if(owner)
		Remove(owner)
	target = null
	QDEL_NULL(button)
	return ..()

/// Granst the action to the passed mob, making it the owner
/datum/action/proc/Grant(mob/M)
	if(M)
		if(owner)
			if(owner == M)
				return
			Remove(owner)
		owner = M
		RegisterSignal(owner, COMSIG_PARENT_QDELETING, .proc/clear_ref, override = TRUE)

		//button id generation
		var/counter = 0
		var/bitfield = 0
		for(var/datum/action/A in M.actions)
			if(A.name == name && A.button.id)
				counter += 1
				bitfield |= A.button.id
		bitfield = ~bitfield
		var/bitflag = 1
		for(var/i in 1 to (counter + 1))
			if(bitfield & bitflag)
				button.id = bitflag
				break
			bitflag *= 2

		LAZYADD(M.actions, src)
		if(M.client)
			M.client.screen += button
			button.locked = M.client.prefs.read_preference(/datum/preference/toggle/buttons_locked) || button.id ? M.client.prefs.action_buttons_screen_locs["[name]_[button.id]"] : FALSE //even if it's not defaultly locked we should remember we locked it before
			button.moved = button.id ? M.client.prefs.action_buttons_screen_locs["[name]_[button.id]"] : FALSE
		M.update_action_buttons()
	else
		Remove(owner)

/// Signal proc that clears any references based on the owner or target deleting
/// If the owner's deleted, we will simply remove from them, but if the target's deleted, we will self-delete
/datum/action/proc/clear_ref(datum/ref)
	SIGNAL_HANDLER
	if(ref == owner)
		Remove(owner)
	if(ref == target)
		qdel(src)

/// Remove the passed mob from being owner of our action
/datum/action/proc/Remove(mob/M)
	for(var/datum/weakref/reference as anything in sharers)
		var/mob/freeloader = reference.resolve()
		if(!freeloader)
			continue
		Unshare(freeloader)
	sharers = null
	if(M)
		if(M.client)
			M.client.screen -= button
		LAZYREMOVE(M.actions, src)
		M.update_action_buttons()
	if(owner)
		UnregisterSignal(owner, COMSIG_PARENT_QDELETING)
		if(target == owner)
			RegisterSignal(target, COMSIG_PARENT_QDELETING, .proc/clear_ref)
		owner = null
	if(button)
		button.moved = FALSE //so the button appears in its normal position when given to another owner.
		button.locked = FALSE
		button.id = null

/// Actually triggers the effects of the action.
/// Called when the on-screen button is clicked, for example.
/datum/action/proc/Trigger(trigger_flags)
	if(!IsAvailable())
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_ACTION_TRIGGER, src) & COMPONENT_ACTION_BLOCK_TRIGGER)
		return FALSE
	return TRUE

/// Whether our action is currently available to use or not
/datum/action/proc/IsAvailable()
	if(!owner)
		return FALSE
	if((check_flags & AB_CHECK_HANDS_BLOCKED) && HAS_TRAIT(owner, TRAIT_HANDS_BLOCKED))
		return FALSE
	if((check_flags & AB_CHECK_IMMOBILE) && HAS_TRAIT(owner, TRAIT_IMMOBILIZED))
		return FALSE
	if((check_flags & AB_CHECK_LYING) && isliving(owner))
		var/mob/living/action_user = owner
		if(action_user.body_position == LYING_DOWN)
			return FALSE
	if((check_flags & AB_CHECK_CONSCIOUS) && owner.stat != CONSCIOUS)
		return FALSE
	return TRUE

/// Updates the icon of the button on the owner's screen
/datum/action/proc/UpdateButtonIcon(status_only = FALSE, force = FALSE)
	if(button)
		if(!status_only)
			button.name = name
			button.desc = desc
			if(owner?.hud_used && background_icon_state == ACTION_BUTTON_DEFAULT_BACKGROUND)
				var/list/settings = owner.hud_used.get_action_buttons_icons()
				if(button.icon != settings["bg_icon"])
					button.icon = settings["bg_icon"]
				if(button.icon_state != settings["bg_state"])
					button.icon_state = settings["bg_state"]
			else
				if(button.icon != button_icon)
					button.icon = button_icon
				if(button.icon_state != background_icon_state)
					button.icon_state = background_icon_state

			ApplyIcon(button, force)

		if(!IsAvailable())
			button.color = transparent_when_unavailable ? rgb(128,0,0,128) : rgb(128,0,0)
		else
			button.color = rgb(255,255,255,255)
			return TRUE

/// Applies our button icon over top the background icon of the action
/datum/action/proc/ApplyIcon(atom/movable/screen/movable/action_button/current_button, force = FALSE)
	if(icon_icon && button_icon_state && ((current_button.button_icon_state != button_icon_state) || force))
		current_button.cut_overlays(TRUE)
		current_button.add_overlay(mutable_appearance(icon_icon, button_icon_state))
		current_button.button_icon_state = button_icon_state

/// Signal proc for COMSIG_ATOM_UPDATED_ICON - for atoms, also updates our button icon on icon updates
/datum/action/proc/on_target_update_icon(datum/source)
	SIGNAL_HANDLER

	UpdateButtonIcon()

/// Signal proc for COMSIG_MIND_TRANSFERRED - for minds, transfers our action to our new mob on mind transfer
/datum/action/proc/on_target_mind_swapped(datum/mind/source, mob/old_current)
	SIGNAL_HANDLER

	// MELBERT TODO removed the remove() since it shouldn't be needed, also check what happens with ghosts
	Grant(source.current)
