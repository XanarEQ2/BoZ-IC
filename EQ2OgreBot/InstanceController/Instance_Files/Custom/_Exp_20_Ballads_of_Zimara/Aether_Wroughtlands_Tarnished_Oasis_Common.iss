; This IC file requires ZoneHelperScript/HOHelperScript/MendRuneSwapHelperScript/IC_Helper files to function
variable string ZoneHelperScript="EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/Aether_Wroughtlands_Tarnished_Oasis_Helper"
variable string HOHelperScript="HO_Helper"
variable string MendRuneSwapHelperScript="EQ2OgreBot/InstanceController/Support_Files_Common/Mend_Rune_Swap_Helper"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"

variable string Solo_Zone_Name="Aether Wroughtlands: Tarnished Oasis [Solo]"
variable string Heroic_1_Zone_Name="Aether Wroughtlands: Tarnished Oasis [Heroic I]"
variable string Heroic_2_Zone_Name="Aether Wroughtlands: Tarnished Oasis [Heroic II]"
variable bool CragnokIncomingSwipe=FALSE
variable bool CragnokIncomingCriticalMass=FALSE
variable int DerussahKillSpotNum=1

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
			call This.Named1 "Farzun the Forerunner"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#1: Farzun the Forerunner"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 2
		if ${_StartingPoint} == 2
		{
			call This.Named2 "Tarsisk the Tainted"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#2: Tarsisk the Tainted"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 3
		if ${_StartingPoint} == 3
		{
			call This.Named3 "Cragnok"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#3: Cragnok"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 4
		if ${_StartingPoint} == 4
		{
			call This.Named4 "Derussah the Deceptive"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#4: Derussah the Deceptive"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 5
		if ${_StartingPoint} == 5
		{
			call This.Named5 "Hasira the Hawk"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#5: Hasira the Hawk"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		
		; Zone Out
		if ${_StartingPoint} == 6
		{
			call move_to_next_waypoint "-826.74,53.97,-385.08" "10"
			call move_to_next_waypoint "-786.33,54.94,-400.36" "5"
			; Look for shinies
			if !${Ogre_Instance_Controller.bSkipShinies}
			{
				call move_to_next_waypoint "-753.29,53.73,-402.12" "5"
				call move_to_next_waypoint "-786.33,54.94,-400.36" "5"
			}
			call move_to_next_waypoint "-781.36,54.27,-403.11" "1"
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

/**********************************************************************************************************
    Named 1 **********************    Move to, spawn and kill - Farzun the Forerunner   *******************
***********************************************************************************************************/

	function:bool Named1(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-620.08,35.80,-693.02]
		
		; Repair if needed
		call mend_and_rune_swap "noswap" "noswap" "noswap" "noswap"
		
		; Enable HO for all (mobs have "Gritty" effect that reduces damage, dispel with HO)
		eq2execute cancel_ho_starter
		call HO "All" "FALSE"
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "${_NamedNPC}"

		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "1"
		call move_to_next_waypoint "-381.72,59.16,-247.33"
		call move_to_next_waypoint "-432.62,54.52,-304.84"
		call move_to_next_waypoint "-377.43,55.39,-370.10"
		call move_to_next_waypoint "-398.62,56.37,-431.32"
		call move_to_next_waypoint "-423.46,54.13,-506.28"
		call move_to_next_waypoint "-464.42,57.74,-565.46"
		call move_to_next_waypoint "-533.50,45.22,-616.16"
		
		; Destroy Forerunner's Blink Buoys
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["Forerunner's Blink Buoy",0,FALSE,FALSE]
		call move_to_next_waypoint "-542.18,45.65,-649.52"
		Obj_OgreIH:ChangeCampSpot["-537.70,43.22,-672.500"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		call move_to_next_waypoint "-522.30,43.27,-693.85"
		call move_to_next_waypoint "-558.16,37.24,-655.24"
		call move_to_next_waypoint "-559.71,49.63,-605.12"
		call move_to_next_waypoint "-587.35,45.51,-633.50"
		call move_to_next_waypoint "-627.02,41.60,-614.51"
		call move_to_next_waypoint "-595.30,40.72,-653.03"
		call move_to_next_waypoint "-605.85,35.02,-668.99"
		Obj_OgreIH:ChangeCampSpot["-631.87,35.06,-660.14"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		call move_to_next_waypoint "-638.79,34.81,-649.04"
		call move_to_next_waypoint "-628.75,35.19,-662.31"
		call move_to_next_waypoint "-600.91,35.02,-673.48"
		
		; Disable HO for all
		call HO "Disable" "FALSE"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; If H2, swap to fear immunity rune
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			call mend_and_rune_swap "fear" "fear" "fear" "fear"
		
		; Kill named
		; For H2, summons adds and get "Zakir Rush" detrimental while adds are up
		; 	just ignored the adds and detrimental and focused dps on the named and it was fine
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
		
		; Finished with named
		return TRUE
	}

/**********************************************************************************************************
 	Named 2 ********************    Move to, spawn and kill - Tarsisk the Tainted  ************************
***********************************************************************************************************/

	function:bool Named2(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-556.06,52.66,-437.08]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "2"
		call move_to_next_waypoint "-588.06,40.68,-655.91"
		call move_to_next_waypoint "-594.86,46.81,-571.73" "40"
		; Stop by Shiny
		call move_to_next_waypoint "-569.44,50.92,-500.23"
		call move_to_next_waypoint "-558.93,51.70,-470.58"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; If H2, swap to stun immunity rune
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			call mend_and_rune_swap "stun" "stun" "stun" "stun"
		
		; For H2, enable HO for all
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			eq2execute cancel_ho_starter
			call HO "All" "FALSE"
			oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
			oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "${_NamedNPC}"
		}

		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["corrupted roots",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_n_Spank "${_NamedNPC}" "${KillSpot}"
			Ob_AutoTarget:Clear
		}
		; For H2
		; Metallic Affliction buff on named reduces all damage by 100%
		; 	Need HO to remove
		; Corrupted Roots detrimental when roots spawn
		; 	Have fighter use Bulwark against roots to reset Cure Curse for Priest allies
		; 	Anyone still trapped when Tarsisk pulls back has Corrupted Roots will die (have 45s to clear them all)
		elseif ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Set default values for variables
			oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RootPriority" "3"
			oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RootID" "0"
			variable int GroupNum=0
			while ${GroupNum:Inc} < ${Me.GroupCount}
			{
				oc !ci -Set_Variable igw:${Me.Name} "${Me.Group[${GroupNum}].Name}_RootPriority" "3"
				oc !ci -Set_Variable igw:${Me.Name} "${Me.Group[${GroupNum}].Name}_RootID" "0"
			}
			; Clear AutoTarget, will selectively target
			Ob_AutoTarget:Clear
			; Disable Cure Curse
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_curecurse TRUE TRUE
			; Disable ascensions for fighter (don't want to cast things with a long cast time when trying to proc Overpowering Barrage)
			call SetupAscensionsFighter "FALSE"
			; Run ZoneHelperScript to help select roots to remove
			oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
			oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC}"
			; Kill named
			oc ${Me.Name} is pulling ${_NamedNPC}
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			Actor["${_NamedNPC}"]:DoTarget
			; Use Monkey In Middle formation to keep characters spread out so they can each see their own root
			oc !ci -CS_Set_Formation_MonkeyInMiddle igw:${Me.Name} 5 ${Me.X} ${Me.Y} ${Me.Z} ${Me.Name}
			wait 50
			variable int RootPriority
			variable int RootID
			variable string CharacterName
			variable int WaitTime
			while ${Me.InCombat}
			{
				; Check to see if any "corrupted roots" exist
				if ${Actor[Query,Name=="corrupted roots" && Type != "Corpse" && Distance <= 50].ID(exists)}
				{
					; Get ID of root to remove first based on RootPriority
					RootPriority:Set[0]
					RootID:Set[0]
					; Loop through Priority 1/2/3 looking for character with a RootID
					while ${RootPriority:Inc} <= 3 && ${RootID.Equal[0]}
					{
						if ${RootPriority.Equal[${OgreBotAPI.Get_Variable["${Me.Name}_RootPriority"]}]}
							RootID:Set[${OgreBotAPI.Get_Variable["${Me.Name}_RootID"]}]
						if !${RootID.Equal[0]}
							CharacterName:Set["${Me.Name}"]
						GroupNum:Set[0]
						while ${RootID.Equal[0]} && ${GroupNum:Inc} < ${Me.GroupCount}
						{
							if ${RootPriority.Equal[${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}_RootPriority"]}]}
								RootID:Set[${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}_RootID"]}]
							if !${RootID.Equal[0]}
								CharacterName:Set["${Me.Group[${GroupNum}].Name}"]
						}
					}
					; If a valid RootID was found, remove it
					while !${RootID.Equal[0]} && ${Actor[${RootID}].ID(exists)}
					{
						; Target root to remove (if can't cure it, may be able to dps it down)
						if !${Target(exists)} || !${Target.ID.Equal[${RootID}]}
							Actor[${RootID}]:DoTarget
						; Set AutoCurse for group member to cure CharacterName (curing them will remove the root)
						oc !ci -AutoCurse igw:${Me.Name} ${CharacterName}
						; Wait a bit for curse to be cured
						WaitTime:Set[0]
						while ${WaitTime:Inc} <=5 && ${Actor[${RootID}].ID(exists)}
						{
							wait 10
						}
						if !${Actor[${RootID}].ID(exists)}
							break
						; If root still exists, have fighter cast Bulwark to reset recast on Cure Curse
						oc !ci -CastAbility igw:${Me.Name}+fighter "Bulwark of Order"
						wait 10
					}
				}
				; If no "corrupted roots", focus on named
				else
				{
					if !${Target(exists)} || !${Target.Name.Equal["${_NamedNPC}"]}
						Actor["${_NamedNPC}"]:DoTarget
				}
				; Wait a second before looping again
				wait 10
			}
			Ob_AutoTarget:Clear
			; Re-enable Cure Curse and ascensions for fighter
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_curecurse FALSE TRUE
			call SetupAscensionsFighter "TRUE"
			; Send everyone back to KillSpot
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
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

/**********************************************************************************************************
 	Named 3 *********************    Move to, spawn and kill - Cragnok ************************************
***********************************************************************************************************/

	function:bool Named3(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-561.50,52.62,-188.03]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "3"
		; Look for shiny from last boss
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "-524.72,54.35,-403.23" "5"
			call move_to_next_waypoint "-490.19,56.29,-352.12" "25"
			call move_to_next_waypoint "-524.72,54.35,-403.23" "25"
			call move_to_next_waypoint "-556.06,52.66,-437.08"
		}
		call move_to_next_waypoint "-574.35,53.82,-359.15"
		; Look for shiny from last boss
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "-640.94,55.13,-386.98" "5"
			call move_to_next_waypoint "-574.35,53.82,-359.15"
		}
		call move_to_next_waypoint "-563.84,56.94,-304.37"
		call move_to_next_waypoint "-534.94,54.15,-254.23" "5"
		; Look for shiny from last boss
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "-521.66,59.61,-268.85" "5"
			call move_to_next_waypoint "-534.94,54.15,-254.23" "5"
			call move_to_next_waypoint "-540.86,54.09,-225.45" "1"
			call move_to_next_waypoint "-548.07,57.99,-225.81" "5"
			call move_to_next_waypoint "-540.86,54.09,-225.45" "1"
			call move_to_next_waypoint "-534.94,54.15,-254.23" "5"
		}
		call move_to_next_waypoint "-519.86,54.36,-193.95"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; If H2, swap to stifle immunity rune
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
			call mend_and_rune_swap "stifle" "stifle" "stifle" "stifle"
		
		; Disable HO for all
		call HO "Disable" "FALSE"
		
		; For H2, attach Atoms to handle text events, run HOHelperScript but leave HO disabled for now, and disable Immunization
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Handle text events
			Event[EQ2_onIncomingChatText]:AttachAtom[CragnokIncomingChatText]
			Event[EQ2_onIncomingText]:AttachAtom[CragnokIncomingText]
			; Run HOHelperScript
			oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
			oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "${_NamedNPC}"
			; Disable Immunization for Mystic in Cast Stack (pretty sure it prevents the Heroic Stomp knock up)
			oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Immunization" FALSE TRUE
		}
		
		; If H2, clear lower level mobs before fight
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			call move_to_next_waypoint "-523.32,-6.34,-138.88" "1"
			call move_to_next_waypoint "-510.72,-4.91,-139.66" "1"
			call move_to_next_waypoint "-547.85,-6.12,-107.62" "1"
			call move_to_next_waypoint "-560.21,-6.34,-142.05" "1"
			call move_to_next_waypoint "-540.31,-5.41,-148.80" "1"
			call EnterPortal "pick_sign" "Climb"
			; May potentially aggro named here (like Open Wounds from Berserker still active after killing trash mobs)
			Obj_OgreIH:ChangeCampSpot["-534.89,52.46,-184.73"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			;Obj_OgreIH:ChangeCampSpot["-519.86,54.36,-193.95"]
			;call Obj_OgreUtilities.HandleWaitForCampSpot 10
		}
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			; Send everyone to KillSpot
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			; Send non-fighters behind (if not Solo zone)
			if !${Zone.Name.Equals["${Solo_Zone_Name}"]}
				oc !ci -ChangeCampSpotWho "igw:${Me.Name}+notfighter" -562.51 53.58 -173.31
			; Kill named
			call Tank_in_Place "${_NamedNPC}"
			Ob_AutoTarget:Clear
			; Get Chest
			eq2execute summon
			wait 10
			call Obj_OgreIH.Get_Chest
		}
		; For H2, named will cast Critical Mass
		; 	When increments reach 0, destroys everyone on same level as him
		; 	Need to swap between upper and lower levels
		; 	On lower level, doing HOs will prompt the named to cast "Heroic Stomp" sending everyone into the air
		elseif ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Set AutoTarget
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			; Send everyone to KillSpot
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			; Send non-fighters behind
			oc !ci -ChangeCampSpotWho "igw:${Me.Name}+notfighter" -562.51 53.58 -173.31
			; Kill named
			oc ${Me.Name} is pulling ${_NamedNPC}
			oc !ci -PetOff igw:${Me.Name}
			wait 10
			oc !ci -PetAssist igw:${Me.Name}
			Actor["${_NamedNPC}"]:DoTarget
			wait 50
			variable bool OnTop=TRUE
			variable bool ReadyForHO=FALSE
			while ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
			{
				; If OnTop, wait until Critical Mass has 10 seconds left, then go to bottom
				if ${OnTop}
				{
					; Check for Critical Mass with 10 increments or less
					; 	Should always be in first effects slot
					call GetTargetEffectIncrements "Critical Mass" "1"
					if ${Return} > 0 && ${Return} <= 10
					{
						; Set CragnokIncomingCriticalMass to TRUE
						CragnokIncomingCriticalMass:Set[TRUE]
						; Move to bottom
						oc !ci -ChangeCampSpotWho "igw:${Me.Name}" -528.33 -4.56 -150.49
						; Wait for Critical Mass to go off
						while ${CragnokIncomingCriticalMass} && ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
						{
							wait 10
						}
						; Set OnTop to FALSE
						OnTop:Set[FALSE]
					}
				}
				; If not OnTop, need to use HOs to trigger Opportune Stomp to send characters flying in the air to they can get back to top
				else
				{
					; Check for Critical Mass
					; 	Should always be in first effects slot
					call GetTargetEffectIncrements "Critical Mass" "1"
					if ${Return} > 0
					{
						; Set CragnokIncomingCriticalMass to TRUE and CragnokIncomingSwipe to FALSE
						CragnokIncomingCriticalMass:Set[TRUE]
						CragnokIncomingSwipe:Set[FALSE]
						; Wait for a swipe (want to enable HO's after swipe so don't potentially get swiped right before Opportune Stomp goes off)
						while !${CragnokIncomingSwipe} && ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
						{
							wait 10
							; If down to 25 increments, need to stop waiting regardless of swipe
							call GetTargetEffectIncrements "Critical Mass" "1"
							if ${Return} > 0 && ${Return} <= 25
								break
							
						}
						; Wait a bit for swipe to go off
						if ${CragnokIncomingSwipe}
							wait 50
						; Check increments and wait a bit if there is still time before enabling HO's
						; 	Have seen swipes come in like 39 second increments so should have time to wait a bit and still complete HO
						call GetTargetEffectIncrements "Critical Mass" "1"
						if ${Return} >= 40
							wait 150
						elseif ${Return} >= 35
							wait 100
						elseif ${Return} >= 30
							wait 50
						; Enable HO for all to trigger Opportune Stomp
						eq2execute cancel_ho_starter
						call HO "All" "FALSE"
						; Run ZoneHelperScript to handle move to top of cliff for everyone else in the group
						; 	Initially handled everyone at the same time but had some characters get a delayed pop up into the air
						; 	This would cause them to get stuck on the cliff and die, so handling each character separately
						oc !ci -EndScriptRequiresOgreBot igw:${Me.Name}+-${Me.Name} ${ZoneHelperScript}
						oc !ci -RunScriptRequiresOgreBot igw:${Me.Name}+-${Me.Name} ${ZoneHelperScript} "${_NamedNPC}"
						; Wait to be sent into the air
						while ${Me.Y} < 35 && ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
						{
							wait 5
						}
						; Disable HO for all
						call HO "Disable" "FALSE"
						; Exit if named died before sending up in air
						if !${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
							break
						; Change CampSpot to top of cliff (just this character)
						oc !ci -ChangeCampSpotWho "${Me.Name}" -552.07 53.87 -194.17
						; Wait to land
						wait 70
						; Send everyone to new KillSpot
						oc !ci -ChangeCampSpotWho "igw:${Me.Name}+fighter" -528.90 53.42 -202.35
						oc !ci -ChangeCampSpotWho "igw:${Me.Name}+notfighter" -527.08 53.25 -185.12
						; Wait for Critical Mass to go off
						while ${CragnokIncomingCriticalMass} && ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
						{
							wait 10
						}
						; Set OnTop to TRUE
						OnTop:Set[TRUE]
					}
				}
				; Wait a second before looping
				wait 10
			}
			call Obj_OgreUtilities.HandleWaitForCombat
			call Obj_OgreUtilities.WaitWhileGroupMembersDead
			wait 50
			Ob_AutoTarget:Clear
			; Get Chest
			eq2execute summon
			wait 10
			call Obj_OgreIH.Get_Chest
			; After fight, if on bottom go back to top
			if ${Me.Y} < 40
			{
				call move_to_next_waypoint "-528.33,-4.56,-150.49" "1"
				call move_to_next_waypoint "-540.31,-5.41,-148.80" "1"
				call EnterPortal "pick_sign" "Climb"
				call move_to_next_waypoint "-535.50,52.70,-189.47" "1"
				call move_to_next_waypoint "-519.86,54.36,-193.95" "1"
			}
			; Send everyone back to KillSpot
			call move_to_next_waypoint "${KillSpot}" "1"
		}
		
		; Disable HO for all
		call HO "Disable" "FALSE"
		
		; For H2, detach Atoms that are no longer needed and re-enable Immunization
		if ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Detach Atoms
			Event[EQ2_onIncomingChatText]:DetachAtom[CragnokIncomingChatText]
			Event[EQ2_onIncomingText]:DetachAtom[CragnokIncomingText]
			; Re-enable Immunization for Mystic in Cast Stack
			oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Immunization" TRUE TRUE
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
			call move_to_next_waypoint "-533.29,-6.12,-127.46" "10"
			call move_to_next_waypoint "-574.45,-6.69,-110.67" "5"
			call move_to_next_waypoint "-561.60,-5.46,-102.23" "5"
			call move_to_next_waypoint "-574.45,-6.69,-110.67" "5"
			call move_to_next_waypoint "-533.29,-6.12,-127.46" "10"
			call move_to_next_waypoint "-508.22,-4.52,-139.50" "10"
			call move_to_next_waypoint "-533.29,-6.12,-127.46" "10"
			call move_to_next_waypoint "-540.31,-5.41,-148.80"
			call EnterPortal "pick_sign" "Climb"
			call move_to_next_waypoint "${KillSpot}"
		}
		
		; Finished with named
		return TRUE
	}
	
/**********************************************************************************************************
 	Named 4 *********************    Move to, spawn and kill - Derussah the Deceptive *********************
***********************************************************************************************************/

	function:bool Named4(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-731.06,58.57,-352.89]
		
		; Setup AutoTarget for "a sandscaled wyvern"
		; Other mobs gets 50% damage reduction when near a wyvern
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["a sandscaled wyvern",0,FALSE,FALSE]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "4"
		call move_to_next_waypoint "-605.19,53.21,-195.01" "5"
		; Stop by shiny on way to named
		call move_to_next_waypoint "-622.40,52.51,-209.63" "5"
		call move_to_next_waypoint "-700.14,54.47,-278.52" "15"
		call move_to_next_waypoint "-747.37,54.36,-310.56" "5"
		; Pull mobs near named, but don't want to fight there and risk aggroing named
		Obj_OgreIH:ChangeCampSpot["-744.28,54.21,-325.80"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		call move_to_next_waypoint "-747.37,54.36,-310.56" "5"
		call move_to_next_waypoint "-768.04,54.41,-325.28" "5"
		call move_to_next_waypoint "-799.12,53.94,-328.48" "5"
		call move_to_next_waypoint "-774.20,54.42,-325.93" "5"
		call move_to_next_waypoint "-759.97,53.73,-389.29" "5"
		call move_to_next_waypoint "-744.26,54.58,-434.88" "5"
		call move_to_next_waypoint "-784.53,54.62,-468.28" "5"
		call move_to_next_waypoint "-808.79,54.61,-464.67" "5"
		call move_to_next_waypoint "-790.23,54.57,-472.21" "5"
		call move_to_next_waypoint "-756.81,53.78,-444.06" "5"
		call move_to_next_waypoint "-764.48,53.98,-369.15" "5"
		
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
		
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			; Kill named
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["a violent vortex",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			call Tank_n_Spank "${_NamedNPC}" "${KillSpot}"
			Ob_AutoTarget:Clear
			; Get Chest
			eq2execute summon
			wait 10
			call Obj_OgreIH.Get_Chest
		}
		; For H2, have 3 sets of sand storm adds need to kill
		elseif ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Handle text events
			Event[EQ2_onIncomingChatText]:AttachAtom[DerussahIncomingChatText]
			; Setup variables to use during the fight
			variable int CurrentKillSpotNum=1
			variable point3f KillSpots[3]
			KillSpots[1]:Set[-731.06,58.57,-352.89]
			KillSpots[2]:Set[-767.76,53.97,-368.75]
			KillSpots[3]:Set[-760.91,53.80,-336.09]
			; Kill named
			oc ${Me.Name} is pulling ${_NamedNPC}
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["a violent vortex",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			Obj_OgreIH:ChangeCampSpot["${KillSpots[1]}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			Actor["${_NamedNPC}"]:DoTarget
			wait 50
			while ${Me.InCombat}
			{
				; Check to see if CurrentKillSpotNum matches DerussahKillSpotNum
				if !${CurrentKillSpotNum.Equal[${DerussahKillSpotNum}]}
				{
					; Move to new KillSpot
					CurrentKillSpotNum:Set[${DerussahKillSpotNum}]
					Obj_OgreIH:ChangeCampSpot["${KillSpots[${CurrentKillSpotNum}]}"]
				}
				; Wait a second before looping again
				wait 10
			}
			Ob_AutoTarget:Clear
			; Remove Atom for text event
			Event[EQ2_onIncomingChatText]:DetachAtom[DerussahIncomingChatText]
			; Get Chest
			eq2execute summon
			wait 10
			call Obj_OgreIH.Get_Chest
			; Move back to original KillSpot
			call move_to_next_waypoint "${KillSpots[2]}" "5"
			call move_to_next_waypoint "${KillSpots[1]}" "5"
		}
		
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
 	Named 5 *********************    Move to, spawn and kill - Hasira the Hawk ****************************
***********************************************************************************************************/

	function:bool Named5(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[-846.89,53.47,-409.21]
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "5"
		call move_to_next_waypoint "-759.46,54.00,-365.93" "5"
		; Look for shiny
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "-792.81,53.96,-337.17" "5"
			call move_to_next_waypoint "-766.64,54.48,-344.42" "5"
			call move_to_next_waypoint "-743.02,54.22,-339.15" "5"
			call move_to_next_waypoint "-766.64,54.48,-344.42" "5"
			call move_to_next_waypoint "-759.46,54.00,-365.93" "5"
		}
		call move_to_next_waypoint "-771.61,54.27,-397.79" "5"
		; Look for shiny
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "-753.31,53.73,-402.29" "5"
			call move_to_next_waypoint "-771.61,54.27,-397.79" "5"
		}
		; Stop by Shiny
		call move_to_next_waypoint "-789.95,55.01,-409.61" "5"
		call move_to_next_waypoint "-816.71,53.94,-430.27" "5"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Set Loot settings for last boss
		call SetLootForLastBoss
		
		; Setup variables to use during the fight
		variable bool AtKillSpot=TRUE
		variable int MarkerNum=1
		variable point3f MarkerSpot[4]
		MarkerSpot[1]:Set[-809.00,54.83,-411.00]
		MarkerSpot[2]:Set[-797.00,54.83,-411.00]
		MarkerSpot[3]:Set[-797.00,54.84,-399.00]
		MarkerSpot[4]:Set[-809.00,54.83,-399.00]
		variable point3f FighterSpot[4]
		FighterSpot[1]:Set[-822.00,53.98,-422.00]
		FighterSpot[2]:Set[-785.00,54.43,-422.00]
		FighterSpot[3]:Set[-785.00,54.44,-388.00]
		FighterSpot[4]:Set[-822.00,54.11,-388.00]
		variable int ExpectedMarkerNum=1
		; Kill named
		if ${Zone.Name.Equals["${Solo_Zone_Name}"]} || ${Zone.Name.Equals["${Heroic_1_Zone_Name}"]}
		{
			; Kill named
			Ob_AutoTarget:Clear
			Ob_AutoTarget:AddActor["Hasira's Marker",0,FALSE,FALSE]
			Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
			oc ${Me.Name} is pulling ${_NamedNPC}
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			Actor["${_NamedNPC}"]:DoTarget
			wait 50
			while ${Me.InCombat}
			{
				; Wait at KillSpot until a Marker spawns
				if ${AtKillSpot}
				{
					if ${Actor[Query,Name=="Hasira's Marker" && Type != "Corpse"].ID(exists)}
					{
						; Move to MarkerSpot
						Obj_OgreIH:ChangeCampSpot["-823.73,54.20,-425.53"]
						call Obj_OgreUtilities.HandleWaitForCampSpot 10
						Obj_OgreIH:ChangeCampSpot["${MarkerSpot[${MarkerNum}]}"]
						call Obj_OgreUtilities.HandleWaitForCampSpot 10
						; No longer at KillSpot
						AtKillSpot:Set[FALSE]
					}
				}
				; Not at KillSpot, if there is not a marker close, but another marker away, move to next marker position
				elseif !${Actor[Query,Name=="Hasira's Marker" && Type != "Corpse" && Distance <= 8].ID(exists)}
				{
					if ${Actor[Query,Name=="Hasira's Marker" && Type != "Corpse" && Distance > 8].ID(exists)}
					{
						; Increment MarkerNum, or go back to 1
						if ${MarkerNum:Inc} > 4
							MarkerNum:Set[1]
						; Move to Marker
						Obj_OgreIH:ChangeCampSpot["${MarkerSpot[${MarkerNum}]}"]
						call Obj_OgreUtilities.HandleWaitForCampSpot 10
						; Wait a couple of seconds before checking again
						wait 20
					}
				}
				; Wait a second before looping
				wait 10
			}
			Ob_AutoTarget:Clear
		}
		; For H2, when a marker spawns
		; 	can only target it if in close proximity
		; 	named will fly away and lock onto closest target
		; 		if not a fighter, will throw back that character and any other characters around them
		; 		need to keep fighter between named and group, and more than 10m away from group
		; After a marker is destroyed
		; 	everyone gets a curse with various metals (Iron, Copper, Silver, Gold, Platinum)
		; 	fighter casts bulwark to trigger named to say which one to cure
		; 	cure the person that has the type called out to cure all
		elseif ${Zone.Name.Equals["${Heroic_2_Zone_Name}"]}
		{
			; Clear AutoTarget, will selectively target
			Ob_AutoTarget:Clear
			; Disable Assist and Cure Curse
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_assist FALSE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_curecurse TRUE TRUE
			; Run ZoneHelperScript to handle targeting and curing curse
			oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
			oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC}"
			; Kill named
			oc ${Me.Name} is pulling ${_NamedNPC}
			Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			Actor["${_NamedNPC}"]:DoTarget
			wait 50
			while ${Me.InCombat}
			{
				; Wait at KillSpot until a Marker spawns
				if ${AtKillSpot}
				{
					if ${Actor[Query,Name=="Hasira's Marker" && Type != "Corpse"].ID(exists)}
					{
						; Move to MarkerSpot
						Obj_OgreIH:ChangeCampSpot["-823.73,54.20,-425.53"]
						wait 20
						; Split up group and fighter
						oc !ci -ChangeCampSpotWho "igw:${Me.Name}+notfighter" ${MarkerSpot[${MarkerNum}].X} ${MarkerSpot[${MarkerNum}].Y} ${MarkerSpot[${MarkerNum}].Z}
						wait 20
						oc !ci -ChangeCampSpotWho "igw:${Me.Name}+fighter" ${FighterSpot[${MarkerNum}].X} ${FighterSpot[${MarkerNum}].Y} ${FighterSpot[${MarkerNum}].Z}
						; No longer at KillSpot
						AtKillSpot:Set[FALSE]
					}
				}
				; Not at KillSpot, move group as needed based on location of Marker
				else
				{
					; Get location of Marker
					ActorLoc:Set[${Actor[Query,Name=="Hasira's Marker" && Type != "Corpse"].Loc}]
					if ${ActorLoc.X}!=0 || ${ActorLoc.Y}!=0 || ${ActorLoc.Z}!=0
					{
						; Set ExpectedMarkerNum based on Marker coordinates
						if ${ActorLoc.X} > -802
						{
							if ${ActorLoc.Z} > -404
								ExpectedMarkerNum:Set[3]
							else
								ExpectedMarkerNum:Set[2]
						}
						else
						{
							if ${ActorLoc.Z} > -404
								ExpectedMarkerNum:Set[4]
							else
								ExpectedMarkerNum:Set[1]
						}
						; If MarkerNum is not ExpectedMarkerNum, move group to next MarkerNum
						if !${MarkerNum.Equal[${ExpectedMarkerNum}]}
						{
							; Increment MarkerNum, or go back to 1
							if ${MarkerNum:Inc} > 4
								MarkerNum:Set[1]
							; Move to Marker and wait a bit before checking again
							oc !ci -ChangeCampSpotWho "igw:${Me.Name}+fighter" ${FighterSpot[${MarkerNum}].X} ${FighterSpot[${MarkerNum}].Y} ${FighterSpot[${MarkerNum}].Z}
							wait 20
							oc !ci -ChangeCampSpotWho "igw:${Me.Name}+notfighter" ${MarkerSpot[${MarkerNum}].X} ${MarkerSpot[${MarkerNum}].Y} ${MarkerSpot[${MarkerNum}].Z}
							wait 20
						}
					}
					else
					; If no marker, move group together at MarkerSpot
					{
						; Bring everyone together
						oc !ci -ChangeCampSpotWho "igw:${Me.Name}" ${MarkerSpot[${MarkerNum}].X} ${MarkerSpot[${MarkerNum}].Y} ${MarkerSpot[${MarkerNum}].Z}
						; Wait a couple of seconds before checking again
						wait 20
					}
				}
				; Wait a second before looping
				wait 10
			}
			; Re-enable Assist and Cure Curse
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+notfighter checkbox_settings_assist TRUE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_curecurse FALSE TRUE
		}
			
		; Get Chest
		eq2execute summon
		wait 10
		call Obj_OgreIH.Get_Chest
		
		; Move back to KillSpot
		while ${MarkerNum} != 1
		{
			; Increment MarkerNum, or go back to 1
			MarkerNum:Inc
			if ${MarkerNum} > 4
				MarkerNum:Set[1]
			; Move to Marker
			Obj_OgreIH:ChangeCampSpot["${MarkerSpot[${MarkerNum}]}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
		}
		Obj_OgreIH:ChangeCampSpot["-823.73,54.20,-425.53"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		
		; Check named is dead
		if ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_FailedToKill["${_NamedNPC}"]
			return FALSE
		}
		
		; Look for shinies
		if !${Ogre_Instance_Controller.bSkipShinies}
		{
			call move_to_next_waypoint "-823.91,54.19,-424.38"
			call move_to_next_waypoint "-804.54,55.02,-416.78" "5"
			call move_to_next_waypoint "-764.94,53.73,-431.98" "5"
			; May be a shiny at this point on a rock, use special code to handle
			call move_to_next_waypoint "-753.62,53.73,-408.31" "1"
			Obj_OgreIH:ChangeCampSpot["-750.16,55.00,-408.51"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
			call Obj_OgreUtilities.HandleWaitForCombat
			call click_shiny
			call move_to_next_waypoint "-753.62,53.73,-408.31" "1"
			call move_to_next_waypoint "-764.94,53.73,-431.98" "5"
			call move_to_next_waypoint "-766.49,53.63,-478.51" "1"
			call move_to_next_waypoint "-758.18,56.20,-476.04" "5"
			call move_to_next_waypoint "-766.49,53.63,-478.51" "1"
			call move_to_next_waypoint "-764.68,54.32,-458.19" "5"
			call move_to_next_waypoint "-816.62,53.93,-493.49" "5"
			call move_to_next_waypoint "-814.65,53.92,-470.28" "5"
			call move_to_next_waypoint "-764.68,54.32,-458.19" "5"
			call move_to_next_waypoint "-764.94,53.73,-431.98" "5"
			call move_to_next_waypoint "-725.42,58.65,-433.16" "1"
			call move_to_next_waypoint "-722.51,58.67,-439.47" "5"
			call move_to_next_waypoint "-725.42,58.65,-433.16" "1"
			call move_to_next_waypoint "-764.94,53.73,-431.98" "5"
			call move_to_next_waypoint "-804.54,55.02,-416.78" "5"
			call move_to_next_waypoint "-823.91,54.19,-424.38"
			call move_to_next_waypoint "${KillSpot}" "10"
		}
		
		; Finished with named
		return TRUE
	}
}

/***********************************************************************************************************
***********************************************  ATOMS  ****************************************************
************************************************************************************************************/

atom CragnokIncomingChatText(int ChatType, string Message, string Speaker, string TargetName, string SpeakerIsNPC, string ChannelName)
{
	; Look for Massive Swipe being cast
	; Cragnok sets up to swipe away everyone in front of it!
	if ${Speaker.Equal["Cragnok"]} && ${Message.Find["sets up to swipe"]}
		CragnokIncomingSwipe:Set[TRUE]
	
	; Look for a Critical Mass going off
	; Cragnok crumbles into the ground to move to another level
	if ${Speaker.Equal["Cragnok"]} && ${Message.Find["crumbles into the ground"]}
		CragnokIncomingCriticalMass:Set[FALSE]
		
	; Debug text to see messages
	;echo ${ChatType}, ${Message}, ${Speaker}, ${TargetName}, ${SpeakerIsNPC}, ${ChannelName}
}

atom CragnokIncomingText(string Text)
{
	; Look for a Critical Mass going off
	; "You survive Cragnok's Critical Mass!"
	if ${Text.Find["You survive Cragnok's Critical Mass!"]}
		CragnokIncomingCriticalMass:Set[FALSE]
}

atom DerussahIncomingChatText(int ChatType, string Message, string Speaker, string TargetName, string SpeakerIsNPC, string ChannelName)
{
	; Look for second set of adds spawned
	; Derussah the Deceptive says, "The countdown begins anew. This time, with more sand!"
	if ${Speaker.Equal["Derussah the Deceptive"]} && ${Message.Find["The countdown begins anew. This time, with more sand!"]}
		DerussahKillSpotNum:Set[2]
	
	; Look for third set of adds spawned
	; Derussah the Deceptive says, "Time for one last one? I know I am!"
	if ${Speaker.Equal["Derussah the Deceptive"]} && ${Message.Find["Time for one last one? I know I am!"]}
		DerussahKillSpotNum:Set[3]
		
	; Debug text to see messages
	;echo ${ChatType}, ${Message}, ${Speaker}, ${TargetName}, ${SpeakerIsNPC}, ${ChannelName}
}
