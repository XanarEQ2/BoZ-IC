#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Ogre_Instance_Include.iss"

; Helper script for Zimara Breadth: Razing the Razelands
; Script should be placed in ...Scripts/EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/
function main(string _NamedNPC)
{
	switch ${_NamedNPC}
	{
		case Barlanka
			call TestOfMagic "${_NamedNPC}"
			break
		case Fuejenyrus
			call TitanicFrost "${_NamedNPC}"
			break
	}
}

; For Barlanka (H2)
; Test of Magic: MainIconID 839, BackDropIconID 315
; Need fighter intercept to cure, or kills character on expiration
function TestOfMagic(string _NamedNPC)
{
	while ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
	{
		if ${Me.Effect[Query, "Detrimental" && MainIconID == 839 && BackDropIconID == 315].ID(exists)}
		{
			oc !ci -CastAbilityOnPlayer igw:${Me.Name}+fighter "Intercept" "${Me.Name}"
			wait 20
		}
		wait 10
	}
}

; For Fuejenyrus (H2)
; Titanic Frost MainIconID 888, BackDropIconID 313
; Need fighter intercept to cure, or kills character on expiration
; Also characters may get knocked out of position and need to re-adjust
function TitanicFrost(string _NamedNPC)
{
	variable int MyCounter=0
	variable bool RepositionNeeded=FALSE
	while ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
	{
		; Check for Titanic Frost
		if ${Me.Effect[Query, "Detrimental" && MainIconID == 888 && BackDropIconID == 313].ID(exists)}
		{
			oc !ci -CastAbilityOnPlayer igw:${Me.Name}+fighter "Intercept" "${Me.Name}"
			wait 20
		}
		; See if character is out of position
		if ${Me.Z} < 876 || ${Me.Z} > 884
		{
			; Give character a few seconds to re-adjust on their own, otherwise set RepositionNeeded = TRUE
			if ${MyCounter:Inc} > 3
				RepositionNeeded:Set[TRUE]
		}
		elseif ${MyCounter} > 0
			MyCounter:Set[0]
		; Reposition if needed
		if ${RepositionNeeded}
		{
			; Reposition depending on which side of the pillar character is stuck on
			if ${Me.Z} < 876
				oc !ci -ChangeCampSpotWho ${Me.Name} -219.95 432.81 868.99
			else
				oc !ci -ChangeCampSpotWho ${Me.Name} -223.27 432.11 889.61
			; Wait a bit, then go back to KillSpot
			wait 20
			oc !ci -ChangeCampSpotWho ${Me.Name} -216.87 432.08 880.55
			; Reset Counter and RepositionNeeded
			MyCounter:Set[0]
			RepositionNeeded:Set[FALSE]
		}
		; Wait a second before checking again
		wait 10
	}
}
