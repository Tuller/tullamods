--[[
	BongosClassBar
		A replacement for the Blizzard shapeshift bar
--]]

local class = select(2, UnitClass("player"))
if not(class == "DRUID" or class == "ROGUE" or class == "WARRIOR" or class == "PALADIN" or class == "HUNTER") then
	return
end

BongosClassBar = Bongos:NewModule("Bongos-ClassBar")

--constants
local DEFAULT_SPACING = 2


--[[ Bar ]]--

local function Bar_Layout(self, cols, space)
	if InCombatLockdown() then return end

	local numForms = GetNumShapeshiftForms()

	cols = (cols or self.sets.cols or numForms)
	if cols == numForms then
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

	local buttonSize = 30 + space
	local offset = space / 2

	self:SetSize(buttonSize * cols - space, buttonSize * ceil(numForms/cols) - space)

	for i = 1, numForms do
		local row = mod(i-1, cols)
		local col = ceil(i / cols) - 1
		BongosClassButton:Get(i):SetPoint("TOPLEFT", self, "TOPLEFT", buttonSize * row, -buttonSize * col)
	end
end

local function Bar_CreateMenu(frame)
	local name = format("BongosMenu%s", frame.id)
	local menu = BongosMenu:Create(name)
	menu.frame = frame
	menu.text:SetText("Class Bar")

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
		getglobal(name .. "Cols"):SetMinMaxValues(1, GetNumShapeshiftForms())
		getglobal(name .. "ColsLow"):SetText(GetNumShapeshiftForms())
		getglobal(name .. "Cols"):SetValue(GetNumShapeshiftForms() - (frame.sets.cols or GetNumShapeshiftForms()) + 1)
	end)
	cols:SetScript("OnValueChanged", function(self, value)
		if not menu.onShow then
			frame:Layout(GetNumShapeshiftForms() - value + 1)
		end
		getglobal(self:GetName() .. "ValText"):SetText(GetNumShapeshiftForms() - value + 1)
	end)
	cols:SetValueStep(1)
	getglobal(name .. "ColsText"):SetText("Columns")
	getglobal(name .. "ColsHigh"):SetText(1)

	return menu
end

local function Bar_ShowMenu(self)
	if not self.menu then
		self.menu = Bar_CreateMenu(self)
	end

	local menu = self.menu
	menu.onShow = 1
	self:PlaceMenu(menu)
	menu.onShow = nil
end

local function Bar_OnCreate(self)
	self.ShowMenu = Bar_ShowMenu
	self.Layout = Bar_Layout
end


--[[ Events ]]--

function BongosClassBar:Load()
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS", "UpdateAll")
	self:RegisterEvent("ACTIONBAR_UPDATE_USABLE", "UpdateAll")
	self:RegisterEvent("UPDATE_INVENTORY_ALERTS", "UpdateAll")
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN", "UpdateAll")
	self:RegisterEvent("SPELL_UPDATE_USABLE", "UpdateAll")
	self:RegisterEvent("PLAYER_AURAS_CHANGED", "UpdateAll")
	self:RegisterEvent("ACTIONBAR_PAGE_CHANGED", "UpdateAll")
	self:RegisterEvent("UNIT_HEALTH", "UpdateAll")
	self:RegisterEvent("UNIT_RAGE", "UpdateAll")
	self:RegisterEvent("UNIT_FOCUS", "UpdateAll")
	self:RegisterEvent("UNIT_ENERGY", "UpdateAll")
	self:RegisterEvent("UPDATE_BINDINGS", "UpdateBindings")

	self.bar = BBar:CreateSecure("class", Bar_OnCreate, nil, {["y"] = 651, ["x"] = 703})
end

function BongosClassBar:Unload()
	self:UnregisterAllEvents()
	self.bar:Destroy()
end

function BongosClassBar:UpdateBindings()
	BongosClassButton:ForAll("UpdateHotkey")
end

function BongosClassBar:UpdateAll()
	local layoutChanged = nil

	for i = 1, GetNumShapeshiftForms() do
		local button = BongosClassButton:Get(i)
		if not button then
			button = BongosClassButton:Create(i, self.bar)
			layoutChanged = true
		else
			button:Update()
		end
	end

	if layoutChanged then
		self.bar:Layout()
	end
end