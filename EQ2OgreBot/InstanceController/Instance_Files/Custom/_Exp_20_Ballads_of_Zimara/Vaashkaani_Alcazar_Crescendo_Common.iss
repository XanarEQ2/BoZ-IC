; This IC file requires HOHelperScript/MendRuneSwapHelperScript/IC_Helper files to function
variable string HOHelperScript="HO_Helper"
variable string MendRuneSwapHelperScript="EQ2OgreBot/InstanceController/Support_Files_Common/Mend_Rune_Swap_Helper"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"

variable string Solo_Zone_Name="Vaashkaani: Alcazar Crescendo [Solo]"

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
			call This.Named1 "Khazinehdar Zuhraasa"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#1: Khazinehdar Zuhraasa"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 2
		if ${_StartingPoint} == 2
		{
			call This.Named2 "Zakir-Sar-Ussur"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#2: Zakir-Sar-Ussur"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 3
		if ${_StartingPoint} == 3
		{
			call This.Named3 "Kapuji-bashi Haakhaz"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#3: Kapuji-bashi Haakhaz"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 4
		if ${_StartingPoint} == 4
		{
			call This.Named4 "General Ra'Zaal"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#4: General Ra'Zaal"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		
		; Zone Out
		if ${_StartingPoint} == 5
		{
			call move_to_next_waypoint "367.52,20.85,-335.01"
			Ob_AutoTarget:Clear
			Obj_OgreIH:LetsGo
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
    Named 1 **********************    Move to, spawn and kill - Khazinehdar Zuhraasa   ********************
***********************************************************************************************************/

	function:bool Named1(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[614.50,71.14,-45.40]
		
		; Repair if needed
		call mend_and_rune_swap "noswap" "noswap" "noswap" "noswap"
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "1"
		call move_to_next_waypoint "521.58,71.37,16.98"
		call move_to_next_waypoint "521.55,71.37,0.24"
		call move_to_next_waypoint "601.88,71.34,-0.07"
		call move_to_next_waypoint "602.14,71.36,-30.95"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Kill named
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		call Tank_n_Spank "${_NamedNPC}" "${KillSpot}"
		Ob_AutoTarget:Clear
		
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
 	Named 2 ********************    Move to, spawn and kill - Zakir-Sar-Ussur  ****************************
***********************************************************************************************************/

	function:bool Named2(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[841.62,70.20,-0.35]
		
		; Setup and move to named (should pick up shiny from last boss on the way)
		call initialize_move_to_next_boss "${_NamedNPC}" "2"
		call move_to_next_waypoint "602.14,71.36,-30.95"
		call move_to_next_waypoint "601.88,71.34,-0.07"
		call move_to_next_waypoint "623.09,71.38,-0.13"
		call EnterPortal "portal_to_throne_from_hoard"
		call move_to_next_waypoint "790.71,71.37,-0.03"
		call move_to_next_waypoint "801.25,70.41,-28.86"
		call move_to_next_waypoint "821.64,71.32,-47.84"
		call move_to_next_waypoint "854.15,70.41,-47.23"
		call move_to_next_waypoint "880.64,71.38,-30.91"
		call move_to_next_waypoint "888.76,70.41,-0.50"
		call move_to_next_waypoint "880.97,71.38,30.27"
		call move_to_next_waypoint "854.57,70.41,47.05"
		call move_to_next_waypoint "823.52,71.38,49.00"
		call move_to_next_waypoint "801.11,70.41,28.57"
		call move_to_next_waypoint "790.71,71.37,-0.03"
		call move_to_next_waypoint "801.25,70.41,-28.86"
		call move_to_next_waypoint "821.64,71.32,-47.84"
		call move_to_next_waypoint "854.15,70.41,-47.23"
		call move_to_next_waypoint "880.64,71.38,-30.91"
		call move_to_next_waypoint "888.76,70.41,-0.50"
		wait 20
		call EnterPortal "transport_carpet_01" "Travel"
		
		; Spawn Named
		Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		Obj_OgreIH:ChangeCampSpot["827.41,69.87,-0.11"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		wait 100
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			return TRUE
		}
		
		; Move to KillSpot
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
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
			; Check to see if named has "Sovereign's Reign" effect (needs to be removed using the Glorious Maestra's Cithara)
			; 	Can only use the Cithara after a bit of scripted text
			call CheckTargetEffect "Sovereign's Reign" "8"
			if ${Return}
			{
				; Pause Ogre
				oc !ci -Pause igw:${Me.Name}
				wait 3
				; Clear ability queue
				relay ${OgreRelayGroup} eq2execute clearabilityqueue
				; Cancel anything currently being cast
				oc !ci -CancelCasting igw:${Me.Name}
				; Use Glorious Maestra's Cithara
				wait 20
				Me.Inventory[Query, Name == "Glorious Maestra's Cithara" && Location == "Inventory"]:Use
				wait 20
				; Resume Ogre
				oc !ci -Resume igw:${Me.Name}
			}
			; Wait a second before looping
			wait 10
		}
		; Clear AutoTarget
		Ob_AutoTarget:Clear
		
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
 	Named 3 *********************    Move to, spawn and kill - Kapuji-bashi Haakhaz ***********************
***********************************************************************************************************/

	function:bool Named3(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[380.25,23.59,-356.39]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "3"
		call move_to_next_waypoint "848.37,70.57,-15.15"
		call EnterPortal "portal_from_throne_to_prison"
		call move_to_next_waypoint "225.07,35.44,-355.99"
		call move_to_next_waypoint "291.67,24.29,-356.14"
		call move_to_next_waypoint "298.40,24.54,-387.20"
		call move_to_next_waypoint "313.73,24.29,-395.74"
		call move_to_next_waypoint "327.25,20.88,-355.88"
		call move_to_next_waypoint "373.53,22.17,-356.34"
		call move_to_next_waypoint "${KillSpot}"
		
		; Pause Ogre
		oc !ci -Pause igw:${Me.Name}
		wait 3
		; Clear ability queue
		relay ${OgreRelayGroup} eq2execute clearabilityqueue
		; Cancel anything currently being cast
		oc !ci -CancelCasting igw:${Me.Name}
		
		; Hail Lyrissa Nostrolo
		wait 20
		oc !ci -HailNPC igw:${Me.Name} "Lyrissa Nostrolo"
		wait 20
		variable int Counter=0
		while ${Counter:Inc} <= 10
		{
			oc !ci -ConversationBubble igw:${Me.Name} "1"
			wait 10
		}
		
		; Set Arca Down
		wait 20
		oc !ci -ApplyVerbForWho igw:${Me.Name} "Arca Location" "Set Arca Down"
		wait 40
		
		; Hail Lyrissa Nostrolo (will spawn named)
		oc ${Me.Name} is pulling ${_NamedNPC}
		oc !ci -HailNPC igw:${Me.Name} "Lyrissa Nostrolo"
		wait 20
		oc !ci -ConversationBubble igw:${Me.Name} "1"
		
		; Resume Ogre
		oc !ci -Resume igw:${Me.Name}
		
		; Setup AutoTarget
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["a copper maedjinn",0,FALSE,FALSE]
		Ob_AutoTarget:AddActor["an iron maedjinn",0,FALSE,FALSE]
		Ob_AutoTarget:AddActor["a maedjinn saitahn",0,FALSE,FALSE]
		Ob_AutoTarget:AddActor["a maedjinn saitihn",0,FALSE,FALSE]
		Ob_AutoTarget:AddActor["a maedjinn zakhan",0,FALSE,FALSE]
		Ob_AutoTarget:AddActor["a maedjinn zakhin",0,FALSE,FALSE]
		Ob_AutoTarget:AddActor["a maedjinn alharan",0,FALSE,FALSE]
		Ob_AutoTarget:AddActor["a maedjinn alharin",0,FALSE,FALSE]
		Ob_AutoTarget:AddActor["a maedjinn elzhan",0,FALSE,FALSE]
		Ob_AutoTarget:AddActor["a maedjinn elzhin",0,FALSE,FALSE]
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		
		; Will have a series of mobs spawn followed by named
		; 	Wait until 10 seconds have passed without combat or a mob spawning
		Counter:Set[0]
		while ${Counter:Inc} <= 100
		{
			if ${Me.InCombat} || ${Actor[Query,(Name=-"maedjinn" || Name=="${_NamedNPC}") && Type != "Corpse" && Distance <= 50].ID(exists)}
				Counter:Set[0]
			wait 1
		}
		
		; Clear AutoTarget
		Ob_AutoTarget:Clear
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 4 *********************    Move to, spawn and kill - General Ra'Zaal ****************************
***********************************************************************************************************/

	function:bool Named4(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[321.18,20.88,-356.00]
		
		; Pause Ogre
		oc !ci -Pause igw:${Me.Name}
		wait 3
		; Clear ability queue
		relay ${OgreRelayGroup} eq2execute clearabilityqueue
		; Cancel anything currently being cast
		oc !ci -CancelCasting igw:${Me.Name}
		
		; Hail Lyrissa Nostrolo
		wait 20
		oc !ci -HailNPC igw:${Me.Name} "Lyrissa Nostrolo"
		wait 20
		variable int Counter=0
		while ${Counter:Inc} <= 10
		{
			oc !ci -ConversationBubble igw:${Me.Name} "1"
			wait 10
		}
		
		; Hail Vahravi
		wait 20
		oc !ci -HailNPC igw:${Me.Name} "Vahravi"
		wait 20
		Counter:Set[0]
		while ${Counter:Inc} <= 10
		{
			oc !ci -ConversationBubble igw:${Me.Name} "1"
			wait 10
		}
		
		; Resume Ogre
		oc !ci -Resume igw:${Me.Name}
		
		; Wait for named to spawn
		call move_to_next_waypoint "349.76,20.88,-356.28"
		wait 250
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}

		; Enable HO for all (needed to kill adds and named) and run HO_Helper script
		call HO "All" "FALSE"
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "${_NamedNPC}"
		
		; Kill named
		oc ${Me.Name} is pulling ${_NamedNPC}
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["Ra'Zaal's ghul",0,FALSE,FALSE]
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		wait 50
		while ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)} || ${Me.InCombat}
		{
			
			; Wait a second before looping
			wait 10
		}
		; Clear AutoTarget
		Ob_AutoTarget:Clear
		
		; Disable HO for all
		call HO "Disable" "FALSE"
		
		; Check named is dead
		if ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_FailedToKill["${_NamedNPC}"]
			return FALSE
		}
		
		; Finished with named
		return TRUE
	}
}
