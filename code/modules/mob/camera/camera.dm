// Camera mob, used by AI camera and blob.

/mob/camera
	name = "camera mob"
	density = FALSE
	move_force = INFINITY
	move_resist = INFINITY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	see_in_dark = 7
	invisibility = INVISIBILITY_ABSTRACT // No one can see us
	sight = SEE_SELF
	move_on_shuttle = FALSE

/mob/camera/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_GODMODE, ROUNDSTART_TRAIT)

/mob/camera/experience_pressure_difference()
	return

/mob/camera/canUseStorage()
	return FALSE

/mob/camera/emote(act, m_type=1, message = null, intentional = FALSE, force_silence = FALSE)
	return FALSE
