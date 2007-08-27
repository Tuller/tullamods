--[[
	BongosPetBar
		A replacement for the default pet actionbar
--]]

BongosPetBar = Bongos:NewModule("Bongos-PetBar")
local L = BONGOS_LOCALS
local DEFAULT_SPACING = 2


--[[ Bar Functions ]]--

local function Bar_SetSpacing(self, spacing)
	self:Layout(nil, spacing)
end

local function Bar_GetSpacing(self)
	return self.sets.spacing or DEFAULT_SPACING
end

local function Bar_Layout(self, cols, space)
	if InCombatLockdown() then return end

	cols = (cols or self.sets.cols or NUM_PET_ACTION_SLOTS)
	if cols == NUM_PET_ACTION_SLOTS then
		self.sets.cols = nil
	else
		self.sets.cols = cols
	end

	space = (space or self.sets.space or DEFAULT_SPACING)
	if space == DEFAULT_SPACING then
		self.sets.space = nil
	else
		self.sets.space = space
	end
	space = space + 2

	local buttonSize = 30 + space
	local offset = space / 2

	self:SetSize(buttonSize * cols - space, buttonSize * ceil(NUM_PET_ACTION_SLOTS/cols) - space)

	for i = 1, NUM_PET_ACTION_SLOTS do
		local row = mod(i - 1, cols)
		local col = ceil(i / cols) - 1

		local button = BongosPetButton:Get(i)
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", self, "TOPLEFT", buttonSize * row, -buttonSize * col)
	end
end

local function Bar_CreateMenu(frame)
	local menu,panel = BongosMenu:CreateMenu(frame.id)

	panel:AddSpacingSlider()

	local cols = panel:AddSlider(L.Columns, 1, NUM_PET_ACTION_SLOTS, 1)
	cols:SetScript("OnShow", function(self)
		self.onShow = true
		self:SetValue(NUM_PET_ACTION_SLOTS - (frame.sets.cols or NUM_PET_ACTION_SLOTS) + 1)
		self.onShow = nil
	end)
	cols:SetScript("OnValueChanged", function(self, value)
		if not self.onShow then
			frame:Layout(NUM_PET_ACTION_SLOTS - value + 1)
		end
		getglobal(self:GetName() .. "ValText"):SetText(NUM_PET_ACTION_SLOTS - value + 1)
	end)
	getglobal(cols:GetName() .. "High"):SetText(1)
	getglobal(cols:GetName() .. "Low"):SetText(NUM_PET_ACTION_SLOTS)

	return menu
end

local function Bar_OnCreate(self)
	self.CreateMenu = Bar_CreateMenu
	self.Layout = Bar_Layout
	self.SetSpacing = Bar_SetSpacing
	self.GetSpacing = Bar_GetSpacing

	for i = 1, NUM_PET_ACTION_SLOTS do
		BongosPetButton:Set(i, self)
	end
end


--[[ Events ]]--

function BongosPetBar:Load()
	self.bar = BBar:CreateHeader("pet", Bar_OnCreate, nil, {["y"] = 591, ["x"] = 553})
	self.bar:Layout()

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
	
	self:RegisterMessage("KEYBOUND_ENABLED")
	self:RegisterMessage("KEYBOUND_DISABLED")
end

function BongosPetBar:Unload()
	self.bar:Destroy()
	self:UnregisterAllMessages()
	PetActionBarFrame:UnregisterAllEvents()
end

function BongosPetBar:KEYBOUND_ENABLED()
	for i = 1, NUM_PET_ACTION_SLOTS do
		local button = BongosPetButton:Get(i)
		button:Show()
		button:UpdateHotkey()
	end
end

function BongosPetBar:KEYBOUND_DISABLED()
	local petBarShown = PetHasActionBar()
	for i = 1, NUM_PET_ACTION_SLOTS do
		local button = BongosPetButton:Get(i)
		if(petBarShown and GetPetActionInfo(i)) then
			button:Show()
		else
			button:Hide()
		end
	end
end