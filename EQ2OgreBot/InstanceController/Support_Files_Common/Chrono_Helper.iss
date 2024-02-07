; Helper script for Chrono zones
; Script should be placed in ...Scripts/EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/
function main()
{
	; Get Chrono Dungeons: [Level 130] item
	variable item ChronoDungeonsItem
	ChronoDungeonsItem:Set[${Me.Inventory[Query, Name =- "Chrono Dungeons: [Level 130]"].ID}]
	; If the item was found, update ChronoCount with Quantity
	if ${ChronoDungeonsItem.ID(exists)}
		oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_ChronoCount" "${ChronoDungeonsItem.Quantity}"
}

atom atexit()
{
	; Set variable indicating script complete
	oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}_ChronoCountComplete" "TRUE"
}
