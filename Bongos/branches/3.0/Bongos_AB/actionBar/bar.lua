--[[
	BActionBar - A Bongos Actionbar
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local Action = Bongos:GetModule('ActionBar')

local ActionBar = Bongos:CreateWidgetClass('Frame', Bongos.Bar)
Action.Bar = ActionBar

function ActionBar:Create(numRows, numCols, point, x, y)
	if numRows * numCols <= self:NumFreeIDs() then
		--get the next available barID
		local id = 1
		while Bongos.Bar:Get(id) do
			id = id + 1
		end

		local defaults = {
			rows = numRows,
			cols = numCols,
		}
		local bar, isNew = self.super.Create(self, id, defaults, true)
		if isNew then
			bar:OnCreate()
		end

		--place the bar, the point starts relative to UIParent bottom left, make it not that
		bar:ClearAllPoints()
		bar:SetPoint(point, UIParent, 'BOTTOMLEFT', x, y)
		bar:SavePosition()

		bar:UpdateUsedIDs()
		bar:UpdateStates()
		bar:UpdateActions()
		bar:UpdateStateDriver()
		bar:Layout()
	else
		UIErrorsFrame:AddMessage('Not Enough Available Action IDs', 1, 0.2, 0.2, 1, UIERRORS_HOLD_TIME)
	end
end

function ActionBar:Load(id)
	local bar, isNew = self.super.Create(self, id, nil, true)
	if isNew then
		bar:OnCreate()
	end

	bar:LoadIDs()
	bar:UpdateStates()
	bar:UpdateActions()
	bar:UpdateStateDriver()
	bar:Layout()
end

function ActionBar:OnCreate()
	self.buttons = {}
	self:SetAttribute('statemap-state', '$input')
	self:SetAttribute('statebindings', '*:main')
end

function ActionBar:OnDelete()
	for i,button in self:GetButtons() do
		button:Release()
		self.buttons[i] = nil
	end
	self:ReleaseAllIDs()
end

--[[ Dimensions ]]--

function ActionBar:SetSize(rows, cols)
	local newSize = rows * cols
	local oldSize = self:GetRows() * self:GetCols()
	self.sets.rows = rows
	self.sets.cols = cols

	if newSize ~= oldSize then
		self:UpdateUsedIDs()
		self:UpdateActions()
	end
	self:Layout()
end

function ActionBar:GetRows()
	return self.sets.rows or 1
end

function ActionBar:GetCols()
	return self.sets.cols or 1
end

--spacing
function ActionBar:SetSpacing(spacing)
	self.sets.spacing = spacing
	self:Layout()
end

function ActionBar:GetSpacing()
	return self.sets.spacing or 1
end


--[[ Update & Layout ]]--

--add/remove buttons and update their actionsIDs for each state
--needs to be called whenever the size/number of pages of a bar changes
function ActionBar:UpdateActions()
	local states = self:NumStates()
	local ids = self.sets.ids
	local numButtons = self:GetCols() * self:GetRows()
	local index = 1

	for state = 1, self:NumStates() do
		for index = 1, numButtons do
			local button = self:GetButton(index) or self:AddButton(index)
			local actionID = ids[index + numButtons*(state-1)]
			if state == 1 then
				button:SetAttribute('action', actionID)
				button.needsUpdate = true
			else
				button:SetAttribute(format('*action-s%d', state), actionID)
				button:SetAttribute(format('*action-s%ds', state), actionID)
			end
		end
	end

	for i = numButtons + 1, #self.buttons do
		local button = self.buttons[i]
		button:Release()
		self.buttons[i] = nil
	end
end

--layout needs to be called whenever the amount of buttons or dimensions of a bar change
--layout must be performed only AFTER we actually have buttons
function ActionBar:Layout()
	local spacing = self:GetSpacing()
	local buttonSize = 37 + spacing
	local rows, cols = self:GetRows(), self:GetCols()

	self:SetWidth(buttonSize*cols - spacing)
	self:SetHeight(buttonSize*rows - spacing)

	for i = 1, rows do
		for j = 1, cols do
			local button = self.buttons[j + cols*(i-1)]
			button:ClearAllPoints()
			button:SetPoint('TOPLEFT', buttonSize*(j-1), -buttonSize*(i-1))
			button:Show()
		end
	end
	
	self:UpdateVisibility()
end

function ActionBar:UpdateVisibility()
	local changed = false
	for _,button in self:GetButtons() do
		if button:UpdateVisibility() then
			changed = true
		end
	end

	if changed then
		SecureStateHeader_Refresh(self)
		if not InCombatLockdown() then
			self:UpdateGrid()
		end
	end
end

function ActionBar:UpdateGrid()
	for _,button in self:GetButtons() do
		button:UpdateGrid()
	end
end

function ActionBar:UpdateAction(id)
	for _,button in self:GetButtons() do
		if button:GetPagedID() == id then
			button:Update()
			button:UpdateSpellID()
		end
	end
end


--[[ States ]]--

--states: allow us to map a button to multiple virtual buttons
function ActionBar:SetNumStates(numStates)
	if numStates ~= self:NumStates() then
		self.sets.numStates = numStates
		self:UpdateUsedIDs()
		self:UpdateActions()
	end
end

function ActionBar:UpdateStates()
	local stateButton = ''
	local stateButton2 = ''

	for i = 2, self:NumStates() do
		stateButton = stateButton .. format('%d:s%d;', i, i)
		stateButton2 = stateButton2 .. format('%d:s%ds;', i, i)
	end

	if stateButton == '' then
		self:SetAttribute('statebutton', nil)
		self:SetAttribute('*statebutton2', nil)
	else
		self:SetAttribute('statebutton', stateButton)
		self:SetAttribute('*statebutton2', stateButton2)
	end
end

function ActionBar:NumStates()
	return self.sets.numStates or 1
end


--[[ Condition - State Mapping ]]--

--needs to be called whenever we change a state condition
--or when we change the number of available states
local stateConditions
function ActionBar:UpdateStateDriver()
	if not stateConditions then
		stateConditions = {}

		--modifiers
		table.insert(stateConditions, '[mod:ctrl]')
		table.insert(stateConditions, '[mod:alt]')
		table.insert(stateConditions, '[mod:shift]')

		--pages
		for i = 2, 6 do
			table.insert(stateConditions, format('[bar:%d]', i))
		end

		--forms
		table.insert(stateConditions, '[form:2/3,stealth]')

		for i = 1, 7 do
			table.insert(stateConditions, format('[form:%d]', i))
		end

		--help harm targeting
		table.insert(stateConditions, '[help]')
		table.insert(stateConditions, '[harm]')
	end

	UnregisterStateDriver(self, "state", 0)

	local header = ''
	for _,condition in ipairs(stateConditions) do
		local state = self:GetConditionState(condition)
		if state then
			header = header .. condition .. state .. ';'
		end
	end

	if header ~= '' then
		RegisterStateDriver(self, 'state', header .. '0')
	end
end

--state conditions specify when we  switch states.  uses the macro syntax for now
function ActionBar:SetConditionState(condition, state)
	if not self.sets.states then
		self.sets.states = {}
	end

	if self.sets.states[condition] ~= state then
		self.sets.stateHeader[condition] = state
		self:UpdateStateDriver()
	end
end

function ActionBar:GetConditionState(condition)
	return self.sets.states and self.sets.states[condition]
end


--[[ ID Grabbing ]]--

function ActionBar:LoadIDs()
	if self.sets.ids then
		for _,id in pairs(self.sets.ids) do
			self:TakeID(id)
		end
		self:SortAvailableIDs()
	else
		self:UpdateUsedIDs()
	end
end

function ActionBar:UpdateUsedIDs()
	if not self.sets.ids then
		self.sets.ids = {}
	end

	local ids = self.sets.ids
	local numActions = self:GetRows() * self:GetCols() * self:NumStates()

	for i = 1, (self:GetRows() * self:GetCols() * self:NumStates()) do
		if not ids[i] then
			ids[i] = self:TakeID()
		end
	end

	for i = #ids, numActions + 1, -1 do
		self:GiveID(ids[i])
		ids[i] = nil
	end
	self:SortAvailableIDs()
end

function ActionBar:ReleaseAllIDs()
	local ids = self.sets.ids
	for i = #self.sets.ids, 1, -1 do
		self:GiveID(ids[i])
	end
	self:SortAvailableIDs()
end

do
	local freeActions = {}
	for i = 1, 120 do
		freeActions[i] = i
	end

	function ActionBar:TakeID(id)
		if id then
			for i,availableID in pairs(freeActions) do
				if id == availableID then
					table.remove(freeActions, i)
					Action.Painter:UpdateText()
					return
				end
			end
		else
			local id = table.remove(freeActions, 1)
			Action.Painter:UpdateText()
			return id
		end
	end

	function ActionBar:GiveID(id)
		table.insert(freeActions, 1, id)
		Action.Painter:UpdateText()
	end

	function ActionBar:NumFreeIDs()
		return #freeActions
	end

	function ActionBar:SortAvailableIDs()
		table.sort(freeActions)
	end
end


--[[ Button Creation ]]--

function ActionBar:AddButton(index)
	local button = Action.Button:Get(self)
	self.buttons[index] = button
	
	button.index = index
	self:UpdateButtonBindings(index)
	
	return button
end

function ActionBar:GetButton(index)
	return self.buttons and self.buttons[index]
end

function ActionBar:GetButtons()
	return pairs(self.buttons)
end


--[[ Bindings ]]--

local function splitNext(sep, body)
    if (body) then
        local pre, post = strsplit(sep, body, 2);
        if (post) then
            return post, pre;
        end
        return false, body;
    end
end
local function semicolonIterator(str) return splitNext, ";", str; end

function ActionBar:AddBinding(index, newBinding)
	if newBinding then
		local bindings = self:GetBindings(index)
		if bindings then
			if bindings == newBinding then
				return
			end

			for _,binding in semicolonIterator(bindings) do
				if binding == newBinding then
					return
				end
			end

			self.sets.bindings[index] = bindings .. ';' .. newBinding
		else
			if not self.sets.bindings then
				self.sets.bindings = {}
			end
			self.sets.bindings[index] = newBinding
		end
		self:UpdateButtonBindings(index)
	end
end

function ActionBar:RemoveBinding(index, binding)
	local bindings = self:GetBindings(index)
	local changed

	if bindings == binding then
		self.sets.bindings[index] = nil
		changed = true
	else
		local newBindings
		for _,b in semicolonIterator(bindings) do
			if b ~= binding then
				if newBindings then
					newBindings = newBindings .. ';' .. b
				else
					newBindings = b
				end
			else
				changed = true
			end
		end
		self.sets.bindings[index] = newBindings
	end
	self:UpdateButtonBindings(index)
	return changed
end

function ActionBar:FreeBinding(binding)
	local changed

	for _,bar in self:GetAll() do
		local bindings = bar.sets.bindings
		if bindings then
			for index in pairs(bindings) do
				if bar:RemoveBinding(index, binding) then
					changed = true
				end
			end
		end
	end
	return changed
end

function ActionBar:ClearBindings(index)
	local bindings = self:GetBindings(index)
	if bindings then
		self.sets.bindings[index] = nil
		self:UpdateButtonBindings(index)
	end
end

function ActionBar:GetBindings(index)
	return self.sets.bindings and self.sets.bindings[index]
end

function ActionBar:UpdateButtonBindings(index)
	local button = self:GetButton(index)
	if button then
		button:SetAttribute('bindings-main', self:GetBindings(index))
		button:UpdateHotkey()
		self:SetAttribute("_bindingset", nil)
		SecureStateHeader_Refresh(self)
	end
end


--[[ Menu Code ]]--

function ActionBar:CreateMenu()
	local menu = Bongos.Menu:Create(self.id)
	ActionBar.menu = menu

	local panel = menu:AddLayoutPanel()

	panel:CreateSpacingSlider()

	local states, rows, cols
	local function UpdateSliderSizes(bar)
		local freeIDs = bar:NumFreeIDs()

		local maxStates = bar:GetCols() * bar:GetRows()
		states:SetMinMaxValues(1, floor(freeIDs / maxStates) + bar:NumStates())

		local maxRows = bar:GetCols() * bar:NumStates()
		rows:SetMinMaxValues(1, floor(freeIDs / maxRows) + bar:GetRows())

		local maxCols = bar:GetRows() * bar:NumStates()
		cols:SetMinMaxValues(1, floor(freeIDs / maxCols) + bar:GetCols())
	end

	states = panel:CreateSlider('States', 1, 1, 1)
	function states:UpdateValue(value)
		local bar = Bongos.Bar:Get(self:GetParent().id)
		bar:SetNumStates(value)
		UpdateSliderSizes(bar)
	end
	function states:OnShow()
		local bar = Bongos.Bar:Get(self:GetParent().id)
		local freeIDs = bar:NumFreeIDs()
		local maxStates = bar:GetCols() * bar:GetRows()

		self:SetMinMaxValues(1, floor(freeIDs / maxStates) + bar:NumStates())
		self:SetValue(bar:NumStates())
	end

	cols = panel:CreateSlider('Cols', 1, 1, 1)
	function cols:UpdateValue(value)
		local bar = Bongos.Bar:Get(self:GetParent().id)
		bar:SetSize(bar:GetRows(), value)
		UpdateSliderSizes(bar)
	end
	function cols:OnShow()
		local bar = Bongos.Bar:Get(self:GetParent().id)
		local maxCols = bar:GetRows() * bar:NumStates()
		local freeIDs = bar:NumFreeIDs()

		self:SetMinMaxValues(1, floor(freeIDs / maxCols) + bar:GetCols())
		self:SetValue(bar:GetCols())
	end

	rows = panel:CreateSlider('Rows', 1, 1, 1)
	function rows:UpdateValue(value)
		local bar = Bongos.Bar:Get(self:GetParent().id)
		bar:SetSize(value, bar:GetCols())
		UpdateSliderSizes(bar)
	end
	function rows:OnShow()
		local bar = Bongos.Bar:Get(self:GetParent().id)
		local maxRows = bar:GetCols() * bar:NumStates()
		local freeIDs = bar:NumFreeIDs()

		self:SetMinMaxValues(1, floor(freeIDs / maxRows) + bar:GetRows())
		self:SetValue(bar:GetRows())
	end

	return menu
end