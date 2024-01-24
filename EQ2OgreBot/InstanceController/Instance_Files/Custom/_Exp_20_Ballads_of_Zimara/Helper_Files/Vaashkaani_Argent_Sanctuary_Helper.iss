#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Ogre_Instance_Include.iss"

variable bool HaveCurse=FALSE
variable string CurseTarget
variable string KillTarget="Sansobog"

; Helper script for Vaashkaani: Argent Sanctuary
; Script should be placed in ...Scripts/EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/
function main(string _NamedNPC1, string _NamedNPC2)
{
	switch ${_NamedNPC1}
	{
		case Sansobog
			call SansobogAndAkharys "${_NamedNPC1}" "${_NamedNPC2}"
			break
		case Uah'Lu the Unhallowed
			call UahLuTheUnhallowed "${_NamedNPC1}"
			break
	}
}

; For Sansobog and Akharys (H2)
function SansobogAndAkharys(string _NamedNPC1, string _NamedNPC2)
{
	; Handle IncomingText event
	Event[EQ2_onIncomingText]:AttachAtom[SansobogAndAkharysIncomingText]
	; Handle IncomingChat event
    Event[EQ2_onIncomingChatText]:AttachAtom[SansobogAndAkharysIncomingChatText]
	; Keep script running throughout fight
	while ${Actor[namednpc,"${_NamedNPC1}"].ID(exists)} || ${Actor[namednpc,"${_NamedNPC2}"].ID(exists)}
	{
		; Check for Curse
		if ${HaveCurse}
		{
			; Make sure Target is CurseTarget
			if ${Target(exists)} && ${Target.Name.Equal["${CurseTarget}"]}
			{
				; Set AutoCurse for group member to cure this character
				oc !ci -AutoCurse igw:${Me.Name} ${Me.Name}
				; Add wait time for curse to be cured
				wait 50
			}
			; If Target is not CurseTarget, set to CurseTarget
			else
				Actor["${CurseTarget}"]:DoTarget
		}
		; If don't have Curse, make sure target is KillTarget
		elseif !${Target(exists)} || !${Target.Name.Equal["${KillTarget}"]}
			Actor["${KillTarget}"]:DoTarget
		; Wait a second before looping
		wait 10
	}
}

atom SansobogAndAkharysIncomingText(string Text)
{
	; Look for Twice Bitten curse
	; Kills target on expiration
	; When being cured, must have the named that cast it on you as your target or you die when cured
	if ${Text.Find["You must be targeting Akharys to be cured"]}
	{
		CurseTarget:Set["Akharys"]
		HaveCurse:Set[TRUE]
		Actor["${CurseTarget}"]:DoTarget
	}
	elseif ${Text.Find["You must be targeting Sansobog to be cured"]}
	{
		CurseTarget:Set["Sansobog"]
		HaveCurse:Set[TRUE]
		Actor["${CurseTarget}"]:DoTarget
	}
	elseif ${Text.Find["relieves Twice Bitten from YOU"]}
	{
		HaveCurse:Set[FALSE]
		Actor["${KillTarget}"]:DoTarget
	}
}

atom SansobogAndAkharysIncomingChatText(int ChatType, string Message, string Speaker, string TargetName, string SpeakerIsNPC, string ChannelName)
{
	; Look for Second Life (need to kill the named that doesn't have it)
	if ${Message.Find["gains Second Life"]}
		if ${Speaker.Equal["Sansobog"]}
			KillTarget:Set["Akharys"]
		elseif ${Speaker.Equal["Akharys"]}
			KillTarget:Set["Sansobog"]
			
	; Debug text to see messages
	;echo ${ChatType}, ${Message}, ${Speaker}, ${TargetName}, ${SpeakerIsNPC}, ${ChannelName}
}

; For Uah'Lu the Unhallowed (H2)
; Need to look for and hail Archetype-specific Adds during the fight to activate them
function UahLuTheUnhallowed(string _NamedNPC)
{
	; Setup AddName based on Archetype
	variable string AddName
	if ${Me.Archetype.Equal[fighter]}
		AddName:Set["a fallen fighter"]
	elseif ${Me.Archetype.Equal[scout]}
		AddName:Set["a fallen scout"]
	elseif ${Me.Archetype.Equal[mage]}
		AddName:Set["a fallen mage"]
	elseif ${Me.Archetype.Equal[priest]}
		AddName:Set["a fallen priest"]
	; During the fight, look for AddName to activate
	variable int AddID
	variable point3f AddLoc
	while ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
	{
		; Look for NoKill Add
		AddID:Set[${Actor[Query,Name=="${AddName}" && Type == "NoKill NPC" && Distance <= 100].ID}]
		if ${AddID} != 0
		{
			; Get Add Location
			AddLoc:Set[${Actor[${AddID}].Loc}]
			if ${AddLoc.X}!=0 || ${AddLoc.Y}!=0 || ${AddLoc.Z}!=0
			{
				; Move to Add
				oc !ci -ChangeCampSpotWho ${Me.Name} ${AddLoc.X} ${AddLoc.Y} ${AddLoc.Z}
				while ${Actor[Query,ID == ${AddID} && Type == "NoKill NPC" && Distance > 5].ID(exists)}
				{
					wait 10
				}
				; Hail Add to activate it
				wait 10
				Actor[${AddID}]:DoubleClick
				wait 10
				; Move back to KillSpot
				oc !ci -ChangeCampSpotWho ${Me.Name} 262.17 3.45 -65.12
			}
		}
		; Wait a second before looping
		wait 10
	}
}
