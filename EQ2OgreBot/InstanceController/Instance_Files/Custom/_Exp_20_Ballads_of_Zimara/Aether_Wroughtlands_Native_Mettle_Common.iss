; This IC file requires ZoneHelperScript/HOHelperScript/MendRuneSwapHelperScript/IC_Helper files to function
variable string ZoneHelperScript="EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/Aether_Wroughtlands_Native_Mettle_Helper"
variable string HOHelperScript="HO_Helper"
variable string MendRuneSwapHelperScript="EQ2OgreBot/InstanceController/Support_Files_Common/Mend_Rune_Swap_Helper"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"

; Custom variables
variable bool AuromQuickCurseIncoming=FALSE
variable int AurumPhaseNum=1

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
			call This.Named1 "The Aurum Outlaw"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#1: The Aurum Outlaw"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 2
		if ${_StartingPoint} == 2
		{
			call This.Named2 ""
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#2: "]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 3
		if ${_StartingPoint} == 3
		{
			call This.Named3 ""
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#3: "]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 4
		if ${_StartingPoint} == 4
		{
			call This.Named4 ""
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#4: "]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 5
		if ${_StartingPoint} == 5
		{
			call This.Named5 ""
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#5: "]
				return FALSE
			}
			_StartingPoint:Inc
		}
		
		; Zone Out
		if ${_StartingPoint} == 6
		{
			call move_to_next_waypoint "" "1"
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
    Named 1 **********************    Move to, spawn and kill - The Aurum Outlaw   ************************
***********************************************************************************************************/
	
	; Setup Variables needed outside Named1 function
	variable int TimeSinceBanditKill=0
	
	function:bool Named1(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[744.64,208.26,-84.55]
			
		; Setup Variables
		variable int SpotNum=1
		variable point3f BanditSpot[4]
		variable bool MovedToKillSpot=FALSE
		variable int Counter
		
		; Update BanditSpots
		BanditSpot[1]:Set[774.73,207.03,-150.32]
		BanditSpot[2]:Set[727.60,203.93,-179.31]
		BanditSpot[3]:Set[708.94,206.49,-157.21]
		BanditSpot[4]:Set[741.06,202.04,-132.95]
		
		; Update Variable default values
		AuromQuickCurseIncoming:Set[FALSE]
		AurumPhaseNum:Set[1]
		
		; Swap to stifle immunity rune
		call mend_and_rune_swap "stifle" "stifle" "stifle" "stifle"
		
		; Set custom settings for The Aurum Outlaw
		call SetupAurom "TRUE"
		
		; Run HOHelperScript to help complete HO's
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "InZone"
		
		; Run ZoneHelperScript to handle dealing with Bandits and named
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC}"
		
		; Setup and move to named
		call initialize_move_to_next_boss "${_NamedNPC}" "1"
		call move_to_next_waypoint "883.28,203.71,-68.62"
		; Enable PreCastTag to allow priest to setup wards before engaging first mob
		oc !ci -AbilityTag igw:${Me.Name} "PreCastTag" "6" "Allow"
		wait 60
		
		; Kill first 4 bandits closest to zone entrance
		; 	Don't move to bandits because don't want any extra aggro at this point
		; 	also wait a while after 2nd and third bandits because don't want respawns to happen too quickly in a row
		call AurumBanditMove "861.36,202.50,-80.17" "FALSE"
		call AurumBanditMove "838.65,200.09,-100.14" "FALSE"
		if ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
			wait 200
		call AurumBanditMove "831.50,208.57,-127.22" "FALSE"
		if ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
			wait 200
		call AurumBanditMove "804.56,202.35,-99.89" "FALSE"
		
		; Check if already killed
		if !${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Handle text events
		Event[EQ2_onIncomingText]:AttachAtom[TheAurumOutlawIncomingText]
		Event[EQ2_onIncomingChatText]:AttachAtom[TheAurumOutlawIncomingChatText]
	
		; Pull Named
		Ob_AutoTarget:Clear
		oc ${Me.Name} is pulling ${_NamedNPC}
		Obj_OgreIH:ChangeCampSpot["774.73,207.03,-150.32"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		while !${Me.InCombat} || ${Actor[namednpc,"${_NamedNPC}"].Distance} > 10
		{
			oc !ci -PetOff igw:${Me.Name}
			Actor["${_NamedNPC}"]:DoTarget
			wait 30
		}
		; Kill named
		; There are 10 "an aureate bandit" mobs in the area
		; 	Named has "Golden Gang" effect that shows the number of bandits
		; 	If there are 8 or more increments when in combat with the named it is a wipe
		; 	Three of the bandits have "Hat Trick" effect
		; 		They will dps from ranged and cannot be killed
		; 		Dispelling the effect will move it to another bandit
		; 	General strategy is to keep 7 bandits on the south side of the area killed and to not engage with the 3 bandits on the north side
		; As the fight progresses, the named will start to summon æther æraquis
		; 	These are NoKill NPC mobs that roam around the area
		; 	If they collide with you they will knock you back
		; 	If they collide with named he will hop on and ride the æraquis
		; 		This does a lot of initial damage and he is effectively immune to damage until knocked off
		; 		He gets knocked off by a collision with another æraquis
		; 	Want to avoid the whole situation and keep named in a position out of the roaming paths of any æraquis
		oc !ci -PetAssist igw:${Me.Name}
		variable actor Bandit
		variable actor Aeraquis
		variable int TimeSinceFlanking=0
		while ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
		{
			; Make sure named is being targeted
			Actor["${_NamedNPC}"]:DoTarget
			; In phase 1, want to move around killing the bandits after a bit of a delay to space out the kills
			if ${AurumPhaseNum} == 1
			{
				; Check to see if group needs to move
				; 	Don't move if AuromQuickCurseIncoming
				if !${AuromQuickCurseIncoming}
				{
					; Check to see if in combat with a bandit (may get an additional bandit aggroed during AurumBanditMove)
					Bandit:Set[${Actor[Query,Name=="an aureate bandit" && Type != "Corpse" && Distance <= 50 && Target.ID > 0].ID}]
					if ${Bandit.ID(exists)}
					{
						; Move to kill bandit
						call AurumBanditMove "${Bandit.Loc}" "TRUE"
						; Wait in case AuromQuickCurseIncoming
						while ${AuromQuickCurseIncoming}
						{
							; Wait a second before looping
							wait 10
							; Increment TimeSinceBanditKill
							TimeSinceBanditKill:Inc
						}
						; Move back to previous BanditSpot
						call AurumBanditMove "${BanditSpot[${SpotNum}]}" "TRUE"
					}
					; If it has been at least 30 seconds since the last bandit was killed, move to next BanditSpot
					if ${TimeSinceBanditKill} >= 30
					{
						; Move to next BanditSpot
						if ${SpotNum:Inc} <= ${BanditSpot.Size}
							call AurumBanditMove "${BanditSpot[${SpotNum}]}" "TRUE"
						; If completed all BanditSpots, move to second phase early
						else
							AurumPhaseNum:Set[2]
					}
				}
				; Send scouts to flanking position every few seconds as long as named is nearby
				if ${TimeSinceFlanking:Inc} > 3
				{
					if ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse" && Distance <= 10].ID(exists)}
					{
						call MoveInRelationToNamed "igw:${Me.Name}+scout" "${_NamedNPC}" "3" "-90"
						TimeSinceFlanking:Set[0]
					}
				}
			}
			; In phase 2, move the group to a spot that will hopefully be out of the path of the roaming æther æraquis
			; 	Helper script will send out a character to pull bandits that respawn back to the group
			else
			{
				; Move to KillSpot if needed
				if !${MovedToKillSpot}
				{
					; Move to KillSpot
					Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
					call Obj_OgreUtilities.HandleWaitForCampSpot 10
					; Wait a bit to arrive at KillSpot
					wait 100
					; Set MovedToKillSpot to TRUE
					MovedToKillSpot:Set[TRUE]
				}
				else
				{
					; Check to see if in combat with a bandit (may have a respawned bandit pulled back to group)
					Bandit:Set[${Actor[Query,Name=="an aureate bandit" && Type != "Corpse" && Distance <= 30 && Target.ID > 0].ID}]
					; Kill bandit if found
					if ${Bandit.ID(exists)}
						call AurumBanditMove "${KillSpot}" "FALSE"
					; Otherwise, pull bandits that respawn
					else
						call PullBanditRespawns "${KillSpot}"
					; Check to see if named needs to be re-positioned (want named as close to KillSpot as possible to avoid roaming æther æraquis)
					ActorLoc:Set[${Actor["${_NamedNPC}"].Loc}]
					if ${ActorLoc.X}!=0 || ${ActorLoc.Y}!=0 || ${ActorLoc.Z}!=0
					{
						; Check to see if named is out of position
						if ${ActorLoc.X} > 749 || ${ActorLoc.Z} < -89 || ${ActorLoc.Z} > -75
						{
							; Move away from KillSpot
							Obj_OgreIH:ChangeCampSpot["730.62,207.47,-103.68"]
							call Obj_OgreUtilities.HandleWaitForCampSpot 10
							wait 50
							; Move back to KillSpot
							Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
							call Obj_OgreUtilities.HandleWaitForCampSpot 10
							Counter:Set[0]
							while (${Actor["${_NamedNPC}"].Loc.X} > 749 || ${Actor["${_NamedNPC}"].Loc.Z} < -89 || ${Actor["${_NamedNPC}"].Loc.Z} > -75) && ${Counter:Inc} <= 18
							{
								wait 5
							}
							wait 10
						}
					}
				}
			}
			; Wait a second before looping
			wait 10
			; Increment TimeSinceBanditKill
			TimeSinceBanditKill:Inc
		}
		
		; Detach Atoms
		Event[EQ2_onIncomingText]:DetachAtom[TheAurumOutlawIncomingText]
		Event[EQ2_onIncomingChatText]:DetachAtom[TheAurumOutlawIncomingChatText]
	
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
		
		; Send all characters back to KillSpot after fight
		call move_to_next_waypoint "${KillSpot}" "1"
		
		; Finished with named
		return TRUE
	}

	function SetupAurom(bool EnableAurom)
	{
		; Setup Cures
		variable bool SetDisable
		SetDisable:Set[!${EnableAurom}]
		call SetupAurumCures "${SetDisable}"
		; Set HO settings
		call SetupAurumHO "${EnableAurom}"
		; Setup class-specific HO abilities
		call SetupAurumClassHOAbilities "${SetDisable}"
		; Set Bulwark
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_settings_disable_bulwark_of_order ${EnableAurom} TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_settings_disable_bulwark_of_order_defensives ${EnableAurom} TRUE
	}

	function SetupAurumCures(bool EnableCures)
	{
		; Set Cast Stack Cure and Cure Curse
		variable bool SetDisable
		SetDisable:Set[!${EnableCures}]
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_cure ${SetDisable} TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack_curecurse ${SetDisable} TRUE
		; Setup class-specific abilities with cures attached
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Crusader's Judgement" ${EnableCures} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Zealous Smite" ${EnableCures} TRUE
		wait 1
	}

	function SetupAurumHO(bool EnableAurom)
	{
		if ${EnableAurom}
		{
			; Set HO Start on Mage only
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+mage checkbox_settings_ho_start TRUE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-mage checkbox_settings_ho_start FALSE TRUE
			; Set HO Starter on Scout/Mage only
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+scout|mage checkbox_settings_ho_starter TRUE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-scout+-mage checkbox_settings_ho_starter FALSE TRUE
			; Set HO Wheel on everyone
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_ho_wheel TRUE TRUE
			; Set Offensive Only to make sure HO's complete in a way that triggers the effect
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_ho_wheel_offensive_only TRUE TRUE
			; Disable fighter horn/boot and priest chalice/hammer HO icon abilities
			; 	This is to make sure HO's follow the path that will get them completed the quickest
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_settings_disable_fighter_hoicon_2 TRUE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_settings_disable_fighter_hoicon_4 TRUE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+priest checkbox_settings_disable_priest_hoicon_12 TRUE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+priest checkbox_settings_disable_priest_hoicon_14 TRUE TRUE
		}
		else
			call SetInitialHOSettings
	}

	function SetupAurumClassHOAbilities(bool EnableAbilities)
	{
		; Disable class-specific fighter horn/boot and priest chalice/hammer abilities
		; 	This is to make sure they aren't already in the process of being cast when an HO is started
		; 	Wwant HO's to use specific starter paths to best ensure quick completion
		; 	Modify as needed for other classes
		; Shadowknight horn
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Insidious Whisper" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Intercept" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Blasphemy" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Rescue" ${EnableAbilities} TRUE
		; Berserker horn
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+berserker "Intercept" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+berserker "Mock" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+berserker "Aggressive Defense" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+berserker "Enrage" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+berserker "Master's Rage" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+berserker "Rescue" ${EnableAbilities} TRUE
		; Shadowknight boot
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Soulrend" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Crusader's Judgement" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Doom Judgment" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Shadowy Elusion" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Earthshock" ${EnableAbilities} TRUE
		; Berserker boot
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+berserker "Knee Break" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+berserker "Earthshock" ${EnableAbilities} TRUE
		; Mystic chalice
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Ritual Healing" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Rejuvenation" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Echoes of the Ancients" ${EnableAbilities} TRUE
		; Fury chalice
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fury "Nature's Salve" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fury "Nature's Elixir" ${EnableAbilities} TRUE
		; Mystic hammer
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Wrath of the Ancients" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Plague" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Glacial Flames" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Velium Winds" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Polar Fire" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Spirits" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Wrath" ${EnableAbilities} TRUE
		; Fury hammer
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fury "Death Swarm" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fury "Brambles" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fury "Ball Lightning" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fury "Starnova" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fury "Master's Smite" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fury "Tempest" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fury "Thunderbolt" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fury "Wrath" ${EnableAbilities} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+fury "Raging Whirlwind" ${EnableAbilities} TRUE
		wait 1
	}

	function AurumBanditMove(point3f MoveSpot, bool MoveToBandit)
	{
		; Move to MoveSpot
		oc !ci -resume igw:${Me.Name}
		oc !ci -letsgo igw:${Me.Name}
		oc !ci -PetOff igw:${Me.Name}
		Obj_OgreIH:SetCampSpot
		Obj_OgreIH:ChangeCampSpot["${MoveSpot}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		; Look for closest bandit (up to 30m away)
		variable int BanditDistance=0
		variable actor Bandit
		while ${Bandit.ID} == 0 && ${BanditDistance:Inc[5]} <= 30
		{
			Bandit:Set[${Actor[Query,Name=="an aureate bandit" && Type != "Corpse" && Distance <= ${BanditDistance}].ID}]
		}
		; Kill Bandit
		if ${Bandit.ID(exists)}
		{
			; Get initial Bandit location
			variable point3f BanditInitialLoc
			BanditInitialLoc:Set[${Bandit.Loc}]
			; If MoveToBandit, move characters to Bandit putting fighter in front and rest flanking
			if ${MoveToBandit}
			{
				call MoveInRelationToActorID "igw:${Me.Name}+fighter" "${Bandit.ID}" "3" "0"
				call MoveInRelationToActorID "igw:${Me.Name}+notfighter" "${Bandit.ID}" "3" "-90"
				wait 20
			}
			; Target Bandit and send in pets
			Bandit:DoTarget
			oc !ci -PetAssist igw:${Me.Name}
			wait 30
			; Kill Bandit, re-adjusting position of the scouts as needed to stay at flank
			variable point3f BanditNewLoc
			variable float BanditLocDistanceChange
			while ${Bandit.ID(exists)}
			{
				; If MoveToBandit, re-adjust position if needed (as long as Bandit within 10m of BanditInitialLoc)
				if ${MoveToBandit}
				{
					BanditNewLoc:Set[${Bandit.Loc}]
					BanditLocDistanceChange:Set[${Math.Distance[${BanditInitialLoc.X},${BanditInitialLoc.Z},${BanditNewLoc.X},${BanditNewLoc.Z}]}]
					if ${BanditLocDistanceChange} <= 10
						call MoveInRelationToActorID "igw:${Me.Name}+scout" "${Bandit.ID}" "3" "-90"
				}
				; Wait a few seconds before checking again
				wait 30
			}
			; Update TimeSinceBanditKill
			TimeSinceBanditKill:Set[0]
		}
		; If in combat with an æther æraquis, kill it
		variable actor Aeraquis
		Aeraquis:Set[${Actor[Query,Name=="an æther æraquis" && Type != "Corpse" && Distance <= 30 && Target.ID > 0].ID}]
		if ${Aeraquis.ID(exists)}
		{
			; Target Aeraquis and send in pets
			Aeraquis:DoTarget
			oc !ci -PetAssist igw:${Me.Name}
			wait 30
			TimeSinceBanditKill:Inc[3]
			; Kill Aeraquis
			while ${Aeraquis.ID(exists)}
			{
				wait 10
				TimeSinceBanditKill:Inc
			}
		}
		
	}
	
	function PullBanditRespawns(point3f KillSpot)
	{
		; Setup variables
		variable index:actor Bandits
		variable iterator BanditIterator
		variable point3f BanditLoc
		variable int BanditCount=0
		variable point3f BanditRespawnPullSpot="758.51,207.65,-114.01"
		variable point3f TravelSpots[6]
		variable point3f HealPullSpot="753.89,205.49,-104.52"
		variable int Counter
		variable float Slope
		variable float Intercept
		variable float NewX
		variable float NewZ
		variable index:actor Aeraquis
		variable iterator AeraquisIterator
		variable point3f AeraquisLoc
		variable float AeraquisHeading
		variable int NumSteps
		variable bool CollisionFound=FALSE
		variable actor ClosestBandit
		variable actor ClosestSafeBandit
		variable actor PullBandit
		variable int GroupNum
		variable string GroupCharacter
		
		; Search for any bandits that have respawned and are not in combat
		; 	Skip the first bandit by zone in and the 3 bandits at the north side
		EQ2:QueryActors[Bandits, Name=="an aureate bandit" && Type != "Corpse" && Distance <= 120 && X < 850 && (Z > -153 || X < 760) && Target.ID == 0]
		Bandits:GetIterator[BanditIterator]
		if ${BanditIterator:First(exists)}
		{
			; Search for all NoKill æther æraquis
			EQ2:QueryActors[Aeraquis, Name=="an æther æraquis" && Type != "Corpse" && Type == "NoKill NPC" && Distance <= 200]
			Aeraquis:GetIterator[AeraquisIterator]
			; Loop through bandits
			do
			{
			   ; Get bandit Location, make sure it is valid
				BanditLoc:Set[${BanditIterator.Value.Loc}]
				if ${BanditLoc.X}==0 && ${BanditLoc.Y}==0 && ${BanditLoc.Z}==0
					continue
				; Increment BanditCount
				BanditCount:Inc
				; Setup list of points between BanditRespawnPullSpot and Bandit
				Slope:Set[(${BanditLoc.Z}-${BanditRespawnPullSpot.Z})/(${BanditLoc.X}-${BanditRespawnPullSpot.X})]
				Intercept:Set[${BanditRespawnPullSpot.Z}-${Slope}*${BanditRespawnPullSpot.X}]
				Counter:Set[0]
				while ${Counter:Inc} <= ${TravelSpots.Size}
				{
					NewX:Set[${BanditRespawnPullSpot.X}+(${BanditLoc.X}-${BanditRespawnPullSpot.X})*((${Counter}-1)/(${TravelSpots.Size}-1))]
					NewZ:Set[${Slope}*${NewX}+${Intercept}]
					TravelSpots[${Counter}]:Set[${NewX},${BanditRespawnPullSpot.Y},${NewZ}]
				}
				; Default to no CollisionFound
				CollisionFound:Set[FALSE]
				; Loop through æraquis
				if ${AeraquisIterator:First(exists)}
				{
					do
					{
					   ; Get æraquis Location and Heading, make sure they are valid
						AeraquisLoc:Set[${AeraquisIterator.Value.Loc}]
						AeraquisHeading:Set[${AeraquisIterator.Value.Heading}]
						if ${AeraquisLoc.X}==0 && ${AeraquisLoc.Y}==0 && ${AeraquisLoc.Z}==0
							continue
						; See if æraquis is on a collision path with KillSpot or any TravelSpot
						NumSteps:Set[-1]
						while ${NumSteps:Inc} <= 10
						{
							; Calculate future Location of æraquis moving 5m * NumSteps
							NewLoc:Set[${AeraquisLoc.X},${AeraquisLoc.Y},${AeraquisLoc.Z}]
							NewLoc.X:Dec[5*${NumSteps}*${Math.Sin[${AeraquisHeading}]}]
							NewLoc.Z:Dec[5*${NumSteps}*${Math.Cos[${AeraquisHeading}]}]
							; Check to see if Distance is within 10m of KillSpot
							if ${Math.Distance[${KillSpot.X},${KillSpot.Z},${NewLoc.X},${NewLoc.Z}]} < 10
								CollisionFound:Set[TRUE]
							; Check to see if Distance is within 10m of a TravelSpot
							Counter:Set[0]
							while ${Counter:Inc} <= ${TravelSpots.Size}
							{
								if ${Math.Distance[${TravelSpots[${Counter}].X},${TravelSpots[${Counter}].Z},${NewLoc.X},${NewLoc.Z}]} < 10
									CollisionFound:Set[TRUE]
							}
							; Stop search if CollisionFound
							if ${CollisionFound}
								break
						}
						; Stop search if CollisionFound
						if ${CollisionFound}
							break
					}
					while ${AeraquisIterator:Next(exists)}
				}
				; Update ClosestBandit if not set or bandit is closer
				if ${ClosestBandit.ID} == 0 || ${BanditIterator.Value.Distance} < ${ClosestBandit.Distance}
					ClosestBandit:Set[${BanditIterator.Value.ID}]
				; Update ClosestSafeBandit if no CollisionFound and not set or bandit is closer
				if !${CollisionFound} && (${ClosestSafeBandit.ID} == 0 || ${BanditIterator.Value.Distance} < ${ClosestSafeBandit.Distance})
					ClosestSafeBandit:Set[${BanditIterator.Value.ID}]
			}
			while ${BanditIterator:Next(exists)}
		}
		; Set PullBandit as ClosestSafeBandit if found
		if ${ClosestSafeBandit.ID} != 0
			PullBandit:Set[${ClosestSafeBandit.ID}]
		; Otherwise set as ClosestBandit if there are multiple bandits
		elseif ${ClosestBandit.ID} != 0 && ${BanditCount} > 1
			PullBandit:Set[${ClosestBandit.ID}]
		; Exit if no bandit to pull
		if ${PullBandit.ID} == 0
			return
		
		; Look for a character to pull the bandit
		; 	Setup to pull using a bard or rogue, modify as needed based on group makeup
		GroupNum:Set[0]
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			if ${Me.Group[${GroupNum}].Class.Equal[dirge]} || ${Me.Group[${GroupNum}].Class.Equal[troubador]} || ${Me.Group[${GroupNum}].Class.Equal[swashbuckler]} || ${Me.Group[${GroupNum}].Class.Equal[brigand]}
				GroupCharacter:Set[${Me.Group[${GroupNum}].Name}]
		}
		; Make sure a GroupCharacter was found
		if ${GroupCharacter.Length} == 0
			return
		; Set PullBanditCharacter variable
		oc !ci -Set_Variable igw:${Me.Name} "PullBanditCharacter" "${GroupCharacter}"
		; Have GroupCharacter cast Sprint so they can move quickly (may get out of range of group speed buffs if not a bard)
		oc !ci -CastAbility ${GroupCharacter} "Sprint"
		; Send GroupCharacter to bandit PullSpot and priests to HealPullSpot
		; 	Send priests out a bit to extend heal range in case GroupCharacter needs heals while out
		oc !ci -ChangeCampSpotWho ${GroupCharacter} ${BanditRespawnPullSpot.X} ${BanditRespawnPullSpot.Y} ${BanditRespawnPullSpot.Z}
		oc !ci -ChangeCampSpotWho igw:${Me.Name}+priest ${HealPullSpot.X} ${HealPullSpot.Y} ${HealPullSpot.Z}
		Counter:Set[0]
		while ${Math.Distance[${Me.Group[${GroupCharacter}].Loc.X},${Me.Group[${GroupCharacter}].Loc.Z},${BanditRespawnPullSpot.X},${BanditRespawnPullSpot.Z}]} > 5 && ${Counter:Inc} <= 6
		{
			wait 5
		}
		; Send GroupCharacter to bandit to pull it
		oc !ci -ChangeCampSpotWho ${GroupCharacter} ${PullBandit.Loc.X} ${PullBandit.Loc.Y} ${PullBandit.Loc.Z}
		; Wait for Bandit to be aggroed (wait up to 20 seconds)
		Counter:Set[0]
		while ${PullBandit.ID(exists)} && ${PullBandit.Target.ID} == 0 && ${Counter:Inc} <= 40
		{
			wait 5
		}
		; Bring GroupCharacter back to BanditRespawnPullSpot
		oc !ci -ChangeCampSpotWho ${GroupCharacter} ${BanditRespawnPullSpot.X} ${BanditRespawnPullSpot.Y} ${BanditRespawnPullSpot.Z}
		Counter:Set[0]
		while ${Math.Distance[${Me.Group[${GroupCharacter}].Loc.X},${Me.Group[${GroupCharacter}].Loc.Z},${BanditRespawnPullSpot.X},${BanditRespawnPullSpot.Z}]} > 5 && ${Counter:Inc} <= 16
		{
			wait 5
		}
		; Bring Character, priests, and bandit back (wait up to 20 seconds)
		oc !ci -ChangeCampSpotWho igw:${Me.Name}+${GroupCharacter}|priest ${KillSpot.X} ${KillSpot.Y} ${KillSpot.Z}
		Counter:Set[0]
		while ${PullBandit.ID(exists)} && ${PullBandit.Distance} > 30 && ${Counter:Inc} <= 40
		{
			wait 5
		}
		; Cancel Sprint on GroupCharacter
		oc !c -CancelMaintainedForWho ${GroupCharacter} "Sprint"
		; Clear PullBanditCharacter variable
		oc !c -Set_Variable igw:${Me.Name} "PullBanditCharacter" "None"
	}

/**********************************************************************************************************
 	Named 2 ********************    Move to, spawn and kill - ???  ****************************
***********************************************************************************************************/

	function:bool Named2(string _NamedNPC="Doesnotexist")
	{
		; Undo The Aurum Outlaw custom settings
		call SetupAurom "FALSE"
		
		; End ZoneHelperScript
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
		
		
		return FALSE
	}

/**********************************************************************************************************
 	Named 3 *********************    Move to, spawn and kill - ??? **********************************
***********************************************************************************************************/

	function:bool Named3(string _NamedNPC="Doesnotexist")
	{
		return FALSE
	}

/**********************************************************************************************************
 	Named 4 *********************    Move to, spawn and kill - ??? *************************************
***********************************************************************************************************/

	function:bool Named4(string _NamedNPC="Doesnotexist")
	{
		return FALSE
	}

/**********************************************************************************************************
 	Named 5 *********************    Move to, spawn and kill - ??? ***********************
***********************************************************************************************************/

	function:bool Named5(string _NamedNPC="Doesnotexist")
	{
		return FALSE
	}
}

/***********************************************************************************************************
***********************************************  ATOMS  ****************************************************
************************************************************************************************************/

atom TheAurumOutlawIncomingText(string Text)
{
	; Look for message that Quick Curse has been cured
	if ${Text.Find["Successfully curing Quick Curse also removes the curse, Not Quick Enough, from those afflicted!"]}
		AuromQuickCurseIncoming:Set[FALSE]
}

atom TheAurumOutlawIncomingChatText(int ChatType, string Message, string Speaker, string TargetName, string SpeakerIsNPC, string ChannelName)
{
	; Look for message that a Quick Curse is incoming
	if ${Message.Find["Let's see how quick you are!"]}
		AuromQuickCurseIncoming:Set[TRUE]
	
	; Look for message that æther æraquis are being summoned
	; 	Will move to Phase 2 of fight
	if ${Message.Find["To me, aether aeraquis!"]}
		if ${AurumPhaseNum} == 1
			AurumPhaseNum:Set[2]
	
	; Debug text to see messages
	;echo ${ChatType}, ${Message}, ${Speaker}, ${TargetName}, ${SpeakerIsNPC}, ${ChannelName}
}
