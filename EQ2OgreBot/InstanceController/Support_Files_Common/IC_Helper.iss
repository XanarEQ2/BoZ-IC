; Add the following to IC files in order to use these support functions
; #include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"

/**********************************************************************************************************
****************************************    Setup Functions    ********************************************
***********************************************************************************************************/

variable bool GroupedWithFighter=FALSE
variable bool GroupedWithScout=FALSE
variable bool GroupedWithMage=FALSE
variable bool GroupedWithPriest=FALSE

; Set various settings at the start when running an instance
; 	(these may be modified for certain scripts, so make sure everything has the correct default value)
function SetInitialInstanceSettings()
{
	; Disable "Smart Loot" (can comment this out if you want to use it)
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_loot_lo_smartassign FALSE TRUE
	; Assist
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_settings_assist FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notfighter checkbox_settings_assist TRUE TRUE
	; Enable Heroic Setups
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_grindoptions TRUE TRUE
	; Cast Stack
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_ca FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_namedca FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_items FALSE TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+priest "Cure" TRUE TRUE
	; Enable Cures and Interrupts
	call SetupAllCures "TRUE"
	call SetupAllInterrupts "TRUE"
	; Auto Target
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_autotarget_enabled TRUE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_autotarget_outofcombatscanning TRUE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notfighter checkbox_autotarget_enabled FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notfighter checkbox_autotarget_outofcombatscanning FALSE TRUE
	; Disable Pack Pony, can be triggered at the wrong time and cause problems
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_packpony_enable FALSE TRUE
	; Set Initial HO Settings
	call SetInitialHOSettings
}

function SetupAllCures(bool EnableCures)
{
	; Used for disabling all curing during certain fights that have detrimentals that need to not be cured
	; Add any class-specific abilities that cure (and aren't disabled by Disable CS_Cure) to this list
	variable bool SetCastStack
	SetCastStack:Set[!${EnableCures}]
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_cure ${SetCastStack} TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_curecurse ${SetCastStack} TRUE
	; Setup class-specific abilities with cures attached
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Crusader's Judgement" ${EnableCures} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Zealous Smite" ${EnableCures} TRUE
}

function SetupAllInterrupts(bool EnableInterrupts)
{
	; Used for disabling all interrupts during certain fights that need you to not interrupt
	; Add any class-specific abilities that interrupt (and aren't disabled by No Interrupts) to this list
	variable bool SetCastStack
	SetCastStack:Set[!${EnableInterrupts}]
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_nointerrupts ${SetCastStack} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+swashbuckler "Daring Advance" ${EnableInterrupts} TRUE
	if !${EnableInterrupts}
	{
		oc !ci -CancelMaintainedForWho igw:${Me.Name}+swashbuckler "Daring Advance"
	}
}

function SetInitialHOSettings()
{
	; Set HO default values to clear any custom settings
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disable_ho_abilities FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_ho_start FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+ranger checkbox_settings_ho_starter FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-ranger checkbox_settings_ho_starter TRUE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+ranger checkbox_settings_ho_wheel FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-ranger checkbox_settings_ho_wheel TRUE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_ho_wheel_offensive_only FALSE TRUE
	; Enable all fighter icons
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_settings_disable_fighter_hoicon_0 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_settings_disable_fighter_hoicon_1 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_settings_disable_fighter_hoicon_2 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_settings_disable_fighter_hoicon_3 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_settings_disable_fighter_hoicon_4 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_settings_disable_fighter_hoicon_5 FALSE TRUE
	; Enable all priest icons
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+priest checkbox_settings_disable_priest_hoicon_12 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+priest checkbox_settings_disable_priest_hoicon_13 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+priest checkbox_settings_disable_priest_hoicon_14 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+priest checkbox_settings_disable_priest_hoicon_15 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+priest checkbox_settings_disable_priest_hoicon_16 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+priest checkbox_settings_disable_priest_hoicon_17 FALSE TRUE
	; Enable all mage icons
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+mage checkbox_settings_disable_mage_hoicon_24 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+mage checkbox_settings_disable_mage_hoicon_25 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+mage checkbox_settings_disable_mage_hoicon_26 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+mage checkbox_settings_disable_mage_hoicon_27 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+mage checkbox_settings_disable_mage_hoicon_28 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+mage checkbox_settings_disable_mage_hoicon_29 FALSE TRUE
	; Enable all scout icons
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+scout checkbox_settings_disable_scout_hoicon_36 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+scout checkbox_settings_disable_scout_hoicon_37 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+scout checkbox_settings_disable_scout_hoicon_38 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+scout checkbox_settings_disable_scout_hoicon_39 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+scout checkbox_settings_disable_scout_hoicon_40 FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+scout checkbox_settings_disable_scout_hoicon_41 FALSE TRUE
}

; Set HO Start/Starter/Wheel for group members based on Mode and group setup
function HO(string Mode, bool Exclude_Healer1=TRUE)
{
	; Check Group Setup
	call CheckGroupSetup
	; Set Start based on Mode
	switch ${Mode}
	{
		case Disable
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_ho_start FALSE TRUE
			break
		case All
			if (!${Obj_OgreIH.DuoMode} && !${Obj_OgreIH.SoloMode})
			{
				; For Heroic, enable HO for all except ranger
				; (modify as desired, idea was to have main dps just focus on dps and let another scout deal with HO)
				oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-ranger checkbox_settings_ho_start TRUE TRUE
				oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+ranger checkbox_settings_ho_start FALSE TRUE
			}
			else
			{
				; For fighter + scout duo, let fighter start and do starter (only have scout do wheel)
				if (${GroupedWithFighter} && ${GroupedWithScout})
				{
					oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+scout checkbox_settings_ho_start FALSE TRUE
					oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notscout checkbox_settings_ho_start TRUE TRUE
					oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+scout checkbox_settings_ho_starter FALSE TRUE
					oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notscout checkbox_settings_ho_starter TRUE TRUE
					oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_ho_wheel TRUE TRUE
					return
				}
				; For priest + scout duo, let priest Start
				elseif (${GroupedWithPriest} && ${GroupedWithScout})
				{
					oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+priest checkbox_settings_ho_start TRUE TRUE
					oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notpriest checkbox_settings_ho_start FALSE TRUE
				}
				; For mage + scout duo, let scout Start
				elseif (${GroupedWithMage} && ${GroupedWithScout})
				{
					oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+scout checkbox_settings_ho_start TRUE TRUE
					oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notscout checkbox_settings_ho_start FALSE TRUE
				}
				; For other combinations, let any class Start
				else
					oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_ho_start TRUE TRUE
			}
			break
		case Scout
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+scout checkbox_settings_ho_start TRUE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notscout checkbox_settings_ho_start FALSE TRUE
			break
		case Priest	
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+priest checkbox_settings_ho_start TRUE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notpriest checkbox_settings_ho_start FALSE TRUE
			break
		case Mage
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+mage checkbox_settings_ho_start TRUE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notmage checkbox_settings_ho_start FALSE TRUE
			break
		case Fighter
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_settings_ho_start TRUE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notfighter checkbox_settings_ho_start FALSE TRUE
			break
		default
			wait 1
	}
	; Set Starter and Wheel
	if (!${Obj_OgreIH.DuoMode} && !${Obj_OgreIH.SoloMode})
	{
		; For Heroic, enable HO for all except ranger
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-ranger checkbox_settings_ho_starter TRUE TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-ranger checkbox_settings_ho_wheel TRUE TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+ranger checkbox_settings_ho_starter FALSE TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+ranger checkbox_settings_ho_wheel FALSE TRUE
		if ${Exclude_Healer1}
		{
			wait 1
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+@healer1 checkbox_settings_ho_starter FALSE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+@healer1 checkbox_settings_ho_wheel FALSE TRUE
		}
	}
	else
	{
		; For Solo/Duo, enable HO for all
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_ho_starter TRUE TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_ho_wheel TRUE TRUE
	}
}

function CheckGroupSetup()
{
	; Default all variables to FALSE
	GroupedWithFighter:Set[FALSE]
	GroupedWithScout:Set[FALSE]
	GroupedWithMage:Set[FALSE]
	GroupedWithPriest:Set[FALSE]
	; Check my Class
	call CheckGroupClass "${Me.SubClass}"
	; Check each group member Class
	variable int GroupNum=0
	while ${GroupNum:Inc} < ${Me.GroupCount}
	{
		call CheckGroupClass "${Me.Group[${GroupNum}].Class}"
	}
}

function CheckGroupClass(string Class)
{
	; Get Archetype based on Class
	call GetArchetypeFromClass "${Class}"
	; Set Grouped With variable based on Archetype
	switch ${Return}
	{
		case fighter
			GroupedWithFighter:Set[TRUE]
			break
		case scout
			GroupedWithScout:Set[TRUE]
			break
		case mage
			GroupedWithMage:Set[TRUE]
			break
		case priest
			GroupedWithPriest:Set[TRUE]
			break
	}
}

function GetArchetypeFromClass(string Class)
{
	; Return Archetype based on Class
	if ${Class.Equal[berserker]} || ${Class.Equal[guardian]} || ${Class.Equal[shadowknight]}
		return "fighter"
	elseif ${Class.Equal[paladin]} || ${Class.Equal[bruiser]} || ${Class.Equal[monk]}
		return "fighter"
	elseif ${Class.Equal[beastlord]} || ${Class.Equal[ranger]} || ${Class.Equal[assassin]} || ${Class.Equal[brigand]}
		return "scout"
	elseif ${Class.Equal[swashbuckler]} || ${Class.Equal[dirge]} || ${Class.Equal[troubador]}
		return "scout"
	elseif ${Class.Equal[wizard]} || ${Class.Equal[warlock]} || ${Class.Equal[necromancer]}
		return "mage"
	elseif ${Class.Equal[conjuror]} || ${Class.Equal[coercer]} || ${Class.Equal[illusionist]}
		return "mage"
	elseif ${Class.Equal[channeler]} || ${Class.Equal[inquisitor]} || ${Class.Equal[templar]} || ${Class.Equal[fury]}
		return "priest"
	elseif ${Class.Equal[warden]} || ${Class.Equal[mystic]} || ${Class.Equal[defiler]}
		return "priest"
}

function SetLootForLastBoss()
{
	; Disable "Loot everything" so it pauses when a NO-TRADE item is encountered
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_loot_lo_looteverything FALSE TRUE
}

; Checks to see if waist item needs to be repaired and swap immunity Rune
; Pass in "stun", "stifle", "mez", or "fear" (if pass in something else like "noswap" will just check repair)
; Requires Mend_Rune_Swap_Helper script to check and see if the repair/swap is actually needed
function mend_and_rune_swap(string FighterAdorn, string ScoutAdorn, string MageAdorn, string PriestAdorn)
{
	; Make sure not in combat
	oc !ci -PetOff igw:${Me.Name}
	call Obj_OgreUtilities.HandleWaitForCombat
	; Set default values for variables MendRuneSwapHelperScript uses
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_WaistCondition" "100"
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RepairBotAvailable" "FALSE"
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RuneSwapNeeded" "FALSE"
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RuneSwapCheckComplete" "FALSE"
	variable int GroupNum=0
	while ${GroupNum:Inc} < ${Me.GroupCount}
	{
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Group[${GroupNum}].Name}_WaistCondition" "100"
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Group[${GroupNum}].Name}_RepairBotAvailable" "FALSE"
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Group[${GroupNum}].Name}_RuneSwapNeeded" "FALSE"
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Group[${GroupNum}].Name}_RuneSwapCheckComplete" "FALSE"
	}
	; Add short delay to allow all variables to be set, otherwise won't work properly
	wait 1
	; Run MendRuneSwapHelperScript on everyone in group to see if repair/swap is needed
	oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${MendRuneSwapHelperScript}
	oc !ci -RunScriptRequiresOgreBot igw:${Me.Name}+fighter ${MendRuneSwapHelperScript} "Check" "${FighterAdorn}"
	oc !ci -RunScriptRequiresOgreBot igw:${Me.Name}+scout ${MendRuneSwapHelperScript} "Check" "${ScoutAdorn}"
	oc !ci -RunScriptRequiresOgreBot igw:${Me.Name}+mage ${MendRuneSwapHelperScript} "Check" "${MageAdorn}"
	oc !ci -RunScriptRequiresOgreBot igw:${Me.Name}+priest ${MendRuneSwapHelperScript} "Check" "${PriestAdorn}"
	; Wait for script to complete on each character (timeout if it takes too long to run)
	variable int Counter = 0
	while !${OgreBotAPI.Get_Variable["${Me.Name}_RuneSwapCheckComplete"]} && ${Counter:Inc} <= 100
	{
		wait 1
	}
	GroupNum:Set[0]
	while ${GroupNum:Inc} < ${Me.GroupCount}
	{
		while !${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}_RuneSwapCheckComplete"]} && ${Counter:Inc} <= 100
		{
			wait 1
		}
	}
	; Print some debug information just to make sure all values returned are correct
	oc ${Me.Name}: Waist%:${OgreBotAPI.Get_Variable["${Me.Name}_WaistCondition"]} Repair Avail:${OgreBotAPI.Get_Variable["${Me.Name}_RepairBotAvailable"]} Rune Need:${OgreBotAPI.Get_Variable["${Me.Name}_RuneSwapNeeded"]}
	GroupNum:Set[0]
	while ${GroupNum:Inc} < ${Me.GroupCount}
	{
		oc ${Me.Group[${GroupNum}].Name}: Waist%:${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}_WaistCondition"]} Repair Avail:${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}_RepairBotAvailable"]} Rune Need:${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}_RuneSwapNeeded"]}
	}
	; Check to see if anyone needs rune swapped
	variable bool RuneSwapNeeded=FALSE
	if ${OgreBotAPI.Get_Variable["${Me.Name}_RuneSwapNeeded"]}
		RuneSwapNeeded:Set[TRUE]
	GroupNum:Set[0]
	while ${GroupNum:Inc} < ${Me.GroupCount}
	{
		if ${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}_RuneSwapNeeded"]}
			RuneSwapNeeded:Set[TRUE]
	}
	; Check to see if anyone needs repair (Waist condition <= 50 or Waist condition < 100 with RuneSwapNeeded)
	variable bool RepairNeeded=FALSE
	if ${OgreBotAPI.Get_Variable["${Me.Name}_WaistCondition"]} <= 50
		RepairNeeded:Set[TRUE]
	elseif ${OgreBotAPI.Get_Variable["${Me.Name}_WaistCondition"]} < 100 && ${RuneSwapNeeded}
		RepairNeeded:Set[TRUE]
	GroupNum:Set[0]
	while ${GroupNum:Inc} < ${Me.GroupCount}
	{
		if ${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}_WaistCondition"]} <= 50
			RepairNeeded:Set[TRUE]
		elseif ${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}_WaistCondition"]} < 100 && ${RuneSwapNeeded}
			RepairNeeded:Set[TRUE]
	}
	; Perform repair if needed
	if ${RepairNeeded}
	{
		; Summon Mechanized Platinum Repository of Reconstruction from the first person that has it available
		if !${Actor[Query,Name=="Mechanized Platinum Repository of Reconstruction" && Distance <= 10](exists)}
		{
			if ${OgreBotAPI.Get_Variable["${Me.Name}_RepairBotAvailable"]}
			{
				oc !ci -UseItem ${Me.Name} "Mechanized Platinum Repository of Reconstruction"
				wait 60
			}
			if !${Actor[Query,Name=="Mechanized Platinum Repository of Reconstruction" && Distance <= 10](exists)}
			{
				GroupNum:Set[0]
				while ${GroupNum:Inc} < ${Me.GroupCount}
				{
					if ${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}_RepairBotAvailable"]}
					{
						oc !ci -UseItem ${Me.Group[${GroupNum}].Name} "Mechanized Platinum Repository of Reconstruction"
						wait 60
					}
					; Stop checking group members once the bot exists
					if ${Actor[Query,Name=="Mechanized Platinum Repository of Reconstruction" && Distance <= 10](exists)}
						break
				}
			}
		}
		; If a bot was summoned, have the group repair
		if ${Actor[Query,Name=="Mechanized Platinum Repository of Reconstruction" && Distance <= 10](exists)}
		{
			oc !ci -repair igw:${Me.Name}
			wait 60
		}
	}
	; Perform rune swap if needed
	if ${RuneSwapNeeded}
	{
		; Make sure not in combat (again)
		oc !ci -PetOff igw:${Me.Name}
		call Obj_OgreUtilities.HandleWaitForCombat
		; Set default values for variables MendRuneSwapHelperScript uses
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RuneSwapCheckComplete" "FALSE"
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RuneSwapSuccessful" "FALSE"
		GroupNum:Set[0]
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			oc !ci -Set_Variable igw:${Me.Name} "${Me.Group[${GroupNum}].Name}_RuneSwapCheckComplete" "FALSE"
			oc !ci -Set_Variable igw:${Me.Name} "${Me.Group[${GroupNum}].Name}_RuneSwapSuccessful" "FALSE"
		}
		; Add short delay to allow all variables to be set, otherwise won't work properly
		wait 1
		; Run MendRuneSwapHelperScript on everyone in group to swap if needed
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${MendRuneSwapHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name}+fighter ${MendRuneSwapHelperScript} "Swap" "${FighterAdorn}"
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name}+scout ${MendRuneSwapHelperScript} "Swap" "${ScoutAdorn}"
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name}+mage ${MendRuneSwapHelperScript} "Swap" "${MageAdorn}"
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name}+priest ${MendRuneSwapHelperScript} "Swap" "${PriestAdorn}"
		; Wait for script to complete on each character
		; 	(no timeout, would rather get stuck in script than continue on without a belt equipped)
		while !${OgreBotAPI.Get_Variable["${Me.Name}_RuneSwapCheckComplete"]}
		{
			wait 1
		}
		GroupNum:Set[0]
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			while !${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}_RuneSwapCheckComplete"]}
			{
				wait 1
			}
		}
		; Check RuneSwapSuccessful
		variable bool RuneSwapSuccessful=TRUE
		if !${OgreBotAPI.Get_Variable["${Me.Name}_RuneSwapSuccessful"]}
			RuneSwapSuccessful:Set[FALSE]
		GroupNum:Set[0]
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			if !${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}_RuneSwapSuccessful"]}
				RuneSwapSuccessful:Set[FALSE]
		}
		if !${RuneSwapSuccessful}
		{
			; Pause Ogre
			oc !ci -Pause igw:${Me.Name}
			; Show pause message
			oc ${Me.Name}: Rune Swap not successfully completed.  Correct any Waist item issues, then resume Ogre Bot on this character to continue.
			; Wait while OgreBot is paused
			wait 10
			while ${Script[${OgreBotScriptName}](exists)} && ${b_OB_Paused}
			{
				wait 10
			}
			; Resume Ogre
			oc !ci -Resume igw:${Me.Name}
		}
	}
}

function initialize_move_to_next_boss(string _NamedNPC, int startpoint)
{
	oc ${Me.Name} is moving to ${_NamedNPC} [${startpoint}].
	oc !ci -OgreFollow igw:${Me.Name} ${Me.Name} 2
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_nostuns FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_nodazes FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_nostifles FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_nointerrupts FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_nofears FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_nodispels FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_npc_cast_monitoring TRUE TRUE
	eq2execute summon
	wait 5
	Obj_OgreIH:SetCampSpot
	call Obj_OgreUtilities.PreCombatBuff 5
	wait 30
	if ${Obj_OgreIH.SoloMode}
	{
		eq2execute merc resume
		wait 30
		eq2execute merc ranged
		eq2execute merc backoff
	}
}

; Disable or re-enable ascensions for fighter
; 	To disable for fights when fighter needs to react quickly with things like aggro snaps and not be stuck casting long spells
function SetupAscensionsFighter(bool EnableAscensions)
{
	; Etherealist ascensions
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Cascading Force" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Compounding Force" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Etherflash" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Focused Blast" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Implosion" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Levinbolt" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Mana Schism" ${EnableAscensions} TRUE
	; Thaumaturgist Ascensions
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Anti-Life" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Blood Contract" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Desiccation" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Exsanguination" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Necrotic Consumption" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Revocation of Life" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Septic Strike" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Virulent Outbreak" ${EnableAscensions} TRUE
	; Geomancer Ascensions
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Accretion" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Bastion of Iron" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Domain of Earth" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Earthen Phalanx" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Erosion" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Geotic Rampage" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Granite Protector" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Mudslide" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Obsidian Mind" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "One with Stone" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Stone Hammer" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Stone Soul" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Telluric Rending" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Terrene Destruction" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Terrestrial Coffin" ${EnableAscensions} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fighter "Xenolith" ${EnableAscensions} TRUE
}

/**********************************************************************************************************
****************************************    Movement Functions    *****************************************
***********************************************************************************************************/

variable int DefaultScanRadius="20"
variable int ShiniesLooted="0"
variable bool Move_Needed=TRUE
variable point3f KillSpot
variable point3f ActorLoc
variable point3f NewLoc

function move_to_next_waypoint(point3f waypoint, int ScanRadius)
{
	oc !ci -resume igw:${Me.Name}
	oc !ci -letsgo igw:${Me.Name}
	variable float Return_X="0"
    variable float Return_Y="0"
    variable float Return_Z="0"
    if ${ScanRadius}==0
    {
        ScanRadius:Set[${DefaultScanRadius}]
    }
	Obj_OgreIH:SetCampSpot
	oc !ci -notarget ${Me.Name}
	Obj_OgreIH:ChangeCampSpot["${waypoint}"]
	call Obj_OgreUtilities.HandleWaitForCampSpot 10
	wait 10
	if ${Me.InCombat}
	{
		call kill_trash
	}
	if ${Actor[Query,Name=="?" && Distance < ${ScanRadius}](exists)} && !${Ogre_Instance_Controller.bSkipShinies}
	{
		Return_X:Set[${Me.X}]
		Return_Y:Set[${Me.Y}]
		Return_Z:Set[${Me.Z}]
		Obj_OgreIH:CCS_Actor["${Actor[Query,Name=="?"].ID}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 5
		call Obj_OgreUtilities.HandleWaitForCombat
		while ${Actor[Query,Name=="?" && Distance < 20](exists)}
		{
			Obj_OgreIH:CCS_Actor["${Actor[Query,Name=="?"].ID}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 5
			Actor[Query,Name=="?"]:DoTarget
			wait 1
			Actor[Query,Name=="?"]:DoubleClick
			wait 20
		}
		ShiniesLooted:Inc
		oc ${Me.Name} ninjas a shiny [${ShiniesLooted} so far]
		Obj_OgreIH:ChangeCampSpot["${Return_X},${Return_Y},${Return_Z}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 5
	}
	if ${Me.InCombat}
	{
		call kill_trash
	}
	call Obj_OgreUtilities.HandleWaitForGroupDistance 5
}

function move_if_needed(string _NamedNPC, point3f NextKillSpot)
{
	if ${Move_Needed}
	{
		if ${Actor[Query,Name=="${_NamedNPC}" && Distance > 25 && Target.ID == 0](exists)}
		{
			KillSpot:Set[${NextKillSpot}]
			Obj_OgreIH:ChangeCampSpot["${NextKillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
		}
		else
		{
			Move_Needed:Set[FALSE]
		}
	}
}

function MoveInRelationToNamed(string ForWho, string _NamedNPC, float Distance, float DegreeOffset)
{
	; Get _NamedNPC ID, make sure it is valid
	variable int NamedID
	NamedID:Set[${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID}]
	; Call MoveInRelationToActorID
	call MoveInRelationToActorID "${ForWho}" "${NamedID}" "${Distance}" "${DegreeOffset}"
}

function MoveInRelationToActorID(string ForWho, int ActorID, float Distance, float DegreeOffset)
{
	; Note for how EQ2 coordinates work
	; 	Positive X is West, Positive Z is South
	; 	0 degree heading is North, 90 degree heading is East (goes clockwise)
	
	; Make sure ActorID is valid
	if ${ActorID.Equal[0]} || !${Actor[${ActorID}].ID(exists)}
		return
	; Get actor Location and Heading, make sure they are valid
	variable float ActorHeading
	ActorLoc:Set[${Actor[${ActorID}].Loc}]
	ActorHeading:Set[${Actor[${ActorID}].Heading}]
	if ${ActorLoc.X}==0 && ${ActorLoc.Y}==0 && ${ActorLoc.Z}==0
		return
	; Get new Location at Distance and DegreeOffset from Named
	; 	Note DegreeOffset is such that 0 degrees is in front of named and rotates clockwise around named
	; 	ex. 90 degrees would move you to the named's right side, -90 to named's left
	NewLoc:Set[${ActorLoc.X},${ActorLoc.Y},${ActorLoc.Z}]
	NewLoc.X:Dec[${Distance}*${Math.Sin[${ActorHeading}+${DegreeOffset}]}]
	NewLoc.Z:Dec[${Distance}*${Math.Cos[${ActorHeading}+${DegreeOffset}]}]
	; Change Camp Spot to new Location
	oc !ci -campspot ${ForWho}
	oc !ci -ChangeCampSpotWho ${ForWho} ${NewLoc.X} ${NewLoc.Y} ${NewLoc.Z}
}

function CalcSpotOffset(point3f InitialSpot, point3f FinalSpot, float Offset)
{
	; Given an InitialSpot and FinalSpot, calculate a new FinalSpot along the path but at an Offset from FinalSpot
	; 	For when you want to move to a new location, but stop just short of it
	
	; Calculate Slope in degrees based on a line from InitialSpot to FinalSpot
	; 	SlopeDegrees is number of degrees from the positive X Axis
	variable float SlopeDegrees
	if ${FinalSpot.X} != ${InitialSpot.X}
		SlopeDegrees:Set[${Math.Atan[(${FinalSpot.Z}-${InitialSpot.Z})/(${FinalSpot.X}-${InitialSpot.X})]}]
	elseif ${FinalSpot.Z} > ${InitialSpot.Z}
		SlopeDegrees:Set[90]
	else
		SlopeDegrees:Set[-90]
	
	; Correct SlopeDegrees if in the -X direction (Atan only gives values from -90 to +90)
	if ${FinalSpot.X} < ${InitialSpot.X}
		if ${FinalSpot.Z} > ${InitialSpot.Z}
			SlopeDegrees:Inc[180]
		else
			SlopeDegrees:Dec[180]
			
	; Calculate Distance, adding in Offset
	variable float Distance
	Distance:Set[${Math.Distance[${InitialSpot.X},${InitialSpot.Z},${FinalSpot.X},${FinalSpot.Z}]}-${Offset}]
	
	; Return NewSpot from InitialSpot with the calculated Distance and SlopeDegrees
	variable point3f NewSpot
	NewSpot:Set[${InitialSpot}]
	NewSpot.X:Inc[${Distance}*${Math.Cos[${SlopeDegrees}]}]
	NewSpot.Z:Inc[${Distance}*${Math.Sin[${SlopeDegrees}]}]
	return ${NewSpot}
	
}

/**********************************************************************************************************
****************************************    Combat Functions    *******************************************
***********************************************************************************************************/

function kill_trash()
{
	oc !ci -PetOff igw:${Me.Name}
	call Obj_OgreUtilities.HandleWaitForCampSpot 5
	oc !ci -PetAssist igw:${Me.Name}
	if (!${Obj_OgreIH.DuoMode} && !${Obj_OgreIH.SoloMode})
	{
		oc !ci -LetsGo igw:${Me.Name}+scout
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+scout checkbox_settings_movemelee TRUE TRUE
	}
	call Obj_OgreUtilities.HandleWaitForCombat
	oc !ci -campspot igw:${Me.Name}
	oc !ci -ChangeCampSpotWho igw:${Me.Name} ${Me.X} ${Me.Y} ${Me.Z}
	call Obj_OgreUtilities.WaitWhileGroupMembersDead
	call Obj_OgreUtilities.HandleWaitForGroupDistance 5
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+scout checkbox_settings_movemelee FALSE TRUE
	wait 10
}

function Tank_n_Spank(string _NamedNPC, point3f KillSpot)
{
	variable int iCount=0
	variable int Counter=0
	oc ${Me.Name} is pulling ${_NamedNPC}
	Obj_OgreIH:SetCampSpot
	Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
	call Obj_OgreUtilities.HandleWaitForCampSpot 10
	oc !ci -PetOff igw:${Me.Name}
	wait 10
	oc !ci -PetAssist igw:${Me.Name}
	Actor["${_NamedNPC}"]:DoTarget
	wait 50
	while ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
	{
		if ${Actor[Query,Name=="${_NamedNPC}" && Distance > 7](exists)}
		{
			while ${Actor[Query,Name=="${_NamedNPC}" && Distance > 5](exists)} && ${iCount} < 15
			{
				iCount:Inc
				wait 10
			}
		}
		if (!${Obj_OgreIH.DuoMode} && !${Obj_OgreIH.SoloMode})
		{
			Obj_OgreIH:CCS_Actor_Position["${Actor[Query,Name=="${_NamedNPC}"].ID}"]
			Counter:Set[0]
			while ${Counter:Inc} <= 10
			{
				if ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
					wait 10
			}
		}
		wait 10
	}
	call Obj_OgreUtilities.HandleWaitForCombat
	call Obj_OgreUtilities.WaitWhileGroupMembersDead
	wait 50
}

function Tank_n_Spank_Move_Named_Target(string _NamedNPC, point3f KillSpot)
{
	variable int iCount="0"
	oc ${Me.Name} is pulling ${_NamedNPC}
	Obj_OgreIH:SetCampSpot
	Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
	call Obj_OgreUtilities.HandleWaitForCampSpot 10
	oc !ci -PetOff igw:${Me.Name}
	wait 10
	oc !ci -PetAssist igw:${Me.Name}
	Actor["${_NamedNPC}"]:DoTarget
	wait 50
	; Move to _NamedNPC initially
	if ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
	{
		Obj_OgreIH:CCS_Actor["${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID}"]
		wait 40
	}
	; Update position to Target throughout the fight
	while ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
	{
		if ${Target(exists)}
		{
			Obj_OgreIH:CCS_Actor["${Target.ID}"]
			wait 40
		}
	}
	call Obj_OgreUtilities.HandleWaitForCombat
	call Obj_OgreUtilities.WaitWhileGroupMembersDead
	wait 50
}

function Tank_n_Spank_Ensure_Group_Behind(string _NamedNPC, point3f KillSpot)
{
	; Disable ascensions for fighter (don't want to cast things with a long cast time in case need to snap aggro)
	if (!${Obj_OgreIH.DuoMode} && !${Obj_OgreIH.SoloMode})
		call SetupAscensionsFighter "FALSE"
	; Tank and spank _NamedNPC while updating position every 4 seconds to keep group behind
	variable int iCount="0"
	oc ${Me.Name} is pulling ${_NamedNPC}
	Obj_OgreIH:SetCampSpot
	Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
	call Obj_OgreUtilities.HandleWaitForCampSpot 10
	oc !ci -PetOff igw:${Me.Name}
	wait 10
	oc !ci -PetAssist igw:${Me.Name}
	Actor["${_NamedNPC}"]:DoTarget
	wait 50
	while ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
	{
		if (!${Obj_OgreIH.DuoMode} && !${Obj_OgreIH.SoloMode})
		{
			oc !ci -SetCS_InFrontNPC igw:${Me.Name}+Fighter "${Actor[Query,Name=="${_NamedNPC}"].ID}" 3 FALSE
			oc !ci -SetCS_BehindNPC igw:${Me.Name}+-Fighter "${Actor[Query,Name=="${_NamedNPC}"].ID}" 3 FALSE
		}
		wait 30
	}
	call Obj_OgreUtilities.HandleWaitForCombat
	call Obj_OgreUtilities.WaitWhileGroupMembersDead
	wait 50
	; Re-enable ascensions for fighter
	if (!${Obj_OgreIH.DuoMode} && !${Obj_OgreIH.SoloMode})
		call SetupAscensionsFighter "TRUE"
}

function Tank_at_KillSpot(string _NamedNPC, point3f KillSpot)
{
	oc ${Me.Name} is pulling ${_NamedNPC}
	Obj_OgreIH:SetCampSpot
	Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
	call Obj_OgreUtilities.HandleWaitForCampSpot 10
	oc !ci -PetOff igw:${Me.Name}
	wait 10
	oc !ci -PetAssist igw:${Me.Name}
	Actor["${_NamedNPC}"]:DoTarget
	wait 50
	while ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
	{
		wait 10
	}
	call Obj_OgreUtilities.HandleWaitForCombat
	call Obj_OgreUtilities.WaitWhileGroupMembersDead
	wait 50
}

function Tank_in_Place(string _NamedNPC)
{
	oc ${Me.Name} is pulling ${_NamedNPC}
	oc !ci -PetOff igw:${Me.Name}
	wait 10
	oc !ci -PetAssist igw:${Me.Name}
	Actor["${_NamedNPC}"]:DoTarget
	wait 50
	while ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
	{
		wait 10
	}
	call Obj_OgreUtilities.HandleWaitForCombat
	call Obj_OgreUtilities.WaitWhileGroupMembersDead
	wait 50
}

; Check to see if Target has the EffectName
; Will check Effects to up MaxEffects
function CheckTargetEffect(string EffectName, int MaxEffects=30)
{
	; Loop through each effect up to MaxEffects
	variable int Counter = 0
	while (${Target(exists)} && ${Counter:Inc} <= ${Target.NumEffects} && ${Counter} <= ${MaxEffects})
	{
		; Wait for effect info available
		while (${Target.Effect[${Counter}].ID(exists)} && !${Target.Effect[${Counter}].IsEffectInfoAvailable})
		{
			waitframe
		}
		; Return True if effect name is found
		if ${Target.Effect[${Counter}].ToEffectInfo.Name.Equal[${EffectName}]}
			return TRUE
	}
	; Return FALSE if EffectName not found
	return FALSE
}

; Check to see if Target has the EffectName and return number of increments (return -1 if not valid)
; Will check Effects to up MaxEffects
function GetTargetEffectIncrements(string EffectName, int MaxEffects=30)
{
	; Loop through each effect up to MaxEffects
	variable int Counter = 0
	while (${Target(exists)} && ${Counter:Inc} <= ${Target.NumEffects} && ${Counter} <= ${MaxEffects})
	{
		; Wait for effect info available
		while (${Target.Effect[${Counter}].ID(exists)} && !${Target.Effect[${Counter}].IsEffectInfoAvailable})
		{
			waitframe
		}
		; Check if effect name is found
		if ${Target.Effect[${Counter}].ToEffectInfo.Name.Equal[${EffectName}]}
			return ${Target.Effect[${Counter}].CurrentIncrements}
	}
	; Return -1 if EffectName not found
	return -1
}

function CastInterrupt()
{
	; Pause Ogre
	oc !ci -Pause igw:${Me.Name}
	wait 3
	; Clear ability queue
	relay ${OgreRelayGroup} eq2execute clearabilityqueue
	; Cancel anything currently being cast
	oc !ci -CancelCasting igw:${Me.Name}
	; Cast Interrupt ability depending on Class (modify as needed based on group setup)
	oc !ci -CastAbility igw:${Me.Name}+berserker "Mock"
	oc !ci -CastAbility igw:${Me.Name}+shadowknight "Blasphemy"
	oc !ci -CastAbility igw:${Me.Name}+ranger "Hilt Strike"
	oc !ci -CastAbility igw:${Me.Name}+dirge "Hymn of Horror"
	oc !ci -CastAbility igw:${Me.Name}+swashbuckler "Tease"
	oc !ci -CastAbility igw:${Me.Name}+beastlord "Sharpened Claws"
	oc !ci -CastAbility igw:${Me.Name}+coercer "Hemorrhage"
	;oc !ci -CastAbility igw:${Me.Name}+coercer "Spellblade's Counter"
	;oc !ci -CastAbilityNoChecks igw:${Me.Name}+fury "Maddening Swarm"
	;oc !ci -CastAbilityNoChecks igw:${Me.Name}+mystic "Echoes of the Ancients"
	; Resume Ogre
	oc !ci -Resume igw:${Me.Name}
}

/**********************************************************************************************************
****************************************    Misc Functions    *********************************************
***********************************************************************************************************/

function EnterPortal(string PortalName, string PortalAction="Teleport", int PortalWaitTime=60, int PortalInitialWaitTime=20, int PortalFaceWaitTime=10)
{
	; Make sure not in combat
	oc !ci -PetOff igw:${Me.Name}
	call Obj_OgreUtilities.HandleWaitForCombat
	; Stop movement
	oc !ci -LetsGo igw:${Me.Name}
	Obj_OgreIH:Set_NoMove
	; Teleport
	wait ${PortalInitialWaitTime}
	relay ${OgreRelayGroup} face ${PortalName}
	wait ${PortalFaceWaitTime}
	oc !ci -ApplyVerbForWho igw:${Me.Name} "${PortalName}" "${PortalAction}"
	wait ${PortalWaitTime}
	; Set CampSpot at new destination
	Obj_OgreIH:SetCampSpot
}

function click_shiny()
{
	wait 10
	if ${Actor[Query,Name=="?" && Distance < 5](exists)}
	{
		Actor[Query,Name=="?"]:DoTarget
		wait 1
		Actor[Query,Name=="?"]:DoubleClick
		wait 20
		ShiniesLooted:Inc
	}
}

function UseChronoDungeonItem()
{
	; Check to see if already in Chrono version of instance
	if ${Actor[Query,(Type == "NPC" || Type == "NamedNPC") && Level >= 130].ID(exists)}
		return TRUE
	; Set default values for ChronoCount
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_ChronoCount" "0"
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_ChronoCountComplete" "FALSE"
	variable int GroupNum=0
	while ${GroupNum:Inc} < ${Me.GroupCount}
	{
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Group[${GroupNum}].Name}_ChronoCount" "0"
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Group[${GroupNum}].Name}_ChronoCountComplete" "FALSE"
	}
	; Add short delay to allow all variables to be set, otherwise won't work properly
	wait 1
	; Run ChronoHelperScript on everyone in group to get number of Chrono Dungeon items they have
	oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ChronoHelperScript}
	oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ChronoHelperScript}
	; Wait for script to complete on each character (timeout if more than 2 seconds to run)
	variable int Counter = 0
	while !${OgreBotAPI.Get_Variable["${Me.Name}_ChronoCountComplete"]} && ${Counter:Inc} <= 20
	{
		wait 1
	}
	GroupNum:Set[0]
	while ${GroupNum:Inc} < ${Me.GroupCount}
	{
		Counter:Set[0]
		while !${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}_ChronoCountComplete"]} && ${Counter:Inc} <= 20
		{
			wait 1
		}
	}
	; Get character that has the most Chrono Dungeon items
	variable int ChronoCount=0
	variable int MaxChronoCount=0
	variable string MaxChronoCharacter
	ChronoCount:Set[${OgreBotAPI.Get_Variable["${Me.Name}_ChronoCount"]}]
	if ${ChronoCount} > ${MaxChronoCount}
	{
		MaxChronoCount:Set[${ChronoCount}]
		MaxChronoCharacter:Set["${Me.Name}"]
	}
	GroupNum:Set[0]
	while ${GroupNum:Inc} < ${Me.GroupCount}
	{
		ChronoCount:Set[${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}_ChronoCount"]}]
		if ${ChronoCount} > ${MaxChronoCount}
		{
			MaxChronoCount:Set[${ChronoCount}]
			MaxChronoCharacter:Set["${Me.Group[${GroupNum}].Name}"]
		}
		; If characters have the same number of Chronos, set to character that would come first if sorted by Name
		; 	This should prevent a character from potentially using twice in a row
		elseif ${ChronoCount} == ${MaxChronoCount} && ${Me.Group[${GroupNum}].Name.Compare["${MaxChronoCharacter}"]} < 0
		{
			MaxChronoCount:Set[${ChronoCount}]
			MaxChronoCharacter:Set["${Me.Group[${GroupNum}].Name}"]
		}
	}
	; Make sure a character was found with at least 1 Chrono Dungeon item
	if ${MaxChronoCount} == 0
	{
		oc No Character found with a Chrono Dungeons: [Level 130] item
		return FALSE
	}
	; Pause Ogre
	oc !ci -Pause igw:${Me.Name}
	wait 3
	; Clear ability queue
	relay ${OgreRelayGroup} eq2execute clearabilityqueue
	; Cancel anything currently being cast
	oc !ci -CancelCasting igw:${Me.Name}
	; Have MaxChronoCharacter use Chrono Dungeon item
	wait 20
	oc !c -UseItem igw:${Me.Name}+${MaxChronoCharacter} "Chrono Dungeons: [Level 130]"
	wait 60
	; Confirm choice
	oc !ci -ChoiceWindow igw:${Me.Name}+${MaxChronoCharacter} "1"
	wait 60
	; Wait for group to zone into new Chrono instance
	call WaitForGroupToZoneIn
	; Make sure in Chrono version of instance (sometimes doesn't always work the first time, so check a few times just in case)
	Counter:Set[0]
	while !${Actor[Query,(Type == "NPC" || Type == "NamedNPC") && Level >= 130].ID(exists)} && ${Counter:Inc} <= 3
	{
		wait 10
	}
	if !${Actor[Query,(Type == "NPC" || Type == "NamedNPC") && Level >= 130].ID(exists)}
	{
		oc Failed to zone into Chrono version of instance
		return FALSE
	}
	; Resume Ogre
	oc !ci -Resume igw:${Me.Name}
	; Chrono Dungeon item used
	return TRUE
}

function WaitForGroupToZoneIn()
{
	; Wait for character to zone
	call WaitForMeToZoneIn
	; Loop through group members
	variable int GroupNum=0
	while ${GroupNum:Inc} < ${Me.GroupCount}
	{
		; Wait for group member to be within 30m of character
		while ${GroupNum} < ${Me.GroupCount} && !${Actor[Query,Name=="${Me.Group[${GroupNum}].Name}" && Type == "PC" && Distance <= 30].ID(exists)}
		{
			wait 10
		}
	}
}

function WaitForMeToZoneIn()
{
	; Wait for character to zone by checking ID (will be NULL while zoning)
	while ${Me.ID} == 0
	{
		wait 10
	}
}

function ZoneOut(string ZoneOutName)
{
	; Check to see if Pause at end of zone is checked
	if ${Ogre_Instance_Controller.bPauseAtEndOfZone}
	{
		; Pause Ogre
		oc !ci -Pause igw:${Me.Name}
		; Show pause message
		oc ${Me.Name}: Pause at end of zone checked.  Resume Ogre Bot on this character to continue.
		; Wait while OgreBot is paused
		wait 10
		while ${Script[${OgreBotScriptName}](exists)} && ${b_OB_Paused}
		{
			wait 10
		}
		; Resume Ogre
		oc !ci -Resume igw:${Me.Name}
	}
	
	; Get initial Zone Name
	variable string InitialZoneName
	InitialZoneName:Set["${Zone.Name}"]
	
	; Zone Out
	oc !ci -Actor_Click igw:${Me.Name} "${ZoneOutName}" "TRUE"
	wait 10
	; If there are multiple instances, choose first
	oc !ci -ZoneDoorForWho igw:${Me.Name} "1"
	wait 60
	
	; Wait for group to zone in
	call WaitForGroupToZoneIn
	
	; Make sure zone has changed
	if !${Zone.Name.Equal["${InitialZoneName}"]}
		return TRUE
	else
		return FALSE
}