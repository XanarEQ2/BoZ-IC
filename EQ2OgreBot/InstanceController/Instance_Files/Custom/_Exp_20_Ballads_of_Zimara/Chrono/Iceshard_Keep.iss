; This IC file requires ChronoHelperScript/IC_Helper files to function
variable string ChronoHelperScript="EQ2OgreBot/InstanceController/Support_Files_Common/Chrono_Helper"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Ogre_Instance_Include.iss"

variable string sZoneName="Iceshard Keep"

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
			_StartingPoint:Inc

			; Change starting point below to start script after a certain named. (for debugging only)		
			_StartingPoint:Set[0]
			_StartingPoint:Inc
		}
		; Move to and kill Named 1
		if ${_StartingPoint} == 1
		{
			call This.Named1 "Krindem Sigmundr"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#1: Krindem Sigmundr"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 2
		if ${_StartingPoint} == 2
		{
			call This.Named2 "Praefectus Kriegr"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#2: Praefectus Kriegr"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		
		; Exit Script
		return TRUE
	}

/**********************************************************************************************************
    Named 1 **********************    Move to, spawn and kill - Krindem Sigmundr   ***********************
***********************************************************************************************************/

	function:bool Named1(string _NamedNPC="Doesnotexist")
	{
		; Use Chrono Dungeon item to make this a Chrono zone
		call UseChronoDungeonItem
		if !${Return}
		{
			Obj_OgreIH:Message_FailedToKill["#1: Krindem Sigmundr"]
			return FALSE
		}
		
		; Back off pets (will get aggro from named at long range and don't want pets runing off and getting aggro)
		oc !ci -PetOff igw:${Me.Name}
		
		; Move to named and kill it
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		oc !ci -ChangeCampSpotWho "igw:${Me.Name}" -559.90 91.43 64.55
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		call move_to_next_waypoint "-564.24,106.19,117.67" "1"
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 2 ********************    Move to, spawn and kill - Praefectus Kriegr  **************************
***********************************************************************************************************/

	function:bool Named2(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-530.91,118.27,575.53]
		
		; Move to named
		call move_to_next_waypoint "-564.27,94.64,98.97" "1"
		call move_to_next_waypoint "-564.22,118.70,185.58" "1"
		call move_to_next_waypoint "-563.48,115.59,380.33" "1"
		call move_to_next_waypoint "-562.65,115.59,447.80" "1"
		call move_to_next_waypoint "-581.82,115.59,472.86" "1"
		call move_to_next_waypoint "-551.63,118.27,518.44" "1"
		call move_to_next_waypoint "${KillSpot}" "1"
		
		; Back off pets (will get aggro from other named at long range and don't want pets runing off and getting aggro)
		oc !ci -PetOff igw:${Me.Name}
		
		; Wait for named to spawn
		while !${Actor[Query,Name=="${_NamedNPC}" && Type == "NamedNPC" && Distance < 40].ID(exists)}
		{
			wait 10
		}
		
		; Enter combat with named (will pull the rest of the named in the zone)
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		while !${Me.InCombat}
		{
			Actor[Query,Name=="${_NamedNPC}"]:DoTarget
			wait 10
		}
		
		; Wait for combat to end
		while ${Me.InCombat}
		{
			wait 10
		}
		
		; Finished with named
		return TRUE
	}
}
