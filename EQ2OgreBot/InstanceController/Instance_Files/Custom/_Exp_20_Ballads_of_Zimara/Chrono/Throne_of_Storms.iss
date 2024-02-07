; This IC file requires ChronoHelperScript/IC_Helper files to function
variable string ChronoHelperScript="EQ2OgreBot/InstanceController/Support_Files_Common/Chrono_Helper"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Ogre_Instance_Include.iss"

variable string sZoneName="Throne of Storms"

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
			call This.Named1 "Allectus Prime Karsgard"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#1: Allectus Prime Karsgard"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 2
		if ${_StartingPoint} == 2
		{
			call This.Named2 "Wolfmaster Oor"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#2: Wolfmaster Oor"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 3
		if ${_StartingPoint} == 3
		{
			call This.Named3 "Decanus Prime Vundr"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#3: Decanus Prime Vundr"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 4
		if ${_StartingPoint} == 4
		{
			call This.Named4 "Weapons Master Korin"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#4: Weapons Master Korin"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 5
		if ${_StartingPoint} == 5
		{
			call This.Named5 "Arch-Depracator Vorkin"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#5: Arch-Depracator Vorkin"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 6
		if ${_StartingPoint} == 6
		{
			call This.Named6 "Tribunus-Prime Hagandr"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#6: Tribunus-Prime Hagandr"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Exit Script
		return TRUE
	}

/**********************************************************************************************************
    Named 1 *******************    Move to, spawn and kill - Allectus Prime Karsgard   ********************
***********************************************************************************************************/

	function:bool Named1(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-121.53,-29.82,1455.82]
		
		; Use Chrono Dungeon item to make this a Chrono zone
		call UseChronoDungeonItem
		if !${Return}
		{
			Obj_OgreIH:Message_FailedToKill["#1: Krindem Sigmundr"]
			return FALSE
		}
		
		; Move to named
		call move_to_next_waypoint "-85.13,-12.04,793.18" "1"
		call move_to_next_waypoint "-84.92,-12.04,872.04" "1"
		call move_to_next_waypoint "-85.84,-12.04,967.09" "1"
		call move_to_next_waypoint "-85.68,-12.04,1006.61" "1"
		call move_to_next_waypoint "-85.75,-12.04,1102.61" "1"
		call move_to_next_waypoint "-85.86,-12.04,1134.86" "1"
		call move_to_next_waypoint "-126.57,-12.04,1140.94" "1"
		call move_to_next_waypoint "-122.43,-17.41,1205.06" "1"
		call move_to_next_waypoint "-121.08,-19.32,1340.46" "1"
		call move_to_next_waypoint "${KillSpot}" "1"
		
		; Wait for dialog to spawn and kill named
		while ${Actor[Query,Name=="Allectus Prime Karsgard" && Type != "Corpse" && Distance < 20].ID(exists)}
		{
			wait 10
		}
		
		; Kill named
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		call move_to_next_waypoint "${KillSpot}" "1"
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
    Named 2 **********************    Move to, spawn and kill - Wolfmaster Oor   **************************
***********************************************************************************************************/

	function:bool Named2(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[228.19,21.15,1258.47]
		
		; Move to named and kill it
		call move_to_next_waypoint "-121.08,-19.32,1340.46" "1"
		call move_to_next_waypoint "-32.40,-20.47,1258.51" "1"
		call move_to_next_waypoint "22.15,0.85,1260.96" "1"
		call move_to_next_waypoint "83.26,13.77,1301.44" "1"
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		call move_to_next_waypoint "${KillSpot}" "1"
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 3 ********************    Move to, spawn and kill - Decanus Prime Vundr  ************************
***********************************************************************************************************/

	function:bool Named3(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[154.44,20.17,1847.50]
		
		; Move to named
		call move_to_next_waypoint "83.26,13.77,1301.44" "1"
		call move_to_next_waypoint "22.15,0.85,1260.96" "1"
		call move_to_next_waypoint "-32.40,-20.47,1258.51" "1"
		call move_to_next_waypoint "-47.90,-20.47,1282.56" "1"
		call move_to_next_waypoint "50.65,-20.47,1441.90" "1"
		call move_to_next_waypoint "69.81,-7.40,1472.60" "1"
		call move_to_next_waypoint "38.33,13.91,1561.34" "1"
		call move_to_next_waypoint "144.05,20.17,1656.74" "1"
		call move_to_next_waypoint "150.85,20.17,1779.84" "1"
		
		; Wait for named to spawn if arrived too early
		while !${Actor[Query,Name=="Decanus Prime Vundr" && Type == "NamedNPC" && Distance < 100].ID(exists)}
		{
			wait 10
		}
		
		; Kill named
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		Ob_AutoTarget:AddActor["Lion of Ages",0,FALSE,FALSE]
		call move_to_next_waypoint "${KillSpot}" "1"
		
		; Combat ends for a bit before Lion of Ages spawns, make sure don't leave before killing him
		wait 20
		
		; Kill named
		call move_to_next_waypoint "${KillSpot}" "1"
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 4 ********************    Move to, spawn and kill - Weapons Master Korin  ***********************
***********************************************************************************************************/

	function:bool Named4(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-533.22,21.15,1244.00]
		
		; Move to named
		call move_to_next_waypoint "144.05,20.17,1656.74" "1"
		call move_to_next_waypoint "38.33,13.91,1561.34" "1"
		call move_to_next_waypoint "69.81,-7.40,1472.60" "1"
		call move_to_next_waypoint "50.65,-20.47,1441.90" "1"
		call move_to_next_waypoint "-110.36,-29.56,1409.01" "1"
		call move_to_next_waypoint "-282.63,-20.47,1380.33" "1"
		call move_to_next_waypoint "-243.44,-9.55,1323.24" "1"
		call move_to_next_waypoint "-256.78,1.17,1291.24" "1"
		call move_to_next_waypoint "-369.24,22.12,1278.83" "1"
		call move_to_next_waypoint "-473.09,21.15,1280.23" "1"
		call move_to_next_waypoint "-532.35,21.15,1281.15" "1"
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		call move_to_next_waypoint "${KillSpot}" "1"
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 5 ********************    Move to, spawn and kill - Arch-Depracator Vorkin  *********************
***********************************************************************************************************/

	function:bool Named5(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-380.45,20.17,1759.39]
		
		; Move to named
		call move_to_next_waypoint "-532.35,21.15,1281.15" "1"
		call move_to_next_waypoint "-473.09,21.15,1280.23" "1"
		call move_to_next_waypoint "-369.24,22.12,1278.83" "1"
		call move_to_next_waypoint "-256.78,1.17,1291.24" "1"
		call move_to_next_waypoint "-243.44,-9.55,1323.24" "1"
		call move_to_next_waypoint "-282.63,-20.47,1380.33" "1"
		call move_to_next_waypoint "-330.91,-20.47,1444.81" "1"
		call move_to_next_waypoint "-285.62,13.95,1560.02" "1"
		call move_to_next_waypoint "-341.54,22.12,1621.46" "1"
		call move_to_next_waypoint "-340.92,20.17,1759.19" "1"
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		call move_to_next_waypoint "${KillSpot}" "1"
		
		; Should be finished here and have enough kills to get the best reward, but have had issues with some kills not registering
		; 	so continuing on to fill the final boss to make sure we have enough
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 6 ********************    Move to, spawn and kill - Tribunus-Prime Hagandr  *********************
***********************************************************************************************************/

	function:bool Named6(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-119.38,-29.82,1437.07]
		
		; Move to named
		call move_to_next_waypoint "-340.92,20.17,1759.19" "1"
		call move_to_next_waypoint "-341.54,22.12,1621.46" "1"
		call move_to_next_waypoint "-285.62,13.95,1560.02" "1"
		call move_to_next_waypoint "-330.91,-20.47,1444.81" "1"
		call move_to_next_waypoint "-282.63,-20.47,1380.33" "1"
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		call move_to_next_waypoint "${KillSpot}" "1"
		; Waiting here just to make sure fully out of combat before ending script
		wait 60
		while ${Me.InCombat}
		{
			wait 10
		}
		
		; Finished with named
		return TRUE
	}
}
