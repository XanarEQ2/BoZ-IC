; This IC file requires ZoneHelperScript/HOHelperScript/MendRuneSwapHelperScript/IC_Helper files to function
variable string ZoneHelperScript="EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/Zimara_Breadth_Razing_the_Razelands_Helper"
variable string HOHelperScript="HO_Helper"
variable string MendRuneSwapHelperScript="EQ2OgreBot/InstanceController/Support_Files_Common/Mend_Rune_Swap_Helper"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"

variable string Solo_Zone_Name="Zimara Breadth: Razing the Razelands [Solo]"
variable string Heroic_1_Zone_Name="Zimara Breadth: Razing the Razelands [Heroic I]"
variable string Heroic_2_Zone_Name="Zimara Breadth: Razing the Razelands [Heroic II]"

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
			call This.Named1 "Eaglovok"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#1: Eaglovok"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 2
		if ${_StartingPoint} == 2
		{
			call This.Named2 "Gilded Back Demolisher"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#2: Gilded Back Demolisher"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 3
		if ${_StartingPoint} == 3
		{
			call This.Named3 "Sina A'Rak"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#3: Sina A'Rak"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 4
		if ${_StartingPoint} == 4
		{
			call This.Named4 "Doda K'Bael"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#4: Doda K'Bael"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 5
		if ${_StartingPoint} == 5
		{
			call This.Named5 "Queen Era'selka"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#5: Queen Era'selka"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		
		; Zone Out
		if ${_StartingPoint} == 6
		{
			call move_to_next_waypoint "146.83,160.95,54.77" "1"
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
    Named 1 **********************    Move to, spawn and kill - Eaglovok   ********************************
***********************************************************************************************************/

	function:bool Named1(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-332.18,125.62,-658.49]
		
		; Repair if needed
		call mend_and_rune_swap "noswap" "noswap" "noswap" "noswap"
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "1"
		call move_to_next_waypoint "-568.09,168.35,-588.10"
		call move_to_next_waypoint "-613.64,180.74,-570.88"
		call move_to_next_waypoint "-676.50,175.75,-548.11"
		call move_to_next_waypoint "-675.66,155.37,-506.56"
		call move_to_next_waypoint "-617.62,123.56,-430.76"
		call move_to_next_waypoint "-581.55,114.19,-448.72"
		call move_to_next_waypoint "-512.08,94.52,-491.14"
		call move_to_next_waypoint "-471.05,95.32,-522.91"
		call move_to_next_waypoint "-425.90,102.39,-566.91"
		call move_to_next_waypoint "-396.45,121.68,-609.06"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "-365.35,124.44,-652.00"
			return TRUE
		}
		
		; If H2, swap to stun immunity rune for fighter/scout and stifle immunity rune for mage/priest
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			call mend_and_rune_swap "stun" "stun" "stifle" "stifle"
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Move around side of Named near KillSpot
			call move_to_next_waypoint "-367.35,122.78,-617.01"
			call move_to_next_waypoint "-338.41,124.90,-656.78"
			; Pull Named
			call Obj_OgreUtilities.PreCombatBuff 5
			wait 50
			oc !ci -PetOff igw:${Me.Name}
			; Kill Named
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			if ${Zone.Name.Equals["${Solo_Zone_Name}"]}
			{
				; Send everyone to pull named and back to KillSpot
				Obj_OgreIH:ChangeCampSpot["-365.63,124.44,-651.63"]
				call Obj_OgreUtilities.HandleWaitForCampSpot 10
				Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
				call Obj_OgreUtilities.HandleWaitForCampSpot 10
			}
			else
			{
				; Send everyone except fighter directly to KillSpot
				oc !ci -ChangeCampSpotWho "igw:${Me.Name}+notfighter" ${KillSpot.X} ${KillSpot.Y} ${KillSpot.Z}
				; Have fighter pull back
				oc !ci -ChangeCampSpotWho "igw:${Me.Name}+fighter" -365.63 124.44 -651.63
				call Obj_OgreUtilities.HandleWaitForCampSpot 10
				oc !ci -ChangeCampSpotWho "igw:${Me.Name}+fighter" ${KillSpot.X} ${KillSpot.Y} ${KillSpot.Z}
				call Obj_OgreUtilities.HandleWaitForCampSpot 10
			}
			; Run ZoneHelperScript
			oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
			oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC}"
			; Kill Named
			call Tank_at_KillSpot "${_NamedNPC}" "${KillSpot}"
			Ob_AutoTarget:Clear
			; Get Chest
			eq2execute summon
			wait 10
			call Obj_OgreIH.Get_Chest
			; Move back to center of area
			call move_to_next_waypoint "-365.35,124.44,-652.00"
		}
		
		; Check named is dead
		if ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_FailedToKill["${_NamedNPC}"]
			return FALSE
		}
		
		; Look for shinies
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "-365.35,124.44,-652.00" "40"
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 2 ********************    Move to, spawn and kill - Gilded Back Demolisher  *********************
***********************************************************************************************************/

	function:bool Named2(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-289.37,93.86,-271.95]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "2"
		call move_to_next_waypoint "-334.17,124.55,-647.14"
		call EnterPortal "telelport crystal"
		call move_to_next_waypoint "-235.54,104.15,-418.30"
		call move_to_next_waypoint "-250.16,91.10,-326.23"
		call move_to_next_waypoint "-263.53,91.65,-271.36"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; If H2, swap to stifle immunity rune for fighter/scout and stun immunity rune for mage/priest
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			call mend_and_rune_swap "stifle" "stifle" "stun" "stun"
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
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
			call move_to_next_waypoint "${KillSpot}" "20"
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 3 *********************    Move to, spawn and kill - Sina A'Rak *********************************
***********************************************************************************************************/

	function:bool Named3(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[72.20,149.70,-319.45]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "3"
		; Pick up shiny on way to next boss
		call move_to_next_waypoint "-254.07,91.52,-259.02"
		call move_to_next_waypoint "-214.48,97.86,-232.76"
		call move_to_next_waypoint "-149.45,124.36,-169.36"
		call move_to_next_waypoint "-73.06,138.33,-155.43"
		call move_to_next_waypoint "-4.05,139.58,-209.44"
		call move_to_next_waypoint "38.15,144.09,-269.09"
		call move_to_next_waypoint "39.75,144.73,-305.41"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; If H2, swap to stun immunity rune for scout/mage
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			call mend_and_rune_swap "noswap" "stun" "stun" "noswap"
		
		; If H2, disable single target Cure (there are a lot of detrimentals during the fight and don't want healers stuck doing nothing but curing them)
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+priest "Cure" FALSE TRUE
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_at_KillSpot "${_NamedNPC}" "${KillSpot}"
			Ob_AutoTarget:Clear
		}
		
		; If H2, re-enable single target Cure
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+priest "Cure" TRUE TRUE
		
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
			call move_to_next_waypoint "${KillSpot}" "20"
			call move_to_next_waypoint "49.07,144.62,-308.71" "15"
			call move_to_next_waypoint "44.67,145.75,-336.66" "10"
			call move_to_next_waypoint "49.07,144.62,-308.71" "15"
			call move_to_next_waypoint "${KillSpot}" "20"
			call move_to_next_waypoint "70.29,150.42,-343.70" "5"
			call move_to_next_waypoint "61.40,149.74,-364.37" "10"
			call move_to_next_waypoint "70.29,150.42,-343.70" "5"
			call move_to_next_waypoint "${KillSpot}" "20"
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 4 *********************    Move to, spawn and kill - Doda K'Bael ********************************
***********************************************************************************************************/

	function:bool Named4(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-31.19,156.73,5.95]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "4"
		call move_to_next_waypoint "21.25,141.65,-230.46"
		call move_to_next_waypoint "-67.93,140.89,-138.77"
		call move_to_next_waypoint "2.41,141.94,-91.47"
		call move_to_next_waypoint "12.20,142.77,-73.42"
		call move_to_next_waypoint "-5.95,152.00,-22.88"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; If H2, run ZoneHelperScript
			if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			{
				oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
				oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC}"
			}
			; Kill named
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_at_KillSpot "${_NamedNPC}" "${KillSpot}"
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
			call move_to_next_waypoint "-80.96,160.23,6.81" "20"
			call move_to_next_waypoint "-85.01,160.23,53.09" "20"
			call move_to_next_waypoint "-80.96,160.23,6.81" "20"
			call move_to_next_waypoint "${KillSpot}" "20"
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 5 *********************    Move to, spawn and kill - Queen Era'selka ****************************
***********************************************************************************************************/

	function:bool Named5(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[144.26,161.85,44.14]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "5"
		call move_to_next_waypoint "-6.72,151.46,-25.94"
		call move_to_next_waypoint "2.45,147.16,-50.36"
		call move_to_next_waypoint "59.61,146.34,-32.95"
		call move_to_next_waypoint "127.23,157.59,1.22"
		call move_to_next_waypoint "143.99,158.01,12.21"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; If H2, swap to stun immunity rune for scout/mage
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			call mend_and_rune_swap "noswap" "stun" "stun" "noswap"
		
		; Set Loot settings for last boss
		call SetLootForLastBoss
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; If H1/H2, run ZoneHelperScript
			if ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			{
				oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
				oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC}"
			}
			; Kill named
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_at_KillSpot "${_NamedNPC}" "${KillSpot}"
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
			call move_to_next_waypoint "${KillSpot}" "20"
			call move_to_next_waypoint "187.08,161.61,48.38" "20"
			call move_to_next_waypoint "144.87,161.85,44.09" "20"
			call move_to_next_waypoint "147.57,158.02,11.50" "5"
			call move_to_next_waypoint "123.38,157.24,8.29" "20"
			call move_to_next_waypoint "147.57,158.02,11.50" "5"
			call move_to_next_waypoint "150.64,157.70,-7.48" "20"
			call move_to_next_waypoint "190.13,157.90,3.20" "20"
			call move_to_next_waypoint "150.64,157.70,-7.48" "20"
			call move_to_next_waypoint "${KillSpot}" "20"
		}
		
		; Finished with named
		return TRUE
	}
}
