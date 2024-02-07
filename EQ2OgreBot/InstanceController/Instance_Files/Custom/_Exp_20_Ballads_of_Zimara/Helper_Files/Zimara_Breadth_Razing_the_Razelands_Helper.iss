#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Ogre_Instance_Include.iss"

; Helper script for Zimara Breadth: Razing the Razelands
; Script should be placed in ...Scripts/EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/
function main(string _NamedNPC)
{
	switch ${_NamedNPC}
	{
		case Eaglovok
			call Eaglovok "${_NamedNPC}"
			break
		case Doda K'Bael
			call AuriacToxin "${_NamedNPC}"
			break
		case Queen Era'selka
			call AuriacToxin "${_NamedNPC}"
			break
	}
}

; For Eaglovok
; Named has knockback that can put either the named or character out of position
; Check to reposition as needed
function Eaglovok(string _NamedNPC)
{
	variable int MyCounter=0
	variable int NamedCounter=0
	variable point3f NamedLoc
	variable bool RepositionNeeded=FALSE
	while ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
	{
		; See if character is out of position
		if ${Me.X} > -331 || ${Me.Y} > 127
		{
			; Give character a few seconds to re-adjust on their own, otherwise set RepositionNeeded = TRUE
			if ${MyCounter:Inc} > 3
				RepositionNeeded:Set[TRUE]
		}
		elseif ${MyCounter} > 0
			MyCounter:Set[0]
		; If character is a fighter, see if named needs to be repositioned
		if ${Me.Archetype.Equal[fighter]}
		{
			; Get location of named
			NamedLoc:Set[${Actor[namednpc,"${_NamedNPC}"].Loc}]
			if ${NamedLoc.X}!=0 || ${NamedLoc.Y}!=0 || ${NamedLoc.Z}!=0
			{
				; Reposition named if needed
				if ${NamedLoc.X} > -331 || ${NamedLoc.Y} > 127
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
			oc !ci -ChangeCampSpotWho ${Me.Name} -337.25 125.04 -657.30
			wait 20
			oc !ci -ChangeCampSpotWho ${Me.Name} -332.18 125.62 -658.49
			; Reset Counters and RepositionNeeded
			MyCounter:Set[0]
			NamedCounter:Set[0]
			RepositionNeeded:Set[FALSE]
		}
		; Wait a second before checking again
		wait 10
	}
}

; For Doda (H2) and Queen Era'selka (H1/H2)
; Auriac Toxin: MainIconID 909, BackDropIconID 315
; Need fighter intercept to cure, or kills character on expiration
function AuriacToxin(string _NamedNPC)
{
	while ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
	{
		if ${Me.Effect[Query, "Detrimental" && MainIconID == 909 && BackDropIconID == 315].ID(exists)}
		{
			oc !ci -CastAbilityOnPlayer igw:${Me.Name}+fighter "Intercept" "${Me.Name}"
			wait 20
		}
		wait 10
	}
}
