--[[
	-- Playable Piano by Brzysiek <brzysiekdev@gmail.com>
	-- Sounds exported from soundfont made by Keppy Studios (http://kaleidonkep99.altervista.org/keppy-s-steinway-piano.html)
	-- download_c.lua
	-- Download sounds in background
]] 

local screenW, screenH = guiGetScreenSize() 

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

class "CClientDownloadManager"
{
	__init__ = function(self)
		self.downloadQueue = {}
		self.fileSizes = {}
		self.downloadFilesSize = 0 
		self.downloadedFilesSize = 0
		self.currentDownloading = ""
		self.infoText = "" 
		
		addEvent("onClientInitPianoDownload", true)
		addEventHandler("onClientInitPianoDownload", root, function(files, fileSizes) self:initDownload(files, fileSizes) end)

		addEventHandler("onClientFileDownloadComplete", resourceRoot, function(file, success) self:onDownloadFile(file, success) end)
		
		self.renderFunc = function() self:onRender() end 
		if SHOW_DOWNLOAD_INFO then addEventHandler("onClientRender", root, self.renderFunc) end 
		
		setTimer(triggerServerEvent, 1000, 1, "onPlayerInitDownload", localPlayer)
	end,
	
	initDownload = function(self, filesToDownload, fileSizes)
		for k,v in ipairs(filesToDownload) do 
			self.fileSizes = fileSizes
			
			local size = fileSizes[v]
			self.downloadFilesSize = self.downloadFilesSize+size 
			table.insert(self.downloadQueue, v)
		end
	
		if #self.downloadQueue > 0 then 
			self.currentDownloading = self.downloadQueue[1]
			setTimer(function() self:startDownload() end, 1000, 1)
		end 
	end,
	
	startDownload = function(self)
		local path, file, _ = string.match(self.currentDownloading, "(.-)([^\\/]-%.?([^%.\\/]*))$")
		if getLocalization()["code"] == "pl" then 
			self.infoText = "Pobieranie zasobów fortepianu: "..file.." ("..tostring(round(self.downloadedFilesSize, 2)).." MB / "..tostring(round(self.downloadFilesSize, 2)).."MB)"
		else 
			self.infoText = "Downloading piano resources: "..file.." ("..tostring(round(self.downloadedFilesSize, 2)).." MB / "..tostring(round(self.downloadFilesSize, 2)).."MB)"
		end
		
		downloadFile(self.currentDownloading)
	end,
	
	endDownload = function(self)
		if SHOW_DOWNLOAD_INFO then removeEventHandler("onClientRender", root, self.renderFunc) end
		self.downloadQueue = {}
		self.fileSizes = {}
		self.downloadFilesSize = 0 
		self.downloadedFilesSize = 0
		self.currentDownloading = ""
		self.infoText = "" 
	end, 
	
	onDownloadFile = function(self, file, success)
		if source == resourceRoot then 
			if success then 
				table.remove(self.downloadQueue, 1)
				
				self.downloadedFilesSize = self.downloadedFilesSize+self.fileSizes[file]
				if #self.downloadQueue > 0 then 
					self.currentDownloading = self.downloadQueue[1]
					self:startDownload()
				else 
					self:endDownload()
				end
			else 
				self:startDownload()
			end
		end
	end, 
	
	onRender = function(self)
		dxDrawText(self.infoText, screenW, 7, screenW-20, 0, tocolor(200, 200, 200, 200), 1.0, "default", "right", "top", false, false, true)
	end,
}

function onClientResourceStart() 
	downloadManager = CClientDownloadManager()
end
addEventHandler("onClientResourceStart", resourceRoot, onClientResourceStart)