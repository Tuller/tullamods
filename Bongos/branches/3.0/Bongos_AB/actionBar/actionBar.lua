--[[
	actionbar event code
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local ActionBar = Bongos:NewModule('ActionBar', 'AceEvent-3.0')

function ActionBar:Load(isNewProfile)
	if not self.Painter.loaded then
		self.Painter:Load()
	end
	
	if isNewProfile then
		Bongos:SetBarSets(1, {
			point = 'BOTTOM',
			rows = 1,
			cols = 12,
			ids = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12},
			numStates = 1,
			stateHeader = {},
		})
	end

	for id in Bongos:GetBars() do
		if tonumber(id) then
			self.Bar:Load(id)
		end
	end
end

function ActionBar:Unload()
	for i = 1, 120 do
		local bar = Bongos.Bar:Get(id)
		if bar then
			bar:Destroy()
		end
	end
end