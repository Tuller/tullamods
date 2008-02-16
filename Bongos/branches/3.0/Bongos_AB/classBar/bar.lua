--[[
	ClassBar
		A replacement for the Blizzard shapeshift bar
--]]

local class = select(2, UnitClass('player'))
if not(class == 'DRUID' or class == 'ROGUE' or class == 'WARRIOR' or class == 'PALADIN') then
	return
end

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local ClassBar = Bongos:NewModule('ClassBar', 'AceEvent-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3-AB')
local DEFAULT_SPACING = 2


local function Bar_SetSpacing(self, spacing)
	self:Layout(nil, spacing)
end

local function Bar_GetSpacing(self)
	return self.sets.spacing or DEFAULT_SPACING
end

local function Bar_Layout(self, cols, space)
	local numForms = GetNumShapeshiftForms()

	cols = (cols or self.sets.cols or numForms)
	self.sets.cols = (cols ~= numForms and cols) or nil

	space = (space or self.sets.space or DEFAULT_SPACING)
	self.sets.space = (space ~= DEFAULT_SPACING and space) or nil

	local size = 30 + space
	local offset = space / 2

	for i = 1, numForms do
		local row = (i - 1) % cols
		local col = ceil(i / cols) - 1
		ClassBar.Button:Get(i):SetPoint('TOPLEFT', size * row, -size * col)
	end

	self:SetWidth(size * cols - space)
	self:SetHeight(size * ceil(numForms/cols) - space)
end

local function Bar_CreateMenu(bar)
	local menu = Bongos.Menu:Create(bar.id)
	local panel = menu:AddLayoutPanel()

	--sliders
	panel:CreateSpacingSlider()

	local function Cols_OnShow(self)
		self:SetMinMaxValues(1, GetNumShapeshiftForms())
		self:SetValue(GetNumShapeshiftForms() - (bar.sets.cols or GetNumShapeshiftForms()) + 1)
	end

	local function Cols_UpdateValue(self, value)
		bar:Layout(GetNumShapeshiftForms() - value + 1)
	end
	
	local function Cols_UpdateText(self, value)
		self.valText:SetText(GetNumShapeshiftForms() - value + 1)
	end
	panel:CreateSlider(L.Columns, 1, 1, 1, Cols_OnShow, Cols_UpdateValue, Cols_UpdateText)

	return menu
end

local function Bar_OnCreate(self)
	self.CreateMenu = Bar_CreateMenu
	self.Layout = Bar_Layout
	self.SetSpacing = Bar_SetSpacing
	self.GetSpacing = Bar_GetSpacing
end


--[[ Events ]]--

function ClassBar:Load()
	local bar, isNew = Bongos.Bar:Create('class')
	if isNew then
		Bar_OnCreate(bar)
	end
	self.bar = bar

	self:UpdateForms()
	self:RegisterEvent('UPDATE_SHAPESHIFT_FORMS', 'UpdateForms')
end

function ClassBar:Unload()
	self:UnregisterAllEvents()
	self.bar:Destroy()
end

function ClassBar:UpdateForms()
	for id = 1, GetNumShapeshiftForms() do
		local button = self.Button:Get(id) or self.Button:Create(id, self.bar)
		button:UpdateSpell()
		button:Show()
	end
	self.bar:Layout()
end