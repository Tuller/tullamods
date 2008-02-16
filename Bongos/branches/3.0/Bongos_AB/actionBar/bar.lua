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
			ids = {},
			stateHeader = {}
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

		Action.profile.bars[id] = true
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
end

function ActionBar:OnDelete()
	for i,button in self:GetButtons() do
		button:Release()
		self.buttons[i] = nil
	end
	self:ReleaseAllIDs()

	Action.profile.bars[self.id] = nil
end

--[[ Layout Stuff ]]--

function ActionBar:SetSize(rows, cols)
	local newSize = rows * cols
	local oldSize = self:GetSize()
	if (newSize - oldSize) <= self:NumFreeIDs() then
		self.sets.rows = rows
		self.sets.cols = cols

		if newSize ~= oldSize then
			self:UpdateUsedIDs()
			self:UpdateActions()
		end
		self:Layout()
	else
		UIErrorsFrame:AddMessage('Not Enough Available Action IDs', 1, 0.2, 0.2, 1, UIERRORS_HOLD_TIME)
	end
end

function ActionBar:GetRows()
	return self.sets.rows or 1
end

function ActionBar:GetCols()
	return self.sets.cols or 1
end

function ActionBar:GetSize()
	return self:GetCols() * self:GetRows()
end

--spacing
function ActionBar:SetSpacing(spacing)
	self.sets.spacing = spacing
	self:Layout()
end

function ActionBar:GetSpacing()
	return self.sets.spacing or 1
end

--states: allow us to map a button to multiple virtual buttons
function ActionBar:SetStates(numStates)
	if numStates ~= self:NumStates() then
		self.sets.states = numStates
		self:UpdateUsedIDs()
		self:UpdateActions()
	end
end

function ActionBar:UpdateStates()
	local stateButton = ''
	local stateButton2 = ''
	for i = 1, self:NumStates() do
		stateButton = stateButton .. format('%d:s%d;', i, i)
		stateButton2 = stateButton2 .. format('%d:s%ds;', i, i)
	end

	if stateButton == '' then
		self:SetAttribute('statebutton', nil)
		self:SetAttribute('statebutton2', nil)
	else
		self:SetAttribute('statebutton', stateButton)
		self:SetAttribute('*statebutton2', stateButton2)
	end
end

function ActionBar:NumStates()
	return self.sets.states or 0
end

--add/remove buttons and update their actionsIDs for each state
--needs to be called whenever the size/number of pages of a bar changes
function ActionBar:UpdateActions()
	local states = self:NumStates()
	local ids = self.sets.ids
	local numButtons = self:GetSize()
	local index = 1

	for i = 1, numButtons do
		local button = self.buttons[i]
		if not button then
			button = Action.Button:Get(self)
			self.buttons[i] = button
		end

		button:SetAttribute('action', ids[index])
		index = index + 1

		for j = 1, self:NumStates() do
			button:SetAttribute(format('*action-s%d', j), ids[index])
			button:SetAttribute(format('*action-s%ds', j), ids[index])
			index = index + 1
		end
		button.needsUpdate = true
	end

	for i = self:GetSize() + 1, #self.buttons do
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
end

--state conditions specify when we  switch states.  uses the macro syntax for now
function ActionBar:SetStateConditions(state, condition)
	if self.sets.stateHeader[state] ~= condition and state <= self:NumStates() then
		self.sets.stateHeader[state] = condition
		self:UpdateStateDriver()
	end
end

--needs to be called whenever we change a state condition
--or when we change the number of available states
function ActionBar:UpdateStateDriver()
	UnregisterStateDriver(self, 'state', 0)

	local header = ''
	for i = 1, self:NumStates() do
		local state = self:GetStateCondition(i)
		if state then
			header = header .. state .. i .. ';'
		end
	end

	Bongos:Print(header)
	if header ~= '' then
		RegisterStateDriver(self, 'state', header .. 0)
	end
end

function ActionBar:GetStateCondition(state)
	return self.sets.stateHeader[state]
end


--[[ ID Grabbing ]]--

function ActionBar:LoadIDs()
	for _,id in pairs(self.sets.ids) do
		self:TakeID(id)
	end
	self:SortAvailableIDs()
end

function ActionBar:UpdateUsedIDs()
	local ids = self.sets.ids
	local numIDs = (self:NumStates() + 1) * self:GetSize()

	for i = 1, numIDs do
		if not ids[i] then
			ids[i] = self:TakeID()
		end
	end

	for i = #ids, numIDs + 1, -1 do
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
	local availableActions = {}
	for i = 1, 120 do
		availableActions[i] = i
	end

	function ActionBar:TakeID(id)
		if id then
			for i,availableID in pairs(availableActions) do
				if id == availableID then
					table.remove(availableActions, i)
					Action.Painter:UpdateText()
					return
				end
			end
		else
			local id = table.remove(availableActions, 1)
			Action.Painter:UpdateText()
			return id
		end
	end

	function ActionBar:GiveID(id)
		table.insert(availableActions, 1, id)
		Action.Painter:UpdateText()
	end

	function ActionBar:NumFreeIDs()
		return #availableActions
	end

	function ActionBar:SortAvailableIDs()
		table.sort(availableActions)
	end
end

function ActionBar:GetButtons()
	return pairs(self.buttons)
end