; This IC file requires ZoneHelperScript/HOHelperScript/MendRuneSwapHelperScript/IC_Helper files to function
variable string ZoneHelperScript="EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/Vaashkaani_Argent_Sanctuary_Helper"
variable string HOHelperScript="HO_Helper"
variable string MendRuneSwapHelperScript="EQ2OgreBot/InstanceController/Support_Files_Common/Mend_Rune_Swap_Helper"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"

variable string Solo_Zone_Name="Vaashkaani: Argent Sanctuary [Solo]"
variable string Heroic_1_Zone_Name="Vaashkaani: Argent Sanctuary [Heroic I]"
variable string Heroic_2_Zone_Name="Vaashkaani: Argent Sanctuary [Heroic II]"

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
			call This.Named1 "Tazir Tanziri"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#1: Tazir Tanziri"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 2
		if ${_StartingPoint} == 2
		{
			call This.Named2 "Sansobog" "Akharys"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#2: Sansobog and Akharys"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 3
		if ${_StartingPoint} == 3
		{
			call This.Named3 "Uah'Lu the Unhallowed"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#3: Uah'Lu the Unhallowed"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 4
		if ${_StartingPoint} == 4
		{
			call This.Named4 "Xuxuquaxul"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#4: Xuxuquaxul"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 5
		if ${_StartingPoint} == 5
		{
			call This.Named5 "General Ra'Zaal"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#5: General Ra'Zaal"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		
		; Zone Out
		if ${_StartingPoint} == 6
		{
			call move_to_next_waypoint "111.48,10.32,-313.97"
			call move_to_next_waypoint "105.10,7.94,-318.15"
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
    Named 1 **********************    Move to, spawn and kill - Tazir Tanziri   ***************************
***********************************************************************************************************/

	function:bool Named1(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[96.91,3.53,0]
		
		; Repair if needed
		call mend_and_rune_swap "noswap" "noswap" "noswap" "noswap"
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "1"
		call move_to_next_waypoint "-48.93,3.06,-19.11"
		call move_to_next_waypoint "-13.98,2.95,-30.64"
		call move_to_next_waypoint "25.66,3.46,-28.24"
		call move_to_next_waypoint "34.87,3.50,-27.98"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "63.50,3.53,0"
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			; Move to center of room
			call Obj_OgreUtilities.PreCombatBuff 5
			wait 50
			oc !ci -PetOff igw:${Me.Name}
			Obj_OgreIH:ChangeCampSpot["63.50,3.53,0"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			oc ${Me.Name} is pulling ${_NamedNPC}
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			; Target a silver shard if it exists, othewise target Named
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["a silver shard",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			; Kill Named
			oc !ci -PetAssist igw:${Me.Name}
			while ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
			{
				; Make sure not within 10m of a shard
				if !${Actor[Query,Name=="a silver shard" && Distance <= 10].ID(exists)}
				{
					; Check to see if a silver shard exists within 55m
					ActorLoc:Set[${Actor[Query,Name=="a silver shard" && Distance < 55].Loc}]
					if ${ActorLoc.X}!=0 || ${ActorLoc.Y}!=0 || ${ActorLoc.Z}!=0
					{
						; Setup new location to move to shard (need to be at least 5m away to avoid "Shiner" det)
						NewLoc:Set[${ActorLoc.X},${ActorLoc.Y},0]
						NewLoc.X:Inc[6]
						; Move to NewLoc
						Obj_OgreIH:ChangeCampSpot["${NewLoc}"]
						call Obj_OgreUtilities.HandleWaitForCampSpot 10
					}
					; Move to center of room if no shard within 55m
					else
					{
						Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
						call Obj_OgreUtilities.HandleWaitForCampSpot 10
					}
				}
				; Wait before looping again
				Wait 30
			}
			Ob_AutoTarget:Clear
		}
		; For H2, similar start as H1 destroying shards, but named heals if within 10m of shards and need to be at least 10m away to avoid "Shiner"
		elseif ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Move to center of room
			call Obj_OgreUtilities.PreCombatBuff 5
			wait 50
			oc !ci -PetOff igw:${Me.Name}
			Obj_OgreIH:ChangeCampSpot["63.50,3.53,0"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			oc ${Me.Name} is pulling ${_NamedNPC}
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			; Clear AutoTarget, will selectively target
			Ob_AutoTarget:Clear
			; Kill Named
			Actor[${_NamedNPC}]:DoTarget
			wait 30
			oc !ci -PetAssist igw:${Me.Name}
			; Setup variables for current/next SilverShardID
			variable int CurrentSilverShardID
			variable int NextSilverShardID
			; Check for silver shards to kill during the fight
			while ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
			{
				; Check to see if there is a silver shard within 10m/20m/55m (want to kill any close shards first)
				NextSilverShardID:Set[${Actor[Query,Name=="a silver shard" && Distance <= 10 && Type != "Corpse"].ID}]
				if ${NextSilverShardID} == 0
					NextSilverShardID:Set[${Actor[Query,Name=="a silver shard" && Distance <= 20 && Type != "Corpse"].ID}]
				if ${NextSilverShardID} == 0
					NextSilverShardID:Set[${Actor[Query,Name=="a silver shard" && Distance <= 55 && Type != "Corpse"].ID}]
				; Update CurrentSilverShardID if needed (ID changed and actor with current ID doesn't exist anymore)
				if !${NextSilverShardID.Equal[${CurrentSilverShardID}]} && !${Actor[${CurrentSilverShardID}].ID(exists)}
				{
					CurrentSilverShardID:Set[${NextSilverShardID}]
					; Check to see if SilverShardID is valid
					if !${CurrentSilverShardID.Equal[0]} && ${Actor[${CurrentSilverShardID}].ID(exists)}
					{
						; Get location of silver shard
						ActorLoc:Set[${Actor[${CurrentSilverShardID}].Loc}]
						if ${ActorLoc.X}!=0 || ${ActorLoc.Y}!=0 || ${ActorLoc.Z}!=0
						{
							; Setup new location to move to shard (need to be at least 10m away to avoid "Shiner" det)
							; Note Z=0 at center path of room
							NewLoc:Set[${ActorLoc.X},${ActorLoc.Y},0]
							if ${ActorLoc.X} < 97
								NewLoc.X:Inc[12]
							else
								NewLoc.X:Dec[12]
							; Target shard (can only target through fighter)
							Actor[${CurrentSilverShardID}]:DoTarget
							; Move fighter to center wall, hopefully away from shards
							oc !ci -ChangeCampSpotWho igw:${Me.Name}+fighter 100.04 3.78 14.33
							; Move scouts and mages to kill silver shard
							oc !ci -ChangeCampSpotWho igw:${Me.Name}+scout|mage ${NewLoc.X} ${NewLoc.Y} ${NewLoc.Z}
							; Move priest between fighter and scouts/mages to heal everyone
							NewLoc.X:Set[(${NewLoc.X}+100.04)/2]
							NewLoc.Y:Set[(${NewLoc.Y}+3.78)/2]
							NewLoc.Z:Set[(${NewLoc.Z}+14.33)/2]
							oc !ci -ChangeCampSpotWho igw:${Me.Name}+priest ${NewLoc.X} ${NewLoc.Y} ${NewLoc.Z}
							; Wait a few seconds, then check again
							wait 30
							continue
						}
					}
					; If not changing location to kill a silver shard, move back to named at KillSpot
					oc !ci -ChangeCampSpotWho igw:${Me.Name} ${KillSpot.X} ${KillSpot.Y} ${KillSpot.Z}
				}
				; Wait before looping again
				Wait 30
			}
		}
		
		; Get Chest
		eq2execute summon
		wait 10
		call Obj_OgreIH.Get_Chest

		; Move everyone to KillSpot after fight
		call move_to_next_waypoint "${KillSpot}"
		
		; Check named is dead
		if ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_FailedToKill["${_NamedNPC}"]
			return FALSE
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 2 ********************    Move to, spawn and kill - Sansobog and Akharys  ***********************
***********************************************************************************************************/

	function:bool Named2(string _NamedNPC1="Doesnotexist", string _NamedNPC2="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[213.13,3.45,62.91]
		
		; If H1/H2, swap to stun immunity rune for fighter and mez immunity rune for scout/mage/priest
		; 	doing here instead of right before boss because don't want to potentially be stuck in combat with a wandering add
		if ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			call mend_and_rune_swap "stun" "mez" "mez" "mez"
		
		; Setup and move to named (should pick up shiny from last boss on the way)
		call initialize_move_to_next_boss "${_NamedNPC1}" "2"
		call move_to_next_waypoint "165.13,3.76,-0.23" "5"
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "170.36,3.76,5.02" "2"
			call move_to_next_waypoint "165.13,3.76,-0.23" "5"
			call move_to_next_waypoint "170.33,3.76,-5.03" "2"
			call move_to_next_waypoint "165.13,3.76,-0.23" "5"
		}
		call move_to_next_waypoint "167.70,3.76,-21.93" "5"
		call move_to_next_waypoint "176.94,3.76,-23.18" "5"
		call move_to_next_waypoint "183.82,3.76,-0.10"
		call move_to_next_waypoint "213.75,3.46,0.01"
		call move_to_next_waypoint "213.36,3.45,34.72"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC1}"].ID(exists)} && !${Actor[namednpc,"${_NamedNPC2}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC1}"]
			Obj_OgreIH:ChangeCampSpot["213.68,3.46,-0.04"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			return TRUE
		}
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC1}",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["${_NamedNPC2}",0,FALSE,FALSE]
			call Tank_n_Spank2 "${_NamedNPC1}" "${_NamedNPC2}" "${KillSpot}"
			Ob_AutoTarget:Clear
		}
		; For H2, need to target named without Second Life and only have Twice Bitten curse cured when targeting the named that cast it
		elseif ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Clear AutoTarget, will selectively target
			Ob_AutoTarget:Clear
			; Disable Assist and Cure Curse
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_assist FALSE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_curecurse TRUE TRUE
			wait 1
			; Run ZoneHelperScript (will handle Targets and Cure Curse)
			; Note for this fight, if you have a Mystic make sure the Mystical Moppet is set to not cure curse or it can kill you
			oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
			oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC1}" "${_NamedNPC2}"
			wait 1
			; Move to KillSpot
			oc ${Me.Name} is pulling ${_NamedNPC1} and ${_NamedNPC2}
			Obj_OgreIH:SetCampSpot
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			oc !ci -PetOff igw:${Me.Name}
			wait 10
			oc !ci -PetAssist igw:${Me.Name}
			; Wait for both named to be killed
			while ${Actor[Query,Name=="${_NamedNPC1}" && Type != "Corpse"].ID(exists)} || ${Actor[Query,Name=="${_NamedNPC2}" && Type != "Corpse"].ID(exists)}
			{
				wait 10
			}
			; Re-enable Assist and Cure Curse
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notfighter checkbox_settings_assist TRUE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_curecurse FALSE TRUE
		}
		
		; Check named is dead
		if ${Actor[namednpc,"${_NamedNPC1}"].ID(exists)} || ${Actor[namednpc,"${_NamedNPC2}"].ID(exists)}
		{
			Obj_OgreIH:Message_FailedToKill["${_NamedNPC1}"]
			return FALSE
		}
		
		; Get Chest
		eq2execute summon
		wait 10
		call Obj_OgreIH.Get_Chest
		
		; Move back to center of hallway (don't want to check shinies at this point)
		call move_to_next_waypoint "${KillSpot}"
		Obj_OgreIH:ChangeCampSpot["213.68,3.46,-0.04"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 3 *********************    Move to, spawn and kill - Uah'Lu the Unhallowed **********************
***********************************************************************************************************/

	function:bool Named3(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[262.17,3.45,-65.12]
		
		; Look for shiny from last boss
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "213.32,3.45,-29.80"
			call move_to_next_waypoint "213.56,3.45,-56.43"
			call move_to_next_waypoint "213.68,3.46,-0.04"
		}
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "3"
		call move_to_next_waypoint "253.54,3.46,-0.34"
		call move_to_next_waypoint "262.17,3.75,-19.05"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			Obj_OgreIH:ChangeCampSpot["269.64,3.46,-0.70"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			return TRUE
		}
		
		; If H1/H2, swap to stifle immunity rune
		if ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			call mend_and_rune_swap "stifle" "stifle" "stifle" "stifle"
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_n_Spank "${_NamedNPC}" "${KillSpot}"
			Ob_AutoTarget:Clear
		}
		; For H2, Archetype-specific NoKill adds will spawn during the fight
		; Need a character of that Archetype to go over to the add and hail it to activate
		elseif ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Setup AutoTarget
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["a fallen fighter",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["a fallen scout",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["a fallen mage",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["a fallen priest",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			; Run ZoneHelperScript (will handle hailing adds)
			oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
			oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC}" ""
			wait 1
			; Move to KillSpot
			oc ${Me.Name} is pulling ${_NamedNPC}
			Obj_OgreIH:SetCampSpot
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			oc !ci -PetOff igw:${Me.Name}
			wait 10
			oc !ci -PetAssist igw:${Me.Name}
			; Wait for named to be killed
			while ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
			{
				wait 10
			}
			; Clear AutoTarget:Clear
			Ob_AutoTarget:Clear
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
		
		; Move back to hallway (don't want to check shinies at this point)
		Obj_OgreIH:ChangeCampSpot["262.17,3.75,-19.05"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		Obj_OgreIH:ChangeCampSpot["269.64,3.46,-0.70"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 4 *********************    Move to, spawn and kill - Xuxuquaxul *********************************
***********************************************************************************************************/

	function:bool Named4(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[86.74,11.43,-183.85]
		
		; Look for shiny from last boss
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "262.05,3.52,19.82"
			call move_to_next_waypoint "262.18,3.45,55.09"
			call move_to_next_waypoint "262.05,3.52,19.82"
			call move_to_next_waypoint "269.64,3.46,-0.70"
		}
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "4"
		call move_to_next_waypoint "295.10,3.64,0.14"
		call EnterPortal "portal_to_aviary"
		
		; Swap to fear immunity rune (before moving into room, otherwise could get caught in combat with a roaming mob when trying to swap)
		call mend_and_rune_swap "fear" "fear" "fear" "fear"
		
		; Continue to move to named
		call move_to_next_waypoint "-7.21,11.90,-247.23"
		call move_to_next_waypoint "60.71,11.43,-175.64"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_n_Spank "${_NamedNPC}" "${KillSpot}"
			Ob_AutoTarget:Clear
		}
		; For H2, named has Lead-Lined effect that reflects spells and increases damage based on increments
		; Group gets cureable Lead Poisoning that allows you to land spells, but damages you
		; Named has a single add, killing it resets the increments for Lead-Lined
		; On death of add, get Airy Annihilation (MainIconID 509, BackDropIconID 20) curse
		; Curing curse on one person cures from entire group, but locks aggro onto the person cured
		; If don't cure curse, character dies
		; Depending on group setup may need to keep Lead Poisoning on group and kill add if increments get high
		; For this script, just focus DPS on the named and cure the curse on tank if add dies
		elseif ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Setup AutoTarget
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			; Disable Cure Curse
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_curecurse TRUE TRUE
			wait 1
			; Move to KillSpot
			oc ${Me.Name} is pulling ${_NamedNPC}
			Obj_OgreIH:SetCampSpot
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			oc !ci -PetOff igw:${Me.Name}
			wait 10
			oc !ci -PetAssist igw:${Me.Name}
			; Wait for named to be killed
			while ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
			{
				; Check for curse that needs to be cured
				if ${Me.Effect[Query, Type == "Detrimental" && MainIconID == 509 && BackDropIconID == 20].ID(exists)}
				{
					; Set AutoCurse for group member to cure this character
					oc !ci -AutoCurse igw:${Me.Name} ${Me.Name}
					; Add wait time for curse to be cured
					wait 50
				}
				; Wait a few seconds before looping
				wait 30
			}
			; Clear AutoTarget:Clear
			Ob_AutoTarget:Clear
			; Re-enable Cure Curse
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_curecurse FALSE TRUE
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
			call move_to_next_waypoint "87.03,11.78,-225.44"
			call move_to_next_waypoint "157.51,11.77,-206.01"
			call move_to_next_waypoint "87.03,11.78,-225.44"
			; May be a shiny at this point on a ledge, use special code to handle
			Obj_OgreIH:ChangeCampSpot["124.17,11.42,-167.59"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			call Obj_OgreUtilities.HandleWaitForCombat
			call click_shiny
			call move_to_next_waypoint "87.03,11.78,-225.44"
			call move_to_next_waypoint "52.85,7.94,-207.51" "20"
			call move_to_next_waypoint "29.26,7.94,-232.25" "20"
			call move_to_next_waypoint "30.44,9.16,-271.96"
			call move_to_next_waypoint "29.26,7.94,-232.25" "20"
			call move_to_next_waypoint "52.85,7.94,-207.51" "20"
			call move_to_next_waypoint "87.03,11.78,-225.44"
			call move_to_next_waypoint "${KillSpot}"
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 5 *********************    Move to, spawn and kill - General Ra'Zaal ****************************
***********************************************************************************************************/

	function:bool Named5(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[97.58,7.94,-303.69]
		
		; If H2, swap to mez immunity rune (Shifting Minds detrimental mesmerizes group
		; 	(swapping at previous KillSpot because otherwise could get caught in combat with a roaming mob when trying to swap)
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			call mend_and_rune_swap "mez" "mez" "mez" "mez"
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "5"
		call move_to_next_waypoint "111.18,7.94,-242.13"
		call move_to_next_waypoint "96.90,7.94,-269.51"
		call move_to_next_waypoint "67.71,7.94,-291.53"
		
		; Check if already killed
		if !${Actor[Query,Name=="${_NamedNPC}"](exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}

		; Enable HO for all (needed to kill adds and named) and run HO_Helper script
		call HO "All" "FALSE"
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "${_NamedNPC}"
		
		; Buff to prepare for boss
		call Obj_OgreUtilities.PreCombatBuff 5
		wait 50
		
		; If H2, disable Cure during fight
		; Named casts noxious det Hubristic Pride (MainIconID 183, BackDropIconID 183)
		; 	Deals damage, need to not cure or target dies
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_cure TRUE TRUE
		
		; If named has not been spawned, kill adds and spawn named
		variable string _NamedAdds="Ra'Zaal's ghul"
		if ${Actor[Query,Name=="${_NamedNPC}" && Type=="NoKill NPC"](exists)}
		{
			; Kill adds
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedAdds}",0,FALSE,FALSE]
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			Actor["${_NamedAdds}"]:DoTarget
			wait 50
			call Obj_OgreUtilities.HandleWaitForCombat
			call Obj_OgreUtilities.WaitWhileGroupMembersDead
			wait 50
			; Spawn named
			while ${Actor[Query,Name=="${_NamedNPC}" && Type=="NoKill NPC"](exists)}
			{
				Actor["${_NamedNPC}"]:DoubleClick
				wait 10
			}
		}
		
		; Set Loot settings for last boss
		call SetLootForLastBoss
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			oc ${Me.Name} is pulling ${_NamedNPC}
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			wait 50
			while ${Me.InCombat}
			{
				; If there are adds, change target to kill them but try to make sure no HO running first
				if ${Actor[Query,Name=="${_NamedAdds}" && Type != "Corpse" && Distance < 20](exists)}
				{
					; Disable HO for all
					call HO "Disable" "FALSE"
					wait 10
					eq2execute cancel_ho_starter
					; Wait to give time for any HO to complete
					wait 120
					; Make sure adds still exist
					while ${Actor[Query,Name=="${_NamedAdds}" && Type != "Corpse" && Distance < 20](exists)}
					{
						; Update AutoTarget to kill adds
						Ob_AutoTarget:Clear
						Ob_AutoTarget:AddActor["Ra'Zaal's ghul",0,FALSE,FALSE]
						Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
						; Enable HO for all
						wait 30
						eq2execute cancel_ho_starter
						call HO "All" "FALSE"
					}
				}
				; If no adds, change target to kill named and enable HO
				else
				{
					; Update AutoTarget to kill named
					Ob_AutoTarget:Clear
					Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
					; Enable HO for all
					eq2execute cancel_ho_starter
					call HO "All" "FALSE"
					wait 50
				}
			}
			Ob_AutoTarget:Clear
		}
		
		; Disable HO for all
		call HO "Disable" "FALSE"
		
		; If H2, re-enable Cure
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_cure FALSE TRUE
		
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
			call move_to_next_waypoint "69.59,11.42,-334.69"
			call move_to_next_waypoint "51.25,11.42,-315.81"
			call move_to_next_waypoint "${KillSpot}"
			call move_to_next_waypoint "81.97,7.94,-278.35"
			call move_to_next_waypoint "129.67,20.01,-289.97" "5"
			call move_to_next_waypoint "149.69,30.18,-304.03" "10"
			call move_to_next_waypoint "174.54,30.16,-294.04"
			call move_to_next_waypoint "149.69,30.18,-304.03" "10"
			call move_to_next_waypoint "129.67,20.01,-289.97" "5"
			call move_to_next_waypoint "106.21,7.94,-254.85" "5"
			call move_to_next_waypoint "128.09,7.94,-249.25" "5"
			call move_to_next_waypoint "137.70,8.72,-265.00"
			call move_to_next_waypoint "128.09,7.94,-249.25" "5"
			call move_to_next_waypoint "106.21,7.94,-254.85" "5"
			call move_to_next_waypoint "81.92,7.94,-291.18"
			call move_to_next_waypoint "${KillSpot}"
		}
		
		; Finished with named
		return TRUE
	}
}

/***********************************************************************************************************
***********************************************  FUNCTIONS  ************************************************    
************************************************************************************************************/

function Tank_n_Spank2(string _NamedNPC1, string _NamedNPC2, point3f KillSpot)
{
	variable int iCount="0"
	oc ${Me.Name} is pulling ${_NamedNPC1} and ${_NamedNPC2}
	Obj_OgreIH:SetCampSpot
	Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
	call Obj_OgreUtilities.HandleWaitForCampSpot 10
	oc !ci -PetOff igw:${Me.Name}
	wait 10
	oc !ci -PetAssist igw:${Me.Name}
	if ${Actor[Query,Name=="${_NamedNPC1}" && Type != "Corpse"].ID(exists)}
	{
		Actor["${_NamedNPC1}"]:DoTarget
		wait 30
		while ${Actor[Query,Name=="${_NamedNPC1}" && Type != "Corpse"].ID(exists)}
		{
			if ${Actor[Query,Name=="${_NamedNPC1}" && Distance > 7](exists)}
			{
				while ${Actor[Query,Name=="${_NamedNPC1}" && Distance > 5](exists)} && ${iCount} < 15
				{
					iCount:Inc
					wait 10
				}
			}
			if (!${Obj_OgreIH.DuoMode} && !${Obj_OgreIH.SoloMode})
			{
				Obj_OgreIH:CCS_Actor_Position["${Actor[Query,Name=="${_NamedNPC1}"].ID}"]
				wait 100
			}
		}
	}
	if ${Actor[Query,Name=="${_NamedNPC2}" && Type != "Corpse"].ID(exists)}
	{
		Actor["${_NamedNPC2}"]:DoTarget
		wait 30
		while ${Actor[Query,Name=="${_NamedNPC2}" && Type != "Corpse"].ID(exists)}
		{
			if ${Actor[Query,Name=="${_NamedNPC2}" && Distance > 7](exists)}
			{
				while ${Actor[Query,Name=="${_NamedNPC2}" && Distance > 5](exists)} && ${iCount} < 15
				{
					iCount:Inc
					wait 10
				}
			}
			if (!${Obj_OgreIH.DuoMode} && !${Obj_OgreIH.SoloMode})
			{
				Obj_OgreIH:CCS_Actor_Position["${Actor[Query,Name=="${_NamedNPC2}"].ID}"]
				wait 100
			}
		}
	}
	call Obj_OgreUtilities.HandleWaitForCombat
	call Obj_OgreUtilities.WaitWhileGroupMembersDead
	wait 50
}
