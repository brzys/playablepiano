--[[
	-- Playable Piano by Brzysiek <brzysiekdev@gmail.com>
	-- Sounds exported from soundfont made by Keppy Studios (http://kaleidonkep99.altervista.org/keppy-s-steinway-piano.html)
	-- piano_s.lua
	-- Sound synchronization, piano creation
]] 

local CPianoManager = class "CPianoManager" 
{
	__init__ = function(self)
		self.pianos = {} 
		
		addEvent("onSyncNote", true)
		addEventHandler("onSyncNote", root, function(note, x, y, z, press) self:syncNote(note, x, y, z, press) end)
		
		addEvent("onPlayerEnterPiano", true)
		addEvent("onPlayerExitPiano", true)
		
		for k,v in ipairs(PIANOS) do 
			self:createPiano(v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8], v[9])
			if SHOW_BLIPS then 
				createBlip(v[1], v[2], v[3], BLIP_ID, 2, 255, 255, 255, 255, 0, 200)
			end
		end
	end,
	
	createPiano = function(self, x, y, z, rot, int, dim, r, g, b)
		if not x or not y or not z or not rot then return false end 
		
		local vehicle = createVehicle(PIANO_MODEL, x, y, z, 0, 0, rot)
		setElementFrozen(vehicle, true)
		r = r or PIANO_COLOR[1] 
		g = g or PIANO_COLOR[2] 
		b = b or PIANO_COLOR[3]
		setVehicleColor(vehicle, r, g, b)
		int = int or 0 
		dim = dim or 0 
		setElementInterior(vehicle, int)
		setElementDimension(vehicle, dim)
		setElementData(vehicle, "piano", #self.pianos+1)
		
		addEventHandler("onVehicleStartEnter", vehicle, function(player, seat, jacked)
			if jacked and self:isPlayerUsingPiano(jacked) then 
				cancelEvent() 
			end 
			
			if seat ~= 0 then 
				cancelEvent()
			end
		end) 
		
		addEventHandler("onVehicleEnter", vehicle, function(player) self:onEnterPiano(player) triggerEvent("onPlayerEnterPiano", player) end)
		addEventHandler("onVehicleExit", vehicle,   function(player) self:onExitPiano(player) triggerEvent("onPlayerExitPiano", player) end)
		
		table.insert(self.pianos, vehicle)
		return #self.pianos 
	end, 
	
	destroyPiano = function(self, piano)
		if self.pianos[piano] then 
			destroyElement(self.pianos[piano])
			table.remove(self.pianos, piano)
			return true
		else 
			return false 
		end
	end,
	
	isPlayerUsingPiano = function(self, player)
		if isElement(player) and getElementType(player) == "player" then 
			return getElementData(player, "player:onPiano") == true
		else 
			return false
		end
	end, 
	
	setPianoColor = function(self, piano, r, g, b)
		if self.pianos[piano] and r and g and b then 
			return setVehicleColor(self.pianos[piano], r, g, b)
		else 
			return false 
		end
	end, 
	
	syncNote = function(self, note, x, y, z, press)
		for k,v in ipairs(getElementsByType("player")) do
			local px, py, pz = getElementPosition(v)
			local dist = getDistanceBetweenPoints3D(px, py, pz, x, y, z)
			if dist < MAX_SOUND_DISTANCE then 
				if press then 
					triggerClientEvent(v, "onClientPlayNote", v, note, x, y, z)
				else 
					triggerClientEvent(v, "onClientStopNote", v, note, x, y, z)
				end 
			end 
		end 
	end,
	
	onEnterPiano = function(self, player)
		if not player then return end 
		triggerClientEvent(player, "onClientEnterPiano", player, source)
		setVehicleEngineState(source, false)
		setVehicleOverrideLights(source, 1)
		setElementData(player, "player:onPiano", false)
	end, 
	
	onExitPiano = function(self, player)
		if not player then return end 
		setElementData(player, "player:onPiano", true)
	end, 
}

function onResourceStart()
	pianoManager = CPianoManager()
end 
addEventHandler("onResourceStart", resourceRoot, onResourceStart)