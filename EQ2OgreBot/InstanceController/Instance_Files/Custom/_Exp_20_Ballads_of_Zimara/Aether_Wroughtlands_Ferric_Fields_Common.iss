; This IC file requires ZoneHelperScript/HOHelperScript/MendRuneSwapHelperScript/IC_Helper files to function
variable string ZoneHelperScript="EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/Aether_Wroughtlands_Ferric_Fields_Helper"
variable string HOHelperScript="HO_Helper"
variable string MendRuneSwapHelperScript="EQ2OgreBot/InstanceController/Support_Files_Common/Mend_Rune_Swap_Helper"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"

variable string Solo_Zone_Name="Aether Wroughtlands: Ferric Fields [Solo]"
variable string Heroic_1_Zone_Name="Aether Wroughtlands: Ferric Fields [Heroic I]"
variable string Heroic_2_Zone_Name="Aether Wroughtlands: Ferric Fields [Heroic II]"
variable bool TheyaNeedInterrupt=TRUE
variable bool TheyaNeedDispel=TRUE

#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Ogre_Instance_Include.iss"

function main(int _StartingPoint=0, ... Args)
{
call function_Handle_Startup_Process ${_StartingPoint} "-NoAutoLoadMapOnZone" ${Args.Expand}
}
atom atexit()
{
	echo ${Time}: ${Script.Filename} done
}
objectdef Object_Instance
{
	function:bool RunInstance(int _StartingPoint=0)
	{
		oc !ci -LetsGo igw:${Me.Name}
		Obj_OgreIH:SetCampSpot
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_movetoarea TRUE TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} textentry_setup_moveintomeleerangemaxdistance 20 TRUE
		; Check group setup (needed for group-specific code)
		call CheckGroupSetup
		
		if ${_StartingPoint} == 0
		{
			call Obj_OgreIH.ZoneNavigation.GetIntoZone "${sZoneName}"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone
				return FALSE
			}
			Ogre_Instance_Controller:ZoneSet
			call Obj_OgreIH.Set_VariousOptions
			call Obj_OgreIH.Set_PriestAscension FALSE
			call SetInitialInstanceSettings
			Obj_OgreIH:Set_NoMove
			Obj_OgreIH:SetCampSpot
			call Obj_OgreUtilities.PreCombatBuff 5
			_StartingPoint:Inc

			; Change starting point below to start script after a certain named. (for debugging only)		
			_StartingPoint:Set[0]
			_StartingPoint:Inc
		}
		; Move to and kill Named 1
		if ${_StartingPoint} == 1
		{
			call This.Named1 "Katakir the Cruel"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#1: Katakir the Cruel"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 2
		if ${_StartingPoint} == 2
		{
			call This.Named2 "Theya Shen'Safa"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#2: Theya Shen'Safa"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 3
		if ${_StartingPoint} == 3
		{
			call This.Named3 "Metalloid"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#3: Metalloid"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 4
		if ${_StartingPoint} == 4
		{
			call This.Named4 "Syadun"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#4: Syadun"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 5
		if ${_StartingPoint} == 5
		{
			call This.Named5 "Shanrazad the Spared"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#5: Shanrazad the Spared"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		
		; Zone Out
		if ${_StartingPoint} == 6
		{
			; Stop by shiny
			call move_to_next_waypoint "91.21,14.41,-532.88" "15"
			call move_to_next_waypoint "111.69,13.32,-538.91" "5"
			call move_to_next_waypoint "91.21,14.41,-532.88" "15"
			call move_to_next_waypoint "92.64,14.44,-570.30" "15"
			call move_to_next_waypoint "74.75,13.72,-557.30" "1"
			call move_to_next_waypoint "71.85,13.41,-554.82" "5"
			call move_to_next_waypoint "74.75,13.72,-557.30" "1"
			call move_to_next_waypoint "92.64,14.44,-570.30" "15"
			call move_to_next_waypoint "85.04,13.71,-574.45"
			call move_to_next_waypoint "81.68,12.89,-576.44" "1"
			Ob_AutoTarget:Clear
			Obj_OgreIH:LetsGo
			oc ${Me.Name} looted ${ShiniesLooted} shinies
			call ZoneOut "zone_exit"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZoneOut
				return FALSE
			}
			_StartingPoint:Inc
		}
		
		; Exit Script
		return TRUE
	}

/**********************************************************************************************************
    Named 1 **********************    Move to, spawn and kill - Katakir the Cruel   ***********************
***********************************************************************************************************/

	function:bool Named1(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-83.39,36.89,-632.26]
		
		; Repair if needed
		call mend_and_rune_swap "noswap" "noswap" "noswap" "noswap"
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "1"
		call move_to_next_waypoint "-167.08,36.34,-684.76"
		call move_to_next_waypoint "-85.45,36.19,-702.45"
		call move_to_next_waypoint "-76.46,36.92,-673.44"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Enable HO for Fighter
		; A Heroic Opportunity initiated by a fighter is the only way to interrupt Katakir's Iron Will!
		eq2execute cancel_ho_starter
		call HO "Fighter" "FALSE"
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "${_NamedNPC}"
		
		; If H2, disable Cure during fight
		; Named casts noxious det Pitiless Punishment (MainIconID 884, BackDropIconID 884)
		; 	On termination evolves into a curse
		; 	Want to leave on as long as possible so Cure Curse has enough time to refresh when it turns into a curse
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			call SetupAllCures "FALSE"
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			Ob_AutoTarget:Clear
			; For H2, kill adds first
			if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			{
				Ob_AutoTarget:AddActor["an iron maedjinn saitahn",0,FALSE,FALSE]
				Ob_AutoTarget:AddActor["an iron maedjinn saitihn",0,FALSE,FALSE]
				Ob_AutoTarget:AddActor["an iron maedjinn alharan",0,FALSE,FALSE]
				Ob_AutoTarget:AddActor["an iron maedjinn alharin",0,FALSE,FALSE]
				Ob_AutoTarget:AddActor["an iron maedjinn guard",0,FALSE,FALSE]
			}
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_n_Spank "${_NamedNPC}" "${KillSpot}"
			Ob_AutoTarget:Clear
		}
		
		; Disable HO for all
		call HO "Disable" "FALSE"
		
		; If H2, re-enable Cure
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			call SetupAllCures "TRUE"
		
		; Check named is dead
		if ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_FailedToKill["${_NamedNPC}"]
			return FALSE
		}
		
		; Get Chest
		eq2execute summon
		wait 10
		call Obj_OgreIH.Get_Chest
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 2 ********************    Move to, spawn and kill - Theya Shen'Safa  ****************************
***********************************************************************************************************/

	function:bool Named2(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-15.17,49.89,-780.46]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "2"
		call move_to_next_waypoint "-72.03,36.74,-699.68" "10"
		call move_to_next_waypoint "-40.21,43.52,-717.77" "10"
		; Look for shiny from last boss
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "-50.42,43.49,-743.20" "5"
			call move_to_next_waypoint "-40.21,43.52,-717.77" "10"
			; There is another shiny spot to the left right by the ledge, skipping it intentionally
			; because it is really easy for characters to fall off the ledge and get stuck
		}
		; Skipping another potential shiny near here by a plant because it is really hard to get back from
		call move_to_next_waypoint "-19.05,49.82,-753.16" "5"
		call move_to_next_waypoint "4.11,50.19,-774.62" "5"
		; Wait a bit for named to spawn
		wait 150
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Disable single target Cure (only want to use group cures)
		; Named casts "Iron Sickness" that does greater damage if not also on a fighter
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+priest "Cure" FALSE TRUE
		
		; For H2, enable HO for all
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			eq2execute cancel_ho_starter
			call HO "All" "FALSE"
			oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
			oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "${_NamedNPC}"
		}

		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_n_Spank "${_NamedNPC}" "${KillSpot}"
			Ob_AutoTarget:Clear
		}
		; For H2
		; 	Named casts Purify that heals named, need to Interrupt
		; 	Named casts Steel Skin that prevents damage, can dispel
		elseif ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Handle text events
			Event[EQ2_onIncomingChatText]:AttachAtom[TheyaIncomingChatText]
			; Kill named
			oc ${Me.Name} is pulling ${_NamedNPC}
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			Actor["${_NamedNPC}"]:DoTarget
			wait 50
			while ${Me.InCombat}
			{
				; Interrupt Purify
				if ${TheyaNeedInterrupt}
				{
					; Cast Interrupt
					call CastInterrupt
					; Interrupt handled
					TheyaNeedInterrupt:Set[FALSE]
				}
				; Dispel Steel Skin
				if ${TheyaNeedDispel}
				{
					; Cast Absorb Magic to dispel
					oc !ci -CastAbility igw:${Me.Name}+mage "Absorb Magic"
					; Dispel handled
					TheyaNeedDispel:Set[FALSE]
				}
				; Short wait before looping again (need to respond to Interrupt as quickly as possible)
				wait 1
			}
			Ob_AutoTarget:Clear
			; Remove Atom for text event
			Event[EQ2_onIncomingChatText]:DetachAtom[TheyaIncomingChatText]
		}
		
		; Re-enable Cure
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+priest "Cure" TRUE TRUE
		
		; Disable HO for all
		call HO "Disable" "FALSE"
		
		; Check named is dead
		if ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_FailedToKill["${_NamedNPC}"]
			return FALSE
		}
		
		; Get Chest
		eq2execute summon
		wait 10
		call Obj_OgreIH.Get_Chest
		
		; Look for shinies
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "-26.24,50.15,-765.90" "5"
			call move_to_next_waypoint "${KillSpot}" "10"
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 3 *********************    Move to, spawn and kill - Metalloid **********************************
***********************************************************************************************************/

	function:bool Named3(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[257.45,36.70,-697.80]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "3"
		call move_to_next_waypoint "14.23,49.82,-770.02" "1"
		; Stop by shiny on the way down
		call move_to_next_waypoint "30.51,45.09,-771.57" "5"
		call move_to_next_waypoint "28.81,44.36,-758.78" "5"
		call move_to_next_waypoint "35.51,37.85,-739.07" "10"
		; Look for shiny from last boss
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "40.41,37.76,-751.68" "5"
			call move_to_next_waypoint "50.56,37.34,-752.37" "5"
			call move_to_next_waypoint "40.41,37.76,-751.68" "5"
			call move_to_next_waypoint "35.51,37.85,-739.07" "10"
		}
		Obj_OgreIH:ChangeCampSpot["50.22,36.53,-706.06"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		call move_to_next_waypoint "52.34,38.35,-683.78" "5"
		call move_to_next_waypoint "50.22,36.53,-706.06" "10"
		; Stop by Shiny on the way to next named
		call move_to_next_waypoint "70.49,36.36,-702.68" "10"
		call move_to_next_waypoint "89.33,37.73,-703.70" "10"
		call move_to_next_waypoint "151.52,36.23,-670.97"
		call move_to_next_waypoint "205.01,36.24,-693.27"
		call move_to_next_waypoint "226.64,39.29,-697.25"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Named has Ferrous Form effect, reduces damage done by 99%
		; For solo zone, remove with HO
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]}
		{
			; Enable HO for all
			eq2execute cancel_ho_starter
			call HO "All" "FALSE"
			oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
			oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "${_NamedNPC}"
			; Kill named
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_n_Spank "${_NamedNPC}" "${KillSpot}"
			Ob_AutoTarget:Clear
			; Disable HO for all
			call HO "Disable" "FALSE"
		}
		; For Heroic, remove effect with Bulwark
		elseif ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; For H2, run ZoneHelperScript to handle pillars, enable HO for Fighter, disable Heroic Setups
			if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			{
				; Run ZoneHelperScript to detect incoming pillars and cast Bulwark
				oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
				oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC}"
				; Enable HO for Fighter to get Overpowered Weaponry buff to damage named
				eq2execute cancel_ho_starter
				call HO "Fighter" "FALSE"
				oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
				oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "${_NamedNPC}"
				; Disable Heroic Setups (movement from setup can mess us CampSpots)
				oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_grindoptions FALSE TRUE
			}
			; Kill named
			oc ${Me.Name} is pulling ${_NamedNPC}
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			Actor["${_NamedNPC}"]:DoTarget
			wait 50
			variable int TimeSinceBulwark=30
			while ${Me.InCombat}
			{
				; Named has Ferrous Form effect, reduces damage done by 99%
				; Have fighter cast Bulwark of Order to get past it
				; 	I believe Ogre also casts it as part of Heroic Setups
				if ${TimeSinceBulwark:Inc} >= 30
				{
					oc !ci -CastAbility igw:${Me.Name}+fighter "Bulwark of Order"
					TimeSinceBulwark:Set[0]
				}
				; Wait a second before looping again
				wait 10
			}
			Ob_AutoTarget:Clear
			; For H2, disable HO for all and re-enable Heroic Setups
			if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			{
				call HO "Disable" "FALSE"
				oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_grindoptions TRUE TRUE	
			}
		}
		
		; Check named is dead
		if ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_FailedToKill["${_NamedNPC}"]
			return FALSE
		}
		
		; Get Chest
		eq2execute summon
		wait 10
		call Obj_OgreIH.Get_Chest
		
		; Look for shinies
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "257.73,36.47,-706.47" "10"
			call move_to_next_waypoint "299.79,38.30,-723.80" "10"
			call move_to_next_waypoint "305.14,42.79,-736.67" "10"
			call move_to_next_waypoint "299.79,38.30,-723.80" "10"
			call move_to_next_waypoint "257.73,36.47,-706.47" "10"
			call move_to_next_waypoint "${KillSpot}"
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 4 *********************    Move to, spawn and kill - Syadun *************************************
***********************************************************************************************************/

	function:bool Named4(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[48.46,37.84,-664.95]
		
		; Swap to stifle immunity rune (named has Hot Wrought effect that stifles if in front of)
		call mend_and_rune_swap "stifle" "stifle" "stifle" "stifle"
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "4"
		call move_to_next_waypoint "294.80,36.78,-683.82"
		call EnterPortal "portal_cube_01" "Teleport"
		call move_to_next_waypoint "48.99,37.32,-694.59"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Kill named
		; Named has Watcher's Weaves effect that reduces damage by 20% for each watcher's weave not in combat
		; Want to pull all of the watcher's weave (on top of pillars), but not kill them
		; If they are killed, they will just respawn
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			oc ${Me.Name} is pulling ${_NamedNPC}
			Ob_AutoTarget:Clear
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			Actor["${_NamedNPC}"]:DoTarget
			wait 50
			variable int WeaveID=0
			while ${Me.InCombat}
			{
				; Target "a watcher's weave" on pillar between 5m and 35m away if at full HP
				WeaveID:Set[${Actor[Query,Name=="a watcher's weave" && Y > 48 && Distance > 5 && Distance < 35 && Health == 100 && Type != "Corpse" && Type != "NoKill NPC"].ID}]
				if !${WeaveID.Equal[0]}
					Actor[${WeaveID}]:DoTarget
				; Otherwise target named
				else
					Actor["${_NamedNPC}"]:DoTarget
				; Wait a second before looping
				wait 10
			}
		}
		; For H2, can't target weaves by default
		; Standing on platform near weaves gives Unraveled Weaves: MainIconID: 417 BackDropIconID: -1
		; 	Allows targeting weaves
		; 	Only one person may be afflicted at a time
		; Named will cast curse Wrought Rot: MainIconID: 879 BackDropIconID: 413
		; 	Kills target on expiration or if cured while maintaining Unraveled Weaves
		elseif ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Clear AutoTarget, will selectively target
			Ob_AutoTarget:Clear
			; Disable Assist and Cure Curse
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_assist FALSE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_curecurse TRUE TRUE
			; Disable ascensions for fighter (don't want to cast things with a long cast time when trying to target weaves)
			call SetupAscensionsFighter "FALSE"
			; Enable HO for all (to reset Cure Curse)
			eq2execute cancel_ho_starter
			call HO "All" "FALSE"
			oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
			oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "${_NamedNPC}"
			; Kill named
			oc ${Me.Name} is pulling ${_NamedNPC}
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			Actor["${_NamedNPC}"]:DoTarget
			wait 50
			; Run ZoneHelperScript to pull weaves and handle Curse Cure
			oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
			oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC}"
			while ${Me.InCombat}
			{
				; Wait a second before looping again
				wait 10
			}
			Ob_AutoTarget:Clear
			; Re-enable Assist, Cure Curse, and ascensions for fighter
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notfighter checkbox_settings_assist TRUE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_curecurse FALSE TRUE
			call SetupAscensionsFighter "TRUE"
			; Send everyone back to KillSpot (wait a bit first, the helper script might still be running and moving fighter)
			wait 50
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			; Disable HO for all
			call HO "Disable" "FALSE"
		}
		
		; Check named is dead
		if ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_FailedToKill["${_NamedNPC}"]
			return FALSE
		}
		
		; Get Chest
		eq2execute summon
		wait 10
		call Obj_OgreIH.Get_Chest
		
		; Look for shinies
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "48.65,38.29,-689.80" "10"
			call move_to_next_waypoint "38.94,36.92,-716.05" "10"
			call move_to_next_waypoint "32.60,37.11,-690.06" "5"
			call move_to_next_waypoint "19.78,36.22,-702.40" "5"
			call move_to_next_waypoint "12.17,38.13,-719.62" "5"
			call move_to_next_waypoint "19.78,36.22,-702.40" "5"
			call move_to_next_waypoint "-7.88,36.06,-674.38" "5"
			call move_to_next_waypoint "-2.38,38.29,-656.47" "5"
			call move_to_next_waypoint "-10.81,37.02,-656.47" "5"
			call move_to_next_waypoint "-10.42,38.13,-640.64" "5"
			call move_to_next_waypoint "9.11,42.87,-643.25" "5"
			call move_to_next_waypoint "-10.42,38.13,-640.64" "5"
			call move_to_next_waypoint "-10.81,37.02,-656.47" "5"
			call move_to_next_waypoint "-2.38,38.29,-656.47" "5"
			call move_to_next_waypoint "-7.88,36.06,-674.38" "5"
			call move_to_next_waypoint "37.37,36.52,-703.70" "10"
			call move_to_next_waypoint "53.83,38.35,-681.73" "10"
			call move_to_next_waypoint "${KillSpot}"
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 5 *********************    Move to, spawn and kill - Shanrazad the Spared ***********************
***********************************************************************************************************/

	function:bool Named5(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[91.21,14.41,-532.88]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "5"
		call move_to_next_waypoint "53.04,37.83,-658.54" "5"
		call EnterPortal "portal_cube_03" "Teleport"
		; Aggro mobs, then pull back (don't want to potentially aggro named)
		Obj_OgreIH:ChangeCampSpot["97.32,14.58,-559.31"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		call move_to_next_waypoint "99.92,14.51,-572.70" "5"
		; Kill flier mobs
		call move_to_next_waypoint "76.95,13.85,-557.98" "5"
		call move_to_next_waypoint "86.10,13.57,-576.77" "5"
		call move_to_next_waypoint "101.82,13.71,-580.36" "5"
		call move_to_next_waypoint "112.90,13.15,-565.76" "5"
		call move_to_next_waypoint "97.32,14.58,-559.31" "5"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Disable Interrupts
		call SetupAllInterrupts "FALSE"
		
		; Set Loot settings for last boss
		call SetLootForLastBoss
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			; Send everyone to KillSpot
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			; Send priests to center of area to cure people ported out (if not Solo zone)
			if !${Zone.Name.Equals["${Solo_Zone_Name}"]}
				oc !ci -ChangeCampSpotWho "igw:${Me.Name}+priest" 94.32 14.53 -546.05
			; Kill named
			call Tank_in_Place "${_NamedNPC}"
			Ob_AutoTarget:Clear
		}
		; For H2, need to fight on specific platforms
		; There are 5 orbs on the back wall that match up with 5 platforms
		; During fight, 1/2/3/4 orbs will glow and not allow you to stand on the corresponding platform
		; 	If you stand on the platform, you get Smelting: MainIconID: 406 BackDropIconID: -1
		; 	This prevents character from targeting named
		; Named likes to stay back and range attack group
		; 	Strategy is to try to pull named to a position near the center of the 4 platforms
		; 	Then roate around as needed if the current platform is not allowed
		; A character may be ported out and rooted during the fight
		; 	If that happens, send the Priests to their location to cure them
		elseif ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Setup variables
			variable int KillSpotNum=1
			variable point3f KillSpots[4]
			KillSpots[1]:Set[94.03,14.62,-544.64]
			KillSpots[2]:Set[96.14,14.67,-539.03]
			KillSpots[3]:Set[91.70,14.52,-534.91]
			KillSpots[4]:Set[89.82,14.67,-540.55]
			; Send everyone to initial aggro spot right in front of named
			oc ${Me.Name} is pulling ${_NamedNPC}
			Obj_OgreIH:ChangeCampSpot["90.75,14.41,-530.58"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			wait 50
			; Then joust back to try to pull named out a bit from his initial location
			Obj_OgreIH:ChangeCampSpot["98.57,14.49,-565.78"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			wait 50
			; Go right/left a bit to try to get him to the center in case he is on the side
			Obj_OgreIH:ChangeCampSpot["105.19,14.44,-565.11"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			wait 30
			Obj_OgreIH:ChangeCampSpot["91.71,14.44,-568.35"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			wait 30
			; Go to first KillSpot
			Obj_OgreIH:ChangeCampSpot["${KillSpots[${KillSpotNum}]}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			; Kill named
			variable int PriestAwayCount=-5
			while ${Me.InCombat}
			{
				; Check to see if KillSpot platform is not allowed
				if ${Me.Effect[Query, Type == "Detrimental" && MainIconID == 406 && BackDropIconID == -1].ID(exists)}
				{
					; Increment KillSpotNum, or go back to 1
					if ${KillSpotNum:Inc} > 4
						KillSpotNum:Set[1]
					; Move to next KillSpot (don't move Priest if they have been sent out)
					if ${PriestAwayCount} < 0
						oc !ci -ChangeCampSpotWho igw:${Me.Name} ${KillSpots[${KillSpotNum}].X} ${KillSpots[${KillSpotNum}].Y} ${KillSpots[${KillSpotNum}].Z}
					else
						oc !ci -ChangeCampSpotWho igw:${Me.Name}+notpriest ${KillSpots[${KillSpotNum}].X} ${KillSpots[${KillSpotNum}].Y} ${KillSpots[${KillSpotNum}].Z}
					; Wait a couple of seconds to move to new KillSpot
					wait 20
				}
				; Check to see if a group member has been ported out
				; 	Need to send a Priest over to cure them so they can return to group
				if ${PriestAwayCount} == -1
				{
					ActorLoc:Set[${Actor[Query,(Type == "PC" || Type == "Me") && Z < -550].Loc}]
					if ${ActorLoc.X}!=0 || ${ActorLoc.Y}!=0 || ${ActorLoc.Z}!=0
					{
						; Send Priest to their Location
						oc !ci -ChangeCampSpotWho igw:${Me.Name}+priest ${ActorLoc.X} ${ActorLoc.Y} ${ActorLoc.Z}
						PriestAwayCount:Set[0]
					}
				}
				else
					PriestAwayCount:Inc
				; If Priest has been away for more than 5 seconds, bring them back
				if ${PriestAwayCount} > 5
				{
					oc !ci -ChangeCampSpotWho igw:${Me.Name}+priest ${KillSpots[${KillSpotNum}].X} ${KillSpots[${KillSpotNum}].Y} ${KillSpots[${KillSpotNum}].Z}
					PriestAwayCount:Set[-5]
				}
				; Wait a second before looping
				wait 10
			}
			Ob_AutoTarget:Clear
		}
		
		; Re-enable Interrupts
		call SetupAllInterrupts "TRUE"
		
		; Check named is dead
		if ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_FailedToKill["${_NamedNPC}"]
			return FALSE
		}
		
		; Get Chest
		eq2execute summon
		wait 10
		call Obj_OgreIH.Get_Chest
		
		; Finished with named
		return TRUE
	}
}

/***********************************************************************************************************
***********************************************  ATOMS  ****************************************************
************************************************************************************************************/

atom TheyaIncomingChatText(int ChatType, string Message, string Speaker, string TargetName, string SpeakerIsNPC, string ChannelName)
{
	; Look for Purify being cast
	; Theya Shen'Safa says, "Purify!"
	if ${Speaker.Equal["Theya Shen'Safa"]} && ${Message.Find["Purify!"]}
		TheyaNeedInterrupt:Set[TRUE]
	
	; Look for Steel Skin
	; Theya Shen'Safa says, "Steel Skin!"
	if ${Speaker.Equal["Theya Shen'Safa"]} && ${Message.Find["Steel Skin!"]}
		TheyaNeedDispel:Set[TRUE]
	
	; Debug text to see messages
	;echo ${ChatType}, ${Message}, ${Speaker}, ${TargetName}, ${SpeakerIsNPC}, ${ChannelName}
}
