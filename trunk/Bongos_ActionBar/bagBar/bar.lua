--[[
	bar.lua
		Scripts used for the Bongos Bag bar
--]]

BongosBagBar = BongosActionMain:NewModule("Bongos-BagBar")
BongosBagBar.defaults = {x = 1261.85, y = 37, vis = 1}

--constants
local DEFAULT_SPACING = 4
local DEFAULT_ROWS = 1
local BAG_SIZE = 37
local bags = {CharacterBag3Slot, CharacterBag2Slot, CharacterBag1Slot, CharacterBag0Slot, MainMenuBarBackpackButton}

--[[ Bar Functions ]]--

local function Bar_Layout(self, rows, space)
	rows = (rows or self.sets.rows or DEFAULT_ROWS)
	if rows == DEFAULT_ROWS then
		self.sets.rows = nil
	else
		self.sets.rows = rows
	end
	space = (space or self.sets.space or DEFAULT_SPACING)

	if space == DEFAULT_SPACING then
		self.sets.space = nil
	else
		self.sets.space = space
	end

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
				bags[i]:SetPoint("LEFT", bags[i-1], "RIGHT", space, 0)
			end
			self:SetSize((BAG_SIZE + space) * #bags - space, (BAG_SIZE + space) - space)
		--vertical alignment
		else
			for i = 2, #bags do
				bags[i]:SetPoint("TOP", bags[i-1], "BOTTOM", 0, -space)
			end
			self:SetSize((BAG_SIZE + space) - space, (BAG_SIZE + space)*#bags - space)
		end
	end
end

local function Bar_SetOneBag(self, enable)
	if enable then
		self.sets.oneBag = 1
	else
		self.sets.oneBag = nil
	end
	self:Layout()
end

local function Bar_SetVertical(self, enable)
	if enable then
		self:Layout(5)
	else
		self:Layout(1)
	end
end

local function Bar_CreateMenu(frame)
	local name = format("BongosMenu%s", frame.id)
	local menu = BongosMenu:Create(name)
	menu.frame = frame
	menu.text:SetText("Bag Bar")

	--checkbuttons
	local oneBag = menu:CreateCheckButton(name .. "OneBag")
	oneBag:SetScript("OnShow", function(self) self:SetChecked(frame.sets.oneBag) end)
	oneBag:SetScript("OnClick", function(self) frame:SetOneBag(self:GetChecked()) end)
	oneBag:SetText("One Bag")

	local vertical = menu:CreateCheckButton(name .. "Vertical")
	oneBag:SetScript("OnShow", function(self) self:SetChecked(frame.sets.rows) end)
	vertical:SetScript("OnClick", function(self) frame:SetVertical(self:GetChecked()) end)
	vertical:SetText("Vertical")

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
	self.SetVertical = Bar_SetVertical
	self.SetOneBag = Bar_ShowAsOneBag

	for _,bag in pairs(bags) do
		self:Attach(bag)
	end
end


--[[ Startup ]]--

function BongosBagBar:Load()
	local bar = BBar:Create("bags", Bar_OnCreate, nil, self.defaults)
	bar:Layout()

	if bar:IsShown() then
		MainMenuBarBackpackButton:Show()
	end

	self.bar = bar
end

function BongosBagBar:Unload()
	self.bar:Destroy()
end