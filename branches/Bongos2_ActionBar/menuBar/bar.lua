--[[
	BMenuBar
		A movable bar for the micro buttons
--]]

BongosMenuBar = Bongos:NewModule("Bongos-MenuBar")
local L = BONGOS_LOCALS

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

local function Bar_SetSpacing(self, spacing)
	self:Layout(nil, spacing)
end

local function Bar_GetSpacing(self)
	return self.sets.spacing or DEFAULT_SPACING
end

local function Bar_Layout(self, rows, spacing)
	rows = (rows or self.sets.rows or DEFAULT_ROWS)
	if rows == DEFAULT_ROWS then
		self.sets.rows = nil
	else
		self.sets.rows = rows
	end

	spacing = (spacing or self.sets.spacing or DEFAULT_SPACING)
	if spacing == DEFAULT_SPACING then
		self.sets.spacing = nil
	else
		self.sets.spacing = spacing
	end

	for _,button in pairs(buttons) do button:ClearAllPoints() end
	buttons[1]:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 20)

	local actspacing = spacing
	if rows == DEFAULT_ROWS then
		--horizontal layout
		spacing = spacing - 4 --apparently the anchors are weird on the micro buttons, and need to be adjusted
		for i = 2, #buttons do
			buttons[i]:SetPoint("LEFT", buttons[i-1], "RIGHT", spacing, 0)
		end

		self:SetHeight(39)
		self:SetWidth(14 + (24 + actspacing) * #buttons - actspacing)
	else
		--vertical layoute
		spacing = spacing - 24 --apparently the anchors are weird on the micro buttons, and need to be adjusted
		for i = 2, #buttons do
			buttons[i]:SetPoint("TOP", buttons[i-1], "BOTTOM", 0, -spacing)
		end

		self:SetHeight(12 + (33 + actspacing) * #buttons - actspacing)
		self:SetWidth(28)
	end
end

local function Bar_SetVertical(self, enable)
	self:Layout(enable and 5 or 1)
end

local function Bar_CreateMenu(frame)
	local menu,panel = BongosMenu:CreateMenu(frame.id)

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
	self.SetSpacing = Bar_SetSpacing
	self.GetSpacing = Bar_GetSpacing

	for _,button in pairs(buttons) do
		self:Attach(button)
	end

	--mess with the talent button to make it hide properly, it causes layout issues otherwise
	local function TalentButton_Update(self)
		if UnitLevel("player") < 10 then
			self:Hide()
		elseif BBar:Get("menu") then
			self:Show()
		end
	end

	TalentMicroButton:SetScript("OnEvent", function(self, event)
		if event == "PLAYER_LEVEL_UP" then
			TalentButton_Update(self)
			if not CharacterFrame:IsShown() then
				SetButtonPulse(self, 60, 1)
			end
		elseif event == "UNIT_LEVEL" or event == "PLAYER_ENTERING_WORLD" then
			TalentButton_Update(self)
		elseif event == "UPDATE_BINDINGS" then
			self.tooltipText =  MicroButtonTooltipText(TALENTS_BUTTON, "TOGGLETALENTS")
		end
	end)
end


--[[ Startup ]]--

function BongosMenuBar:Load()
	local bar = BBar:Create("menu", Bar_OnCreate, nil, {["y"] = 39, ["x"] = 988})
	bar:Layout()

	--hack to make sure all the buttons are shown properly
	if bar:IsShown() then bar:Hide(); bar:Show() end

	self.bar = bar
end

function BongosMenuBar:Unload()
	self.bar:Destroy()
end