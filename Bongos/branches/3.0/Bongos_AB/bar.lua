--[[
	BActionBar - A Bongos Actionbar
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local Action = Bongos:GetModule('ActionBar')

local ActionBar = Bongos:CreateWidgetClass('Frame', Bongos.Bar)
Action.Bar = ActionBar

function ActionBar:Create(id, numRows, numCols, point, x, y)
	local bar, isNew = self.super:Create(id, {
		rows = numRows,
		cols = numCols,
	})
	setmetatable(bar, self.mt)
	
	if isNew then
		bar:OnCreate()
	end

	bar:ClearAllPoints()
	bar:SetPoint(point, UIParent, 'BOTTOMLEFT', x, y)
	bar:SavePosition()
	bar:Layout()
end

function ActionBar:OnCreate()
	self.buttons = {}
end

function ActionBar:OnDestroy()
	for i,button in pairs(buttons) do
		button:Release()
		self.buttons[i] = nil
	end
end

function ActionBar:SetRows(rows)
	self.sets.rows = rows
	self:Layout()
end

function ActionBar:SetCols(cols)
	self.sets.cols = cols
	self:Layout()
end

function ActionBar:SetSpacing(spacing)
	self.sets.spacing = spacing
end

function ActionBar:Layout()
	local spacing = self.sets.spacing or 0
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

	for i = self.sets.rows * self.sets.cols + 1, #self.buttons do
		local button = self.buttons[i]
		button:Release()
		self.buttons[i] = nil
	end
end