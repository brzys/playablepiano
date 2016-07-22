--[[
	-- Playable Piano by Brzysiek <brzysiekdev@gmail.com>
	-- Sounds exported from soundfont made by Keppy Studios (http://kaleidonkep99.altervista.org/keppy-s-steinway-piano.html)
	-- piano_c.lua
	-- Everything :E
]] 

local screenW, screenH = guiGetScreenSize() 
local sx, sy = screenW/1366, screenH/768 

class "CClientPianoHandler"
{
	__init__ = function(self, object)
		self.object = object 
		
		-- ["bind"] = note
		self.keyboardToNote = {
			["1"] = 15, 
			["2"] = 17,
			["3"] = 19,
			["4"] = 20, 
			["5"] = 22, 
			["6"] = 24, 
			["7"] = 26,
			["8"] = 27,
			["9"] = 29,
			["0"] = 31,
			["q"] = 32,
			["w"] = 34,
			["e"] = 36,
			["r"] = 38,
			["t"] = 39, 
			["y"] = 41,
			["u"] = 43,
			["i"] = 44,
			["o"] = 46,
			["p"] = 48,
			["a"] = 50,
			["s"] = 51,
			["d"] = 53,
			["f"] = 55,
			["g"] = 56,
			["h"] = 58,
			["j"] = 60,
			["k"] = 62,
			["l"] = 63,
			["z"] = 65,
			["x"] = 67,
			["c"] = 68,
			["v"] = 70,
			["b"] = 72,
			["n"] = 74,
			["m"] = 75,
		}
		
		self.noteToKeyboard = {
			[15] = "1",
			[16] = "!",
			[17] = "2",
			[18] = "@",
			[19] = "3",
			[20] = "4",
			[21] = "$",
			[22] = "5",
			[23] = "%",
			[24] = "6",
			[25] = "^",
			[26] = "7",
			[27] = "8",
			[28] = "*",
			[29] = "9",
			[30] = "(",
			[31] = "0",
			[32] = "q",
			[33] = "Q",
			[34] = "w",
			[35] = "W",
			[36] = "e",
			[37] = "E",
			[38] = "r",
			[39] = "t",
			[40] = "T",
			[41] = "y",
			[42] = "Y",
			[43] = "u",
			[44] = "i",
			[45] = "I",
			[46] = "o",
			[47] = "O",
			[48] = "p",
			[49] = "P",
			[50] = "a",
			[51] = "s",
			[52] = "S",
			[53] = "d",
			[54] = "D",
			[55] = "f",
			[56] = "g",
			[57] = "G",
			[58] = "h",
			[59] = "H",
			[60] = "j",
			[61] = "J",
			[62] = "k",
			[63] = "l",
			[64] = "L",
			[65] = "z",
			[66] = "Z",
			[67] = "x",
			[68] = "c",
			[69] = "C",
			[70] = "v",
			[71] = "V",
			[72] = "b",
			[73] = "B",
			[74] = "n",
			[75] = "m"
		}
		
		self.pressedKeys = {}
		self.halfNote = false 
		
		self.blackKeys = {16, 18, 21, 23, 25, 28, 30, 33, 35, 37, 40, 42, 45, 47, 49, 52, 54, 57, 59, 61, 64, 66, 69, 71, 73}
		self.whiteKeys = {15, 17, 19, 20, 22, 24, 26, 27, 29, 31, 32, 34, 36, 38, 39, 41, 43, 44, 46, 48, 50, 51, 53, 55, 56, 58, 60, 62, 63, 65, 67, 68, 70, 72, 74, 75}
		self.keyView = {} 
		
		-- generate key view 
		local w,h,x,y,color
		for k,v in ipairs(self.whiteKeys) do
			w = 25
			h = 110
			x = 240 + w*(k-1) 
			y = 600
			if k % 2 == 0 then -- make some beauty
				color = {230, 230, 230, 255}
			else 
				color = {240, 240, 240, 255}
			end 
			table.insert(self.keyView, {x=x, y=y, w=w, h=h, note=v, color=color})
		end 
		
		for k,v in ipairs(self.blackKeys) do 
			i = v-15
			w = 14.6
			h = 70
			x = 251 + w*(i-1) 
			y = 600
			color = {60, 60, 60, 255}
			table.insert(self.keyView, {x=x, y=y, w=w, h=h, note=v, color=color})
		end  
		
		if SHOW_SHEETS then
			self.sheets = CSheets()
		end 
		
		self.bg = guiCreateGridList(230*sx, 580*sy, 920*sx, 140*sy, false)
		self.renderFunc = function() self:onRender() end
		addEventHandler("onClientRender", root, self.renderFunc)
		
		guiSetInputMode("no_binds")
	end, 
	
	destroy = function(self)
		guiSetInputMode("allow_binds")
		if isElement(self.bg) then destroyElement(self.bg) end
		removeEventHandler("onClientRender", root, self.renderFunc)
		if SHOW_SHEETS then 
			self.sheets:destroy() 
		end
	end, 
	
	-- not onClientKey because of chords
	onRender = function(self) 
		if getKeyState(EXIT_KEY) or not isElement(self.object) then 
			setControlState("enter_exit", true) -- exit vehicle
			setTimer(setControlState, 200, 1, "enter_exit", false)
			pianoManager:exitPiano()
			return 
		end 
		
		if SHOW_SHEETS and getKeyState(HIDE_SHEETS_KEY) then 
			self.sheets:toggle() 
		end
		
		self.halfNote = getKeyState("lshift")
		
		-- handle notes 
		for k, v in pairs(self.keyboardToNote) do 
			local keyState = getKeyState(k)
			if keyState then 
				local playNote = true  
				for _, pressedKey in ipairs(self.pressedKeys) do 
					if pressedKey.key == k then
						playNote = false 
					end 
				end
				
				if playNote then 
					local x,y,z = getElementPosition(self.object)
					local note = self.keyboardToNote[k]
					if self.halfNote then 
						note = math.min(note+1, 75)
					end 
					
					--pianoManager:playNote(note, x, y, z)
					triggerServerEvent("onSyncNote", localPlayer, note, x, y, z, true)
					table.insert(self.pressedKeys, {key=k, note=note})
				end
			else 
				for i, pressedKey in ipairs(self.pressedKeys) do 
					if pressedKey.key == k then 
						local x,y,z = getElementPosition(self.object)
						table.remove(self.pressedKeys, i)
						local note = self.keyboardToNote[k]
						if self.halfNote then
							note = math.min(note+1, 75)
						end 
						
						--pianoManager:stopNote(note, x, y, z)
						triggerServerEvent("onSyncNote", localPlayer, note, x, y, z, false)
					end 
				end
			end 
		end
		
		-- draw key view
		for k,v in ipairs(self.keyView) do 
			local r,g,b,a = v.color[1], v.color[2], v.color[3], v.color[4] 
			local active = false 
			for _, pressedKey in ipairs(self.pressedKeys) do 
				if pressedKey.note == v.note then 
					active = true 
				end
			end 
			
			if active then 
				r,g,b = math.max(0, r-70), math.max(0, g-70), math.max(0, b-70)
			end 
			
			dxDrawRectangle((v.x+1)*sx, (v.y+1)*sy, v.w*sx, v.h*sy, tocolor(0, 0, 0, 150), true)
			dxDrawRectangle(v.x*sx, v.y*sy, v.w*sx, v.h*sy, tocolor(r,g,b,a), true)
			
			local note = self.noteToKeyboard[v.note]
			if note then 
				if v.color[1] == 60 then -- black note 
					dxDrawText(note, (v.x+2)*sx, (v.y+25)*sy, 0, 0, tocolor(200, 200, 200, 255), 1.2*sx, "default-bold", "left", "top", false, false, true)
				else -- white note  
					dxDrawText(note, (v.x+7)*sx, (v.y+85)*sy, 0, 0, tocolor(50, 50, 50, 255), 1.2*sx, "default-bold", "left", "top", false, false, true)
				end 
			end 
		end 
		
		dxDrawText("Playable Piano by Brzysiek", 240*sx, 582*sy, 920*sx, 150*sy, tocolor(130, 130, 130, 130), 1.0*sx, "default", "left", "top", false, false, true)
		if getLocalization()["code"] == "pl" then 
			dxDrawText("By przestać grać kliknij "..string.upper(EXIT_KEY)..".  By schować nuty kliknij "..string.upper(HIDE_SHEETS_KEY)..".", 413*sx, 543*sy, 921*sx, 151*sy, tocolor(0, 0, 0, 255), 1.5*sx, "default-bold", "center", "top", false, false, true)
			dxDrawText("By przestać grać kliknij "..string.upper(EXIT_KEY)..".  By schować nuty kliknij "..string.upper(HIDE_SHEETS_KEY)..".", 412*sx, 542*sy, 920*sx, 150*sy, tocolor(255, 255, 255, 255), 1.5*sx, "default-bold", "center", "top", false, false, true)
		else 
			dxDrawText("To stop playing press "..string.upper(EXIT_KEY)..".  To hide sheets press "..string.upper(HIDE_SHEETS_KEY)..".", 413*sx, 543*sy, 921*sx, 151*sy, tocolor(0, 0, 0, 255), 1.5*sx, "default-bold", "center", "top", false, false, true)
			dxDrawText("To stop playing press "..string.upper(EXIT_KEY)..".  To hide sheets press "..string.upper(HIDE_SHEETS_KEY)..".", 412*sx, 542*sy, 920*sx, 150*sy, tocolor(255, 255, 255, 255), 1.5*sx, "default-bold", "center", "top", false, false, true)
		end 
	end, 
}

class "CClientPianoManager"
{
	__init__ = function(self)
		self.notes = {} 
		
		self.handlingPiano = false 
		
		self.wasVehicleNameVisible = false 
		self.wasRadarVisible = false 
		
		addEvent("onClientPlayNote", true)
		addEventHandler("onClientPlayNote", root, function(note, x, y, z) self:playNote(note, x, y, z) end)
		
		addEvent("onClientStopNote", true)
		addEventHandler("onClientStopNote", root, function(note, x, y, z) self:stopNote(note, x, y, z) end)
		
		addEvent("onClientEnterPiano", true)
		addEventHandler("onClientEnterPiano", root, function(piano) self:enterPiano(piano) end)
		
		addEvent("onClientExitPiano", true)
		addEventHandler("onClientExitPiano", root, function() self:exitPiano() end)
		
		addEventHandler("onClientVehicleDamage", root, 
			function()
				if getElementData(source, "piano") then 
					cancelEvent()
				end 
			end 
		)
		addEventHandler("onClientRender", root, function() self:onRender() end)
	end, 
	
	enterPiano = function(self, piano)
		if isPlayerHudComponentVisible("vehicle_name") then 
			setPlayerHudComponentVisible("vehicle_name", false)
			self.wasVehicleNameVisible = true
		end 
		
		if isPlayerHudComponentVisible("radar") then 
			setPlayerHudComponentVisible("radar", false)
			self.wasRadarVisible = true
		end 
		
		repeat 
			setRadioChannel(0)
		until getRadioChannel() == 0
		
		self.handlingPiano = CClientPianoHandler(piano)
	end, 
	
	exitPiano = function(self)
		if self.handlingPiano then 
			self.handlingPiano:destroy() 
			self.handlingPiano = false 
			
			if self.wasVehicleNameVisible then 
				self.wasVehicleNameVisible = false 
				setTimer(setPlayerHudComponentVisible, 1500, 1, "vehicle_name", true)
			end 
			
			if self.wasRadarVisible then 
				self.wasRadarVisible = false
				setTimer(setPlayerHudComponentVisible, 1000, 1, "radar", true)
			end 
		end 
	end, 
	
	isPlayerUsingPiano = function(self)
		if isElement(player) and getElementType(player) == "player" then 
			return getElementData(player, "player:onPiano") == true
		else 
			return false
		end
	end,
	
	playNote = function(self, note, x, y, z)
		if not note then return end 
		
		if #self.notes > MAX_SOUND_LIMIT then -- stop first note after reaching limit 
			local snd = self.notes[1].sound
			if isElement(snd) then 
				stopSound(snd)
				table.remove(self.notes, 1)
			end
		end 
		
		local path = "snd/"..tostring(note)..".ogg"
		if fileExists(path) then 
			local sound = playSound3D(path, x, y, z, false)
			setSoundMaxDistance(sound, MAX_SOUND_DISTANCE)
			if FADE_POPS then 
				setSoundVolume(sound, 0)
				setSoundPosition(sound, 0.05)
			else 
				setSoundVolume(sound, SOUND_VOLUME)
			end 
			
			table.insert(self.notes, {note=note, sound=sound, fading=false, fadeTick=0, playTick=getTickCount()})
		end
	end, 
	
	stopNote = function(self, note, x, y, z)
		for k,v in ipairs(self.notes) do 
			if isElement(v.sound) then 
				if v.note == note then 
					-- smooth fade 
					v.fading = true 
				end 
			else 
				table.remove(self.notes, k)
			end
		end
	end,
	
	onRender = function(self)
		local now = getTickCount() 
		-- smooth sounds: delete pops & fading notes
		for k,v in ipairs(self.notes) do 
			if isElement(v.sound) then 
				-- it could be done by editing sound files, but i'm to lazy
				if FADE_POPS then 
					local progress = (now - v.playTick) / (v.playTick+50 - v.playTick)
					if progress < 2 then 
						local vol = interpolateBetween(0, 0, 0, SOUND_VOLUME, 0, 0, math.min(1, progress), "InQuad")
						setSoundVolume(v.sound, vol)
					end 
				end 
				
				if v.fading then 
					if now > v.fadeTick then 
						local vol = getSoundVolume(v.sound)
						if vol < 0.02 then 
							v.fading = false 
							stopSound(v.sound)
							table.remove(self.notes, k)
						else 
							setSoundVolume(v.sound, vol-0.01)
							v.fadeTick = getTickCount()+50
						end 
					end
				end
			end 
		end
	end, 
}

function onClientResourceStart() 
	pianoManager = CClientPianoManager()
	
	engineImportTXD(engineLoadTXD("models/piano.txd"), PIANO_MODEL)
	engineReplaceModel(engineLoadDFF("models/piano.dff"), PIANO_MODEL)
	
	if DISABLE_ENGINE_START_SOUND then 
		setWorldSoundEnabled(19, 37, false)
	end
end 
addEventHandler("onClientResourceStart", resourceRoot, onClientResourceStart)

function onClientResourceStop()
	pianoManager:exitPiano()
	setWorldSoundEnabled(19, 37, true)
end 
addEventHandler("onClientResourceStop", resourceRoot, onClientResourceStop)