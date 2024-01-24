#includeoptional "${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Object_ICOverride.iss"

; Starts Instance Controller and loads Custom BoZ Heroic I zones
; Can add Ogre MCP button using the following code
; 	(right click empty MCP button and paste in Inner Space console, not Ogre console)
; Obj_OgreMCP:PasteButton[OgreConsoleCommand,IC_H1,-RunScriptOB_AP,\${Me.Name},IC_Custom_BOZ_H1]
function main()
{
	; Start instance controller
	if !${Ogre_Instance_Controller(exists)}
	  ogre ic
	; wait for it to load
	; 1 second delay to make sure everything has been processed
	while (!${Ogre_Instance_Controller(exists)} || ${Ogre_Instance_Controller.Get_Status.NotEqual["Idle_NotRunning"]} )
	  wait 10
	; Set the base directory (you cannot go higher than this in the menu)
	Ogre_Instance_Controller:Set_BaseDirectory["${LavishScript.HomeDirectory}/Scripts/EQ2OgreBot/InstanceController/Instance_Files"]
	; Set to Custom/_Exp_20_Ballads_of_Zimara/Heroic_I folder
	Ogre_Instance_Controller:Set_CurrentDirectory["Custom/_Exp_20_Ballads_of_Zimara/Heroic_I"]
	; auto remove transmuting
	Ogre_Instance_Controller:ChangeUIOptionViaCode["ogreim_checkbox", FALSE] 
	; auto Pause at end of zone
	Ogre_Instance_Controller:ChangeUIOptionViaCode["pause_at_end_of_zone_checkbox", TRUE] 
	; Clear list of zones to run
	Ogre_Instance_Controller:Clear_ZonesToRun
	wait 1
	; Add the current zone if it exists
	Ogre_Instance_Controller:AddInstance_ViaCode_ViaName["${Ogre_Instance_Controller.CleanZoneName}.iss"]
	wait 1
	; Uncomment the next line if you want to immeditely run the instance
	;Ogre_Instance_Controller:ChangeUIOptionViaCode["run_instances_checkbox", TRUE]
}