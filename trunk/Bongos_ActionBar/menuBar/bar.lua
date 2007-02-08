--[[
	BMenuBar
		A movable bar for the micro buttons
--]]

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


--[[ Update Functions ]]--

local function Layout(self, rows, space)
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
	buttons[1]:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, 20)

	local actSpace = space
	if rows == DEFAULT_ROWS then
		--horizontal layout
		space = space - 4 --apparently the anchors are weird on the micro buttons, and need to be adjusted
		for i = 2, #buttons do
			buttons[i]:SetPoint('LEFT', buttons[i-1], 'RIGHT', space, 0)
		end

		self:SetHeight(39)
		self:SetWidth(14 + (24 + actSpace) * #buttons - actSpace)
	else
		--vertical layoute
		space = space - 24 --apparently the anchors are weird on the micro buttons, and need to be adjusted
		for i = 2, #buttons do
			buttons[i]:SetPoint('TOP', buttons[i-1], 'BOTTOM', 0, -space)
		end

		self:SetHeight(12 + (33 + actSpace) * #buttons - actSpace)
		self:SetWidth(28)
	end
end

local function SetVertical(self, enable)
	if enable then
		self:Layout(5)
	else
		self:Layout(1)
	end
end


--[[ Rightclick Menu Functions ]]--

local function CreateConfigMenu(name, frame)
	local menu = CreateFrame('Button', name, UIParent, "BongosRightClickMenu")
	menu.frame = frame

	menu:SetText('Menu Bar')
	menu:SetWidth(220); menu:SetHeight(200)

	--checkbuttons
	local vertical = CreateFrame("CheckButton", name .. "Vertical", menu, "GooeyCheckButton")
	vertical:SetScript("OnClick", function() SetVertical(frame, this:GetChecked()) end)
	vertical:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -28)
	vertical:SetText(BONGOS_VERTICAL)
	
	--sliders
	local opacity = CreateFrame("Slider", name .. "Opacity", menu, "BongosOpacitySlider")
	opacity:SetPoint("BOTTOM", menu, "BOTTOM", 0, 24)

	local scale = CreateFrame("Slider", name .. "Scale", menu, "BongosScaleSlider")
	scale:SetPoint("BOTTOM", opacity, "TOP", 0, 24)

	local spacing = CreateFrame("Slider", name .. "Spacing", menu, "BongosSpaceSlider")
	spacing:SetPoint("BOTTOM", scale, "TOP", 0, 24)
	spacing:SetScript("OnValueChanged", function()
		if not menu.onShow then
			frame:Layout(nil, this:GetValue())
		end
		getglobal(this:GetName() .. 'ValText'):SetText(this:GetValue())
	end)
	
	return menu
end

--Called when the right click menu is shown, loads the correct values to the checkbuttons/sliders/text
local function ShowMenu(self)
	local name = 'BongosMenuBarMenu'
	local menu = getglobal(name) or CreateConfigMenu(name, self)

	menu.onShow = 1

	getglobal(name .. 'Spacing'):SetValue(self.sets.space or DEFAULT_SPACING)
	getglobal(name .. 'Vertical'):SetChecked(self.sets.rows)

	self:DisplayMenu(menu)

	menu.onShow = nil
end


--[[ Startup ]]--

local function OnCreate(self)
	self.ShowMenu = ShowMenu
	self.Layout = Layout
	
	for _,button in pairs(buttons) do
		self:Attach(button)
	end
end

Bongos.AddStartup(function()
	if not Bongos.GetBarSets('menu') then
		Bongos.SetBarSets('menu', {x = 1242.857, y = 78, vis = 1})
	end

	local bar = BBar.Create('menu', OnCreate)
	bar:Layout()

	--hack to make sure all the buttons are shown properly
	if bar:IsShown() then bar:Hide(); bar:Show() end
end)

--[[ Overrides ]]--

--Prevents the talent button from always showing up even when the bar is hidden
UpdateTalentButton = function()
	if UnitLevel('player') < 10 then
		TalentMicroButton:Hide()
	elseif BBar.Get('menu') then
		TalentMicroButton:Show()
	end
end