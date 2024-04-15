; Helper script to use Painlink if needed for each character
function main()
{
	; Get Painlink
	call GetPainlink "1"
}

function GetPainlink(int RetryNum)
{
	; Loop through Maintained Effects
    variable int Counter = 0
	while ${Counter:Inc} <= ${Me.CountMaintained}
	{
		; Look for Painlink
		if ${Me.Maintained[${Counter}].Name.Equal["Painlink"]}
		{
			; Check to see if Duration is more than 30 minutes left (1800 seconds)
			if ${Me.Maintained[${Counter}].Duration} > 1800
			{
				; Exit if have more than 30 minutes left, don't need to re-apply
				return
			}
			; Cancel Painlink so it can be re-applied
			else
			{
				oc !ci -CancelMaintainedForWho ${Me.Name} "Painlink"
				wait 20
			}
			; Stop search after Painlink is found
			break
		}
	}
	
	; Pause Ogre
	oc !ci -Pause ${Me.Name}
	wait 1
	; Clear ability queue
	eq2execute clearabilityqueue
	; Cancel anything currently being cast
	oc !ci -CancelCasting ${Me.Name}
	; Wait a second to recover
	wait 10
	
	; Check to see if Painlink ability exists
	;  ID 1361385413 is for Painlink ability from Handcrafted Zimaran Painlink
	variable ability PainlinkAbility
	PainlinkAbility:Set[${Me.Ability[Query, ID == 1361385413]}]
	if ${PainlinkAbility.ID(exists)}
	{
		; Wait until ability is ready to cast (up to 20 seconds)
		Counter:Set[0]
		while !${PainlinkAbility.IsReady} && ${Counter:Inc} <= 200
		{
			wait 1
		}
		; Cast PainlinkAbility
		PainlinkAbility:Use
		wait 60
	}
	else
	{
		; Use Handcrafted Zimaran Painlink to get Painlink
		oc !ci -UseItem igw:${Me.Name} "Handcrafted Zimaran Painlink"
		wait 50
	}
	
	; Call GetPainlink again (to cast Painlink ability after item used, or to verify the Painlink is Maintained)
	if ${RetryNum:Inc} <= 3
		call GetPainlink "${RetryNum}"
}

atom atexit()
{
	; Set variable indicating script complete
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_PainlinkComplete" "TRUE"
	; Resume Ogre
	oc !ci -Resume ${Me.Name}
}
