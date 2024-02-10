; This IC file requires HOHelperScript/MendRuneSwapHelperScript/IC_Helper files to function
variable string HOHelperScript="HO_Helper"
variable string MendRuneSwapHelperScript="EQ2OgreBot/InstanceController/Support_Files_Common/Mend_Rune_Swap_Helper"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"

variable string Solo_Zone_Name="Splendor Sky Aerie: Marshlands Miasma [Solo]"
variable string Heroic_1_Zone_Name="Splendor Sky Aerie: Marshlands Miasma [Event Heroic I]"

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
			call This.Named1 "Droseraceae"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#1: Droseraceae"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 2
		if ${_StartingPoint} == 2
		{
			call This.Named2 "Nerjehl Khaneh"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#2: Nerjehl Khaneh"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 3
		if ${_StartingPoint} == 3
		{
			call This.Named3 "Miasmasula"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#3: Miasmasula"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		
		; Zone Out
		if ${_StartingPoint} == 4
		{
			call move_to_next_waypoint "784.78,50.90,-43.70" "1"
			Ob_AutoTarget:Clear
			Obj_OgreIH:LetsGo
			oc ${Me.Name} looted ${ShiniesLooted} shinies
			call ZoneOut "Exit"
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
    Named 1 **********************    Move to, spawn and kill - Droseraceae  ********************************
***********************************************************************************************************/

	function:bool Named1(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[837.52,60.10,220.53]
		
		; Repair if needed
		call mend_and_rune_swap "noswap" "noswap" "noswap" "noswap"
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "1"
		call move_to_next_waypoint "718.03,73.33,344.76"
		call move_to_next_waypoint "781.72,59.33,290.93"
		call move_to_next_waypoint "806.71,62.27,254.80"
		
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
			call Obj_OgreUtilities.PreCombatBuff 5
			wait 50
			call Tank_n_Spank "${_NamedNPC}" "${KillSpot}"
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
		
		; Look for shinies
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "807.14,62.18,253.54"
			call move_to_next_waypoint "811.43,62.12,217.15"
			call move_to_next_waypoint "822.28,61.98,186.20"
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 2 ********************    Move to, spawn and kill - Nerjehl Khaneh  ********************************
***********************************************************************************************************/

	function:bool Named2(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[831.76,43.54,122.67]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "2"
		call move_to_next_waypoint "818.61,62.78,176.58"
		call move_to_next_waypoint "822.80,58.29,154.78"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Named wanders around, may need to path around lake to aggro
		Move_Needed:Set[TRUE]
		call move_if_needed "${_NamedNPC}" "${KillSpot}"
		call move_if_needed "${_NamedNPC}" "788.74,44.15,118.77"
		call move_if_needed "${_NamedNPC}" "831.76,43.54,122.67"
		call move_if_needed "${_NamedNPC}" "844.44,49.72,92.33"
		call move_if_needed "${_NamedNPC}" "848.43,49.08,27.21"
		call move_if_needed "${_NamedNPC}" "797.87,45.50,-12.45"
		call move_if_needed "${_NamedNPC}" "762.04,44.76,-0.95"
		call move_if_needed "${_NamedNPC}" "757.89,44.80,32.74"
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_n_Spank "${_NamedNPC}" "${KillSpot}"
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
		
		; Skip shinies, will check after last boss
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 3 *********************    Move to, spawn and kill - Miasmasula ********************************
***********************************************************************************************************/

	function:bool Named3(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[790.90,41.62,45.12]
		
		; Setup for named
		call initialize_move_to_next_boss "${_NamedNPC}" "3"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Set Loot settings for last boss
		call SetLootForLastBoss
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_n_Spank "${_NamedNPC}" "${KillSpot}"
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
		
		; Look for shinies
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "823.49,44.15,122.85"
			call move_to_next_waypoint "771.30,44.15,122.20"
			call move_to_next_waypoint "754.79,44.15,123.00"
			call move_to_next_waypoint "795.91,44.15,117.18"
			call move_to_next_waypoint "${KillSpot}"
			call move_to_next_waypoint "772.63,44.76,-8.65"
			call move_to_next_waypoint "782.88,44.90,-16.31"
			call move_to_next_waypoint "811.14,45.65,-2.46"
			call move_to_next_waypoint "782.88,44.90,-16.31"
		}
		
		; Finished with named
		return TRUE
	}
}
