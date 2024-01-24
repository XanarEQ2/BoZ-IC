#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Ogre_Instance_Include.iss"

variable bool HaveSphereOfInfluence=FALSE

; Helper script for Vaashkaani: Every Which Way
; Script should be placed in ...Scripts/EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/
function main(string ZoneName)
{
	; Print to ogre console that script is active
	oc ${Me.Name}: The Vaashkaani_Every_Which_Way_Helper script is active for ${ZoneName}!
	
	; Handle incoming chat text
    Event[EQ2_onIncomingChatText]:AttachAtom[IncomingChatText]
	
	; If this character is a bard, disable Selo's Accelerando (running too fast may cause issues picking up orbs)
	if ${Me.Class.Equal[bard]}
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Selo's Accelerando" FALSE TRUE
	; If this character is a priest, disable Cure Curse in Cast Stack (will handle with AutoCurse)
	elseif ${Me.Archetype.Equal[priest]}
		oc !ci -ChangeOgreBotUIOption ${Me.Name} checkbox_settings_disablecaststack_curecurse TRUE TRUE
	
	; Cancel Selo's Accelerando if this character has it
	oc !ci -CancelMaintained ${Me.Name} "Selo's Accelerando"
	
	; Run as an infinite loop while in zone
	while ${Zone.Name.Equals["${ZoneName}"]} || !${EQ2.Zoning.Equal[0]}
	{
		; Check to see if have Sphere of Influence detrimental
		if ${Me.Effect[Query, Type == "Detrimental" && MainIconID == 582 && BackDropIconID == 582].ID(exists)}
		{
			; Update variable if needed to show this character has Sphere of Influence
			if !${HaveSphereOfInfluence}
			{
				oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_HaveSphereOfInfluence" "TRUE"
				HaveSphereOfInfluence:Set[TRUE]
			}
		}
		else
		{
			; Update variable if needed to show this character does not have Sphere of Influence
			if ${HaveSphereOfInfluence}
			{
				oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_HaveSphereOfInfluence" "FALSE"
				HaveSphereOfInfluence:Set[FALSE]
			}
		}
		
		; If this character is a fighter, check to see if have Creeping Contagion detrimental
		if ${Me.Archetype.Equal[fighter]}
		{
			if ${Me.Effect[Query, Type == "Detrimental" && MainIconID == 1079 && BackDropIconID == 313].ID(exists)}
			{
				; Set AutoCurse for group member to cure this character
				oc !ci -AutoCurse igw:${Me.Name} ${Me.Name}
				; Add wait time for curse to be cured
				wait 50
			}
		}
		
		; Check to see if have Cramped Quarters detrimental
		if ${Me.Effect[Query, Type == "Detrimental" && MainIconID == 847 && BackDropIconID == 791].ID(exists)}
		{
			; Set AutoCurse for group member to cure this character
			oc !ci -AutoCurse igw:${Me.Name} ${Me.Name}
			; Add wait time for curse to be cured
			wait 50
		}
		
		; Wait a second before looping again
		wait 10
	}
}

atom IncomingChatText(int ChatType, string Message, string Speaker, string TargetName, string SpeakerIsNPC, string ChannelName)
{
	; Look for message to enable Archetype-specific Heroic Opportunity
	if ${Message.Find["hopes a fighter doesn't start a Heroic Opportunity"]}
	{
		; Start HO only on a fighter
		if ${Me.Archetype.Equal[fighter]}
			oc !ci -ChangeOgreBotUIOption ${Me.Name} checkbox_settings_ho_start TRUE TRUE
		else
			oc !ci -ChangeOgreBotUIOption ${Me.Name} checkbox_settings_ho_start FALSE TRUE
	}
	elseif ${Message.Find["hopes a scout doesn't start a Heroic Opportunity"]}
	{
		; Start HO only on a scout
		if ${Me.Archetype.Equal[scout]}
			oc !ci -ChangeOgreBotUIOption ${Me.Name} checkbox_settings_ho_start TRUE TRUE
		else
			oc !ci -ChangeOgreBotUIOption ${Me.Name} checkbox_settings_ho_start FALSE TRUE
	}
	elseif ${Message.Find["hopes a mage doesn't start a Heroic Opportunity"]}
	{
		; Start HO only on a mage
		if ${Me.Archetype.Equal[mage]}
			oc !ci -ChangeOgreBotUIOption ${Me.Name} checkbox_settings_ho_start TRUE TRUE
		else
			oc !ci -ChangeOgreBotUIOption ${Me.Name} checkbox_settings_ho_start FALSE TRUE
	}
	elseif ${Message.Find["hopes a priest doesn't start a Heroic Opportunity"]}
	{
		; Start HO only on a priest
		if ${Me.Archetype.Equal[priest]}
			oc !ci -ChangeOgreBotUIOption ${Me.Name} checkbox_settings_ho_start TRUE TRUE
		else
			oc !ci -ChangeOgreBotUIOption ${Me.Name} checkbox_settings_ho_start FALSE TRUE
	}
	; Debug text to see messages
	; echo ${ChatType}, ${Message}, ${Speaker}, ${TargetName}, ${SpeakerIsNPC}, ${ChannelName}
}

atom atexit()
{
	; Print to ogre console that script is ending
	oc ${Me.Name}: Ending the Vaashkaani_Every_Which_Way_Helper script.
	; If this character is a bard, re-enable Selo's Accelerando
	if ${Me.Class.Equal[bard]}
		oc !ci -ChangeCastStackListBoxItem ${Me.Name} "Selo's Accelerando" TRUE TRUE
	; If this character is a priest, re-enable Cure Curse in Cast Stack
	elseif ${Me.Archetype.Equal[priest]}
		oc !ci -ChangeOgreBotUIOption ${Me.Name} checkbox_settings_disablecaststack_curecurse FALSE TRUE
}

; Effect information for this zone:
; Sphere of Influence - MainIconID = 582 - BackDropIconID = 582
; Orbs Absorbed - MainIconID = 119 - BackDropIconID = 119
; Remaining Orbs - MainIconID = 114 - BackDropIconID = 114

; First boss, need to cure curse on fighter
; Creeping Contagion - MainIconID = 1079, BackDropIconID = 313

; Third boss, need cure curse on anyone
; Cramped Quarters - MainIconID = 847, BackDropIconID = 791

; Third boss, HO text
; Abin'Ebi the Awkward hopes a scout doesn't start a Heroic Opportunity
; Hurry! Complete a Heroic Opportunity initiated by a scout!
