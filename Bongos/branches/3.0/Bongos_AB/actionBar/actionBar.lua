--[[
	actionbar event code
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local ActionBar = Bongos:NewModule('ActionBar', 'AceEvent-3.0')
local actions = {}

function ActionBar:Load(isNewProfile)
	for i = 1, 120 do
		actions[i] = HasAction(i)
	end

	if isNewProfile then
		local header = {}

		local class = select(2, UnitClass('player'))
		if class == 'DRUID' then
			header['[form:1]'] = 2
			header['[form:3]'] = 3
			maxState = 3
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
	
	self:RegisterEvent('PLAYER_REGEN_ENABLED', 'OnLeaveCombat')
	self:RegisterEvent('ACTIONBAR_SLOT_CHANGED', 'OnSlotChanged')
	self:RegisterEvent('ACTIONBAR_SHOWGRID', 'UpdateGrid')
	self:RegisterEvent('ACTIONBAR_HIDEGRID', 'UpdateGrid')
	self:RegisterMessage('KEYBOUND_ENABLED', 'UpdateGrid')
	self:RegisterMessage('KEYBOUND_DISABLED', 'UpdateGrid')
end

function ActionBar:Unload()
	for id,bar in Bongos.Bar:GetAll() do
		if tonumber(id) then
			bar:Destroy()
		end
	end
	
	self:UnregisterAllEvents()
	self:UnregisterAllMessages()
end

--[[ Events ]]--

function ActionBar:OnLeaveCombat()
	if self.needsVisUpdate then
		self:UpdateVisibility()
	end

	if self.needsGridUpdate then
		self:UpdateGridVisibility()
	end
end

function ActionBar:OnSlotChanged(event, id)
	local hadAction = actions[id]
	if HasAction(id) ~= hadAction then
		actions[id] = HasAction(id)
		self:UpdateVisibility()
	end

	for id,bar in self.Bar:GetAll() do
		if tonumber(id) and bar:IsShown() then
			bar:UpdateAction(id)
		end
	end
end

function ActionBar:UpdateGrid(event)
	self.Button.showEmpty = (event == 'ACTIONBAR_SHOWGRID')
	self:UpdateGridVisibility()
end

--updates the showstates of every button on every bar
function ActionBar:UpdateVisibility()
	if InCombatLockdown() then
		self.needsVisUpdate = true
	else
		self.needsVisUpdate = nil

		for id,bar in self.Bar:GetAll() do
			if tonumber(id) and bar:IsShown() then
				bar:UpdateVisibility()
			end
		end
	end
end

function ActionBar:UpdateGridVisibility()
	if InCombatLockdown() then
		self.needsGridUpdate = true
	else
		self.needsGridUpdate = nil

		for id,bar in self.Bar:GetAll() do
			if tonumber(id) and bar:IsShown() then
				bar:UpdateGrid()
			end
		end
	end
end