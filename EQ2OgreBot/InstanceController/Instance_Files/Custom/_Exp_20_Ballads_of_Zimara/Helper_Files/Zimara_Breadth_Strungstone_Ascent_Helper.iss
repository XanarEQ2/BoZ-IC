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
function TitanicFrost(string _NamedNPC)
{
	while ${Actor[namednpc,"${_NamedNPC}"].ID(exists)}
	{
		if ${Me.Effect[Query, "Detrimental" && MainIconID == 888 && BackDropIconID == 313].ID(exists)}
		{
			oc !ci -CastAbilityOnPlayer igw:${Me.Name}+fighter "Intercept" "${Me.Name}"
			wait 20
		}
		wait 10
	}
}
