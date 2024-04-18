# BoZ-IC
OgreBot Instance Controller files for BoZ Solo/H1/H2/H3/Chrono zones.  To use, download the zip file and copy all of the files in the BoZ-IC-main folder to the InnerSpace\Scripts folder.  Everything should go in the folder structure that I have setup.  The Ogre IC main files are run from a "Default" folder.  I put my files in a "Custom" folder to not interfere with the main files.  You can navigate to the custom folder from within IC, or use an MCP button to run the instance.

For the MCP, I have separate scripts for loading up the Solo/H1/H2/H3/Chrono zones.  Right click an empty MCP button and paste in Inner Space console (not Ogre console):

Obj_OgreMCP:PasteButton[OgreConsoleCommand,IC_Solo,-RunScriptOB_AP,\${Me.Name},IC_Custom_BOZ_Solo]
Obj_OgreMCP:PasteButton[OgreConsoleCommand,IC_H1,-RunScriptOB_AP,\${Me.Name},IC_Custom_BOZ_H1]
Obj_OgreMCP:PasteButton[OgreConsoleCommand,IC_H2,-RunScriptOB_AP,\${Me.Name},IC_Custom_BOZ_H2]
Obj_OgreMCP:PasteButton[OgreConsoleCommand,IC_H3,-RunScriptOB_AP,\${Me.Name},IC_Custom_BOZ_H3]
Obj_OgreMCP:PasteButton[OgreConsoleCommand,IC_Chro,-RunScriptOB_AP,\${Me.Name},IC_Custom_BOZ_Chrono]

These will open IC, navigate to the appropriate Custom folder, then auto-add the current zone if it is in the list.  I disable Ogre IM-TSE and enable Pause at end of zone (except for Chrono), but you can modify that in the scripts if you want.  You can also uncomment out the last line if you want the zone to automatically be run instead of having to click Run Instances (for Chrono it auto-runs by default).  

Some notes about the IC files:
- I do a lot of running side scripts to handle character-specific mechanics for variable fights.  I don't think that is typical of IC files, but it seemed the best way to reliably run everything to me.

- I disable "Smart Loot", then right before the last boss disable "Loot everything" so it pauses on No-Trade items like CBOC gear.  You can modify this behavior if you want in IC_Helper SetInitialInstanceSettings/SetLootForLastBoss.

- My group when creating/testing these files was initially Zerker/Ranger/Dirge/Coercer/Fury/Mystic, now SK/Ranger/Swash/Coercer/BL/Mystic.  Solos were done with 3 sets of 2 characters.  I have not tried any other classes or using Mercenaries.  I tried to code things in a way that wasn't too specific to my group, but there are some class-specific sections of code that may need to be modified to support other classes.  Also if a group doesn't have range dps or requires positionals to dps there will probably be issues.

- I perform Archetype-specific immunity rune swapping for many fights in order to make them as reliable as possible.  The immunity runes will be put in the second slot (first purple slot) so if you have a double purple slot belt put the rune you want to keep in the last slot.

- The HO_Helper was something I created because I had a lot of issues with HO's not completing.  I run it during fights that require HO's to add some extra code to get them to complete.  It will disable Ascensions to not have long casting spells, periodically cancel the HO Starter if it seems like it is stuck, and perform some class-specific code to try to get HO's to complete.  I found this more necessary in solo zones where there weren't multiple characters of an Archetype to complete HO's.  I only setup the classes in my group that I was having trouble with, but this could be modified to support additional classes.  For the Zerker it doesn't complete the HO with an ability that targets the enemy, but I found it better to just complete the HO in general and move onto another one than get stuck not completing.

- Vaashkaani: Every Which Way is not an easy zone to script.  My script mostly works, but spends a long time with characters waiting around for the nameds to randomly be in certain positions.  There are also a lot of things that can randomly go wrong.  Don't run this if you are in a hurry.  There is almost certainly a better way to do this zone, but after getting something that was mostly functional I was ready to move on.

- For Chrono zones the idea is use Coldborne EverPorter to zone to Kael, run 1 of the zones then evac out, run the other zone then Call to Guild Hall or port somewhere else.  They will auto-use the Chrono Dungeons: [Level 130] items starting from the person that has the most items, or in alphabetical order if people have the same number.  Give everyone the same number of items at the start (or -1 if a character currently has a Commandar lockout) and it will cycle through the characters using them evenly.  You could run the set of 2 zones 3 times a day and it would use the chrono items once on each character.

- H3 is complete, but still a work in progress

I can't take full credit for all of the code, a lot of this was based on or copied from code that others have posted, especially Kordulek and Jiimbo.  So big thanks to everyone that has provided previous IC files/scripts/code snippets as I couldn't have done this without them.

If there are any issues with the files or other feedback, feel free to let me know.  I have not run other BoZ IC files aside from the very first ones released, so I don't know how others are scripting fights.  There may be better ways to do things than what I came up with.
