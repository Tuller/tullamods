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
		button:Update()
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
	self:SetAttribute("statemap-pet", "$input")
	RegisterStateDriver(self, "pet", "[target=pet,nomounted,exists,nodead]1;0")

	for i=1, NUM_PET_ACTION_SLOTS do BongosPetButton:Set(i, self) end

	if(UnitExists("pet") and not(IsMounted() or UnitIsDead("pet"))) then
		self:SetAttribute("state", "1")
	else
		self:SetAttribute("state", "0")
	end
	SecureStateHeader_Refresh(self)
end


--[[ Events ]]--

function BongosPetBar:Load()
	self.bar = BBar:CreateHeader("pet", Bar_OnCreate, nil, {["y"] = 591, ["x"] = 553}, "HIGH")
	self.bar:Layout()

	self:RegisterEvent("UNIT_FLAGS", "UpdateIfPet")
	self:RegisterEvent("UNIT_AURA", "UpdateIfPet")
	self:RegisterEvent("PET_BAR_UPDATE", "UpdatePetBar")
	self:RegisterEvent("PET_BAR_UPDATE_COOLDOWN", "UpdateCooldown")
	self:RegisterEvent("PET_BAR_SHOWGRID", "UpdateShowGrid")
	self:RegisterEvent("PET_BAR_HIDEGRID", "UpdateShowGrid")
	self:RegisterEvent("UPDATE_BINDINGS", "UpdateBindings")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateCombat")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "UpdateCombat")

	self:RegisterMessage("KEYBOUND_ENABLED", "UpdateVisibility")
	self:RegisterMessage("KEYBOUND_DISABLED", "UpdateVisibility")
end

function BongosPetBar:Unload()
	self.bar:Destroy()
	self:UnregisterAllEvents()
	self:UnregisterAllMessages()
end

function BongosPetBar:UpdateBindings()
	BongosPetButton:ForAll("UpdateHotkey")
end

function BongosPetBar:UpdateIfPet(event, unit)
	if unit == "pet" then
		BongosPetButton:ForAll("Update")
	end
end

function BongosPetBar:UpdatePetBar()
	BongosPetButton:ForAll("Update")
	self:UpdateVisibility()
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
	self:UpdateVisibility()
end

function BongosPetBar:UpdateVisibility()
	if(self.inCombat) then
		self.needsUpdate = true
	else
		self.needsUpdate = nil
		BongosPetButton:ForAll("UpdateVisibility")
		SecureStateHeader_Refresh(self.bar)
	end
end

function BongosPetBar:UpdateCombat(event)
	if(event == "PLAYER_REGEN_ENABLED") then
		self.inCombat = nil
		if(self.needsUpdate) then
			self:UpdateVisibility()
		end
	elseif(event == "PLAYER_REGEN_DISABLED") then
		self.inCombat = true
	end
end