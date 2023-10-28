/// Attempts to open the tgui menu
/mob/verb/interact_with()
	set name = "Interact With"
	set desc = "Perform an interaction with someone."
	set category = "IC"
	set src in view(usr.client)

	var/datum/component/interaction_menu_granter/menu = usr.GetComponent(/datum/component/interaction_menu_granter)
	if(!menu)
		usr.AddComponent(/datum/component/interaction_menu_granter)
		menu = usr.GetComponent(/datum/component/interaction_menu_granter)
	if(!menu)
		to_chat(usr, span_warning("Shits broken!."))
		return

	if(!src)
		to_chat(usr, span_warning("Your interaction target is gone!"))
		return
	menu.open_menu(usr, src)

#define INTERACTION_NORMAL 0
#define INTERACTION_LEWD 1
#define INTERACTION_EXTREME 2
#define INTERACTION_CONSENT 3

/// The menu itself, only var is target which is the mob you are interacting with
/datum/component/interaction_menu_granter
	var/datum/weakref/weaktarget
	// var/mob/living/target
	/// weakrefs to mobs we are doing cool things with
	var/list/splurting_with = list()

/datum/component/interaction_menu_granter/Initialize(...)
	if(!ismob(parent))
		return COMPONENT_INCOMPATIBLE
	var/mob/parent_mob = parent
	if(!parent_mob.client)
		return COMPONENT_INCOMPATIBLE
	splurting_with |= parent_mob.ckey
	. = ..()

/datum/component/interaction_menu_granter/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_CLICK_CTRL_SHIFT, .proc/open_menu)
	RegisterSignal(parent, COMSIG_SPLURT_REVOKE, .proc/splurt_revoke)
	RegisterSignal(parent, COMSIG_SPLURT_REQUEST, .proc/splurt_request)
	RegisterSignal(parent, COMSIG_SPLURT_REPLY, .proc/handle_splurt_reply)
	RegisterSignal(parent, COMSIG_SPLURT_IS_SPLURTING, .proc/are_we_fucking)

/datum/component/interaction_menu_granter/Destroy(force, ...)
	weaktarget = null
	splurting_with.Cut()
	. = ..()

/datum/component/interaction_menu_granter/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_CLICK_CTRL_SHIFT, COMSIG_SPLURT_REQUEST))
	. = ..()

/// Clicker wants to ask us if we want to do cool things together 
/// We are clicked, clicker wants to be added to our cool list
/// why is clicked an arg here? well its simple, really
/datum/component/interaction_menu_granter/proc/splurt_request(mob/living/us, mob/living/them)
	SIGNAL_HANDLER
	if(!istype(them))
		return FALSE
	if(SEND_SIGNAL(them, COMSIG_SPLURT_IS_SPLURTING, parent, FALSE))
		to_chat(them, span_green("They already want it!"))
		to_chat(parent, span_green("[them] appreciates the consent you've given them! <3"))
		return
	INVOKE_ASYNC(src, .proc/splurt_consent, them)

/// Clicker wants to ask us if we want to do cool things together 
/// We are clicked, clicker wants to be added to our cool list
/// why is clicked an arg here? well its simple, really
/datum/component/interaction_menu_granter/proc/splurt_revoke(mob/living/clicked, mob/living/clicker)
	SIGNAL_HANDLER
	if(!istype(clicker))
		return FALSE
	if(!SEND_SIGNAL(clicker, COMSIG_SPLURT_IS_SPLURTING, parent, FALSE))
		to_chat(parent, span_green("You aren't doing anything interesting with [clicker]!"))
		return
	INVOKE_ASYNC(src, .proc/splurt_unconsent, clicker)

#define SPLURT_YES "Yes"
#define SPLURT_NO "No"
#define SPLURT_HELL_NO "No, and call an admin!"
#define SPLURT_YES_HELL_NO "Yes, and call an admin!"
#define SPLURT_REPLY_YES 1
#define SPLURT_REPLY_NO 2
#define SPLURT_REPLY_HELLNO 3

/datum/component/interaction_menu_granter/proc/splurt_consent(mob/living/clicker)
	if(!istype(clicker))
		return
	var/what_do = alert(
		parent,
		"Hey! [clicker] wants to engage in mechanical erotic roleplay adventures with you! Is this alright?",
		"Somebody likes you!",
		SPLURT_YES,
		SPLURT_NO,
		SPLURT_HELL_NO
		)
	switch(what_do)
		if(SPLURT_YES)
			splurting_with |= clicker.ckey
			to_chat(parent, span_love("You gave [clicker] the green light! You and they can do mechanical ERP!"))
			SEND_SIGNAL(clicker, COMSIG_SPLURT_REPLY, src, SPLURT_YES)
			clicker.log_message("[parent] gave [clicker] consent for lewd stuff")
		if(SPLURT_NO)
			to_chat(parent, span_userdanger("You decline [clicker]'s offer to mechanically ERP with them."))
			SEND_SIGNAL(clicker, COMSIG_SPLURT_REPLY, src, SPLURT_NO)
		if(SPLURT_HELL_NO)
			message_admins(span_boldannounce("HEY! [clicker] wanted to mechanically ERP with [parent], and [parent] said no, and is calling for an admin!"))
			to_chat(parent, span_userdanger("You decline [clicker]'s offer to mechanically ERP with them, and called for an admin! One will be with you shortly!"))
			SEND_SIGNAL(clicker, COMSIG_SPLURT_REPLY, src, SPLURT_NO)
			for(var/client/C in GLOB.admins)
				SEND_SOUND(C, sound('sound/effects/meow1.ogg')) // Someow's in troubmeow!

/datum/component/interaction_menu_granter/proc/splurt_unconsent(mob/living/them)
	if(!istype(them))
		return
	var/what_do = alert(
		parent,
		"Revoke permission for [them] to do lewd things to you?",
		"No means no",
		SPLURT_NO,
		SPLURT_YES,
		SPLURT_YES_HELL_NO // v0v
		)
	switch(what_do)
		if(SPLURT_NO)
			to_chat(parent, span_notice("Never mind!"))
			return
		if(SPLURT_YES)
			to_chat(parent, span_userdanger("You have revoked [them]'s permission to mechanically ERP with you!!!"))
			to_chat(them, span_userdanger("[parent] has revoked their permission for you to mechanically ERP with them!!!"))
		if(SPLURT_HELL_NO)
			message_admins(span_userdanger("HEY! [parent] has revoked permission for [parent] to mechanically ERP with them, and is calling for an admin for help!"))
			to_chat(parent, span_userdanger("You have revoked [them]'s permission to mechanically ERP with you, and called an admin for help!!!"))
			to_chat(them, span_userdanger("[parent] has revoked their permission for you to mechanically ERP with them!!!"))
			SEND_SIGNAL(them, COMSIG_SPLURT_REPLY, src, SPLURT_NO)
			for(var/client/C in GLOB.admins)
				SEND_SOUND(C, sound('sound/effects/meow1.ogg')) // Someow's in troubmeow!

/// the person we clicked on has replied! 
/datum/component/interaction_menu_granter/proc/handle_splurt_reply(mob/living/us, mob/living/them, reply)
	SIGNAL_HANDLER
	if(!istype(them))
		return
	switch(reply)
		if(SPLURT_REPLY_YES)
			to_chat(parent, span_love("[them] gave the green light! You and they can do mechanical ERP!"))
			splurting_with |= them.ckey
		if(SPLURT_REPLY_NO)
			to_chat(parent, span_userdanger("[them] declines your offer to mechanically ERP with you!"))
			return
		if(SPLURT_REPLY_HELLNO)
			to_chat(parent, span_userdanger("[them] declines your offer to mechanically ERP with you!"))
			return // cool

/// The one interacting is clicker, the interacted is clicked.
/// 'us' is required for compiling
/datum/component/interaction_menu_granter/proc/are_we_fucking(datum/source, mob/living/requester, send_signal = TRUE)
	if(!istype(requester))
		return FALSE
	var/datum/weakref/them = WEAKREF(requester)
	if(!(requester.ckey in splurting_with))
		return FALSE
	if(send_signal && !SEND_SIGNAL(requester, COMSIG_SPLURT_IS_SPLURTING, parent, FALSE))
		return FALSE
	return TRUE

/// The one interacting is clicker, the interacted is clicked.
/datum/component/interaction_menu_granter/proc/open_menu(mob/clicker, mob/clicked)

	// COMSIG_CLICK_CTRL_SHIFT accepts `atom`s, prevent it
	if(!istype(clicked))
		return FALSE
	// Don't cancel admin quick spawn
	if(isobserver(clicked) && check_rights_for(clicker.client, R_SPAWN))
		return FALSE
	weaktarget = WEAKREF(clicked)
	ui_interact(clicker)
	return COMSIG_MOB_CANCEL_CLICKON

/datum/component/interaction_menu_granter/ui_state(mob/user)
	// Funny admin, don't you dare be the extra funny now.
	if(user.client.holder && !user.client.holder.deadmined)
		return GLOB.always_state
	if(user == parent)
		return GLOB.conscious_state
	return GLOB.never_state

/datum/component/interaction_menu_granter/ui_interact(mob/user, datum/tgui/ui)
	if(!user.CheckActionCooldown(0.8 SECONDS))
		return // sex is combat, didnt ya know?
	user.DelayNextAction(0.8 SECONDS) // mainly cus spamming the buttons will lock up your client with sex messages

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MobInteraction", "Interactions")
		ui.open()

/proc/pref_to_num(pref)
	switch(pref)
		if("Yes")
			return 1
		if("Ask")
			return 2
		else
			return 0

/datum/component/interaction_menu_granter/ui_data(mob/user)
	. = ..()
	//Getting player
	var/mob/living/self = parent
	var/mob/living/target = GET_WEAKREF(weaktarget)
	if(!target)
		return
	//Getting info
	.["isTargetSelf"] = target == self
	.["interactingWith"] = target != self ? "Interacting with \the [target]..." : "Interacting with yourself..."
	.["selfAttributes"] = self.list_interaction_attributes(self)
	.["lust"] = self.get_lust()
	.["maxLust"] = self.get_lust_tolerance() * 3
	if(target != self)
		.["theirAttributes"] = target.list_interaction_attributes(self)
		if(HAS_TRAIT(user, TRAIT_IN_HEAT))
			.["theirLust"] = target.get_lust()
			.["theirMaxLust"] = target.get_lust_tolerance() * 3

	//Getting interactions
	var/list/sent_interactions = list()
	for(var/interaction_key in SSinteractions.interactions)
		var/datum/interaction/I = SSinteractions.interactions[interaction_key]
		if(!I.evaluate_user(self, silent = TRUE, action_check = FALSE) || !I.evaluate_target(self, target, silent = TRUE))
			continue
		if(I.user_is_target && target != self)
			continue
		var/list/interaction = list()
		interaction["key"] = I.type
		var/description = replacetext(I.description, "%COCK%", self.has_penis() ? "cock" : "strapon")
		interaction["desc"] = description
		if(istype(I, /datum/interaction/lewd))
			var/datum/interaction/lewd/O = I
			if(O.extreme)
				interaction["type"] = INTERACTION_EXTREME
			else
				interaction["type"] = INTERACTION_LEWD
		else
			interaction["type"] = INTERACTION_NORMAL
		interaction["additionalDetails"] = I.additional_details
		sent_interactions += list(interaction)
	.["interactions"] = sent_interactions
/* 
	//Get their genitals
	var/list/genitals = list()
	var/mob/living/carbon/get_genitals = self
	if(istype(get_genitals))
		for(var/obj/item/organ/genital/genital in get_genitals.internal_organs)	//Only get the genitals
			if(CHECK_BITFIELD(genital.genital_flags, GENITAL_INTERNAL))			//Not those though
				continue
			var/list/genital_entry = list()
			genital_entry["name"] = "[capitalize(genital.name)]" //Prevents code from adding a prefix
			genital_entry["key"] = REF(genital) //The key is the reference to the object
			var/visibility = "Invalid"
			if(CHECK_BITFIELD(genital.genital_visflags , GEN_VISIBLE_ALWAYS))
				visibility = "Always visible"
			else if(CHECK_BITFIELD(genital.genital_visflags , GEN_VISIBLE_NO_UNDIES))
				visibility = "Hidden by underwear"
			else if(CHECK_BITFIELD(genital.genital_visflags , GEN_VISIBLE_NEVER))
				visibility = "Always hidden"
			else
				visibility = "Hidden by clothes"
			genital_entry["visibility"] = visibility
			genital_entry["possible_choices"] = GLOB.genitals_visibility_toggles
			genital_entry["can_arouse"] = (
				!!CHECK_BITFIELD(genital.genital_flags, GENITAL_CAN_AROUSE) \
				&& !(HAS_TRAIT(get_genitals, TRAIT_PERMABONER) \
				|| HAS_TRAIT(get_genitals, TRAIT_NEVERBONER)))
			genital_entry["arousal_state"] = genital.aroused_state
			genital_entry["always_accessible"] = genital.always_accessible
			genitals += list(genital_entry)
		if(!get_genitals.getorganslot(ORGAN_SLOT_ANUS)) //SPLURT Edit
			var/simulated_ass = list()
			simulated_ass["name"] = "Anus"
			simulated_ass["key"] = "anus"
			var/visibility = "Invalid"
			switch(get_genitals.anus_exposed)
				if(1)
					visibility = "Always visible"
				if(0)
					visibility = "Hidden by underwear"
				else
					visibility = "Always hidden"
			simulated_ass["visibility"] = visibility
			simulated_ass["possible_choices"] = GLOB.genitals_visibility_toggles - GEN_VISIBLE_NO_CLOTHES
			simulated_ass["always_accessible"] = get_genitals.anus_always_accessible
			genitals += list(simulated_ass)
	.["genitals"] = genitals
*/
	var/datum/preferences/prefs = self?.client.prefs
	if(prefs)
	//Getting char prefs
		.["erp_pref"] = 			pref_to_num(prefs.erppref)
		.["noncon_pref"] = 			pref_to_num(prefs.nonconpref)
		.["vore_pref"] = 			pref_to_num(prefs.vorepref)
		.["extreme_pref"] = 		pref_to_num(prefs.extremepref)
		.["extreme_harm"] = 		pref_to_num(prefs.extremeharm)
		.["unholy_pref"] =		pref_to_num(prefs.unholypref)

	//Getting preferences
		.["verb_consent"] = 		!!CHECK_BITFIELD(prefs.toggles, VERB_CONSENT)
		.["lewd_verb_sounds"] = 	!CHECK_BITFIELD(prefs.toggles, LEWD_VERB_SOUNDS)
		.["arousable"] = 			prefs.arousable
		.["genital_examine"] = 		!!CHECK_BITFIELD(prefs.cit_toggles, GENITAL_EXAMINE)
		.["vore_examine"] = 		prefs.allow_vore_messages
		.["eating_noises"] = 		prefs.allow_eating_sounds
		.["digestion_noises"] =		prefs.allow_digestion_sounds
		.["trash_forcefeed"] = 		prefs.allow_trash_messages
		.["forced_fem"] = 			!!CHECK_BITFIELD(prefs.cit_toggles, FORCED_FEM)
		.["forced_masc"] = 			!!CHECK_BITFIELD(prefs.cit_toggles, FORCED_MASC)
		.["hypno"] = 				!!CHECK_BITFIELD(prefs.cit_toggles, HYPNO)
		.["bimbofication"] = 		!!CHECK_BITFIELD(prefs.cit_toggles, BIMBOFICATION)
		.["breast_enlargement"] = 	!!CHECK_BITFIELD(prefs.cit_toggles, BREAST_ENLARGEMENT)
		.["penis_enlargement"] =	!!CHECK_BITFIELD(prefs.cit_toggles, PENIS_ENLARGEMENT)
		.["butt_enlargement"] =		!!CHECK_BITFIELD(prefs.cit_toggles, BUTT_ENLARGEMENT)
		.["belly_inflation"] = 		!!CHECK_BITFIELD(prefs.cit_toggles, BELLY_INFLATION)
		.["never_hypno"] = 			!CHECK_BITFIELD(prefs.cit_toggles, NEVER_HYPNO)
		.["no_aphro"] = 			!CHECK_BITFIELD(prefs.cit_toggles, NO_APHRO)
		.["no_ass_slap"] = 		!CHECK_BITFIELD(prefs.cit_toggles, NO_ASS_SLAP)
		.["no_auto_wag"] = 		!CHECK_BITFIELD(prefs.cit_toggles, NO_AUTO_WAG)
		.["chastity_pref"] = 		!!CHECK_BITFIELD(prefs.cit_toggles, CHASTITY)
		.["stimulation_pref"] = 	!!CHECK_BITFIELD(prefs.cit_toggles, STIMULATION)
		.["edging_pref"] =			!!CHECK_BITFIELD(prefs.cit_toggles, EDGING)
		.["cum_onto_pref"] = 		!!CHECK_BITFIELD(prefs.cit_toggles, CUM_ONTO)

/proc/num_to_pref(num)
	switch(num)
		if(1)
			return "Yes"
		if(2)
			return "Ask"
		else
			return "No"

/datum/component/interaction_menu_granter/ui_act(action, params)
	if(..())
		return
	var/mob/living/parent_mob = parent
	switch(action)
		if("interact")
			if(!isliving(parent_mob))
				return
			var/datum/interaction/o = SSinteractions.interactions[params["interaction"]]
			if(o)
				var/mob/living/target = GET_WEAKREF(weaktarget)
				if(!target)
					return
				o.do_action(parent_mob, target)
				return TRUE
			return FALSE
		/* todo: make this work : ^ )
		if("genital")
			var/mob/living/carbon/self = parent_mob
			if("visibility" in params)
				if(params["genital"] == "anus")
					self.anus_toggle_visibility(params["visibility"])
					return TRUE
				var/obj/item/organ/genital/genital = locate(params["genital"], self.internal_organs)
				if(genital && (genital in self.internal_organs))
					genital.toggle_visibility(params["visibility"])
					return TRUE
			if("set_arousal" in params)
				var/obj/item/organ/genital/genital = locate(params["genital"], self.internal_organs)
				if(!genital || (genital \
					&& (!CHECK_BITFIELD(genital.genital_flags, GENITAL_CAN_AROUSE) \
					|| HAS_TRAIT(self, TRAIT_PERMABONER) \
					|| HAS_TRAIT(self, TRAIT_NEVERBONER))))
					return FALSE
				var/original_state = genital.aroused_state
				genital.set_aroused_state(params["set_arousal"])// i'm not making it just `!aroused_state` because
				if(original_state != genital.aroused_state)		// someone just might port skyrat's new genitals
					to_chat(self, span_userlove("[genital.aroused_state ? genital.arousal_verb : genital.unarousal_verb]."))
					. = TRUE
				else
					to_chat(self, span_userlove("You can't make that genital [genital.aroused_state ? "unaroused" : "aroused"]!"))
					. = FALSE
				genital.update_appearance()
				if(ishuman(self))
					var/mob/living/carbon/human/human = self
					human.update_genitals()
				return
			if("set_accessibility" in params)
				if(!self.getorganslot(ORGAN_SLOT_ANUS) && params["genital"] == "anus")
					self.toggle_anus_always_accessible()
					return TRUE
				var/obj/item/organ/genital/genital = locate(params["genital"], self.internal_organs)
				if(!genital)
					return FALSE
				genital.toggle_accessibility()
				return TRUE
			else
				return FALSE
			*/
		if("char_pref")
			var/datum/preferences/prefs = parent_mob.client.prefs
			var/value = num_to_pref(params["value"])
			switch(params["char_pref"])
				if("erp_pref")
					if(prefs.erppref == value)
						return FALSE
					else
						prefs.erppref = value
				if("noncon_pref")
					if(prefs.nonconpref == value)
						return FALSE
					else
						prefs.nonconpref = value
				if("vore_pref")
					if(prefs.vorepref == value)
						return FALSE
					else
						prefs.vorepref = value
				if("unholy_pref")
					if(prefs.unholypref == value)
						return FALSE
					else
						prefs.unholypref = value
				if("extreme_pref")
					if(prefs.extremepref == value)
						return FALSE
					else
						prefs.extremepref = value
						if(prefs.extremepref == "No")
							prefs.extremeharm = "No"
				if("extreme_harm")
					if(prefs.extremeharm == value)
						return FALSE
					else
						prefs.extremeharm = value
				else
					return FALSE
			prefs.save_character()
			return TRUE
		if("pref")
			var/datum/preferences/prefs = parent_mob.client.prefs
			switch(params["pref"])
				if("verb_consent")
					TOGGLE_BITFIELD(prefs.toggles, VERB_CONSENT)
				if("lewd_verb_sounds")
					TOGGLE_BITFIELD(prefs.toggles, LEWD_VERB_SOUNDS)
				if("arousable")
					prefs.arousable = !prefs.arousable
				if("genital_examine")
					TOGGLE_BITFIELD(prefs.cit_toggles, GENITAL_EXAMINE)
				if("vore_examine")
					TOGGLE_BITFIELD(prefs.cit_toggles, VOREALLOW_SEEING_BELLY_DESC)
				if("eating_noises")
					TOGGLE_BITFIELD(prefs.cit_toggles, EATING_NOISES)
				if("digestion_noises")
					prefs.allow_digestion_sounds = !prefs.allow_digestion_sounds
				if("trash_forcefeed")
					prefs.allow_trash_messages = !prefs.allow_trash_messages
				if("forced_fem")
					TOGGLE_BITFIELD(prefs.cit_toggles, FORCED_FEM)
				if("forced_masc")
					TOGGLE_BITFIELD(prefs.cit_toggles, FORCED_MASC)
				if("hypno")
					TOGGLE_BITFIELD(prefs.cit_toggles, HYPNO)
				if("bimbofication")
					TOGGLE_BITFIELD(prefs.cit_toggles, BIMBOFICATION)
				if("breast_enlargement")
					TOGGLE_BITFIELD(prefs.cit_toggles, BREAST_ENLARGEMENT)
				if("penis_enlargement")
					TOGGLE_BITFIELD(prefs.cit_toggles, PENIS_ENLARGEMENT)
				if("butt_enlargement")
					TOGGLE_BITFIELD(prefs.cit_toggles, BUTT_ENLARGEMENT)
				if("belly_inflation")
					TOGGLE_BITFIELD(prefs.cit_toggles, BELLY_INFLATION)
				if("never_hypno")
					TOGGLE_BITFIELD(prefs.cit_toggles, NEVER_HYPNO)
				if("no_aphro")
					TOGGLE_BITFIELD(prefs.cit_toggles, NO_APHRO)
				if("no_ass_slap")
					TOGGLE_BITFIELD(prefs.cit_toggles, NO_ASS_SLAP)
				if("no_auto_wag")
					TOGGLE_BITFIELD(prefs.cit_toggles, NO_AUTO_WAG)
				// SPLURT edit
				if("chastity_pref")
					TOGGLE_BITFIELD(prefs.cit_toggles, CHASTITY)
				if("stimulation_pref")
					TOGGLE_BITFIELD(prefs.cit_toggles, STIMULATION)
				if("edging_pref")
					TOGGLE_BITFIELD(prefs.cit_toggles, EDGING)
				if("cum_onto_pref")
					TOGGLE_BITFIELD(prefs.cit_toggles, CUM_ONTO)
				//
				else
					return FALSE
			//Todo: Just save when the player closes the menu or switches tabs when there are unsaved changes.
			//Also add a save button.
			prefs.save_preferences()
			return TRUE

#undef INTERACTION_NORMAL
#undef INTERACTION_LEWD
#undef INTERACTION_EXTREME
#undef INTERACTION_CONSENT
#undef SPLURT_YES
#undef SPLURT_NO
#undef SPLURT_HELL_NO
#undef SPLURT_REPLY_YES
#undef SPLURT_REPLY_NO
#undef SPLURT_REPLY_HELLNO
