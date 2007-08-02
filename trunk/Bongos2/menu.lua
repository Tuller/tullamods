--[[
	BongosMenu.lua
		GUI config functions for Sage
--]]

local L = BONGOS_LOCALS
L.Show = "Show"
L.FadedOpacity = "Faded Opacity"

BongosMenu = CreateFrame("Frame", nil, UIParent)
local Frame_MT = {__index = BongosMenu}

function BongosMenu:CreateMenu(name, tabbed)
	local frame = setmetatable(CreateFrame("Frame", "BongosBarMenu" .. name, UIParent, not(tabbed) and "GooeyComponent"), Frame_MT)

	--mother frame, used to hide and show the entire window
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata("DIALOG")

	if(tabbed) then
		local menu = frame:AddPanelMenu()
		menu:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -12)
		frame.menu = menu
	end
	frame.content = frame:AddContentPane()

	local panel = frame:AddPanel(L.Layout)
--	panel:AddVisibilityButton()
	panel:AddAlphaSlider()
	panel:AddFadeSlider()
	panel:AddScaleSlider()

	return frame, panel
end

function BongosMenu:SetFrameID(id)
	if(self.panels) then
		for _,frame in pairs(self.panels) do
			frame.id = id
		end
	end

	if tonumber(id) then
		self.text:SetText(format("ActionBar %s", id))
	else
		self.text:SetText(format("%s Bar", id:gsub("^%l", string.upper)))
	end
end

--background frame for all the panels
function BongosMenu:AddContentPane()
	--content pane, where all the panels are anchored to
	local content
	if(self.menu) then
		content = CreateFrame("Frame", self:GetName() .. "Panel", self, "GooeyComponent")
		content:SetFrameLevel(content:GetFrameLevel() + 1)
		content:SetPoint("TOPLEFT", self.menu, "TOPRIGHT", -6, 12)
		content:SetPoint("BOTTOMRIGHT", self)
	else
		content = self
	end
	content:SetScript("OnMouseDown", function() self:StartMoving() end)
	content:SetScript("OnMouseUp", function() self:StopMovingOrSizing() end)
	content:EnableMouse(true)

	--title text
	local text = content:CreateFontString(nil, "OVERLAY")
	text:SetPoint("TOP", content, "TOP", 0, -10)
	text:SetFontObject("GameFontHighlightLarge")
	self.text = text

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

function BongosMenu:AddPanelMenu()
	local menu = CreateFrame("Frame", self:GetName() .. "Menu", self, "GooeyComponent")
	menu:SetWidth(64)
	menu:SetClampedToScreen(true)
	menu.AddItem = Menu_AddItem

	self.menu = menu
	return menu
end

function BongosMenu:ShowPanel(name)
	local menuName = self.menu:GetName()
	for index, panel in pairs(self.panels) do
		if(index == name) then
			if(not panel:IsShown()) then
				getglobal(menuName .. index):LockHighlight()
				panel:Show()
				if(self.menu) then
					self:SetWidth(self.menu:GetWidth() + panel.width)
					self:SetHeight(panel.height)
					-- self:SetHeight(max(panel.height, self.menu:GetHeight() + 32))
				else
					self:SetWidth(panel.width)
					self:SetHeight(panel.height)
				end
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

local function Panel_OnShow(self)
	local parent = self:GetParent()
	parent:SetWidth(self.width); parent:SetHeight(self.height)
end

function BongosMenu:AddPanel(name)
	local content = self.content
	local panel = setmetatable(CreateFrame("Frame", content:GetName() .. name, content), Panel_MT)
	panel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -28)
	panel:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT")
	if(not self.menu) then
		panel:SetScript("OnShow", Panel_OnShow)
	end

	panel.width = 216
	panel.height = 38

	if(not self.panels) then self.panels = {} end
	self.panels[name] = panel

	if(self.menu) then
		self.menu:AddItem(name)
		panel:Hide()
	end

	return panel
end


--[[ Checkbuttons ]]--

--checkbutton
function Panel:AddCheckButton(name)
	local button = CreateFrame("CheckButton", self:GetName() .. name, self, "GooeyCheckButton")
	if(self.button) then
		button:SetPoint("TOPLEFT", self.button, "BOTTOMLEFT", 0, 2)
	else
		button:SetPoint("TOPLEFT", self, "TOPLEFT", 6, 0)
	end
	button:SetText(name)

	self.height = self.height + 30
	self.button = button

	return button
end

local function Visibility_OnShow(self)
	self:SetChecked(BBar:Get(self:GetParent().id):FrameIsShown())
end

local function Visibility_OnClick(self)
	if(self:GetChecked()) then
		BBar:Get(self:GetParent().id):ShowFrame()
	else
		BBar:Get(self:GetParent().id):HideFrame()
	end
end

function Panel:AddVisibilityButton()
	local button = self:AddCheckButton(L.Show)
	button:SetScript("OnShow", Visibility_OnShow)
	button:SetScript("OnClick", Visibility_OnClick)

	return button
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

--scale slider
local function ScaleSlider_OnShow(self)
	self.onShow = true
	local id = self:GetParent().id
	self:SetValue(BBar:Get(id):GetScale() * 100)
	self.onShow = nil
end

local function ScaleSlider_OnValueChanged(self, value)
	if not self.onShow then
		local id = self:GetParent().id
		BBar:Get(id):SetFrameScale(value/100)
	end
	getglobal(self:GetName() .. "ValText"):SetText(value)
end

function Panel:AddScaleSlider()
	local slider = self:AddSlider(L.Scale, 50, 150, 1)
	slider:SetScript("OnShow", ScaleSlider_OnShow)
	slider:SetScript("OnValueChanged", ScaleSlider_OnValueChanged)

	return slider
end

--opacity slider
local function AlphaSlider_OnShow(self)
	self.onShow = true
	local id = self:GetParent().id
	self:SetValue(BBar:Get(id):GetFrameAlpha() * 100)
	self.onShow = nil
end

local function AlphaSlider_OnValueChanged(self, value)
	if not self.onShow then
		local id = self:GetParent().id
		BBar:Get(id):SetFrameAlpha(value/100)
	end
	getglobal(self:GetName() .. "ValText"):SetText(value)
end

function Panel:AddAlphaSlider()
	local slider = self:AddSlider(L.Opacity, 0, 100, 1)
	slider:SetScript("OnShow", AlphaSlider_OnShow)
	slider:SetScript("OnValueChanged", AlphaSlider_OnValueChanged)

	return slider
end

--faded opacity slider
local function FadeSlider_OnShow(self)
	self.onShow = true
	local id = self:GetParent().id
	self:SetValue(BBar:Get(id):GetFadeAlpha() * 100)
	self.onShow = nil
end

local function FadeSlider_OnValueChanged(self, value)
	if not self.onShow then
		local id = self:GetParent().id
		BBar:Get(id):SetFadeAlpha(value/100)
	end
	getglobal(self:GetName() .. "ValText"):SetText(value)
end

function Panel:AddFadeSlider()
	local slider = self:AddSlider(L.FadedOpacity, 0, 100, 1)
	slider:SetScript("OnShow", FadeSlider_OnShow)
	slider:SetScript("OnValueChanged", FadeSlider_OnValueChanged)

	return slider
end

--spacing slider
local function SpaceSlider_OnShow(self)
	self.onShow = true
	local frame = BBar:Get(self:GetParent().id)
	self:SetValue(frame:GetSpacing())
	self.onShow = nil
end

local function SpaceSlider_OnValueChanged(self, value)
	if not self.onShow then
		BBar:Get(self:GetParent().id):SetSpacing(value)
	end
	getglobal(self:GetName() .. "ValText"):SetText(value)
end

function Panel:AddSpacingSlider(defaultSpacing)
	local slider = self:AddSlider(L.Spacing, -8, 32, 1)
	slider.defaultSpacing = defaultSpacing or 0
	slider:SetScript("OnShow", SpaceSlider_OnShow)
	slider:SetScript("OnValueChanged", SpaceSlider_OnValueChanged)

	return slider
end