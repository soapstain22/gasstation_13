// This file contains defines allowing targeting byond versions newer than the supported

//Update this whenever you need to take advantage of more recent byond features
#define MIN_COMPILER_VERSION 514
#define MIN_COMPILER_BUILD 1556
#if (DM_VERSION < MIN_COMPILER_VERSION || DM_BUILD < MIN_COMPILER_BUILD) && !defined(SPACEMAN_DMM)
//Don't forget to update this part
#error Your version of BYOND is too out-of-date to compile this project. Go to https://secure.byond.com/download and update.
#error You need version 514.1556 or higher
#endif

#if (DM_VERSION == 514 && DM_BUILD > 1575 && DM_BUILD <= 1577)
#error Your version of BYOND currently has a crashing issue that will prevent you from running Dream Daemon test servers.
#error We require developers to test their content, so an inability to test means we cannot allow the compile.
#error Please consider downgrading to 514.1575 or lower.
#endif

// Keep savefile compatibilty at minimum supported level
#if DM_VERSION >= 515
/savefile/byond_version = MIN_COMPILER_VERSION
#endif

// 515 split call for external libraries into call_ext
#if DM_VERSION < 515
#define LIBCALL call
#else
#define LIBCALL call_ext
#endif

// So we want to have compile time guarantees these methods exist on local type, unfortunately 515 killed the .proc/procname and .verb/verbname syntax so we have to use nameof()

// These are the generic defines that wrap for the either the sub-515 or post-515 syntax.

/// Call by name proc references, checks if the proc exists on this type or as a global proc.
#define PROC_REF(X) GENERIC_REF(##X, proc)
/// Call by name verb references, checks if the verb exists on this type or as a global verb.
#define VERB_REF(X) GENERIC_REF(##X, verb)

/// Call by name proc reference, checks if the proc exists on given type or as a global proc
#define TYPE_PROC_REF(TYPE, X) TYPE_GENERIC_REF(##TYPE, ##X, proc)
/// Call by name verb reference, checks if the verb exists on given type or as a global verb
#define TYPE_VERB_REF(TYPE, X) TYPE_GENERIC_REF(##TYPE, ##X, verb)

/// Call by name proc reference, checks if the proc is AN existing global proc
#define GLOBAL_PROC_REF(X) GLOBAL_GENERIC_REF(##X, proc)
/// Call by name verb reference, checks if the verb is AN existing global verb
#define GLOBAL_VERB_REF(X) GLOBAL_GENERIC_REF(##X, verb)

// Now, these are what actually performs the compile-level analysis we want.

#if DM_VERSION < 515
/// Call by name method reference, checks if the method exists on this type or as a global method
#define GENERIC_REF(X, INVOKE_METHOD) (.##INVOKE_METHOD/##X)
/// Call by name method reference, checks if the method exists on given type or as a global method
#define TYPE_GENERIC_REF(TYPE, X, INVOKE_METHOD) (##TYPE.##INVOKE_METHOD/##X)
/// Call by name method reference, checks if the proc is AN existing global proc
#define GLOBAL_GENERIC_REF(X, INVOKE_METHOD) (/##INVOKE_METHOD/##X)
#else
/// Call by name method reference, checks if the method exists on this type or as a global method
#define GENERIC_REF(X, INVOKE_METHOD) (nameof(.##INVOKE/##X))
/// Call by name method reference, checks if the method exists on given type or as a global method
#define TYPE_GENERIC_REF(TYPE, X, INVOKE_METHOD) (nameof(##TYPE.##INVOKE_METHOD/##X))
/// Call by name method reference, checks if the method is AN existing global method
#define GLOBAL_GENERIC_REF(X, INVOKE_METHOD) (/##INVOKE_METHOD/##X)
#endif
