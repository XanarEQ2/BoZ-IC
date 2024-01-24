#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Ogre_Instance_Include.iss"

; Helper script for Aether Wroughtlands: Tarnished Oasis
; Script should be placed in ...Scripts/EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/
function main(string _NamedNPC)
{
	switch ${_NamedNPC}
	{
		case Tarsisk the Tainted
			call TarsisktheTainted "${_NamedNPC}"
			break
		case Cragnok
			call Cragnok "${_NamedNPC}"
			break
		case Hasira the Hawk
			call HasiraTheHawk "${_NamedNPC}"
			break
	}
}

; For Tarsisk the Tainted (H2)
; "corrupted roots" spawn on top of a character
; 	can remove the roots with Cure Curse for that character
; 	Set RootPriority to cure priests and fighters first
; 	Get ID of root when it spawns or is removed to help clear the correct roots
variable int CurrentRootID=0
variable int NewRootID
function TarsisktheTainted(string _NamedNPC)
{
	; Update RootPriority if needed based on Archetype (priest top priority, then fighter)
	if ${Me.Archetype.Equal[priest]}
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RootPriority" "1"
	elseif ${Me.Archetype.Equal[fighter]}
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RootPriority" "2"
	
	; Run as long as named is alive
	while ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
	{
		; Look for ID of "corrupted roots" within 3m of character
		NewRootID:Set[${Actor[Query,Name=="corrupted roots" && Type != "Corpse" && Distance <= 3].ID}]
		if !${NewRootID.Equal[${CurrentRootID}]}
		{
			; Update character's RootID variable
			oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RootID" "${NewRootID}"
			; Set CurrentRootID to NewRootID
			CurrentRootID:Set[${NewRootID}]
		}
		; Wait a second before looping
		wait 10
	}
}

; For Cragnok (H2) to handle the move back to cliff after Opportune Stomp
; 	Initially handled everyone at the same time but had some characters get a delayed pop up into the air
; 	This would cause them to get stuck on the cliff and die, so handling each character separately
function Cragnok(string _NamedNPC)
{
	; Wait to be sent into the air
	while ${Me.Y} < 35 && ${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
	{
		wait 5
	}
	; Exit if named died before sending up in air
	if !${Actor[Query,Name=="${_NamedNPC}" && Type != "Corpse"].ID(exists)}
		return
	; Change CampSpot to top of cliff (just this character)
	oc !ci -ChangeCampSpotWho "${Me.Name}" -552.07 53.87 -194.17
}

; For Hasira the Hawk (H2) to handle targeting and curing curse
; Metal Mayhem: Platinum (MainIconID: 234, BackDropIconID: 413)
; 	also Iron, Copper, Silver, Gold
; 	curse is accompanied by text with which type the character has
; 	fighter needs to bast bulwark and named will say which one to cure
; 	cure the person that has the type called out and will cure for all
variable string MyCurseType="NotSet"
variable string CureCurseType="NotSet"
function HasiraTheHawk(string _NamedNPC)
{
	; Handle text events
	Event[EQ2_onIncomingChatText]:AttachAtom[HasiraTheHawkIncomingChatText]
	Event[EQ2_onIncomingText]:AttachAtom[HasiraTheHawkIncomingText]
	; Run as long as named is alive
	while ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
	{
		; Have fighter focus on named at all times
		if ${Me.Archetype.Equal[fighter]}
		{
			if !${Target(exists)} || !${Target.Name.Equal["${_NamedNPC}"]}
				Actor["${_NamedNPC}"]:DoTarget
		}
		; For other characters, check to see if Hasira's Marker exists
		elseif ${Actor[Query,Name=="Hasira's Marker" && Type != "Corpse"].ID(exists)}
		{
			if !${Target(exists)} || !${Target.Name.Equal["Hasira's Marker"]}
				Actor["Hasira's Marker"]:DoTarget
		}
		; Check to see if adds exist (named was healing, think it was because of the adds)
		elseif ${Actor[Query,Name=="a copper maedjinn alharan" && Type != "Corpse" && Distance <= 20].ID(exists)}
		{
			if !${Target(exists)} || !${Target.Name.Equal["a copper maedjinn alharan"]}
				Actor["a copper maedjinn alharan"]:DoTarget
		}
		elseif ${Actor[Query,Name=="a copper maedjinn alharin" && Type != "Corpse" && Distance <= 20].ID(exists)}
		{
			if !${Target(exists)} || !${Target.Name.Equal["a copper maedjinn alharin"]}
				Actor["a copper maedjinn alharin"]:DoTarget
		}
		elseif ${Actor[Query,Name=="a copper maedjinn saitahn" && Type != "Corpse" && Distance <= 20].ID(exists)}
		{
			if !${Target(exists)} || !${Target.Name.Equal["a copper maedjinn saitahn"]}
				Actor["a copper maedjinn saitahn"]:DoTarget
		}
		elseif ${Actor[Query,Name=="a copper maedjinn saitihn" && Type != "Corpse" && Distance <= 20].ID(exists)}
		{
			if !${Target(exists)} || !${Target.Name.Equal["a copper maedjinn saitihn"]}
				Actor["a copper maedjinn saitihn"]:DoTarget
		}
		; If no marker and no adds, focus on named
		elseif !${Target(exists)} || !${Target.Name.Equal["${_NamedNPC}"]}
			Actor["${_NamedNPC}"]:DoTarget
		
		; Check to see if cursed
		if ${Me.Effect[Query, "Detrimental" && MainIconID == 234 && BackDropIconID == 413].ID(exists)}
		{
			; If fighter and CureCurseType is "NotSet", cast Bulwark to trigger message
			if ${Me.Archetype.Equal[fighter]} && ${CureCurseType.Equal["NotSet"]}
			{
				; Cast Bulwark
				wait 20
				oc !ci -CastAbility igw:${Me.Name}+fighter "Bulwark of Order"
				; Recast should be cleared every 5 seconds, so try every 6 seconds if it still needs to be cast
				wait 30
			}
			; Otherwise if CureCurseType has been set and matches MyCurseType, have curse cured on this character
			elseif !${CureCurseType.Equal["NotSet"]} && ${CureCurseType.Equal["${MyCurseType}"]}
			{
				; Set AutoCurse for group member to cure this character
				oc !ci -AutoCurse igw:${Me.Name} ${Me.Name}
				; Add wait time for curse to be cured
				wait 50
			}
		}
		; Wait a second before looping
		wait 10
	}
}

atom HasiraTheHawkIncomingChatText(int ChatType, string Message, string Speaker, string TargetName, string SpeakerIsNPC, string ChannelName)
{
	; Look for type of curse to cure
	; Hasira the Hawk says, "Fine! It's platinum!"
	if ${Speaker.Equal["Hasira the Hawk"]}
		if ${Message.Find["Fine! It's iron!"]}
			CureCurseType:Set["Iron"]
		elseif ${Message.Find["Fine! It's copper!"]}
			CureCurseType:Set["Copper"]
		elseif ${Message.Find["Fine! It's silver!"]}
			CureCurseType:Set["Silver"]
		elseif ${Message.Find["Fine! It's gold!"]}
			CureCurseType:Set["Gold"]
		elseif ${Message.Find["Fine! It's platinum!"]}
			CureCurseType:Set["Platinum"]
	
	; Debug text to see messages
	;echo ${ChatType}, ${Message}, ${Speaker}, ${TargetName}, ${SpeakerIsNPC}, ${ChannelName}
}

atom HasiraTheHawkIncomingText(string Text)
{
	; Look for cursed with Metal Mayhem to set MyCurseType
	if ${Text.Find["You have been cursed with Metal Mayhem: Iron!"]}
		MyCurseType:Set["Iron"]
	elseif ${Text.Find["You have been cursed with Metal Mayhem: Copper!"]}
		MyCurseType:Set["Copper"]
	elseif ${Text.Find["You have been cursed with Metal Mayhem: Silver!"]}
		MyCurseType:Set["Silver"]
	elseif ${Text.Find["You have been cursed with Metal Mayhem: Gold!"]}
		MyCurseType:Set["Gold"]
	elseif ${Text.Find["You have been cursed with Metal Mayhem: Platinum!"]}
		MyCurseType:Set["Platinum"]
	
	; Look for curse cured to reset MyCurseType and CureCurseType
	; <character> successfully cured <character>'s Metal Mayhem, which cures all!
	if ${Text.Find["Metal Mayhem, which cures all!"]}
	{
		MyCurseType:Set["NotSet"]
		CureCurseType:Set["NotSet"]
	}
}
