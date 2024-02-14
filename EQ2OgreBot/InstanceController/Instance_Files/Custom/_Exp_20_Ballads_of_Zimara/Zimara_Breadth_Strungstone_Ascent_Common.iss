; This IC file requires ZoneHelperScript/HOHelperScript/MendRuneSwapHelperScript/IC_Helper files to function
variable string ZoneHelperScript="EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/Zimara_Breadth_Strungstone_Ascent_Helper"
variable string HOHelperScript="HO_Helper"
variable string MendRuneSwapHelperScript="EQ2OgreBot/InstanceController/Support_Files_Common/Mend_Rune_Swap_Helper"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"

variable string Solo_Zone_Name="Zimara Breadth: Strungstone Ascent [Solo]"
variable string Heroic_1_Zone_Name="Zimara Breadth: Strungstone Ascent [Heroic I]"
variable string Heroic_2_Zone_Name="Zimara Breadth: Strungstone Ascent [Heroic II]"

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
			call This.Named1 "Rubblethrong"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#1: Rubblethrong"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 2
		if ${_StartingPoint} == 2
		{
			call This.Named2 "Bolagehera"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#2: Bolagehera"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 3
		if ${_StartingPoint} == 3
		{
			call This.Named3 "Barlanka"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#3: Barlanka"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 4
		if ${_StartingPoint} == 4
		{
			call This.Named4 "Crisj'Jen the Bold"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#4: Crisj'Jen the Bold"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 5
		if ${_StartingPoint} == 5
		{
			call This.Named5 "Fuejenyrus"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#5: Fuejenyrus"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		
		; Zone Out
		if ${_StartingPoint} == 6
		{
			call move_to_next_waypoint "-245.89,432.11,892.87" "1"
			call move_to_next_waypoint "-248.26,432.11,892.22" "1"
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
    Named 1 **********************    Move to, spawn and kill - Rubblethrong   ****************************
***********************************************************************************************************/

	function:bool Named1(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[596.41,205.29,-543.48]
		
		; Repair if needed
		call mend_and_rune_swap "noswap" "noswap" "noswap" "noswap"
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "1"
		call move_to_next_waypoint "619.55,201.87,-767.47"
		call move_to_next_waypoint "605.50,194.65,-717.87"
		call move_to_next_waypoint "610.13,195.64,-678.17"
		call move_to_next_waypoint "616.36,204.77,-624.71"
		call move_to_next_waypoint "621.61,206.77,-576.81"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "624.99,206.15,-531.89"
			return TRUE
		}
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Pull Named
			call Obj_OgreUtilities.PreCombatBuff 5
			wait 50
			oc !ci -PetOff igw:${Me.Name}
			Obj_OgreIH:ChangeCampSpot["624.99,206.15,-531.89"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			; Kill Named
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_at_KillSpot "${_NamedNPC}" "${KillSpot}"
			Ob_AutoTarget:Clear
			; Get Chest
			eq2execute summon
			wait 10
			call Obj_OgreIH.Get_Chest
			; Move out of KillSpot
			call move_to_next_waypoint "624.99,206.15,-531.89"
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
			call move_to_next_waypoint "636.80,205.91,-535.73" "40"
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 2 ********************    Move to, spawn and kill - Bolagehera  *********************************
***********************************************************************************************************/

	function:bool Named2(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[703.08,185.52,328.14]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "2"
		call move_to_next_waypoint "648.24,207.47,-462.94"
		call EnterPortal "telelport crystal" "Teleport" 70 30 20
		call move_to_next_waypoint "648.24,207.47,-462.94"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Named wanders around, may need to path around to aggro
		Move_Needed:Set[TRUE]
		call move_if_needed "${_NamedNPC}" "${KillSpot}"
		call move_if_needed "${_NamedNPC}" "748.56,186.39,342.35"
		call move_if_needed "${_NamedNPC}" "786.05,188.48,353.85"
		call move_if_needed "${_NamedNPC}" "790.87,189.05,378.69"
		
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
		
		; Move back to original KillSpot
		call move_to_next_waypoint "786.05,188.48,353.85"
		call move_to_next_waypoint "703.08,185.52,328.14"
		
		; Look for shinies
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "770.05,187.41,348.33" "40"
			call move_to_next_waypoint "703.08,185.52,328.14" "40"
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 3 *********************    Move to, spawn and kill - Barlanka ***********************************
***********************************************************************************************************/

	function:bool Named3(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[553.20,276.64,537.12]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "3"
		call move_to_next_waypoint "716.08,199.04,399.46"
		call move_to_next_waypoint "761.06,229.57,486.33"
		call move_to_next_waypoint "739.17,255.57,531.69"
		call move_to_next_waypoint "702.59,261.36,531.54"
		call move_to_next_waypoint "688.36,272.43,500.59"
		call move_to_next_waypoint "702.30,283.53,475.74"
		call move_to_next_waypoint "720.72,286.18,486.74"
		call move_to_next_waypoint "712.31,288.05,503.09"
		call move_to_next_waypoint "682.28,292.56,526.80"
		call move_to_next_waypoint "628.81,282.19,553.63"
		call move_to_next_waypoint "588.06,273.19,545.27"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Named wanders around, may need to path around to aggro
		Obj_OgreIH:ChangeCampSpot["529.92,280.66,526.84"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		Move_Needed:Set[TRUE]
		call move_if_needed "${_NamedNPC}" "${KillSpot}"
		call move_if_needed "${_NamedNPC}" "554.99,274.34,590.91"
		call move_if_needed "${_NamedNPC}" "535.74,277.88,624.94"
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; If H2, run ZoneHelperScript
			if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			{
				oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
				oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC}"
			}
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
		
		; Move back to original KillSpot
		call move_to_next_waypoint "554.99,274.34,590.91"
		call move_to_next_waypoint "526.49,278.40,628.74"
		call move_to_next_waypoint "554.99,274.34,590.91"
		call move_to_next_waypoint "553.20,276.64,537.12"
		
		; Look for shinies
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "539.89,280.79,547.93" "40"
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 4 *********************    Move to, spawn and kill - Crisj'Jen the Bold *************************
***********************************************************************************************************/

	function:bool Named4(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[121.18,383.66,725.35]
		
		; If H2, swap to stun immunity rune for fighter/scout and stifle immunity rune for mage/priest
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			call mend_and_rune_swap "stun" "stun" "stifle" "stifle"
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "4"
		call move_to_next_waypoint "513.46,288.97,567.26"
		call move_to_next_waypoint "456.80,316.69,620.96"
		call move_to_next_waypoint "400.54,337.48,625.17"
		call move_to_next_waypoint "373.10,355.95,589.66"
		call move_to_next_waypoint "374.90,362.78,558.04"
		call move_to_next_waypoint "392.70,369.20,542.21"
		call move_to_next_waypoint "427.72,380.56,553.72"
		call move_to_next_waypoint "427.73,382.39,573.74"
		call move_to_next_waypoint "343.62,401.98,599.22"
		call EnterPortal "telelport crystal" "Focus Your Power" 70 30 20
		call move_to_next_waypoint "159.57,361.49,672.04"
		call move_to_next_waypoint "138.47,363.19,693.33"
		call move_to_next_waypoint "123.29,369.18,697.23"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			return TRUE
		}
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Pull Named
			call Obj_OgreUtilities.PreCombatBuff 5
			wait 50
			oc !ci -PetOff igw:${Me.Name}
			if ${Zone.Name.Equals["${Solo_Zone_Name}"]}
			{
				Obj_OgreIH:ChangeCampSpot["93.74,382.24,714.62"]
				call Obj_OgreUtilities.HandleWaitForCampSpot 10
				Obj_OgreIH:ChangeCampSpot["123.29,369.18,697.23"]
				call Obj_OgreUtilities.HandleWaitForCampSpot 10
			}
			else
			{
				; Send everyone except fighter directly to KillSpot
				oc !ci -ChangeCampSpotWho "igw:${Me.Name}+notfighter" ${KillSpot.X} ${KillSpot.Y} ${KillSpot.Z}
				; Have fighter pull back
				oc !ci -ChangeCampSpotWho "igw:${Me.Name}+fighter" 93.74 382.24 714.62
				call Obj_OgreUtilities.HandleWaitForCampSpot 10
				oc !ci -ChangeCampSpotWho "igw:${Me.Name}+fighter" 123.29 369.18 697.23
				call Obj_OgreUtilities.HandleWaitForCampSpot 10
			}
			; Kill Named
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_at_KillSpot "${_NamedNPC}" "${KillSpot}"
			Ob_AutoTarget:Clear
			; Get Chest
			eq2execute summon
			wait 10
			call Obj_OgreIH.Get_Chest
			; Move out of KillSpot
			call move_to_next_waypoint "123.29,369.18,697.23"
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
			call move_to_next_waypoint "112.29,377.93,676.11" "20"
			call move_to_next_waypoint "123.29,369.18,697.23" "20"
			call move_to_next_waypoint "93.34,383.74,728.25" "20"
			call move_to_next_waypoint "113.11,386.63,746.65" "20"
			call move_to_next_waypoint "93.34,383.74,728.25" "20"
			call move_to_next_waypoint "123.29,369.18,697.23" "40"
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 5 *********************    Move to, spawn and kill - Fuejenyrus *********************************
***********************************************************************************************************/

	function:bool Named5(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-216.87,432.08,880.55]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "5"
		call move_to_next_waypoint "54.84,398.15,733.95"
		call move_to_next_waypoint "8.51,401.67,739.50"
		call move_to_next_waypoint "-37.44,387.53,718.39"
		call move_to_next_waypoint "-69.74,393.01,713.80"
		call move_to_next_waypoint "-117.20,411.49,769.66"
		call move_to_next_waypoint "-176.20,407.14,812.11"
		call move_to_next_waypoint "-181.98,409.34,874.21"
		call move_to_next_waypoint "-213.28,430.39,906.05"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "-244.78,433.52,867.27"
			return TRUE
		}
		
		; Set Loot settings for last boss
		call SetLootForLastBoss
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; For solo, pull named back to KillSpot
			if ${Zone.Name.Equals["${Solo_Zone_Name}"]}
			{
				Obj_OgreIH:ChangeCampSpot["-244.78,433.52,867.27"]
				call Obj_OgreUtilities.HandleWaitForCampSpot 10
			}
			else
			{
				; Move up a bit
				Obj_OgreIH:ChangeCampSpot["-226.64,432.08,891.58"]
				call Obj_OgreUtilities.HandleWaitForCampSpot 10
				; Send everyone except fighter directly to KillSpot
				oc !ci -ChangeCampSpotWho "igw:${Me.Name}+notfighter" ${KillSpot.X} ${KillSpot.Y} ${KillSpot.Z}
				; Have fighter pull back
				oc !ci -ChangeCampSpotWho "igw:${Me.Name}+fighter" -244.78 433.52 867.27
				call Obj_OgreUtilities.HandleWaitForCampSpot 10
			}
			; Run ZoneHelperScript
			oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
			oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC}"
			; Kill Named
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_at_KillSpot "${_NamedNPC}" "${KillSpot}"
			Ob_AutoTarget:Clear
			; Get Chest
			eq2execute summon
			wait 10
			call Obj_OgreIH.Get_Chest
			; Move out of KillSpot
			call move_to_next_waypoint "-244.78,433.52,867.27"
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
			call move_to_next_waypoint "-239.53,432.66,872.60" "40"
		}
		
		; Finished with named
		return TRUE
	}
}
