--[[
	actionbar event code
--]]

BongosActionBar = Bongos:NewModule('Bongos-ActionBar')
local DEFAULT_NUM_ACTIONBARS = 10
local actions = {}

function BongosActionBar:Load()
	for i = 1, BONGOS_MAX_BUTTONS do
		actions[i] = HasAction(i)
	end
	for i = 1, self:GetNumber() do
		BActionBar:Create(i)
	end

	self:RegisterEvent('PLAYER_REGEN_ENABLED', 'OnLeaveCombat')

	self:RegisterEvent('ACTIONBAR_SLOT_CHANGED', 'OnSlotChanged')

	self:RegisterEvent('ACTIONBAR_SHOWGRID', 'UpdateGrid')
	self:RegisterEvent('ACTIONBAR_HIDEGRID', 'UpdateGrid')

	self:RegisterMessage('KEYBOUND_ENABLED', 'UpdateGrid')
	self:RegisterMessage('KEYBOUND_DISABLED', 'UpdateGrid')

	local class = select(2, UnitClass('player'))
	if class == 'DRUID' or class == 'ROGUE' or class == 'WARRIOR' or class == 'PRIEST' then
		self.numForms = GetNumShapeshiftForms()
		self:RegisterEvent('UPDATE_SHAPESHIFT_FORMS', 'UpdateStanceNumbers')
	end
end

function BongosActionBar:Unload()
	for i = 1, self:GetNumber() do
		BActionBar:Get(i):Destroy()
	end

	self:UnregisterAllEvents()
	self:UnregisterAllMessages()
end


--[[ Events ]]--

function BongosActionBar:OnLeaveCombat()
	if self.needsVisUpdate then
		self:UpdateVisibility()
	end

	if self.needsGridUpdate then
		self:UpdateGridVisibility()
	end
end

function BongosActionBar:OnSlotChanged(event, id)
	local hadAction = actions[id]
	if HasAction(id) ~= hadAction then
		actions[id] = HasAction(id)
		self:UpdateVisibility()
	end
	BongosActionButton:UpdateButtonsWithID(id)
end

function BongosActionBar:UpdateGrid(event)
	BongosActionButton.showEmpty = (event == 'ACTIONBAR_SHOWGRID')
	self:UpdateGridVisibility()
end

--updates the showstates of every button on every bar
function BongosActionBar:UpdateVisibility()
	if InCombatLockdown() then
		self.needsVisUpdate = true
	else
		self.needsVisUpdate = nil

		for i = 1, self:GetNumber() do
			local bar = BActionBar:Get(i)
			if bar:IsShown() then
				bar:UpdateVisibility()
			end
		end
	end
end

function BongosActionBar:UpdateGridVisibility()
	if InCombatLockdown() then
		self.needsGridUpdate = true
	else
		self.needsGridUpdate = nil

		for i = 1, self:GetNumber() do
			local bar = BActionBar:Get(i)
			if bar:IsShown() then
				bar:UpdateGrid()
			end
		end
	end
end

function BongosActionBar:UpdateStanceNumbers()
	local prevNumForms = self.numForms
	self.numForms = GetNumShapeshiftForms()

	if self.numForms ~= prevNumForms then
		for i = 1, self:GetNumber() do
			local bar = BActionBar:Get(i)
			bar:UpdateStateHeader()
			bar:UpdateButtonStates()
		end
	end
end


--[[ actionbar numbers ]]--

function BongosActionBar:SetNumber(newSize)
	if newSize ~= self:GetNumber() then
		self:Unload()
		Bongos.profile.numActionBars = newSize
		self:Load()
	end
end

function BongosActionBar:GetNumber()
	return Bongos.profile.numActionBars or DEFAULT_NUM_ACTIONBARS
end

--converts BActionButton and ActionButton bindings to their proper bongos bars, inspired from Bartender3
function BongosActionBar:ConvertBindings()
	--baction buttons
	for i = 1, 120 do
		local key = GetBindingKey(format('CLICK BActionButton%d:LeftButton', i))
		while key do
			SetBindingClick(key, format('BongosActionButton%d', i), 'LeftButton')
			key = GetBindingKey(format('CLICK BActionButton%d:LeftButton', i))
		end
	end

	--action buttons
	for i = 1, 12 do
		local key = GetBindingKey(format('ActionButton%d', i))
		while key do
			SetBindingClick(key, format('BongosActionButton%d', i), 'LeftButton')
			key = GetBindingKey(format('ActionButton%d', i))
		end
	end

	--left side multibars
	local k = 5
	for i = 1, 2 do
		for j = 1, 12 do
			local key = GetBindingKey(format('MULTIACTIONBAR%dBUTTON%d', i, j))
			while key do
				SetBindingClick(key, format('BongosActionButton%d', j+(k*12)), 'LeftButton')
				key = GetBindingKey(format('ActionButton%d', i))
			end
		end
		k = k - 1
	end

	--right side bars
	for i = 4, 3, -1 do
		for j = 1, 12 do
			local key = GetBindingKey(format('MULTIACTIONBAR%dBUTTON%d', i, j))
			while key do
				SetBindingClick(key, format('BongosActionButton%d', j+(k*12)), 'LeftButton')
				key = GetBindingKey(format('ActionButton%d', i))
			end
		end
		k = k - 1
	end
	SaveBindings(GetCurrentBindingSet())

	Bongos:Print('Converted keys from the blizzard actionbars and old bongos versions')
end
