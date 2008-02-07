--[[
	BActionBar - A Bongos Actionbar
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local Action = Bongos:GetModule('ActionBar')

local ActionBar = Bongos:CreateWidgetClass('Frame', Bongos.Bar)
Action.Bar = ActionBar

function ActionBar:Create(numRows, numCols, point, x, y)
	if numRows * numCols <= self:NumFreeIDs() then
		local id
		for i = 1, #Action.profile.bars + 1 do
			if not Action.profile.bars[i] then
				id = i
				break
			end
		end
	
		local bar, isNew = self.super.Create(self, id, {
			rows = numRows,
			cols = numCols,
			ids = {},
		})

		if isNew then
			bar:OnCreate()
		end

		bar:ClearAllPoints()
		bar:SetPoint(point, UIParent, 'BOTTOMLEFT', x, y)
		bar:SavePosition()
		bar:Layout()
		bar:ConsumeIDs()
		
		Action.profile.bars[id] = true
	else
		UIErrorsFrame:AddMessage('Not Enough Available Action IDs', 1, 0.2, 0.2, 1, UIERRORS_HOLD_TIME)
	end
end

function ActionBar:Load(id)
	local bar, isNew = self.super.Create(self, id)
	if isNew then
		bar:OnCreate()
	end

	bar:Layout()
	bar:LoadIDs()
end
	

function ActionBar:OnCreate()
	self.buttons = {}
end

function ActionBar:OnDelete()
	for i,button in self:GetButtons() do
		button:Release()
		self.buttons[i] = nil
	end
	self:ReleaseAllIDs()
	
	Action.profile.bars[self.id] = nil
end

function ActionBar:SetRows(rows)
	self.sets.rows = rows
	self:Layout()
	self:ConsumeIDs()
end

function ActionBar:SetCols(cols)
	self.sets.cols = cols
	self:Layout()
	self:ConsumeIDs()
end

function ActionBar:SetSpacing(spacing)
	self.sets.spacing = spacing
	self:Layout()
end

function ActionBar:SetStates(numStates)
	self.sets.states = numStates
	self:ConsumeIDs()
end

function ActionBar:GetSize()
	return (self.sets.cols or 1)*(self.sets.rows or 1)
end

function ActionBar:GetNumStates()
	return self.sets.states or 1
end

function ActionBar:GetSpacing()
	return self.sets.spacing or 1
end

function ActionBar:Layout()
	local spacing = self:GetSpacing()
	local buttonSize = 37 + spacing

	self:SetWidth(buttonSize*self.sets.cols - spacing)
	self:SetHeight(buttonSize*self.sets.rows - spacing)

	local k = 0
	for i = 1, self.sets.rows do
		for j = 1, self.sets.cols do
			k = k + 1
			local button = self.buttons[k]
			if not button then
				button = Action.Button:Get(self)
				self.buttons[k] = button
			end
			button:ClearAllPoints()
			button:SetPoint('TOPLEFT', buttonSize*(j-1), -buttonSize*(i-1))
			button:Show()
		end
	end

	for i = self:GetSize() + 1, #self.buttons do
		local button = self.buttons[i]
		button:Release()
		self.buttons[i] = nil
	end
end

function ActionBar:ConsumeIDs()
	local ids = self.sets.ids
	local numIDs = self:GetNumStates() * self:GetSize()

	for i = 1, numIDs do
		if not ids[i] then
			ids[i] = self:TakeID()
		end
	end

	for i = #ids, numIDs + 1, -1 do
		self:GiveID(ids[i])
		ids[i] = nil
	end

	self:UpdateActions()
end

function ActionBar:LoadIDs()
	for _,id in pairs(self.sets.ids) do
		self:TakeID(id)
	end
	self:UpdateActions()
end

function ActionBar:ReleaseAllIDs()
	local ids = self.sets.ids
	for i = #self.sets.ids, 1, -1 do
		self:GiveID(ids[i])
	end
end

function ActionBar:UpdateActions()
	local states = self.sets.states or 1
	local ids = self.sets.ids
	local index = 1

	for i = 1, self:GetSize() do
		local button = self.buttons[i]
		for j = 1, self:GetNumStates() do
			if j == 1 then
				button:SetAttribute('action', ids[index])
				button:SetAttribute('action2', ids[index])
			else
				button:SetAttribute(format('*action-s%d', j), ids[index])
				button:SetAttribute(format('*action-s%d2', j), ids[index])
			end
			index = index + 1
		end
		button:Update(true)
	end
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
end

function ActionBar:GetButtons()
	return pairs(self.buttons)
end