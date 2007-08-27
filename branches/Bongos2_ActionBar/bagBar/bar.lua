--[[
	bar.lua
		Scripts used for the Bongos Bag bar
--]]

BongosBagBar = Bongos:NewModule("Bongos-BagBar")

local L = BONGOS_LOCALS

--constants
local DEFAULT_SPACING, DEFAULT_ROWS = 4, 1
local BAG_SIZE = 37
local bags = {CharacterBag3Slot, CharacterBag2Slot, CharacterBag1Slot, CharacterBag0Slot, MainMenuBarBackpackButton}


--[[ Bar Functions ]]--

local function Bar_SetSpacing(self, spacing)
	self:Layout(nil, spacing)
end

local function Bar_GetSpacing(self)
	return self.sets.spacing or DEFAULT_SPACING
end

local function Bar_Layout(self, rows, spacing)
	rows = (rows or self.sets.rows or DEFAULT_ROWS)
	self.sets.rows = (rows ~= DEFAULT_ROWS and rows) or nil

	spacing = (spacing or self.sets.spacing or DEFAULT_SPACING)
	self.sets.spacing = (spacing ~= DEFAULT_SPACING and spacing) or nil

	for _,bag in pairs(bags) do bag:ClearAllPoints() end

	if self.sets.oneBag then
		for i = 1, #bags-1 do bags[i]:Hide() end
		bags[#bags]:SetPoint("TOPLEFT", self)

		self:SetWidth(BAG_SIZE); self:SetHeight(BAG_SIZE)
	else
		for _,bag in pairs(bags) do bag:Show() end
		bags[1]:SetPoint("TOPLEFT", self)

		--horizontal alignment
		if rows == 1 then
			for i = 2, #bags do
				bags[i]:SetPoint("LEFT", bags[i-1], "RIGHT", spacing, 0)
			end
			self:SetSize((BAG_SIZE + spacing) * #bags - spacing, (BAG_SIZE + spacing) - spacing)
		--vertical alignment
		else
			for i = 2, #bags do
				bags[i]:SetPoint("TOP", bags[i-1], "BOTTOM", 0, -spacing)
			end
			self:SetSize((BAG_SIZE + spacing) - spacing, (BAG_SIZE + spacing)*#bags - spacing)
		end
	end
end

local function Bar_SetOneBag(self, enable)
	self.sets.oneBag = enable or nil
	self:Layout()
end

local function Bar_SetVertical(self, enable)
	self:Layout(enable and 5 or 1)
end

local function Bar_CreateMenu(frame)
	local menu,panel = BongosMenu:CreateMenu(frame.id)

	local oneBag = panel:AddCheckButton(L.OneBag)
	oneBag:SetScript("OnShow", function(self) self:SetChecked(frame.sets.oneBag) end)
	oneBag:SetScript("OnClick", function(self) frame:SetOneBag(self:GetChecked()) end)

	local vertical = panel:AddCheckButton(L.Vertical)
	vertical:SetScript("OnShow", function(self) self:SetChecked(frame.sets.rows) end)
	vertical:SetScript("OnClick", function(self) frame:SetVertical(self:GetChecked()) end)

	panel:AddSpacingSlider()

	return menu
end

local function Bar_OnCreate(self)
	self.CreateMenu = Bar_CreateMenu
	self.Layout = Bar_Layout
	self.SetVertical = Bar_SetVertical
	self.SetOneBag = Bar_SetOneBag
	self.SetSpacing = Bar_SetSpacing
	self.GetSpacing = Bar_GetSpacing

	for _,bag in pairs(bags) do
		self:Attach(bag)
	end

	--hack to prevent some random issue with the backpack
	MainMenuBarBackpackButton:Show()
end


--[[ Startup ]]--

function BongosBagBar:Load()
	local bar = BBar:Create("bags", Bar_OnCreate, nil, {["y"] = 37, ["x"] = 1241})
	bar:Layout()

	self.bar = bar
end

function BongosBagBar:Unload()
	self.bar:Destroy()
end