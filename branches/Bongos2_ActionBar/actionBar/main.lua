--[[
	actionbar event code
--]]

BongosActionBar = Bongos:NewModule('Bongos-ActionBar')
local DEFAULT_NUM_ACTIONBARS = 10
local actions = {}

function BongosActionBar:Load()
	for i = 1, 120 do 
		actions[i] = HasAction(i) 
	end
	for i = 1, self:GetNumber() do 
		BActionBar:Create(i) 
	end

	self:RegisterEvent('ACTIONBAR_SLOT_CHANGED', 'OnSlotChanged')
	self:RegisterEvent('PLAYER_REGEN_ENABLED', 'OnLeaveCombat')

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

function BongosActionBar:OnSlotChanged(event, id)
	local hasAction = actions[id]
	if(HasAction(id) ~= hasAction) then
		actions[id] = HasAction(id) or nil
		self:UpdateVisibility()
	end
	BongosActionButton:UpdateButtonsWithID(id)
end

function BongosActionBar:OnLeaveCombat()
	if self.updateVisibility then
		self:UpdateVisibility()
	end
	if self.updateGrid then
		self:UpdateGrid()
	end
end

function BongosActionBar:UpdateGrid(event)
	if(event == 'ACTIONBAR_SHOWGRID') then
		BongosActionButton.showEmpty = true
	elseif(event == 'ACTIONBAR_HIDEGRID') then
		BongosActionButton.showEmpty = nil
	end
	self:UpdateGrid()
end

--updates the showstates of every button on every bar
function BongosActionBar:UpdateVisibility()
	if InCombatLockdown() then
		self.updateVisibility = true
	else
		self.updateVisibility = nil

		for i = 1, self:GetNumber() do
			local bar = BActionBar:Get(i)
			if bar:IsShown() then
				bar:UpdateVisibility()
			end
		end
	end
end

function BongosActionButton:UpdateGrid()
	if InCombatLockdown() then
		self.updateGrid = true
	else
		self.updateGrid = nil
		for i = 1, self:GetNumber() do
			local bar = BActionBar:Get(i)
			if bar:IsShown() then
				local s, e = bar:GetStartID(), bar:GetEndID()
				for j = s, e do
					BongosActionButton:Get(j):UpdateGrid()
				end
			end
		end
	end
end

function BongosActionBar:UpdateStanceNumbers()
	local prev = self.numForms
	self.numForms = GetNumShapeshiftForms()

	if(self.numForms ~= prev) then
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
	return Bongos.profile.numActionBars or 10
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
