
wsel = wsel or {}

--[[Here are some convars you can change in the server's console (premium only).

	'wep_select_movespeed' defaults to 0.40 //How fast, compared to normal, that players walk/run while inventory is open. 1 means normal speed. MULTIPLAYER ONLY.
	'wep_select_timescale' defaults to 0.60 //How fast, compared to normal, that the game moves while inv is open. 1 means normal speed. SINGLEPLAYER ONLY.
]]

//This FORCES all players to use this weapon select. If false, users can decide to use the default weapon select with "wep_select_use 1|0"
wsel.ForceUse = true

//This is the default key to open the weapon select menu. Note that players who have used this script on other servers will keep their own preference.
wsel.DefaultKey = "T" 

//Use this to override preview icons.
//By default it uses the spawnmenu icons, which are located at "materials/entities/<class_name>.png" or "materials/vgui/<class_name>.vmt"
wsel.PreviewIcons = {
	weapon_crowbar = "entities/weapon_crowbar.png", 
	//Add more here. The format is weapon_class_name = "path/to/material.png",
	
	
	
}

//Use this to give players some choices for their scrolling sounds.
wsel.selectSounds = {
	{"Default","ui/buttonrollover.wav"},
	{"Zoom 2","items/nvg_off.wav"},
	{"Pickup Sound","items/itempickup.wav"},
	{"Empty Clip","weapons/clipempty_rifle.wav"},
	{"Zoom","weapons/zoom.wav"},
	{"Light Switch","buttons/lightswitch2.wav"},
	{"Geiger","common/wpn_moveselect.wav"},
	//Add more here. Format is {"Description", "path/to/soundfile.mp3"},
	
	
	
}
