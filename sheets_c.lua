--[[
	-- Playable Piano by Brzysiek <brzysiekdev@gmail.com>
	-- Sounds exported from soundfont made by Keppy Studios (http://kaleidonkep99.altervista.org/keppy-s-steinway-piano.html)
	-- sheets_c.lua
	-- Provides some sheet music from virtualpiano.net
]] 

local sw, sh = guiGetScreenSize() 
local sx, sy = sw/1366, sh/768
class "CSheets"
{
	__init__= function(self)
		-- TODO: add isBrowserSupported() after releasing 1.5.4
		self.browserW, self.browserH = 730*sx, 400*sy
		self.browserX, self.browserY = sw/2-self.browserW/2, sh/2.3-self.browserH/2
		self.browser = createBrowser(self.browserW, self.browserH, false, false)
	 	self.scrollUpdateFunc = function(key) -- any ideas why this doesn't work: please write to me :E
			if not self.show then return end 
			
			if key == "mouse_wheel_up" then 
				injectBrowserMouseWheel(self.browser, 70, 0)
			elseif key == "mouse_wheel_down" then
				injectBrowserMouseWheel(self.browser, -70, 0)
			end
		end 
		
		self.cursorUpdateFunc = function(_, _, x, y) 
			if not self.show then return end 
			
			x = x - self.browserX
			y = y - self.browserY
			injectBrowserMouseMove (self.browser, x, y) 
		end
		
		self.clickUpdateFunc = function(button, press)
			if not self.show then return end 
			
			if button == "left" and press == "down" then 
				injectBrowserMouseDown(self.browser, "left") 
			elseif button == "left" and press == "up" then 
				injectBrowserMouseUp(self.browser, "left") 
			end
		end 
		self.renderFunc = function() self:onRender() end 
		
		requestBrowserDomains({"virtualpiano.net", "virtualpiano.net/music-sheets/", "i1.wp.com", "i2.wp.com"})
		addEventHandler("onClientBrowserWhitelistChange", root, function(changedDomains) 
			for k,v in ipairs(changedDomains) do
				if v == "virtualpiano.net" then  
					self:load()
				end
			end 
		end) 
	
		addEventHandler("onClientBrowserCreated", self.browser, function()
			if not isBrowserDomainBlocked("virtualpiano.net") then 
				self:load()
			else 
				if getLocalization()["code"] == "pl" then 
					outputChatBox("By wyświetlić nuty musisz zaakceptować domeny.", 255, 0, 0)
				else 
					outputChatBox("To see sheets you must accept domains.", 255, 0, 0)
				end
			end 
		end)
		
		self.show = true 
		self.lastShow = 0 
		
		showCursor(true)
	end,
	
	toggle = function(self)
		if self.lastShow > getTickCount() then return end 
		
		self.show = not self.show 
		self.lastShow = getTickCount()+500
	end, 
	
	load = function(self)
		if not isElement(self.browser) then return end 
		
		loadBrowserURL(self.browser, "http://virtualpiano.net/music-sheets")
		-- focusBrowser(self.browser) onClientKey with this doesnt work :C
		
		addEventHandler("onClientKey", root, self.scrollUpdateFunc)
		addEventHandler("onClientCursorMove", root, self.cursorUpdateFunc)
		addEventHandler("onClientRender", root, self.renderFunc)
		addEventHandler("onClientClick", root, self.clickUpdateFunc)
		
		addEventHandler("onClientBrowserDocumentReady", self.browser, function(url) if url == "http://virtualpiano.net/music-sheets" then injectBrowserMouseWheel(self.browser, -430, 0) end end)
	end, 
	
	destroy = function(self)
		showCursor(false)
		removeEventHandler("onClientKey", root, self.scrollUpdateFunc)
		removeEventHandler("onClientCursorMove", root, self.cursorUpdateFunc)
		removeEventHandler("onClientRender", root, self.renderFunc)
		removeEventHandler("onClientClick", root, self.clickUpdateFunc)
		if isElement(self.browser) then destroyElement(self.browser) end 
		collectgarbage("collect")
	end,
	
	onRender = function(self)
		if isElement(self.browser) and self.show then 
			local floor = math.floor
			dxDrawImage(floor(self.browserX), floor(self.browserY), floor(self.browserW), floor(self.browserH), self.browser, 0, 0, 0, tocolor(255,255,255,255), true)
		end 
	end,
}