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
		local defaults = {point = 'BOTTOM', rows = 1, cols = 12, possessBar = true}

		defaults.ids, defaults.setMap, defaults.numSets = self:GetDefaultActions(select(2, UnitClass('player')))

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
	self:RegisterEvent('ACTIONBAR_SHOWGRID', 'OnShowGrid')
	self:RegisterEvent('ACTIONBAR_HIDEGRID', 'OnShowGrid')

	local kb = LibStub('LibKeyBound-1.0')
	kb.RegisterCallback(self, 'LIBKEYBOUND_ENABLED', 'UpdateGrid')
	kb.RegisterCallback(self, 'LIBKEYBOUND_DISABLED', 'UpdateGrid')
end

function ActionBar:Unload()
	self.Bar:ForAll('Destroy')
	self:UnregisterAllEvents()
	self:UnregisterAllMessages()
end

function ActionBar:GetDefaultActions(class)
	local header
	if class == 'DRUID' then
		header = {['[bonusbar:1]'] = 2, ['[bonusbar:3]'] = 4, ['[bonusbar:4]'] = 3, ['[bonusbar:2]'] = 3} --cat, bear, moonkin, tree

		--bar 1 (caster)
		buttons = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}

		--bar 7 (cat), bar 8 (tree/boomkin), bar 9 (bear)
		for i = 73, 108 do
			table.insert(buttons, i)
		end
	elseif class == 'WARRIOR' then
		header = {['[bonusbar:2]'] = 2, ['[bonusbar:3]'] = 3}

		--bars 7-9 (battle, defensive, berserker)
		buttons = {}
		for i = 73, 108 do
			table.insert(buttons, i)
		end
	elseif class == 'ROGUE' or class == 'PRIEST' then
		header = {['[bonusbar:1]'] = 2}

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
		self:UpdateShowStates()
	end

	if self.needsGridUpdate then
		self:UpdateGrid()
	end
end

function ActionBar:OnSlotChanged(event, id)
	local hadAction = actions[id]
	if HasAction(id) ~= hadAction then
		actions[id] = HasAction(id)
		self:UpdateShowStates()
	end
	self.Bar:ForAllShown('UpdateAction', id)
end

function ActionBar:OnShowGrid(event)
	self.Button.showEmpty = (event == 'ACTIONBAR_SHOWGRID')
	self:UpdateGrid()
end


--[[ Update Functions ]]--

--shows/hides buttons based on if we're in keybinding/showgrid mode
function ActionBar:UpdateGrid()
	if InCombatLockdown() then
		self.needsGridUpdate = true
	else
		self.needsGridUpdate = nil
		self.Bar:ForAllShown('UpdateShowEmpty')
	end
end

--updates the showstates of every button on every bar
function ActionBar:UpdateShowStates()
	if InCombatLockdown() then
		self.needsVisUpdate = true
	else
		self.needsVisUpdate = nil
		self.Bar:ForAllShown('UpdateShowStates')
	end
end