--[[
	-- Playable Piano by Brzysiek <brzysiekdev@gmail.com>
	-- Sounds exported from soundfont made by Keppy Studios (http://kaleidonkep99.altervista.org/keppy-s-steinway-piano.html)
	-- exported_s.lua
	-- Exported functions
]] 

function isPlayerUsingPiano(player)
	if pianoManager then 
		return pianoManager:isPlayerUsingPiano(player)
	else 
		return false
	end
end 

function isVehiclePiano(vehicle)
	if isElement(vehicle) and getElementType(vehicle) == "vehicle" then 
		return getElementData(vehicle, "piano") or false 
	else 
		return false 
	end
end 

function createPiano(x, y, z, rot, int, dim, r, g, b)
	if pianoManager then 
		return pianoManager:createPiano(x, y, z, rot, int, dim, r, g, b)
	else 
		return false 
	end 
end 

function destroyPiano(piano)
	if pianoManager then 
		return pianoManager:destroyPiano(piano)
	else 
		return false 
	end 
end 

function setPianoColor(piano, r, g, b)
	if pianoManager then 
		return pianoManager:setPianoColor(piano, r, g, b)
	else 
		return false 
	end 
end