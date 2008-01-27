--[[
	SageOptions.lua
		GUI config functions for Sage
--]]

local L = SAGE_LOCALS

SageOptions = CreateFrame("Frame", "SageOptions", UIParent)

function SageOptions:Load()
	--mother frame, used to hide and show the entire window
	self:SetMovable(true)
	self:SetClampedToScreen(true)
	self:SetFrameStrata("DIALOG")
	self:SetPoint("LEFT", UIParent)

	local menu = self:AddMenu()
	menu:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -12)

	local content = self:AddContentPane()
	content:SetPoint("TOPLEFT", menu, "TOPRIGHT", -6, 12)
	content:SetPoint("BOTTOMRIGHT", self)
end

function SageOptions:Toggle()
	if(self:IsShown()) then
		self:Hide()
	else
		self:Show()
	end
end

--background frame for all the panels
function SageOptions:AddContentPane()
	--content pane, where all the panels are anchored to
	local content = CreateFrame("Frame", self:GetName() .. "Panel", self, "GooeyFrame")
	content:SetFrameLevel(content:GetFrameLevel() + 1)
	content:SetScript("OnMouseDown", function(self) self:GetParent():StartMoving() end)
	content:SetScript("OnMouseUp", function(self) self:GetParent():StopMovingOrSizing() end)
	content:EnableMouse(true)
	self.content = content

	--title text
	local text = content:CreateFontString(nil, "OVERLAY")
	text:SetPoint("TOP", content, "TOP", 0, -10)
	text:SetFontObject("GameFontHighlightLarge")
	text:SetText("Sage Options")

	--close button
	local close = CreateFrame("Button", nil, content, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", content, "TOPRIGHT", -2, -2)
	close:SetScript("OnClick", function() HideUIPanel(self) end)

	self.content = content
	return content
end


--[[ Tabbed Menu ]]--

local function MenuItem_OnClick(self)
	self:GetParent():GetParent():ShowPanel(self:GetText())
end

local function Menu_AddItem(self, name)
	local button = CreateFrame("Button", self:GetName() .. name, self)
	button:SetWidth(52); button:SetHeight(24)
	button:SetScript("OnClick", MenuItem_OnClick)

	button:SetTextFontObject("GameFontNormalSmall")
	button:SetHighlightTextColor(1, 1, 1)
	button:SetText(name)

	if not self.button then
		button:SetPoint("TOP", self, "TOP", 0, -2)
		self:SetHeight(self:GetHeight() + 30)
	else
		button:SetPoint("TOP", self.button, "BOTTOM")
		self:SetHeight(self:GetHeight() + 24)
	end
	self.button = button
end

function SageOptions:AddMenu()
	local menu = CreateFrame("Frame", self:GetName() .. "Menu", self, "GooeyFrame")
	menu:SetWidth(64)
	menu.AddItem = Menu_AddItem

	self.menu = menu
	return menu
end

function SageOptions:ShowPanel(name)
	local menuName = self.menu:GetName()
	for index, panel in pairs(self.panels) do
		if(index == name) then
			if(not panel:IsShown()) then
				UIFrameFadeIn(panel, 0.2)
				getglobal(menuName .. index):LockHighlight()
				self:SetWidth(self.menu:GetWidth() + panel.width)
				self:SetHeight(max(panel.height, self.menu:GetHeight() + 32))
			end
		elseif(panel:IsShown()) then
			panel:Hide()
			getglobal(menuName .. index):UnlockHighlight()
		end
	end
end


--[[  Panels ]]--

local Panel = CreateFrame("Frame")
local Panel_MT = {__index = Panel}

function SageOptions:AddPanel(name, unit)
	local content = self.content
	local panel = setmetatable(CreateFrame("Frame", content:GetName() .. name, content), Panel_MT)
	panel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -28)
	panel:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT")
	panel:Hide()

	panel.width = 216
	panel.height = 38

	if(not self.panels) then self.panels = {} end
	self.panels[name] = panel
	self.menu:AddItem(name)

	if(unit) then
		panel:AddUnitOptions(unit)
	end

	return panel
end

function Panel:AddUnitOptions(unit)
	self.unit = unit

	self:AddCombatTextButton()
	self:AddShowCastableButton()
	self:AddShowCurableButton()
	self:AddTextDisplaySelector()
	self:AddWidthSlider()
	self:AddAlphaSlider()
	self:AddScaleSlider()
end

--[[ Checkbuttons ]]--

--checkbutton
function Panel:AddCheckButton(name, OnClick, OnShow)
	local button = CreateFrame("CheckButton", self:GetName() .. name, self, "GooeyCheckButton")
	if(self.button) then
		button:SetPoint("TOPLEFT", self.button, "BOTTOMLEFT", 0, 2)
	else
		button:SetPoint("TOPLEFT", self, "TOPLEFT", 6, 0)
	end
	button:SetText(name)
	button:SetScript("OnClick", OnClick)
	button:SetScript("OnShow", OnShow)

	self.height = self.height + 30
	self.button = button

	return button
end

--show combat text
local function ShowCombatText_OnClick(self)
	Sage:SetShowCombatText(self:GetParent().unit, self:GetChecked())
end
local function ShowCombatText_OnShow(self)
	self:SetChecked(Sage:ShowingCombatText(self:GetParent().unit))
end

function Panel:AddCombatTextButton()
	return self:AddCheckButton(L.ShowCombatText, ShowCombatText_OnClick, ShowCombatText_OnShow)
end

--show curable debuffs
local function ShowCurable_OnClick(self)
	Sage:SetShowCurable(self:GetParent().unit, self:GetChecked())
end
local function ShowCurable_OnShow(self)
	self:SetChecked(Sage:ShowingCurable(self:GetParent().unit))
end

function Panel:AddShowCurableButton()
	return self:AddCheckButton(L.ShowCurable, ShowCurable_OnClick, ShowCurable_OnShow)
end

--show castable buffs
local function ShowCastable_OnClick(self)
	Sage:SetShowCastable(self:GetParent().unit, self:GetChecked())
end
local function ShowCastable_OnShow(self)
	self:SetChecked(Sage:ShowingCastable(self:GetParent().unit))
end

function Panel:AddShowCastableButton()
	return self:AddCheckButton(L.ShowCastable, ShowCastable_OnClick, ShowCastable_OnShow)
end


--[[ Sliders ]]--

--slider
local function Slider_OnMouseWheel(self, direction)
	local step = self:GetValueStep() * direction
	local value = self:GetValue()
	local minVal, maxVal = self:GetMinMaxValues()

	if(step > 0) then
		self:SetValue(min(value+step, maxVal))
	else
		self:SetValue(max(value+step, minVal))
	end
end

function Panel:AddSlider(name, min, max, step)
	local slider = CreateFrame("Slider", self:GetName() .. name, self, "GooeySlider")
	slider:SetWidth(200); slider:SetHeight(18)
	slider:SetMinMaxValues(min, max)
	slider:SetValueStep(step)
	slider:EnableMouseWheel(true)
	slider:SetScript("OnMouseWheel", Slider_OnMouseWheel)

	getglobal(slider:GetName() .. "Text"):SetText(name)
	getglobal(slider:GetName() .. "Low"):SetText(min)
	getglobal(slider:GetName() .. "High"):SetText(max)

	if(self.slider) then
		slider:SetPoint("BOTTOM", self.slider, "TOP", 0, 24)
	else
		slider:SetPoint("BOTTOM", self, "BOTTOM", 0, 24)
	end
	self.height = self.height + 43
	self.slider = slider

	return slider
end

--width slider
local function WidthSlider_OnShow(self)
	self.onShow = true
	self:SetValue(Sage:GetWidth(self:GetParent().unit))
	self.onShow = nil
end

local function WidthSlider_OnValueChanged(self, value)
	if not self.onShow then
		Sage:SetWidth(self:GetParent().unit, value)
	end
	getglobal(self:GetName() .. "ValText"):SetText(value)
end

function Panel:AddWidthSlider()
	local slider = self:AddSlider(L.Width, 0, 300, 5)
	slider:SetScript("OnShow", WidthSlider_OnShow)
	slider:SetScript("OnValueChanged", WidthSlider_OnValueChanged)

	return slider
end

--scale slider
local function ScaleSlider_OnShow(self)
	self.onShow = true
	self:SetValue(Sage:GetScale(self:GetParent().unit) * 100)
	self.onShow = nil
end

local function ScaleSlider_OnValueChanged(self, value)
	if not self.onShow then
		Sage:SetScale(self:GetParent().unit, value/100)
	end
	getglobal(self:GetName() .. "ValText"):SetText(value)
end

function Panel:AddScaleSlider()
	local slider = self:AddSlider(L.Scale, 50, 150, 1, true)
	slider:SetScript("OnShow", ScaleSlider_OnShow)
	slider:SetScript("OnValueChanged", ScaleSlider_OnValueChanged)

	return slider
end

--opacity slider
local function AlphaSlider_OnShow(self)
	self.onShow = true
	self:SetValue(Sage:GetOpacity(self:GetParent().unit) * 100)
	self.onShow = nil
end

local function AlphaSlider_OnValueChanged(self, value)
	if not self.onShow then
		Sage:SetOpacity(self:GetParent().unit, value/100)
	end
	getglobal(self:GetName() .. "ValText"):SetText(value)
end

function Panel:AddAlphaSlider()
	local slider = self:AddSlider(L.Opacity, 0, 100, 1)
	slider:SetScript("OnShow", AlphaSlider_OnShow)
	slider:SetScript("OnValueChanged", AlphaSlider_OnValueChanged)

	return slider
end


--[[ Selector ]]--

function Panel:AddSelector(name, vals, OnClick, OnShow)
	local fname = self:GetName() .. name
	local selector = CreateFrame("Frame", fname, self, "GooeyComponent")
	selector:SetHeight(26)
	selector.vals = vals
	selector:SetScript("OnShow", OnShow)

	local left = CreateFrame("Button", fname .. "Left", selector)
	left:SetWidth(20); left:SetHeight(20)
	left:SetNormalTexture("Interface\\MoneyFrame\\Arrow-Left-Up")
	left:SetPushedTexture("Interface\\MoneyFrame\\Arrow-Left-Down")
	left:SetPoint("LEFT", selector, "LEFT", 0, -1)
	left:SetScript("OnClick", function() OnClick(selector, true) end)
	selector.left = left

	local text = selector:CreateFontString()
	text:SetFontObject("GameFontHighlight")
	text:SetPoint("CENTER", selector, 0, 1)
	text:SetWidth(98 - 48); text:SetHeight(24)
	selector.text = text

	local right = CreateFrame("Button", fname .. "Right", selector)
	right:SetWidth(20); right:SetHeight(20)
	right:SetNormalTexture("Interface\\MoneyFrame\\Arrow-Right-Up")
	right:SetPushedTexture("Interface\\MoneyFrame\\Arrow-Right-Down")
	right:SetPoint("RIGHT", selector, "RIGHT", 4, -1)
	right:SetScript("OnClick", function() OnClick(selector) end)
	selector.right = right

	local title = selector:CreateFontString()
	title:SetFontObject("GameFontNormalSmall")
	title:SetPoint("LEFT", selector, "RIGHT")
	title:SetText(name)

	if(self.button) then
		selector:SetPoint("TOPLEFT", self.button, "BOTTOMLEFT", 0, 2)
	else
		selector:SetPoint("TOPLEFT", self, "TOPLEFT", 6, 0)
	end
	self.height = self.height + 30
	self.button = button

	selector:SetWidth(text:GetWidth() + 40)

	return selector
end

--text display selector
local modes = {L.TextNormal, L.TextSmart, L.TextFull}
local function TextMode_OnClick(self, reverse)
	if(reverse) then
		self.value = (self.value or 1) - 1
		if(self.value <= 0) then
			self.value = #self.vals
		end
	else
		self.value = (self.value or 1) + 1
		if(self.value > #self.vals) then
			self.value = 1
		end
	end
	self.text:SetText(self.vals[self.value])
	Sage:SetTextMode(self:GetParent().unit, self.value)
end

local function TextMode_OnShow(self)
	self.value = Sage:GetTextMode(self:GetParent().unit)
	self.text:SetText(self.vals[self.value])
end

function Panel:AddTextDisplaySelector()
	return self:AddSelector(L.TextDisplay, modes, TextMode_OnClick, TextMode_OnShow)
end

SageOptions:Load()