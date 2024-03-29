; This Helper file requires IC_Helper file to function
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Support_Files_Common/IC_Helper.iss"
#include "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Ogre_Instance_Include.iss"

; Helper script for Aether Wroughtlands: Native Mettle
; Script should be placed in ...Scripts/EQ2OgreBot/InstanceController/Instance_Files/Custom/_Exp_20_Ballads_of_Zimara/Helper_Files/
function main(string _NamedNPC)
{
	switch ${_NamedNPC}
	{
		case The Aurum Outlaw
			call TheAurumOutlaw "${_NamedNPC}"
			break
		case Nugget
			call Nugget "${_NamedNPC}"
			break
	}
}

/*******************************************************************************************
    Named 1 **********************    The Aurum Outlaw   ***********************************
********************************************************************************************/

; For The Aurum Outlaw and "an aureate bandit" mobs
variable bool HOEnabled=FALSE
variable int LeftOptionNum=0
variable int RightOptionNum=0
variable bool SneakNeeded=FALSE
function TheAurumOutlaw(string _NamedNPC)
{
	; Handle text events
	Event[EQ2_onIncomingChatText]:AttachAtom[TheAurumOutlawIncomingChatText]
	; Start by enabling HO's on non-scout to trigger a Window of Opportunity
	call EnableNonScoutStartHO
	; Setup variables
	oc !ci -Set_Variable ${Me.Name} "NeedsFlecksCure" "None"
	oc !ci -Set_Variable ${Me.Name} "NeedsCurseCure" "None"
	oc !ci -Set_Variable ${Me.Name} "PullBanditCharacter" "None"
	variable int CurseCounter=0
	variable int FlecksCounter=0
	variable int CureFlecksCounter=0
	variable int DispelCounter=0
	variable string NeedsFlecksCure="None"
	variable string NeedsCurseCure="None"
	; Run as long as named is alive or there is an aureate bandit alive
	while ${Actor[namednpc,"${_NamedNPC}"].ID(exists)} || ${Actor[Query,Name=="an aureate bandit"].ID(exists)}
	{
		; Check to see if in combat
		if ${Me.InCombat}
		{
			; Handle sneak
			; 	When named is about to cast a barrage, scouts will get a message that they need to sneak
			; 	This will pop-up a conversation bubble with the named to choose Left or Right
			if ${SneakNeeded}
			{
				; Set SneakNeeded back to FALSE
				SneakNeeded:Set[FALSE]
				; Make sure character is not being sent out to pull a bandit
				if !${OgreBotAPI.Get_Variable["PullBanditCharacter"].Equal[${Me.Name}]}
				{
					; Pause Ogre
					oc !ci -Pause ${Me.Name}
					wait 3
					; Clear ability queue
					eq2execute clearabilityqueue
					; Cancel anything currently being cast
					oc !ci -CancelCasting ${Me.Name}
					; Cast Stealth ability depending on class
					oc !ci -CastAbility ${Me.Name}+assassin|ranger "Stealth"
					oc !ci -CastAbility ${Me.Name}+beastlord "Spiritshroud"
					oc !ci -CastAbility ${Me.Name}+brigand|swashbuckler "Sneak"
					oc !ci -CastAbility ${Me.Name}+dirge|Troubador "Shroud"
					wait 15
					; Resume Ogre
					oc !ci -Resume ${Me.Name}
				}
			}
			; If character is a scout, check to see if there is a conversation bubble
			; 	Appears when named preparing to cast barrage
			; 	Need to choose Left or Right side based on the position of named's gear and named will tell you if you are right or wrong
			; 		This is whether his eye patch and boot are on the Left or Right side of his body
			; 	If the answer is truthful need to cast Bulwark, if it is a lie need to not cast Bulwark
			; 		Setup so we always pick the correct option, which means the "That's correct!" or "That's right!" message will be a signal to Bulwark
			if ${Me.Archetype.Equal[scout]}
			{
				; Check to see if a conversation window exists
				if ${EQ2UIPage[ProxyActor,Conversation].IsVisible}
				{
					; Check to make sure Left/Right option num values have been set
					if ${LeftOptionNum} != 0 && ${RightOptionNum} != 0
					{
						; Choose option based on Equipment Appearance
						; 	Slot 1 will be 42088 if Left side and 42138 if Right side
						if ${Actor["${_NamedNPC}"].EquipmentAppearance[1].ID} == 42088
							oc !ci -ConversationBubble ${Me.Name} ${LeftOptionNum}
						elseif ${Actor["${_NamedNPC}"].EquipmentAppearance[1].ID} == 42138
							oc !ci -ConversationBubble ${Me.Name} ${RightOptionNum}
					}
				}
			}
			; Handle Quick Curse
			; 	Will be put on a random group member and expires very quickly
			; 	If it expires, that character gets an incurable "Not Quick Enough" Curse
			; 	Curing Quick Curse removes from all Not Quick Enough curses
			; Check to see if cursed with Quick Curse (if not already handled within last 5 seconds)
			if ${CurseCounter} < 0
				CurseCounter:Inc
			if ${CurseCounter} == 0
			{
				if ${Me.Effect[Query, "Detrimental" && MainIconID == 750 && BackDropIconID == 750].ID(exists)}
				{
					; Set NeedsCurseCure for group member to cure this character
					oc !ci -Set_Variable igw:${Me.Name} "NeedsCurseCure" "${Me.Name}"
					wait 1
					CurseCounter:Set[-10]
				}
			}
			; Check to see if anyone needs Quick Curse cured
			if ${Me.Archetype.Equal[priest]}
			{
				; Get NeedsCurseCure
				NeedsCurseCure:Set["${OgreBotAPI.Get_Variable["NeedsCurseCure"]}"]
				if ${NeedsCurseCure.Length} > 0 && !${NeedsCurseCure.Equal["None"]}
				{
					; Set NeedsCurseCure back to None
					oc !ci -Set_Variable igw:${Me.Name} "NeedsCurseCure" "None"
					; Pause Ogre
					oc !ci -Pause ${Me.Name}
					wait 3
					; Clear ability queue
					eq2execute clearabilityqueue
					; Cancel anything currently being cast
					oc !ci -CancelCasting ${Me.Name}
					; Cast Cure Curse
					oc !ci -CastAbilityOnPlayer ${Me.Name} "Cure Curse" "${NeedsCurseCure}" "0"
					; Resume Ogre
					oc !ci -Resume ${Me.Name}
				}
			}
			; Handle Flecks of Regret detrimental
			; 	Gets cast on everyone in group and deals damamge and power drains
			; 	If cured from entire group gets re-applied to entire group
			; 	Want to cure on everyone that is not a fighter
			; Check to see if this character needs to be cured (if not already handled within last 3 seconds)
			if ${FlecksCounter} < 0
				FlecksCounter:Inc
			if ${FlecksCounter} == 0 && !${Me.Archetype.Equal[fighter]}
			{
				if ${Me.Effect[Query, "Detrimental" && MainIconID == 1127 && BackDropIconID == 313].ID(exists)}
				{
					; Set NeedsFlecksCure for group member to cure this character
					oc !ci -Set_Variable igw:${Me.Name} "NeedsFlecksCure" "${Me.Name}"
					wait 1
					FlecksCounter:Set[-6]
				}
			}
			; Check to see if this character needs to cure Flecks of Regret from anyone (if not already handled within last 3 seconds)
			if ${CureFlecksCounter} < 0
				CureFlecksCounter:Inc
			if ${CureFlecksCounter} == 0 && ${Me.Archetype.Equal[priest]}
			{
				; Get NeedsFlecksCure
				NeedsFlecksCure:Set["${OgreBotAPI.Get_Variable["NeedsFlecksCure"]}"]
				if ${NeedsFlecksCure.Length} > 0 && !${NeedsFlecksCure.Equal["None"]}
				{
					; Set NeedsFlecksCure back to None
					oc !ci -Set_Variable igw:${Me.Name} "NeedsFlecksCure" "None"
					; Cure NeedsFlecksCure character
					oc !ci -CastAbilityOnPlayer ${Me.Name} "Cure" "${NeedsFlecksCure}" "0"
					CureFlecksCounter:Set[-6]
				}
			}
			; Handle HO settings and Hat Trick dispel
			; 	only run this on fighter when in combat, but will apply for everyone
			; Dishonorable effect does not allow The Aurum Outlaw or "an aureate bandit" mobs to be damaged unless Scout's Honor is active
			; Scout's Honor is triggered by completing an HO initiated by a scout
			; 	However, it must only be applied during a Window of Opportunity otherwise it kills the scout
			; A Window of Opportunity is triggered by completing an HO initiated by a non-scout
			; There will be 3 bandits with Hat Trick effect
			; 	if bandit dies while Hat Trick is maintained, it instead complete heals and kills person that landed the deathblow
			; 	can dispel to transfer to another aureate bandit
			if ${Me.Archetype.Equal[fighter]}
			{
				; Check to see if target has Hat Trick (if not already handled within last 3 seconds)
				if ${DispelCounter} < 0
					DispelCounter:Inc
				if ${DispelCounter} == 0
				{
					; Should always be first effect if it exists
					call CheckTargetEffect "Hat Trick" "1"
					if ${Return}
					{
						; Have mage cast Absorb Magic to dispel
						oc !ci -CastAbility igw:${Me.Name}+mage "Absorb Magic"
						DispelCounter:Set[-6]
					}
				}
				; Check to see if HO window is currently active
				; 	HO Window State: -1 = No active HO, 2 = Starter, 8 = Wheel, 9 = Completed/Failed
				if ${EQ2.HOWindowState} >= 2
				{
					; Disable starting any additional HO's
					if ${HOEnabled}
						call DisableStartHO
				}
				; Check to see if maintaining Scout's Honor with at least 50 seconds left
				elseif ${Me.Effect[Query, "Detrimental" && MainIconID == 814 && BackDropIconID == 814 && Duration >= 50].ID(exists)}
				{
					; Don't need any HO's right now
					if ${HOEnabled}
						call DisableStartHO
				}
				; Check to see if maintaining Window of Opportunity with at least 10 seconds left
				; 	Need to complete a scout HO while maintained, so don't want to start a scout HO if it won't be completed in time
				elseif ${Me.Effect[Query, "Detrimental" && MainIconID == 223 && BackDropIconID == 317 && Duration >= 10].ID(exists)}
				{
					; Enable Scout Start HO
					if !${HOEnabled}
						call EnableScoutStartHO
				}
				; Enable HO's on non-scout to trigger a Window of Opportunity
				elseif !${HOEnabled}
					call EnableNonScoutStartHO
			}
		}
		; Short wait before checking again
		wait 5
	}
	; Detach Atoms
	Event[EQ2_onIncomingChatText]:DetachAtom[TheAurumOutlawIncomingChatText]
}

atom TheAurumOutlawIncomingChatText(int ChatType, string Message, string Speaker, string TargetName, string SpeakerIsNPC, string ChannelName)
{
	; Look for message that a barrage is incoming
	; 	"Perhaps I'll cast a barrage!" or "Perhaps I'll cast another barrage!"
	; 	Scouts will get message the first time: "As a scout, only you can sneak and speak to The Aurum Outlaw to reveal the truth of its incoming barrage. Hint: if he's lying, do not Bulwark."
	; 		They need to sneak to pop-up a conversation bubble with the named to choose Left or Right
	if ${Message.Find["Perhaps I'll cast"]}
	{
		if ${Me.Archetype.Equal[scout]}
			SneakNeeded:Set[TRUE]
	}
	; Look for message that scout needs to choose Left or Right
	; 	Order of options varies based on tell The Aurum Outlaw sends to scout
	elseif ${Message.Find["Left or right?"]}
	{
		LeftOptionNum:Set[1]
		RightOptionNum:Set[2]
	}
	elseif ${Message.Find["Right or left?"]}
	{
		RightOptionNum:Set[1]
		LeftOptionNum:Set[2]
	}
	; Look for message that Bulwark needs to be cast
	; 	After answering message on scout which side of named it has its gear on, should get a response "That's correct!" or "That's right!"
	; 	If get a response that says "Wrong!" but you selected the correct side, that means the named is lying and you should not Bulwark
	; 	Need to delay the Bulwark by a bit, the barrage doesn't happen right away
	; 		also clear Left/Right option num after answer is given, want to make sure the values are reset when asked again
	elseif (${Message.Find["That's correct!"]} || ${Message.Find["That's right!"]})
	{
		oc !ci -CastAbilityInSeconds igw:${Me.Name}+fighter "Bulwark of Order" "5"
		LeftOptionNum:Set[0]
		RightOptionNum:Set[0]
	}
	
	; Debug text to see messages
	;echo ${ChatType}, ${Message}, ${Speaker}, ${TargetName}, ${SpeakerIsNPC}, ${ChannelName}
}

function EnableScoutStartHO()
{
	; Start HO with scout
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-scout checkbox_settings_ho_start FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+scout checkbox_settings_ho_start TRUE TRUE
	HOEnabled:Set[TRUE]
}

function EnableNonScoutStartHO()
{
	; Start HO with mage
	; 	Any non-scout would work, but choosing mage because it should be the fastest to complete
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+-mage checkbox_settings_ho_start FALSE TRUE
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+mage checkbox_settings_ho_start TRUE TRUE
	HOEnabled:Set[TRUE]
}

function DisableStartHO()
{
	; Disable HO Start for everyone
	oc !ci -ChangeOgreBotUIOption igw:${Me.Name} checkbox_settings_ho_start FALSE TRUE
	HOEnabled:Set[FALSE]
}

/*******************************************************************************************
    Named 2 **********************    Nugget   *********************************************
********************************************************************************************/

variable bool NuggetExists
variable bool NuggetStupendousSlamIncoming=FALSE
variable int NuggetSlamCounter
function Nugget(string _NamedNPC)
{
	; Handle text events
	Event[EQ2_onIncomingText]:AttachAtom[NuggetIncomingText]
	Event[EQ2_onAnnouncement]:AttachAtom[NuggetAnnouncement]
	; Default Variable values
	oc !ci -Set_Variable ${Me.Name} "${Me.Name}NeedsFlecksCure" "FALSE"
	oc !ci -Set_Variable ${Me.Name} "NeedsCurseCure" "None"
	; Setup variables
	variable int GroupNum
	variable int Counter
	variable string GroupMembers[6]
	variable int FlecksCounter=0
	variable bool CastingFlecksCure=FALSE
	variable int CurseCounter=0
	variable string NeedsCurseCure="None"
	variable int CombatEventCount=0
	variable int MineCheckCount=0
	variable int NuggetCheckCount=0
	variable actor Tree
	variable int AurumCount
	variable item AurumOre
	variable int AllMineCureDuration=7
	variable bool FoundNeedsFlecksCure=FALSE
	; Set AllMineCureDuration for fighter to cure at 15s remaining so it gets cured before non-fighters
	; 	This is to get Flecks re-applied to a fighter first so it doesn't get re-applied to the whole group when cured from non-fighters
	if ${Me.Archetype.Equal[fighter]}
		AllMineCureDuration:Set[10]
	; Get GroupMembers
	GroupNum:Set[0]
	while ${GroupNum:Inc} < ${Me.GroupCount}
	{
		GroupMembers[${GroupNum}]:Set["${Me.Group[${GroupNum}].Name}"]
	}
	GroupMembers[6]:Set["${Me.Name}"]
	; Check to see if character has too many aurum ore
	AurumOre:Set[${Me.Inventory[Query, Name == "aurum ore" && Location == "Inventory"].ID}]
	if ${AurumOre.ID(exists)} && ${AurumOre.Quantity} > ${OgreBotAPI.Get_Variable["${Me.Name}TargetAurumCount"]}
	{
		; Get number of excess ore
		variable int ExcessQuantity
		ExcessQuantity:Set[${AurumOre.Quantity} - ${OgreBotAPI.Get_Variable["${Me.Name}TargetAurumCount"]}]
		; Move excess ore to a new spot in bag
		AurumOre:Move[NextFreeNonBank,${ExcessQuantity}]
		wait 10
		; Update AurumOre with new new item matching ExcessQuantity
		AurumOre:Set[${Me.Inventory[Query, Name == "aurum ore" && Location == "Inventory" && Quantity == ${ExcessQuantity}].ID}]
		; Destroy excess ore
		if ${AurumOre.ID(exists)}
			AurumOre:Destroy
	}
	; Run as long as named is alive
	call CheckNuggetExists
	while ${NuggetExists}
	{
		; Handle Stupendous Slam (ID: 1177407465, Time = 3 sec)
		; 	Get message "Quick! Hold onto something! But not the same thing as anyone else!"
		; 	Named will cast a very large knockback that will most likely wipe the group
		; 	To avoid, have characters move to a tree and "Hold on!" giving them a temporary detrimental that roots them and prevents the knockback
		;		Holding on tight (MainIconID: 187, BackDropIconID 187)
		; 	Fighter will get message "As a fighter, you shrug off the attempted knock up.", so they don't need to move for this
		; Main script will move characters to trees, this script will click them to Hold on tight
		if ${NuggetStupendousSlamIncoming}
		{
			; Fighters don't need to Hold on
			if !${Me.Archetype.Equal[fighter]}
			{
				; Handle clicking tree for up to 10 seconds
				while ${NuggetSlamCounter:Inc} <= 100
				{
					; Look for tree within 10m to hold onto
					Tree:Set[${Actor[Query, Name == "Hold on tight!" && Distance < 10].ID}]
					if ${Tree.ID} != 0
					{
						; Make sure character is not moving (may pass by another tree on the way to destination tree)
						if !${Me.IsMoving}
						{
							; Click Tree
							Tree:DoubleClick
							wait 1
							NuggetSlamCounter:Inc
							; Check for Holding on tight detrimental
							if ${Me.Effect[Query, "Detrimental" && MainIconID == 187 && BackDropIconID == 187].ID(exists)}
								break
						}
					}
					; Short wait before checking again
					wait 1
				}
			}
			; Consider the Slam handled
			NuggetStupendousSlamIncoming:Set[FALSE]
		}
		; Handle Flecks of Regret detrimental
		; 	Gets cast on everyone in group and deals damamge and power drains
		; 	If cured from entire group gets re-applied to entire group
		; 	Want to cure on everyone that is not a fighter
		; Check to see if this character needs to be cured
		if ${FlecksCounter} < 0
			FlecksCounter:Inc
		if ${FlecksCounter} == 0 && !${Me.Archetype.Equal[fighter]}
		{
			if ${Me.Effect[Query, "Detrimental" && MainIconID == 1127 && BackDropIconID == 313].ID(exists)}
			{
				; Set NeedsFlecksCure for group member to cure this character
				oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}NeedsFlecksCure" "TRUE"
				wait 1
				FlecksCounter:Set[-50]
			}
		}
		; Check to see if this character needs to cure Flecks of Regret from anyone
		; 	Don't try to cure on the move or if not near KillSpot
		if ${Me.Archetype.Equal[priest]} && !${Me.IsMoving} && ${Math.Distance[${Me.X},${Me.Z},752.10,156.93]} < 20
		{
			; Loop as long as there is someone that needs a Flecks Cure
			do
			{
				; Default FoundNeedsFlecksCure to FALSE
				FoundNeedsFlecksCure:Set[FALSE]
				; Loop through each Group member, checking to see if NeedsFlecksCure = TRUE
				GroupNum:Set[0]
				while ${GroupNum:Inc} <= ${GroupMembers.Size}
				{
					; Check NeedsFlecksCure, skip if not TRUE
					if !${OgreBotAPI.Get_Variable["${GroupMembers[${GroupNum}]}NeedsFlecksCure"].Equal["TRUE"]}
						continue
					; Make sure Group member is in Cure range
					if !${Actor[Query, Name == "${GroupMembers[${GroupNum}]}" && (Type == "PC" || Type == "Me") && Distance <= 15].ID(exists)}
						continue
					; Set FoundNeedsFlecksCure = TRUE
					FoundNeedsFlecksCure:Set[TRUE]
					; Setup for casting Cure if this is the first character being cured
					if !${CastingFlecksCure}
					{
						CastingFlecksCure:Set[TRUE]
						; Pause Ogre
						oc !ci -Pause ${Me.Name}
						wait 3
						; Clear ability queue
						eq2execute clearabilityqueue
						; Cancel anything currently being cast
						oc !ci -CancelCasting ${Me.Name}
					}
					; Cast Cure
					oc !ci -CastAbilityOnPlayer ${Me.Name} "Cure" "${GroupMembers[${GroupNum}]}" "0"
					; Wait for Cure to start casting (up to 2 seconds)
					Counter:Set[0]
					while !${Me.CastingSpell} && ${Counter:Inc} <= 20
					{
						wait 1
					}
					; Wait for Cure to be completed (up to 2 seconds)
					Counter:Set[0]
					while ${Me.CastingSpell} && ${Counter:Inc} <= 20
					{
						wait 1
					}
					; Wait for recovery
					wait 4
					; Set NeedsFlecksCure back to FALSE
					oc !ci -Set_Variable igw:${Me.Name} "${GroupMembers[${GroupNum}]}NeedsFlecksCure" "FALSE"
					wait 1
				}
			}
			while ${FoundNeedsFlecksCure}
			; Check to see if Cure was cast to Resume when completed
			if ${CastingFlecksCure}
			{
				wait 1
				CastingFlecksCure:Set[FALSE]
				; Resume Ogre
				oc !ci -Resume ${Me.Name}
			}
		}
		; Check every second for combat events that don't need immediate response
		if ${CombatEventCount:Inc} >= 10
		{
			; Handle All Mine curse (MainIconID: 773, BackDropIconID 773)
			; 	Cast on everyone when named buries itself and spawns unearthed aurum clusters
			; 	Allows harvesting of a single unearthed aurum cluster
			; 	Kills target on expiration (30s)
			; 	Curing from a single character sets duration back to 30 for all still afllicataed
			; 	Harvesting aurum cluster clears Cure Curse reuse for all priests
			; 	Harvesting all clusters clears from group
			; General idea is have the characters that don't need to harvest call for a Cure Curse if < 10 seconds remaining on Curse
			if ${CurseCounter} < 0
				CurseCounter:Inc
			if ${CurseCounter} == 0
			{
				if ${Me.Effect[Query, "Detrimental" && MainIconID == 773 && BackDropIconID == 773 && Duration < ${AllMineCureDuration}].ID(exists)}
				{
					; Check to see if character has all of the aurum that they need
					AurumOre:Set[${Me.Inventory[Query, Name == "aurum ore" && Location == "Inventory"].ID}]
					if ${AurumOre.ID(exists)}
						AurumCount:Set[${AurumOre.Quantity}]
					else
						AurumCount:Set[0]
					if ${AurumCount} == ${OgreBotAPI.Get_Variable["${Me.Name}TargetAurumCount"]}
					{
						; Set NeedsCurseCure for group member to cure this character
						oc !ci -Set_Variable igw:${Me.Name} "NeedsCurseCure" "${Me.Name}"
						wait 1
						CurseCounter:Set[-5]
					}
				}
			}
			; Check to see if anyone needs All Mine cured
			if ${Me.Archetype.Equal[priest]}
			{
				; Get NeedsCurseCure
				NeedsCurseCure:Set["${OgreBotAPI.Get_Variable["NeedsCurseCure"]}"]
				if ${NeedsCurseCure.Length} > 0 && !${NeedsCurseCure.Equal["None"]}
				{
					; Set AutoCurse for this character to cure NeedsCurseCure character
					oc !ci -AutoCurse ${Me.Name} ${NeedsCurseCure}
					; Add wait time for curse to be cured
					wait 30
					; Set NeedsCurseCure back to None
					oc !ci -Set_Variable igw:${Me.Name} "NeedsCurseCure" "None"
					wait 1
				}
			}
			CombatEventCount:Set[0]
		}
		; Check every second to mine Aurum if needed
		if ${MineCheckCount:Inc} >= 10
		{
			call MineAurum
			MineCheckCount:Set[0]
		}
		; Update NuggetExists every 3 seconds
		if ${NuggetCheckCount:Inc} >= 30
		{
			call CheckNuggetExists
			NuggetCheckCount:Set[0]
		}
		; Short wait before looping (to respond as quickly as possible to events)
		wait 1
	}
	; Detach Atoms
	Event[EQ2_onIncomingText]:DetachAtom[NuggetIncomingText]
	Event[EQ2_onAnnouncement]:DetachAtom[NuggetAnnouncement]
}

atom NuggetIncomingText(string Text)
{
	; Look for message that Stupendous Slam is incoming
	if ${Text.Find["Hold on tight!"]}
	{
		NuggetStupendousSlamIncoming:Set[TRUE]
		NuggetSlamCounter:Set[0]
	}
}

atom NuggetAnnouncement(string Text, string SoundType, float Timer)
{
	; Look for message that Stupendous Slam is incoming
	if ${Text.Find["Quick! Hold onto something! But not the same thing as anyone else!"]}
	{
		NuggetStupendousSlamIncoming:Set[TRUE]
		NuggetSlamCounter:Set[0]
	}
}

function MineAurum()
{
	; See if there is a nearby aurum cluster
	variable actor AurumCluster
	AurumCluster:Set[${Actor[Query, Name =- "aurum cluster" && Distance < 8].ID}]
	if ${AurumCluster.ID} == 0
		return
	; Make sure not in combat with a gleaming goldslug
	if ${Actor[Query, Name == "a gleaming goldslug" && Target.ID != 0].ID(exists)}
		return
	; Check to see if character needs to mine additional aurum
	variable int AurumCount
	variable item AurumOre
	AurumOre:Set[${Me.Inventory[Query, Name == "aurum ore" && Location == "Inventory"].ID}]
	if ${AurumOre.ID(exists)}
		AurumCount:Set[${AurumOre.Quantity}]
	else
		AurumCount:Set[0]
	if ${AurumCount} >= ${OgreBotAPI.Get_Variable["${Me.Name}TargetAurumCount"]}
		return
	; Pause Ogre
	oc !ci -Pause ${Me.Name}
	wait 3
	; Clear ability queue
	eq2execute clearabilityqueue
	; Cancel anything currently being cast
	oc !ci -CancelCasting ${Me.Name}
	; Mine Aurum Cluster
	wait 3
	AurumCluster:DoTarget
	wait 3
	AurumCluster:DoubleClick
	; Wait to finish mining aurum
	wait 5
	while ${Me.CastingSpell}
	{
		wait 1
	}	
	; Resume Ogre
	oc !ci -Resume ${Me.Name}
}

function CheckNuggetExists()
{
	; Assume NuggetExists if in Combat
	if ${Me.InCombat}
	{
		NuggetExists:Set[TRUE]
		return
	}
	; Have seen him disappear briefly even when not killed, so repeat check multiple times just to make sure he is actually gone
	variable int Counter=0
	while ${Counter:Inc} <= 5
	{
		; Check to see if Nugget exists
		if ${Actor[Query,Name=="Nugget" && Type != "Corpse"].ID(exists)}
		{
			NuggetExists:Set[TRUE]
			return
		}
	}
	; Nugget not found
	NuggetExists:Set[FALSE]
}
