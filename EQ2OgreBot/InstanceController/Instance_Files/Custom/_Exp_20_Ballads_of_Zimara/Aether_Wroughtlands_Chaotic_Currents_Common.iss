; This IC file requires HOHelperScript/MendRuneSwapHelperScript/IC_Helper files to function
variable string HOHelperScript="HO_Helper"
variable string MendRuneSwapHelperScript="EQ2OgreBot/InstanceController/Support_Files_Common/Mend_Rune_Swap_Helper"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"

variable string Solo_Zone_Name="Aether Wroughtlands: Chaotic Currents [Solo]"
variable string Heroic_1_Zone_Name="Aether Wroughtlands: Chaotic Currents [Event Heroic I]"

; Portal variables
variable string PortalName
variable point3f CenterPoint
variable point3f IntermediatePoint
variable point3f PullPoint
variable point3f SilverIckPoint[3]
variable point3f SilverIckIntermediatePoint[3]

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
			call This.Named1 "Satashi the Staggering"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#1: Satashi the Staggering"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 2
		if ${_StartingPoint} == 2
		{
			call This.Named2 "Vashtu the Volatile"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#2: Vashtu the Volatile"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 3
		if ${_StartingPoint} == 3
		{
			call This.Named3 "Etosh the Electrifying"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#3: Etosh the Electrifying"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		
		; Zone Out
		if ${_StartingPoint} == 4
		{
			call move_to_next_waypoint "-761.78,279.21,685.65" "5"
			call move_to_next_waypoint "-779.37,253.59,711.17" "5"
			; Look for shinies
			if !${Ogre_Instance_Controller.bSkipShinies}
			{
				call move_to_next_waypoint "-756.96,254.54,698.97" "5"
				call move_to_next_waypoint "-753.45,254.73,700.17" "5"
				; May be a shiny at this point on a ledge, use special code to handle
				Obj_OgreIH:ChangeCampSpot["-751.28,255.16,678.91"]
				call Obj_OgreUtilities.HandleWaitForCampSpot 10
				call Obj_OgreUtilities.HandleWaitForCombat
				call click_shiny
				call move_to_next_waypoint "-754.85,255.16,673.72" "5"
				call move_to_next_waypoint "-733.04,254.53,661.98" "5"
				call move_to_next_waypoint "-754.85,255.16,673.72" "5"
				Obj_OgreIH:ChangeCampSpot["-751.28,255.16,678.91"]
				call Obj_OgreUtilities.HandleWaitForCampSpot 10
				call move_to_next_waypoint "-753.45,254.73,700.17" "5"
				call move_to_next_waypoint "-756.96,254.54,698.97" "5"
				call move_to_next_waypoint "-779.37,253.59,711.17" "5"
			}
			call move_to_next_waypoint "-791.55,253.80,677.29" "5"
			if !${Ogre_Instance_Controller.bSkipShinies}
			{
				call move_to_next_waypoint "-776.53,254.53,658.75" "5"
				call move_to_next_waypoint "-791.55,253.80,677.29" "5"
			}
			call move_to_next_waypoint "-806.33,254.46,673.65" "5"
			if !${Ogre_Instance_Controller.bSkipShinies}
			{
				call move_to_next_waypoint "-832.03,253.84,662.44" "5"
				call move_to_next_waypoint "-806.33,254.46,673.65" "5"
			}
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
    Named 1 **********************    Move to, spawn and kill - Satashi the Staggering   ******************
***********************************************************************************************************/

	function:bool Named1(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-453.78,277.41,613.61]
		
		; Repair if needed
		call mend_and_rune_swap "noswap" "noswap" "noswap" "noswap"
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "1"
		call move_to_next_waypoint "-425.01,252.65,607.84"
		call move_to_next_waypoint "-452.53,253.36,614.47"
		
		; Setup Portal variables
		PortalName:Set["portal_to_top_01"]
		CenterPoint:Set[-452.53,253.36,614.47]
		IntermediatePoint:Set[-463.99,252.62,632.67]
		PullPoint:Set[-481.52,252.40,631.69]
		SilverIckPoint[1]:Set[-477.86,252.45,622.00]
		SilverIckPoint[2]:Set[-464.55,252.92,641.77]
		SilverIckPoint[3]:Set[-437.19,251.91,636.56]
		SilverIckIntermediatePoint[1]:Set[-463.99,252.62,632.67]
		SilverIckIntermediatePoint[2]:Set[-463.99,252.62,632.67]
		SilverIckIntermediatePoint[3]:Set[-429.60,252.76,609.54]
		
		; Spawn Portal to top
		call SpawnPortalToTop
		
		; Move to portal and port up to top platform
		call move_to_next_waypoint "-465.39,252.75,599.74"
		call move_to_next_waypoint "-470.82,252.95,602.71"
		call EnterPortal "${PortalName}" "Teleport"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Swap to stun immunity rune
		call mend_and_rune_swap "stun" "stun" "stun" "stun"
		
		; Make sure Cure Curse is enabled in Cast Stack
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_curecurse FALSE TRUE
		
		; Detrimentals during fight:
		; Turbulent Ride: MainIconID 511, BackDropIconID 511
		; 	Kill mad maelstrom or use fighter intercept to remove
		; Shocked System: MainIconID 57, BackDropIconID -1
		; 	Kills target on expiration
		; Don't seem to need special code to handle, just kill the adds and use normal cure curse
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["a mad maelstrom",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			; Send everyone to KillSpot
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			; Send fighters back (if not Solo zone) to avoid knockback
			if !${Zone.Name.Equals["${Solo_Zone_Name}"]}
				oc !ci -ChangeCampSpotWho "igw:${Me.Name}+fighter" -442.17 277.41 619.87
			; Kill named
			call Tank_in_Place "${_NamedNPC}"
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
		
		; Send everyone to KillSpot
		call move_to_next_waypoint "${KillSpot}" "1"
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 2 ********************    Move to, spawn and kill - Vashtu the Volatile  ************************
***********************************************************************************************************/

	function:bool Named2(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-613.12,279.65,763.11]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "2"
		call move_to_next_waypoint "-421.61,252.65,606.20" "5"
		call move_to_next_waypoint "-452.63,253.36,614.20" "5"
		; Look for shiny from last boss
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "-441.06,252.74,599.57" "5"
			call move_to_next_waypoint "-452.11,254.98,590.37" "5"
			call move_to_next_waypoint "-460.12,252.94,597.07" "5"
			call move_to_next_waypoint "-474.79,252.74,598.58" "5"
			call move_to_next_waypoint "-460.12,252.94,597.07" "5"
			call move_to_next_waypoint "-452.11,254.98,590.37" "5"
			call move_to_next_waypoint "-441.06,252.74,599.57" "5"
			call move_to_next_waypoint "-452.63,253.36,614.20" "5"
		}
		call move_to_next_waypoint "-458.44,252.75,632.98" "1"
		; Look for shiny from last boss
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "-457.18,252.73,639.04" "5"
			call move_to_next_waypoint "-458.44,252.75,632.98" "1"
		}
		call move_to_next_waypoint "-453.57,252.95,636.15" "5"
		call EnterPortal "portal_from_1_to_2" "Teleport"
		
		; Setup Portal variables
		PortalName:Set["portal_to_top_02"]
		CenterPoint:Set[-613.41,255.61,763.31]
		IntermediatePoint:Set[-622.86,255.03,781.58]
		PullPoint:Set[-610.30,254.98,739.34]
		SilverIckPoint[1]:Set[-627.97,254.88,793.65]
		SilverIckPoint[2]:Set[-601.14,254.89,806.30]
		SilverIckPoint[3]:Set[-586.86,254.91,782.29]
		SilverIckIntermediatePoint[1]:Set[-622.86,255.03,781.58]
		SilverIckIntermediatePoint[2]:Set[-622.86,255.03,781.58]
		SilverIckIntermediatePoint[3]:Set[-622.86,255.03,781.58]
		
		; Spawn Portal to top
		call SpawnPortalToTop
		
		; Move to portal and port up to top platform
		call move_to_next_waypoint "-611.52,255.09,743.44"
		call move_to_next_waypoint "-614.96,255.19,741.84"
		call EnterPortal "${PortalName}" "Teleport"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Swap to fear immunity rune
		call mend_and_rune_swap "fear" "fear" "fear" "fear"
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["a cloud of chaos",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			oc ${Me.Name} is pulling ${_NamedNPC}
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			Actor["${_NamedNPC}"]:DoTarget
			wait 50
			while ${Me.InCombat}
			{
				; Check to see if named has "Explosive Temper" effect (needs to be dispelled)
				; If not dispelled, will knock everyone off platform
				; Only check first 8 effects, should show near beginning of effects
				call CheckTargetEffect "Explosive Temper" "8"
				if ${Return}
				{
					; Have mage cast Absorb Magic to dispel
					oc !ci -CastAbility igw:${Me.Name}+mage "Absorb Magic"
					wait 30
				}
				; Wait a second before checking for effect again
				wait 10
			}
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
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 3 *********************    Move to, spawn and kill - Etosh the Electrifying *********************
***********************************************************************************************************/

	function:bool Named3(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-754.76,279.21,673.22]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "3"
		call move_to_next_waypoint "-600.04,279.65,768.31" "5"
		call move_to_next_waypoint "-581.45,255.66,772.64" "5"
		call move_to_next_waypoint "-604.13,254.87,790.14" "5"
		; Look for shiny from last boss
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "-597.45,254.87,798.63" "10"
			call move_to_next_waypoint "-606.04,255.82,767.23" "1"
			; May be a shiny at this point on a ledge, use special code to handle
			Obj_OgreIH:ChangeCampSpot["-610.34,255.72,769.83"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			call Obj_OgreUtilities.HandleWaitForCombat
			call click_shiny
			call move_to_next_waypoint "-606.04,255.82,767.23" "1"
			call move_to_next_waypoint "-617.38,255.74,756.93" "5"
			call move_to_next_waypoint "-620.16,254.98,740.39" "5"
			call move_to_next_waypoint "-617.38,255.74,756.93" "5"
			call move_to_next_waypoint "-606.04,255.82,767.23" "1"
			call move_to_next_waypoint "-604.13,254.87,790.14" "5"
		}
		call move_to_next_waypoint "-630.47,255.19,776.36" "5"
		call EnterPortal "portal_from_2_to_3" "Teleport"
		
		; Setup Portal variables
		PortalName:Set["portal_to_top_03"]
		CenterPoint:Set[-754.74,255.16,673.190]
		IntermediatePoint:Set[-753.87,255.16,675.69]
		PullPoint:Set[-734.38,254.53,660.45]
		SilverIckPoint[1]:Set[-783.00,254.45,662.11]
		SilverIckPoint[2]:Set[-777.51,253.86,695.82]
		SilverIckPoint[3]:Set[-751.43,254.30,717.45]
		SilverIckIntermediatePoint[1]:Set[-753.87,255.16,675.69]
		SilverIckIntermediatePoint[2]:Set[-753.87,255.16,675.69]
		SilverIckIntermediatePoint[3]:Set[-753.87,255.16,675.69]
		
		; Spawn Portal to top
		call SpawnPortalToTop
		
		; Move to portal and port up to top platform
		call move_to_next_waypoint "-734.47,254.64,671.19"
		call move_to_next_waypoint "-734.04,254.75,666.81"
		call EnterPortal "${PortalName}" "Teleport"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Make sure Cure Curse is enabled in Cast Stack
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_curecurse FALSE TRUE
		
		; Enable HO for all
		eq2execute cancel_ho_starter
		call HO "All" "FALSE"
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "${_NamedNPC}"
		
		; Set Loot settings for last boss
		call SetLootForLastBoss
		
		; Detrimentals during fight:
		; Conductive Curse: MainIconID 233 BackDropIconID 651
		; 	When cured moves to another target
		; 	Completing HO's clears the reuse of Cure Curse
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			; Kill named
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["a shocking left",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["a stunning right",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_n_Spank "${_NamedNPC}" "${KillSpot}"
			Ob_AutoTarget:Clear
		}
		
		; Disable HO for all
		call HO "Disable" "FALSE"
		
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
}

/***********************************************************************************************************
***********************************************  FUNCTIONS  ************************************************    
************************************************************************************************************/

function SpawnPortalToTop()
{
	; Check to see if portal to top exists
	; If portal doesn't exist, need to spawn it
	; Aggro "a volatile current" and pull it over "A silver ick", then kill the current
	; The ick will turn into "an overcharged silver ick", bring it to center area and kill it
	; This will light up one of three orbs, when all are lit up it spawns the portal
	variable int SilverIckIndex=1
	variable bool PortalExists=FALSE
	while !${PortalExists}
	{
		; Check to see if portal exists
		if ${Actor[Query,Name=="${PortalName}"].ID(exists)}
			return
		; Disable Cast Stack and make sure Ranged Attack is on
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack TRUE TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_rangedattack TRUE TRUE
		eq2execute setautoattackmode 0		
		; Back off pets
		oc !ci -PetOff igw:${Me.Name}
		; Go to IntermediatePoint
		Obj_OgreIH:ChangeCampSpot["${IntermediatePoint}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		; Go to PullPoint
		Obj_OgreIH:ChangeCampSpot["${PullPoint}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		; Pull a volatile current
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["a volatile current",0,FALSE,FALSE]
		while !${Me.InCombat} || !${Actor[Query,Name=="a volatile current" && Type != "Corpse" && Distance <= 12].ID(exists)}
		{
			Actor[Query,Name=="a volatile current" && Type != "Corpse" && Distance <= 30]:DoTarget
			wait 10
			if !${Me.AutoAttackOn}
				eq2execute /auto 2
			wait 10
			; Want AutoAttack to only be on for 1 hit, ranger kills the mobs too fast in solo
			eq2execute /auto 0
		}
		wait 10
		; Go to IntermediatePoint
		Obj_OgreIH:ChangeCampSpot["${IntermediatePoint}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		; Go to Silver Ick
		Obj_OgreIH:ChangeCampSpot["${SilverIckPoint[${SilverIckIndex}]}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		; Wait for a volatile current to be in range
		variable int WaitCount=0
		while ${WaitCount:Inc} < 30 && !${Actor[Query,Name=="a volatile current" && Type != "Corpse" && Distance <= 12].ID(exists)}
		{
			wait 10
		}
		; Turn on Cast Stack
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack FALSE TRUE
		; Wait for "an overcharged silver ick" to spawn
		WaitCount:Set[0]
		while ${WaitCount:Inc} < 30 && !${Actor[Query,Name=="an overcharged silver ick" && Type != "Corpse" && Distance <= 12].ID(exists)}
		{
			wait 10
		}
		; Turn off Cast Stack
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack TRUE TRUE
		; Target an overcharged silver ick
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["an overcharged silver ick",0,FALSE,FALSE]
		Actor[Query,Name=="an overcharged silver ick" && Type != "Corpse" && Distance <= 12]:DoTarget
		if !${Me.AutoAttackOn}
			eq2execute /auto 2
		wait 30
		; Go to CenterPoint
		Obj_OgreIH:ChangeCampSpot["${SilverIckIntermediatePoint[${SilverIckIndex}]}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		Obj_OgreIH:ChangeCampSpot["${CenterPoint}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		; Wait for "an overcharged silver ick" to be in range
		WaitCount:Set[0]
		while ${WaitCount:Inc} < 30 && !${Actor[Query,Name=="an overcharged silver ick" && Type != "Corpse" && Distance <= 12].ID(exists)}
		{
			wait 10
		}
		; Turn on Cast Stack
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack FALSE TRUE
		; Resume pets
		oc !ci -PetAssist igw:${Me.Name}
		; Wait to kill "an overcharged silver ick"
		while ${Me.InCombat} && ${Actor[Query,Name=="an overcharged silver ick" && Type != "Corpse" && Distance <= 30].ID(exists)}
		{
			wait 10
		}
		; Increment SilverIckIndex
		if ${SilverIckIndex:Inc} > 3
			SilverIckIndex:Set[1]
		; If everything went correctly, should have lit up an orb around the middle
		; Wait a couple seconds, then loop again to see if the portal exists now
		wait 20
	}
}
