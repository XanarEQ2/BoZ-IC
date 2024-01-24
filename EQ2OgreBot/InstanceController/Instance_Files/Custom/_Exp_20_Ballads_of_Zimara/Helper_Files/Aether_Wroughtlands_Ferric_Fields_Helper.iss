; This Helper file requires IC_Helper file to function
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Ogre_Instance_Include.iss"

; Helper script for Aether Wroughtlands: Ferric Fields
; Script should be placed in ...Scripts/EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/
function main(string _NamedNPC)
{
	switch ${_NamedNPC}
	{
		case Metalloid
			call Metalloid "${_NamedNPC}"
			break
		case Syadun
			call Syadun "${_NamedNPC}"
			break
	}
}

; For Metalloid (H2)
; Pillars will spawn on top of characters throughout fight
; Character will get text "Metalloid strikes while the iron target is YOU!"
; 	then that character will be knocked up and a pillar will be spawned on top of that character
; If you stand too close to a pillar for a long period of time, character will be killed
; If 5 pillars are up, group will wipe
; If a pillar spawns on top of an existing pillar, both will be destroyed
; Strategy is have character being targeted by pillar joust out to spawn away from group
; 	when a second pillar spawns, they will destroy each other
variable bool PillarIncoming=FALSE
variable bool PillarSpawned=FALSE
variable int PillarTime=0
function Metalloid(string _NamedNPC)
{
	; Handle text events
	Event[EQ2_onIncomingChatText]:AttachAtom[MetalloidIncomingChatText]
	Event[EQ2_onIncomingText]:AttachAtom[MetalloidIncomingText]
	; Run as long as named is alive
	while ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
	{
		; Look for PillarIncoming
		if ${PillarIncoming}
		{
			; Move to spawn pillar away from group
			oc !ci -ChangeCampSpotWho "${Me.Name}" 271.67 36.47 -700.27
			; Wait for pillar to spawn (up to 5 seconds)
			PillarTime:Set[0]
			while !${PillarSpawned} && ${PillarTime:Inc} <= 50
			{
				wait 1
			}
			; Move back to to KillSpot
			oc !ci -ChangeCampSpotWho "${Me.Name}" 257.45 36.70 -697.80
			; Set PillarIncoming = FALSE
			PillarIncoming:Set[FALSE]
		}
		; Short wait before looping
		wait 1
	}
}

atom MetalloidIncomingChatText(int ChatType, string Message, string Speaker, string TargetName, string SpeakerIsNPC, string ChannelName)
{
	; Look for pillar being spawned on character
	; Metalloid strikes while the iron target is YOU!
	if ${Speaker.Equal["Metalloid"]} && ${Message.Find["strikes while the iron target is YOU!"]}
	{
		PillarSpawned:Set[FALSE]
		PillarIncoming:Set[TRUE]
	}
	
	; Debug text to see messages
	;echo ${ChatType}, ${Message}, ${Speaker}, ${TargetName}, ${SpeakerIsNPC}, ${ChannelName}
}

atom MetalloidIncomingText(string Text)
{
	; Look for pillar finished spawning
	; The iron pillar that sent you skyward remains! It can only be destroyed with another carefully placed iron pillar.
	if ${Text.Find["The iron pillar that sent you skyward remains!"]}
		PillarSpawned:Set[TRUE]
}

; For Syadun (H2)
function Syadun(string _NamedNPC)
{
	; Run as long as named is alive
	variable point3f WeaveSpots[2]
	WeaveSpots[1]:Set[54.23,38.35,-681.17]
	WeaveSpots[2]:Set[31.12,38.13,-664.78]
	variable int WeaveNum
	variable int WeaveID=0
	while ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
	{
		; Check to see if cursed
		if ${Me.Effect[Query, "Detrimental" && MainIconID == 879 && BackDropIconID == 413].ID(exists)}
		{
			; Set AutoCurse for group member to cure this character
			oc !ci -AutoCurse igw:${Me.Name} ${Me.Name}
			; Add wait time for curse to be cured
			wait 50
		}
		; Fighter needs to move to platforms to pull weaves
		if ${Me.Archetype.Equal[fighter]}
		{
			; Make sure targeting named
			if !${Target(exists)} || !${Target.Name.Equal["${_NamedNPC}"]}
			{
				Actor["${_NamedNPC}"]:DoTarget
				wait 10
				continue
			}
			; Check for Watcher's Weaves with more than 0 increments
			call GetTargetEffectIncrements "Watcher's Weaves" "8"
			if ${Return} > 0
			{
				; Move to platforms to check for weaves to pull
				WeaveNum:Set[0]
				while ${WeaveNum:Inc} <= 2
				{
					; Move to platform
					oc !ci -ChangeCampSpotWho "${Me.Name}" ${WeaveSpots[${WeaveNum}].X} ${WeaveSpots[${WeaveNum}].Y} ${WeaveSpots[${WeaveNum}].Z}
					wait 20
					; Check for weave that needs to be pulled
					do
					{
						; Make sure don't have Curse (if so need to stop pulling weaves)
						; 	Don't cure now, need to move back to KillSpot before being cured or the cure will kill the fighter
						if ${Me.Effect[Query, "Detrimental" && MainIconID == 879 && BackDropIconID == 413].ID(exists)}
						{
							Actor["${_NamedNPC}"]:DoTarget
							WeaveNum:Set[2]
							break
						}
						; Check to see if there is a weave that needs to be pulled
						WeaveID:Set[${Actor[Query,Name=="a watcher's weave" && Distance > 8 && Distance < 20 && Health == 100 && Type == "NPC"].ID}]
						if !${WeaveID.Equal[0]}
						{
							Actor[${WeaveID}]:DoTarget
							; Wait a few seconds before looping again
							wait 30
						}
					}
					while !${WeaveID.Equal[0]}
					; Go back to KillSpot
					oc !ci -ChangeCampSpotWho "${Me.Name}" 48.46 37.84 -664.95
					wait 20
				}
			}
		}
		; For everyone else, just target named
		else
		{
			; Make sure targeting named
			if !${Target(exists)} || !${Target.Name.Equal["${_NamedNPC}"]}
				Actor["${_NamedNPC}"]:DoTarget
		}
		; Wait a second before looping again
		wait 10
	}
}
