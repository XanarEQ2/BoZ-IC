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
		case Coppernicus
			call Coppernicus "${_NamedNPC}"
			break
		case Goldfeather
			call Goldfeather "${_NamedNPC}"
			break
		case Goldan
			call Goldan "${_NamedNPC}"
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
	oc !ci -Set_Variable ${Me.Name} "NeedsCurseCure" "None"
	; Setup variables
	variable int GroupNum
	variable int Counter
	variable int SecondLoopCount=10
	variable string GroupMembers[6]
	variable int FlecksCounter=0
	variable bool CastingFlecksCure=FALSE
	variable int CurseCounter=0
	variable string NeedsCurseCure="None"
	variable int PeelCounter=0
	variable int NuggetCheckCount=0
	variable actor Tree
	variable int AurumCount
	variable item AurumOre
	variable int AllMineCureDuration=7
	variable bool FoundNeedsFlecksCure=FALSE
	; Set AllMineCureDuration for fighter to cure at 10s remaining so it gets cured before non-fighters
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
				NuggetSlamCounter:Set[0]
				while ${NuggetSlamCounter:Inc} <= 100
				{
					; Look for tree within 10m to hold onto
					Tree:Set[${Actor[Query, Name == "Hold on tight!" && Distance < 10].ID}]
					if ${Tree.ID} != 0
					{
						; Make sure character is not moving (may pass by another tree on the way to destination tree)
						if !${Me.IsMoving}
						{
							; **************************************
							; DEBUG TEXT
							oc ${Me.Name} Click Tree at distance ${Tree.Distance} away
							; **************************************
							
							; Click Tree
							Tree:DoubleClick
							wait 1
							; Check for Holding on tight detrimental
							if ${Me.Effect[Query, "Detrimental" && MainIconID == 187 && BackDropIconID == 187].ID(exists)}
							{
								; **************************************
								; DEBUG TEXT
								oc ${Me.Name} Have Holding on Tight detrimental
								; **************************************
								
								break
							}
						}
					}
					; Short wait before checking again
					NuggetSlamCounter:Inc
					wait 1
				}
			}
			; Consider the Slam handled
			NuggetStupendousSlamIncoming:Set[FALSE]
		}
		; Perform checks every second
		if ${SecondLoopCount:Inc} >= 10
		{
			; Handle Flecks of Regret detrimental
			; 	Gets cast on everyone in group and deals damamge and power drains
			; 	If cured from entire group gets re-applied to entire group
			; 	Want to cure on everyone except fighter
			; Check to see if this character needs to be cured (if not already handled within last 2 seconds)
			; 	Using cure pots to cure
			if ${FlecksCounter} < 0
				FlecksCounter:Inc
			if ${FlecksCounter} == 0 && !${Me.Archetype.Equal[fighter]}
			{
				if ${Me.Effect[Query, "Detrimental" && MainIconID == 1127 && BackDropIconID == 313].ID(exists)}
				{
					; Use cure pot to cure
					oc !ci -UseItem ${Me.Name} "Zimaran Cure Trauma"
					FlecksCounter:Set[-2]
				}
			}
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
			; Check to mine Aurum if needed
			call MineAurum
			; Handle Precious Peel (MainIconID: 295, BackDropIconID 295)
			; 	Damage and forced target to the slug
			; 	Want to prevent the forced target on fighters so they can get aggro on each slug
			if ${PeelCounter} < 0
				PeelCounter:Inc
			if ${PeelCounter} == 0 && ${Me.Archetype.Equal[fighter]}
			{
				; Check to see if fighter has Precious Peel
				if ${Me.Effect[Query, "Detrimental" && MainIconID == 295 && BackDropIconID == 295].ID(exists)}
				{
					; Check to see if there is a slug not targeting fighter
					if ${Actor[Query, Name == "a gleaming goldslug" && Target.ID != 0 && Target.ID != ${Me.ID}].ID(exists)}
					{
						; For crusaders, can cast Aura of the Crusader to become immune to forced target
						if ${Me.Class.Equal[crusader]}
							oc !ci -CastAbility ${Me.Name} "Aura of the Crusader"
						; For other characters, use cure pot to remove (don't want to cure and also remove Flecks of Regret)
						else
							oc !ci -UseItem ${Me.Name} "Zimaran Cure Elemental"
					}
					PeelCounter:Set[-3]
				}
			}
			; Reset SecondLoopCount
			SecondLoopCount:Set[0]
		}
		; Short wait before looping (to respond as quickly as possible to events)
		wait 1
		; Update NuggetExists every 3 seconds
		if ${NuggetCheckCount:Inc} >= 30
		{
			call CheckNuggetExists
			NuggetCheckCount:Set[0]
		}
	}
	; Detach Atoms
	Event[EQ2_onIncomingText]:DetachAtom[NuggetIncomingText]
	Event[EQ2_onAnnouncement]:DetachAtom[NuggetAnnouncement]
}

atom NuggetIncomingText(string Text)
{
	; Look for message that Stupendous Slam is incoming
	if ${Text.Find["Hold on tight!"]}
		NuggetStupendousSlamIncoming:Set[TRUE]
}

atom NuggetAnnouncement(string Text, string SoundType, float Timer)
{
	; Look for message that Stupendous Slam is incoming
	if ${Text.Find["Quick! Hold onto something! But not the same thing as anyone else!"]}
		NuggetStupendousSlamIncoming:Set[TRUE]
}

function MineAurum()
{
	; See if there is a nearby aurum cluster
	variable actor AurumCluster
	AurumCluster:Set[${Actor[Query, Name =- "aurum cluster" && Distance < 8].ID}]
	if ${AurumCluster.ID} == 0
		return
	
	
	
	; **************************************
	; DEBUG TEXT
	if ${Me.InCombat}
		oc ${Me.Name} Nearby ore at distance ${AurumCluster.Distance} away
	; **************************************
	
	
	
	; Check to see if character needs to mine additional aurum
	variable int AurumCount
	variable item AurumOre
	AurumOre:Set[${Me.Inventory[Query, Name == "aurum ore" && Location == "Inventory"].ID}]
	if ${AurumOre.ID(exists)}
		AurumCount:Set[${AurumOre.Quantity}]
	else
		AurumCount:Set[0]
	
	
	
	; **************************************
	; DEBUG TEXT
	if ${Me.InCombat}
		oc ${Me.Name} My aurum count ${AurumCount} target ${OgreBotAPI.Get_Variable["${Me.Name}TargetAurumCount"]}
	; **************************************
	
	
	
	if ${AurumCount} >= ${OgreBotAPI.Get_Variable["${Me.Name}TargetAurumCount"]}
		return
	; Check to see if character has Precious Peel, which would prevent them from mining
	if ${Me.Effect[Query, "Detrimental" && MainIconID == 295 && BackDropIconID == 295].ID(exists)}
	{
		; Have priest cure Precious Peel so character can mine
		oc !ci -CastAbilityOnPlayer igw:${Me.Name}+priest "Cure" "${Me.Name}" "0"
		return
	}
	
	
	; **************************************
	; DEBUG TEXT
	if ${Me.InCombat}
		oc ${Me.Name} Mining ore at distance ${AurumCluster.Distance} away
	; **************************************
	
	
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

/*******************************************************************************************
    Named 3 **********************    Coppernicus   ****************************************
********************************************************************************************/

variable bool CoppernicusAbsorbIncoming=FALSE
variable bool CoppernicusExists
variable string CoppernicusPriestTank
function Coppernicus(string _NamedNPC)
{
	; Handle text events
	Event[EQ2_onIncomingChatText]:AttachAtom[CoppernicusIncomingChatText]
	; Get variables
	CoppernicusPriestTank:Set["${OgreBotAPI.Get_Variable["CoppernicusPriestTank"]}"]
	; Setup variables
	variable int Counter
	variable int SecondLoopCount=10
	variable int CoppernicusExistsCount=0
	variable string CoppernicusPhase
	variable point3f CoppernicusLoc
	variable index:actor Materia
	variable iterator MateriaIterator
	variable actor TargetMateria
	variable actor CoppernicusTarget
	variable effect HelioEffect
	variable bool HelioActive=FALSE
	variable int FlecksCounter=0
	variable time NeedFlecksCureTime=${Time.Timestamp}
	variable string NeedsMezzyCure="None"
	
	; **************************************
	; DEBUG TEXT
	variable time AggroTime
	variable time LastInterruptTime
	; **************************************
	
	; Run as long as named is alive
	call CheckCoppernicusExists
	while ${CoppernicusExists}
	{
		
		; **************************************
		; DEBUG TEXT
		; Set AggroTime
		if ${AggroTime.Timestamp} == 0
			if ${Actor["Coppernicus"].Target.ID} != 0
				AggroTime:Set[${Time.Timestamp}]
		; **************************************
		
		; Handle "Absorb Celestial Materia"
		; 	Named casts spell that consumes a celestial materia and heals/buffs him
		; 	After interrupt, will charge towards the character who interrupted him
		if ${CoppernicusAbsorbIncoming}
		{
			; Only interrupt if this character is not a fighter (keep fighter on the celestial materia)
			if !${Me.Archetype.Equal[fighter]}
			{
				; Make sure named is targeted
				Actor["${_NamedNPC}"]:DoTarget
				
				; **************************************
				; DEBUG TEXT
				if ${LastInterruptTime.Timestamp} > 0
					oc ${Me.Name} Interrupt at ${Actor["Coppernicus"].Health} HP after ${Math.Calc[${Time.Timestamp}-${LastInterruptTime.Timestamp}]} seconds from last
				else
					oc ${Me.Name} Interrupt at ${Actor["Coppernicus"].Health} HP after ${Math.Calc[${Time.Timestamp}-${AggroTime.Timestamp}]} seconds from start
				LastInterruptTime:Set[${Time.Timestamp}]
				; **************************************

				; Cast Interrupt
				call CastInterrupt "FALSE"
			}
			; Set Absorb Celestial Materia as handled
			CoppernicusAbsorbIncoming:Set[FALSE]
		}
		; Perform checks every second
		if ${SecondLoopCount:Inc} >= 10
		{
			; Get CoppernicusPhase
			CoppernicusPhase:Set["${OgreBotAPI.Get_Variable["CoppernicusPhase"]}"]
			; Setup target based on Archetype
			; For fighter, target any celestial materia that isn't targeting fighter, otherwise target celestial materia with highest hp
			if ${Me.Archetype.Equal[fighter]}
			{
				; If PrePull, update CoppernicusLoc
				if ${CoppernicusPhase.Equal["PrePull"]}
					CoppernicusLoc:Set[${Actor["${_NamedNPC}"].Loc}]
				; Query all materia within 50m
				EQ2:QueryActors[Materia, Name=="celestial materia" && Type != "Corpse" && Distance < 50]
				Materia:GetIterator[MateriaIterator]
				if ${MateriaIterator:First(exists)}
				{
					; Loop through materia
					do
					{
						; If PrePull, don't target celestial materia if within 15m of named
						if ${CoppernicusPhase.Equal["PrePull"]}
							if ${Math.Distance[${MateriaIterator.Value.X},${MateriaIterator.Value.Z},${CoppernicusLoc.X},${CoppernicusLoc.Z}]} < 15
								continue
						; If TargetMateria doesn't exist, set it
						if !${TargetMateria.ID(exists)}
							TargetMateria:Set[${MateriaIterator.Value.ID}]
						; Check to see if Materia is not targeting fighter
						if ${MateriaIterator.Value.Target.ID} != ${Me.ID}
						{
							; If TargetMateria is already targeting fighter, set as new Materia that isn't
							if ${TargetMateria.Target.ID} == ${Me.ID}
								TargetMateria:Set[${MateriaIterator.Value.ID}]
							; Otherwise set as new Materia if closer
							elseif ${MateriaIterator.Value.Distance} < ${TargetMateria.Distance}
								TargetMateria:Set[${MateriaIterator.Value.ID}]
						}
						; Otherwise set as new Materia if higher HP
						elseif ${MateriaIterator.Value.Health} > ${TargetMateria.Health}
							TargetMateria:Set[${MateriaIterator.Value.ID}]
					}
					while ${MateriaIterator:Next(exists)}
				}
				; If TargetMateria exists, target it
				if ${TargetMateria.ID(exists)}
					TargetMateria:DoTarget
				; If no TargetMateria, target self (don't want to aggro named)
				else
					Me:DoTarget
			}
			; For non-fighters, set target based on CoppernicusPhase
			else
			{
				; For PrePull phase, have characters target themselves
				if ${CoppernicusPhase.Equal["PrePull"]}
					Me:DoTarget
				; Otherwise target either Coppernicus or any roaming adds that may join the fight
				else
				{
					CoppernicusTarget:Set[${Actor[Query,Name != "Coppernicus" && Name != "celestial materia" && Type != "Corpse" && Type =- "NPC" && Target.ID != 0 && Distance < 50].ID}]
					if ${CoppernicusTarget.ID(exists)}
						CoppernicusTarget:DoTarget
					else
						Actor["${_NamedNPC}"]:DoTarget
				}
			}
			; Handle Heliocentric detrimental
			; 	When it expires, character's range to Coppernicus must match number of increments on the detrimental +/- 1m
			; 	Otherwise character dies
			; Note there seems to be an offset between the displayed distance to Coppernicus and the calculated distance of ~5m
			; 	So setting HelioDistance as the CurrentIncrements + 5
			; 	Have also seen some weird cases where Helio shows as active with an extremely high Duration, so only count if Duration < 60
			HelioEffect:Set[${Me.Effect[Query, "Detrimental" && MainIconID == 423 && BackDropIconID == -1].ID}]
			if ${HelioEffect.ID(exists)} && ${HelioEffect.Duration} < 60
			{
				; Set HelioDistance for this character as CurrentIncrements and set HelioDuration
				oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}HelioDistance" "${Math.Calc[${HelioEffect.CurrentIncrements}+5]}"
				oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}HelioDuration" "${HelioEffect.Duration}"
				; Set HelioActive = TRUE
				HelioActive:Set[TRUE]
			}
			elseif ${HelioActive}
			{
				; Clear HelioDistance and HelioDuration for this character
				oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}HelioDistance" "0"
				oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}HelioDuration" "0"
				; Set HelioActive = FALSE
				HelioActive:Set[FALSE]
			}
			; Make sure CoppernicusPhase is Fight
			if ${CoppernicusPhase.Equal["Fight"]}
			{
				; Handle Flecks of Regret detrimental
				; 	Gets cast on everyone in group and deals damamge and power drains
				; 	If cured from entire group gets re-applied to entire group
				; 	Want to cure on everyone except CoppernicusFlecksCharacter
				; 		However have CoppernicusFlecksCharacter cure themselves every 5 minutes because flecks being on a long time can cause it to start spiking up to 100B+ damage
				; Check to see if this character needs to be cured (if not already handled within last 2 seconds)
				if ${FlecksCounter} < 0
					FlecksCounter:Inc
				if ${FlecksCounter} == 0
				{
					if ${Me.Effect[Query, "Detrimental" && MainIconID == 1127 && BackDropIconID == 313].ID(exists)}
					{
						; Make sure Absorb is not incoming
						if !${CoppernicusAbsorbIncoming}
						{
							; If character is CoppernicusFlecksCharacter, only cure themselves if 3 minutes have passed since last cure
							if ${Me.Name.Equal[${OgreBotAPI.Get_Variable["CoppernicusFlecksCharacter"]}]}
							{
								if ${Math.Calc[${Time.Timestamp}-${NeedFlecksCureTime.Timestamp}]} > 180
								{
									oc !ci -UseItem ${Me.Name} "Zimaran Cure Elemental"
									NeedFlecksCureTime:Set[${Time.Timestamp}]
								}
							}
							; Have mages cure themselves
							elseif ${Me.Archetype.Equal[mage]}
								oc !ci -CastAbilityOnPlayer ${Me.Name} "Cure Magic" "${Me.Name}" "0"
							; Have everyone else use a cure pot
							else
								oc !ci -UseItem ${Me.Name} "Zimaran Cure Elemental"
							FlecksCounter:Set[-2]
						}
					}
				}
			}
			; Reset SecondLoopCount
			SecondLoopCount:Set[0]
		}
		; If Absorb is not incoming, short wait before looping (to respond as quickly as possible to events)
		if !${CoppernicusAbsorbIncoming}
			wait 1
		; If Absorb is not incoming, update CoppernicusExists every 3 seconds
		if !${CoppernicusAbsorbIncoming} && ${CoppernicusExistsCount:Inc} >= 30
		{
			call CheckCoppernicusExists
			CoppernicusExistsCount:Set[0]
		}
	}
	; Detach Atoms
	Event[EQ2_onIncomingChatText]:DetachAtom[CoppernicusIncomingChatText]
}

function CheckCoppernicusExists()
{
	; Assume CoppernicusExists if in Combat
	if ${Me.InCombat}
	{
		CoppernicusExists:Set[TRUE]
		return
	}
	; Check to see if Coppernicus exists (only consider him existing if within 100m, want script to end if wipe and respawn)
	if ${Actor[Query,Name=="Coppernicus" && Type != "Corpse" && Distance < 100].ID(exists)}
	{
		CoppernicusExists:Set[TRUE]
		return
	}
	; Coppernicus not found
	CoppernicusExists:Set[FALSE]
}

atom CoppernicusIncomingChatText(int ChatType, string Message, string Speaker, string TargetName, string SpeakerIsNPC, string ChannelName)
{
	; Look for message that "Absorb Celestial Materia" is being cast'
	; 	Coppernicus says, "Celestial materia! Heal me!"
	; 	Coppernicus attempts to absorb a celestial materia!
	if ${Message.Find["attempts to absorb a celestial materia!"]}
	{
		CoppernicusAbsorbIncoming:Set[TRUE]
		
		; **************************************
		; DEBUG TEXT
		oc ${Me.Name} Absorb Inc
		; **************************************
	}
	
	; Debug text to see messages
	;echo ${ChatType}, ${Message}, ${Speaker}, ${TargetName}, ${SpeakerIsNPC}, ${ChannelName}
}

/*******************************************************************************************
    Named 4 **********************    Goldfeather   ****************************************
********************************************************************************************/

variable bool GoldfeatherRuffledFeathersIncoming=FALSE
variable bool GoldfeatherExists
variable time GoldfeatherFeatheredFrenzyTime
function Goldfeather(string _NamedNPC)
{
	; Handle text events
	Event[EQ2_onIncomingText]:AttachAtom[GoldfeatherIncomingText]
	Event[EQ2_onIncomingChatText]:AttachAtom[GoldfeatherIncomingChatText]
	; Setup variables
	variable int Counter
	variable int SecondLoopCount=10
	variable int GoldfeatherExistsCount=0
	variable int DispelTargetID
	variable int FlecksCounter=0
	variable int BellowCounter=0
	variable int SittingDuckCounter=0
	variable int DipCounter=0
	variable int PhylacteryCounter=0
	; Get PhylacteryNum if character is a PhylacteryCharacter
	variable int PhylacteryNum=0
	if ${OgreBotAPI.Get_Variable["PhylacteryCharacter1"].Equal[${Me.Name}]}
		PhylacteryNum:Set[1]
	elseif ${OgreBotAPI.Get_Variable["PhylacteryCharacter2"].Equal[${Me.Name}]}
		PhylacteryNum:Set[2]
	elseif ${OgreBotAPI.Get_Variable["PhylacteryCharacter3"].Equal[${Me.Name}]}
		PhylacteryNum:Set[3]
	; Run as long as named is alive
	call CheckGoldfeatherExists
	while ${GoldfeatherExists}
	{
		; Handle "Ruffled Feathers"
		; 	Named casts spell that memwipes with damage?, want to interrupt
		if ${GoldfeatherRuffledFeathersIncoming}
		{
			; Disable assist and make sure Goldfeather is targeted
			oc !ci -ChangeOgreBotUIOption ${Me.Name} checkbox_settings_assist FALSE TRUE
			wait 1
			Actor[Query,Name=="Goldfeather" && Type != "Corpse"]:DoTarget
			; Cast Interrupt
			call CastInterrupt "FALSE"
			; If not a fighter, re-enable assist after 4 seconds
			if !${Me.Archetype.Equal[fighter]}
				timedcommand 40 oc !ci -ChangeOgreBotUIOption ${Me.Name} checkbox_settings_assist TRUE TRUE
			; Set Ruffled Feathers as handled
			GoldfeatherRuffledFeathersIncoming:Set[FALSE]
		}
		; Perform checks every second
		if ${SecondLoopCount:Inc} >= 10
		{
			; Handle Feathered Frenzy
			; 	Get message Goldfeather's about to go into a Feathered Frenzy!
			; 	Need to complete Mage HO to prevent it
			if ${GoldfeatherFeatheredFrenzyTime.Timestamp} > 0 && ${Math.Calc[${Time.Timestamp}-${GoldfeatherFeatheredFrenzyTime.Timestamp}]} >=0
			{
				; Check to see if character is HOMage
				if ${OgreBotAPI.Get_Variable["HOMage"].Equal[${Me.Name}]}
				{
					; Disable assist and make sure Goldfeather is targeted
					oc !ci -ChangeOgreBotUIOption ${Me.Name} checkbox_settings_assist FALSE TRUE
					wait 1
					Actor[Query,Name=="Goldfeather" && Type != "Corpse"]:DoTarget
					wait 5
					; Perform solo Mage HO
					call PerformSoloMageHO "${Me.Name}"
					; Re-enable Assist and re-check No Interrupts
					oc !ci -ChangeOgreBotUIOption ${Me.Name} checkbox_settings_assist TRUE TRUE
					oc !ci -ChangeOgreBotUIOption igw:${Me.Name}+mage checkbox_settings_nointerrupts TRUE TRUE
				}
				; Consider the Feathered Frenzy handled
				GoldfeatherFeatheredFrenzyTime:Set[0]
			}
			; Check to see if character has Mutagenesis Disease
			if ${Me.Effect[Query, "Detrimental" && MainIconID == 257 && BackDropIconID == 257].ID(exists)}
				oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}HasCurse" "TRUE"
			else
				oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}HasCurse" "FALSE"
			; Check to see if character needs to dispel an aurumutation
			DispelTargetID:Set[${OgreBotAPI.Get_Variable["${Me.Name}DispelTargetID"]}]
			if ${DispelTargetID} > 0
			{
				; Pause Ogre
				oc !ci -Pause ${Me.Name}
				wait 1
				; Clear ability queue
				eq2execute clearabilityqueue
				; Cancel anything currently being cast
				oc !ci -CancelCasting ${Me.Name}
				; Target aurumutation
				Actor[${DispelTargetID}]:DoTarget
				wait 5
				; Dispel Metallic Mutagenesis depending on class/archetype
				if ${Me.SubClass.Equal[mystic]}
					oc !ci -CastAbility ${Me.Name} "Scourge"
				elseif ${Me.Archetype.Equal[mage]}
					oc !ci -CastAbility ${Me.Name} "Absorb Magic"
				; Have everyone else use an energy inverter item to dispel
				else
					oc !ci -UseItem ${Me.Name} "Zimaran Energy Inverter"
				; Check to see if Metallic Mutagenesis was dispelled
				Counter:Set[0]
				while ${Counter:Inc} <= 5
				{
					wait 10
					call GetActorEffectIncrements "${DispelTargetID}" "Metallic Mutagenesis" "2"
					if ${Return} != 0
						break
				}
				; Target self (auto-assist will fix later)
				Me:DoTarget
				; Resume 
				oc !ci -Resume ${Me.Name}
				; If Metallic Mutagenesis was dispelled, clear DispelTargetID
				if ${Return} != 0
				{
					oc !ci -Set_Variable igw:${Me.Name} "${Me.Name}DispelTargetID" "0"
					wait 1
				}
			}
			; Handle Flecks of Regret detrimental
			; 	Gets cast on everyone in group and deals damamge and power drains
			; 	If cured from entire group gets re-applied to entire group
			; 	Want to cure on everyone except FlecksCharacter
			; Check to see if this character needs to be cured (if not already handled within last 2 seconds)
			; 	There are multiple types of detrimentals during this fight, so just using cure pots to make sure only cure flecks
			if ${FlecksCounter} < 0
				FlecksCounter:Inc
			if ${FlecksCounter} == 0 && !${OgreBotAPI.Get_Variable["FlecksCharacter"].Equal[${Me.Name}]}
			{
				if ${Me.Effect[Query, "Detrimental" && MainIconID == 1127 && BackDropIconID == 313].ID(exists)}
				{
					; Only use Cure pot to cure if Goldfeather has at least 40% HP
					; 	Don't want to have cure pots on cooldown when Bellowing Bill hits
					if ${Actor[Query,Name=="Goldfeather" && Type != "Corpse"].Health} > 40
					{
						; Use cure pot to cure
						oc !ci -UseItem ${Me.Name} "Zimaran Cure Trauma"
						FlecksCounter:Set[-2]
					}
				}
			}
			; Handle Bellowing Bill detrimental
			; 	Gets cast on everyone in group, Stuns fighter/scout and Stifles mage/priest
			; 	Kills target on expiration
			; Immunity runes should take care of the Stun/Stifle
			; Use cure pot to remove from everyone
			if ${BellowCounter} < 0
				BellowCounter:Inc
			if ${BellowCounter} == 0
			{
				if ${Me.Effect[Query, "Detrimental" && MainIconID == 86 && BackDropIconID == 86].ID(exists)}
				{
					
					; **************************************
					; DEBUG TEXT
					oc ${Me.Name} Bellowing Bill at ${Actor["Goldfeather"].Health}
					; **************************************
					
					; Use cure pot to cure
					oc !ci -UseItem ${Me.Name} "Zimaran Cure Noxious"
					BellowCounter:Set[-2]
				}
			}
			; Handle Sitting Duck detrimental
			; 	Character takes increasing heat damage while still then moves to top of hate list
			; 	Character is rooted
			; Try moving character away, then back (counts as moving even if character is rooted in place as long as they are trying to move?)
			if ${SittingDuckCounter} < 0
				SittingDuckCounter:Inc
			if ${SittingDuckCounter} == 0
			{
				if ${Me.Effect[Query, "Detrimental" && MainIconID == 434 && BackDropIconID == 581].ID(exists)}
				{
					; Move character into lake
					oc !ci -ChangeCampSpotWho ${Me.Name} 575.49 245.78 352.03
					; Setup a timedcommand to move character back after 15 seconds (Sitting Duck should have a 15 second duration)
					timedcommand 150 oc !ci -ChangeCampSpotWho ${Me.Name} 563.83 249.25 337.73
					SittingDuckCounter:Set[-20]
				}
			}
			; Handle Take a Dip detrimental
			; 	Character ported to a random location in lake
			; 	If cured, will teleport character back
			; 	Character dies if cured by anyone but themselves
			if ${DipCounter} < 0
				DipCounter:Inc
			if ${DipCounter} == 0
			{
				if ${Me.Effect[Query, "Detrimental" && MainIconID == 564 && BackDropIconID == -1].ID(exists)}
				{
					; Only use Cure pot to cure if Goldfeather has at least 40% HP
					; 	Don't want to have cure pots on cooldown when Bellowing Bill hits
					if ${Actor[Query,Name=="Goldfeather" && Type != "Corpse"].Health} > 40
					{
						; Make sure cure pot is available and not on a cooldown
						if ${Me.Inventory[Query, Name =- "Zimaran Cure Trauma" && Location == "Inventory"].TimeUntilReady} == -1
						{
							; **************************************
							; DEBUG TEXT
							oc ${Me.Name} curing Take a Dip
							; **************************************
							
							; Pause Ogre
							oc !ci -Pause ${Me.Name}
							wait 1
							; Clear ability queue
							eq2execute clearabilityqueue
							wait 1
							; Cancel anything currently being cast
							oc !ci -CancelCasting ${Me.Name}
							; Use cure pot to cure
							oc !ci -UseItem ${Me.Name} "Zimaran Cure Trauma"
							; Wait for pot to start casting (up to 2 seconds)
							wait 5
							Counter:Set[0]
							while !${Me.CastingSpell} && ${Counter:Inc} <= 20
							{
								wait 1
							}
							; Wait for casting to be completed (up to 2 seconds)
							Counter:Set[0]
							while ${Me.CastingSpell} && ${Counter:Inc} <= 20
							{
								wait 1
							}
							wait 5
							; Resume Ogre
							oc !ci -Resume ${Me.Name}
							DipCounter:Set[-2]
						}
					}
				}
			}
			; Check to see if character is a PhylacteryCharacter and not in combat
			if ${PhylacteryNum} > 0 && !${Me.InCombat}
			{
				; Update HasPhylactery
				if ${Me.Inventory[Query, Name == "Goldfeather's Phylactery" && Location == "Inventory"].ID(exists)}
					oc !ci -Set_Variable igw:${Me.Name} "PhylacteryCharacter${PhylacteryNum}HasPhylactery" "TRUE"
				else
					oc !ci -Set_Variable igw:${Me.Name} "PhylacteryCharacter${PhylacteryNum}HasPhylactery" "FALSE"
				; If character needs a phylactery and there is one nearby, grab it
				if !${OgreBotAPI.Get_Variable["PhylacteryCharacter${PhylacteryNum}HasPhylactery"]]}
					call GrabGoldfeatherPhylactery
			}
			; Check to see if character is a PhylacteryCharacter and in combat
			if ${PhylacteryCounter} < 0
				PhylacteryCounter:Inc
			if ${PhylacteryCounter} == 0 && ${PhylacteryNum} > 0 && ${Me.InCombat}
			{
				; Check to see if Goldfeather is in combat
				if ${Actor[Query,Name=="Goldfeather" && Type != "Corpse" && Target.ID != 0].ID(exists)}
				{
					; Make sure not in combat with an add (will effectively pause dps on the named while dealing with the add)
					if !${Actor[Query,(Name=-"aurumutation" || Name=-"ick") && Type != "Corpse" && Target.ID != 0].ID(exists)}
					{
						; If character is missing Feather for a Feather detrimental, have them Use Goldfeather's Phylactery to re-acquire it
						if !${Me.Effect[Query, "Detrimental" && MainIconID == 233 && BackDropIconID == 873].ID(exists)}
						{
							; Use Goldfeather's Phylactery
							oc !ci -UseItem igw:${Me.Name} "Goldfeather's Phylactery"
							PhylacteryCounter:Set[-3]
						}
					}
				}
			}
			; Reset SecondLoopCount
			SecondLoopCount:Set[0]
		}
		; Short wait before looping (to respond as quickly as possible to events)
		wait 1
		; Update GoldfeatherExists every 3 seconds
		if ${GoldfeatherExistsCount:Inc} >= 30
		{
			call CheckGoldfeatherExists
			GoldfeatherExistsCount:Set[0]
		}
	}
	; Detach Atoms
	Event[EQ2_onIncomingText]:DetachAtom[GoldfeatherIncomingText]
	Event[EQ2_onIncomingChatText]:DetachAtom[GoldfeatherIncomingChatText]
}

function CheckGoldfeatherExists()
{
	; Assume GoldfeatherExists if in Combat
	if ${Me.InCombat}
	{
		GoldfeatherExists:Set[TRUE]
		return
	}
	; Check to see if Goldfeather exists
	if ${Actor[Query,Name=="Goldfeather" && Type != "Corpse"].ID(exists)}
	{
		GoldfeatherExists:Set[TRUE]
		return
	}
	; Goldfeather not found
	GoldfeatherExists:Set[FALSE]
}

function GrabGoldfeatherPhylactery()
{
	; See if there is a nearby aurum cluster
	variable actor Phylactery
	Phylactery:Set[${Actor[Query, Name=="Goldfeather's phylactery" && Type == "NoKill NPC" && Distance < 6].ID}]
	if ${Phylactery.ID} == 0
		return
	; Pause Ogre
	oc !ci -Pause ${Me.Name}
	wait 3
	; Clear ability queue
	eq2execute clearabilityqueue
	; Cancel anything currently being cast
	oc !ci -CancelCasting ${Me.Name}
	; Grab Phylactery
	wait 3
	Phylactery:DoTarget
	wait 3
	Phylactery:DoubleClick
	; Resume Ogre
	oc !ci -Resume ${Me.Name}
}

atom GoldfeatherIncomingText(string Text)
{
	; Look for message that Feathered Frenzy is incoming
	; 	Goldfeather's about to go into a Feathered Frenzy! A timely Heroic Opportunity started by Arcane Augur may calm him!
	; 	Goldfeather's about to go into a Feathered Frenzy!
	; Note message comes in early, if perform HO to counter too soon it doesn't work, so delaying by 2 seconds
	if ${Text.Find["Goldfeather's about to go into a Feathered Frenzy!"]}
	{
		GoldfeatherFeatheredFrenzyTime:Set[${Time.Timestamp}]
		GoldfeatherFeatheredFrenzyTime.Second:Inc[2]
		GoldfeatherFeatheredFrenzyTime:Update
	}
}

atom GoldfeatherIncomingChatText(int ChatType, string Message, string Speaker, string TargetName, string SpeakerIsNPC, string ChannelName)
{
	; Look for message that Ruffled Feathers is being cast
	; 	Goldfeather ruffles its feathers!
	if ${Message.Find["ruffles its feathers!"]}
		GoldfeatherRuffledFeathersIncoming:Set[TRUE]
	
	; Debug text to see messages
	;echo ${ChatType}, ${Message}, ${Speaker}, ${TargetName}, ${SpeakerIsNPC}, ${ChannelName}
}

/*******************************************************************************************
    Named 5 **********************    Goldan   *********************************************
********************************************************************************************/

variable bool GoldanExists
variable point3f PlatformCenterLocation="659.83,270.30,908.93"
variable uint GoldanPadTintFlag
variable bool GoldanFighterPadDisabledIncoming=FALSE
variable bool GoldanScoutPadDisabledIncoming=FALSE
variable bool GoldanMagePadDisabledIncoming=FALSE
variable bool GoldanPriestPadDisabledIncoming=FALSE

; **************************************
; DEBUG TEXT
variable time GoldanStaggerMessageTime
variable time GoldanTailLashMessageTime
variable time GoldanVaporizeMessageTime
; **************************************

function Goldan(string _NamedNPC)
{
	; Handle text events
	Event[EQ2_onIncomingText]:AttachAtom[GoldanIncomingText]
	Event[EQ2_onIncomingChatText]:AttachAtom[GoldanIncomingChatText]
	; Setup variables
	variable int Counter
	variable int SecondLoopCount=10
	variable int GoldanExistsCount=0
	variable actor GoldanPad
	variable bool AtPad=FALSE
	variable bool PadDisabled=FALSE
	variable int FangsCounter=0
	variable bool NeedUpdateFlecksCureTime=FALSE
	variable int FlecksCounter=0
	variable time FlecksCureTime=${Time.Timestamp}
	
	; Set default variable
	oc !ci -Set_Variable ${Me.Name} "PadDisabledIncoming" "FALSE"
	
	; Get GoldanPadTintFlag and GoldanPad
	GoldanPadTintFlag:Set[${Actor[Query,Name =- "hover_pad_0" && Distance < 10].TintFlags}]
	GoldanPad:Set[${Actor[Query,Name =- "hover_pad_0" && TintFlags == ${GoldanPadTintFlag}].ID}]
	
	; At start, jump characters to platform
	call GoldanJumpPadToPlatform
	
	; Run as long as named is alive
	call CheckGoldanExists
	while ${GoldanExists}
	{
		; Handle platforms being made classless
		if ${GoldanFighterPadDisabledIncoming}
		{
			if ${Me.Archetype.Equal[fighter]}
				call GoldanSetPadDisabledIncoming
			GoldanFighterPadDisabledIncoming:Set[FALSE]
		}
		elseif ${GoldanScoutPadDisabledIncoming}
		{
			if ${Me.Archetype.Equal[scout]}
				call GoldanSetPadDisabledIncoming
			GoldanScoutPadDisabledIncoming:Set[FALSE]
		}
		elseif ${GoldanMagePadDisabledIncoming}
		{
			if ${Me.Archetype.Equal[mage]}
				call GoldanSetPadDisabledIncoming
			GoldanMagePadDisabledIncoming:Set[FALSE]
		}
		elseif ${GoldanPriestPadDisabledIncoming}
		{
			if ${Me.Archetype.Equal[priest]}
				call GoldanSetPadDisabledIncoming
			GoldanPriestPadDisabledIncoming:Set[FALSE]
		}
		; Jump to pad/platform as needed based on PadAllowed/PadReset/PadDisabledIncoming/PadDisabled
		if ${AtPad}
		{
			; If not allowed or disabled, need to get off
			if !${OgreBotAPI.Get_Variable["PadAllowed"]} || ${OgreBotAPI.Get_Variable["PadReset"]} || ${OgreBotAPI.Get_Variable["PadDisabledIncoming"]} || ${PadDisabled}
			{
				; Make sure character is on the ground not moving
				if !${Me.IsMoving} && ${Me.Y} >= 269 && ${Me.Y} <= 272
				{
					call GoldanJumpPadToPlatform
					AtPad:Set[FALSE]
				}
			}
		}
		; If not at pad, see if pad is available to go to
		elseif ${OgreBotAPI.Get_Variable["PadAllowed"]} && !${OgreBotAPI.Get_Variable["PadReset"]} && !${OgreBotAPI.Get_Variable["PadDisabledIncoming"]} && !${PadDisabled}
		{
			; Make sure character is on the ground not moving
			if !${Me.IsMoving} && ${Me.Y} >= 269 && ${Me.Y} <= 272
			{
				call GoldanJumpPlatformToPad
				AtPad:Set[TRUE]
			}
		}
		; If NeedUpdateFlecksCureTime, check to see that flecks was removed
		if ${NeedUpdateFlecksCureTime}
		{
			if !${Me.Effect[Query, "Detrimental" && MainIconID == 1127 && BackDropIconID == 313].ID(exists)}
			{
				FlecksCureTime:Set[${Time.Timestamp}]
				NeedUpdateFlecksCureTime:Set[FALSE]
			}
		}
		; Perform checks every second
		if ${SecondLoopCount:Inc} >= 10
		{
			; Update GoldanPad (may change during the fight, so need to update with the pad matching GoldanPadTintFlag)
			GoldanPad:Set[${Actor[Query,Name =- "hover_pad_0" && TintFlags == ${GoldanPadTintFlag}].ID}]
			; Update PadDisabled based on whether or not GoldanPad exists
			if !${GoldanPad.ID(exists)}
				PadDisabled:Set[TRUE]
			else
				PadDisabled:Set[FALSE]
			; If AtPad, monitor character height and if they get knocked into the air send them to platform
			if ${AtPad} && ${Me.Y} > 290
			{
				
				; **************************************
				; DEBUG TEXT
				oc ${Me.Name} knocked up, sending to platform
				; **************************************
				
				; Send to center of platform, don't want to miss the platform aiming for an edge spot and fall off
				oc !ci -campspot ${Me.Name}
				oc !ci -ChangeCampSpotWho ${Me.Name} ${PlatformCenterLocation.X} ${PlatformCenterLocation.Y} ${PlatformCenterLocation.Z}
				; Set AtPad = FALSE
				AtPad:Set[FALSE]
			}
			; Update AtPad based on distance to pad
			if ${GoldanPad.ID(exists)} && ${Me.Y} <= 290 && ${Math.Distance[${Me.X},${Me.Z},${GoldanPad.X},${GoldanPad.Z}]} < 10
				AtPad:Set[TRUE]
			else
				AtPad:Set[FALSE]
			; Handle Spitting Fangs detrimental
			; 	Curse deals damage, power drains, decrease Fervor/casting speed
			; 	Can only cure while Divine Providence is active or during Priest HO wheel, otherwise character and priest die
			if ${FangsCounter} < 0
				FangsCounter:Inc
			if ${FangsCounter} == 0
			{
				if ${Me.Effect[Query, "Detrimental" && MainIconID == 695 && BackDropIconID == 695].ID(exists)}
				{
					; Cure if LatestHO is Priest, HO window is up, and nothing is incoming
					if ${OgreBotAPI.Get_Variable["LatestHO"].Equal[Priest]} && ${EQ2.HOWindowState} != -1
					{
						if !${OgreBotAPI.Get_Variable["GoldanStaggerIncoming"]} && !${OgreBotAPI.Get_Variable["GoldanTailLashIncoming"]} && !${OgreBotAPI.Get_Variable["GoldanVaporizeIncoming"]}
						{
							; Set AutoCurse for a priest to cure this character
							oc !ci -AutoCurse igw:${Me.Name}+priest ${Me.Name}
							FangsCounter:Set[-6]
						}
					}
				}
			}
			; Handle Flecks of Regret detrimental
			; 	Gets cast on everyone in group and deals damamge and power drains
			; 	If cured from entire group gets re-applied to entire group
			; 	Want to cure on everyone except fighter
			; 		However have fighter cure themselves every 5 minutes because flecks being on a long time can cause it to start spiking up to 100B+ damage
			; Check to see if this character needs to be cured (if not already handled within last 2 seconds)
			; 	Using cure pots to cure
			if ${FlecksCounter} < 0
				FlecksCounter:Inc
			if ${FlecksCounter} == 0
			{
				if ${Me.Effect[Query, "Detrimental" && MainIconID == 1127 && BackDropIconID == 313].ID(exists)}
				{
					; Cure if not fighter or more than 3 minutes have passed since last cure and Stagger is not incoming
					if !${Me.Archetype.Equal[fighter]} || (${Math.Calc[${Time.Timestamp}-${FlecksCureTime.Timestamp}]} > 180 && ${OgreBotAPI.Get_Variable["GoldanStaggerIncomingTime"]} == 0)
					{
						; Make sure character is on the ground not moving
						if !${Me.IsMoving} && ${Me.Y} >= 269 && ${Me.Y} <= 272
						{
							; Use cure pot to cure
							oc !ci -UseItem ${Me.Name} "Zimaran Cure Trauma"
							; For fighter, need to check that flecks was actually removed before setting new FlecksCureTime
							if ${Me.Archetype.Equal[fighter]}
								NeedUpdateFlecksCureTime:Set[TRUE]
							FlecksCounter:Set[-2]
						}
					}
				}
			}
			; Reset SecondLoopCount
			SecondLoopCount:Set[0]
		}
		; Short wait before looping (to respond as quickly as possible to events)
		wait 1
		; Update GoldanExists every 3 seconds
		if ${GoldanExistsCount:Inc} >= 30
		{
			call CheckGoldanExists
			GoldanExistsCount:Set[0]
		}
	}
	; Detach Atoms
	Event[EQ2_onIncomingText]:DetachAtom[GoldanIncomingText]
	Event[EQ2_onIncomingChatText]:DetachAtom[GoldanIncomingChatText]
}

function CheckGoldanExists()
{
	; Assume GoldanExists if in Combat or dead or ID is invalid (likely due to zoning, such as after a revive)
	if ${Me.InCombat} || ${Me.IsDead} || ${Me.ID} == 0
	{
		GoldanExists:Set[TRUE]
		return
	}
	; Check to see if Goldan exists
	if ${Actor[Query,Name=="Goldan" && Type != "Corpse"].ID(exists)}
	{
		GoldanExists:Set[TRUE]
		return
	}
	; Goldan not found
	GoldanExists:Set[FALSE]
}

function GoldanSetPadDisabledIncoming()
{
	; Set pad as not allowed, but change back to allowed 5 seconds later
	; 	By that point any add should have spawned and PadDisabled would prevent jumping back if not safe
	oc !ci -Set_Variable ${Me.Name} "PadDisabledIncoming" "TRUE"
	timedcommand 50 oc !ci -Set_Variable ${Me.Name} "PadDisabledIncoming" "FALSE"
	wait 1
}

function GoldanJumpPadToPlatform()
{
	; Get GoldanPad
	variable actor GoldanPad
	GoldanPad:Set[${Actor[Query,Name =- "hover_pad_0" && TintFlags == ${GoldanPadTintFlag}].ID}]
	; Make sure pad exists
	if !${GoldanPad.ID(exists)}
		return
	; Clear CampSpot and face platform
	oc !ci -CS_ClearCampSpot ${Me.Name}
	wait 1
	face ${PlatformCenterLocation.X} ${PlatformCenterLocation.Z}
	wait 5
	; Start moving to platform
	press -hold "${OgreForwardKey}"
	; Wait until character starts moving away from pad (up to 4m away, wait for up to 2 seconds)
	variable time StartTime
	StartTime:Set[${Time.Timestamp}]
	while ${Math.Distance[${Me.X},${Me.Z},${GoldanPad.X},${GoldanPad.Z}]} < 4 && ${Math.Calc[${Time.Timestamp}-${StartTime.Timestamp}]} < 2
	{
		waitframe
	}
	; Jump to platform
	press ${OgreJumpKey}
	; Wait for the amount of time it takes for character to get to platform, accounting for movement Speed
	call Wait_ms "${Math.Calc[700 * 340/(${Me.Speed}+100)]}"
	press -release "${OgreForwardKey}"
	; Press back for just the right amount of time to stop all forward momentum
	; 	This should have the character land on the platform, ideally about half way between center and edge
	press -hold "${OgreBackwardKey}"
	call Wait_ms "150"
	press -release "${OgreBackwardKey}"
}

function GoldanJumpPlatformToPad()
{
	; Get GoldanPad
	variable actor GoldanPad
	GoldanPad:Set[${Actor[Query,Name =- "hover_pad_0" && TintFlags == ${GoldanPadTintFlag}].ID}]
	; Make sure pad exists
	if !${GoldanPad.ID(exists)}
		return
	; Clear CampSpot and face pad
	oc !ci -CS_ClearCampSpot ${Me.Name}
	wait 1
	face ${GoldanPad.X} ${GoldanPad.Z}
	wait 5
	; Start moving to pad
	press -hold "${OgreForwardKey}"
	; Wait until within 14m of pad (for up to 5 seconds)
	variable time StartTime
	StartTime:Set[${Time.Timestamp}]
	while ${Math.Distance[${Me.X},${Me.Z},${GoldanPad.X},${GoldanPad.Z}]} > 14 && ${Math.Calc[${Time.Timestamp}-${StartTime.Timestamp}]} < 5
	{
		waitframe
	}
	; Jump to pad
	press ${OgreJumpKey}
	; Wait for the amount of time it takes for character to get to center of pad, accounting for movement Speed
	call Wait_ms "${Math.Calc[550 * 340/(${Me.Speed}+100)]}"
	press -release "${OgreForwardKey}"
	; Press back for just the right amount of time to stop all forward momentum
	; 	This should have the character land at the center of the pad
	press -hold "${OgreBackwardKey}"
	call Wait_ms "150"
	press -release "${OgreBackwardKey}"
}

atom GoldanIncomingText(string Text)
{
	; Look for message that Stagger hit
	; 	Goldan's stagger is absorbed by your shield!
	; 	Goldan staggers you, and you go flying!
	if ${Text.Find["Goldan's stagger is absorbed by your shield!"]} || ${Text.Find["Goldan staggers you, and you go flying!"]}
	{
		; Set as no longer incoming
		oc !ci -Set_Variable igw:${Me.Name} "GoldanStaggerIncoming" "FALSE"
		; Debug message
		oc ${Me.Name} Stagger hit ${Math.Calc[${Time.Timestamp}-${GoldanStaggerMessageTime.Timestamp}]} seconds after message
	}
	; Look for message that Tail Lash hit
	; 	What a Lucky Break! You get the stunning Tail Slap!
	; 	What an unlucky break! You get the fearing Tail Slap!
	elseif ${Text.Find["What a Lucky Break! You get the stunning Tail Slap!"]} || ${Text.Find["What an unlucky break! You get the fearing Tail Slap!"]}
	{
		; Set as no longer incoming
		oc !ci -Set_Variable igw:${Me.Name} "GoldanTailLashIncoming" "FALSE"
		; Debug message
		oc ${Me.Name} Tail Slap hit ${Math.Calc[${Time.Timestamp}-${GoldanTailLashMessageTime.Timestamp}]} seconds after message
	}
	; Look for message that Vaporize hit
	; 	You are protected by Divine Providence, and survive being vaporized by Goldan!
	; 	You are vaporized by Goldan as you lacked protection from Divine Providence!
	elseif ${Text.Find["You are protected by Divine Providence, and survive being vaporized by Goldan!"]} || ${Text.Find["You are vaporized by Goldan as you lacked protection from Divine Providence!"]}
	{
		; Set as no longer incoming
		oc !ci -Set_Variable igw:${Me.Name} "GoldanVaporizeIncoming" "FALSE"
		; Debug message
		oc ${Me.Name} Vaporize hit ${Math.Calc[${Time.Timestamp}-${GoldanVaporizeMessageTime.Timestamp}]} seconds after message
	}
}

atom GoldanIncomingChatText(int ChatType, string Message, string Speaker, string TargetName, string SpeakerIsNPC, string ChannelName)
{
	; Look for message that platform is being made classless
	; 	Goldan says, "The maedjinn often wish to test their mettle against fighters!"
	; 	Goldan says, "The maedjinn are attracted to magic and mages."
	; 	Goldan says, "The maedjinn keep their secrets, much like scouts."
	; 	Goldan says, "The maedjinn think themselves more divine than priests."
	; 	Any declared archetypes on their hover pads, watch out!
	; 	This is a classless platform! Nobody can be here, not even you!
	if ${Message.Find["The maedjinn often wish to test their mettle against fighters!"]}
		GoldanFighterPadDisabledIncoming:Set[TRUE]
	elseif ${Message.Find["The maedjinn keep their secrets, much like scouts."]}
		GoldanScoutPadDisabledIncoming:Set[TRUE]
	elseif ${Message.Find["The maedjinn are attracted to magic and mages."]}
		GoldanMagePadDisabledIncoming:Set[TRUE]
	elseif ${Message.Find["The maedjinn think themselves more divine than priests."]}
		GoldanPriestPadDisabledIncoming:Set[TRUE]
	
	; **************************************
	; DEBUG TEXT
	if ${Message.Find["space"]}
		GoldanStaggerMessageTime:Set[${Time.Timestamp}]
	elseif ${Message.Find["I should use my tail!"]}
		GoldanTailLashMessageTime:Set[${Time.Timestamp}]
	elseif ${Message.Find["vaporize"]}
		GoldanVaporizeMessageTime:Set[${Time.Timestamp}]
	; **************************************
	
	; Debug text to see messages
	;echo ${ChatType}, ${Message}, ${Speaker}, ${TargetName}, ${SpeakerIsNPC}, ${ChannelName}
}
