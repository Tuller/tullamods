--[[
	BongosPetBar
		A replacement for the default pet actionbar
--]]

BongosPetBar = Bongos:NewModule("Bongos-PetBar")
local L = BONGOS_LOCALS

--[[ Bar Functions ]]--

local DEFAULT_SPACING = 2

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
	local name = format("BongosMenu%s", frame.id)
	local menu = BongosMenu:Create(name)
	menu.frame = frame
	menu.text:SetText(L.PetBar)

	--sliders
	local spacing = menu:CreateSpacingSlider(name .. "Spacing")
	spacing:SetScript("OnShow", function(self)
		self.onShow = true
		self:SetValue(frame.sets.space or DEFAULT_SPACING)
	end)
	spacing:SetScript("OnValueChanged", function(self, value)
		if not menu.onShow then
			frame:Layout(nil, value)
		end
		getglobal(self:GetName() .. "ValText"):SetText(value)
	end)

	local cols = menu:CreateSlider(name .. "Cols")
	cols:SetScript("OnShow", function(self)
		getglobal(name .. "Cols"):SetValue(NUM_PET_ACTION_SLOTS - (frame.sets.cols or NUM_PET_ACTION_SLOTS) + 1)
	end)
	cols:SetScript("OnValueChanged", function(self, value)
		if not menu.onShow then
			frame:Layout(NUM_PET_ACTION_SLOTS - value + 1)
		end
		getglobal(self:GetName() .. "ValText"):SetText(NUM_PET_ACTION_SLOTS - value + 1)
	end)
	cols:SetValueStep(1)
	getglobal(name .. "ColsText"):SetText(L.Columns)
	getglobal(name .. "Cols"):SetMinMaxValues(1, NUM_PET_ACTION_SLOTS)
	getglobal(name .. "ColsHigh"):SetText(1)
	getglobal(name .. "ColsLow"):SetText(NUM_PET_ACTION_SLOTS)

	return menu
end

local function Bar_ShowMenu(self)
	if not self.menu then
		self.menu = Bar_CreateMenu(self)
	end

	local menu = self.menu
	menu.onShow = true
	self:PlaceMenu(menu)
	menu.onShow = nil
end

local function Bar_OnCreate(self)
	self.ShowMenu = Bar_ShowMenu
	self.Layout = Bar_Layout
	self:SetFrameStrata("HIGH")

	for i = 1, NUM_PET_ACTION_SLOTS do
		BongosPetButton:Set(i, self)
	end
end


--[[ Events ]]--

function BongosPetBar:Load()
	self.bar = BBar:Create("pet", Bar_OnCreate, nil, {["y"] = 591, ["x"] = 553})
	self.bar:Layout()

	PetActionBarFrame:RegisterEvent("PLAYER_CONTROL_LOST")
	PetActionBarFrame:RegisterEvent("PLAYER_CONTROL_GAINED")
	PetActionBarFrame:RegisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED")
	PetActionBarFrame:RegisterEvent("UNIT_PET")
	PetActionBarFrame:RegisterEvent("UNIT_FLAGS")
	PetActionBarFrame:RegisterEvent("UNIT_AURA")
	PetActionBarFrame:RegisterEvent("PET_BAR_UPDATE")
	PetActionBarFrame:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
	PetActionBarFrame:RegisterEvent("PET_BAR_SHOWGRID")
	PetActionBarFrame:RegisterEvent("PET_BAR_HIDEGRID")
end

function BongosPetBar:Unload()
	self.bar:Destroy()
	PetActionBarFrame:UnregisterAllEvents()
end