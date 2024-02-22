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
	
	; Variables for Phase 1
	variable int SpotNum=1
	variable point3f BanditSpot[9]
	variable int TimeSinceBanditKill=0
	; Variables for Phase 2
	variable float MinArenaX=780
	variable float MaxArenaX=820
	variable float MinArenaZ=-190
	variable float MaxArenaZ=-90
	variable point3f CurrentArenaPoint
	variable point3f NewArenaPoint[3,3]
	variable float ArenaPointAeraquisDistance[3,3]
	variable float MinAeraquisDistance
	variable point3f MinArenaPoint
	variable int PointX
	variable int PointZ
	variable int PreviousPetTargetID=-1
	
	function:bool Named1(string _NamedNPC="Doesnotexist")
	{
		; Update KillSpot
		KillSpot:Set[774.73,207.03,-150.32]
		
		; Update Variable default values
		AuromQuickCurseIncoming:Set[FALSE]
		AurumPhaseNum:Set[1]
		
		; Update BanditSpots
		BanditSpot[1]:Set[861.36,202.50,-80.17]
		BanditSpot[2]:Set[838.65,200.09,-100.14]
		BanditSpot[3]:Set[804.56,202.35,-99.89]
		BanditSpot[4]:Set[${KillSpot}]
		BanditSpot[5]:Set[783.44,207.31,-180.44]
		BanditSpot[6]:Set[806.55,206.81,-191.10]
		BanditSpot[7]:Set[807.62,202.02,-166.71]
		BanditSpot[8]:Set[821.56,207.15,-143.65]
		
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
		
		; Kill first 3 bandits (don't move to third one because don't want to accidentally aggro named)
		SpotNum:Set[1]
		call AurumFirstPhaseMove "${BanditSpot[${SpotNum}]}"
		SpotNum:Set[2]
		call AurumFirstPhaseMove "${BanditSpot[${SpotNum}]}"
		SpotNum:Set[3]
		call AurumFirstPhaseMove "${BanditSpot[${SpotNum}]}"
		
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
		Obj_OgreIH:ChangeCampSpot["${KillSpot}"]
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
		; 	General strategy is to keep 7 bandits on the near side of the area killed and to not engage with the 3 bandits on the far side
		; As the fight progresses, the named will start to summon æther æraquis
		; 	These are NoKill NPC mobs that roam around the area
		; 	If they collide with you they will knock you back
		; 	If they collide with named he will hop on and ride the æraquis
		; 		This does a lot of initial damage and he is effectively immune to damage until knocked off
		; 		He gets knocked off bey a collision with another æraquis
		; 	Want to avoid the whole situation and just try to move in a way to not come in contact with any æraquis
		oc !ci -PetAssist igw:${Me.Name}
		variable actor Bandit
		variable actor Aeraquis
		variable int TimeSinceFlanking=0
		while ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
		{
			; In phase 1, want to move around killing the bandits after a bit of a delay to space out the kills
			if ${AurumPhaseNum} == 1
			{
				; Make sure named is being targeted
				Actor["${_NamedNPC}"]:DoTarget
				; Check to see if group needs to move
				; 	Don't move if AuromQuickCurseIncoming
				if !${AuromQuickCurseIncoming}
				{
					; Check to see if in combat with a bandit (may get an additional bandit aggroed during AurumFirstPhaseMove)
					Bandit:Set[${Actor[Query,Name=="an aureate bandit" && Type != "Corpse" && Distance <= 50 && Target.ID > 0].ID}]
					if ${Bandit.ID(exists)}
					{
						; Move to kill bandit
						call AurumFirstPhaseMove "${Bandit.Loc}"
						; Wait in case AuromQuickCurseIncoming
						while ${AuromQuickCurseIncoming}
						{
							; Wait a second before looping
							wait 10
							; Increment TimeSinceBanditKill
							TimeSinceBanditKill:Inc
						}
						; Move back to previous BanditSpot
						call AurumFirstPhaseMove "${BanditSpot[${SpotNum}]}"
					}
					; Get Golden Gang increments
					; 	If more than 4 and it has been at least 30 seconds since the last bandit was killed, move to next BanditSpot
					call GetTargetEffectIncrements "Golden Gang" "5"
					if ${Return} > 4 && ${TimeSinceBanditKill} >= 30
					{
						; Move to next BanditSpot (don't repeat spot 1)
						if ${SpotNum:Inc} > ${BanditSpot.Size}
							SpotNum:Set[2]
						call AurumFirstPhaseMove "${BanditSpot[${SpotNum}]}"
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
			; In phase 2 want to avoid the roaming æther æraquis, killing bandits along the way as they respawn
			else
			{
				; If starting out Phase 2, move to center of Arena
				if ${CurrentArenaPoint.X} == 0 && ${CurrentArenaPoint.Y} == 0 && ${CurrentArenaPoint.Z} == 0
				{
					CurrentArenaPoint:Set[${Math.Calc[(${MinArenaX}+${MaxArenaX})/2]},200,${Math.Calc[(${MinArenaZ}+${MaxArenaZ})/2]}]
					call AurumSecondPhaseMove "${CurrentArenaPoint}"
				}
				; Update NewArenaPoint and ArenaPointAeraquisDistance values based on Location and Heading of roaming NoKill NPC æther æraquis
				call UpdateArenaAeraquisDistance
				; Check to see if CurrentArenaPoint is within 30m of the path of an æraquis
				; 	Will be point at [2,2] in arrays
				if ${ArenaPointAeraquisDistance[2,2]} >= 0 && ${ArenaPointAeraquisDistance[2,2]} <= 30
				{
					; Reset MinAeraquisDistance and MinArenaPoint
					MinAeraquisDistance:Set[-1]
					MinArenaPoint:Set[0,0,0]
					; Look for point with highest distance in ArenaPointAeraquisDistance
					PointX:Set[0]
					while ${PointX:Inc} <= 3
					{
						PointZ:Set[0]
						while ${PointZ:Inc} <= 3
						{
							; Skip if distance is not valid
							if ${ArenaPointAeraquisDistance[${PointX},${PointZ}]} == -1
								continue
							; Compare Distance with MinAeraquisDistance, update MinAeraquisDistance and MinArenaPoint if further away
							if ${ArenaPointAeraquisDistance[${PointX},${PointZ}]} > ${MinAeraquisDistance}
							{
								MinAeraquisDistance:Set[${ArenaPointAeraquisDistance[${PointX},${PointZ}]}]
								MinArenaPoint:Set[${NewArenaPoint[${PointX},${PointZ}]}]
							}
						}
					}
					; If a valid Point was found and it doesn't match CurrentArenaPoint, set as new CurrentArenaPoint
					if ${MinArenaPoint.X} != 0 || ${MinArenaPoint.Y} != 0 || ${MinArenaPoint.Z} != 0
					{
						if ${MinArenaPoint.X} != ${CurrentArenaPoint.X} || ${MinArenaPoint.Y} != ${CurrentArenaPoint.Y} || ${MinArenaPoint.Z} != ${CurrentArenaPoint.Z}
						{
							CurrentArenaPoint:Set[${MinArenaPoint.X},${MinArenaPoint.Y},${MinArenaPoint.Z}]
							call AurumSecondPhaseMove "${CurrentArenaPoint}"
						}
					}
				}
				; If in combat with a Bandit, target it
				Bandit:Set[${Actor[Query,Name=="an aureate bandit" && Type != "Corpse" && Distance <= 30 && Target.ID > 0].ID}]
				if ${Bandit.ID(exists)}
				{
					; Target Bandit
					Bandit:DoTarget
					; Send in pets if within 10m
					if ${Bandit.Distance} <= 10 && ${PreviousPetTargetID} != ${Bandit.ID}
					{
						oc !ci -PetAssist igw:${Me.Name}
						PreviousPetTargetID:Set[${Bandit.ID}]
					}
				}
				else
				{
					; Otherwise if in combat with an æther æraquis, target it
					Aeraquis:Set[${Actor[Query,Name=="an æther æraquis" && Type != "Corpse" && Distance <= 30 && Target.ID > 0].ID}]
					if ${Aeraquis.ID(exists)}
					{
						; Target Aeraquis
						Aeraquis:DoTarget
						; Send in pets if within 10m
						if ${Aeraquis.Distance} <= 10 && ${PreviousPetTargetID} != ${Aeraquis.ID}
						{
							oc !ci -PetAssist igw:${Me.Name}
							PreviousPetTargetID:Set[${Aeraquis.ID}]
						}
					}
					else
					{
						; Otherwise if there is a nearby Bandit not in combat, target it
						; 	Limit to X > 775 to not pull the Bandits on the right side of the arena (should be 3 with hats that we want to leave alone)
						Bandit:Set[${Actor[Query,Name=="an aureate bandit" && Type != "Corpse" && Distance <= 30 && Target.ID == 0 && X > 775].ID}]
						if ${Bandit.ID(exists)}
						{
							; Target Bandit
							Bandit:DoTarget
							; Send in pets if within 10m
							if ${Bandit.Distance} <= 10 && ${PreviousPetTargetID} != ${Bandit.ID}
							{
								oc !ci -PetAssist igw:${Me.Name}
								PreviousPetTargetID:Set[${Bandit.ID}]
							}
						}
						else
						{
							; Target named
							Actor["${_NamedNPC}"]:DoTarget
							; Send in pets if within 10m
							if ${Actor["${_NamedNPC}"].Distance} <= 10 && ${PreviousPetTargetID} != ${Actor["${_NamedNPC}"].ID}
							{
								oc !ci -PetAssist igw:${Me.Name}
								PreviousPetTargetID:Set[${Actor["${_NamedNPC}"].ID}]
							}
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

	function AurumFirstPhaseMove(point3f MoveSpot)
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
			; Move characters to Bandit, putting fighter in front and rest flanking
			; 	Only move for BanditSpot > 3
			if ${BanditSpot} > 3
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
				; Re-adjust position if needed (as long as Bandit within 10m of BanditInitialLoc)
				; 	Only move for BanditSpot > 3
				if ${BanditSpot} > 3
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
		while ${Aeraquis.ID(exists)}
		{
			; Target Aeraquis
			Aeraquis:DoTarget
			oc !ci -PetAssist igw:${Me.Name}
			; Wait a few seconds before checking again
			wait 30
			; Increment TimeSinceBanditKill
			TimeSinceBanditKill:Inc[3]
		}
	}

	function AurumSecondPhaseMove(point3f MoveSpot)
	{
		; Move to MoveSpot
		oc !ci -resume igw:${Me.Name}
		oc !ci -letsgo igw:${Me.Name}
		oc !ci -PetOff igw:${Me.Name}
		Obj_OgreIH:SetCampSpot
		Obj_OgreIH:ChangeCampSpot["${MoveSpot}"]
		call Obj_OgreUtilities.HandleWaitForCampSpot 10
	}

	function UpdateArenaAeraquisDistance()
	{
		; Setup NewArenaPoint and reset ArenaPointAeraquisDistance
		variable int PointX=0
		variable int PointZ=0
		variable float NewX
		variable float NewZ
		while ${PointX:Inc} <= 3
		{
			PointZ:Set[0]
			while ${PointZ:Inc} <= 3
			{
				; Calculate NewX and NewZ
				NewX:Set[${CurrentArenaPoint.X}+(${PointX}-2)*10]
				NewZ:Set[${CurrentArenaPoint.Z}+(${PointZ}-2)*10]
				; Set NewArenaPoint if within the min/max bounds
				if ${NewX} >= ${MinArenaX} && ${NewX} <= ${MaxArenaX} && ${NewZ} >= ${MinArenaZ} && ${NewZ} <= ${MaxArenaZ}
					NewArenaPoint[${PointX},${PointZ}]:Set[${NewX},200,${NewZ}]
				else
					NewArenaPoint[${PointX},${PointZ}]:Set[0,0,0]
				; Reset ArenaPointAeraquisDistance
				ArenaPointAeraquisDistance[${PointX},${PointZ}]:Set[-1]
			}
		}
		; Search for all NoKill æther æraquis
		variable index:actor Actors
		variable iterator ActorIterator
		variable float ActorHeading
		variable int NumSteps
		variable float CurrentDistance
		variable float PreviousDistance
		EQ2:QueryActors[Actors, Name=="an æther æraquis" && Type != "Corpse" && Type == "NoKill NPC" && Distance <= 100]
		Actors:GetIterator[ActorIterator]
		if ${ActorIterator:First(exists)}
		{
			do
			{
			   ; Get æraquis Location and Heading, make sure they are valid
				ActorLoc:Set[${ActorIterator.Value.Loc}]
				ActorHeading:Set[${ActorIterator.Value.Heading}]
				if ${ActorLoc.X}==0 && ${ActorLoc.Y}==0 && ${ActorLoc.Z}==0
					continue
				; Loop through each NewArenaPoint
				PointX:Set[0]
				while ${PointX:Inc} <= 3
				{
					PointZ:Set[0]
					while ${PointZ:Inc} <= 3
					{
						; Skip if NewArenaPoint is not valid
						if ${NewArenaPoint[${PointX},${PointZ}].X} == 0 && ${NewArenaPoint[${PointX},${PointZ}].Y} == 0 && ${NewArenaPoint[${PointX},${PointZ}].Z} == 0
							continue
						; Calculate minimum Distance æraquis will get to NewArenaPoint (with increments of 5m)
						NumSteps:Set[-1]
						PreviousDistance:Set[-1]
						while ${NumSteps:Inc} <= 10
						{
							; Calculate future Location of æraquis moving 5m * NumSteps
							NewLoc:Set[${ActorLoc.X},${ActorLoc.Y},${ActorLoc.Z}]
							NewLoc.X:Dec[5*${NumSteps}*${Math.Sin[${ActorHeading}]}]
							NewLoc.Z:Dec[5*${NumSteps}*${Math.Cos[${ActorHeading}]}]
							; Compare CurrentDistance with ArenaPointAeraquisDistance
							CurrentDistance:Set[${Math.Distance[${NewArenaPoint[${PointX},${PointZ}].X},${NewArenaPoint[${PointX},${PointZ}].Z},${NewLoc.X},${NewLoc.Z}]}]
							if ${ArenaPointAeraquisDistance[${PointX},${PointZ}]} == -1 || ${CurrentDistance} < ${ArenaPointAeraquisDistance[${PointX},${PointZ}]}
								ArenaPointAeraquisDistance[${PointX},${PointZ}]:Set[${CurrentDistance}]
							; Compare CurrentDistance with PreviousDistance, stop checking if moving away
							if ${PreviousDistance} != -1 && ${CurrentDistance} > ${PreviousDistance}
								break
							PreviousDistance:Set[${CurrentDistance}]
						}
					}
				}
			}
			while ${ActorIterator:Next(exists)}
		}
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
