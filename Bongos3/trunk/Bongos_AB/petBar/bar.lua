--[[
	BongosPetBar
		A replacement for the default pet actionbar
--]]


local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local PetBar = Bongos:NewModule('PetBar')
local Config = Bongos:GetModule('ActionBar-Config')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3-AB')
local DEFAULT_SPACING = 2


--[[ Bongos Bar Functions ]]--

local Bar = {}

function Bar:CreateMenu()
	local bar = self
	local menu = Bongos.Menu:Create(self.id)
	local panel = menu:AddLayoutPanel()

	panel:CreateSpacingSlider()

	local cols = panel:CreateSlider(L.Columns, 1, NUM_PET_ACTION_SLOTS, 1)
	cols.OnShow = function(self)
		self:SetValue(NUM_PET_ACTION_SLOTS - (bar.sets.cols or NUM_PET_ACTION_SLOTS) + 1)
	end
	cols.UpdateValue = function(self, value)
		bar:Layout(NUM_PET_ACTION_SLOTS - value + 1)
	end
	cols.UpdateText = function(self, value)
		self.valText:SetText(NUM_PET_ACTION_SLOTS - value + 1)
	end

	return menu
end

function Bar:Layout(cols, spacing)
	if InCombatLockdown() then return end

	local cols = (cols or self.sets.cols or NUM_PET_ACTION_SLOTS)
	if cols == NUM_PET_ACTION_SLOTS then
		self.sets.cols = nil
	else
		self.sets.cols = cols
	end

	local spacing = (spacing or self.sets.spacing or DEFAULT_SPACING)
	if spacing == DEFAULT_SPACING then
		self.sets.spacing = nil
	else
		self.sets.spacing = spacing
	end
	spacing = spacing + 2

	local w = PetBar.Button:Get(1):GetWidth() + spacing
	local h = PetBar.Button:Get(1):GetHeight() + spacing
	local buttonSize = 30 + spacing
	local offset = spacing / 2

	self:SetWidth(w * cols - spacing)
	self:SetHeight(h * ceil(NUM_PET_ACTION_SLOTS/cols) - spacing)

	for i = 1, NUM_PET_ACTION_SLOTS do
		local row = mod(i - 1, cols)
		local col = ceil(i / cols) - 1

		local button = PetBar.Button:Get(i)
		button:ClearAllPoints()
		button:SetPoint('TOPLEFT', self, 'TOPLEFT', w * row, -h * col)
	end
end

function Bar:SetSpacing(spacing)
	self:Layout(nil, spacing)
end

function Bar:GetSpacing()
	return self.sets.spacing or DEFAULT_SPACING
end

function Bar:UpdatePossessBar()
	self:UpdateStateDriver(not KeyBound:IsShown())
end

function Bar:IsPossessBar()
	return Config:IsPossessBar(self.id)
end

function Bar:UpdateStateDriver(enable)
	UnregisterStateDriver(self.header, 'visibility')

	if enable then
		if self:IsPossessBar() then
			RegisterStateDriver(self.header, 'visibility',  '[target=pet,nodead,exists]show;[bonusbar:5]show;hide')
		else
			RegisterStateDriver(self.header, 'visibility',  '[target=pet,nodead,exists,nobonusbar:5]show;hide')
		end
	end
end


--[[ Events ]]--

function PetBar:Load()
	local defaults = {
		point = 'BOTTOM',
		x = 0,
		y = 39,
	}

	local bar, isNew = Bongos.Bar:Create('pet', defaults)
	if isNew then
		self:OnCreate(bar)
	end
	bar:Layout()

	local petBar = PetActionBarFrame
	petBar:RegisterEvent("PLAYER_CONTROL_LOST")
	petBar:RegisterEvent("PLAYER_CONTROL_GAINED")
	petBar:RegisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED")
	petBar:RegisterEvent("UNIT_PET")
	petBar:RegisterEvent("UNIT_FLAGS")
	petBar:RegisterEvent("UNIT_AURA")
	petBar:RegisterEvent("PET_BAR_UPDATE")
	petBar:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
	petBar:RegisterEvent("PET_BAR_SHOWGRID")
	petBar:RegisterEvent("PET_BAR_HIDEGRID")
	petBar:RegisterEvent("PET_BAR_HIDE")

	local kb = LibStub('LibKeyBound-1.0')
	kb.RegisterCallback(self, 'LIBKEYBOUND_ENABLED', 'KEYBOUND_ENABLED')
	kb.RegisterCallback(self, 'LIBKEYBOUND_DISABLED', 'KEYBOUND_DISABLED')

	self.bar = bar
	self.bar:UpdateStateDriver(true)
end

function PetBar:Unload()
	self.bar:UpdateStateDriver(false)
	self.bar:Destroy()
	self:UnregisterAllMessages()

	PetActionBarFrame:UnregisterAllEvents()
end

--called when we first create our bongos bar
function PetBar:OnCreate(bar)
	--copy over all the functions from the Bar table
	for k,v in pairs(Bar) do
		bar[k] = v
	end

	--create the state header, which controls when the pet buttons are shown
	bar.header = CreateFrame('Frame', nil, bar, 'SecureStateHeaderTemplate')

	for i = 1, NUM_PET_ACTION_SLOTS do
		PetBar.Button:Set(i, bar.header)
	end
end

function PetBar:KEYBOUND_ENABLED()
	self.bar:UpdateStateDriver(false)
	self.bar.header:Show()

	for i = 1, NUM_PET_ACTION_SLOTS do
		local button = self.Button:Get(i)
		button:Show()
		button:UpdateHotkey()
	end
end

function PetBar:KEYBOUND_DISABLED()
	self.bar:UpdateStateDriver(true)

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