; Helper script to handle removing/adding Scoundrel's Slip adorn

variable string ApplyAdornComplete=FALSE

function main(string FunctionType)
{
	; Monitor IncomingText for ApplyAdornComplete
	Event[EQ2_onIncomingText]:AttachAtom[IncomingText]
	
	; Check FunctionType
	switch ${FunctionType}
	{
		case Check
			call CheckHateRune
			break
		case Apply
			call ApplyHateRune
			break
		case Remove
			call RemoveHateRune
			break
	}
}

function CheckHateRune()
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
	; Setup variables
	variable item HandsItem=${Me.Equipment[Hands].ID}
	variable item RangedItem=${Me.Equipment[Ranged].ID}
	variable string HandsItemAdornments[4]
	variable string RangedItemAdornments[4]
	variable int AdornmentIndex
	variable int HateRuneIndex
	variable int ScoundrelsSlipIndex
	variable int ContainerID
	; Make sure items exists, otherwise return because nothing to add to
	if !${HandsItem.ID(exists)}
	{
		oc ${Me.Name}: No Hands item found
		return
	}
	if !${RangedItem.ID(exists)}
	{
		oc ${Me.Name}: No Ranged item found
		return
	}
	; Make sure Item Info is available for the items
	while !${HandsItem.IsItemInfoAvailable}
	{
		waitframe
	}
	while !${RangedItem.IsItemInfoAvailable}
	{
		waitframe
	}
	; Set HandsCondition and RangedCondition (wait a couple seconds for Condition to update if it has recently changed)
	wait 20
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_HandsCondition" "${HandsItem.ToItemInfo.Condition}"
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RangedCondition" "${RangedItem.ToItemInfo.Condition}"
	; Loop through each hands adornment to get its name and see if Aggressiveness
	AdornmentIndex:Set[0]
	HateRuneIndex:Set[0]
	while ${AdornmentIndex:Inc} <= ${HandsItemAdornments.Size}
	{
		; Set Name
		HandsItemAdornments[${AdornmentIndex}]:Set[${HandsItem.ToItemInfo.Adornment[${AdornmentIndex}].Name}]
		; If Adornment Name contains Aggressiveness, set HateRuneIndex
		if ${HandsItemAdornments[${AdornmentIndex}].Find["Aggressiveness"]} >= 1
			HateRuneIndex:Set[${AdornmentIndex}]
	}
	; If HateRuneIndex > 0, set HasHateRune = TRUE
	if ${HateRuneIndex} > 0
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_HasHateRune" "TRUE"
	; Loop through each ranged adornment to get its name and see if Scoundrel's Slip
	AdornmentIndex:Set[0]
	ScoundrelsSlipIndex:Set[0]
	while ${AdornmentIndex:Inc} <= ${RangedItemAdornments.Size}
	{
		; Set Name
		RangedItemAdornments[${AdornmentIndex}]:Set[${RangedItem.ToItemInfo.Adornment[${AdornmentIndex}].Name}]
		; If Adornment Name contains Scoundrel's Slip, set ScoundrelsSlipIndex
		if ${RangedItemAdornments[${AdornmentIndex}].Find["Scoundrel's Slip"]} >= 1
			ScoundrelsSlipIndex:Set[${AdornmentIndex}]
	}
	; If ScoundrelsSlipIndex > 0, set HasScoundrelsSlip = TRUE
	if ${ScoundrelsSlipIndex} > 0
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_HasScoundrelsSlip" "TRUE"
	; Check to see if there is an Aggressiveness rune in the inventory to add
	if ${Me.Inventory[Query, Name =- "Aggressiveness" && Location == "Inventory"].ID(exists)}
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_HateRuneNeeded" "TRUE"
	; Check to see if there is a Scoundrel's Slip rune in the first slot in the first bag (indicating it was previously removed and needs to be re-added)
	ContainerID:Set[${Me.Inventory[Query, Location == "Inventory" && IsContainer = TRUE && Slot == 0].ContainerID}]
	if ${Me.Inventory[Query, Name =- "Scoundrel's Slip" && Location == "Inventory" && InContainerID == ${ContainerID} && Slot == 0].ID(exists)}
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_ScoundrelsSlipNeeded" "TRUE"
}

function ApplyHateRune()
{
	; Aggressiveness adornment will be applied to hands item
	; Scoundrel's Slip rune will be remove from Ranged item and moved to first slot in first bag
	
	; Setup variables
	variable item HandsItem=${Me.Equipment[Hands].ID}
	variable item RangedItem=${Me.Equipment[Ranged].ID}
	variable string HandsItemAdornments[4]
	variable string RangedItemAdornments[4]
	variable int AdornmentIndex
	variable int HateRuneIndex
	variable item HateRuneItem
	variable int ScoundrelsSlipIndex
	variable string HateRuneItemName
	variable int HateRuneItemContainerID
	variable int HateRuneItemSlot
	variable string OldHandsAdornmentName
	variable int Counter = 0
	variable item OldAdornment
	variable bool AdornmentFound
	variable int AttachAdornmentIndex
	variable item RuneItem
	
	; Make sure items exists, otherwise return because nothing to add to
	if !${HandsItem.ID(exists)}
	{
		oc ${Me.Name}: No Hands item found
		return
	}
	if !${RangedItem.ID(exists)}
	{
		oc ${Me.Name}: No Ranged item found
		return
	}
	; Make sure Item Info is available for the items
	while !${HandsItem.IsItemInfoAvailable}
	{
		waitframe
	}
	while !${RangedItem.IsItemInfoAvailable}
	{
		waitframe
	}
	; Loop through each hands adornment to get its name and see if Aggressiveness
	AdornmentIndex:Set[0]
	HateRuneIndex:Set[0]
	while ${AdornmentIndex:Inc} <= ${HandsItemAdornments.Size}
	{
		; Set Name
		HandsItemAdornments[${AdornmentIndex}]:Set[${HandsItem.ToItemInfo.Adornment[${AdornmentIndex}].Name}]
		; If Adornment Name contains Aggressiveness, set HateRuneIndex
		if ${HandsItemAdornments[${AdornmentIndex}].Find["Aggressiveness"]} >= 1
			HateRuneIndex:Set[${AdornmentIndex}]
	}
	; Look for HateRuneItem in inventory
	HateRuneItem:Set[${Me.Inventory[Query, Name =- "Aggressiveness" && Location == "Inventory"].ID}]
	; Loop through each adornment to get its name and see if Scoundrel's Slip
	AdornmentIndex:Set[0]
	ScoundrelsSlipIndex:Set[0]
	while ${AdornmentIndex:Inc} <= ${RangedItemAdornments.Size}
	{
		; Set Name
		RangedItemAdornments[${AdornmentIndex}]:Set[${RangedItem.ToItemInfo.Adornment[${AdornmentIndex}].Name}]
		; If Adornment Name contains Scoundrel's Slip, set ScoundrelsSlipIndex
		if ${RangedItemAdornments[${AdornmentIndex}].Find["Scoundrel's Slip"]} >= 1
			ScoundrelsSlipIndex:Set[${AdornmentIndex}]
	}
	; If no swaps to perform, return as successful
	if (${HateRuneIndex} > 0 || !${HateRuneItem.ID(exists)}) && ${ScoundrelsSlipIndex} == 0
	{	
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_ApplyHateRuneSuccessful" "TRUE"
		return
	}
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
	
	; Perform HateRuneItem swap if necessary
	if ${HateRuneIndex} == 0 && ${HateRuneItem.ID(exists)}
	{
		; Set HateRuneItemName
		HateRuneItemName:Set["${HateRuneItem.Name}"]
		; Get HateRuneItem current ContainerID and Slot
		HateRuneItemContainerID:Set["${HateRuneItem.InContainerID}"]
		HateRuneItemSlot:Set["${HateRuneItem.Slot}"]
		; Get Name of current Adornment in Slot 1
		OldHandsAdornmentName:Set["${HandsItem.ToItemInfo.Adornment[1].Name}"]
		; Unequip HandsItem
		Counter:Set[0]
		while !${HandsItem.Location.Equal[Inventory]} && ${Counter:Inc} <= 5
		{
			HandsItem:UnEquip
			wait 10
		}
		; Make sure HandsItem unequipped
		if !${HandsItem.Location.Equal[Inventory]}
		{
			oc ${Me.Name}: Failed to UnEquip ${HandsItem.Name}
			return
		}
		; Make sure Item Info is available for HateRuneItem
		while !${HateRuneItem.IsItemInfoAvailable}
		{
			waitframe
		}
		; Attach HateRuneItem to first slot
		ApplyAdornComplete:Set[FALSE]
		HateRuneItem.ToItemInfo:PrepAdornmentForUse
		wait 10
		HateRuneItem.ToItemInfo:AttachAsAdornment[${HandsItem.ID}, 0]
		Counter:Set[0]
		while !${ApplyAdornComplete} && ${Counter:Inc} <= 10
		{
			wait 10
		}
		; Press Escape to clear the attach adornment cursor
		press Esc
		; Make sure Item Info is available for the HandsItem
		while !${HandsItem.IsItemInfoAvailable}
		{
			waitframe
		}
		; Re-equip HandsItem
		Counter:Set[0]
		while !${HandsItem.Location.Equal[Equipment]} && ${Counter:Inc} <= 5
		{
			; Press Esc again just in case cursor is still weird for some reason
			press Esc
			wait 1
			; Equip HandsItem
			HandsItem:Equip
			wait 20
		}
		; Make sure HandsItem equipped
		if !${HandsItem.Location.Equal[Equipment]}
		{
			oc ${Me.Name}: Failed to Re-equip ${HandsItem.Name}
			return
		}
		; Look for Old Adornment
		if ${OldHandsAdornmentName.Length} > 0
		{
			OldAdornment:Set[${Me.Inventory[Query, Name == "${OldHandsAdornmentName}" && Location == "Inventory"].ID}]
			if ${OldAdornment.ID(exists)}
			{
				; Move Old Adornment if needed to previous Container and Slot of HateRuneItem
				if ${OldAdornment.InContainerID} != ${HateRuneItemContainerID} || ${OldAdornment.Slot} != ${HateRuneItemSlot}
					OldAdornment:Move[${HateRuneItemSlot},${HateRuneItemContainerID}]
			}
		}
		; Loop through each adornment to see if it matches HateRuneItemName
		AdornmentIndex:Set[0]
		AdornmentFound:Set[FALSE]
		while ${AdornmentIndex:Inc} <= ${HandsItemAdornments.Size}
		{
			; Look for Adornment Name matching HateRuneItemName
			if ${HandsItem.ToItemInfo.Adornment[${AdornmentIndex}].Name.Equal["${HateRuneItemName}"]}
				AdornmentFound:Set[TRUE]
		}
		; Check to see if swap was successful
		if ${AdornmentFound}
			oc ${Me.Name}: Swapped to ${HateRuneItemName} in Hands Slot 1
		else
		{
			oc ${Me.Name}: Hands Rune Swap Failed!
			return
		}
	}
	
	; Remove Scoundrel's Slip rune if necessary
	if ${ScoundrelsSlipIndex} > 0
	{
		; Unequip RangedItem
		Counter:Set[0]
		while !${RangedItem.Location.Equal[Inventory]} && ${Counter:Inc} <= 5
		{
			RangedItem:UnEquip
			wait 10
		}
		; Make sure item unequipped
		if !${RangedItem.Location.Equal[Inventory]}
		{
			oc ${Me.Name}: Failed to UnEquip ${RangedItem.Name}
			return
		}
		; Remove Adornments (Ability ID 2858354953 is Adornment Reclamation)
		Counter:Set[0]
		while ${RangedItem.ToItemInfo.NumAdornmentsAttached} > 0 && ${Counter:Inc} <= 5
		{
			; Use Adornment Reclamation on RangedItem
			Me.Ability[Query, ID == 2858354953]:Use
			wait 5
			RangedItem:ReclaimAdornments
			; Wait for reclamation to complete
			wait 10
			while ${Me.CastingSpell}
			{
				wait 1
			}
			; Refresh ItemInfo and wait a second for it to update
			while !${RangedItem.IsItemInfoAvailable}
			{
				waitframe
			}
			wait 10
		}
		; Press Escape to clear the attach adornment cursor
		press Esc
		; Make sure adornments removed
		if ${RangedItem.ToItemInfo.NumAdornmentsAttached} > 0
		{
			oc ${Me.Name}: Failed to remove adornments from ${RangedItem.Name}
			return
		}
		; Loop through adornments removed and re-attach all except Scoundrel's Slip
		AdornmentIndex:Set[0]
		AttachAdornmentIndex:Set[-1]
		while ${AdornmentIndex:Inc} <= ${RangedItemAdornments.Size}
		{
			; Increment AttachAdornmentIndex (need to skip index 1 for it to work properly)
			AttachAdornmentIndex:Inc
			if ${AttachAdornmentIndex} == 1
				AttachAdornmentIndex:Inc
			; Skip if ScoundrelsSlipIndex or adornment is empty
			if ${AdornmentIndex} == ${ScoundrelsSlipIndex} || ${RangedItemAdornments[${AdornmentIndex}].Equal["NULL"]}
				continue
			; Get RuneItem for removed adorn
			RuneItem:Set[${Me.Inventory[Query, Name == "${RangedItemAdornments[${AdornmentIndex}]}" && Location == "Inventory"].ID}]
			if !${RuneItem.ID(exists)}
			{
				oc ${Me.Name}: Unable to find adornment ${RangedItemAdornments[${AdornmentIndex}]} in Inventory after removing from ${RangedItem.Name}
				return
			}
			; Make sure Item Info is available for RuneItem
			while !${RuneItem.IsItemInfoAvailable}
			{
				waitframe
			}
			; Attach RuneItem to RangedItem
			ApplyAdornComplete:Set[FALSE]
			RuneItem.ToItemInfo:PrepAdornmentForUse
			wait 10
			RuneItem.ToItemInfo:AttachAsAdornment[${RangedItem.ID}, ${AttachAdornmentIndex}]
			Counter:Set[0]
			while !${ApplyAdornComplete} && ${Counter:Inc} <= 10
			{
				wait 10
			}
			; Press Escape to clear the attach adornment cursor
			press Esc
		}
		; Re-equip item
		Counter:Set[0]
		while !${RangedItem.Location.Equal[Equipment]} && ${Counter:Inc} <= 5
		{
			; Press Esc again just in case cursor is still weird for some reason
			press Esc
			wait 1
			; Equip RangedItem
			RangedItem:Equip
			wait 20
		}
		if !${RangedItem.Location.Equal[Equipment]}
		{
			oc ${Me.Name}: Failed to Re-equip ${RangedItem.Name}
			return
		}
		; Get Scoundrel's Slip rune that was removed
		RuneItem:Set[${Me.Inventory[Query, Name == "${RangedItemAdornments[${ScoundrelsSlipIndex}]}" && Location == "Inventory"].ID}]
		if !${RuneItem.ID(exists)}
		{
			oc ${Me.Name}: Unable to find adornment ${RangedItemAdornments[${ScoundrelsSlipIndex}]} in Inventory after removing from ${RangedItem.Name}
			return
		}
		; Move to first slot in first bag (will look for the rune there when checking if need to re-apply to ranged item)
		RuneItem:Move[0,${Me.Inventory[Query, Location == "Inventory" && IsContainer = TRUE && Slot == 0].ContainerID}]
		; Message Scoundrel's Slip removed
		oc ${Me.Name}: Removed ${RangedItemAdornments[${ScoundrelsSlipIndex}]} from ${RangedItem.Name}
	}
	
	; Resume Ogre
	oc !ci -Resume ${Me.Name}
	; Set ApplyHateRuneSuccessful
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_ApplyHateRuneSuccessful" "TRUE"
}

function RemoveHateRune()
{
	; Aggressiveness adornment will be removed from hands item by swapping with a Double Cast adorn (assume that is what was previously on the item)
	; Scoundrel's Slip rune in the first slot in the first bag will be applied to Slot 2 in the ranged item
	
	; Setup variables
	variable item HandsItem=${Me.Equipment[Hands].ID}
	variable item RangedItem=${Me.Equipment[Ranged].ID}
	variable string HandsItemAdornments[4]
	variable string RangedItemAdornments[4]
	variable int AdornmentIndex
	variable int HateRuneIndex
	variable item DoubleCastRuneItem
	variable int ContainerID
	variable item ScoundrelsSlipRuneItem
	variable string DoubleCastRuneItemName
	variable int DoubleCastRuneItemContainerID
	variable int DoubleCastRuneItemSlot
	variable string OldHandsAdornmentName
	variable int Counter = 0
	variable item OldAdornment
	variable bool AdornmentFound
	variable string ScoundrelsSlipRuneItemName
	variable int ScoundrelsSlipIndex
	
	; Make sure items exists, otherwise return because nothing to add to
	if !${HandsItem.ID(exists)}
	{
		oc ${Me.Name}: No Hands item found
		return
	}
	if !${RangedItem.ID(exists)}
	{
		oc ${Me.Name}: No Ranged item found
		return
	}
	; Make sure Item Info is available for the items
	while !${HandsItem.IsItemInfoAvailable}
	{
		waitframe
	}
	while !${RangedItem.IsItemInfoAvailable}
	{
		waitframe
	}
	; Loop through each hands adornment to get its name and see if Aggressiveness
	AdornmentIndex:Set[0]
	HateRuneIndex:Set[0]
	while ${AdornmentIndex:Inc} <= ${HandsItemAdornments.Size}
	{
		; Set Name
		HandsItemAdornments[${AdornmentIndex}]:Set[${HandsItem.ToItemInfo.Adornment[${AdornmentIndex}].Name}]
		; If Adornment Name contains Aggressiveness, set HateRuneIndex
		if ${HandsItemAdornments[${AdornmentIndex}].Find["Aggressiveness"]} >= 1
			HateRuneIndex:Set[${AdornmentIndex}]
	}
	; Look for DoubleCastRuneItem in inventory
	DoubleCastRuneItem:Set[${Me.Inventory[Query, Name =- "Double Cast" && Location == "Inventory"].ID}]
	; Look for Scoundrel's Slip rune in the first slot in the first bag
	ContainerID:Set[${Me.Inventory[Query, Location == "Inventory" && IsContainer = TRUE && Slot == 0].ContainerID}]
	ScoundrelsSlipRuneItem:Set[${Me.Inventory[Query, Name =- "Scoundrel's Slip" && Location == "Inventory" && InContainerID == ${ContainerID} && Slot == 0].ID}]
	; If no swaps to perform, return as successful
	if (${HateRuneIndex} == 0 || !${DoubleCastRuneItem.ID(exists)}) && !${ScoundrelsSlipRuneItem.ID(exists)}
	{	
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RemoveHateRuneSuccessful" "TRUE"
		return
	}
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
	
	; Perform HateRuneItem swap if necessary
	if ${HateRuneIndex} > 0 && ${DoubleCastRuneItem.ID(exists)}
	{
		; Set DoubleCastRuneItemName
		DoubleCastRuneItemName:Set["${DoubleCastRuneItem.Name}"]
		; Get DoubleCastRuneItem current ContainerID and Slot
		DoubleCastRuneItemContainerID:Set["${DoubleCastRuneItem.InContainerID}"]
		DoubleCastRuneItemSlot:Set["${DoubleCastRuneItem.Slot}"]
		; Get Name of current Adornment in Slot 1
		OldHandsAdornmentName:Set["${HandsItem.ToItemInfo.Adornment[1].Name}"]
		; Unequip HandsItem
		Counter:Set[0]
		while !${HandsItem.Location.Equal[Inventory]} && ${Counter:Inc} <= 5
		{
			HandsItem:UnEquip
			wait 10
		}
		; Make sure HandsItem unequipped
		if !${HandsItem.Location.Equal[Inventory]}
		{
			oc ${Me.Name}: Failed to UnEquip ${HandsItem.Name}
			return
		}
		; Make sure Item Info is available for DoubleCastRuneItem
		while !${DoubleCastRuneItem.IsItemInfoAvailable}
		{
			waitframe
		}
		; Attach DoubleCastRuneItem to first slot
		ApplyAdornComplete:Set[FALSE]
		DoubleCastRuneItem.ToItemInfo:PrepAdornmentForUse
		wait 10
		DoubleCastRuneItem.ToItemInfo:AttachAsAdornment[${HandsItem.ID}, 0]
		Counter:Set[0]
		while !${ApplyAdornComplete} && ${Counter:Inc} <= 10
		{
			wait 10
		}
		; Press Escape to clear the attach adornment cursor
		press Esc
		; Make sure Item Info is available for the HandsItem
		while !${HandsItem.IsItemInfoAvailable}
		{
			waitframe
		}
		; Re-equip HandsItem
		Counter:Set[0]
		while !${HandsItem.Location.Equal[Equipment]} && ${Counter:Inc} <= 5
		{
			; Press Esc again just in case cursor is still weird for some reason
			press Esc
			wait 1
			; Equip HandsItem
			HandsItem:Equip
			wait 20
		}
		; Make sure HandsItem equipped
		if !${HandsItem.Location.Equal[Equipment]}
		{
			oc ${Me.Name}: Failed to Re-equip ${HandsItem.Name}
			return
		}
		; Look for Old Adornment
		if ${OldHandsAdornmentName.Length} > 0
		{
			OldAdornment:Set[${Me.Inventory[Query, Name == "${OldHandsAdornmentName}" && Location == "Inventory"].ID}]
			if ${OldAdornment.ID(exists)}
			{
				; Move Old Adornment if needed to previous Container and Slot of DoubleCastRuneItem
				if ${OldAdornment.InContainerID} != ${DoubleCastRuneItemContainerID} || ${OldAdornment.Slot} != ${DoubleCastRuneItemSlot}
					OldAdornment:Move[${DoubleCastRuneItemSlot},${DoubleCastRuneItemContainerID}]
			}
		}
		; Loop through each adornment to see if it matches DoubleCastRuneItemName
		AdornmentIndex:Set[0]
		AdornmentFound:Set[FALSE]
		while ${AdornmentIndex:Inc} <= ${HandsItemAdornments.Size}
		{
			; Look for Adornment Name matching DoubleCastRuneItemName
			if ${HandsItem.ToItemInfo.Adornment[${AdornmentIndex}].Name.Equal["${DoubleCastRuneItemName}"]}
				AdornmentFound:Set[TRUE]
		}
		; Check to see if swap was successful
		if ${AdornmentFound}
			oc ${Me.Name}: Swapped to ${DoubleCastRuneItemName} in Hands Slot 1
		else
		{
			oc ${Me.Name}: Hands Rune Swap Failed!
			return
		}
	}
	
	; Apply Scoundrel's Slip rune if necessary
	if ${ScoundrelsSlipRuneItem.ID(exists)}
	{
		; Unequip RangedItem
		Counter:Set[0]
		while !${RangedItem.Location.Equal[Inventory]} && ${Counter:Inc} <= 5
		{
			RangedItem:UnEquip
			wait 10
		}
		; Make sure item unequipped
		if !${RangedItem.Location.Equal[Inventory]}
		{
			oc ${Me.Name}: Failed to UnEquip ${RangedItem.Name}
			return
		}
		; Make sure Item Info is available for ScoundrelsSlipRuneItem
		while !${ScoundrelsSlipRuneItem.IsItemInfoAvailable}
		{
			waitframe
		}
		; Get ScoundrelsSlipRuneItemName
		ScoundrelsSlipRuneItemName:Set["${ScoundrelsSlipRuneItem.Name}"]
		; Attach ScoundrelsSlipRuneItem to RangedItem in SLot 2
		ApplyAdornComplete:Set[FALSE]
		ScoundrelsSlipRuneItem.ToItemInfo:PrepAdornmentForUse
		wait 10
		ScoundrelsSlipRuneItem.ToItemInfo:AttachAsAdornment[${RangedItem.ID}, 2]
		Counter:Set[0]
		while !${ApplyAdornComplete} && ${Counter:Inc} <= 10
		{
			wait 10
		}
		; Press Escape to clear the attach adornment cursor
		press Esc
		; Make sure Item Info is available for the RangedItem
		while !${RangedItem.IsItemInfoAvailable}
		{
			waitframe
		}
		; Re-equip item
		Counter:Set[0]
		while !${RangedItem.Location.Equal[Equipment]} && ${Counter:Inc} <= 5
		{
			; Press Esc again just in case cursor is still weird for some reason
			press Esc
			wait 1
			; Equip RangedItem
			RangedItem:Equip
			wait 20
		}
		if !${RangedItem.Location.Equal[Equipment]}
		{
			oc ${Me.Name}: Failed to Re-equip ${RangedItem.Name}
			return
		}
		; Loop through each adornment to get its name and see if Scoundrel's Slip
		AdornmentIndex:Set[0]
		ScoundrelsSlipIndex:Set[0]
		while ${AdornmentIndex:Inc} <= ${RangedItemAdornments.Size}
		{
			; Set Name
			RangedItemAdornments[${AdornmentIndex}]:Set[${RangedItem.ToItemInfo.Adornment[${AdornmentIndex}].Name}]
			; If Adornment Name contains Scoundrel's Slip, set ScoundrelsSlipIndex
			if ${RangedItemAdornments[${AdornmentIndex}].Find["Scoundrel's Slip"]} >= 1
				ScoundrelsSlipIndex:Set[${AdornmentIndex}]
		}
		; Make sure Scoundrel's Slip was found on ranged item after being re-added
		if ${ScoundrelsSlipIndex} > 0
			oc ${Me.Name}: Added ${ScoundrelsSlipRuneItemName} to ${RangedItem.Name} Slot 2
		else
		{
			oc ${Me.Name}: ${ScoundrelsSlipRuneItemName} not found on ${RangedItem.Name} after attempting to re-add
			return
		}
	}
	
	; Resume Ogre
	oc !ci -Resume ${Me.Name}
	; Set RemoveHateRuneSuccessful
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_RemoveHateRuneSuccessful" "TRUE"
}

atom atexit()
{
	; Set variable indicating script complete
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_HateRuneComplete" "TRUE"
}

atom IncomingText(string Text)
{
	if ${Text.Find["You successfully applied"]} || ${Text.Find["You failed to apply"]}
		ApplyAdornComplete:Set[TRUE]
}
