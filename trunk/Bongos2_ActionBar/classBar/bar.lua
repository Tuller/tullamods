--[[
	BongosClassBar
		A replacement for the Blizzard shapeshift bar
--]]

local class = BONGOS_CLASS
if not(class == "DRUID" or class == "ROGUE" or class == "WARRIOR" or class == "PALADIN" or class == "HUNTER") then
	return
end

BongosClassBar = Bongos:NewModule("Bongos-ClassBar")
local L = BONGOS_LOCALS
local DEFAULT_SPACING = 2


--[[ Bar ]]--

local function Bar_SetSpacing(self, spacing)
	self:Layout(nil, spacing)
end

local function Bar_GetSpacing(self)
	return self.sets.spacing or DEFAULT_SPACING
end

local function Bar_Layout(self, cols, space)
	if InCombatLockdown() then return end

	local numForms = GetNumShapeshiftForms()

	cols = (cols or self.sets.cols or numForms)
	self.sets.cols = (cols ~= numForms and cols) or nil

	space = (space or self.sets.space or DEFAULT_SPACING)
	self.sets.space = (space ~= DEFAULT_SPACING and space) or nil

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
	local menu,panel = BongosMenu:CreateMenu(frame.id)

	--sliders
	panel:AddSpacingSlider()

	local cols = panel:AddSlider(L.Columns, 1, 1, 1)
	cols:SetScript("OnShow", function(self)
		self.onShow = true
		self:SetMinMaxValues(1, GetNumShapeshiftForms())
		self:SetValue(GetNumShapeshiftForms() - (frame.sets.cols or GetNumShapeshiftForms()) + 1)
		getglobal(self:GetName() .. "Low"):SetText(GetNumShapeshiftForms())
		self.onShow = nil
	end)
	cols:SetScript("OnValueChanged", function(self, value)
		if not self.onShow then
			frame:Layout(GetNumShapeshiftForms() - value + 1)
		end
		getglobal(self:GetName() .. "ValText"):SetText(GetNumShapeshiftForms() - value + 1)
	end)

	return menu
end

local function Bar_OnCreate(self)
	self.CreateMenu = Bar_CreateMenu
	self.Layout = Bar_Layout
	self.SetSpacing = Bar_SetSpacing
	self.GetSpacing = Bar_GetSpacing
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

	self.bar = BBar:Create("class", Bar_OnCreate, nil, {["y"] = 651, ["x"] = 703})
	BongosClassButton:ForAll("ShowHotkey", BongosActionConfig:ShowingHotkeys())
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