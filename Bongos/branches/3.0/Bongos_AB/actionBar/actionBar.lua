--[[
	actionbar event code
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local ActionBar = Bongos:NewModule('ActionBar', 'AceEvent-3.0')
local actions = {}

function ActionBar:Load(isNewProfile)
	for i = 1, 132 do
		actions[i] = HasAction(i)
	end

	if isNewProfile then
		local defaults = {point = 'BOTTOM', rows = 1, cols = 12}
	
		defaults.ids, defaults.states, defaults.numStates = self:GetDefaultActions(select(2, UnitClass('player'))

		--load keybinding from old bongos versions & the default ui
		local bindings = {}
		for i = 1, 12 do
			local binding = GetBindingKey(format('CLICK BActionButton%d:LeftButton', i)) or
							GetBindingKey(format('CLICK BongosActionButton%d:LeftButton', i)) or
							GetBindingKey(format('ActionButton%d', i))
			bindings[i] = binding
		end
		defaults.bindings = bindings

		Bongos:SetBarSets(1, defaults)
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
	self:RegisterMessage('KEYBOUND_ENABLED', 'UpdateVisibility')
	self:RegisterMessage('KEYBOUND_DISABLED', 'UpdateVisibility')
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

function ActionBar:GetDefaultActions(class)
	if class == 'DRUID' then
		header['[form:1]'] = 3
		header['[form:3]'] = 2

		--bar 1 (caster)
		buttons = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}

		--bar 7 (cat)
		for i = 73, 84 do
			table.insert(buttons, i)
		end

		--bar 8 (bear)
		for i = 97, 108 do
			table.insert(buttons, i)
		end
	elseif class == 'WARRIOR' then
		header['[form:2]'] = 2
		header['[form:3]'] = 3

		--bars 7-9 (battle, defensive, berserker)
		buttons = {}
		for i = 73, 108 do
			table.insert(buttons, i)
		end
	elseif class == 'ROGUE' or class == 'PRIEST' then
		header['[form:1]'] = 2

		--bar 1 (normal)
		buttons = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}

		--bar 7 (stealth, shadow form)
		for i = 73, 84 do
			table.insert(buttons, i)
		end
	end

	--figure out how many states we're using
	local maxState
	if header then
		for _,state in pairs(header) do
			maxState = max(maxState or 1, state)
		end
	end

	return buttons, header, maxState
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