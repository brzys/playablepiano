--[[
	-- Playable Piano by Brzysiek <brzysiekdev@gmail.com>
	-- Sounds exported from soundfont made by Keppy Studios (http://kaleidonkep99.altervista.org/keppy-s-steinway-piano.html)
	-- download_s.lua
	-- Get files for background download
]] 


class "CDownloadManager"
{
	__init__ = function(self)
		self.files = {}
		self.fileSizes = {}
		
		self:getFilesToDownload()
		
		addEvent("onPlayerInitDownload", true)
		addEventHandler("onPlayerInitDownload", root, function() self:onDownload() end)
	end, 
	
	getFilesToDownload = function(self)
		local xml = xmlLoadFile ("meta.xml")
		if xml == false then
			return
		end
		
		local node
		local index = 0
		local _next = function()
			node = xmlFindChild (xml, "file", index)
			index = index + 1
			return node
		end
		
		self.files = {} 
		self.fileSizes = {} 
		
		local num = 0
		while _next() do
			local path = xmlNodeGetAttribute (node, "src")
			local isClient = xmlNodeGetAttribute (node, "type")
			local download = xmlNodeGetAttribute (node, "download")
			if isClient == "client" and download == "false" then 
				local file = fileOpen(path, true)
				local size = fileGetSize(file)/1024^2
				fileClose(file)
				table.insert(self.files, path)
					
				self.fileSizes[path] = size 
				
				num = num + 1
			end 
		end
	end, 
	
	onDownload = function(self)
		triggerClientEvent(source, "onClientInitPianoDownload", source, self.files, self.fileSizes)
	end, 
}

function onResourceStart()
	downloadManager = CDownloadManager()
end 
addEventHandler("onResourceStart", resourceRoot, onResourceStart)