--[[
	actionbar event code
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local ActionBar = Bongos:NewModule('ActionBar')
ActionBar.bars = {}

function ActionBar:Load()
	self.bars = {}
	Bongos:Cleanup()
	
	self:RegisterMessage('BONGOS_LOCKED')
	self:RegisterMessage('BONGOS_UNLOCKED')
end

function ActionBar:Unload()
	for id,bar in pairs(self.bars) do
		bar:Destroy()
		self.bars[id] = nil
	end
end