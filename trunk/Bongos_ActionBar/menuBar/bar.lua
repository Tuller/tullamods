--[[
	BMenuBar
		A movable bar for the micro buttons
--]]

BongosMenuBar = BongosActionMain:NewModule("Bongos-MenuBar")

local DEFAULT_SPACING = 2
local DEFAULT_ROWS = 1
local buttons = {
	CharacterMicroButton,
	SpellbookMicroButton,
	TalentMicroButton,
	QuestLogMicroButton,
	SocialsMicroButton,
	LFGMicroButton,
	MainMenuMicroButton,
	HelpMicroButton
}


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

	for _,button in pairs(buttons) do button:ClearAllPoints() end
	buttons[1]:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 20)

	local actSpace = space
	if rows == DEFAULT_ROWS then
		--horizontal layout
		space = space - 4 --apparently the anchors are weird on the micro buttons, and need to be adjusted
		for i = 2, #buttons do
			buttons[i]:SetPoint("LEFT", buttons[i-1], "RIGHT", space, 0)
		end

		self:SetHeight(39)
		self:SetWidth(14 + (24 + actSpace) * #buttons - actSpace)
	else
		--vertical layoute
		space = space - 24 --apparently the anchors are weird on the micro buttons, and need to be adjusted
		for i = 2, #buttons do
			buttons[i]:SetPoint("TOP", buttons[i-1], "BOTTOM", 0, -space)
		end

		self:SetHeight(12 + (33 + actSpace) * #buttons - actSpace)
		self:SetWidth(28)
	end
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
	menu.text:SetText("Menu Bar")

	local vertical = menu:CreateCheckButton(name .. "Vertical")
	vertical:SetScript("OnShow", function(self) self:SetChecked(frame.sets.rows) end)
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

	for _,button in pairs(buttons) do
		self:Attach(button)
	end

	--override UpdateTalentButton to properly show the micro button
	function UpdateTalentButton()
		if UnitLevel("player") < 10 then
			TalentMicroButton:Hide()
		elseif BBar.Get("menu") then
			TalentMicroButton:Show()
		end
	end
end


--[[ Startup ]]--

function BongosMenuBar:Load()
	local bar = BBar:Create("menu", Bar_OnCreate, nil, {["y"] = 39, ["x"] = 988})
	bar:Layout()

	--hack to make sure all the buttons are shown properly
	if bar:IsShown() then
		bar:Hide()
		bar:Show()
	end
	
	self.bar = bar
end

function BongosMenuBar:Unload()
	self.bar:Destroy()
end