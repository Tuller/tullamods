--[[
	BongosPetBar
		A replacement for the default pet actionbar
--]]

BongosPetBar = BongosActionMain:NewModule("Bongos-PetBar")

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
		button:Update()
	end
end

local function Bar_CreateMenu(frame)
	local name = format("BongosMenu%s", frame.id)
	local menu = BongosMenu:Create(name)
	menu.frame = frame
	menu.text:SetText("Pet Bar")

	--sliders
	local spacing = menu:CreateSpacingSlider(name .. "Spacing")
	spacing:SetScript("OnShow", function(self)
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
	getglobal(name .. "ColsText"):SetText("Columns")
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
	self:SetAttribute("unit", "pet")
	self:SetAttribute("statemap-unitexists-true",  "1")
	self:SetAttribute("statemap-unitexists-false", "0")
	RegisterUnitWatch(self, true)

	for i=1, NUM_PET_ACTION_SLOTS do
		BongosPetButton:Set(i, self)
	end

	if(UnitExists("pet")) then
		SecureStateHeader_Refresh(self, "1")
	else
		SecureStateHeader_Refresh(self, "0")
	end
end


--[[ Events ]]--

function BongosPetBar:Load()
	self.bar = BBar:CreateSecure("pet", Bar_OnCreate, nil, {["y"] = 598.8, ["x"] = 579.75})
	self.bar:Layout()

	self:RegisterEvent("UNIT_FLAGS", "UpdateIfPet")
	self:RegisterEvent("UNIT_AURA", "UpdateIfPet")
	self:RegisterEvent("PET_BAR_UPDATE", "Update")
	self:RegisterEvent("PET_BAR_UPDATE_COOLDOWN", "UpdateCooldown")
	self:RegisterEvent("PET_BAR_SHOWGRID", "UpdateShowGrid")
	self:RegisterEvent("PET_BAR_HIDEGRID", "UpdateShowGrid")
	self:RegisterEvent("UPDATE_BINDINGS", "UpdateBindings")
end

function BongosPetBar:Unload()
	self.bar:Destroy()

	self:UnregisterEvent("UNIT_FLAGS")
	self:UnregisterEvent("UNIT_AURA")
	self:UnregisterEvent("PET_BAR_UPDATE")
	self:UnregisterEvent("PET_BAR_UPDATE_COOLDOWN")
	self:UnregisterEvent("PET_BAR_SHOWGRID")
	self:UnregisterEvent("PET_BAR_HIDEGRID")
	self:UnregisterEvent("UPDATE_BINDINGS")
end

function BongosPetBar:UpdateBindings()
	BongosPetButton:ForAll("UpdateHotkey")
end

function BongosPetBar:UpdateIfPet(event, unit)
	if unit == "pet" then
		BongosPetButton:ForAll("Update")
	end
end

function BongosPetBar:Update()
	BongosPetButton:ForAll("Update")
end

function BongosPetBar:UpdateCooldown()
	BongosPetButton:ForAll("UpdateCooldown")
end

function BongosPetBar:UpdateShowGrid(event)
	if event == "PET_BAR_SHOWGRID" then
		BongosPetButton.showEmpty = true
	elseif event == "PET_BAR_HIDEGRID" then
		BongosPetButton.showEmpty = nil
	end
	BongosPetButton:ForAll("UpdateVisibility")
end