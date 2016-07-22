--[[
	-- Playable Piano by Brzysiek <brzysiekdev@gmail.com>
	-- Sounds exported from soundfont made by Keppy Studios (http://kaleidonkep99.altervista.org/keppy-s-steinway-piano.html)
	-- exported_c.lua
	-- Exported functions
]] 

function isPlayerUsingPiano(player)
	if pianoManager then 
		return pianoManager:isPlayerUsingPiano(player)
	else 
		return false
	end
end 