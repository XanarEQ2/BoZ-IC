; Helper script for mend_and_rune_swap to see if we actually need to mend and swap

variable string ApplyAdornComplete=FALSE
variable int MaxWaistAdornments=3

function main(string FunctionType, string RuneType)
{
	; Check FunctionType
	switch ${FunctionType}
	{
		case Check
			call CheckSwap "${RuneType}"
			break
		case Swap
			call PerformSwap "${RuneType}"
			break
	}
}

function CheckSwap(string RuneType)
{
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
	
	; Get Waist item and make sure it is valid
	variable item WaistItem
	WaistItem:Set[${Me.Equipment[Waist].ID}]
	if ${WaistItem.ID} == 0
	{
		oc ${Me.Name}: No Waist item found
		return
	}
	
	; Make sure Item Info is available for the Waist item
	while !${WaistItem.IsItemInfoAvailable}
	{
		waitframe
	}
	
	; Set WaistCondition (wait a couple seconds for Condition to update if it has recently changed)
	wait 20
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_WaistCondition" "${WaistItem.ToItemInfo.Condition}"
	
	; Set AdornmentSearchText based on RuneType, or return without needing a Rune Swap
	variable string AdornmentSearchText
	call GetAdornmentSearchText "${RuneType}"
	AdornmentSearchText:Set["${Return}"]
	if ${AdornmentSearchText.Equal[Skip]}
		return
	
	; Loop through each adornment to see if it has the correct Rune
	variable int AdornmentIndex=0
	while ${AdornmentIndex:Inc} <= ${MaxWaistAdornments}
	{
		; If Adornment Name contains AdornmentSearchText, return without needing a Rune Swap
		if ${WaistItem.ToItemInfo.Adornment[${AdornmentIndex}].Name.Find[${AdornmentSearchText}]} >= 1
			return
	}
	
	; Didn't find adornment matching AdornmentSearchText, set character RuneSwapNeeded to TRUE
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RuneSwapNeeded" "TRUE"
}

function GetAdornmentSearchText(string RuneType)
{
	; Return string to search for in Adornment name that corresponds to RuneType
	if ${RuneType.Equal[stun]}
		return "Adamant Defiance"
	elseif ${RuneType.Equal[stifle]}
		return "Adamant Resolve"
	elseif ${RuneType.Equal[mez]}
		return "Astral Dominion"
	elseif ${RuneType.Equal[fear]}
		return "Blinding Gleam"
	else
		return "Skip"
}

function PerformSwap(string RuneType)
{
	; Get Waist item and make sure it is valid
	variable item WaistItem
	WaistItem:Set[${Me.Equipment[Waist].ID}]
	if ${WaistItem.ID} == 0
	{
		oc ${Me.Name}: No Waist item found
		return
	}
	
	; Make sure Item Info is available for the Waist item
	while !${WaistItem.IsItemInfoAvailable}
	{
		waitframe
	}
	
	; Set AdornmentSearchText based on RuneType, or return without needing a Rune Swap
	variable string AdornmentSearchText
	call GetAdornmentSearchText "${RuneType}"
	AdornmentSearchText:Set["${Return}"]
	if ${AdornmentSearchText.Equal[Skip]}
	{
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RuneSwapSuccessful" "TRUE"
		return
	}
	
	; Loop through each adornment to see if it has the correct Rune
	variable int AdornmentIndex=0
	while ${AdornmentIndex:Inc} <= ${MaxWaistAdornments}
	{
		; If Adornment Name contains AdornmentSearchText, return without needing a Rune Swap
		if ${WaistItem.ToItemInfo.Adornment[${AdornmentIndex}].Name.Find[${AdornmentSearchText}]} >= 1
		{
			oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RuneSwapSuccessful" "TRUE"
			return
		}
	}
	
	; Look for Rune to swap to (searching from Tier 3 down)
	variable item RuneItem
	variable string RuneItemName
	RuneItem:Set[${Me.Inventory[Query, Name =- "${AdornmentSearchText}" && Name =- "Tier 3" && Location == "Inventory"].ID}]
	if !${RuneItem.ID(exists)}
		RuneItem:Set[${Me.Inventory[Query, Name =- "${AdornmentSearchText}" && Name =- "Tier 2" && Location == "Inventory"].ID}]
	if !${RuneItem.ID(exists)}
		RuneItem:Set[${Me.Inventory[Query, Name =- "${AdornmentSearchText}" && Name =- "Tier 1" && Location == "Inventory"].ID}]
	if !${RuneItem.ID(exists)}
		RuneItem:Set[${Me.Inventory[Query, Name =- "${AdornmentSearchText}" && Name =- "Tier 0" && Location == "Inventory"].ID}]
	if !${RuneItem.ID(exists)}
		RuneItem:Set[${Me.Inventory[Query, Name =- "${AdornmentSearchText}" && Location == "Inventory"].ID}]
	if !${RuneItem.ID(exists)}
	{
		oc ${Me.Name}: No ${RuneType} rune found to swap to
		; Set Successful even though swap not performed because at least waist item wasn't unequipped
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RuneSwapSuccessful" "TRUE"
		return
	}
	else
		RuneItemName:Set["${RuneItem.Name}"]
	
	; Get RuneItem current ContainerID and Slot
	variable int RuneItemContainerID
	variable int RuneItemSlot
	RuneItemContainerID:Set["${RuneItem.InContainerID}"]
	RuneItemSlot:Set["${RuneItem.Slot}"]
	
	; Get Name of current Adornment in Slot 2
	variable string OldAdornmentName
	OldAdornmentName:Set["${WaistItem.ToItemInfo.Adornment[2].Name}"]
	
	; Make sure not in combat
	while ${Me.InCombat}
	{
		wait 10
	}
	
	; Pause Ogre
	oc !ci -Pause ${Me.Name}
	wait 3
	; Clear ability queue
	eq2execute clearabilityqueue
	; Cancel anything currently being cast
	oc !ci -CancelCasting ${Me.Name}
	wait 10
	
	; Unequip Waist item
	variable int Counter = 0
	while !${WaistItem.Location.Equal[Inventory]} && ${Counter:Inc} <= 5
	{
		WaistItem:UnEquip
		wait 10
	}
	if !${WaistItem.Location.Equal[Inventory]}
	{
		oc ${Me.Name}: Failed to UnEquip Waist item
		return
	}
	
	; Attach RuneItem to second slot
	Event[EQ2_onIncomingText]:AttachAtom[IncomingText]
	ApplyAdornComplete:Set[FALSE]
	wait 10
	; Calling PrepAdornmentForUse multiple times, for some reason it doesn't always work when just called once...
	RuneItem.ToItemInfo:PrepAdornmentForUse
	wait 10
	RuneItem.ToItemInfo:PrepAdornmentForUse
	wait 10
	RuneItem.ToItemInfo:PrepAdornmentForUse
	wait 10
	RuneItem.ToItemInfo:AttachAsAdornment[${WaistItem.ID}, 2]
	Counter:Set[0]
	while !${ApplyAdornComplete} && ${Counter:Inc} <= 10
	{
		wait 10
	}
	
	; Press Escape to clear the attach adornment cursor
	press Esc
	
	; Make sure Item Info is available for the Waist item
	while !${WaistItem.IsItemInfoAvailable}
	{
		waitframe
	}
	
	; Re-equip Waist item
	Counter:Set[0]
	while !${WaistItem.Location.Equal[Equipment]} && ${Counter:Inc} <= 5
	{
		; Press Esc again just in case cursor is still weird for some reason
		press Esc
		wait 1
		; Equip WaistItem
		WaistItem:Equip
		wait 20
	}
	if !${WaistItem.Location.Equal[Equipment]}
	{
		oc ${Me.Name}: Failed to Re-equip Waist item
		return
	}
	
	; Look for Old Adornment
	if ${OldAdornmentName.Length} > 0
	{
		variable item OldAdornment
		OldAdornment:Set[${Me.Inventory[Query, Name =- "${OldAdornmentName}" && Location == "Inventory"].ID}]
		if ${OldAdornment.ID(exists)}
		{
			; Move Old Adornment if needed to previous Container and Slot of RuneItem
			if ${OldAdornment.InContainerID} != ${RuneItemContainerID} || ${OldAdornment.Slot} != ${RuneItemSlot}
				OldAdornment:Move[${RuneItemSlot},${RuneItemContainerID}]
		}
	}
	
	; Loop through each adornment to see if it matches RuneItemName
	AdornmentIndex:Set[0]
	variable bool AdornmentFound=FALSE
	while ${AdornmentIndex:Inc} <= ${MaxWaistAdornments}
	{
		; Look for Adornment Name matching RuneItemName
		if ${WaistItem.ToItemInfo.Adornment[${AdornmentIndex}].Name.Equal["${RuneItemName}"]}
			AdornmentFound:Set[TRUE]
	}
	
	; Check to see if swap was successful
	if ${AdornmentFound}
	{
		oc ${Me.Name}: Swapped to ${RuneType} Immunity Rune in Waist Slot 2
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RuneSwapSuccessful" "TRUE"
	}
	else
		oc ${Me.Name}: Rune Swap Failed!
	
	; Resume Ogre
	oc !ci -Resume ${Me.Name}
}

atom atexit()
{
	; Set variable indicating script complete
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RuneSwapCheckComplete" "TRUE"
}

atom IncomingText(string Text)
{
	if ${Text.Find["You successfully applied"]} || ${Text.Find["You failed to apply"]}
		ApplyAdornComplete:Set[TRUE]
}

