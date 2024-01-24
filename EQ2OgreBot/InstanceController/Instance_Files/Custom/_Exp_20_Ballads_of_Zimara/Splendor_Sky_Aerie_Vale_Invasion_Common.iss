; This IC file requires HOHelperScript/MendRuneSwapHelperScript/IC_Helper files to function
variable string HOHelperScript="HO_Helper"
variable string MendRuneSwapHelperScript="EQ2OgreBot/InstanceController/Support_Files_Common/Mend_Rune_Swap_Helper"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"

variable string Solo_Zone_Name="Splendor Sky Aerie: Vale Invasion [Solo]"
variable string Heroic_1_Zone_Name="Splendor Sky Aerie: Vale Invasion [Event Heroic I]"

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
			call This.Named1 "Magmalatorr"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#1: Magmalatorr"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 2
		if ${_StartingPoint} == 2
		{
			call This.Named2 "Tkesh'Tura"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#2: Tkesh'Tura"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 3
		if ${_StartingPoint} == 3
		{
			call This.Named3 "Kusala'Din"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#3: Kusala'Din"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		
		; Zone Out
		if ${_StartingPoint} == 4
		{
			Ob_AutoTarget:Clear
			Obj_OgreIH:LetsGo
			call Obj_OgreUtilities.NavToLoc "-1094.85,181.88,738.30"
			call Obj_OgreUtilities.HandleWaitForGroupDistance 5
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
    Named 1 **********************    Move to, spawn and kill - Magmalatorr  ********************************
***********************************************************************************************************/

	function:bool Named1(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-744.51,62.91,406.45]
		
		; Repair if needed
		call mend_and_rune_swap "noswap" "noswap" "noswap" "noswap"
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "1"
		call move_to_next_waypoint "-782.94,74.66,297.97"
		call move_to_next_waypoint "-752.36,66.88,357.67"
		call move_to_next_waypoint "-747.83,64.33,379.08"
		
		; Check to see if named needs to be spawned
		call SpawnNamed "Kusala'Din" "${_NamedNPC}" "${KillSpot}" "-747.83,64.33,379.08"
		
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
			call move_to_next_waypoint "-746.61,63.05,416.21"
			call move_to_next_waypoint "-739.44,63.07,414.47"
			call move_to_next_waypoint "${KillSpot}"
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 2 ********************    Move to, spawn and kill - Tkesh'Tura  ********************************
***********************************************************************************************************/

	function:bool Named2(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-556.14,79.83,678.12]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "2"
		call move_to_next_waypoint "-738.42,58.19,483.52"
		call move_to_next_waypoint "-693.84,69.26,534.98"
		call move_to_next_waypoint "-636.36,58.63,600.89"
		call move_to_next_waypoint "-586.51,76.05,662.28"
		
		; Check to see if named needs to be spawned
		call SpawnNamed "Kusala'Din" "${_NamedNPC}" "${KillSpot}" "-586.51,76.05,662.28"
		
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
			call move_to_next_waypoint "-554.42,80.45,681.78"
			call move_to_next_waypoint "${KillSpot}"
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 3 *********************    Move to, spawn and kill - Kusala'Din ********************************
***********************************************************************************************************/

	function:bool Named3(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-1013.80,177.80,729.53]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "3"
		call move_to_next_waypoint "-643.33,57.66,601.89"		
		call move_to_next_waypoint "-712.96,75.91,609.86"
		call move_to_next_waypoint "-791.81,84.76,618.98"
		call EnterPortal "telelport crystal"
		call move_to_next_waypoint "-1004.29,175.46,690.85"
		
		; Check to see if named needs to be spawned
		call SpawnNamed "Kusala'Din" "${_NamedNPC}" "${KillSpot}" "-1004.29,175.46,690.85"
		
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
			call move_to_next_waypoint "-989.73,175.41,740.62"
			call move_to_next_waypoint "-1011.02,176.60,704.50"
			call move_to_next_waypoint "-1024.02,180.07,753.28"
			call move_to_next_waypoint "-1043.16,178.05,695.55"
		}
		
		; Finished with named
		return TRUE
	}
}

/***********************************************************************************************************
***********************************************  FUNCTIONS  ************************************************    
************************************************************************************************************/

function SpawnNamed(string _TempNPC, string _NamedNPC, point3f KillSpot, point3f JoustSpot)
{
	if ${Actor[Query,Name=="${_TempNPC}" && Type=="NoKill NPC" && Distance < 50](exists)}
	{
		Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		Obj_OgreIH:ChangeCampSpot["${JoustSpot}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		call Obj_OgreUtilities.PreCombatBuff 5
		wait 50
		while !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			wait 10
		}
	}
}