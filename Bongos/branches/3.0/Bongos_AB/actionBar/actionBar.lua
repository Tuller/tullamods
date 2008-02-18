--[[
	actionbar event code
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local ActionBar = Bongos:NewModule('ActionBar', 'AceEvent-3.0')

function ActionBar:Load(isNewProfile)
	if isNewProfile then
		local header = {}

		local class = select(2, UnitClass('player'))
		if class == 'DRUID' then
			header['[mod:alt]'] = 2
			header['[help]'] = 2
			header['[form:1]'] = 3
			header['[form:3]'] = 4
			maxState = 4
		elseif class == 'WARRIOR' then
			header['[form:2]'] = 2
			header['[form:3]'] = 3
			maxState = 3
		elseif class == 'ROGUE' then
			header['[form:1]'] = 2
			maxState = 2
		else
			maxState = 6
		end

		Bongos:SetBarSets(1, {
			point = 'BOTTOM',
			rows = 1,
			cols = 12,
			states = header,
			numStates = maxState,
		})
	end

	if not self.Painter.loaded then
		self.Painter:Load()
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