--[[
	-- Playable Piano by Brzysiek <brzysiekdev@gmail.com>
	-- Sounds exported from soundfont made by Keppy Studios (http://kaleidonkep99.altervista.org/keppy-s-steinway-piano.html)
	-- settings.lua
	-- Customize your piano :E
]] 

PIANOS = -- place your pianos here 
{
	-- {x, y, z, rotation(0-360), [[ interior, dimension, pianoColorR, pianoColorG, pianoColorB ]]} [[ (optional) ]]
	{1478, -1686, 13.55, 270}, -- near lspd
	{-1981.4, 883.5, 44.7, 270}, -- sf centre
	{2000.5, 1563.5, 14.85, 0}, -- lv ship
}

PIANO_MODEL = 574 -- https://wiki.multitheftauto.com/wiki/Vehicle_IDs
PIANO_COLOR = {20, 20, 20} -- default piano color (rgb)

SOUND_VOLUME = 0.5
MAX_SOUND_DISTANCE = 50
MAX_SOUND_LIMIT = 10 -- max of sounds playing in one time 
FADE_POPS = true  -- true/false - makes sound more smoother/less powerful and with less pops and vice versa

SHOW_SHEETS = true -- true/false 
SHOW_DOWNLOAD_INFO = true -- true/false - show download information on screen

SHOW_BLIPS = true -- true/false 
BLIP_ID = 48 -- https://wiki.multitheftauto.com/wiki/Blip_Icons 

EXIT_KEY = "tab" -- https://wiki.multitheftauto.com/wiki/Key_names
HIDE_SHEETS_KEY = "f2"-- https://wiki.multitheftauto.com/wiki/Key_names

DISABLE_ENGINE_START_SOUND = true -- true/false - works globally on all vehicles! 
 
