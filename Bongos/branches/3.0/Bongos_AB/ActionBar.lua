--[[
	actionbar event code
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local ActionBar = Bongos:NewModule('ActionBar', 'AceEvent-3.0')

function ActionBar:Load()
	if not Bongos3ABDB then
		Bongos3ABDB = { bars = {} }
	end
	self.profile = Bongos3ABDB
	
	if not self.Painter.loaded then
		self.Painter:Load()
	end
	
	if next(self.profile.bars) then
		for id in pairs(self.profile.bars) do
			self.Bar:Load(id)
		end
	else
		Bongos:Cleanup()
	end
end

function ActionBar:Unload()
	for id,bar in pairs(self.profile.bars) do
		bar:Destroy()
		self.bars[id] = nil
	end
end