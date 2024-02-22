variable string SubClass
variable string Archetype
variable string CurrentHOName
variable int CurrentHOIconID[6]
variable bool CastHOIconID[6]
variable int TimeSinceStarter=-1

; ranger variables
variable bool GroupedWithAnotherScout=FALSE

; Helper script to make completing HO's more reliable
; 	Ogre still takes care of most of the work, this just provides some additonal support
; Script should be placed in ...InnerSpace\Scripts
; MCP button setups (paste in Inner Space Console after right clicking a button to use and clearing any existing Parameters)
; 	Obj_OgreMCP:PasteButton[RunScriptRequiresOgreBot,HO_Helper,igw:\${Me.Name},HO_Helper,InCombat]
; 	Obj_OgreMCP:PasteButton[EndScriptRequiresOgreBot,HO_End,igw:\${Me.Name},HO_Helper]
function main(string _NamedNPC)
{
	; Initialize arrays
	variable int ArrayIndex=0
	while ${ArrayIndex:Inc} <= 6
	{
		CurrentHOIconID[${ArrayIndex}]:Set[-1]
		CastHOIconID[${ArrayIndex}]:Set[FALSE]
	}
	
	; Handle HO Window State Change event
	Event[EQ2_OnHOWindowStateChange]:AttachAtom[MyAtom]    
	
	; Get SubClass and Archetype
	SubClass:Set["${Me.SubClass}"]
	Archetype:Set["${Me.Archetype}"]
	
	; Perform special setup based on SubClass
	if ${SubClass.Equal[ranger]}
		call SetupRanger
	elseif ${SubClass.Equal[berserker]}
		call SetupBerserker
	
	; Disable Ascensions (don't want to cast things with a long cast time while trying to complete an HO)
	call SetupAscensions "FALSE"
	
	; Make sure not currently stuck on a starter
	eq2execute cancel_ho_starter
	
	; Setup loop to handle HO's based on _NamedNPC
	switch ${_NamedNPC}
	{
		case InZone
			; Keep script running as long as in zone
			variable string ZoneName
			ZoneName:Set["${Zone.Name}"]
			while ${Zone.Name.Equal[${ZoneName}]} || ${Me.ID} == 0
			{
				call HandleHO
			}
			break
		case InCombat
			; Keep script running as long as in combat
			while ${Me.InCombat}
			{
				call HandleHO
			}
			break
		default
			; Keep script running as long as _NamedNPC exists or in combat
			while ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)} || ${Me.InCombat}
			{
				call HandleHO
			}
	}
}

atom MyAtom(string HOName, string HODescription, string HOWindowState, string HOTimeLimit, string HOTimeElapsed, string HOTimeRemaining, string HOCurrentWheelSlot, string HOWheelState, string HOIconID1, string HOIconID2, string HOIconID3, string HOIconID4, string HOIconID5, string HOIconID6)
{
	; Update variables
	CurrentHOName:Set["${HOName}"]
	CurrentHOIconID[1]:Set[${HOIconID1}]
	CastHOIconID[1]:Set[FALSE]
	CurrentHOIconID[2]:Set[${HOIconID2}]
	CastHOIconID[2]:Set[FALSE]
	CurrentHOIconID[3]:Set[${HOIconID3}]
	CastHOIconID[3]:Set[FALSE]
	CurrentHOIconID[4]:Set[${HOIconID4}]
	CastHOIconID[4]:Set[FALSE]
	CurrentHOIconID[5]:Set[${HOIconID5}]
	CastHOIconID[5]:Set[FALSE]
	CurrentHOIconID[6]:Set[${HOIconID6}]
	CastHOIconID[6]:Set[FALSE]
	; If CurrentHOName is empty the HO is in the starter phase so set the TimeSinceStarter to 0, otherwise set to -1
	if ${CurrentHOName.Length} == 0
		TimeSinceStarter:Set[0]
	else
		TimeSinceStarter:Set[-1]
}

atom atexit()
{
	; End special setup based on SubClass
	if ${SubClass.Equal[ranger]}
		call EndRanger
	elseif ${SubClass.Equal[berserker]}
		call EndBerserker
	; Re-enable Ascensions
	call SetupAscensions "TRUE"
}

function HandleHO()
{
	; Handle HO based on SubClass
	if ${SubClass.Equal[ranger]} && !${GroupedWithAnotherScout}
		call HandleRangerHO
	elseif ${SubClass.Equal[berserker]}
		call HandleBerserkerHO
	elseif ${SubClass.Equal[dirge]}
		call HandleDirgeHO
	
	; If the starter has been open for at least 4 seconds, assume it is stuck and cancel it
	if ${TimeSinceStarter} >= 4
	{
		eq2execute cancel_ho_starter
		TimeSinceStarter:Set[-1]
	}
	
	; Wait a second and increment TimeSinceStarter if needed
	wait 10
	if ${TimeSinceStarter} != -1
		TimeSinceStarter:Inc
}

function SetupAscensions(bool EnableAscensions)
{
	; Disable or re-enable ascensions (except don't re-enable for priests)
	if !${EnableAscensions} || !${Archetype.Equal[priest]}
	{
		; Etherealist ascensions
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Cascading Force" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Compounding Force" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Etherflash" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Focused Blast" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Implosion" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Levinbolt" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Mana Schism" ${EnableAscensions} TRUE
		; Thaumaturgist Ascensions
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Anti-Life" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Blood Contract" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Desiccation" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Exsanguination" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Necrotic Consumption" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Revocation of Life" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Septic Strike" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Virulent Outbreak" ${EnableAscensions} TRUE
		; Geomancer Ascensions
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Accretion" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Bastion of Iron" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Domain of Earth" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Earthen Phalanx" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Erosion" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Geotic Rampage" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Granite Protector" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Mudslide" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Obsidian Mind" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "One with Stone" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Stone Hammer" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Stone Soul" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Telluric Rending" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Terrene Destruction" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Terrestrial Coffin" ${EnableAscensions} TRUE
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Xenolith" ${EnableAscensions} TRUE
	}
}

function SetupRanger()
{
	; Issue for rangers is casting something to complete the cape icon
	; Most Combat Arts have stealth/positional requirements or long recast
	; This script is setup to allow "Stealth" + "Emberstrike" to complete the HO
	; Should only need in solo instances, in heroic groups can let another scout take care of it
	
	; Don't custom setup if there is another scout in the group , can just let them take care of it
	variable int GroupNum=0
	while ${GroupNum:Inc} < ${Me.GroupCount}
	{
		variable string GroupClass=${Me.Group[${GroupNum}].Class}
		if ${GroupClass.Equal[beastlord]} || ${GroupClass.Equal[assassin]} || ${GroupClass.Equal[brigand]}
			GroupedWithAnotherScout:Set[TRUE]
		elseif ${Class.Equal[swashbuckler]} || ${Class.Equal[dirge]} || ${Class.Equal[troubador]}
			GroupedWithAnotherScout:Set[TRUE]
	}
	if ${GroupedWithAnotherScout}
		return
	
	; Disable Stealth and Emberstrike from cast stack (to make sure they are available to cast when needed)
	oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Stealth" FALSE TRUE
	oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Emberstrike" FALSE TRUE
}

function HandleRangerHO()
{
	; Check to see if any Current HO Icon ID = 40 and have not already cast "Emberstrike"
	variable ability EmberStrike
	variable int WaitTime=0
	variable int ArrayIndex=0
	while ${ArrayIndex:Inc} <= 6
	{
		if ${CurrentHOIconID[${ArrayIndex}]} == 40 && !${CastHOIconID[${ArrayIndex}]}
		{
			; Make sure character has "Emberstrike XIII" ability (ID 980956390)
			; 	For some reason I could not get Ogre to cast Emberstrike, so had to resort to hard-coding the ID and casting it myself
			EmberStrike:Set[${Me.Ability[Query, ID == 980956390]}]
			if !${EmberStrike.ID(exists)}
				return
			; Pause Ogre
			oc !ci -Pause ${Me.Name}
			wait 3
			; Clear ability queue
			eq2execute clearabilityqueue
			; Cancel anything currently being cast
			oc !ci -CancelCasting ${Me.Name}
			; Cast Stealth
			oc !ci -CastAbility ${Me.Name} "Stealth"
			; Wait for Emberstrike to be ready (up to 3 seconds)
			WaitTime:Set[0]
			while !${EmberStrike.IsReady} && ${WaitTime:Inc} < 30
			{
				wait 1
			}
			; Cast Emberstrike
			EmberStrike:Use
			wait 5
			; Resume Ogre
			oc !ci -Resume ${Me.Name}
			; Set as cast
			CastHOIconID[${ArrayIndex}]:Set[TRUE]
		}
	}
}

function EndRanger()
{
	; Re-enable Stealth and Emberstrike in cast stack
	oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Stealth" TRUE TRUE
	oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Emberstrike" TRUE TRUE
}

function SetupBerserker()
{
	; Issue for Berserkers is casting something to complete the arm icon
	; Most Combat Arts have long recast
	; This script is setup to allow the buff "Bloodlust" for HO's
	
	; Disable Bloodlust from cast stack and clear maintained
	oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Bloodlust" FALSE TRUE
	oc !ci -CancelMaintained "Bloodlust"
}

function HandleBerserkerHO()
{
	; Check to see if Bloodlust is maintained and cancel it
	if ${OgreBotAPI.HaveMaintained[-partial, Bloodlust]}
		oc !ci -CancelMaintained "Bloodlust"
	else
	{
		; Check to see if any Current HO Icon ID = 5 and have not already cast "Bloodlust"
		variable int ArrayIndex=0
		while ${ArrayIndex:Inc} <= 6
		{
			if ${CurrentHOIconID[${ArrayIndex}]} == 5 && !${CastHOIconID[${ArrayIndex}]}
			{
				oc !ci -CastAbility ${Me.Name} "Bloodlust"
				CastHOIconID[${ArrayIndex}]:Set[TRUE]
			}
		}
	
	}
}

function EndBerserker()
{
	; Re-enable Bloodlust in cast stack
	oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Bloodlust" TRUE TRUE
}

function HandleDirgeHO()
{
	; Issue for Dirge is for some reason it has a hard time completing the dagger icon
	; 	could be it is trying to cast a debuff that is already maintained?
	; 	or maybe a range issue if more than 5m away and trying to complete with a melee ability?
	; Use Zander's Choral Rebuff to complete it
	
	; Check to see if any Current HO Icon ID = 36 and have not already cast "Zander's Choral Rebuff"
	variable int ArrayIndex=0
	while ${ArrayIndex:Inc} <= 6
	{
		if ${CurrentHOIconID[${ArrayIndex}]} == 36 && !${CastHOIconID[${ArrayIndex}]}
		{
			; Zander's Choral Rebuff gets maintained, so cast it twice to make sure it goes off
			; 	casting when already maintained will cancel it
			oc !ci -CastAbilityNoChecks ${Me.Name} "Zander's Choral Rebuff"
			wait 20
			oc !ci -CastAbilityNoChecks ${Me.Name} "Zander's Choral Rebuff"
			CastHOIconID[${ArrayIndex}]:Set[TRUE]
		}
	}
}

; Heroic Icon ID map

; Fighter
; 0 - sword
; 1 - shield (starter)
; 2 - horn
; 3 - fist
; 4 - boot
; 5 - arm

; Priest
; 12 - chalice
; 13 - a weird snow cone looking thing...
; 14 - hammer
; 15 - eye
; 16 - moon
; 17 - stonehenge (starter)

; Mage
; 24 - wand?
; 25 - lightning
; 26 - cube? (starter)
; 27 - cane
; 28 - fire
; 29 - star

; Scout
; 36 - dagger
; 37 - bow
; 38 - mask
; 39 - lock (starter)
; 40 - cloak
; 41 - coin (can shift an opportunity)
