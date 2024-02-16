#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Ogre_Instance_Include.iss"

; Helper script for Vaashkaani: Golden Rule
; Script should be placed in ...Scripts/EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/
function main(string _NamedNPC)
{
	switch ${_NamedNPC}
	{
		case Nezri En'Sallef
			call FirstLastWish "${_NamedNPC}"
			break
		case Hezodhan
			call Hezodhan "${_NamedNPC}"
			break
		case Ashnu
			call Ashnu "${_NamedNPC}"
			break
	}
}

; For Nezri En'Sallef (H2)
; First Wish: MainIconID 185, BackDropIconID 317
; 	Cast on a single target, does damage
; Last Wish: MainIconID 185, BackDropIconID 315
; 	Cast on group, need to cure the person that had First Wish or wipe
function FirstLastWish(string _NamedNPC)
{
	while ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
	{
		; Look for First Wish
		if ${Me.Effect[Query, "Detrimental" && MainIconID == 185 && BackDropIconID == 317].ID(exists)}
		{
			; Set FirstWish variable to character's name
			oc !ci -Set_Variable igw:${Me.Name} "FirstWish" "${Me.Name}"
			; Set AutoCurse for group member to cure this character
			oc !ci -AutoCurse igw:${Me.Name} ${Me.Name}
			; Add wait time for curse to be cured
			wait 50
		}
		; Look for Last Wish
		if ${Me.Effect[Query, "Detrimental" && MainIconID == 185 && BackDropIconID == 315].ID(exists)}
		{
			; Check to see if this character was the one with First Wish
			if ${OgreBotAPI.Get_Variable["FirstWish"].Equal["${Me.Name}"]}
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

; For Hezodhan (H2)
function Hezodhan(string _NamedNPC)
{
	; Handle text events
	Event[EQ2_onIncomingChatText]:AttachAtom[HezodhanIncomingChatText]
	Event[EQ2_onIncomingText]:AttachAtom[HezodhanIncomingText]
	; Run as long as named is alive
	while ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
	{
		; Make sure Targeting named at all times (can be cleared by Breath of Sand)
		if !${Target(exists)} || !${Target.Name.Equal["${_NamedNPC}"]}
			Actor["${_NamedNPC}"]:DoTarget
		; Wait a second before looping
		Wait 10
	}
}

atom HezodhanIncomingChatText(int ChatType, string Message, string Speaker, string TargetName, string SpeakerIsNPC, string ChannelName)
{
	; Look for Breath of Sand being cast
	; "Hezodhan inhales to release a Breath of Sand!"
	; "Hezodhan inhales!"
	if ${Speaker.Equal["Hezodhan"]} && ${Message.Find["inhales"]}
		oc !ci -Set_Variable igw:${Me.Name} "IncomingBreathOfSand" "TRUE"
	
	; Look for a Cursed Sand Pit spawning
	; "Hezodhan summons pits of sand to swallow you whole!"
	if ${Speaker.Equal["Hezodhan"]} && ${Message.Find["summons pits of sand to swallow you whole!"]}
		oc !ci -Set_Variable igw:${Me.Name} "CursedSandPitSpawning" "TRUE"
	
	; Debug text to see messages
	;echo ${ChatType}, ${Message}, ${Speaker}, ${TargetName}, ${SpeakerIsNPC}, ${ChannelName}
}

atom HezodhanIncomingText(string Text)
{
	; Look for a Cursed Sand Pit spawning
	; "A pit of sand envelopes your feet!"
	; "Escape the sand as quickly as you can"
	if ${Text.Find["A pit of sand envelopes your feet!"]} || ${Text.Find["Escape the sand as quickly as you can"]}
		oc !ci -Set_Variable igw:${Me.Name} "CursedSandPitSpawning" "TRUE"
	
	; Look for a Breath of Sand finished being cast
	; "A sand squall forms, and more follow from those caught in his Breath of Sand!"
	if ${Text.Find["A sand squall forms"]}
		oc !ci -Set_Variable igw:${Me.Name} "IncomingBreathOfSand" "FALSE"
}

; For Zakir-Sar-Ussur and Ashnu (H2)
; Oppressed Opportunities: MainIconID 516, BackDropIconID 1138
; 	Silences HO against named while active on anyone
; 	The last to banish The Sovereign must be the target of a cure to cure everyone
; 	On cure, clears the reuse of the curer's Cure Curse
; Not sure who exactly the last to banish is, would it be the fighter who started the HO or whoever completed the HO?
;  	Didn't bother scripting anything for this because the normal setup just worked fine

; For Ashnu, have had issues with it being positioned too close to mirror and getting line of sight issues
; Check to reposition as needed
function Ashnu(string _NamedNPC)
{
	variable int NamedCounter=0
	variable point3f NamedLoc
	variable bool RepositionNeeded=FALSE
	while ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
	{
		; If character is a fighter, see if named needs to be repositioned
		if ${Me.Archetype.Equal[fighter]}
		{
			; Get location of named
			NamedLoc:Set[${Actor[namednpc,"${_NamedNPC}"].Loc}]
			if ${NamedLoc.X}!=0 || ${NamedLoc.Y}!=0 || ${NamedLoc.Z}!=0
			{
				; Reposition named if needed
				if ${NamedLoc.X} > 616
				{
					; Give named a few seconds to re-adjust on its own, otherwise set RepositionNeeded = TRUE
					if ${NamedCounter:Inc} > 3
						RepositionNeeded:Set[TRUE]
				}
				elseif ${NamedCounter} > 0
					NamedCounter:Set[0]
			}
		}
		; Reposition if needed
		if ${RepositionNeeded}
		{
			; Change CampSpot to back off a bit, then go back to KillSpot
			oc !ci -ChangeCampSpotWho ${Me.Name} 605.37 71.11 -45.81
			wait 20
			oc !ci -ChangeCampSpotWho ${Me.Name} 615.62 71.11 -45.59
			; Reset Counter and RepositionNeeded
			NamedCounter:Set[0]
			RepositionNeeded:Set[FALSE]
		}
		; Wait a second before checking again
		wait 10
	}
}