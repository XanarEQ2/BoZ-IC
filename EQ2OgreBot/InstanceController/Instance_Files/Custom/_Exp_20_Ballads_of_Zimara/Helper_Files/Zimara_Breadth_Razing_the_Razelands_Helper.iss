#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Ogre_Instance_Include.iss"

; Helper script for Zimara Breadth: Razing the Razelands
; Script should be placed in ...Scripts/EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/
function main(string _NamedNPC)
{
	switch ${_NamedNPC}
	{
		case Doda K'Bael
			call AuriacToxin "${_NamedNPC}"
			break
		case Queen Era'selka
			call AuriacToxin "${_NamedNPC}"
			break
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
