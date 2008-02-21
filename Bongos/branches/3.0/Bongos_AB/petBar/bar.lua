--[[
	BongosPetBar
		A replacement for the default pet actionbar
--]]


local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local PetBar = Bongos:NewModule('PetBar', 'AceEvent-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3-AB')
local DEFAULT_SPACING = 2


--[[ Bar Functions ]]--

local function Bar_SetSpacing(self, spacing)
	self:Layout(nil, spacing)
end

local function Bar_GetSpacing(self)
	return self.sets.spacing or DEFAULT_SPACING
end

local function Bar_Layout(self, cols, spacing)
	if InCombatLockdown() then return end

	cols = (cols or self.sets.cols or NUM_PET_ACTION_SLOTS)
	if cols == NUM_PET_ACTION_SLOTS then
		self.sets.cols = nil
	else
		self.sets.cols = cols
	end

	spacing = (spacing or self.sets.spacing or DEFAULT_SPACING)
	if spacing == DEFAULT_SPACING then
		self.sets.spacing = nil
	else
		self.sets.spacing = spacing
	end
	spacing = spacing + 2

	local buttonSize = 30 + spacing
	local offset = spacing / 2

	self:SetWidth(buttonSize * cols - spacing)
	self:SetHeight(buttonSize * ceil(NUM_PET_ACTION_SLOTS/cols) - spacing)

	for i = 1, NUM_PET_ACTION_SLOTS do
		local row = mod(i - 1, cols)
		local col = ceil(i / cols) - 1

		local button = PetBar.Button:Get(i)
		button:ClearAllPoints()
		button:SetPoint('TOPLEFT', self, 'TOPLEFT', buttonSize * row, -buttonSize * col)
	end
end

local function Bar_CreateMenu(bar)
	local menu = Bongos.Menu:Create(bar.id)
	local panel = menu:AddLayoutPanel()

	panel:CreateSpacingSlider()
	
	local function Cols_OnShow(self)
		self:SetValue(NUM_PET_ACTION_SLOTS - (bar.sets.cols or NUM_PET_ACTION_SLOTS) + 1)
	end
	
	local function Cols_UpdateValue(self, value)
		bar:Layout(NUM_PET_ACTION_SLOTS - value + 1)
	end
	
	local function Cols_UpdateText(self, value)
		self.valText:SetText(NUM_PET_ACTION_SLOTS - value + 1)
	end
	panel:CreateSlider(L.Columns, 1, NUM_PET_ACTION_SLOTS, 1, Cols_OnShow, Cols_UpdateValue, Cols_UpdateText)

	return menu
end

local function Bar_OnCreate(self)
	self.CreateMenu = Bar_CreateMenu
	self.Layout = Bar_Layout
	self.SetSpacing = Bar_SetSpacing
	self.GetSpacing = Bar_GetSpacing

	for i = 1, NUM_PET_ACTION_SLOTS do
		PetBar.Button:Set(i, self)
	end
end


--[[ Events ]]--

function PetBar:Load()
	local defaults = {
		point = 'BOTTOM',
		x = 0,
		y = 39,
	}
	
	local bar, isNew = Bongos.Bar:Create('pet', defaults, true)
	if isNew then
		Bar_OnCreate(bar)
	end
	bar:Layout()

	local petBar = PetActionBarFrame
	petBar:RegisterEvent('PLAYER_CONTROL_LOST')
	petBar:RegisterEvent('PLAYER_CONTROL_GAINED')
	petBar:RegisterEvent('PLAYER_FARSIGHT_FOCUS_CHANGED')
	petBar:RegisterEvent('UNIT_PET')
	petBar:RegisterEvent('UNIT_FLAGS')
	petBar:RegisterEvent('UNIT_AURA')
	petBar:RegisterEvent('PET_BAR_UPDATE')
	petBar:RegisterEvent('PET_BAR_UPDATE_COOLDOWN')
	petBar:RegisterEvent('PET_BAR_SHOWGRID')
	petBar:RegisterEvent('PET_BAR_HIDEGRID')
	RegisterStateDriver(petBar, 'visibility', '[pet]show;hide') 

	self:RegisterMessage('KEYBOUND_ENABLED')
	self:RegisterMessage('KEYBOUND_DISABLED')
	
	self.bar = bar
end

function PetBar:Unload()
	self.bar:Destroy()
	self:UnregisterAllMessages()
	PetActionBarFrame:UnregisterAllEvents()

	UnregisterStateDriver(PetActionBarFrame, 'visibility') 
end

function PetBar:KEYBOUND_ENABLED()
	for i = 1, NUM_PET_ACTION_SLOTS do
		local button = self.Button:Get(i)
		button:Show()
		button:UpdateHotkey()
	end
end

function PetBar:KEYBOUND_DISABLED()
	local petBarShown = PetHasActionBar()

	for i = 1, NUM_PET_ACTION_SLOTS do
		local button = self.Button:Get(i)
		if petBarShown and GetPetActionInfo(i) then
			button:Show()
		else
			button:Hide()
		end
	end
end