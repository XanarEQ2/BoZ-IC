; Helper script for mend_and_rune_swap to see if we actually need to mend and swap
function main(string RuneType)
{
	; See if WaistCheck needs to be performed
	if ${RuneType.Equal["WaistCheck"]}
	{
		call WaistCheck
		return
	}
	
	; Look for Mechanized Platinum Repository of Reconstruction in inventory
	variable index:item Items
	variable iterator ItemIterator
	Me:QueryInventory[Items, Name == "Mechanized Platinum Repository of Reconstruction" && Location == "Inventory"]
	Items:GetIterator[ItemIterator]
	if ${ItemIterator:First(exists)}
	{
		do
		{
			; Bot found, set _RepairBotAvailable if bot IsReady
			if ${ItemIterator.Value.IsReady}
				oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RepairBotAvailable" "TRUE"
		}
		while ${ItemIterator:Next(exists)}
	}
	
	; Make sure a Waist item is equipped, otherwise exit
	if !${Me.Equipment[Waist].Name(exists)}
		return
	
	; Make sure Item Info is available for the waist
	if (!${Me.Equipment[Waist].IsItemInfoAvailable})
	{
		do
		{
			waitframe
		}
		while (!${Me.Equipment[Waist].IsItemInfoAvailable})
	}
	
	; Set WaistCondition (wait a couple seconds for Condition to update if it has recently changed)
	wait 20
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_WaistCondition" "${Me.Equipment[Waist].ToItemInfo.Condition}"
	
	; Set AdornmentSearchText based on RuneType, or return without needing a Rune Swap
	variable string AdornmentSearchText
	if ${RuneType.Equal["stun"]}
		AdornmentSearchText:Set["Adamant Defiance"]
	elseif ${RuneType.Equal["stifle"]}
		AdornmentSearchText:Set["Adamant Resolve"]
	elseif ${RuneType.Equal["mez"]}
		AdornmentSearchText:Set["Astral Dominion"]
	elseif ${RuneType.Equal["fear"]}
		AdornmentSearchText:Set["Blinding Gleam"]
	else
		return
	
	; Loop through each adornment to see if it has the correct Rune
	variable int AdornmentIndex=0
	while ${AdornmentIndex:Inc} <= ${Me.Equipment[Waist].ToItemInfo.NumAdornmentsAttached}
	{
		; If Adornment Name contains AdornmentSearchText, return without needing a Rune Swap
		if ${Me.Equipment[Waist].ToItemInfo.Adornment[${AdornmentIndex}].Name.Find[${AdornmentSearchText}]} >= 1
			return
	}
	
	; Didn't find adornment matching AdornmentSearchText, set character RuneSwapNeeded to TRUE
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RuneSwapNeeded" "TRUE"
}

function WaistCheck()
{
	; Check for Waist item equipped (timeout if more than 20 seconds to run)
	variable int Counter = 0
	while !${Me.Equipment[Waist].Name(exists)} && ${Counter:Inc} <= 200
	{
		wait 1
	}
	; Set character WaistEquipped to TRUE
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_WaistEquipped" "TRUE"
}

atom atexit()
{
	; Set variable indicating script complete
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RuneSwapCheckComplete" "TRUE"
}
