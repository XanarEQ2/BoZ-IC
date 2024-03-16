; This IC file requires ZoneHelperScript/HOHelperScript/MendRuneSwapHelperScript/IC_Helper files to function
variable string ZoneHelperScript="EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/Aether_Wroughtlands_Native_Mettle_Helper"
variable string HOHelperScript="HO_Helper"
variable string MendRuneSwapHelperScript="EQ2OgreBot/InstanceController/Support_Files_Common/Mend_Rune_Swap_Helper"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"

; Custom variables for The Aurum Outlaw
variable bool AuromQuickCurseIncoming=FALSE
variable int AurumPhaseNum=1
; Custom variables for Nugget
variable bool ClustersSpawned=FALSE
variable int AdditionalClusters=0
variable bool StupendousSweepIncoming=FALSE
variable bool NuggetStupendousSlamIncoming=FALSE
variable bool NuggetAbsorbAndCrushArmorIncoming=FALSE

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
			call This.Named2 "Nugget"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#2: Nugget"]
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
		
		; Setup for named
		call initialize_move_to_next_boss "${_NamedNPC}" "1"
		
		; Set custom settings for The Aurum Outlaw
		call SetupAurom "TRUE"
		
		; Run HOHelperScript to help complete HO's
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "InZone"
		
		; Run ZoneHelperScript to handle dealing with Bandits and named
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC}"
		
		; Move to named
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
		call SetupAllCures "${SetDisable}"
		; Set HO settings
		call SetupAurumHO "${EnableAurom}"
		; Setup class-specific HO abilities
		call SetupAurumClassHOAbilities "${SetDisable}"
		; Set Bulwark
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_settings_disable_bulwark_of_order ${EnableAurom} TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_settings_disable_bulwark_of_order_defensives ${EnableAurom} TRUE
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
		oc !ci -CancelMaintainedForWho ${GroupCharacter} "Sprint"
		; Clear PullBanditCharacter variable
		oc !ci -Set_Variable igw:${Me.Name} "PullBanditCharacter" "None"
	}

/**********************************************************************************************************
 	Named 2 ********************    Move to, spawn and kill - Nugget  *************************************
***********************************************************************************************************/

	; Setup Variables needed outside Named2 function
	variable bool NuggetExists
	variable string GroupMembers[6]
	variable point3f OreSpot[25]
	variable int OreNum
	variable int TargetAurumCount[5]
	variable point3f UnearthedSpot[8]
	
	function:bool Named2(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot (if changing, make sure to change in Helper code as well)
		KillSpot:Set[752.10,200.11,156.93]
		
		; Undo The Aurum Outlaw custom settings
		call SetupAurom "FALSE"
		
		; Setup Variables
		variable int GroupNum
		variable int Counter
		variable point3f NuggetLoc
		variable point3f TreeSpot[5]
		variable string CharacterTree[5]
		variable int NuggetCheckCount
		variable float FighterNamedOffset
		
		; Get GroupMembers
		GroupNum:Set[0]
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			GroupMembers[${GroupNum}]:Set["${Me.Group[${GroupNum}].Name}"]
		}
		GroupMembers[6]:Set["${Me.Name}"]
	
		; Update TreeSpots
		TreeSpot[1]:Set[721.81,201.65,191.29]
		TreeSpot[2]:Set[777.72,203.99,162.75]
		TreeSpot[3]:Set[797.06,203.15,161.76]
		TreeSpot[4]:Set[737.85,204.26,90.90]
		TreeSpot[5]:Set[690.42,199.91,136.58]
		
		; Assign characters to trees
		; 	Assume this character is a fighter and doesn't need a tree
		; 	Start with priests to keep them close to center
		Counter:Set[0]
		GroupNum:Set[0]
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			call GetArchetypeFromClass "${Me.Group[${GroupNum}].Class}"
			if ${Return.Equal["priest"]}
				CharacterTree[${Counter:Inc}]:Set["${Me.Group[${GroupNum}].Name}"]
		}
		GroupNum:Set[0]
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			call GetArchetypeFromClass "${Me.Group[${GroupNum}].Class}"
			if !${Return.Equal["priest"]} && !${Return.Equal["fighter"]}
				CharacterTree[${Counter:Inc}]:Set["${Me.Group[${GroupNum}].Name}"]
		}
		
		; Assign Target Aurum Count
		; 	This character will have a count of 1
		; 	Then set as 2 3 4 6 9 (25 total aurum clusters exist, assume a full group of 6 characters)
		Counter:Set[2]
		GroupNum:Set[0]
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			call GetArchetypeFromClass "${Me.Group[${GroupNum}].Class}"
			if ${Return.Equal["priest"]}
			{
				TargetAurumCount[${GroupNum}]:Set[${Counter}]
				if ${Counter:Inc} == 5
					Counter:Inc
				elseif ${Counter} == 7
					Counter:Inc[2]
			}
		}
		GroupNum:Set[0]
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			call GetArchetypeFromClass "${Me.Group[${GroupNum}].Class}"
			if !${Return.Equal["priest"]}
			{
				TargetAurumCount[${GroupNum}]:Set[${Counter}]
				if ${Counter:Inc} == 5
					Counter:Inc
				elseif ${Counter} == 7
					Counter:Inc[2]
			}
		}
		; Set TargetAurumCount variable value for each group member
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}TargetAurumCount" "1"
		GroupNum:Set[0]
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			oc !ci -Set_Variable igw:${Me.Name} "${Me.Group[${GroupNum}].Name}TargetAurumCount" "${TargetAurumCount[${GroupNum}]}"
		}
		wait 1
		
		; Update OreSpots
		OreSpot[1]:Set[730.52,218.29,-5.34]
		OreSpot[2]:Set[726.07,215.54,40.51]
		OreSpot[3]:Set[731.57,205.00,84.24]
		OreSpot[4]:Set[726.74,200.35,116.97]
		OreSpot[5]:Set[741.46,200.14,115.16]
		OreSpot[6]:Set[746.32,200.08,141.34]
		OreSpot[7]:Set[758.23,200.41,135.69]
		OreSpot[8]:Set[785.39,203.66,165.01]
		OreSpot[9]:Set[794.40,203.59,156.01]
		OreSpot[10]:Set[769.92,205.42,200.81]
		OreSpot[11]:Set[769.60,209.89,211.55]
		OreSpot[12]:Set[750.81,208.95,207.50]
		OreSpot[13]:Set[728.09,200.06,183.93]
		OreSpot[14]:Set[735.41,200.94,168.37]
		OreSpot[15]:Set[737.78,200.43,152.51]
		OreSpot[16]:Set[729.88,201.31,152.77]
		OreSpot[17]:Set[710.29,202.13,149.11]
		OreSpot[18]:Set[680.57,200.19,152.08]
		OreSpot[19]:Set[693.47,199.95,139.30]
		OreSpot[20]:Set[707.18,202.67,95.88]
		OreSpot[21]:Set[707.71,205.69,76.67]
		OreSpot[22]:Set[685.31,201.95,81.48]
		OreSpot[23]:Set[694.82,202.58,88.46]
		OreSpot[24]:Set[680.09,208.35,52.73]
		OreSpot[25]:Set[680.91,214.70,5.60]
		
		; Update UnearthedSpots
		UnearthedSpot[1]:Set[${KillSpot}]
		UnearthedSpot[2]:Set[751.50,200.10,176.17]
		UnearthedSpot[3]:Set[724.49,200.07,174.85]
		UnearthedSpot[4]:Set[690.77,200.43,155.08]
		UnearthedSpot[5]:Set[701.66,199.38,122.64]
		UnearthedSpot[6]:Set[686.26,200.91,88.73]
		UnearthedSpot[7]:Set[706.82,205.32,65.62]
		UnearthedSpot[8]:Set[737.48,200.59,108.64]
		
		; Setup for named
		call initialize_move_to_next_boss "${_NamedNPC}" "2"
		
		; Set custom settings for Nugget
		call SetupNugget "TRUE"
		
		; Run HOHelperScript to help complete HO's
		; 	In this fight don't actually need it to help complete HO's, but it does disable Ascension abilities
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "InZone"
		
		; Run ZoneHelperScript to handle dealing with named
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC}"
		
		; Move to named
		call move_to_next_waypoint "762.34,214.57,-64.10"
		call move_to_next_waypoint "730.52,218.29,-5.34"
		
		; Check if already killed
		call CheckNuggetExists
		if !${NuggetExists}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "707.13,213.49,28.45"
			call move_to_next_waypoint "728.60,204.25,91.12"
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Mine ore as long as aurum clusters exist or OreNum is not 1
		OreNum:Set[1]
		while ${Actor[Query, Name == "aurum cluster"].ID(exists)} || ${OreNum} != 1
		{
			call MineOreSpot
			; Wait a second before looping
			wait 10
		}
		
		; Handle text events
		Event[EQ2_onIncomingText]:AttachAtom[NuggetIncomingText]
		Event[EQ2_onIncomingChatText]:AttachAtom[NuggetIncomingChatText]
		Event[EQ2_onAnnouncement]:AttachAtom[NuggetAnnouncement]
		
		; Wait until Nugget not within 40m of path to KillSpot
		; 	Don't want to aggro early and have a hard time curing Flecks from all characters before handling additional scripts
		variable bool ReadyForPull=FALSE
		while !${ReadyForPull}
		{
			; Get Location of Nugget
			NuggetLoc:Set[${Actor[Query,Name=="Nugget" && Type != "Corpse"].Loc}]
			if ${NuggetLoc.X}!=0 || ${NuggetLoc.Y}!=0 || ${NuggetLoc.Z}!=0
			{
				if ${Math.Distance[${NuggetLoc.X},${NuggetLoc.Z},707.13,28.45]} > 40
					if ${Math.Distance[${NuggetLoc.X},${NuggetLoc.Z},728.60,91.12]} > 40
						if ${Math.Distance[${NuggetLoc.X},${NuggetLoc.Z},${KillSpot.X},${KillSpot.Z}]} > 40
							ReadyForPull:Set[TRUE]
			}
		}
		
		; Enable PreCastTag to allow priest to setup wards before engaging Named
		oc !ci -AbilityTag igw:${Me.Name} "PreCastTag" "6" "Allow"
		wait 60
		
		; Pull Named
		Ob_AutoTarget:Clear
		Ob_AutoTarget:AddActor["a gleaming goldslug",0,FALSE,FALSE]
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		oc ${Me.Name} is pulling ${_NamedNPC}
		Obj_OgreIH:ChangeCampSpot["707.13,213.49,28.45"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		Obj_OgreIH:ChangeCampSpot["728.60,204.25,91.12"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		while ${NuggetExists} && !${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse" && Distance <= 10].ID(exists)}
		{
			Actor["${_NamedNPC}"]:DoTarget
			oc !ci -PetOff igw:${Me.Name}
			wait 30
			; Update NuggetExists
			call CheckNuggetExists
		}
		; Kill named
		oc !ci -PetAssist igw:${Me.Name}
		NuggetCheckCount:Set[0]
		while ${NuggetExists}
		{
			; Handle Absorb and Crush Armor
			; 	Nugget begins to absorb your armor, and will soon crush them unless interrupted somehow!
			; 	Named will cast an ability that disarms armor on non-fighters and needs to be interrupted
			; 	If not interrupted, will destroy some of your ore and disarmed armor, and likely wipe the group
			; 	Have fighter complete an HO to interrupt it
			; 		The reason specifically calling out abilities here is because the window to complete the HO can
			; 		be very tight at the end and the default method of doing HO's just wasn't reliably quick enough
			if ${NuggetAbsorbAndCrushArmorIncoming}
			{
				; Pause Ogre
				oc !ci -Pause igw:${Me.Name}
				wait 1
				; Clear ability queue
				relay ${OgreRelayGroup} eq2execute clearabilityqueue
				wait 1
				; Cancel anything currently being cast
				oc !ci -CancelCasting igw:${Me.Name}
				wait 5
				; Cast Fighting Chance to bring up HO window
				oc !ci -CastAbility igw:${Me.Name}+fighter "Fighting Chance"
				wait 1
				; Wait for HO window to pop up (up to 2 seconds)
				Counter:Set[0]
				while ${EQ2.HOWindowState} != 2 && ${Counter:Inc} <= 20
				{
					wait 1
				}
				; Cast Ability to start HO
				oc !ci -CastAbility igw:${Me.Name}+shadowknight "Siphon Strike"
				oc !ci -CastAbility igw:${Me.Name}+berserker "Rupture"
				wait 8
				; Cast Ability to complete HO
				oc !ci -CastAbility igw:${Me.Name}+shadowknight "Hateful Slam"
				oc !ci -CastAbility igw:${Me.Name}+berserker "Body Check"
				wait 8
				; Resume Ogre
				oc !ci -Resume igw:${Me.Name}
				; Wait for Absorb and Crush Armor to be cast (up to 10 seconds)
				Counter:Set[0]
				while ${NuggetAbsorbAndCrushArmorIncoming} && ${Counter:Inc} <= 100
				{
					wait 1
				}
				; Set Absorb and Crush Armor as handled
				NuggetAbsorbAndCrushArmorIncoming:Set[FALSE]
			}
			; Handle Stupendous Slam (ID: 1177407465, Time = 3 sec)
			; 	Get message "Quick! Hold onto something! But not the same thing as anyone else!"
			; 	Named will cast a very large knockback that will most likely wipe the group
			; 	To avoid, have characters move to a tree and "Hold on!" giving them a temporary detrimental that roots them and prevents the knockback
			;		Holding on tight (MainIconID: 187, BackDropIconID 187)
			; 	Fighter will get message "As a fighter, you shrug off the attempted knock up.", so they don't need to move for this
			if ${NuggetStupendousSlamIncoming}
			{
				; Send characters with the longest travel time out as soon as they don't need Flecks cured
				; 	Want to do this before sending people out to trees as they can die if they still have the detrimental
				while ${OgreBotAPI.Get_Variable["${CharacterTree[4]}NeedsFlecksCure"].Equal["TRUE"]}
				{
					wait 1
				}
				oc !ci -ChangeCampSpotWho ${CharacterTree[4]} ${TreeSpot[4].X} ${TreeSpot[4].Y} ${TreeSpot[4].Z}
				while ${OgreBotAPI.Get_Variable["${CharacterTree[5]}NeedsFlecksCure"].Equal["TRUE"]}
				{
					wait 1
				}
				oc !ci -ChangeCampSpotWho ${CharacterTree[5]} ${TreeSpot[5].X} ${TreeSpot[5].Y} ${TreeSpot[5].Z}
				
				; Wait for Flecks of Regret detrimental to be cured from everyone else that needs it
				call WaitForFlecksCure
				; Send remaining characters to Trees (keeping tank near the Priest)
				oc !ci -ChangeCampSpotWho ${Me.Name} ${TreeSpot[1].X} ${TreeSpot[1].Y} ${TreeSpot[1].Z}
				oc !ci -ChangeCampSpotWho ${CharacterTree[1]} ${TreeSpot[1].X} ${TreeSpot[1].Y} ${TreeSpot[1].Z}
				oc !ci -ChangeCampSpotWho ${CharacterTree[2]} ${TreeSpot[2].X} ${TreeSpot[2].Y} ${TreeSpot[2].Z}
				oc !ci -ChangeCampSpotWho ${CharacterTree[3]} ${TreeSpot[3].X} ${TreeSpot[3].Y} ${TreeSpot[3].Z}
				; Wait for Stupendous Slam to be cast (up to 10 seconds)
				Counter:Set[0]
				while ${NuggetStupendousSlamIncoming} && ${Counter:Inc} <= 100
				{
					wait 1
				}
				; Bring characters back to KillSpot
				oc !ci -ChangeCampSpotWho igw:${Me.Name} ${KillSpot.X} ${KillSpot.Y} ${KillSpot.Z}
				; Set Stupendous Slam as handled
				NuggetStupendousSlamIncoming:Set[FALSE]
			}
			; Handle Stupendous Sweep
			; 	Ability casting ID 9122154, time = 4 sec
			; 	Frontal AoE with a knockback and detriments
			; 	May also aggro adds in the bushes if hit by the spell
			if ${StupendousSweepIncoming}
			{
				; Want fighter in front of named and rest of group in back, but first want the named looking at direction without a bush in the line of fire
				; 	Heading 150 should get it pointed in a good direction from KillSpot
				FighterNamedOffset:Set[150 - ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].Heading}]
				call MoveInRelationToNamed "igw:${Me.Name}+fighter" "${_NamedNPC}" "5" "${FighterNamedOffset}"
				FighterNamedOffset:Inc[180]
				call MoveInRelationToNamed "igw:${Me.Name}+notfighter" "${_NamedNPC}" "5" "${FighterNamedOffset}"
				wait 20
				; Wait until sweep is about to go off, then send fighter to side to joust it (wait up to 6 seconds)
				Counter:Set[0]
				while ${Counter:Inc} <= 20 || (${Me.GetGameData["Target.Casting"].Percent} > 0 && ${Counter} <= 60)
				{
					; Move fighter to side when sweep >= 70% cast
					if ${Me.GetGameData["Target.Casting"].Percent} >= 70
					{
						FighterNamedOffset:Set[90]
						call MoveInRelationToNamed "igw:${Me.Name}+fighter" "${_NamedNPC}" "5" "${FighterNamedOffset}"
					}
					; Otherwise if not >= 50% cast reposition again just to make sure
					elseif !${Me.GetGameData["Target.Casting"].Percent} >= 50
					{
						FighterNamedOffset:Set[150 - ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].Heading}]
						call MoveInRelationToNamed "igw:${Me.Name}+fighter" "${_NamedNPC}" "5" "${FighterNamedOffset}"
						FighterNamedOffset:Inc[180]
						call MoveInRelationToNamed "igw:${Me.Name}+notfighter" "${_NamedNPC}" "5" "${FighterNamedOffset}"
						wait 5
					}
					wait 1
				}
				; Move everyone back to KillSpot when finished
				Counter:Set[0]
				while ${Counter:Inc} <= 10 && !${NuggetAbsorbAndCrushArmorIncoming}
				{
					wait 1
				}
				oc !ci -ChangeCampSpotWho igw:${Me.Name} ${KillSpot.X} ${KillSpot.Y} ${KillSpot.Z}
				; Set Stupendous Sweep as handled
				StupendousSweepIncoming:Set[FALSE]
			}
			; Check to see if new unearthed aurum clusters have spawned
			; 	Nugget buries itself into the ground, unearthing 2 aurum clusters around the Giltglen!
			if ${ClustersSpawned}
			{
				; Mine new unearthed aurum clusters
				call MineUnearthedClusters
				; Handled ClustersSpawned
				ClustersSpawned:Set[FALSE]
			}
			; Short wait before looping (to respond as quickly as possible to events)
			wait 1
			; Update NuggetExists every 3 seconds
			if ${NuggetCheckCount:Inc} >= 30
			{
				call CheckNuggetExists
				NuggetCheckCount:Set[0]
			}
		}
		
		; Detach Atoms
		Event[EQ2_onIncomingText]:DetachAtom[NuggetIncomingText]
		Event[EQ2_onIncomingChatText]:DetachAtom[NuggetIncomingChatText]
		Event[EQ2_onAnnouncement]:DetachAtom[NuggetAnnouncement]
		
		; Check named is dead
		if ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
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

	function SetupNugget(bool EnableNugget)
	{
		; Setup Cures
		variable bool SetDisable
		SetDisable:Set[!${EnableNugget}]
		call SetupAllCures "${SetDisable}"
		; Set HO settings
		call SetupNuggetHO "${EnableNugget}"
		; Setup Interrupts (don't want to interrupt All Mine when cast or will soft lock the fight)
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_nointerrupts ${EnableNugget} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+swashbuckler "Daring Advance" ${SetDisable} TRUE
		wait 1
		if ${EnableNugget}
			oc !ci -CancelMaintainedForWho igw:${Me.Name}+swashbuckler "Daring Advance"
	}

	function SetupNuggetHO(bool EnableNugget)
	{
		; Setup general HO settings
		if ${EnableNugget}
		{
			; Disable HO Start/Starter/Wheel on all characters
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_ho_start FALSE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_ho_starter FALSE TRUE
			oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_ho_wheel FALSE TRUE
		}
		else
			call SetInitialHOSettings
		; Setup class-specific abilities to use during HO's
		; 	Don't want these abilities to be on a cool down when trying to use them
		variable bool SetDisable
		SetDisable:Set[!${EnableNugget}]
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Siphon Strike" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Hateful Slam" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+berserker "Rupture" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+berserker "Body Check" ${SetDisable} TRUE
		; Disable Walk the Plank, don't want Nugget potentially facing the wrong direction during a sweep
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+swashbuckler "Walk the Plank" ${SetDisable} TRUE
	}

	function CheckNuggetExists()
	{
		; Assume NuggetExists if in Combat
		if ${Me.InCombat}
		{
			NuggetExists:Set[TRUE]
			return
		}
		; Have seen him disappear briefly even when not killed, so repeat check multiple times just to make sure he is actually gone
		variable int Counter=0
		while ${Counter:Inc} <= 5
		{
			; Check to see if Nugget exists
			if ${Actor[Query,Name=="Nugget" && Type != "Corpse"].ID(exists)}
			{
				NuggetExists:Set[TRUE]
				return
			}
		}
		; Nugget not found
		NuggetExists:Set[FALSE]
	}
	
	function MineOreSpot()
	{
		; Get Location of Nugget (try up to 3 times if get Location failed)
		variable point3f NuggetLoc
		NuggetLoc:Set[${Actor[Query,Name=="Nugget" && Type != "Corpse"].Loc}]
		if ${NuggetLoc.X}==0 && ${NuggetLoc.Y}==0 && ${NuggetLoc.Z}==0
		{
			wait 10
			NuggetLoc:Set[${Actor[Query,Name=="Nugget" && Type != "Corpse"].Loc}]
		}
		if ${NuggetLoc.X}==0 && ${NuggetLoc.Y}==0 && ${NuggetLoc.Z}==0
		{
			wait 10
			NuggetLoc:Set[${Actor[Query,Name=="Nugget" && Type != "Corpse"].Loc}]
		}
		; Get Next/Current/Previous OreSpots
		variable int NextOreNum
		variable int PreviousOreNum
		NextOreNum:Set[${OreNum}+1]
		if ${NextOreNum} > ${OreSpot.Size}
			NextOreNum:Set[1]
		PreviousOreNum:Set[${OreNum}-1]
		if ${PreviousOreNum} < 1
			PreviousOreNum:Set[${OreSpot.Size}]
		variable point3f NextOreSpot
		variable point3f CurrentOreSpot
		variable point3f PreviousOreSpot
		NextOreSpot:Set[${OreSpot[${NextOreNum}]}]
		CurrentOreSpot:Set[${OreSpot[${OreNum}]}]
		PreviousOreSpot:Set[${OreSpot[${PreviousOreNum}]}]
		; Calculate Distance of Nugget from each OreSpot
		variable float NextDistance
		variable float CurrentDistance
		variable float PreviousDistance
		NextDistance:Set[${Math.Distance[${NuggetLoc.X},${NuggetLoc.Z},${NextOreSpot.X},${NextOreSpot.Z}]}]
		CurrentDistance:Set[${Math.Distance[${NuggetLoc.X},${NuggetLoc.Z},${CurrentOreSpot.X},${CurrentOreSpot.Z}]}]
		PreviousDistance:Set[${Math.Distance[${NuggetLoc.X},${NuggetLoc.Z},${PreviousOreSpot.X},${PreviousOreSpot.Z}]}]
		; If Nugget not within 50m of NextOreSpot, move to NextOreSpot
		if ${NextDistance} > 50
		{
			OreNum:Set[${NextOreNum}]
			Obj_OgreIH:ChangeCampSpot["${NextOreSpot}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
		}
		; Otherwise if Nugget within 40m of current OreSpot, move to either Next/PreviousOreSpot if either has a greater distance
		elseif ${CurrentDistance} < 40
		{
			if ${NextDistance} > ${CurrentDistance}
			{
				OreNum:Set[${NextOreNum}]
				Obj_OgreIH:ChangeCampSpot["${NextOreSpot}"]
				call Obj_OgreUtilities.HandleWaitForCampSpot 10
			}
			elseif ${PreviousDistance} > ${CurrentDistance}
			{
				OreNum:Set[${PreviousOreNum}]
				Obj_OgreIH:ChangeCampSpot["${PreviousOreSpot}"]
				call Obj_OgreUtilities.HandleWaitForCampSpot 10
			}
		}
		; Wait for any aurum cluster within 8m to be mined (up to 20 seconds)
		variable int Counter
		Counter:Set[0]
		while ${Actor[Query, Name == "aurum cluster" && Distance < 8].ID(exists)} && ${Counter:Inc} <= 20
		{
			; Break out of loop early if Nugget gets within 40m
			if ${Actor[Query,Name=="Nugget" && Type != "Corpse" && Distance < 40].ID(exists)}
				break
			; Wait a second before looping
			wait 10
		}
	}
	
	function MineUnearthedClusters()
	{
		; Setup Variables
		variable int GroupNum
		variable int Counter
		variable int MaxAurumCountGroupNum
		variable bool TargetAurumCountUpdated[5]
		variable int UnearthedNum=1
		variable index:actor Unearthed
		variable iterator UnearthedIterator
		variable actor ClosestUnearthed
		variable point3f UnearthedLoc
		variable int ClosestUnearthedNum
		variable int UnearthedForwardSteps
		variable int UnearthedBackwardSteps
		variable int UnearthedMoveInc
		variable bool FoundCluster=TRUE
		variable bool NeedsFlecksCure
		
		; Add AdditionalClusters to TargetAurumCount
		while ${AdditionalClusters} > 0
		{
			; Loop through TargetAurumCount, searching for highest count that has not already been updated
			GroupNum:Set[0]
			MaxAurumCountGroupNum:Set[0]
			while ${GroupNum:Inc} < ${Me.GroupCount}
			{
				; Skip if TargetAurumCountUpdated
				if ${TargetAurumCountUpdated[${GroupNum}]}
					continue
				; Set MaxAurumCountGroupNum if 0
				elseif ${MaxAurumCountGroupNum} == 0
					MaxAurumCountGroupNum:Set[${GroupNum}]
				; Set MaxAurumCountGroupNum if TargetAurumCount is higher
				elseif ${TargetAurumCount[${GroupNum}]} > ${TargetAurumCount[${MaxAurumCountGroupNum}]}
					MaxAurumCountGroupNum:Set[${GroupNum}]
			}
			; Update TargetAurumCount for MaxAurumCountGroupNum
			TargetAurumCount[${MaxAurumCountGroupNum}]:Inc
			oc !ci -Set_Variable igw:${Me.Name} "${Me.Group[${MaxAurumCountGroupNum}].Name}TargetAurumCount" "${TargetAurumCount[${MaxAurumCountGroupNum}]}"
			TargetAurumCountUpdated[${MaxAurumCountGroupNum}]:Set[TRUE]
			; Decrement AdditionalClusters
			AdditionalClusters:Dec
		}
		; Make sure clusters have spawned (wait up to 5 seconds)
		Counter:Set[0]
		while !${Actor[Query, Name == "unearthed aurum cluster"].ID(exists)} && ${Counter:Inc} <= 50
		{
			wait 1
		}
		; Handle unearthed aurum cluster until they no longer exist
		while ${FoundCluster}
		{
			; Clear ClosestUnearthed and FoundCluster
			ClosestUnearthed:Set[0]
			FoundCluster:Set[FALSE]
			; Search for all unearthed aurum clusters
			EQ2:QueryActors[Unearthed, Name == "unearthed aurum cluster"]
			Unearthed:GetIterator[UnearthedIterator]
			if ${UnearthedIterator:First(exists)}
			{
				; Loop through clusters
				do
				{
					; Update ClosestUnearthed if not set or cluster is closer
					; 	Want to mine the closer clusters first to minimize chance of pulling extra slugs on the way to a cluster
					if ${ClosestUnearthed.ID} == 0 || ${Math.Distance[${UnearthedIterator.Value.X},${UnearthedIterator.Value.Z},${Me.X},${Me.Z}]} < ${Math.Distance[${ClosestUnearthed.X},${ClosestUnearthed.Z},${Me.X},${Me.Z}]}
						ClosestUnearthed:Set[${UnearthedIterator.Value.ID}]
				}
				while ${UnearthedIterator:Next(exists)}
			}
			; Make sure a cluster was found
			if ${ClosestUnearthed.ID} != 0
			{
				; Set FoundCluster = TRUE
				FoundCluster:Set[TRUE]
				; Get cluster Location, make sure it is valid
				UnearthedLoc:Set[${ClosestUnearthed.Loc}]
				if ${UnearthedLoc.X}!=0 || ${UnearthedLoc.Y}!=0 || ${UnearthedLoc.Z}!=0
				{
					; Loop through each UnearthedSpot, see which is closest to cluster
					ClosestUnearthedNum:Set[1]
					Counter:Set[1]
					while ${Counter:Inc} <= ${UnearthedSpot.Size}
					{
						if ${Math.Distance[${UnearthedLoc.X},${UnearthedLoc.Z},${UnearthedSpot[${Counter}].X},${UnearthedSpot[${Counter}].Z}]} < ${Math.Distance[${UnearthedLoc.X},${UnearthedLoc.Z},${UnearthedSpot[${ClosestUnearthedNum}].X},${UnearthedSpot[${ClosestUnearthedNum}].Z}]}
							ClosestUnearthedNum:Set[${Counter}]
					}
					; Figure out if we can get from UnearthedNum to ClosestUnearthedNum faster moving in forward or backward direction looping through UnearthedSpots
					UnearthedForwardSteps:Set[0]
					Counter:Set[${UnearthedNum}]
					while ${Counter} != ${ClosestUnearthedNum}
					{
						Counter:Inc
						if ${Counter} > ${UnearthedSpot.Size}
							Counter:Set[1]
						UnearthedForwardSteps:Inc
					}
					UnearthedBackwardSteps:Set[0]
					Counter:Set[${UnearthedNum}]
					while ${Counter} != ${ClosestUnearthedNum}
					{
						Counter:Dec
						if ${Counter} < 1
							Counter:Set[${UnearthedSpot.Size}]
						UnearthedBackwardSteps:Inc
					}
					; Set UnearthedMoveInc to move forward or backward
					UnearthedMoveInc:Set[1]
					if ${UnearthedBackwardSteps} < ${UnearthedForwardSteps}
						UnearthedMoveInc:Set[-1]
					; Move between UnearthedSpots to get to ClosestUnearthedNum
					while ${UnearthedNum} != ${ClosestUnearthedNum}
					{
						; Update UnearthedNum
						UnearthedNum:Inc[${UnearthedMoveInc}]
						if ${UnearthedNum} > ${UnearthedSpot.Size}
							UnearthedNum:Set[1]
						elseif ${UnearthedNum} < 1
							UnearthedNum:Set[${UnearthedSpot.Size}]
						; Check to make sure not in combat with a gleaming goldslug, otherwise wait to kill it before moving
						while ${Actor[Query, Name == "a gleaming goldslug" && Target.ID != 0].ID(exists)}
						{
							wait 10
						}
						; Check to make sure a Curse Cure is not needed, otherwise wait for it to be cured
						while ${OgreBotAPI.Get_Variable["NeedsCurseCure"].Length} > 0 && !${OgreBotAPI.Get_Variable["NeedsCurseCure"].Equal["None"]}
						{
							wait 10
						}
						; Move to new UnearthedSpot
						Obj_OgreIH:ChangeCampSpot["${UnearthedSpot[${UnearthedNum}]}"]
						call Obj_OgreUtilities.HandleWaitForCampSpot 10
					}
					; Check to make sure a Curse Cure is not needed, otherwise wait for it to be cured
					while ${OgreBotAPI.Get_Variable["NeedsCurseCure"].Length} > 0 && !${OgreBotAPI.Get_Variable["NeedsCurseCure"].Equal["None"]}
					{
						wait 10
					}
					; Move from UnearthedSpot to cluster, but stop just short of it
					; 	Clusters can spawn right by bushes, so don't want to potentially run into a bush and get adds
					call CalcSpotOffset "${UnearthedSpot[${UnearthedNum}]}" "${UnearthedLoc}" "5"
					Obj_OgreIH:ChangeCampSpot["${Return}"]
					call Obj_OgreUtilities.HandleWaitForCampSpot 10
					; Wait as long as cluster exists (up to 60 seconds)
					Counter:Set[0]
					while ${ClosestUnearthed.ID(exists)} && ${Counter:Inc} <= 600
					{
						wait 1
					}
					; Check to make sure a Curse Cure is not needed, otherwise wait for it to be cured
					while ${OgreBotAPI.Get_Variable["NeedsCurseCure"].Length} > 0 && !${OgreBotAPI.Get_Variable["NeedsCurseCure"].Equal["None"]}
					{
						wait 10
					}
					; Move back to UnearthedSpot
					Obj_OgreIH:ChangeCampSpot["${UnearthedSpot[${UnearthedNum}]}"]
					call Obj_OgreUtilities.HandleWaitForCampSpot 10
				}
			}
		}
		; Figure out if we can get UnearthedNum back to 1 faster moving in forward or backward direction looping through UnearthedSpots
		UnearthedForwardSteps:Set[0]
		Counter:Set[${UnearthedNum}]
		while ${Counter} != 1
		{
			Counter:Inc
			if ${Counter} > ${UnearthedSpot.Size}
				Counter:Set[1]
			UnearthedForwardSteps:Inc
		}
		UnearthedBackwardSteps:Set[0]
		Counter:Set[${UnearthedNum}]
		while ${Counter} != 1
		{
			Counter:Dec
			if ${Counter} < 1
				Counter:Set[${UnearthedSpot.Size}]
			UnearthedBackwardSteps:Inc
		}
		; Set UnearthedMoveInc to move forward or backward
		UnearthedMoveInc:Set[1]
		if ${UnearthedBackwardSteps} < ${UnearthedForwardSteps}
			UnearthedMoveInc:Set[-1]
		; Move between UnearthedSpots to get back to 1 (which is KillSpot)
		while ${UnearthedNum} != 1
		{
			; Update UnearthedNum
			UnearthedNum:Inc[${UnearthedMoveInc}]
			if ${UnearthedNum} > ${UnearthedSpot.Size}
				UnearthedNum:Set[1]
			elseif ${UnearthedNum} < 1
				UnearthedNum:Set[${UnearthedSpot.Size}]
			; Move to new UnearthedSpot
			Obj_OgreIH:ChangeCampSpot["${UnearthedSpot[${UnearthedNum}]}"]
			call Obj_OgreUtilities.HandleWaitForCampSpot 10
		}
	}

	function WaitForFlecksCure()
	{
		; Wait for Flecks of Regret detrimental to be cured from everyone that needs it
		; 	Wait up to 10 seconds
		variable bool NeedsFlecksCure=TRUE
		variable int Counter=0
		while ${NeedsFlecksCure} && ${Counter:Inc} <= 20
		{
			; Check to see if anyone NeedsFlecksCure
			call CheckNeedsFlecksCure
			NeedsFlecksCure:Set[${Return}]
			; Short wait before looping again
			wait 5
		}
	}

	function CheckNeedsFlecksCure()
	{
		; Check to see if anyone NeedsFlecksCure
		variable int GroupNum=0
		while ${GroupNum:Inc} <= ${GroupMembers.Size}
		{
			; Return TRUE if NeedsFlecksCure is TRUE
			if ${OgreBotAPI.Get_Variable["${GroupMembers[${GroupNum}]}NeedsFlecksCure"].Equal["TRUE"]}
				return TRUE
		}
		; No one needs Flecks Cure
		return FALSE
	}

/**********************************************************************************************************
 	Named 3 *********************    Move to, spawn and kill - ??? **********************************
***********************************************************************************************************/

	function:bool Named3(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[0,0,0]
		
		; Undo Nugget custom settings
		call SetupNugget "FALSE"
		
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
		
		
		; Set Loot settings for last boss
		call SetLootForLastBoss
		
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

atom NuggetIncomingText(string Text)
{
	; Look for message that Stupendous Slam has been cast
	if ${Text.Find["As a fighter, you shrug off the attempted knock up."]}
		NuggetStupendousSlamIncoming:Set[FALSE]
	; Look for message that Stupendous Slam is incoming
	elseif ${Text.Find["Hold on tight!"]}
		NuggetStupendousSlamIncoming:Set[TRUE]
	; Look for message that Absorb and Crush Armor is incoming
	; Nugget begins to absorb your armor, and will soon crush them unless interrupted somehow!
	; Nugget begins to absorb your armor, and will crush them sooner than before!
	elseif ${Text.Find["Nugget begins to absorb your armor"]}
		NuggetAbsorbAndCrushArmorIncoming:Set[TRUE]
}

atom NuggetIncomingChatText(int ChatType, string Message, string Speaker, string TargetName, string SpeakerIsNPC, string ChannelName)
{
	; Look for message that 2 unearthed aurum clusters have spawned
	if ${Message.Find["buries itself into the ground, unearthing 2 aurum clusters around the Giltglen!"]}
	{
		ClustersSpawned:Set[TRUE]
		AdditionalClusters:Set[2]
	}
	; Look for message that 3 unearthed aurum clusters have spawned
	elseif ${Message.Find["buries itself into the ground, unearthing 3 aurum clusters around the Giltglen!"]}
	{
		ClustersSpawned:Set[TRUE]
		AdditionalClusters:Set[3]
	}
	; Look for message that 4 unearthed aurum clusters have spawned
	elseif ${Message.Find["buries itself into the ground, unearthing 4 aurum clusters around the Giltglen!"]}
	{
		ClustersSpawned:Set[TRUE]
		AdditionalClusters:Set[4]
	}
	; Look for Stupendous Sweep being cast
	elseif ${Message.Find["plants itself and prepares to sweep away everyone in front of it!"]}
		StupendousSweepIncoming:Set[TRUE]
	; Look for message that Absorb and Crush Armor has been interrupted
	elseif ${Message.Find["is interrupted by a successful Heroic Opportunity initiated by Fighting Chance! Your armor returns!"]}
		NuggetAbsorbAndCrushArmorIncoming:Set[FALSE]
	
	; Debug text to see messages
	;echo ${ChatType}, ${Message}, ${Speaker}, ${TargetName}, ${SpeakerIsNPC}, ${ChannelName}
}

atom NuggetAnnouncement(string Text, string SoundType, float Timer)
{
	; Look for message that Stupendous Slam is incoming
	if ${Text.Find["Quick! Hold onto something! But not the same thing as anyone else!"]}
		NuggetStupendousSlamIncoming:Set[TRUE]
}
