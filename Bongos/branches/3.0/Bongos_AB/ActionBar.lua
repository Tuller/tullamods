--[[
	actionbar event code
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local ActionBar = Bongos:NewModule('ActionBar', 'AceEvent-3.0')

function ActionBar:Load()
	if Bongos:IsLocked() then
		ActionBar.Painter:Hide()
	end
	
	self:RegisterMessage('BONGOS_LOCKED')
	self:RegisterMessage('BONGOS_UNLOCKED')
	Bongos:Cleanup()
end

function ActionBar:BONGOS_LOCKED()
	ActionBar.Painter:Hide()
end

function ActionBar:BONGOS_UNLOCKED()
	ActionBar.Painter:Show()
end

function ActionBar:Unload()
	for id,bar in pairs(self.bars) do
		bar:Destroy()
		self.bars[id] = nil
	end
end