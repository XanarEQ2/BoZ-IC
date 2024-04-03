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
			call This.Named2 "Vilmen Riggandr"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#2: Vilmen Riggandr"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 3
		if ${_StartingPoint} == 3
		{
			call This.Named3 "Grundr Kolfrodr"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#3: Grundr Kolfrodr"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 4
		if ${_StartingPoint} == 4
		{
			call This.Named4 "Sjurd Randskeggr"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#4: Sjurd Randskeggr"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 5
		if ${_StartingPoint} == 5
		{
			call This.Named5 "Halkon Tormax"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#5: Halkon Tormax"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 6
		if ${_StartingPoint} == 6
		{
			call This.Named6 "Praefectus Kriegr"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#6: Praefectus Kriegr"]
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
		; Update KillSpot
		KillSpot:Set[-564.24,106.19,117.67]
		
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
		oc !ci -ChangeCampSpotWho igw:${Me.Name} -559.90 91.43 64.55
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		call move_to_next_waypoint "${KillSpot}" "1"
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 2 ********************    Move to, spawn and kill - Vilmen Riggandr  ****************************
***********************************************************************************************************/

	function:bool Named2(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-457.16,118.24,570.04]
		
		; Move to named
		call move_to_next_waypoint "-564.22,118.70,185.58" "1"
		call move_to_next_waypoint "-563.48,115.59,380.33" "1"
		call move_to_next_waypoint "-562.65,115.59,447.80" "1"
		call move_to_next_waypoint "-552.01,115.59,461.53" "1"
		call move_to_next_waypoint "-495.93,118.27,483.44" "1"
		call move_to_next_waypoint "-501.11,118.27,510.32" "1"
		call move_to_next_waypoint "-501.11,118.27,577.38" "1"
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		call move_to_next_waypoint "${KillSpot}" "1"
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 3 ********************    Move to, spawn and kill - Grundr Kolfrodr  ****************************
***********************************************************************************************************/

	function:bool Named3(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-480.53,148.36,277.14]
		
		; Move to named
		call move_to_next_waypoint "-457.16,118.24,570.04" "1"
		call move_to_next_waypoint "-460.47,117.52,472.87" "1"
		call move_to_next_waypoint "-420.24,118.27,463.31" "1"
		call move_to_next_waypoint "-420.95,117.66,350.55" "1"
		call move_to_next_waypoint "-464.32,117.52,288.22" "1"
		call move_to_next_waypoint "-440.11,121.06,291.19" "1"
		wait 20
		oc !ci -ApplyVerbForWho ${Me.Name} "screw_elevator_control" "Lower Lift"
		wait 80
		call move_to_next_waypoint "-429.55,121.68,290.76" "1"
		wait 60
		oc !ci -ApplyVerbForWho ${Me.Name} "screw_elevator_control" "Raise Lift"
		wait 100
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		call move_to_next_waypoint "${KillSpot}" "1"
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 4 ********************    Move to, spawn and kill - Sjurd Randskeggr  ***************************
***********************************************************************************************************/

	function:bool Named4(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-652.07,148.36,295.34]
		
		; Move to named
		call move_to_next_waypoint "-490.76,117.52,348.08" "1"
		call move_to_next_waypoint "-528.76,118.27,364.49" "1"
		call move_to_next_waypoint "-604.54,118.27,362.45" "1"
		call move_to_next_waypoint "-668.69,117.52,323.88" "1"
		call move_to_next_waypoint "-666.80,117.52,290.66" "1"
		call move_to_next_waypoint "-685.76,121.06,294.40" "1"
		wait 20
		oc !ci -ApplyVerbForWho ${Me.Name} "screw_elevator_control" "Lower Lift"
		wait 80
		call move_to_next_waypoint "-695.29,121.68,294.02" "1"
		wait 60
		oc !ci -ApplyVerbForWho ${Me.Name} "screw_elevator_control" "Raise Lift"
		wait 100
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		call move_to_next_waypoint "${KillSpot}" "1"
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 5 ********************    Move to, spawn and kill - Halkon Tormax  ******************************
***********************************************************************************************************/

	function:bool Named5(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-706.75,117.58,538.20]
		
		; Move to named
		call move_to_next_waypoint "-643.17,148.36,311.69" "1"
		call move_to_next_waypoint "-659.47,117.52,343.57" "1"
		call move_to_next_waypoint "-707.74,117.88,350.21" "1"
		call move_to_next_waypoint "-707.97,118.01,473.20" "1"
		call move_to_next_waypoint "-695.70,117.52,497.62" "1"
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		call move_to_next_waypoint "${KillSpot}" "1"
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 6 ********************    Move to, spawn and kill - Praefectus Kriegr  **************************
***********************************************************************************************************/

	function:bool Named6(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-544.34,118.27,562.53]
		
		; Move to named
		call move_to_next_waypoint "-697.76,117.52,513.94" "1"
		call move_to_next_waypoint "-593.83,118.27,467.26" "1"
		call move_to_next_waypoint "-564.20,118.27,496.97" "1"
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		call move_to_next_waypoint "${KillSpot}" "1"
		
		; Finished with named
		return TRUE
	}
}
