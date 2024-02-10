; This IC file requires ZoneHelperScript/HOHelperScript/MendRuneSwapHelperScript/IC_Helper files to function
variable string ZoneHelperScript="EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/Vaashkaani_Every_Which_Way_Helper"
variable string HOHelperScript="HO_Helper"
variable string MendRuneSwapHelperScript="EQ2OgreBot/InstanceController/Support_Files_Common/Mend_Rune_Swap_Helper"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"

variable string Solo_Zone_Name="Vaashkaani: Every Which Way [Solo]"
variable string Heroic_1_Zone_Name="Vaashkaani: Every Which Way [Event Heroic I]"
variable point3f SafeSpot="369.10,-10.45,292.00"
variable point3f SphereOfInfluence1Spot="396.00,-10.61,292.00"
variable point3f SphereOfInfluence2Spot="466.40 -10.61 292.00"
variable string NamedNPC1="Gazu'Taz the Gradual"
variable string NamedNPC2="Soku'Aos the Sturdy"
variable string NamedNPC3="Abin'Ebi the Awkward"
variable bool LeftSideOrbsCollected=FALSE
variable bool RightSideOrbsCollected=FALSE
variable bool TopOrbsCollected=FALSE

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
		; Set default value for HaveSphereOfInfluence to FALSE for everyone
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_HaveSphereOfInfluence" "FALSE"
		variable int GroupNum=0
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			oc !ci -Set_Variable igw:${Me.Name} "${Me.Group[${GroupNum}].Name}_HaveSphereOfInfluence" "FALSE"
		}
		; Add short delay to allow all variables to be set, otherwise won't work properly
		wait 1
		; Run ZoneHelperScript on everyone in group in order to handle character-specific needs
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${Zone.Name}"
		
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
			; Enable Auto Target and Allow Out of Combat Scanning for this zone for everyone (mainly for solos to help aggro named)
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_autotarget_enabled TRUE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_autotarget_outofcombatscanning TRUE TRUE
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
			call This.Named1
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#1: Gazu'Taz the Gradual"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 2
		if ${_StartingPoint} == 2
		{
			call This.Named2
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#2: Soku'Aos the Sturdy"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 3
		if ${_StartingPoint} == 3
		{
			call This.Named3
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#3: Abin'Ebi the Awkward"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		
		; Zone Out
		if ${_StartingPoint} == 4
		{
			; Collect shinies if not set to skip
			if !${Ogre_Instance_Controller.bSkipShinies}
			{
				call CollectShinies
			}
			; Otherwise, move to exit
			else
			{
				call move_waypoint_custom "384.79,-10.40,292.00"
				call move_waypoint_custom "384.44,-10.62,315.45"
				call move_waypoint_custom "397.15,-10.62,320.19"
				call move_waypoint_custom "407.79,-10.60,309.64"
				call move_waypoint_custom "453.65,-10.60,309.62"
				call move_waypoint_custom "439.29,-10.55,292.06"
				call move_waypoint_custom "428.70,-10.54,292.13" "TRUE"
			}
			Ob_AutoTarget:Clear
			Obj_OgreIH:LetsGo
			oc ${Me.Name} looted ${ShiniesLooted} shinies
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
	
; There are 3 wandering named in the zone, need to kill them in a specific order
; 1. Gazu'Taz the Gradual
; 2. Soku'Aos the Sturdy
; 3. Abin'Ebi the Awkward
; There are also wandering hand mobs

; Initially, if you run into a named it will kill you on sight and hand mobs can't be damaged
; Need to collect a Sphere of Influence to allow you to kill the enemies
; Sphere of Influence gives you a buff that counts down
; You can collect orbs to extend the time that the buff lasts
; Collecting a second Sphere of Influence extends the time further

; General strategy is run around picking up as many orbs as possible without aggroing named
; Then grab a Sphere of Influence and kill a named
; Repeat as needed

; This IC spends a lot of time waiting around for the named to randomly be far away from starting position
; or on the left/right side.  There is definitely a more elegant version that could be created to run
; the zone, but it should mostly work if you let it run a while.  There will probably be some random times
; it fails though...
		
/**********************************************************************************************************
    Named 1 **********************    Move to, spawn and kill - Gazu'Taz the Gradual   ********************
***********************************************************************************************************/

	function:bool Named1()
	{
		; Swap to mez immunity rune (need for 2nd named)
		call mend_and_rune_swap "mez" "mez" "mez" "mez"
		
		; Move to SafeSpot
		call move_waypoint_custom "353.66,-10.40,292.34"
		call move_waypoint_custom "${SafeSpot}"
		
		; Clear AutoTarget
		Ob_AutoTarget:Clear
		
		; Setup for NamedNPC1
		call initialize_move_to_next_boss "${NamedNPC1}" "1"
		
		; Check orbs absorbed (in case re-running script)
		call CheckOrbsAbsorbed
		
		; Check if already killed
		if !${Actor[namednpc,"${NamedNPC1}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${NamedNPC1}"]
			return TRUE
		}
		
		; Collect first 3 paths of orbs, unless already collected left/right side
		if !${LeftSideOrbsCollected} && !${RightSideOrbsCollected}
		{
			; Wait for path clear to collect first set of orbs
			oc ${Me.Name} waiting for path clear to collect first set of orbs
			call WaitForBottomPathClear "50" "50" "50"
			
			; Collect first path of orbs
			call CollectPath1Orbs
			
			; May be in combat with a hand at this point and can't damage them without Sphere of Influence
			call HandleHandCombat
			
			; Wait until no one in the group has Sphere of Influence detrimental
			call WaitUntilNoOneHasSphereOfInfluence
			
			; Wait for path clear to collect second set of orbs
			oc ${Me.Name} waiting for path clear to collect second set of orbs
			call WaitForBottomPathClear "80" "35" "35"
			
			; Collect second path of orbs
			call CollectPath2Orbs
			
			; May be in combat with a hand at this point and can't damage them without Sphere of Influence
			call HandleHandCombat
			
			; Wait until no one in the group has Sphere of Influence detrimental
			call WaitUntilNoOneHasSphereOfInfluence
			
			; Wait for path clear to collect third set of orbs
			oc ${Me.Name} waiting for path clear to collect third set of orbs
			call WaitForBottomPathClear "100" "35" "35"
			
			; Collect third path of orbs
			call CollectPath3Orbs
			
			; May be in combat with a hand at this point and can't damage them without Sphere of Influence
			call HandleHandCombat
		}
		
		; Collect left and right side orbs
		oc ${Me.Name} waiting for path clear to collect left/right set of orbs
		variable point3f NamedLoc
		while !${LeftSideOrbsCollected} || !${RightSideOrbsCollected}
		{
			; Wait for path clear to collect set of orbs
			call WaitForBottomPathClear "80" "35" "35"
			; Get Location of NamedNPC1
			NamedLoc:Set[${Actor[Query,Name=="${NamedNPC1}" && Type != "Corpse"].Loc}]
			if ${NamedLoc.X}!=0 || ${NamedLoc.Y}!=0 || ${NamedLoc.Z}!=0
			{
				; Check to see if left side orbs are not collected and named is on the right side
				if !${LeftSideOrbsCollected} && ${NamedLoc.Z} < 264
				{
					; Collect left side orbs
					call CollectLeftSideOrbs
				}
				; Check to see if right side orbs are not collected and named is on the left side
				elseif !${RightSideOrbsCollected} && ${NamedLoc.Z} > 320
				{
					; Collect right side orbs
					call CollectRightSideOrbs
				}
			}
			; Check in case the named or a hand was aggroed while in the process of collecting the side orbs
			Call CheckNamedCombat "${NamedNPC1}"
			; Check if named killed
			if !${Actor[namednpc,"${NamedNPC1}"].ID(exists)}
				return TRUE
			; Wait a second before checking again
			wait 10
		}
		
		; Left and right side orbs collected without aggroing named
		; Try to meet with with Named1 by waiting for it to go to a side, then go to that side
		if ${Actor[namednpc,"${NamedNPC1}"].ID(exists)}
			oc ${Me.Name} waiting for named on left/right side to meet up with
		while ${Actor[namednpc,"${NamedNPC1}"].ID(exists)}
		{
			; Wait for path clear to collect sphere of influence
			call WaitForBottomPathClear "35" "35" "35"
			; Get Location of NamedNPC1
			NamedLoc:Set[${Actor[Query,Name=="${NamedNPC1}" && Type != "Corpse"].Loc}]
			if ${NamedLoc.X}!=0 || ${NamedLoc.Y}!=0 || ${NamedLoc.Z}!=0
			{
				; Check to see if named is on the right side
				if ${NamedLoc.Z} < 264
				{
					; Collect right side orbs and hope run into named along the way
					call CollectRightSideOrbs "TRUE" "${NamedNPC1}"
				}
				; Check to see if named is on the left side
				elseif ${NamedLoc.Z} > 320
				{
					; Collect left side orbs and hope run into named along the way
					call CollectLeftSideOrbs "TRUE" "${NamedNPC1}"
				}
			}
			; Check in case the named or a hand was aggroed
			Call CheckNamedCombat "${NamedNPC1}"
			; Wait a second before checking again
			wait 10
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 2 ********************    Move to, spawn and kill - Soku'Aos the Sturdy  ************************
***********************************************************************************************************/

	function:bool Named2()
	{
		; There is a chance already in combat with Named2 in the process of killing Named1
		; If so, collect second sphere of influence to extend the time and wait for combat to end
		if ${Me.InCombat}
		{
			call CollectSecondSphereOfInfluence
			while ${Me.InCombat}
			{
				; Wait a second before checking again
				wait 10
			}
		}
		
		; Get any Chests
		eq2execute summon
		wait 10
		call Obj_OgreIH.Get_Chest
		
		; Clear AutoTarget
		Ob_AutoTarget:Clear
		
		; Setup for NamedNPC2
		call initialize_move_to_next_boss "${NamedNPC2}" "2"
		
		; Check if already killed
		if !${Actor[namednpc,"${NamedNPC2}"].ID(exists)}
		{
			call CheckOrbsAbsorbed
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${NamedNPC2}"]
			return TRUE
		}
		
		; Collect left and right side orbs if any still need to be collected
		if !${LeftSideOrbsCollected} || !${RightSideOrbsCollected}
			oc ${Me.Name} waiting for path clear to collect left/right set of orbs
		variable point3f NamedLoc
		while !${LeftSideOrbsCollected} || !${RightSideOrbsCollected}
		{
			; Wait for path clear to collect set of orbs
			call WaitForBottomPathClear "35" "80" "35"
			; Get Location of NamedNPC2
			NamedLoc:Set[${Actor[Query,Name=="${NamedNPC2}" && Type != "Corpse"].Loc}]
			if ${NamedLoc.X}!=0 || ${NamedLoc.Y}!=0 || ${NamedLoc.Z}!=0
			{
				; Check to see if left side orbs are not collected and named is on the right side
				if !${LeftSideOrbsCollected} && ${NamedLoc.Z} < 264
				{
					; Collect left side orbs
					call CollectLeftSideOrbs
				}
				; Check to see if right side orbs are not collected and named is on the left side
				elseif !${RightSideOrbsCollected} && ${NamedLoc.Z} > 320
				{
					; Collect right side orbs
					call CollectRightSideOrbs
				}
			}
			; Check in case the named or a hand was aggroed while in the process of collecting the side orbs
			Call CheckNamedCombat "${NamedNPC2}"
			; Check if named killed
			if !${Actor[namednpc,"${NamedNPC2}"].ID(exists)}
				return TRUE
			; Wait a second before checking again
			wait 10
		}
		
		; Left and right side orbs collected without aggroing named
		; Try to meet with with Named2 by waiting for it to go to a side, then go to that side
		if ${Actor[namednpc,"${NamedNPC2}"].ID(exists)}
			oc ${Me.Name} waiting for named on left/right side to meet up with
		while ${Actor[namednpc,"${NamedNPC2}"].ID(exists)}
		{
			; Wait for path clear to collect sphere of influence
			call WaitForBottomPathClear "35" "35" "35"
			; Get Location of NamedNPC2
			NamedLoc:Set[${Actor[Query,Name=="${NamedNPC2}" && Type != "Corpse"].Loc}]
			if ${NamedLoc.X}!=0 || ${NamedLoc.Y}!=0 || ${NamedLoc.Z}!=0
			{
				; Check to see if named is on the right side
				if ${NamedLoc.Z} < 264
				{
					; Collect right side orbs and hope run into named along the way
					call CollectRightSideOrbs "TRUE" "${NamedNPC2}"
				}
				; Check to see if named is on the left side
				elseif ${NamedLoc.Z} > 320
				{
					; Collect left side orbs and hope run into named along the way
					call CollectLeftSideOrbs "TRUE" "${NamedNPC2}"
				}
			}
			; Check in case the named or a hand was aggroed
			Call CheckNamedCombat "${NamedNPC2}"
			; Wait a second before checking again
			wait 10
		}
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 3 *********************    Move to, spawn and kill - Abin'Ebi the Awkward ***********************
***********************************************************************************************************/

	function:bool Named3()
	{
		; Disable HO for all and run HO_Helper script
		call HO "Disable" "FALSE"
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "${NamedNPC3}"
		
		; Set Loot settings for last boss
		call SetLootForLastBoss
		
		; There is a chance already in combat with Named3 in the process of killing Named2
		; If so, collect second sphere of influence to extend the time and wait for combat to end
		if ${Me.InCombat}
		{
			call CollectSecondSphereOfInfluence
			while ${Me.InCombat}
			{
				; Wait a second before checking again
				wait 10
			}
		}
		
		; Get any Chests
		eq2execute summon
		wait 10
		call Obj_OgreIH.Get_Chest
		
		; Clear AutoTarget
		Ob_AutoTarget:Clear
		
		; Setup for NamedNPC3
		call initialize_move_to_next_boss "${NamedNPC3}" "3"
		
		; Check if already killed
		if !${Actor[namednpc,"${NamedNPC3}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${NamedNPC3}"]
			return TRUE
		}
		
		; Collect left and right side orbs if any still need to be collected
		if !${LeftSideOrbsCollected} || !${RightSideOrbsCollected}
			oc ${Me.Name} waiting for path clear to collect left/right set of orbs
		variable point3f NamedLoc
		while !${LeftSideOrbsCollected} || !${RightSideOrbsCollected}
		{
			; Wait for path clear to collect set of orbs
			call WaitForBottomPathClear "35" "35" "80"
			; Get Location of NamedNPC3
			NamedLoc:Set[${Actor[Query,Name=="${NamedNPC3}" && Type != "Corpse"].Loc}]
			if ${NamedLoc.X}!=0 || ${NamedLoc.Y}!=0 || ${NamedLoc.Z}!=0
			{
				; Check to see if left side orbs are not collected and named is on the right side
				if !${LeftSideOrbsCollected} && ${NamedLoc.Z} < 264
				{
					; Collect left side orbs
					call CollectLeftSideOrbs
				}
				; Check to see if right side orbs are not collected and named is on the left side
				elseif !${RightSideOrbsCollected} && ${NamedLoc.Z} > 320
				{
					; Collect right side orbs
					call CollectRightSideOrbs
				}
			}
			; Check in case the named or a hand was aggroed while in the process of collecting the side orbs
			Call CheckNamedCombat "${NamedNPC3}"
			; Check if named killed
			if !${Actor[namednpc,"${NamedNPC3}"].ID(exists)}
				break
			; Wait a second before checking again
			wait 10
		}
		
		; Left and right side orbs collected without aggroing named
		; Try to meet with with Named3 by waiting for it to go to a side, then go to that side
		if ${Actor[namednpc,"${NamedNPC3}"].ID(exists)}
			oc ${Me.Name} waiting for named on left/right side to meet up with
		while ${Actor[namednpc,"${NamedNPC3}"].ID(exists)}
		{
			; Wait for path clear to collect sphere of influence
			call WaitForBottomPathClear "35" "35" "35"
			; Get Location of NamedNPC3
			NamedLoc:Set[${Actor[Query,Name=="${NamedNPC3}" && Type != "Corpse"].Loc}]
			if ${NamedLoc.X}!=0 || ${NamedLoc.Y}!=0 || ${NamedLoc.Z}!=0
			{
				; Check to see if named is on the right side
				if ${NamedLoc.Z} < 264
				{
					; Collect right side orbs and hope run into named along the way
					call CollectRightSideOrbs "TRUE" "${NamedNPC3}"
				}
				; Check to see if named is on the left side
				elseif ${NamedLoc.Z} > 320
				{
					; Collect left side orbs and hope run into named along the way
					call CollectLeftSideOrbs "TRUE" "${NamedNPC3}"
				}
			}
			; Check in case the named or a hand was aggroed
			Call CheckNamedCombat "${NamedNPC3}"
			; Wait a second before checking again
			wait 10
		}
		
		; Get Chest
		eq2execute summon
		wait 10
		call Obj_OgreIH.Get_Chest
		
		; Disable HO for all (likely enabled for some during named fight)
		call HO "Disable" "FALSE"
		
		; Finished with named
		return TRUE
	}
}

/***********************************************************************************************************
***********************************************  FUNCTIONS  ************************************************    
************************************************************************************************************/

function WaitForBottomPathClear(int FirstNamedDistance, int SecondNamedDistance, int ThirdNamedDistance)
{
	; Wait for named to be at least ClearDistances away
	variable bool PathClear=FALSE
	while !${PathClear}
	{
		; Check for any of the 3 named within ClearDistances
		if !${Actor[Query,Name=="${NamedNPC1}" && Type != "Corpse" && Distance <= ${FirstNamedDistance}].ID(exists)}
			if !${Actor[Query,Name=="${NamedNPC2}" && Type != "Corpse" && Distance <= ${SecondNamedDistance}].ID(exists)}
				if !${Actor[Query,Name=="${NamedNPC3}" && Type != "Corpse" && Distance <= ${ThirdNamedDistance}].ID(exists)}
					PathClear:Set[TRUE]
		; If path isn't clear, wait a second before checking again
		if !${PathClear}
			wait 10
	}
	
	; Path clear
	return TRUE
}

function HandleHandCombat()
{
	; Wait for Combat to end, collecting Sphere of Influence if needed
	while ${Me.InCombat}
	{
		; Wait until no one in the group has Sphere of Influence detrimental
		call WaitUntilNoOneHasSphereOfInfluence
		; If still in combat, get it
		if ${Me.InCombat}
		{
			; Wait for path clear to collect first set of orbs
			call WaitForBottomPathClear "35" "35" "35"
			; Collect first Sphere of Influence
			call CollectFirstSphereOfInfluence "TRUE"
		}
		; Wait a second before checking again
		wait 10
	}
}

function WaitUntilNoOneHasSphereOfInfluence()
{
	oc ${Me.Name} waiting until no one in the group has Sphere of Influence
	
	; Wait until no one in the group has Sphere of Influence detrimental
	variable bool AnyoneHasSphereOfInfluence=TRUE
	while ${AnyoneHasSphereOfInfluence}
	{
		; Check to see if anyone in the group has Sphere of Influence detrimental
		call CheckAnyoneHasSphereOfInfluence
		AnyoneHasSphereOfInfluence:Set[${Return}]
		if ${AnyoneHasSphereOfInfluence}
		{
			; Wait a second before checking again
			wait 10
		}
	}
}

function CheckEveryoneHasSphereOfInfluence()
{
	; Check to see if everyone in the group has Sphere of Influence detrimental
	if !${OgreBotAPI.Get_Variable["${Me.Name}_HaveSphereOfInfluence"]}
		return FALSE
	variable int GroupNum=0
	while ${GroupNum:Inc} < ${Me.GroupCount}
	{
		if !${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}_HaveSphereOfInfluence"]}
			return FALSE
	}
	
	; No one in the group without Sphere of Influence detrimental
	return TRUE
}

function CheckAnyoneHasSphereOfInfluence()
{
	; Check to see if anyone in the group has Sphere of Influence detrimental
	if ${OgreBotAPI.Get_Variable["${Me.Name}_HaveSphereOfInfluence"]}
		return TRUE
	variable int GroupNum=0
	while ${GroupNum:Inc} < ${Me.GroupCount}
	{
		if ${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}_HaveSphereOfInfluence"]}
			return TRUE
	}
	
	; No one in the group has Sphere of Influence detrimental
	return FALSE
}

function CollectFirstSphereOfInfluence(bool BackToSafeSpot)
{
	; Travel to Sphere of Influence
	call move_waypoint_custom "384.79,-10.40,292.00"
	call move_waypoint_custom "386.45,-10.62,302.07"
	call move_waypoint_custom "394.30,-10.62,301.80"
	call move_waypoint_custom "${SphereOfInfluence1Spot}"
	; Make sure everyone in the group has Sphere of Influence detrimental
	wait 20
	variable bool EveryoneHasSphereOfInfluence=FALSE
	while !${EveryoneHasSphereOfInfluence}
	{
		; Check to see if everyone in the group has Sphere of Influence detrimental
		call CheckEveryoneHasSphereOfInfluence
		EveryoneHasSphereOfInfluence:Set[${Return}]
		if !${EveryoneHasSphereOfInfluence}
		{
			; If anyone doesn't have it, back off and return to SphereOfInfluence1Spot
			call move_waypoint_custom "403.13,-10.60,292.05"
			call move_waypoint_custom "${SphereOfInfluence1Spot}"
		}
	}
	; Back to SafeSpot if necessary
	if ${BackToSafeSpot}
	{
		call move_waypoint_custom "394.30,-10.62,301.80"
		call move_waypoint_custom "386.45,-10.62,302.07"
		call move_waypoint_custom "384.79,-10.40,292.00"
		call move_waypoint_custom "${SafeSpot}"
	}
}

function CollectPath1Orbs()
{
	; Collect first set of orbs around starting area
	call move_waypoint_custom "384.79,-10.40,292.00"
	call move_waypoint_custom "384.34,-10.62,310.63"
	call move_waypoint_custom "399.87,-10.61,294.84"
	call move_waypoint_custom "400.00,-10.61,289.08"
	call move_waypoint_custom "384.53,-10.62,273.49"
	call move_waypoint_custom "384.79,-10.40,292.00"
	call move_waypoint_custom "${SafeSpot}"
}

function CollectPath2Orbs()
{
	; Collect first Sphere of Influence
	call CollectFirstSphereOfInfluence "FALSE"
	; Collect second set of orbs around starting area
	call move_waypoint_custom "399.84,-10.61,294.93"
	call move_waypoint_custom "384.61,-10.62,310.57"
	call move_waypoint_custom "384.45,-10.62,315.35"
	call move_waypoint_custom "387.93,-10.62,318.28"
	call move_waypoint_custom "405.71,-10.60,300.77"
	call move_waypoint_custom "405.89,-10.60,283.33"
	call move_waypoint_custom "388.21,-10.62,265.56"
	call move_waypoint_custom "384.40,-10.62,268.41"
	call move_waypoint_custom "384.79,-10.40,292.00"
	call move_waypoint_custom "${SafeSpot}"
}

function CollectPath3Orbs()
{
	; Collect first Sphere of Influence
	call CollectFirstSphereOfInfluence "FALSE"
	; Collect third set of orbs around starting area
	call move_waypoint_custom "399.84,-10.61,294.93"
	call move_waypoint_custom "384.61,-10.62,310.57"
	call move_waypoint_custom "384.45,-10.62,315.36"
	call move_waypoint_custom "397.23,-10.62,320.30"
	call move_waypoint_custom "418.47,-10.57,299.05"
	call move_waypoint_custom "421.51,-10.56,294.56"
	call move_waypoint_custom "421.46,-10.56,289.43"
	call move_waypoint_custom "418.55,-10.57,284.82"
	call move_waypoint_custom "397.35,-10.62,263.72"
	call move_waypoint_custom "384.50,-10.62,268.47"
	call move_waypoint_custom "384.79,-10.40,292.00"
	call move_waypoint_custom "${SafeSpot}"
}

function CollectLeftSideOrbs(bool WaitCombat=FALSE, string _NamedNPC="Doesnotexist")
{
	; Make sure no one already has Sphere of Influence
	call CheckAnyoneHasSphereOfInfluence
	if !${Return}
	{
		; Message collecting left side orbs or looking for named
		if ${_NamedNPC.Equal["Doesnotexist"]}
			oc ${Me.Name} collecting left side orbs
		else
			oc ${Me.Name} looking for ${_NamedNPC} on left side
		; Collect first Sphere of Influence
		call CollectFirstSphereOfInfluence "FALSE"
		; If _NamedNPC has been set, enable AutoTarget for it
		if !${_NamedNPC.Equal["Doesnotexist"]}
		{
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		}
		; Left side (outer perimeter)
		call move_waypoint_custom "399.84,-10.61,294.93" "${WaitCombat}"
		call move_waypoint_custom "384.61,-10.62,310.57" "${WaitCombat}"
		call move_waypoint_custom "384.44,-10.62,315.45" "${WaitCombat}"
		call move_waypoint_custom "397.15,-10.62,320.19" "${WaitCombat}"
		call move_waypoint_custom "407.79,-10.60,309.64" "${WaitCombat}"
		call move_waypoint_custom "453.65,-10.60,309.62" "${WaitCombat}"
		call move_waypoint_custom "453.54,-10.62,337.69" "${WaitCombat}"
		call move_waypoint_custom "408.53,-10.62,337.69" "${WaitCombat}"
		call move_waypoint_custom "408.36,-10.60,309.68" "${WaitCombat}"
		; Left side (1st room)
		call move_waypoint_custom "426.11,-10.58,309.66" "${WaitCombat}"
		call move_waypoint_custom "426.08,-10.62,328.47" "${WaitCombat}"
		call move_waypoint_custom "416.09,-10.62,328.37" "${WaitCombat}"
		call move_waypoint_custom "416.10,-10.60,318.44" "${WaitCombat}"
		call move_waypoint_custom "426.03,-10.60,318.47" "${WaitCombat}"
		call move_waypoint_custom "426.05,-10.62,328.38" "${WaitCombat}"
		call move_waypoint_custom "416.12,-10.62,328.33" "${WaitCombat}"
		call move_waypoint_custom "416.04,-10.62,337.63" "${WaitCombat}"
		call move_waypoint_custom "445.09,-10.62,337.65" "${WaitCombat}"
		; Left side (2nd room)
		call move_waypoint_custom "445.17,-10.60,318.41" "${WaitCombat}"
		call move_waypoint_custom "435.15,-10.60,318.37" "${WaitCombat}"
		call move_waypoint_custom "435.06,-10.62,328.36" "${WaitCombat}"
		call move_waypoint_custom "445.08,-10.62,328.48" "${WaitCombat}"
		call move_waypoint_custom "445.27,-10.60,318.45" "${WaitCombat}"
		call move_waypoint_custom "435.12,-10.60,318.36" "${WaitCombat}"
		call move_waypoint_custom "435.35,-10.58,309.66" "${WaitCombat}"
		call move_waypoint_custom "407.80,-10.60,309.51" "${WaitCombat}"
		call move_waypoint_custom "397.13,-10.62,320.12" "${WaitCombat}"
		call move_waypoint_custom "383.53,-10.62,317.77" "${WaitCombat}"
		call move_waypoint_custom "384.58,-10.62,315.42" "${WaitCombat}"
		call move_waypoint_custom "384.79,-10.40,292.00" "${WaitCombat}"
		call move_waypoint_custom "${SafeSpot}" "TRUE"
		; Set LeftSideOrbsCollected = TRUE
		LeftSideOrbsCollected:Set[TRUE]
		; If _NamedNPC has been set, clear AutoTarget
		if !${_NamedNPC.Equal["Doesnotexist"]}
			Ob_AutoTarget:Clear
	}
}

function CollectRightSideOrbs(bool WaitCombat=FALSE, string _NamedNPC="Doesnotexist")
{
	; Make sure no one already has Sphere of Influence
	call CheckAnyoneHasSphereOfInfluence
	if !${Return}
	{
		; Message collecting right side orbs or looking for named
		if ${_NamedNPC.Equal["Doesnotexist"]}
			oc ${Me.Name} collecting right side orbs
		else
			oc ${Me.Name} looking for ${_NamedNPC} on right side
		; Collect first Sphere of Influence
		call CollectFirstSphereOfInfluence "FALSE"
		; If _NamedNPC has been set, enable AutoTarget for it
		if !${_NamedNPC.Equal["Doesnotexist"]}
		{
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		}
		; Right side (outer perimeter)
		call move_waypoint_custom "399.84,-10.61,289.07" "${WaitCombat}"
		call move_waypoint_custom "384.61,-10.62,273.43" "${WaitCombat}"
		call move_waypoint_custom "384.44,-10.62,268.55" "${WaitCombat}"
		call move_waypoint_custom "397.15,-10.62,263.81" "${WaitCombat}"
		call move_waypoint_custom "407.79,-10.60,274.36" "${WaitCombat}"
		call move_waypoint_custom "453.65,-10.60,274.38" "${WaitCombat}"
		call move_waypoint_custom "453.54,-10.62,246.31" "${WaitCombat}"
		call move_waypoint_custom "408.53,-10.62,246.31" "${WaitCombat}"
		call move_waypoint_custom "408.36,-10.60,274.32" "${WaitCombat}"
		; Right side (1st room)
		call move_waypoint_custom "426.11,-10.58,274.34" "${WaitCombat}"
		call move_waypoint_custom "426.08,-10.62,255.53" "${WaitCombat}"
		call move_waypoint_custom "416.09,-10.62,255.63" "${WaitCombat}"
		call move_waypoint_custom "416.10,-10.60,265.56" "${WaitCombat}"
		call move_waypoint_custom "426.03,-10.60,265.53" "${WaitCombat}"
		call move_waypoint_custom "426.05,-10.62,255.62" "${WaitCombat}"
		call move_waypoint_custom "416.12,-10.62,255.67" "${WaitCombat}"
		call move_waypoint_custom "416.04,-10.62,246.37" "${WaitCombat}"
		call move_waypoint_custom "445.09,-10.62,246.35" "${WaitCombat}"
		; Right side (2nd room)
		call move_waypoint_custom "445.17,-10.60,265.59" "${WaitCombat}"
		call move_waypoint_custom "435.15,-10.60,265.63" "${WaitCombat}"
		call move_waypoint_custom "435.06,-10.62,255.64" "${WaitCombat}"
		call move_waypoint_custom "445.08,-10.62,255.52" "${WaitCombat}"
		call move_waypoint_custom "445.27,-10.60,265.55" "${WaitCombat}"
		call move_waypoint_custom "435.12,-10.60,265.64" "${WaitCombat}"
		call move_waypoint_custom "435.35,-10.58,274.34" "${WaitCombat}"
		call move_waypoint_custom "407.80,-10.60,274.49" "${WaitCombat}"
		call move_waypoint_custom "397.13,-10.62,263.88" "${WaitCombat}"
		call move_waypoint_custom "383.42,-10.62,265.94" "${WaitCombat}"
		call move_waypoint_custom "384.58,-10.62,268.58" "${WaitCombat}"
		call move_waypoint_custom "384.79,-10.40,292.00" "${WaitCombat}"
		call move_waypoint_custom "${SafeSpot}" "TRUE"
		; Set RightSideOrbsCollected = TRUE
		RightSideOrbsCollected:Set[TRUE]
		; If _NamedNPC has been set, clear AutoTarget
		if !${_NamedNPC.Equal["Doesnotexist"]}
			Ob_AutoTarget:Clear
	}
}

function CollectShinies()
{
	; Wait until no one in the group has Sphere of Influence detrimental
	call WaitUntilNoOneHasSphereOfInfluence
	; Collect first Sphere of Influence
	call CollectFirstSphereOfInfluence "FALSE"
	; Shiny near first orb
	call move_collect_shinies "405.37,-10.59,291.92"
	call move_collect_shinies "405.15,-10.60,282.29"
	call move_collect_shinies "405.37,-10.59,291.92"
	; Shiny at top of bottom triangle
	call move_collect_shinies "384.35,-10.62,309.65"
	call move_collect_shinies "384.32,-10.62,315.41"
	call move_collect_shinies "397.03,-10.62,320.40"
	call move_collect_shinies "418.52,-10.57,299.07"
	call move_collect_shinies "416.09,-10.57,297.47"
	call move_collect_shinies "418.52,-10.57,299.07"
	; Shiny at bottom of left side bottom loop
	call move_collect_shinies "418.44,-10.58,309.54"
	call move_collect_shinies "426.17,-10.58,309.64"
	call move_collect_shinies "426.59,-10.59,317.37"
	call move_collect_shinies "416.64,-10.60,318.06"
	call move_collect_shinies "415.92,-10.61,321.39"
	; Shinies at left side top loop
	call move_collect_shinies "416.05,-10.60,318.09"
	call move_collect_shinies "426.69,-10.60,318.07"
	call move_collect_shinies "426.04,-10.58,309.40"
	call move_collect_shinies "434.80,-10.57,309.30"
	call move_collect_shinies "435.39,-10.60,318.26"
	call move_collect_shinies "435.35,-10.62,327.63"
	call move_collect_shinies "435.39,-10.60,318.26"
	call move_collect_shinies "445.25,-10.60,318.23"
	call move_collect_shinies "445.44,-10.61,325.79"
	; Shiny at bottom of right side
	call move_collect_shinies "445.35,-10.60,318.35"
	call move_collect_shinies "434.50,-10.59,318.32"
	call move_collect_shinies "435.16,-10.58,310.03"
	call move_collect_shinies "413.47,-10.59,309.22"
	call move_collect_shinies "421.38,-10.56,294.87"
	call move_collect_shinies "420.84,-10.56,286.92"
	call move_collect_shinies "407.25,-10.60,272.65"
	call move_collect_shinies "409.25,-10.60,265.61"
	call move_collect_shinies "404.17,-10.62,257.14"
	; Shiny at bottom of right side bottom loop
	call move_collect_shinies "407.91,-10.62,247.33"
	call move_collect_shinies "416.36,-10.62,246.85"
	call move_collect_shinies "416.53,-10.61,263.58"
	; Shiny at right side top loop
	call move_collect_shinies "416.43,-10.60,266.36"
	call move_collect_shinies "427.36,-10.60,265.67"
	call move_collect_shinies "427.42,-10.57,275.04"
	call move_collect_shinies "435.76,-10.57,274.80"
	call move_collect_shinies "435.34,-10.62,255.59"
	call move_collect_shinies "445.87,-10.62,255.43"
	call move_collect_shinies "435.34,-10.62,255.59"
	call move_collect_shinies "435.76,-10.57,274.80"
	; Shiny at top near zone out
	call move_collect_shinies "453.16,-10.58,275.76"
	call move_collect_shinies "444.49,-10.56,283.17"
	call move_collect_shinies "447.29,-10.57,286.30"
	call move_collect_shinies "444.49,-10.56,283.17"
	; Shiny at top
	call move_collect_shinies "453.16,-10.58,275.76"
	call move_collect_shinies "465.43,-10.61,263.82"
	call move_collect_shinies "472.83,-10.62,266.78"
	call move_collect_shinies "465.25,-10.61,275.34"
	call move_collect_shinies "472.83,-10.62,266.78"
	; Shiny at second Sphere of Influence
	call move_collect_shinies "477.01,-10.62,268.01"
	call move_collect_shinies "479.47,-10.62,271.63"
	call move_collect_shinies "464.25,-10.61,287.08"
	call move_collect_shinies "466.43,-10.61,292.44"
	; Another shiny at top near zone out
	call move_collect_shinies "466.20,-10.62,299.41"
	call move_collect_shinies "479.53,-10.62,310.99"
	call move_collect_shinies "474.14,-10.62,317.68"
	call move_collect_shinies "466.31,-10.62,310.02"
	; Shiny at top left
	call move_collect_shinies "474.14,-10.62,317.68"
	call move_collect_shinies "463.83,-10.61,319.63"
	call move_collect_shinies "452.14,-10.59,307.50"
	call move_collect_shinies "456.13,-10.62,330.85"
	call move_collect_shinies "452.14,-10.59,307.50"
	; Go to zone out
	call move_collect_shinies "446.14,-10.57,302.36"
	call move_collect_shinies "439.90,-10.55,292.71"
	call move_collect_shinies "431.30,-10.54,292.14"
	; Shiny near zone out
	call move_collect_shinies "432.93,-10.55,299.70"
	call move_collect_shinies "431.30,-10.54,292.14"
}

function CheckNamedCombat(string _NamedNPC)
{
	; Check to see if in combat
	if ${Me.InCombat}
	{
		; Assume in combat with named if they are the target
		if ${Me.Target.Name.Equal[${_NamedNPC}]}
		{
			; If don't have both sides collected may run out of time to kill named
			; In that case, collect second sphere of influence to extend the time
			; Will probably wipe if grab aggro on the first side collected
			if !${LeftSideOrbsCollected} || !${RightSideOrbsCollected}
				call CollectSecondSphereOfInfluence
			; Wait for Combat to end
			while ${Me.InCombat}
			{
				; Wait a second before checking again
				wait 10
			}
		}
		; If not in combat with named, assume in combat with hand
		else
			call HandleHandCombat	
	}
}

function CollectSecondSphereOfInfluence()
{
	; Assume everyone already has first sphere, collect the second to extend the time
	; May be in combat with a named while this is happening, so wait a few seconds after each move to cast spells
	; Move around left side to second orb
	wait 100
	call move_waypoint_custom "384.79,-10.40,292.00"
	wait 30
	call move_waypoint_custom "397.28,-10.62,320.30"
	wait 30
	call move_waypoint_custom "407.83,-10.60,309.67"
	wait 30
	call move_waypoint_custom "454.48,-10.60,309.66"
	wait 30
	call move_waypoint_custom "465.07,-10.62,320.33"
	wait 30
	call move_waypoint_custom "470.70,-10.62,314.78"
	wait 30
	call move_waypoint_custom "456.49,-10.60,300.62"
	wait 30
	call move_waypoint_custom "456.35,-10.59,291.85"
	wait 30
	call move_waypoint_custom "${SphereOfInfluence2Spot}"
	; Get it a second time just in case someone didn't pick it up
	wait 30
	call move_waypoint_custom "456.35,-10.59,291.85"
	wait 30
	call move_waypoint_custom "${SphereOfInfluence2Spot}"
	; Move around right side back to SafeSpot
	wait 30
	call move_waypoint_custom "456.62,-10.59,283.46"
	wait 30
	call move_waypoint_custom "470.68,-10.62,269.32"
	wait 30
	call move_waypoint_custom "465.19,-10.61,263.65"
	wait 30
	call move_waypoint_custom "454.42,-10.58,274.16"
	wait 30
	call move_waypoint_custom "407.95,-10.60,274.13"
	wait 30
	call move_waypoint_custom "397.42,-10.62,263.55"
	wait 30
	call move_waypoint_custom "388.17,-10.62,265.48"
	wait 30
	call move_waypoint_custom "384.44,-10.62,268.53"
	wait 30
	call move_waypoint_custom "384.79,-10.40,292.00"
	wait 30
	call move_waypoint_custom "${SafeSpot}"
}

function CheckOrbsAbsorbed()
{
	; Check to see if have Orbs Absorbed detrimental
	if ${Me.Effect[Query, Type == "Detrimental" && MainIconID == 119 && BackDropIconID == 119].ID(exists)}
	{
		; If have more than 130 orbs absorbed assume both left and right side already collected
		if ${Me.Effect[Query, Type == "Detrimental" && MainIconID == 119 && BackDropIconID == 119].CurrentIncrements} > 130
		{
			LeftSideOrbsCollected:Set[TRUE]
			RightSideOrbsCollected:Set[TRUE]
		}
	}
}

function move_waypoint_custom(point3f waypoint, bool WaitCombat=FALSE)
{
	; If WaitCombat and in combat, wait until combat ends before moving (unless Target not in combat)
	variable bool InCombat=FALSE
	while ${WaitCombat} && ${Me.InCombat}
	{
		InCombat:Set[TRUE]
		Wait 10
		; Exit if target not in combat (may have targeted a named, but not aggroed it)
		if ${Target(exists)} && !${Target.InCombatMode}
			break
	}
	if ${InCombat}
	{
		eq2execute summon
		wait 10
		call Obj_OgreIH.Get_Chest
	}
	; Move to waypoint without stopping for combat or collecting shinies
	oc !ci -resume igw:${Me.Name}
	oc !ci -letsgo igw:${Me.Name}
	Obj_OgreIH:SetCampSpot
	oc !ci -notarget ${Me.Name}
	Obj_OgreIH:ChangeCampSpot["${waypoint}"]
	call Obj_OgreUtilities.HandleWaitForCampSpot 5
	call Obj_OgreUtilities.HandleWaitForGroupDistance 5
}

function move_collect_shinies(point3f waypoint)
{
	oc !ci -resume igw:${Me.Name}
	oc !ci -letsgo igw:${Me.Name}
	variable float Return_X="0"
    variable float Return_Y="0"
    variable float Return_Z="0"
	Obj_OgreIH:SetCampSpot
	oc !ci -notarget ${Me.Name}
	Obj_OgreIH:ChangeCampSpot["${waypoint}"]
	call Obj_OgreUtilities.HandleWaitForCampSpot 5
	wait 5
	if ${Me.InCombat}
	{
		call kill_trash
	}
	if ${Actor[Query,Name=="?" && Distance <= 5](exists)}
	{
		Return_X:Set[${Me.X}]
		Return_Y:Set[${Me.Y}]
		Return_Z:Set[${Me.Z}]
		Obj_OgreIH:CCS_Actor["${Actor[Query,Name=="?"].ID}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 5
		call Obj_OgreUtilities.HandleWaitForCombat
		while ${Actor[Query,Name=="?" && Distance <= 5](exists)}
		{
			Obj_OgreIH:CCS_Actor["${Actor[Query,Name=="?"].ID}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 5
			Actor[Query,Name=="?"]:DoTarget
			wait 1
			Actor[Query,Name=="?"]:DoubleClick
			wait 20
		}
		ShiniesLooted:Inc
		oc ${Me.Name} ninjas a shiny [${ShiniesLooted} so far]
		Obj_OgreIH:ChangeCampSpot["${Return_X},${Return_Y},${Return_Z}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 5
	}
	if ${Me.InCombat}
	{
		call kill_trash
	}
	call Obj_OgreUtilities.HandleWaitForGroupDistance 5
}
