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
variable bool NuggetAllMineIncoming=FALSE
; Custom variabled for Coppernicus
variable bool CoppernicusRespawn=FALSE
variable time ChangingTheoryExpirationTimestamp
variable time CoppernicusExpectedHelioTime
; Custom variables for Goldfeather
variable bool GoldfeatherRespawn=FALSE
variable bool GoldfeatherPlumeBoomIncoming=FALSE
variable bool GoldfeatherPlumeBoomCast=FALSE

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
			; Check to see if at "The Golden Terrace" respawn point after wiping to Coppernicus
			if ${Math.Distance[${Me.X},${Me.Y},${Me.Z},745.04,312.38,68.43]} < 50
			{
				_StartingPoint:Set[3]
				CoppernicusRespawn:Set[TRUE]
			}
			; Check to see if at "Eighteen Karat Copse" respawn point after wiping to Goldfeather
			if ${Math.Distance[${Me.X},${Me.Y},${Me.Z},790.69,279.30,547.14]} < 50
			{
				_StartingPoint:Set[4]
				GoldfeatherRespawn:Set[TRUE]
			}
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
			call This.Named3 "Coppernicus"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#3: Coppernicus"]
				return FALSE
			}
			_StartingPoint:Inc
		}
		; Move to and kill Named 4
		if ${_StartingPoint} == 4
		{
			call This.Named4 "Goldfeather"
			if !${Return}
			{
				Obj_OgreIH:Message_FailedZone["#4: Goldfeather"]
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
		; Allow Heroic Setups (not needed, but seems to work fine along with my script)
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_grindoptions ${EnableAurom} TRUE
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
	variable point3f OreSpot[26]
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
		variable int SweepCount=0
		variable bool NuggetAbsorbAndCrushArmorPreparing=FALSE
		variable int NuggetHP=0
		variable int NuggetHPCount=0
		
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
		OreSpot[9]:Set[787.63,204.01,156.65]
		OreSpot[10]:Set[796.32,203.45,156.79]
		OreSpot[11]:Set[769.92,205.42,200.81]
		OreSpot[12]:Set[769.60,209.89,211.55]
		OreSpot[13]:Set[750.81,208.95,207.50]
		OreSpot[14]:Set[728.09,200.06,183.93]
		OreSpot[15]:Set[735.41,200.94,168.37]
		OreSpot[16]:Set[737.78,200.43,152.51]
		OreSpot[17]:Set[729.88,201.31,152.77]
		OreSpot[18]:Set[710.29,202.13,149.11]
		OreSpot[19]:Set[680.57,200.19,152.08]
		OreSpot[20]:Set[693.47,199.95,139.30]
		OreSpot[21]:Set[707.18,202.67,95.88]
		OreSpot[22]:Set[707.71,205.69,76.67]
		OreSpot[23]:Set[685.31,201.95,81.48]
		OreSpot[24]:Set[694.82,202.58,88.46]
		OreSpot[25]:Set[680.09,208.35,52.73]
		OreSpot[26]:Set[680.91,214.70,5.60]
		
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
				; Enable fighter cast stack
				oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_settings_disablecaststack FALSE TRUE
				; Set Absorb and Crush Armor as handled and not preparing
				NuggetAbsorbAndCrushArmorIncoming:Set[FALSE]
				NuggetAbsorbAndCrushArmorPreparing:Set[FALSE]
			}
			; Prepare for Absorb and Crush Armor
			; 	Happens at 76%, 51%, 26%
			; 	Want to complete as fast as possible, so disable cast stack for fighters right before so they aren't casting/in recovery when need to start HO
			if !${NuggetAbsorbAndCrushArmorPreparing}
			{
				if ${NuggetHPCount} < 0
					NuggetHPCount:Inc
				if ${NuggetHPCount} == 0
				{
					; Get Nugget HP, see if at 77/78%, 52/53%, or 27/28%
					NuggetHP:Set[${Actor[Query,Name=="Nugget" && Type != "Corpse"].Health}]
					if ${NuggetHP} == 77 || ${NuggetHP} == 78 || ${NuggetHP} == 52 || ${NuggetHP} == 53 || ${NuggetHP} == 27 || ${NuggetHP} == 28
					{
						; Disable fighter cast stack
						oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_settings_disablecaststack TRUE TRUE
						; Set NuggetAbsorbAndCrushArmorPreparing = TRUE
						NuggetAbsorbAndCrushArmorPreparing:Set[TRUE]
					}
					; Set NuggetHPCount to prevent from being triggered again for another second
					NuggetHPCount:Set[-10]
				}
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
				call MoveInRelationToNamed "igw:${Me.Name}+fighter" "${_NamedNPC}" "7" "${FighterNamedOffset}"
				FighterNamedOffset:Inc[180]
				call MoveInRelationToNamed "igw:${Me.Name}+notfighter" "${_NamedNPC}" "7" "${FighterNamedOffset}"
				wait 20
				; Cast Immunization on fighter in case they don't successfully dodge the sweep
				oc !ci -CastAbilityOnPlayer igw:${Me.Name}+mystic "Immunization" ${Me.Name} 0
				; Wait until sweep is about to go off, then send fighter to side to joust it (wait up to 6 seconds)
				Counter:Set[0]
				SweepCount:Set[0]
				while (${Counter:Inc} <= 20 || (${Me.GetGameData["Target.Casting"].Percent} > 0 && ${Counter} <= 60)) && !${NuggetAbsorbAndCrushArmorIncoming}
				{
					; Move fighter to side when sweep >= 70% cast
					if ${Me.GetGameData["Target.Casting"].Percent} >= 70
					{
						FighterNamedOffset:Set[90]
						call MoveInRelationToNamed "igw:${Me.Name}+fighter" "${_NamedNPC}" "7" "${FighterNamedOffset}"
					}
					; Otherwise if not >= 50% cast reposition again just to make sure
					elseif !${Me.GetGameData["Target.Casting"].Percent} >= 50
					{
						if ${SweepCount} < 0
							SweepCount:Inc
						if ${SweepCount} == 0
						{
							FighterNamedOffset:Set[150 - ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].Heading}]
							call MoveInRelationToNamed "igw:${Me.Name}+fighter" "${_NamedNPC}" "7" "${FighterNamedOffset}"
							FighterNamedOffset:Inc[180]
							call MoveInRelationToNamed "igw:${Me.Name}+notfighter" "${_NamedNPC}" "7" "${FighterNamedOffset}"
							; Set SweepCount to prevent from being triggered again for another half second
							SweepCount:Set[-5]
						}
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
			; Handle All Mine incoming
			; 	Nugget begins to cast All Mine, then buries itself into the ground and spawns clusters
			; 	Have found this to be very buggy and occasionally Nugget will either not give characters the curse or just straight up reset the fight
			; 	To try to minimize the chance of this happening, stopping all attacks during the cast
			if ${NuggetAllMineIncoming}
			{
				; Pause Ogre and back off pets
				oc !ci -Pause igw:${Me.Name}
				oc !ci -PetOff igw:${Me.Name}
				wait 1
				; Clear ability queue
				relay ${OgreRelayGroup} eq2execute clearabilityqueue
				wait 1
				; Cancel anything currently being cast
				oc !ci -CancelCasting igw:${Me.Name}
				wait 5
				; Wait for All Mine to be cast (up to 6 seconds)
				Counter:Set[0]
				while !${ClustersSpawned} && ${Counter:Inc} <= 60
				{
					wait 1
				}
				; Resume Ogre and pets
				oc !ci -Resume igw:${Me.Name}
				oc !ci -PetAssist igw:${Me.Name}
				; Set All Mine as handled
				NuggetAllMineIncoming:Set[FALSE]
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
		; Disable Immunization so it is available during Stupendous Sweep
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Immunization" ${SetDisable} TRUE
		; Disable abilities that may cause problems with named movement/direction
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+swashbuckler "Walk the Plank" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+beastlord "Noxious Grasp" ${SetDisable} TRUE
		; Disable Interrupts and various abilities during fight
		; 	Have had it happen where after casting "All Mine" none of the characters in the group get the curse and it softlocks the fight
		; 	Not sure what causes it, so turning off Interrupts and and other abilities that might interfere with it somehow
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_nostuns ${EnableNugget} TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_nodazes ${EnableNugget} TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_nostifles ${EnableNugget} TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_nointerrupts ${EnableNugget} TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_noaeblockers ${EnableNugget} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Aura of the Crusader" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Death March" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Hammer Ground" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Hateful Slam" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+shadowknight "Soulrend" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+scout "Cheap Shot" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+ranger "Point Blank Shot" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+ranger "Sniper Shot" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+swashbuckler "Dashing Swathe" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+swashbuckler "Shanghai" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Ancestral Support" ${SetDisable} TRUE
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
		variable bool FoundSlug
		
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
					FoundSlug:Set[FALSE]
					while ${UnearthedNum} != ${ClosestUnearthedNum}
					{
						; Check to make sure not in combat with a gleaming goldslug, otherwise wait to kill it before moving
						while ${Actor[Query, Name == "a gleaming goldslug" && Target.ID != 0].ID(exists)}
						{
							FoundSlug:Set[TRUE]
							wait 5
						}
						; Check to make sure a Curse Cure is not needed, otherwise wait for it to be cured
						while ${OgreBotAPI.Get_Variable["NeedsCurseCure"].Length} > 0 && !${OgreBotAPI.Get_Variable["NeedsCurseCure"].Equal["None"]}
						{
							wait 5
						}
						; If FoundSlug, don't continue because may have come across another cluster on the way to target cluster and want to mine it first
						if ${FoundSlug} 
							break
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
					; Check to make sure a Curse Cure is not needed, otherwise wait for it to be cured
					while ${OgreBotAPI.Get_Variable["NeedsCurseCure"].Length} > 0 && !${OgreBotAPI.Get_Variable["NeedsCurseCure"].Equal["None"]}
					{
						wait 5
					}
					; If FoundSlug, loop again to refresh which cluster is closest
					if ${FoundSlug} 
						continue
					; Move from UnearthedSpot to cluster, but stop just short of it
					; 	Clusters can spawn right by bushes, so don't want to potentially run into a bush and get adds
					call CalcSpotOffset "${UnearthedSpot[${UnearthedNum}]}" "${UnearthedLoc}" "5"
					Obj_OgreIH:ChangeCampSpot["${Return}"]
					call Obj_OgreUtilities.HandleWaitForCampSpot 10
					
					
					
					
					; ************************************************************
					; ************************************************************
					; ************************************************************
					; Testing!!!
					
					; Bring fighter back to pull slug away from cluster
					;call CalcSpotOffset "${UnearthedSpot[${UnearthedNum}]}" "${UnearthedLoc}" "20"
					;oc !ci -ChangeCampSpotWho ${Me.Name} ${Return.X} ${Return.Y} ${Return.Z}
					
					; ************************************************************
					; ************************************************************
					; ************************************************************
					
					
					
					
					
					; Wait as long as cluster exists (up to 60 seconds)
					Counter:Set[0]
					while ${ClosestUnearthed.ID(exists)} && ${Counter:Inc} <= 600
					{
						wait 1
					}
					; Check to make sure a Curse Cure is not needed, otherwise wait for it to be cured
					while ${OgreBotAPI.Get_Variable["NeedsCurseCure"].Length} > 0 && !${OgreBotAPI.Get_Variable["NeedsCurseCure"].Equal["None"]}
					{
						wait 5
					}
					
					
					; ************************************************************
					; ************************************************************
					; ************************************************************
					; Testing!!!
					
					; Check to make sure not in combat with a gleaming goldslug, otherwise wait to kill it before moving
					;while ${Actor[Query, Name == "a gleaming goldslug" && Target.ID != 0].ID(exists)}
					;{
					;	wait 5
					;}
					; Check to make sure a Curse Cure is not needed, otherwise wait for it to be cured
					;while ${OgreBotAPI.Get_Variable["NeedsCurseCure"].Length} > 0 && !${OgreBotAPI.Get_Variable["NeedsCurseCure"].Equal["None"]}
					;{
					;	wait 5
					;}
					
					; ************************************************************
					; ************************************************************
					; ************************************************************
					
					
					
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
 	Named 3 *********************    Move to, spawn and kill - Coppernicus ********************************
***********************************************************************************************************/
	
	; Setup Variables needed outside Named3 function
	variable bool CoppernicusExists
	variable string CoppernicusPriestTank
	
	function:bool Named3(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[904.63,328.05,82.13]
		
		; Undo Nugget custom settings
		call SetupNugget "FALSE"
		
		; Set Loot settings for last boss (not the last boss, but does drop NO-TRADE Bell)
		call SetLootForLastBoss
		
		; Setup variables
		variable int GroupNum
		variable int Counter
		variable string JoustCharacter[5]
		variable bool JoustCharacterPositionSet[5]
		variable int CoppernicusID
		variable int SecondLoopCount=10
		variable int CoppernicusExistsCount=0
		variable int CentralFireIncrements=0
		variable int OrbitingBodiesIncrements=0
		variable int ChangingTheoryIncrements=-1
		variable int CoppernicusTargetID
		variable point3f CoppernicusLoc
		variable index:actor Materia
		variable iterator MateriaIterator
		variable actor TargetMateria
		variable int MateriaTotalCount
		variable int MateriaInCount
		variable int TargetIncrements
		variable point3f PriestTankLoc
		variable point3f JoustInLoc
		variable point3f JoustOutLoc
		variable point3f FighterJoustInLoc
		variable point3f FighterJoustOutLoc
		variable point3f FighterJoustOutPriestLoc
		variable float HelioDistance
		variable float HelioDuration
		variable point3f HelioLoc
		variable bool HelioActive=FALSE
		variable bool FoundHelio=FALSE
		variable bool DPSEnabled=TRUE
		variable bool DPSAllowed=TRUE
		variable int CoppernicusHPRemainder
		
		; Swap to mez immunity rune
		call mend_and_rune_swap "mez" "mez" "mez" "mez"
		
		; Setup for named
		call initialize_move_to_next_boss "${_NamedNPC}" "3"
		
		; Move to named from Nugget
		if !${CoppernicusRespawn}
		{
			call move_to_next_waypoint "742.42,200.10,177.75"
			call move_to_next_waypoint "682.43,205.56,170.69"
			call move_to_next_waypoint "609.59,238.68,230.09"
			call move_to_next_waypoint "549.60,248.19,252.95"
			call move_to_next_waypoint "573.85,256.26,284.47"
			call move_to_next_waypoint "641.49,267.66,262.60"
			call move_to_next_waypoint "715.35,276.07,230.56"
			call move_to_next_waypoint "728.95,275.88,194.88"
			call EnterPortal "teleporter_lower" "Teleport"
		}
		; Otherwise move from respawn point
		else
			call move_to_next_waypoint "770.42,312.89,53.38"
		
		; Determine priest who will tank Coppernicus
		GroupNum:Set[0]
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			switch ${Me.Group[${GroupNum}].Class}
			{
				; Use mystic if they exist
				case mystic
					CoppernicusPriestTank:Set["${Me.Group[${GroupNum}].Name}"]
					GroupNum:Set[${Me.GroupCount}]
					break
				; Use other priest if no mystic
				default
					call GetArchetypeFromClass "${Me.Group[${GroupNum}].Class}"
					if ${Return.Equal["priest"]} && ${CoppernicusPriestTank.Length} == 0
						CoppernicusPriestTank:Set["${Me.Group[${GroupNum}].Name}"]
			}
		}
		
		; Determine character that will keep Flecks of Regret on themselves throughout the fight
		; 	Use a scout/mage that won't be tanking the adds
		GroupNum:Set[0]
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			call GetArchetypeFromClass "${Me.Group[${GroupNum}].Class}"
			if ${Return.Equal["scout"]} || ${Return.Equal["mage"]}
			{
				oc !ci -Set_Variable igw:${Me.Name} "CoppernicusFlecksCharacter" "${Me.Group[${GroupNum}].Name}"
				break
			}
		}
		
		; Set variables to use in helper script
		oc !ci -Set_Variable igw:${Me.Name} "CoppernicusPhase" "PrePull"
		oc !ci -Set_Variable igw:${Me.Name} "CoppernicusPriestTank" "${CoppernicusPriestTank}"
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}HelioDistance" "0"
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}HelioDuration" "0"
		GroupNum:Set[0]
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			oc !ci -Set_Variable igw:${Me.Name} "${Me.Group[${GroupNum}].Name}HelioDistance" "0"
			oc !ci -Set_Variable igw:${Me.Name} "${Me.Group[${GroupNum}].Name}HelioDuration" "0"
		}
		wait 1
		
		; Disable PBAE abilities before moving to named
		; 	Will also disable as part of SetupCoppernicus, but want to make sure don't aggro celestial materia when near named
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_donotsave_dynamicignorepbae TRUE TRUE
		
		; Continue move to named
		call move_to_next_waypoint "811.52,313.29,19.79"
		call move_to_next_waypoint "864.66,321.10,18.19"
		call move_to_next_waypoint "846.19,329.14,90.04"
		call move_to_next_waypoint "840.13,329.07,111.56"
		Obj_OgreIH:ChangeCampSpot["898.91,327.96,108.51"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		call move_to_next_waypoint "892.28,328.48,87.36"
		Obj_OgreIH:ChangeCampSpot["887.56,327.96,64.84"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		call move_to_next_waypoint "892.28,328.48,87.36"
		
		; Check if already killed
		call CheckCoppernicusExists
		
		; Skip if already killed
		if !${CoppernicusExists}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Assign characters to Joust
		; 	Exclude this character who will be used to tank adds and handled separately
		; 	Assign priests last so they will be out if anyone is (they get range buff by being out, so everyone in and out should be in range of heals)
		Counter:Set[0]
		GroupNum:Set[0]
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			JoustCharacter[${Counter:Inc}]:Set["${Me.Group[${GroupNum}].Name}"]
		}
		
		; Set custom settings for Coppernicus
		call SetupCoppernicus "TRUE"
		
		; ***********************************************
		; Pre-Pull
		; 	aggro 4 celestial materia, but not the named
		; ***********************************************
		
		; Move to first celestial materia
		call move_to_next_waypoint "851.26,329.08,72.82"
		call move_to_next_waypoint "852.20,321.03,16.71"
		call move_to_next_waypoint "757.07,312.72,41.99"
		call move_to_next_waypoint "750.36,312.40,33.04"

		; Disable Cast Stack for scouts/mages
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-fighter+-priest checkbox_settings_disablecaststack TRUE TRUE
		
		; Get Celestial Materia
		TargetMateria:Set[${Actor[Query,Name=="celestial materia" && Type != "Corpse" && X < 700 && Z < 0].ID}]
		
		; Pull Celestial Materia
		if ${TargetMateria.ID(exists)}
		{
			; Target Celestial Materia
			TargetMateria:DoTarget
			wait 5
			; Pet pull Celestial Materia
			while ${TargetMateria.Target.ID} == 0
			{
				relay ${OgreRelayGroup} eq2execute pet attack
				wait 10
			}
			; Wait for Celestial Materia to be pulled back to group
			while ${TargetMateria.Distance} > 10
			{
				oc !ci -PetOff igw:${Me.Name}
				wait 10
			}
		}
		
		; Move to second celestial materia
		Obj_OgreIH:ChangeCampSpot["809.00,313.17,32.97"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		Obj_OgreIH:ChangeCampSpot["851.89,321.03,19.37"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		Obj_OgreIH:ChangeCampSpot["851.85,329.06,69.01"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		Obj_OgreIH:ChangeCampSpot["813.76,328.73,141.21"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		Obj_OgreIH:ChangeCampSpot["807.64,328.38,154.44"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		
		; Get Celestial Materia
		TargetMateria:Set[${Actor[Query,Name=="celestial materia" && Type != "Corpse" && X < 800 && Z > 250].ID}]
		
		; Pull Celestial Materia
		if ${TargetMateria.ID(exists)}
		{
			; Target Celestial Materia
			TargetMateria:DoTarget
			wait 5
			; Pet pull Celestial Materia
			while ${TargetMateria.Target.ID} == 0
			{
				relay ${OgreRelayGroup} eq2execute pet attack
				wait 10
			}
			; Wait for Celestial Materia to be pulled back to group
			while ${TargetMateria.Distance} > 10
			{
				oc !ci -PetOff igw:${Me.Name}
				wait 10
			}
		}
		
		; Move to named
		Obj_OgreIH:ChangeCampSpot["832.01,329.08,101.33"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		Obj_OgreIH:ChangeCampSpot["892.28,328.48,87.36"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		
		; Run HOHelperScript to help complete HO's
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "InZone"
		
		; Handle text events
		Event[EQ2_onIncomingChatText]:AttachAtom[CoppernicusIncomingChatText]
		
		; Get CoppernicusID
		CoppernicusID:Set[${Actor[Query,Name=="Coppernicus" && Type != "Corpse"].ID}]
		
		; Wait until no celestial materia within 15m of named
		CoppernicusLoc:Set[${Actor[${CoppernicusID}].Loc}]
		while ${Actor[Query,Name=="celestial materia" && Type != "Corpse" && ${Math.Distance[${X},${Z},${CoppernicusLoc.X},${CoppernicusLoc.Z}]} < 15].ID(exists)}
		{
			wait 10
		}
		
		; Pull Named (Helper script will handle targeting)
		Ob_AutoTarget:Clear
		oc ${Me.Name} is pulling ${_NamedNPC}
		
		; Back off pets (and keep off the whole fight, Coppernicus does not like pets)
		oc !ci -PetOff igw:${Me.Name}
		
		; Move to Pull Spot
		Obj_OgreIH:ChangeCampSpot["917.36,328.29,76.56"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
		
		; Pause Ogre
		oc !ci -Pause igw:${Me.Name}
		wait 1
		
		; Run ZoneHelperScript (at start should aggro celestial materia on this character, which is assumed to be a fighter)
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC}"
		
		; Enable Cast Stack for everyone
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_disablecaststack FALSE TRUE
		
		; Wait a couple of seconds for helper script to update everyone's target, then Resume Ogre
		wait 20
		oc !ci -Resume igw:${Me.Name}
		
		; Wait until there are no un-aggroed celestial materia near named
		while ${Actor[Query,Name=="celestial materia" && Type != "Corpse" && Distance < 50 && Target.ID == 0].ID(exists)}
		{
			wait 10
		}
		
		; ***********************************************
		; Start Fight
		; ***********************************************
		
		; Set phase to Fight (will cause group to target Coppernicus in helper script)
		oc !ci -Set_Variable igw:${Me.Name} "CoppernicusPhase" "Fight"
		
		; Wait for Coppernicus to be aggroed
		while ${Actor[Query,Name=="Coppernicus" && Type != "Corpse" && Target.ID == 0].ID(exists)}
		{
			wait 1
		}
		
		; Setting CampSpot to use _MinDistance = 1 instead of the default 2 to make sure characters are close enough to Helio distances
		oc !ci -campspot igw:${Me.Name} "1" "200"
		wait 1
		
		; Send everyone back to KillSpot
		oc !ci -ChangeCampSpotWho igw:${Me.Name} ${KillSpot.X} ${KillSpot.Y} ${KillSpot.Z}
		wait 20
		
		; ***********************************************
		; Complete Priest HO to lock aggro
		; ***********************************************
		
		; Disable scout coin HO abilities (don't want to interfere with priest HO path)
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_ho_starter FALSE TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_ho_wheel FALSE TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+scout checkbox_settings_disable_scout_hoicon_41 TRUE TRUE
		; Pause Ogre
		oc !ci -Pause ${CoppernicusPriestTank}
		wait 1
		; Clear ability queue
		relay ${OgreRelayGroup} eq2execute clearabilityqueue
		wait 1
		; Cancel anything currently being cast
		oc !ci -CancelCasting igw:${Me.Name}+-fighter+-mage
		wait 5
		; Cast Divine Providence to bring up HO window
		oc !ci -CastAbility ${CoppernicusPriestTank} "Divine Providence"
		wait 1
		; Wait for HO window to pop up (up to 2 seconds)
		Counter:Set[0]
		while ${EQ2.HOWindowState} != 2 && ${Counter:Inc} <= 20
		{
			wait 1
		}
		; Cast Ability to start HO
		oc !ci -CastAbility ${CoppernicusPriestTank}+mystic "Plague"
		wait 10
		; Cast Ability to complete HO
		oc !ci -CastAbility ${CoppernicusPriestTank}+mystic "Velium Winds"
		wait 15
		; Resume Ogre
		oc !ci -Resume ${Me.Name}
		; Re-enable scout coin HO abilities
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-ranger checkbox_settings_ho_starter TRUE TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-ranger checkbox_settings_ho_wheel TRUE TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+scout checkbox_settings_disable_scout_hoicon_41 FALSE TRUE
		
		; Set default Time values
		CoppernicusExpectedHelioTime:Set[${Time.Timestamp}]
		
		; Kill named
		; There is a swirling ring around named
		; 	"The Central Fire" effect shows the number of enemies that must be within his orbit to damage him
		; 		This is based on the number of increments and includes both players and celestial materia mobs
		; 		Fight initally starts with 2 celestial materia mobs spawned and they will roam around, potentially going in and out of ring
		; 	"Orbiting Bodies" effect shows number of players + celestial materia currently in the ring
		; 		Keep number of increments equal to "The Central Fire" increments in order to damage named
		; 	"Changing Theory" effect shows the next number of increments that "The Central Fire" will swap to when "Changing Theory" expires
		; 		Occurs every 10% HP (~91%, 81% etc.)
		; 		If number doesn't match on expiration (15 seconds later) it will be a wipe
		; Will need to joust players in and out of orbit as needed to match effect increments
		; "Celestial Connection" detrimental shows HO information
		; 	Completing HO started by priest can respawn up to 4 celestial materias
		; 	Completing HO started by fighter clears the reuse of Bulwark of Order
		; Absorb Celestial Materia
		; 	Occurs every ~41-55 seconds, need to interrupt
		; Heliocentric
		; 	Occurs every ~55 seconds to 1 minute 38 seconds
		; 	Expires after ~15-24 seconds
		; 	Character needs to be at a specific range or they die
		while ${CoppernicusExists}
		{
			; Handle updates every second
			if ${SecondLoopCount:Inc} >= 10
			{
				; Update increments
				call GetActorEffectIncrements "${CoppernicusID}" "The Central Fire" "5"
				CentralFireIncrements:Set[${Return}]
				call GetActorEffectIncrements "${CoppernicusID}" "Orbiting Bodies" "5"
				OrbitingBodiesIncrements:Set[${Return}]
				call GetActorEffectIncrements "${CoppernicusID}" "Changing Theory" "5"
				ChangingTheoryIncrements:Set[${Return}]
				
				; *****************************************************
				; DEBUG TEXT
				;if ${ChangingTheoryIncrements} > 0 && ${Math.Calc[${ChangingTheoryExpirationTimestamp.Timestamp}-${Time.Timestamp}]} > 12
				;	oc Changing theory starting at ${Actor[${CoppernicusID}].Health}
				; *****************************************************
				
				; Update CoppernicusTargetID
				CoppernicusTargetID:Set[${Actor[${CoppernicusID}].Target.ID}]
				; Update location of named, make sure it is valid
				CoppernicusLoc:Set[${Actor[${CoppernicusID}].Loc}]
				if ${CoppernicusLoc.X}!=0 || ${CoppernicusLoc.Y}!=0 || ${CoppernicusLoc.Z}!=0
				{
					; Reset Materia variables
					MateriaTotalCount:Set[0]
					MateriaInCount:Set[0]
					; Query all materia within 100m
					EQ2:QueryActors[Materia, Name=="celestial materia" && Type != "Corpse" && Distance < 100]
					Materia:GetIterator[MateriaIterator]
					if ${MateriaIterator:First(exists)}
					{
						; Loop through materia
						do
						{
							; Increment MateriaTotalCount
							MateriaTotalCount:Inc
							; Increment MateriaInCount if materia within 22.5m of named
							if ${Math.Distance[${MateriaIterator.Value.X},${MateriaIterator.Value.Z},${CoppernicusLoc.X},${CoppernicusLoc.Z}]} < 22.5
								MateriaInCount:Inc
						}
						while ${MateriaIterator:Next(exists)}
					}
					; Check to see if Changing Thoery set to expire within 10 seconds
					if ${ChangingTheoryIncrements} > 0 && ${Math.Calc[${ChangingTheoryExpirationTimestamp.Timestamp}-${Time.Timestamp}]} <= 10
					{
						; Set TargetIncrements as ChangingTheoryIncrements
						TargetIncrements:Set[${ChangingTheoryIncrements}]
					}
					else
						; Set TargetIncrements as CentralFireIncrements
						TargetIncrements:Set[${CentralFireIncrements}]
					
					; **************************************
					; DEBUG TEXT
					;if ${Math.Calc[${ChangingTheoryExpirationTimestamp.Timestamp}-${Time.Timestamp}]} <= 2
					;{
					;	oc Increments CF:${CentralFireIncrements} CT:${ChangingTheoryIncrements} in ${Math.Calc[${ChangingTheoryExpirationTimestamp.Timestamp}-${Time.Timestamp}]} Tar:${TargetIncrements} OB:${OrbitingBodiesIncrements}
					;	oc Increments Mat Total:${MateriaTotalCount} Mat In:${MateriaInCount} Coppernicus target ${Actor[${CoppernicusTargetID}].Name}
					;}
					;oc Absorb Time: ${Math.Calc[${CoppernicusExpectedAbsorbTime.Timestamp}-${Time.Timestamp}]} Helio Time: ${Math.Calc[${CoppernicusExpectedHelioTime.Timestamp}-${Time.Timestamp}]}
					; **************************************
					
					; Update Joust locations based on current location of Coppernicus
					; 	Ring should be at 22.5m from Coppernicus (17m displayed distance, but +5.5 to account for difference between displayed and calculated distance)
					; 		so set In as 18.5 away and Out as 26.5 away
					; 	Arena is angled ~22 degrees off X axis
					JoustInLoc:Set[${CoppernicusLoc}]
					JoustInLoc.X:Dec[${Math.Calc[18.5*${Math.Cos[52]}]}]
					JoustInLoc.Z:Inc[${Math.Calc[18.5*${Math.Sin[52]}]}]
					JoustOutLoc:Set[${CoppernicusLoc}]
					JoustOutLoc.X:Dec[${Math.Calc[26.5*${Math.Cos[52]}]}]
					JoustOutLoc.Z:Inc[${Math.Calc[26.5*${Math.Sin[52]}]}]
					; Send fighter further in/out to keep celestial materia in/out as well
					FighterJoustInLoc:Set[${CoppernicusLoc}]
					FighterJoustInLoc.X:Dec[${Math.Calc[7*${Math.Cos[-68]}]}]
					FighterJoustInLoc.Z:Inc[${Math.Calc[7*${Math.Sin[-68]}]}]
					FighterJoustOutLoc:Set[${CoppernicusLoc}]
					FighterJoustOutLoc.X:Dec[${Math.Calc[40*${Math.Cos[22]}]}]
					FighterJoustOutLoc.Z:Inc[${Math.Calc[40*${Math.Sin[22]}]}]
					; Set PriestTankLoc within melee range of Coppernicus, but positioned to maximize range of spells for group
					PriestTankLoc:Set[${CoppernicusLoc}]
					PriestTankLoc.X:Dec[${Math.Calc[5*${Math.Cos[22]}]}]
					PriestTankLoc.Z:Inc[${Math.Calc[5*${Math.Sin[22]}]}]
					; Set FighterJoustOutPriestLoc
					; 	For when fighter is out, to still be within 25m of priest for heals
					PriestTankLoc:Set[${Actor[PC,"${CoppernicusPriestTank}"].Loc}]
					if ${PriestTankLoc.X}!=0 || ${PriestTankLoc.Y}!=0 || ${PriestTankLoc.Z}!=0
					{
						FighterJoustOutPriestLoc:Set[${PriestTankLoc}]
						FighterJoustOutPriestLoc.X:Dec[${Math.Calc[24*${Math.Cos[22]}]}]
						FighterJoustOutPriestLoc.Z:Inc[${Math.Calc[24*${Math.Sin[22]}]}]
					}
					; Clear JoustCharacterPositionSet
					GroupNum:Set[0]
					while ${GroupNum:Inc} <= ${JoustCharacter.Size}
					{
						JoustCharacterPositionSet[${GroupNum}]:Set[FALSE]
					}
					; Update fighter position as needed
					HelioDistance:Set[${OgreBotAPI.Get_Variable["${Me.Name}HelioDistance"]}]
					; If fighter has aggro, send to KillSpot
					if ${CoppernicusTargetID} == ${Me.ID}
					{
						; Send fighter to KillSpot
						oc !ci -ChangeCampSpotWho ${Me.Name} ${KillSpot.X} ${KillSpot.Y} ${KillSpot.Z}
						; Remove increment from TargetIncrements
						TargetIncrements:Dec
						; Remove MateriaTotalCount from TargetIncrements for materia, assuming all will be in
						TargetIncrements:Dec[${MateriaTotalCount}]
					}
					; If Helio set to expire within 10 seconds, move to HelioDistance away from Coppernicus
					elseif ${HelioDistance} > 0 && ${OgreBotAPI.Get_Variable["${Me.Name}HelioDuration"]} <= 10
					{
						; Set HelioLoc
						HelioLoc:Set[${CoppernicusLoc}]
						HelioLoc.X:Dec[${Math.Calc[${HelioDistance}*${Math.Cos[22]}]}]
						HelioLoc.Z:Inc[${Math.Calc[${HelioDistance}*${Math.Sin[22]}]}]
						; Send fighter to HelioLoc
						oc !ci -ChangeCampSpotWho ${Me.Name} ${HelioLoc.X} ${HelioLoc.Y} ${HelioLoc.Z}
						; Remove increment from TargetIncrements if HelioDistance < 22.5
						if ${HelioDistance} < 22.5
							TargetIncrements:Dec
						; Remove MateriaInCount from TargetIncrements for materia that are in range
						; 	This may fluctuate over time as materia are in the process of being moved, but handle based on what is the number right now
						TargetIncrements:Dec[${MateriaInCount}]
					}
					; If 6 or more increments are needed will want fighter in to draw celestial materia in as well
					elseif ${TargetIncrements} >= 6
					{
						; Send fighter to FighterJoustInLoc
						oc !ci -ChangeCampSpotWho ${Me.Name} ${FighterJoustInLoc.X} ${FighterJoustInLoc.Y} ${FighterJoustInLoc.Z}
						; Remove increment from TargetIncrements
						TargetIncrements:Dec
						; Remove MateriaTotalCount from TargetIncrements for materia, assuming all will be in
						TargetIncrements:Dec[${MateriaTotalCount}]
					}
					; If fewer increments are needed keep fighter and celestial materia out
					else
					{
						; Send fighter to FighterJoustOutPriestLoc if all materia are out
						if ${MateriaInCount} == 0
							oc !ci -ChangeCampSpotWho ${Me.Name} ${FighterJoustOutPriestLoc.X} ${FighterJoustOutPriestLoc.Y} ${FighterJoustOutPriestLoc.Z}
						; Otherwise fighter to FighterJoustOutLoc
						else
							oc !ci -ChangeCampSpotWho ${Me.Name} ${FighterJoustOutLoc.X} ${FighterJoustOutLoc.Y} ${FighterJoustOutLoc.Z}
					}
					; Send CoppernicusPriestTank or any character with aggro to KillSpot
					GroupNum:Set[0]
					while ${GroupNum:Inc} <= ${JoustCharacter.Size}
					{
						; Check to see if character is CoppernicusPriestTank or has aggro
						if ${JoustCharacter[${GroupNum}].Equal[${OgreBotAPI.Get_Variable["CoppernicusPriestTank"]}]} || ${CoppernicusTargetID} == ${Actor[PC,"${JoustCharacter[${GroupNum}]}"].ID}
						{
							; If character is CoppernicusPriestTank and Coppernicus is within 10m of Killspot, send to PriestTankLoc
							if ${JoustCharacter[${GroupNum}].Equal[${OgreBotAPI.Get_Variable["CoppernicusPriestTank"]}]} && ${Math.Distance[${CoppernicusLoc.X},${CoppernicusLoc.Z},${KillSpot.X},${KillSpot.Z}]} <= 10
								oc !ci -ChangeCampSpotWho ${JoustCharacter[${GroupNum}]} ${PriestTankLoc.X} ${PriestTankLoc.Y} ${PriestTankLoc.Z}
							; Otherwise send character to KillSpot
							else
								oc !ci -ChangeCampSpotWho ${JoustCharacter[${GroupNum}]} ${KillSpot.X} ${KillSpot.Y} ${KillSpot.Z}
							; Remove increment from TargetIncrements
							TargetIncrements:Dec
							; Set JoustCharacterPositionSet = TRUE for this character (so they don't get re-moved)
							JoustCharacterPositionSet[${GroupNum}]:Set[TRUE]
						}
					}
					; Make sure Changing Thoery not about to expire
					if ${ChangingTheoryIncrements} == -1 || ${Math.Calc[${ChangingTheoryExpirationTimestamp.Timestamp}-${Time.Timestamp}]} > 10
					{
						; Handle characters with Helio set to expire within 10 seconds
						GroupNum:Set[0]
						while ${GroupNum:Inc} <= ${JoustCharacter.Size}
						{
							; Skip if JoustCharacterPositionSet (position already handled)
							if ${JoustCharacterPositionSet[${GroupNum}]}
								continue
							; Check HelioDistance
							HelioDistance:Set[${OgreBotAPI.Get_Variable["${JoustCharacter[${GroupNum}]}HelioDistance"]}]
							if ${HelioDistance} > 0 && ${OgreBotAPI.Get_Variable["${JoustCharacter[${GroupNum}]}HelioDuration"]} <= 10
							{
								; Set HelioLoc
								HelioLoc:Set[${CoppernicusLoc}]
								HelioLoc.X:Dec[${Math.Calc[${HelioDistance}*${Math.Cos[52]}]}]
								HelioLoc.Z:Inc[${Math.Calc[${HelioDistance}*${Math.Sin[52]}]}]
								; Send character to HelioLoc
								oc !ci -ChangeCampSpotWho ${JoustCharacter[${GroupNum}]} ${HelioLoc.X} ${HelioLoc.Y} ${HelioLoc.Z}
								; Remove increment from TargetIncrements if HelioDistance < 22.5
								if ${HelioDistance} < 22.5
									TargetIncrements:Dec
								; Set JoustCharacterPositionSet = TRUE for this character (so they don't get re-moved)
								JoustCharacterPositionSet[${GroupNum}]:Set[TRUE]
							}
						}
					}
					; Joust remaining characters in/out as needed based on TargetIncrements
					GroupNum:Set[0]
					while ${GroupNum:Inc} <= ${JoustCharacter.Size}
					{
						; Skip if JoustCharacterPositionSet (position already handled)
						if ${JoustCharacterPositionSet[${GroupNum}]}
							continue
						; Send character in if there are remaining TargetIncrements
						if ${TargetIncrements:Dec} >= 0
							oc !ci -ChangeCampSpotWho ${JoustCharacter[${GroupNum}]} ${JoustInLoc.X} ${JoustInLoc.Y} ${JoustInLoc.Z}
						else
							oc !ci -ChangeCampSpotWho ${JoustCharacter[${GroupNum}]} ${JoustOutLoc.X} ${JoustOutLoc.Y} ${JoustOutLoc.Z}
					}
					; Check to see if anyone has Helio and update CoppernicusExpectedHelioTime if needed
					FoundHelio:Set[FALSE]
					if ${OgreBotAPI.Get_Variable["${Me.Name}HelioDistance"]} > 0
						FoundHelio:Set[TRUE]
					GroupNum:Set[0]
					while ${GroupNum:Inc} <= ${JoustCharacter.Size}
					{
						if ${OgreBotAPI.Get_Variable["${JoustCharacter[${GroupNum}]}HelioDistance"]} > 0
							FoundHelio:Set[TRUE]
					}
					; If FoundHelio and Helio was not previously active, update CoppernicusExpectedHelioTime
					; 	Expect every ~55 seconds to 1 minute 38 seconds
					; 	Duration ~15-24 seconds
					if ${FoundHelio} && !${HelioActive}
					{
						CoppernicusExpectedHelioTime:Set[${Time.Timestamp}]
						CoppernicusExpectedHelioTime.Second:Inc[55]
						CoppernicusExpectedHelioTime.Second:Inc[15]
						CoppernicusExpectedHelioTime:Update
						
						; ***************************************************************
						; DEBUG TEXT
						;oc Helio time set to ${CoppernicusExpectedHelioTime}
						; ***************************************************************
						
					}
					; Update HelioActive
					HelioActive:Set[${FoundHelio}]
					; Enable/disable dps as needed
					; 	Changing Theory occurs every 10% HP (~91%, 81% etc.)
					; 	Don't want it to expire at the same time as Helio expiration
					; 	So hold dps when about to trigger Changing Theory until a time when it is safe to do so
					DPSAllowed:Set[TRUE]
					; Check to see if Changing Theory is not active (if already active no reason to stop dps)
					if ${ChangingTheoryIncrements} == -1
					{
						; Check to see if Coppernicus HP is close to next trigger point (should be when the remainder is 1)
						; 	Health%10 gives the remainder after dividing by 10 (e.g. 74%10 = 4)
						CoppernicusHPRemainder:Set[${Math.Calc[${Actor[${CoppernicusID}].Health}%10]}]
						if ${CoppernicusHPRemainder} > 0 && ${CoppernicusHPRemainder} <= 3
						{
							; If anyone has Helio with Duration > 5 seconds, set DPSAllowed = FALSE
							if ${OgreBotAPI.Get_Variable["${Me.Name}HelioDistance"]} > 0 && ${OgreBotAPI.Get_Variable["${Me.Name}HelioDuration"]} > 5
								DPSAllowed:Set[FALSE]
							GroupNum:Set[0]
							while ${GroupNum:Inc} <= ${JoustCharacter.Size}
							{
								if ${OgreBotAPI.Get_Variable["${JoustCharacter[${GroupNum}]}HelioDistance"]} > 0 && ${OgreBotAPI.Get_Variable["${JoustCharacter[${GroupNum}]}HelioDuration"]} > 5
									DPSAllowed:Set[FALSE]
							}
							; If CoppernicusExpectedHelioTime not more than 25 seconds into the future, set DPSAllowed = FALSE
							; 	Have seen instances where Helio just never happened initially so if past a minute overdue assume it won't happen
							if ${Math.Calc[${CoppernicusExpectedHelioTime.Timestamp}-${Time.Timestamp}]} >= -60 && ${Math.Calc[${CoppernicusExpectedHelioTime.Timestamp}-${Time.Timestamp}]} <= 25
								DPSAllowed:Set[FALSE]
						}
					}
					; Check to see if there is a mismatch between DPSEnabled and DPSAllowed (^ is XOR, exclusive OR)
					if ${DPSEnabled}^${DPSAllowed}
					{
						
						; *********************************************
						; DEBUG TEXT
						;if ${DPSAllowed}
						;	oc Start DPS - CT increments ${ChangingTheoryIncrements} - HP ${CoppernicusHPRemainder} - Absorb ${Math.Calc[${CoppernicusExpectedAbsorbTime.Timestamp}-${Time.Timestamp}]} - Helio ${Math.Calc[${CoppernicusExpectedHelioTime.Timestamp}-${Time.Timestamp}]}
						;else
						;	oc Stop DPS - CT increments ${ChangingTheoryIncrements} - HP ${CoppernicusHPRemainder} - Absorb ${Math.Calc[${CoppernicusExpectedAbsorbTime.Timestamp}-${Time.Timestamp}]} - Helio ${Math.Calc[${CoppernicusExpectedHelioTime.Timestamp}-${Time.Timestamp}]}
						; *********************************************
						
						; Enable/disable CA's (on non-fighters because fighter is attacking celestial materia)
						oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-fighter checkbox_settings_disablecaststack_ca ${DPSEnabled} TRUE
						oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-fighter checkbox_settings_disablecaststack_namedca ${DPSEnabled} TRUE
						oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-fighter+-priest checkbox_settings_disablecaststack_combat ${DPSEnabled} TRUE
						oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-fighter checkbox_settings_disablecaststack_debuff ${DPSEnabled} TRUE
						oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-fighter checkbox_settings_disablecaststack_nameddebuff ${DPSEnabled} TRUE
						; Update DPSEnabled
						DPSEnabled:Set[${DPSAllowed}]
					}
				}
				; Reset SecondLoopCount
				SecondLoopCount:Set[0]
			}
			; Short wait before looping (to respond as quickly as possible to events)
			wait 1
			; Update CoppernicusExists every 3 seconds
			if ${CoppernicusExistsCount:Inc} >= 30
			{
				call CheckCoppernicusExists
				CoppernicusExistsCount:Set[0]
			}
		}
		
		; Detach Atoms
		Event[EQ2_onIncomingChatText]:DetachAtom[CoppernicusIncomingChatText]
		
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
	
	function CheckCoppernicusExists()
	{
		; Assume CoppernicusExists if in Combat
		if ${Me.InCombat}
		{
			CoppernicusExists:Set[TRUE]
			return
		}
		; Check to see if Coppernicus exists
		if ${Actor[Query,Name=="Coppernicus" && Type != "Corpse"].ID(exists)}
		{
			CoppernicusExists:Set[TRUE]
			return
		}
		; Coppernicus not found
		CoppernicusExists:Set[FALSE]
	}
	
	function SetupCoppernicus(bool EnableCoppernicus)
	{
		; Setup Cures
		variable bool SetDisable
		SetDisable:Set[!${EnableCoppernicus}]
		call SetupAllCures "${SetDisable}"
		; Set initial HO settings
		call SetInitialHOSettings
		; Disable Assist, helper script will selectively target per character
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-fighter checkbox_settings_assist ${SetDisable} TRUE
		; Disable PBAE abilities during the fight (want to keep aggro split between Coppernicus and celestial materia)
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_donotsave_dynamicignorepbae ${EnableCoppernicus} TRUE
		; Setup Interrupts (will selectively interrupt as needed so don't want abilities on cooldown)
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_nointerrupts ${EnableCoppernicus} TRUE
		; Disable abilities that may cause problems with named movement/direction
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+swashbuckler "Walk the Plank" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+beastlord "Noxious Grasp" ${SetDisable} TRUE
		; Disable pets (Coppernicus does not like having pets as his main target)
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_donotsendpettoattack ${EnableCoppernicus} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+ranger "Hawk Attack" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+ranger "Sniper Squad" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+swashbuckler "Shadow" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+coercer "Puppetmaster" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+beastlord "Animalistic Intent" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+beastlord "Savage Allies" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Ancestral Sentry" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Lunar Attendant" ${SetDisable} TRUE
		; Disable priest dps (want to focus on healing/curing)
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Rabies" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Polar Fire" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Wrath of the Ancients" ${SetDisable} TRUE
		; Setup class-specific abilities to use during HO's
		; 	Don't want these abilities to be on a cool down when trying to use them
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Plague" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Velium Winds" ${SetDisable} TRUE
		; Disable threat priority and hate reduction abilities
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name} "Shadow Slip" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name} "Evade" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+mystic "Spirits" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+swashbuckler "Sleight of Hand" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+coercer "Mind Control" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+coercer "Thought Snap" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+coercer "Coercive Shout" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+coercer "Peaceful Link" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+coercer "Sever Hate" ${SetDisable} TRUE
		wait 1
		if ${EnableCoppernicus}
			oc !ci -CancelMaintainedForWho igw:${Me.Name}+coercer "Peaceful Link"
		; Disable all hate transfers
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+dirge "Hyran's Seething Sonata" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+swashbuckler "Swarthy Deception" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+coercer "Enraging Demeanor" ${SetDisable} TRUE
		oc !ci -ChangeCastStackListBoxItem igw:${Me.Name}+assassin "Murderous Design" ${SetDisable} TRUE
		wait 1
		if ${EnableCoppernicus}
		{
			oc !ci -CancelMaintainedForWho igw:${Me.Name}+dirge "Hyran's Seething Sonata"
			oc !ci -CancelMaintainedForWho igw:${Me.Name}+swashbuckler "Swarthy Deception"
			oc !ci -CancelMaintainedForWho igw:${Me.Name}+coercer "Enraging Demeanor"
			oc !ci -CancelMaintainedForWho igw:${Me.Name}+assassin "Murderous Design"
		}
	}

/**********************************************************************************************************
 	Named 4 *********************    Move to, spawn and kill - Goldfeather ********************************
***********************************************************************************************************/

	; Setup Variables needed outside Named4 function
	variable bool GoldfeatherExists
	
	function:bool Named4(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[602.36,248.94,416.31]
		
		; Undo Coppernicus custom settings
		call SetupCoppernicus "FALSE"
		
		; Disable cures (don't need to start curing on the way to named)
		call SetupAllCures "FALSE"
		
		; Set Loot settings for last boss (not the last boss, but may drop NO-TRADE Bell)
		call SetLootForLastBoss
		
		; Setup variables
		variable int GroupNum
		variable int Counter
		variable int GoldfeatherExistsCount=0
		variable string PhylacteryCharacter[3]
		variable string HOMage
		variable actor Aurumutation
		
		; Swap immunity runes (stun on fighter/scout, stifle on mage/priest)
		call mend_and_rune_swap "stun" "stun" "stifle" "stifle"
		
		; Setup for named
		call initialize_move_to_next_boss "${_NamedNPC}" "4"
		
		; Enable PreCastTag to allow priest to setup wards before engaging first mob
		oc !ci -AbilityTag igw:${Me.Name} "PreCastTag" "6" "Allow"
		wait 60
		
		; Move to named from Coppernicus
		if !${GoldfeatherRespawn}
		{
			call move_to_next_waypoint "850.84,329.15,95.23"
			call move_to_next_waypoint "854.30,321.05,18.23"
			call move_to_next_waypoint "736.48,312.70,53.18"
			call EnterPortal "teleporter_upper" "Teleport"
		}
		; Otherwise move from respawn point
		else
		{
			call move_to_next_waypoint "737.94,274.65,504.15"
			call move_to_next_waypoint "758.30,284.21,476.69"
			call move_to_next_waypoint "775.99,291.62,455.75"
			call move_to_next_waypoint "809.41,309.21,407.65"
			call move_to_next_waypoint "811.31,319.28,362.22"
			call move_to_next_waypoint "810.53,321.43,325.36"
			call move_to_next_waypoint "780.69,322.19,287.77"
			call move_to_next_waypoint "743.99,275.50,254.98"
		}
		
		; Continue to Goldfeather
		call move_to_next_waypoint "713.45,276.07,235.17"
		call move_to_next_waypoint "662.90,275.51,253.26"
		call move_to_next_waypoint "625.39,260.31,286.42"
		
		; Check if already killed
		call CheckGoldfeatherExists
		
		; Skip if already killed
		if !${GoldfeatherExists}
		{
			Obj_OgreIH:Message_NamedDoesNotExistSkipping["${_NamedNPC}"]
			call move_to_next_waypoint "570.64,256.26,287.82"
			call move_to_next_waypoint "519.36,256.88,303.53"
			call move_to_next_waypoint "473.40,256.21,340.62"
			call move_to_next_waypoint "459.97,257.38,393.92"
			call move_to_next_waypoint "480.87,252.34,437.96"
			call move_to_next_waypoint "495.92,261.01,484.20"
			call move_to_next_waypoint "554.29,250.88,493.65"
			call move_to_next_waypoint "609.51,251.40,496.74"
			call move_to_next_waypoint "592.45,249.94,433.45"
			call move_to_next_waypoint "${KillSpot}"
			return TRUE
		}
		
		; Determine characters that will use each Phylactery
		; 	Prefer fighters and scouts
		PhylacteryCharacter[1]:Set[${Me.Name}]
		GroupNum:Set[0]
		Counter:Set[1]
		while ${GroupNum:Inc} < ${Me.GroupCount} && ${Counter} <= ${PhylacteryCharacter.Size}
		{
			; Check if fighter or scout
			call GetArchetypeFromClass "${Me.Group[${GroupNum}].Class}"
			if ${Return.Equal["fighter"]} || ${Return.Equal["scout"]}
				PhylacteryCharacter[${Counter:Inc}]:Set["${Me.Group[${GroupNum}].Name}"]
		}
		GroupNum:Set[0]
		while ${GroupNum:Inc} < ${Me.GroupCount} && ${Counter} <= ${PhylacteryCharacter.Size}
		{
			; Check if mage or priest
			call GetArchetypeFromClass "${Me.Group[${GroupNum}].Class}"
			if ${Return.Equal["mage"]} || ${Return.Equal["priest"]}
				PhylacteryCharacter[${Counter:Inc}]:Set["${Me.Group[${GroupNum}].Name}"]
		}
		
		; Determine HOMage
		GroupNum:Set[0]
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			; Check if mage
			call GetArchetypeFromClass "${Me.Group[${GroupNum}].Class}"
			if ${Return.Equal["mage"]}
			{
				HOMage:Set["${Me.Group[${GroupNum}].Name}"]
				break
			}
		}
		
		; Set variables to use in helper script
		oc !ci -Set_Variable igw:${Me.Name} "PhylacteryCharacter1" "${PhylacteryCharacter[1]}"
		oc !ci -Set_Variable igw:${Me.Name} "PhylacteryCharacter2" "${PhylacteryCharacter[2]}"
		oc !ci -Set_Variable igw:${Me.Name} "PhylacteryCharacter3" "${PhylacteryCharacter[3]}"
		oc !ci -Set_Variable igw:${Me.Name} "PhylacteryCharacter1HasPhylactery" "FALSE"
		oc !ci -Set_Variable igw:${Me.Name} "PhylacteryCharacter2HasPhylactery" "FALSE"
		oc !ci -Set_Variable igw:${Me.Name} "PhylacteryCharacter3HasPhylactery" "FALSE"
		oc !ci -Set_Variable igw:${Me.Name} "HOMage" "${HOMage}"
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}HasCurse" "FALSE"
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}DispelTargetID" "0"
		GroupNum:Set[0]
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			oc !ci -Set_Variable igw:${Me.Name} "${Me.Group[${GroupNum}].Name}HasCurse" "FALSE"
			oc !ci -Set_Variable igw:${Me.Name} "${Me.Group[${GroupNum}].Name}DispelTargetID" "0"
		}
		wait 1
		
		; Set custom settings for Goldfeather
		call SetupGoldfeather "TRUE"
		
		; Run HOHelperScript to help complete HO's
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${HOHelperScript} "InZone"
		
		; Run ZoneHelperScript
		oc !ci -EndScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript}
		oc !ci -RunScriptRequiresOgreBot igw:${Me.Name} ${ZoneHelperScript} "${_NamedNPC}"
		
		; Let script run for a couple of seconds to update HasCurse for each character
		wait 20
		
		; Pull "an aurumutation" mobs and dispel them as needed to get Mutagenesis Disease curse on everyone in the group
		call CheckGoldfeatherNeedCurse
		while ${Return}
		{
			; Pull "an aurumutation" mobs and dispel them as needed to get Mutagenesis Disease curse on a character missing it
			call PullAurumutation
			; Check again to see if anyone else needs curse
			call CheckGoldfeatherNeedCurse
		}
		
		; Wait for goldfeather to be clear of path to island
		while !${Actor[Query,Name=="Goldfeather" && Type != "Corpse" && (X < 580 || X > 640)].ID(exists)}
		{
			wait 10
		}
		
		; Disable CA on priests (may aggro extra aurumutations and have characters die because they have the Mutagenesis Disease, just don't want the priests to die)
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+priest checkbox_settings_disablecaststack_ca TRUE TRUE
		
		; Move to island
		call move_to_next_waypoint "621.33,261.04,318.36"
		call move_to_next_waypoint "616.91,245.72,340.46"
		call move_to_next_waypoint "615.65,246.03,364.73"
		call move_to_next_waypoint "615.26,246.17,392.98"
		call move_to_next_waypoint "${KillSpot}"
		
		; Get Phylacterys
		call CheckGoldfeatherNeedPhylactery
		while ${Return}
		{
			; Move to Phylactery location and have characters grab it
			call GetPhylactery
			; Check again to see if anyone else needs curse
			call CheckGoldfeatherNeedPhylactery
		}
		
		; Kill any auramutation around KillSpot
		Aurumutation:Set[${Actor[Query,Name=="an aurumutation" && Type != "Corpse" && Distance < 35].ID}]
		while ${Aurumutation.ID(exists)}
		{
			; Pause Ogre
			oc !ci -Pause igw:${Me.Name}
			wait 1
			; Pull Aurumutation
			Aurumutation:DoTarget
			wait 5
			; Pet pull aurumutation
			while ${Aurumutation.Target.ID} == 0
			{
				relay ${OgreRelayGroup} eq2execute pet attack
				wait 10
			}
			; Wait for aurumutation to be pulled back to group
			while ${Aurumutation.Distance} > 25
			{
				oc !ci -PetOff igw:${Me.Name}
				wait 10
			}
			; Resume
			oc !ci -Resume igw:${Me.Name}
			; Kill aurumutation
			Aurumutation:DoTarget
			oc !ci -PetAssist igw:${Me.Name}
			while ${Aurumutation.ID(exists)}
			{
				wait 10
			}
			call Obj_OgreUtilities.HandleWaitForCombat
			call Obj_OgreUtilities.WaitWhileGroupMembersDead
			wait 10
			; Update Aurumutation
			Aurumutation:Set[${Actor[Query,Name=="an aurumutation" && Type != "Corpse" && Distance < 35].ID}]
		}
		
		; Repair if needed (may have had some extra deaths killing auramutations)
		call mend_and_rune_swap "noswap" "noswap" "noswap" "noswap"
		
		; Wait for Goldfeather to path near KillSpot
		while !${Actor[Query,Name=="Goldfeather" && Type != "Corpse" && Distance < 70].ID(exists)}
		{
			wait 10
		}
		
		; Enable PreCastTag to allow priest to setup wards before engaging named
		oc !ci -AbilityTag igw:${Me.Name} "PreCastTag" "6" "Allow"
		wait 60
		
		; Handle text events
		Event[EQ2_onIncomingText]:AttachAtom[GoldfeatherIncomingText]
		Event[EQ2_onIncomingChatText]:AttachAtom[GoldfeatherIncomingChatText]
		
		; Pull Named
		Ob_AutoTarget:Clear
		oc ${Me.Name} is pulling ${_NamedNPC}
		
		; Use Goldfeather's Phylactery on all characters to pull named
		wait 20
		oc !ci -UseItem igw:${Me.Name} "Goldfeather's Phylactery"
		wait 20
		
		; Re-enable CA on priests
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+priest checkbox_settings_disablecaststack_ca FALSE TRUE
		
		; Enable AutoTarget (but disable Out of Combat scanning)
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_autotarget_outofcombatscanning FALSE TRUE
		wait 1
		Ob_AutoTarget:AddActor["an aurumutation",0,FALSE,FALSE]
		Ob_AutoTarget:AddActor["${_NamedNPC}",0,FALSE,FALSE]
		
		; Kill named
		; 	There are a lot of detrimentals to cure and spells to interrupt that are all handled in the helper script
		while ${GoldfeatherExists}
		{
			; Handle Plume Boom incoming
			; 	Will cause damage and knock up to characters around fighter
			; 	Move fighter away from group to avoid it
			if ${GoldfeatherPlumeBoomIncoming}
			{
				; Move fighter away from group
				oc !ci -ChangeCampSpotWho igw:${Me.Name}+fighter 592.81 249.32 427.72
				; Handled GoldfeatherPlumeBoomIncoming
				GoldfeatherPlumeBoomIncoming:Set[FALSE]
			}
			; Handle Plume Boom cast
			; 	After Plume Boom gets cast, move fighter back to group
			if ${GoldfeatherPlumeBoomCast}
			{
				; Move fighter back to KillSpot
				oc !ci -ChangeCampSpotWho igw:${Me.Name}+fighter ${KillSpot.X} ${KillSpot.Y} ${KillSpot.Z}
				; Handled GoldfeatherPlumeBoomCast
				GoldfeatherPlumeBoomCast:Set[FALSE]
			}
			; Short wait before looping (to respond as quickly as possible to events)
			wait 1
			; Update GoldfeatherExists every 3 seconds
			if ${GoldfeatherExistsCount:Inc} >= 30
			{
				call CheckGoldfeatherExists
				GoldfeatherExistsCount:Set[0]
			}
		}
		
		; Detach Atoms
		Event[EQ2_onIncomingText]:DetachAtom[GoldfeatherIncomingText]
		Event[EQ2_onIncomingChatText]:DetachAtom[GoldfeatherIncomingChatText]
		
		; Reset AutoTarget
		Ob_AutoTarget:Clear
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_autotarget_outofcombatscanning TRUE TRUE
		
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
		
		; Finished with named
		return TRUE
	}
	
	function CheckGoldfeatherExists()
	{
		; Assume GoldfeatherExists if in Combat
		if ${Me.InCombat}
		{
			GoldfeatherExists:Set[TRUE]
			return
		}
		; Check to see if Goldfeather exists
		if ${Actor[Query,Name=="Goldfeather" && Type != "Corpse"].ID(exists)}
		{
			GoldfeatherExists:Set[TRUE]
			return
		}
		; Goldfeather not found
		GoldfeatherExists:Set[FALSE]
	}
	
	function SetupGoldfeather(bool EnableGoldfeather)
	{
		; Setup Cures
		variable bool SetDisable
		SetDisable:Set[!${EnableGoldfeather}]
		call SetupAllCures "${SetDisable}"
		; Set initial HO settings
		call SetInitialHOSettings
		; Disable mage lightning and star HO icon abilities so they are available when mage needs to complete an HO
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+mage checkbox_settings_disable_mage_hoicon_25 ${EnableGoldfeather} TRUE
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+mage checkbox_settings_disable_mage_hoicon_29 ${EnableGoldfeather} TRUE
		; Disable PBAE abilities (don't want to aggro extra roaming aurumutation mobs)
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_donotsave_dynamicignorepbae ${EnableGoldfeather} TRUE
		; Setup Interrupts (will selectively interrupt as needed so don't want abilities on cooldown)
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_nointerrupts ${EnableGoldfeather} TRUE
		; Set Auto Target Out of Combat scanning to enabled by default
		oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+fighter checkbox_autotarget_outofcombatscanning TRUE TRUE
	}
	
	function CheckGoldfeatherNeedCurse()
	{
		; Check to see if anyone in the group is missing Curse
		if !${OgreBotAPI.Get_Variable["${Me.Name}HasCurse"]}
			return TRUE
		variable int GroupNum=0
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			if !${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}HasCurse"]}
				return TRUE
		}
		; No one found that still needs curse, return FALSE
		return FALSE
	}
	
	function PullAurumutation()
	{
		; Target self to avoid fighting aurumutation at first
		Me:DoTarget
		; Setup variables
		variable int GroupNum=0
		variable index:actor Aurumutation
		variable iterator AurumutationIterator
		variable actor TargetAurumutation
		variable string PullCharacter
		; Query all aurumutation mobs within 150m
		EQ2:QueryActors[Aurumutation, Name=="an aurumutation" && Type != "Corpse" && X > 620 && Distance < 150]
		Aurumutation:GetIterator[AurumutationIterator]
		if ${AurumutationIterator:First(exists)}
		{
			; Loop through each aurumutation
			do
			{
				; If TargetAurumutation doesn't exist, set it
				if !${TargetAurumutation.ID(exists)}
					TargetAurumutation:Set[${AurumutationIterator.Value.ID}]
				; Otherwise if aurumutation is in combat, set as the target and stop search
				elseif ${AurumutationIterator.Value.Target.ID} != 0
				{
					TargetAurumutation:Set[${AurumutationIterator.Value.ID}]
					break
				}
				; Otherwise set as target if closer
				elseif ${AurumutationIterator.Value.Distance} < ${TargetAurumutation.Distance}
					TargetAurumutation:Set[${AurumutationIterator.Value.ID}]
			}
			while ${AurumutationIterator:Next(exists)}
		}
		; Make sure TargetAurumutation exists
		if !${TargetAurumutation.ID(exists)}
			return
		; Get group member that does not have curse
		if !${OgreBotAPI.Get_Variable["${Me.Name}HasCurse"]}
			PullCharacter:Set["${Me.Name}"]
		while ${GroupNum:Inc} < ${Me.GroupCount}
		{
			if ${PullCharacter.Length} == 0 && !${OgreBotAPI.Get_Variable["${Me.Group[${GroupNum}].Name}HasCurse"]}
				PullCharacter:Set["${Me.Group[${GroupNum}].Name}"]
		}
		; If PullCharacter is empty and TargetAurumutation is not in combat, exit
		if ${PullCharacter.Length} == 0 && ${TargetAurumutation.Target.ID} == 0
			return
		; If PullCharacter is empty and TargetAurumutation is in combat, cure curse from this character and use as PullCharacter
		if ${PullCharacter.Length} == 0 && ${TargetAurumutation.Target.ID} != 0
		{
			; Cure curse from this character
			while ${OgreBotAPI.Get_Variable["${Me.Name}HasCurse"]}
			{
				oc !ci -AutoCurse igw:${Me.Name} ${Me.Name}
				wait 50
			}
			; Set this character as PullCharacter
			PullCharacter:Set[${Me.Name}]
		}
		; Pause Ogre
		oc !ci -Pause igw:${Me.Name}
		wait 1
		; Pull TargetAurumutation
		TargetAurumutation:DoTarget
		wait 5
		; Pet pull aurumutation
		while ${TargetAurumutation.Target.ID} == 0
		{
			relay ${OgreRelayGroup} eq2execute pet attack
			wait 10
		}
		; Wait for aurumutation to be pulled back to group
		while ${TargetAurumutation.Distance} > 15
		{
			oc !ci -PetOff igw:${Me.Name}
			wait 10
		}
		; Target self again (don't want to attack TargetAurumutation until it is dispelled)
		Me:DoTarget
		wait 5
		; Resume 
		oc !ci -Resume igw:${Me.Name}
		; Set DispelTargetID
		oc !ci -Set_Variable igw:${Me.Name} "${PullCharacter}DispelTargetID" "${TargetAurumutation.ID}"
		; Wait for PullCharacter to dispel the aurumutation from helper script
		do
		{
			call GetActorEffectIncrements "${TargetAurumutation.ID}" "Metallic Mutagenesis" "2"
			wait 10
		}
		while ${Return} == 0
		; Kill aurumutation
		TargetAurumutation:DoTarget
		oc !ci -PetAssist igw:${Me.Name}
		while ${TargetAurumutation.ID(exists)}
		{
			wait 10
		}
		call Obj_OgreUtilities.HandleWaitForCombat
		call Obj_OgreUtilities.WaitWhileGroupMembersDead
		wait 10
	}
	
	function CheckGoldfeatherNeedPhylactery()
	{
		; Check to see if Phylactery character is missing the Phylactery
		if !${OgreBotAPI.Get_Variable["PhylacteryCharacter1HasPhylactery"]} || !${OgreBotAPI.Get_Variable["PhylacteryCharacter2HasPhylactery"]} || !${OgreBotAPI.Get_Variable["PhylacteryCharacter3HasPhylactery"]}
			return TRUE
		; No one found that still needs Phylactery, return FALSE
		return FALSE
	}
	
	function GetPhylactery()
	{
		; Setup variables
		variable index:actor Phylacterys
		variable iterator PhylacteryIterator
		variable point3f PhylacteryLoc
		variable point3f TravelSpots[6]
		variable int Counter
		variable float Slope
		variable float Intercept
		variable float NewX
		variable float NewZ
		variable point3f GoldfeatherLoc
		variable float GoldfeatherHeading
		variable int NumSteps
		variable bool CollisionFound=FALSE
		variable actor ClosestSafePhylactery
		variable float CurrentY
		
		; Search for any Goldfeather's phylactery
		EQ2:QueryActors[Phylacterys, Name=="Goldfeather's phylactery" && Type == "NoKill NPC"]
		Phylacterys:GetIterator[PhylacteryIterator]
		if ${PhylacteryIterator:First(exists)}
		{
			; Loop through Phylacterys
			do
			{
				; Get phylactery Location, make sure it is valid
				PhylacteryLoc:Set[${PhylacteryIterator.Value.Loc}]
				if ${PhylacteryLoc.X}==0 && ${PhylacteryLoc.Y}==0 && ${PhylacteryLoc.Z}==0
					continue
				; Setup list of points between KillSpot and phylactery
				Slope:Set[(${PhylacteryLoc.Z}-${KillSpot.Z})/(${PhylacteryLoc.X}-${KillSpot.X})]
				Intercept:Set[${KillSpot.Z}-${Slope}*${KillSpot.X}]
				Counter:Set[0]
				while ${Counter:Inc} <= ${TravelSpots.Size}
				{
					NewX:Set[${KillSpot.X}+(${PhylacteryLoc.X}-${KillSpot.X})*((${Counter}-1)/(${TravelSpots.Size}-1))]
					NewZ:Set[${Slope}*${NewX}+${Intercept}]
					TravelSpots[${Counter}]:Set[${NewX},${KillSpot.Y},${NewZ}]
				}
				; Default to no CollisionFound
				CollisionFound:Set[FALSE]
				; Get Goldfeather Location and Heading, make sure they are valid
				GoldfeatherLoc:Set[${Actor[Query,Name=="Goldfeather" && Type != "Corpse"].Loc}]
				GoldfeatherHeading:Set[${Actor[Query,Name=="Goldfeather" && Type != "Corpse"].Heading}]
				if ${GoldfeatherLoc.X}==0 && ${GoldfeatherLoc.Y}==0 && ${GoldfeatherLoc.Z}==0
					continue
				; See if Goldfeather is on a collision path with KillSpot or any TravelSpot
				NumSteps:Set[-1]
				while ${NumSteps:Inc} <= 10
				{
					; Calculate future Location of Goldfeather moving 5m * NumSteps
					NewLoc:Set[${GoldfeatherLoc.X},${GoldfeatherLoc.Y},${GoldfeatherLoc.Z}]
					NewLoc.X:Dec[5*${NumSteps}*${Math.Sin[${GoldfeatherHeading}]}]
					NewLoc.Z:Dec[5*${NumSteps}*${Math.Cos[${GoldfeatherHeading}]}]
					; Check to see if Distance is within 50m of KillSpot
					if ${Math.Distance[${KillSpot.X},${KillSpot.Z},${NewLoc.X},${NewLoc.Z}]} < 50
						CollisionFound:Set[TRUE]
					; Check to see if Distance is within 50m of a TravelSpot
					Counter:Set[0]
					while ${Counter:Inc} <= ${TravelSpots.Size}
					{
						if ${Math.Distance[${TravelSpots[${Counter}].X},${TravelSpots[${Counter}].Z},${NewLoc.X},${NewLoc.Z}]} < 50
							CollisionFound:Set[TRUE]
					}
					; Stop search if CollisionFound
					if ${CollisionFound}
						break
				}
				; Update ClosestSafePhylactery if no CollisionFound and not set or phylactery is closer
				if !${CollisionFound} && (${ClosestSafePhylactery.ID} == 0 || ${PhylacteryIterator.Value.Distance} < ${ClosestSafePhylactery.Distance})
					ClosestSafePhylactery:Set[${PhylacteryIterator.Value.ID}]
			}
			while ${PhylacteryIterator:Next(exists)}
		}
		; Exit if no safe phylactery (wait a second first before checking again)
		if ${ClosestSafePhylactery.ID} == 0
		{
			wait 10
			return
		}
		; Send characters to phylactery
		Counter:Set[0]
		while ${Counter:Inc} <= ${TravelSpots.Size}
		{
			; Move to TravelSpot
			call move_to_next_waypoint "${TravelSpots[${Counter}]}"
			; Swim down to bottom of lake
			CurrentY:Set[${Me.Y}]
			oc !ci -FlyDown igw:${Me.Name}
			wait 10
			while ${Me.Y} != ${CurrentY}
			{
				CurrentY:Set[${Me.Y}]
				wait 10
			}
			oc !ci -FlyStop igw:${Me.Name}
			; Move to TravelSpot (again, just to make sure handle combat for anything new aggroed before moving on)
			call move_to_next_waypoint "${TravelSpots[${Counter}]}"
		}
		; Wait until ClosestSafePhylactery no longer exists (up to 10 seconds)
		Counter:Set[0]
		while ${ClosestSafePhylactery.ID(exists)} && ${Counter:Inc} <= 10
		{
			wait 10
		}
		; Send characters back to KillSpot
		Counter:Set[${Math.Calc[${TravelSpots.Size}+1]}]
		while ${Counter:Dec} > 0
		{
			call move_to_next_waypoint "${TravelSpots[${Counter}]}"
		}
	}

/**********************************************************************************************************
 	Named 5 *********************    Move to, spawn and kill - ??? ***********************
***********************************************************************************************************/

	function:bool Named5(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[0,0,0]
		
		; Undo Goldfeather custom settings
		call SetupGoldfeather "FALSE"
		
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
	; 	Happens at 76%, 51%, 26%
	elseif ${Text.Find["Nugget begins to absorb your armor"]}
		NuggetAbsorbAndCrushArmorIncoming:Set[TRUE]
	; Look for message that All Mine is incoming
	; Nugget is about to collapse! You almost here it whisper, "All mine!"
	; Nugget is about to collapse!
	elseif ${Text.Find["Nugget is about to collapse!"]}
		NuggetAllMineIncoming:Set[TRUE]
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

atom CoppernicusIncomingChatText(int ChatType, string Message, string Speaker, string TargetName, string SpeakerIsNPC, string ChannelName)
{
	; Look for message that Changing Theory will happen soon
	; 	In 15 seconds, The Central Fire will require a new amount based on Coppernicus' Changing Theory!
	; 	Coppernicus says, "Nope, these numbers don't add up."
	; 	Coppernicus says, "Nope, this just won't do."
	; 	Coppernicus reconsiders his current theory.
	if ${Message.Find["reconsiders his current theory."]}
	{
		ChangingTheoryExpirationTimestamp:Set[${Time.Timestamp}]
		ChangingTheoryExpirationTimestamp.Second:Inc[15]
		ChangingTheoryExpirationTimestamp:Update
	}
	
	; Debug text to see messages
	;echo ${ChatType}, ${Message}, ${Speaker}, ${TargetName}, ${SpeakerIsNPC}, ${ChannelName}
}

atom GoldfeatherIncomingText(string Text)
{
	; Look for message that Plume Boom has been cast
	if ${Text.Find["As a fighter, you avoid getting knocked back by Plume Boom!"]}
		GoldfeatherPlumeBoomCast:Set[TRUE]
}

atom GoldfeatherIncomingChatText(int ChatType, string Message, string Speaker, string TargetName, string SpeakerIsNPC, string ChannelName)
{
	; Look for message that Plume Boom is being cast
	; 	Goldfeather targets <Target> and those around them to go boom!
	if ${Message.Find["and those around them to go boom!"]}
		GoldfeatherPlumeBoomIncoming:Set[TRUE]
	
	; Debug text to see messages
	;echo ${ChatType}, ${Message}, ${Speaker}, ${TargetName}, ${SpeakerIsNPC}, ${ChannelName}
}
