; This IC file requires ZoneHelperScript/HOHelperScript/MendRuneSwapHelperScript/IC_Helper files to function
variable string ZoneHelperScript="EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/Vaashkaani_Golden_Rule_Helper"
variable string HOHelperScript="HO_Helper"
variable string MendRuneSwapHelperScript="EQ2OgreBot/InstanceController/Support_Files_Common/Mend_Rune_Swap_Helper"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"

variable string Solo_Zone_Name="Vaashkaani: Golden Rule [Solo]"
variable string Heroic_1_Zone_Name="Vaashkaani: Golden Rule [Heroic I]"
variable string Heroic_2_Zone_Name="Vaashkaani: Golden Rule [Heroic II]"

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
			call SetupPets "TRUE"
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
			call This.Named1 "Nezri En'Sallef"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#1: Nezri En'Sallef"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 2
		if ${_StartingPoint} == 2
		{
			call This.Named2 "Isos"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#2: Isos"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 3
		if ${_StartingPoint} == 3
		{
			call This.Named3 "The Storm Mistress"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#3: The Storm Mistress"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 4
		if ${_StartingPoint} == 4
		{
			call This.Named4 "Hezodhan"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#4: Hezodhan"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 5
		if ${_StartingPoint} == 5
		{
			call This.Named5 "Zakir-Sar-Ussur" "Ashnu"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#5: Zakir-Sar-Ussur and Ashnu"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		
		; Zone Out
		if ${_StartingPoint} == 6
		{
			call move_to_next_waypoint "592.46,71.11,-55.50" "5"
			Ob_AutoTarget:Clear
			Obj_OgreIH:LetsGo
			oc ${Me.Name} looted ${ShiniesLooted} shinies
			call Obj_OgreIH.ZoneNavigation.ZoneOut
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
    Named 1 **********************    Move to, spawn and kill - Nezri En'Sallef   *************************
***********************************************************************************************************/

	function:bool Named1(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[147.30,20.36,0.26]
		
		; Repair if needed
		call mend_and_rune_swap "noswap" "noswap" "noswap" "noswap"
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "1"
		; Pull trash near ramp, have had them aggro on way up and run into line of sight issues
		call move_to_next_waypoint "-38.08,2.96,-44.15"
		call move_to_next_waypoint "14.87,2.95,-41.96"
		call move_to_next_waypoint "-46.62,2.96,-42.22"
		call move_to_next_waypoint "-33.91,2.99,-28.73"
		call move_to_next_waypoint "-16.09,10.04,-35.73"
		call move_to_next_waypoint "-2.48,15.61,-33.07"
		call move_to_next_waypoint "6.40,19.96,-25.70"
		call move_to_next_waypoint "15.02,19.93,0.05"
		call move_to_next_waypoint "68.59,20.30,0.34"
		call move_to_next_waypoint "104.06,20.30,0.20"
		call move_to_next_waypoint "123.06,20.36,0.33"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "206.58,31.50,0.00" "1"
			return TRUE
		}
		
		; Swap to stifle immunity rune (otherwise can get stifled and not able to complete HO in time and wipe)
		call mend_and_rune_swap "stifle" "stifle" "stifle" "stifle"
		
		; Disable HO for all and run HO_Helper script
		call HO "Disable" "FALSE"
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "${_NamedNPC}"
		variable bool HOEnabled=FALSE
		
		; If H2, disable Cure Curse, run ZoneHelperScript, and disable Absorb Magic in Cast Stack
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Disable Cure Curse
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_curecurse TRUE TRUE
			; Set a default value for FirstWish variable (has not been cast on anyone)
			oc !ci -Set_Variable igw:${Me.Name} "FirstWish" "None"
			; Run ZoneHelperScript (will handle Cure Curse)
			; Note for this fight, if you have a Mystic make sure the Mystical Moppet is set to not cure curse or it can kill you
			oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
			oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC}"
			; Disable Absorb Magic in Cast Stack
			oc !ci -ChangeCastStackListBoxItem igw:${Me.Name} "Absorb Magic" FALSE TRUE
		}
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			oc ${Me.Name} is pulling ${_NamedNPC}
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			Actor["${_NamedNPC}"]:DoTarget
			wait 50
			while ${Me.InCombat}
			{
				; Check to see if named has "Gilded Guard" effect (needs to be removed with an HO)
				; If not removed, wipes group at 25 increments
				; Only check first 8 effects, should show near beginning of effects
				call CheckTargetEffect "Gilded Guard" "8"
				if ${Return}
				{
					; Enable HO for all
					eq2execute cancel_ho_starter
					call HO "All" "FALSE"
					HOEnabled:Set[TRUE]
					wait 100
					; In H2, need to cast Absorb Magic to get rid of Gilded Guard after HO completes
					if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
						oc !ci -CastAbility igw:${Me.Name}+mage "Absorb Magic"
						
				}
				; If no effect, disable HO for all
				elseif ${HOEnabled}
				{
					call HO "Disable" "FALSE"
					HOEnabled:Set[FALSE]
					wait 10
					eq2execute cancel_ho_starter
				}
				; Wait a second before checking for effect again
				wait 10
			}
			Ob_AutoTarget:Clear
		}
		
		; If H2, re-enable Cure Curse and Absorb Magic in Cast Stack
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_curecurse FALSE TRUE
			oc !ci -ChangeCastStackListBoxItem igw:${Me.Name} "Absorb Magic" TRUE TRUE
		}
		
		; Check named is dead
		if ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_FailedToKill["${_NamedNPC}"]
			return FALSE
		}
		
		; Disable HO for all
		call HO "Disable" "FALSE"
		
		; Get Chest
		eq2execute summon
		wait 10
		call Obj_OgreIH.Get_Chest

		; Move to start of next area (don't want to check shinies at this point)
		call move_to_next_waypoint "206.58,31.50,0.00" "1"
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 2 ********************    Move to, spawn and kill - Isos  ***************************************
***********************************************************************************************************/

	function:bool Named2(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[262.11,31.25,54.39]
		
		; Look for shiny from last boss
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "204.48,31.50,-8.18" "5"
			call move_to_next_waypoint "218.84,31.50,-8.10" "5"
			call move_to_next_waypoint "218.20,31.50,0.94" "5"
			call move_to_next_waypoint "218.94,31.50,7.56" "5"
			call move_to_next_waypoint "207.05,31.50,7.89" "5"
			call move_to_next_waypoint "206.58,31.50,0.00"
		}
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "2"
		call move_to_next_waypoint "222.27,31.25,39.71" "1"
		call move_to_next_waypoint "203.74,31.70,47.07s" "1"
		call GetOrb "orb_gales" "Take the orb"
		call move_to_next_waypoint "222.27,31.25,39.71" "1"
		call GetOrb "orb_cyclones" "Take the orb"
		call move_to_next_waypoint "206.58,31.50,0.00" "1"
		call move_to_next_waypoint "223.46,31.41,-40.32" "1"
		call move_to_next_waypoint "203.25,31.82,-47.31" "1"
		call GetOrb "orb_hale" "Take the orb"
		call move_to_next_waypoint "223.46,31.41,-40.32" "1"
		call GetOrb "orb_rains" "Take the orb"
		call move_to_next_waypoint "212.95,31.78,-14.36" "1"
		call move_to_next_waypoint "220.64,31.50,0.08" "1"
		call move_to_next_waypoint "250.36,31.50,0.00" "1"
		call move_to_next_waypoint "261.86,31.78,13.90" "1"
		call move_to_next_waypoint "261.94,31.55,21.03" "1"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Swap to stun immunity rune
		call mend_and_rune_swap "stun" "stun" "stun" "stun"
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Disable ascensions for fighter (don't want to cast things with a long cast time in case need to snap aggro)
			if (!${Obj_OgreIH.DuoMode} && !${Obj_OgreIH.SoloMode})
				call SetupAscensionsFighter "FALSE"
			; Kill Named
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_at_KillSpot "${_NamedNPC}" "${KillSpot}"
			Ob_AutoTarget:Clear
			; Re-enable ascensions for fighter
			if (!${Obj_OgreIH.DuoMode} && !${Obj_OgreIH.SoloMode})
				call SetupAscensionsFighter "TRUE"
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
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 3 *********************    Move to, spawn and kill - The Storm Mistress *************************
***********************************************************************************************************/

	function:bool Named3(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[262.24,31.25,-55.07]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "3"
		call move_to_next_waypoint "265.76,31.68,62.89"
		call GetOrb "orb_thunder" "Take the orb"
		call move_to_next_waypoint "261.92,31.45,-23.34" "1"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}" "1"
			return TRUE
		}
		
		; Swap to stun immunity rune (otherwise can get stunned and not able to kill adds in time and wipe)
		call mend_and_rune_swap "stun" "stun" "stun" "stun"
		
		; If H2, disable Absorb Magic in Cast Stack
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			oc !ci -ChangeCastStackListBoxItem igw:${Me.Name} "Absorb Magic" FALSE TRUE
		
		; Named info:
		; Spawns lightning anchor adds, if 3 up for too long group wipes
		; 	Note lightning anchors actually show up as Specials called boss_03_wisp_sphere_01/02/03
		; 	Adds have "Lightning Leader" - only the Lightning Leader can be damaged in the chain
		; 		For Solo/H1 don't have to worry about it can just kill them as they spawn
		; 		For H2 need to make sure targeting the correct add
		
		; Kill named
		; For Solo version, need to use HO's to remove "Bolted" effect from lightning anchors to kill (reduces dmg 99%)
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]}
		{
			; Disable HO for all and run HO_Helper script
			call HO "Disable" "FALSE"
			oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
			oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "${_NamedNPC}"
			variable bool HOEnabled=FALSE
			; Start fight with named
			oc ${Me.Name} is pulling ${_NamedNPC}
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["lightning anchor",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			Actor["${_NamedNPC}"]:DoTarget
			wait 50
			while ${Me.InCombat}
			{
				; Check for lightning anchor
				if ${Actor[Query,Name=="lightning anchor" && Type != "Corpse" && Distance < 50](exists)}
				{
					; Enable HO for all
					eq2execute cancel_ho_starter
					call HO "All" "FALSE"
					HOEnabled:Set[TRUE]
					; Move to lightning anchor
					Obj_OgreIH:CCS_Actor["${Actor[Query,Name=="lightning anchor" && Type != "Corpse" && Distance < 50].ID}"]
					; Wait 5 seconds before checking again
					wait 50
				}
				; If no lightning anchor, disable HO for all
				elseif ${HOEnabled}
				{
					call HO "Disable" "FALSE"
					HOEnabled:Set[FALSE]
					wait 10
					eq2execute cancel_ho_starter
				}
				; Wait a second before checking for lightning anchor again
				wait 10
			}
		}
		; For H1 don't need to use HO's, just move to adds and kill them as they spawn
		elseif ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["lightning anchor",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			; Move to named initially, but move to lightning anchors when they spawn
			call Tank_n_Spank_Move_Named_Target "${_NamedNPC}" "${KillSpot}"
		}
		; For H2 adds start with "Bolted", which needs to be removed by a Bulwark
		; Adds then have "Unbolted", which needs to be removed by a Dispel
		; Need to make sure only targeting Lightning Leader
		elseif ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Setup variable for adds
			variable int AddNum=1
			variable int AddID
			variable point3f AddLoc[3]
			AddLoc[1]:Set[271.02,31.58,-45.99]
			AddLoc[2]:Set[262.52,31.25,-33.85]
			AddLoc[3]:Set[253.12,32.03,-44.12]
			variable bool HasEffect
			; Start fight with named
			oc ${Me.Name} is pulling ${_NamedNPC}
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["lightning anchor",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			Actor["${_NamedNPC}"]:DoTarget
			wait 50
			while ${Me.InCombat}
			{
				; Check for lightning anchor
				if ${Actor[Query,Name=="lightning anchor" && Type != "Corpse" && Distance < 50](exists)}
				{
					; Move to AddNum location
					Obj_OgreIH:ChangeCampSpot["${AddLoc[${AddNum}]}"]
					call Obj_OgreUtilities.HandleWaitForCampSpot 5
					; Check to see if there is an add within 5m
					AddID:Set[${Actor[Query,Name=="lightning anchor" && Type != "Corpse" && Distance <= 5].ID}]
					if ${AddID} != 0 && ${Actor[${AddID}].ID(exists)}
					{
						; Target the add
						wait 10
						Actor[${AddID}]:DoTarget
						wait 10
						; Stay on add as long as they have "Lightning Leader"
						HasEffect:Set[TRUE]
						while ${HasEffect}
						{
							call CheckTargetEffect "Lightning Leader" "4"
							if ${Return}
							{
								; Check to see if add has "Bolted"
								HasEffect:Set[TRUE]
								while ${HasEffect}
								{
									call CheckTargetEffect "Bolted" "4"
									if ${Return}
									{
										; Need to use Bulwark to remove Bolted
										oc !ci -CastAbility igw:${Me.Name}+fighter "Bulwark of Order"
										wait 40
									}
									else
										HasEffect:Set[FALSE]
								}
								; Check to see if add has "Unbolted"
								HasEffect:Set[TRUE]
								while ${HasEffect}
								{
									call CheckTargetEffect "Unbolted" "4"
									if ${Return}
									{
										; Need to use Absorb Magic to dispel Unbolted
										oc !ci -CastAbility igw:${Me.Name}+mage "Absorb Magic"
										wait 40
									}
									else
										HasEffect:Set[FALSE]
								}
								; Wait a second before looping (going to assume still have Lightning Leader at this point)
								HasEffect:Set[TRUE]
								wait 10
							}
							else
								HasEffect:Set[FALSE]
						}
					}
					; When finished with add, move to next
					AddNum:Inc
					if ${AddNum} > 3
						AddNum:Set[1]
				}
				; Wait a second before checking for lightning anchor again
				wait 10
			}
		}
		
		; If H2, re-enable Absorb Magic in Cast Stack
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			oc !ci -ChangeCastStackListBoxItem igw:${Me.Name} "Absorb Magic" TRUE TRUE
		
		; Move back to KillSpot after the fight
		call move_to_next_waypoint "${KillSpot}" "1"
		Ob_AutoTarget:Clear
		
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
 	Named 4 *********************    Move to, spawn and kill - Hezodhan ***********************************
***********************************************************************************************************/

	function:bool Named4(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[430.40,6.56,0.03]
		
		; Look for shiny from Isos
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "264.34,31.47,-61.93"
			call move_to_next_waypoint "262.24,31.25,-55.07"
			call move_to_next_waypoint "253.05,31.25,-48.08"
			call move_to_next_waypoint "261.59,31.78,-14.55" "1"
			call move_to_next_waypoint "272.70,31.50,0.28" "10"
			call move_to_next_waypoint "261.59,31.78,-14.55" "1"
		}
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "4"
		call move_to_next_waypoint "265.58,31.45,-62.79"
		call GetOrb "orb_lightning" "Take the orb"
		call move_to_next_waypoint "262.24,31.25,-55.07"
		call move_to_next_waypoint "261.93,31.78,-10.09"
		call move_to_next_waypoint "279.33,31.64,-0.09"
		call EnterPortal "portal_to_forum" "use"
		call move_to_next_waypoint "399.40,3.70,-0.07" "1"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; If H2, swap to stifle immunity rune
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			call mend_and_rune_swap "stifle" "stifle" "stifle" "stifle"
		
		; Named info:
		; Named spawns "a sand squall" adds
		; If 20 adds, group wipes
		; Adds spawn based on people in front of named, so make sure rest of group stays behind
		; 	Have heard this also counts pets
		; For H2, there are also cursed sand pits that spawn
		; 	Seems to be at location of named's target
		
		; Kill named
		; For solo and H1 should be able to focus burn the named down in time as long as make sure the group is behind named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_n_Spank_Ensure_Group_Behind "${_NamedNPC}" "${KillSpot}"
			Ob_AutoTarget:Clear
		}
		; For H2, need to keep group out of cursed sand pits as they root the target in place
		elseif ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; First kill trash in area to clear space
			call move_to_next_waypoint "408.41,3.51,16.05" "1"
			call move_to_next_waypoint "377.92,3.51,29.23" "1"
			call move_to_next_waypoint "379.90,3.51,-20.15" "1"
			call move_to_next_waypoint "405.93,3.51,-19.34" "1"
			call move_to_next_waypoint "405.10,3.52,-0.01" "1"
			; Clear AutoTarget, will selectively target
			Ob_AutoTarget:Clear
			; Disable Assist and pets
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_assist FALSE TRUE
			call SetupPets "FALSE"
			; Set a default values for IncomingBreathOfSand/CursedSandPitSpawning variables
			oc !ci -Set_Variable igw:${Me.Name} "IncomingBreathOfSand" "FALSE"
			oc !ci -Set_Variable igw:${Me.Name} "CursedSandPitSpawning" "FALSE"
			wait 1
			; Setup variables for KillSpots (need to move away from Cursed Sand Pits)
			variable int KillSpotNum=1
			variable point3f KillSpots[5]
			KillSpots[1]:Set[410.10,3.52,-0.01]
			KillSpots[2]:Set[399.14,3.51,18.55]
			KillSpots[3]:Set[378.55,3.70,11.50]
			KillSpots[4]:Set[378.15,3.70,-10.69]
			KillSpots[5]:Set[399.38,3.51,-19.35]
			variable float DesiredHeading[5]
			DesiredHeading[1]:Set[321]
			DesiredHeading[2]:Set[252]
			DesiredHeading[3]:Set[180]
			DesiredHeading[4]:Set[111]
			DesiredHeading[5]:Set[29]
			variable float InitialNamedHeading
			variable float NewNamedHeading
			variable float NamedHeadingChange
			variable float FighterNamedOffset
			variable int BreathMoves
			variable int BreathOffsetNum
			variable float BreathOffset[2]
			BreathOffset[1]:Set[10]
			BreathOffset[2]:Set[-10]
			variable int WaitSpawn
			variable bool FirstBreath=TRUE
			variable bool CADisabled=FALSE
			; Run ZoneHelperScript
			oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
			oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC}"
			wait 1
			; Pull with tank, then move back to initial KillSpot
			oc ${Me.Name} is pulling ${_NamedNPC}
			Obj_OgreIH:SetCampSpot
			oc !ci -ChangeCampSpotWho "igw:${Me.Name}+fighter" 425.21 6.46 0.17
			wait 20
			oc !ci -ChangeCampSpotWho "igw:${Me.Name}" ${KillSpots[${KillSpotNum}].X} ${KillSpots[${KillSpotNum}].Y} ${KillSpots[${KillSpotNum}].Z}
			wait 20
			; Kill named
			while ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
			{				
				; Check to see if CursedSandPitSpawning
				if ${OgreBotAPI.Get_Variable["CursedSandPitSpawning"]}
				{
					; Increment KillSpotNum
					KillSpotNum:Inc
					if ${KillSpotNum} > 5
						KillSpotNum:Set[1]
					; Move group to next KillSpot
					; If IncomingBreathOfSand, keep fighter near named for a bit before moving to KillSpot
					if ${OgreBotAPI.Get_Variable["IncomingBreathOfSand"]}
					{
						; Send rest of group to KillSpot
						oc !ci -ChangeCampSpotWho "igw:${Me.Name}+notfighter" ${KillSpots[${KillSpotNum}].X} ${KillSpots[${KillSpotNum}].Y} ${KillSpots[${KillSpotNum}].Z}
						; Wait up to 3 seconds for Breath of Sand to finish casting
						; Helper script should set IncomingBreathOfSand = FALSE as soon as message of sand squall being formed
						WaitSpawn:Set[0]
						while ${WaitSpawn:Inc} <= 30
						{
							; Wait if breath is still incoming
							if ${OgreBotAPI.Get_Variable["IncomingBreathOfSand"]}
								wait 1
							else
								WaitSpawn:Set[100]
						}
						; Send fighter to KillSpot
						oc !ci -ChangeCampSpotWho "igw:${Me.Name}+fighter" ${KillSpots[${KillSpotNum}].X} ${KillSpots[${KillSpotNum}].Y} ${KillSpots[${KillSpotNum}].Z}
						wait 10
						; Set IncomingBreathOfSand to FALSE as breath was handled
						oc !ci -Set_Variable igw:${Me.Name} "IncomingBreathOfSand" "FALSE"
						wait 1
					}
					; If no IncomingBreathOfSand, send everyone to KillSpot right away
					else
					{
						Obj_OgreIH:ChangeCampSpot["${KillSpots[${KillSpotNum}]}"]
						wait 10
					}
					; If CADisabled, re-enable CA/NamedCA for everyone
					if ${CADisabled}
					{
						oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notfighter checkbox_settings_disablecaststack_ca FALSE TRUE
						oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notfighter checkbox_settings_disablecaststack_namedca FALSE TRUE
						CADisabled:Set[FALSE]
					}	
					; Set CursedSandPitSpawning to FALSE, spawn was handled
					oc !ci -Set_Variable igw:${Me.Name} "CursedSandPitSpawning" "FALSE"
					wait 1
				}
				; Check to see if IncomingBreathOfSand
				if ${OgreBotAPI.Get_Variable["IncomingBreathOfSand"]}
				{
					; Disable CA/NamedCA for everyone except fighter (need to make sure no one pulls aggro during this or will likely wipe)
					; 	Only for first Breath of Sand, after that fight should be going on long enough to not worry about potential aggro issues
					if ${FirstBreath}
					{
						oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notfighter checkbox_settings_disablecaststack_ca TRUE TRUE
						oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notfighter checkbox_settings_disablecaststack_namedca TRUE TRUE
						FirstBreath:Set[FALSE]
						CADisabled:Set[TRUE]
					}
					; Want fighter in front of named and rest of group in back, but first want the named looking at direction opposite of next KillSpot
					; This is in case a Cursed Sand Pit spawns while a Breath of Sand is incoming and group has to move
					; Don't want group running into the line of fire of the Breath of Sand
					FighterNamedOffset:Set[${DesiredHeading[${KillSpotNum}]} - ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].Heading}]
					call MoveInRelationToNamed "igw:${Me.Name}+fighter" "${_NamedNPC}" "5" "${FighterNamedOffset}"
					FighterNamedOffset:Inc[180]
					call MoveInRelationToNamed "igw:${Me.Name}+notfighter" "${_NamedNPC}" "5" "${FighterNamedOffset}"
					wait 20
					; Get initial Heading of named (hopefully is targeting fighter at this point)
					; Named seems to lock Heading right before casting Breath of Sand
					; The idea is move fighter back and forth and see if Heading changes
					; When it doesn't change, the cast should be imminent so fighter should move to side of named
					; If everything goes as planned, all group members avoid the breath and only a single Sand Squall spawns
					InitialNamedHeading:Set[${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].Heading}]
					BreathMoves:Set[0]
					; Try up to 5 sets of moves
					while ${BreathMoves:Inc} <= 5
					{
						; Move one direction, then the other
						BreathOffsetNum:Set[0]
						while ${BreathOffsetNum:Inc} <= 2
						{
							; Change position in relation to named
							call MoveInRelationToNamed "igw:${Me.Name}+fighter" "${_NamedNPC}" "5" "${BreathOffset[${BreathOffsetNum}]}"
							wait 10
							; Get NewNamedHeading
							NewNamedHeading:Set[${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].Heading}]
							; Calculate NamedHeadingChange
							NamedHeadingChange:Set[${Math.Abs[${NewNamedHeading}-${InitialNamedHeading}]}]
							; Set InitialNamedHeading to NewNamedHeading for next comparison
							InitialNamedHeading:Set[${NewNamedHeading}]
							; If named didn't move by at least 5 degrees, cast is imminent and fighter needs to move to side of named
							; 	Note Heading can wrap around from 360 to 0 so may be a large number with a small change
							if ${NamedHeadingChange} <=5 || ${NamedHeadingChange} >= 355
							{
								; Set FighterNamedOffset (move to right or left side depending on which side already moved to)
								FighterNamedOffset:Set[90]
								if ${BreathOffsetNum} == 2
									FighterNamedOffset:Set[-90]
								; Move to side of named
								call MoveInRelationToNamed "igw:${Me.Name}+fighter" "${_NamedNPC}" "5" "${FighterNamedOffset}"
								; Wait up to 3 seconds for Breath of Sand to finish casting
								; Helper script should set IncomingBreathOfSand = FALSE as soon as message of sand squall being formed
								WaitSpawn:Set[0]
								while ${WaitSpawn:Inc} <= 30
								{
									; Wait if breath is still incoming and there is not a sand pit spawning
									if ${OgreBotAPI.Get_Variable["IncomingBreathOfSand"]} && !${OgreBotAPI.Get_Variable["CursedSandPitSpawning"]}
										wait 1
									else
										WaitSpawn:Set[100]
								}
								; Set BreathOffsetNum and BreathMoves to break out of loops
								BreathOffsetNum:Set[2]
								BreathMoves:Set[100]
							}
						}
					}
					; If CADisabled and IncomingBreathOfSand = FALSE, re-enable CA/NamedCA for everyone
					if ${CADisabled} && !${OgreBotAPI.Get_Variable["IncomingBreathOfSand"]}
					{
						oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notfighter checkbox_settings_disablecaststack_ca FALSE TRUE
						oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notfighter checkbox_settings_disablecaststack_namedca FALSE TRUE
						CADisabled:Set[FALSE]
					}
					; If CursedSandPitSpawning = FALSE, set IncomingBreathOfSand to FALSE as breath was handled
					; 	Otherwise might still be happening, just needed to break out early to deal with Cursed Sand Pit
					if !${OgreBotAPI.Get_Variable["CursedSandPitSpawning"]}
						oc !ci -Set_Variable igw:${Me.Name} "IncomingBreathOfSand" "FALSE"
				}
				; Short wait, need to respond to IncomingBreathOfSand/CursedSandPitSpawning as quickly as possible
				wait 1
			}
			; Re-enable CA, NamedCA, Assist and pets
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_ca FALSE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_namedca FALSE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notfighter checkbox_settings_assist TRUE TRUE
			call SetupPets "TRUE"
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
		
		; Send all characters back to KillSpot after fight
		call move_to_next_waypoint "${KillSpot}" "1"
		
		; Look for shiny from The Storm Mistress
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "370.41,3.51,-16.69" "20"
			call move_to_next_waypoint "404.61,3.51,-33.37" "10"
			call move_to_next_waypoint "426.41,8.00,-40.88"
			call move_to_next_waypoint "459.22,8.00,-23.56" "15"
			call move_to_next_waypoint "452.21,8.00,22.60" "10"
			call move_to_next_waypoint "438.12,8.00,36.59" "10"
			call move_to_next_waypoint "415.36,6.02,43.44" "10"
			call move_to_next_waypoint "409.30,3.51,14.71" "20"
			call move_to_next_waypoint "${KillSpot}"
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 5 *********************    Move to, spawn and kill - Zakir-Sar-Ussur and Ashnu ******************
***********************************************************************************************************/

	function:bool Named5(string _NamedNPC1="Doesnotexist", string _NamedNPC2="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[615.62,71.11,-45.59]
		
		; Setup and move to named, looking for shiny from Hezodhan along the way
		call initialize_move_to_next_boss "${_NamedNPC1}" "5"
		call move_to_next_waypoint "442.00,6.59,0.59"
		call EnterPortal "transport_carpet_01" "Travel"
		call move_to_next_waypoint "363.06,31.61,-0.02" "5"
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "370.30,31.23,0.27"
		}
		call move_to_next_waypoint "340.82,31.49,0.06" "5"
		call move_to_next_waypoint "328.08,31.49,7.97" "5"
		call move_to_next_waypoint "305.37,31.49,8.82" "5"
		call move_to_next_waypoint "304.25,31.53,0.14" "5"
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "298.16,31.50,-0.82" "10"
			call move_to_next_waypoint "304.25,31.53,0.14" "5"
			call move_to_next_waypoint "303.90,31.49,-7.55" "5"
			call move_to_next_waypoint "331.00,31.49,-8.42" "15"
			call move_to_next_waypoint "303.90,31.49,-7.55" "5"
			call move_to_next_waypoint "304.25,31.53,0.14" "5"
		}
		call move_to_next_waypoint "346.91,52.12,-0.01" "5"
		call move_to_next_waypoint "368.56,63.49,-0.12" "5"
		call move_to_next_waypoint "392.75,71.37,-0.31" "5"
		call move_to_next_waypoint "391.92,71.37,-18.02" "5"
		call move_to_next_waypoint "407.33,71.37,-18.12" "10"
		call move_to_next_waypoint "391.92,71.37,-18.02" "5"
		call move_to_next_waypoint "391.96,71.37,17.66" "5"
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "399.15,71.37,17.85" "10"
			call move_to_next_waypoint "391.96,71.37,17.66" "5"
		}
		call move_to_next_waypoint "411.56,71.33,17.67"
		call EnterPortal "portal_cube_01" "Teleport"
		call move_to_next_waypoint "521.55,71.37,17.55"
		call move_to_next_waypoint "521.29,71.37,-0.10"
		call move_to_next_waypoint "566.98,71.32,0.00"
		call move_to_next_waypoint "601.65,71.34,0.08"
		call move_to_next_waypoint "602.28,71.37,-32.14"
		call move_to_next_waypoint "${KillSpot}"
		call EnterPortal "djinn_boss_mirror" "Peer into the mirror"
		wait 60
		
		; Check if already killed
		if !${Actor[Query,Name=="${_NamedNPC1}"](exists)} && !${Actor[Query,Name=="${_NamedNPC2}"](exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC1}"]
			return TRUE
		}
		
		; Swap to fear immunity rune (need to stay in front of mirror to draw in named)
		call mend_and_rune_swap "fear" "fear" "fear" "fear"
		
		; Disable HO for all and run HO_Helper script
		call HO "Disable" "FALSE"
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "${_NamedNPC2}"
		variable bool HOEnabled=FALSE
		
		; Set Loot settings for last boss
		call SetLootForLastBoss
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Need to cast an HO to send Zakir-Sar-Ussur into the mirror
			; If not done within 60 seconds group wipes (40 H2)
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC1}",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["${_NamedNPC2}",0,FALSE,FALSE]
			; Pull named
			oc ${Me.Name} is pulling ${_NamedNPC1}
			while !${Me.InCombat}
			{
				Actor["${_NamedNPC1}"]:DoTarget
				wait 10
			}
			; Kill named
			while ${Me.InCombat}
			{	
				; If Zakir-Sar-Ussur is the Target, enable HO to send him into the mirror
				if !${HOEnabled} && ${Target.Name.Equal[${_NamedNPC1}]}
				{
					eq2execute cancel_ho_starter
					; In Solo zone, can use any HO
					if ${Zone.Name.Equals["${Solo_Zone_Name}"]}
						call HO "All" "FALSE"
					; In Heroic zone, specifically need HO started by Fighter
					else
						call HO "Fighter" "FALSE"
					HOEnabled:Set[TRUE]
				}
				; If no effect, disable HO for all
				elseif ${HOEnabled}
				{
					call HO "Disable" "FALSE"
					HOEnabled:Set[FALSE]
					wait 10
					eq2execute cancel_ho_starter
				}
				; Wait a second before checking again
				wait 10
			}
			Ob_AutoTarget:Clear
		}
		
		; Check named is dead
		if ${Actor[namednpc,"${_NamedNPC1}"].ID(exists)} || ${Actor[namednpc,"${_NamedNPC2}"].ID(exists)}
		{
			Obj_OgreIH:Message_FailedToKill["${_NamedNPC1}"]
			return FALSE
		}
		
		; Disable HO for all
		call HO "Disable" "FALSE"
		
		; Get Chest
		eq2execute summon
		wait 10
		call Obj_OgreIH.Get_Chest
		
		; Look for shinies
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "602.10,71.11,-36.00"
			call move_to_next_waypoint "601.90,71.34,-0.18" "10"
			; If there is still a shiny, check room across from named
			if ${Actor[Query,Name=="?" && Distance < 100](exists)}
			{
				call move_to_next_waypoint "602.37,71.26,33.22" "5"
				call move_to_next_waypoint "590.22,72.18,44.38" "10"
				call move_to_next_waypoint "602.37,71.26,33.22" "5"
				call move_to_next_waypoint "610.41,71.11,48.27" "10"
				call move_to_next_waypoint "602.37,71.26,33.22" "5"
				call move_to_next_waypoint "601.90,71.34,-0.18" "10"
				; If there is still a shiny, check back rooms
				if ${Actor[Query,Name=="?" && Distance < 100](exists)}
				{
					call move_to_next_waypoint "563.35,71.32,-0.14" "5"
					call move_to_next_waypoint "553.17,71.43,-6.99" "5"
					call move_to_next_waypoint "552.96,71.12,-35.37" "20"
					call move_to_next_waypoint "562.24,71.16,-60.86"
					call move_to_next_waypoint "552.96,71.12,-35.37" "20"
					call move_to_next_waypoint "553.17,71.43,-6.99" "5"
					call move_to_next_waypoint "563.35,71.32,-0.14" "5"
					if ${Actor[Query,Name=="?" && Distance < 100](exists)}
					{
						call move_to_next_waypoint "553.17,71.43,6.99" "5"
						call move_to_next_waypoint "552.96,71.12,35.37" "15"
						call move_to_next_waypoint "564.51,72.93,51.70" "15"
						call move_to_next_waypoint "547.82,71.18,62.14" "15"
						call move_to_next_waypoint "564.51,72.93,51.70" "15"
						call move_to_next_waypoint "552.96,71.12,35.37" "15"
						call move_to_next_waypoint "553.17,71.43,6.99" "5"
						call move_to_next_waypoint "563.35,71.32,-0.14" "5"
					}
					call move_to_next_waypoint "601.90,71.34,-0.18" "10"
				}
				call move_to_next_waypoint "602.10,71.11,-36.00"
			}
		}
		
		; Finished with named
		return TRUE
	}
}

/***********************************************************************************************************
***********************************************  FUNCTIONS  ************************************************    
************************************************************************************************************/

function SetupPets(bool EnablePets)
{
	; It seems like Hezodhan can hit pets with Breath of Sand and cause extra Sand Squalls to form, 
	; 	so disabling as many pets as possible during fight (maybe leave some that are critical for dps)
	
	; Ranger pets
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+ranger "Hawk Attack" ${EnablePets} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+ranger "Heartseeker Hawk" ${EnablePets} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+ranger "Sniper Squad" ${EnablePets} TRUE
	; Dirge pets
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+dirge "Dancing Precession" ${EnablePets} TRUE
	; Coercer pets
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+coercer "Mastermind" ${EnablePets} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+coercer "Possess Essence" ${EnablePets} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+coercer "Puppetmaster" ${EnablePets} TRUE
	; Fury pets
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fury "Ball Lightning" ${EnablePets} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fury "Ring of Fire" ${EnablePets} TRUE
	; Mystic pets
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Ancestral Sentry" ${EnablePets} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Lunar Attendant" ${EnablePets} TRUE
	;oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Mystical Hex Ward" ${EnablePets} TRUE
	oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Summon Spirit Companion" ${EnablePets} TRUE
	; Dismiss all pets if disabling them
	if !${EnablePets}
	{
		wait 1
		relay ${OgreRelayGroup} eq2execute pet getlost
	}
}

function GetOrb(string OrbName, string OrbAction)
{
	; Make sure not in combat
	oc !ci -PetOff igw:${Me.Name}
	call Obj_OgreUtilities.HandleWaitForCombat	
	; See if orb still exists
	if ${Actor[Query,Name=="${OrbName}"](exists)}
	{
		; Get Orb
		wait 20
		face ${OrbName}
		wait 10
		oc !ci -ApplyVerbForWho ${Me.Name} "${OrbName}" "${OrbAction}"
		wait 50
	}
}
