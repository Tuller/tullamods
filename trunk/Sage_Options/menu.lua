--[[
	SageOptions.lua
		GUI config functions for Bongos
--]]

SageOptions = CreateFrame("Frame", "SageOptions", UIParent)
local L = SAGE_LOCALS
L.General = "General"
L.Profiles = "Profiles"
L.SetLock = "Lock Frame Positions"
L.SetSticky = "Enable Sticky Frames"
L.EnterName = "Enter Profile Name"
L.OutlineBarText = "Outline Statusbar Text"
L.OutlineOutside = "Outline Outside Text"
L.HealthBarDebuffColoring = "Color Health When Debuffed"
L.ShowHealthPercents = "Show Health Percents"
L.ShowStatusBarText = "Show Statusbar Text"
L.ShowCastBars = "Show Casting Bars"

function SageOptions:Load()
	--mother frame, used to hide and show the entire window
	self:SetMovable(true)
	self:SetClampedToScreen(true)
	self:SetFrameStrata("DIALOG")
	self:SetPoint("LEFT", UIParent)

	local menu = self:AddMenu()
	menu:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -12)

	local content = self:AddContentPane()
	content:SetFrameLevel(content:GetFrameLevel() + 1)
	content:SetPoint("TOPLEFT", menu, "TOPRIGHT", -6, 12)
	content:SetPoint("BOTTOMRIGHT", self)

	self:AddGeneralPanel()
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

--general options
function SageOptions:AddGeneralPanel()
	local panel = self:AddPanel(L.General)

	local function Lock_OnShow(self) self:SetChecked(Sage:IsLocked()) end
	local function Lock_OnClick(self) Sage:SetLock(self:GetChecked()) end
	panel:AddCheckButton(L.SetLock, Lock_OnClick, Lock_OnShow)

	local function Sticky_OnShow(self) self:SetChecked(Sage:IsSticky()) end
	local function Sticky_OnClick(self) Sage:SetSticky(self:GetChecked()) end
	panel:AddCheckButton(L.SetSticky, Sticky_OnClick, Sticky_OnShow)
	
	local function OutlineBar_OnShow(self) self:SetChecked(Sage:OutlineBarFonts()) end
	local function OutlineBar_OnClick(self) Sage:SetOutlineBarFonts(self:GetChecked()) end
	panel:AddCheckButton(L.OutlineBarText, OutlineBar_OnClick, OutlineBar_OnShow)
	
	local function OutlineOut_OnShow(self) self:SetChecked(Sage:OutlineOutsideFonts()) end
	local function OutlineOut_OnClick(self) Sage:SetOutlineOutsideFonts(self:GetChecked()) end
	panel:AddCheckButton(L.OutlineOutside, OutlineOut_OnClick, OutlineOut_OnShow)
	
	local function DebuffColoring_OnShow(self) self:SetChecked(Sage:DebuffColoring()) end
	local function DebuffColoring_OnClick(self) Sage:SetDebuffColoring(self:GetChecked()) end
	panel:AddCheckButton(L.HealthBarDebuffColoring, DebuffColoring_OnClick, DebuffColoring_OnShow)
	
	local function Percents_OnShow(self) self:SetChecked(Sage:ShowingPercents()) end
	local function Percents_OnClick(self) Sage:SetShowPercents(self:GetChecked()) end
	panel:AddCheckButton(L.ShowHealthPercents, Percents_OnClick, Percents_OnShow)
	
	local function Text_OnShow(self) self:SetChecked(Sage:ShowingText()) end
	local function Text_OnClick(self) Sage:SetShowText(self:GetChecked()) end
	panel:AddCheckButton(L.ShowStatusBarText, Text_OnClick, Text_OnShow)
	
	local function CastBars_OnShow(self) self:SetChecked(Sage:ShowingCastBars()) end
	local function CastBars_OnClick(self) Sage:SetShowCastBars(self:GetChecked()) end
	panel:AddCheckButton(L.ShowCastBars, CastBars_OnClick, CastBars_OnShow)
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
				self:SetHeight(max(panel.height, self.menu:GetHeight() + 64))
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
		local function Lock_OnShow(self) self:SetChecked(Sage:IsLocked()) end
		local function Lock_OnClick(self) Sage:SetLock(self:GetChecked()) end
		panel:AddCheckButton(L.ShowCurable, Lock_OnClick, Lock_OnShow)
	end

	return panel
end

--slider
function Panel:AddSlider(name)
	local slider = CreateFrame("Slider", self:GetName() .. name, self, "GooeySlider")
	slider:SetWidth(200); slider:SetHeight(18)

	if(self.slider) then
		slider:SetPoint("BOTTOM", self.slider, "TOP", 0, 24)
	else
		slider:SetPoint("BOTTOM", self, "BOTTOM", 0, 24)
	end
	self.height = self.height + 43
	self.slider = slider

	return slider
end

--checkbutton
function Panel:AddCheckButton(name, OnClick, OnShow)
	local button = CreateFrame("CheckButton", self:GetName() .. name, self, "GooeyCheckButton")
	if(self.button) then
		button:SetPoint("TOP", self.button, "BOTTOM", 0, 2)
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

SageOptions:Load()