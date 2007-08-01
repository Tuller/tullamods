--[[
	BongosOptions.lua
		GUI config functions for Bongos
--]]

local L = BONGOS_LOCALS

BongosOptions = CreateFrame("Frame", "BongosOptions", UIParent)
BongosOptions:Hide()

function BongosOptions:Load()
	--mother frame, used to hide and show the entire window
	self:SetMovable(true)
	self:SetClampedToScreen(true)
	self:SetFrameStrata("DIALOG")
	self:SetPoint("RIGHT", UIParent)

	local menu = self:AddMenu()
	menu:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -12)

	local content = self:AddContentPane()
	content:SetPoint("TOPLEFT", menu, "TOPRIGHT", -6, 12)
	content:SetPoint("BOTTOMRIGHT", self)

	UIFrameFadeIn(self, 0.2)
end

function BongosOptions:Toggle()
	if(self:IsShown()) then
		self:Hide()
	else
		UIFrameFadeIn(self, 0.2)
	end
end

--background frame for all the panels
function BongosOptions:AddContentPane()
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
	text:SetText("Bongos Options")

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

function BongosOptions:AddMenu()
	local menu = CreateFrame("Frame", self:GetName() .. "Menu", self, "GooeyFrame")
	menu:SetWidth(64)
	menu.AddItem = Menu_AddItem

	self.menu = menu
	return menu
end

function BongosOptions:ShowPanel(name)
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

function BongosOptions:AddPanel(name, unit)
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

	return panel
end


--[[ Checkbutton ]]--

function Panel:CreateCheckButton(name, OnClick, OnShow)
	local button = CreateFrame("CheckButton", self:GetName() .. name, self, "GooeyCheckButton")
	button:SetText(name)
	button:SetScript("OnClick", OnClick)
	button:SetScript("OnShow", OnShow)

	return button
end

function Panel:AddCheckButton(name, OnClick, OnShow)
	local button = self:CreateCheckButton(name, OnClick, OnShow)
	if(self.button) then
		button:SetPoint("TOPLEFT", self.button, "BOTTOMLEFT", 0, 2)
	else
		button:SetPoint("TOPLEFT", self, "TOPLEFT", 6, 0)
	end
	self.height = self.height + 30
	self.button = button

	return button
end


--[[ Slider ]]--

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

function Panel:CreateSlider(name, min, max, step)
	local slider = CreateFrame("Slider", self:GetName() .. name, self, "GooeySlider")
	slider:SetWidth(200); slider:SetHeight(18)
	slider:SetMinMaxValues(min, max)
	slider:SetValueStep(step)
	slider:EnableMouseWheel(true)
	slider:SetScript("OnMouseWheel", Slider_OnMouseWheel)

	slider.title = getglobal(slider:GetName() .. "Text")
	slider.high = getglobal(slider:GetName() .. "High")
	slider.low = getglobal(slider:GetName() .. "Low")
	slider.text = getglobal(slider:GetName() .. "ValText")

	slider.title:SetText(name)
	slider.low:SetText(min); slider.high:SetText(max)

	return slider
end

function Panel:AddSlider(name, min, max, step)
	local slider = self:CreateSlider(name, min, max, step)
	if(self.slider) then
		slider:SetPoint("BOTTOM", self.slider, "TOP", 0, 24)
	else
		slider:SetPoint("BOTTOM", self, "BOTTOM", 0, 24)
	end
	self.height = self.height + 43
	self.slider = slider

	return slider
end


--[[ Selector ]]--

function Panel:CreateSelector(name, vals, OnClick, OnShow)
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

	selector:SetWidth(text:GetWidth() + 40)

	return selector
end

function Panel:AddSelector(name, vals, OnClick, OnShow)
	local selector = self:CreateSelector(name, vals, OnClick, OnShow)
	if(self.button) then
		selector:SetPoint("TOPLEFT", self.button, "BOTTOMLEFT", 0, 2)
	else
		selector:SetPoint("TOPLEFT", self, "TOPLEFT", 6, 0)
	end
	self.height = self.height + 30
	self.button = button

	return selector
end

--button
function Panel:CreateButton(name, width, height)
	local button = CreateFrame("Button", self:GetName() .. name, self, "GooeyButton")
	button:SetText(name)
	button:SetWidth(width); button:SetHeight(height or width)

	return button
end

BongosOptions:Load()