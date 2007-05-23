--[[
	BongosMenu.lua
		GUI config functions for Bongos
--]]

local L = BONGOS_LOCALS

BongosMenu = CreateFrame("Button")
local Button_MT = {__index = BongosMenu}

local function Menu_OnClick(self)
	self:Hide()
end

local function Menu_OnShow(self)
	if(not self.panels) then
		self:SetWidth(self.width)
		self:SetHeight(self.height)
	end
end

function BongosMenu:Create(name, tabbed)
	local menu = setmetatable(CreateFrame("Button", name, UIParent, "GooeyPopup"), Button_MT)
	self.width = 210; self.height = 38

	menu:RegisterForClicks("AnyUp")
	menu:SetScript("OnShow", Menu_OnShow)
	menu:SetScript("OnClick", Menu_OnClick)

	menu.text = menu:CreateFontString(nil, "OVERLAY")
	menu.text:SetPoint("TOP", menu, "TOP", 0, -10)
	menu.text:SetFontObject("GameFontHighlightLarge")

	local close = CreateFrame("Button", nil, menu, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -2, -2)

	local panel = nil
	if(tabbed) then
		panel = menu:AddPanel(L.Layout)
		panel:CreateAlphaSlider(name .. "Opacity")
		panel:CreateScaleSlider(name .. "Scale")
	else
		menu:CreateAlphaSlider(name .. "Opacity")
		menu:CreateScaleSlider(name .. "Scale")
	end

	return menu, panel
end

function BongosMenu:SetFrame(frame)
	if(self.panels) then
		for _,panel in pairs(self.panels) do
			panel.frame = frame
		end
	end
	self.frame = frame
end

--[[ Tabbed Menu ]]--

local function MenuItem_OnClick(self)
	local menu = self:GetParent():GetParent()
	menu:ShowPanel(self:GetText())
end

local function TabbedMenu_AddItem(self, name)
	local button = CreateFrame("Button", self:GetName() .. name, self)
	button:SetWidth(48)
	button:SetHeight(20)
	button:SetScript("OnClick", MenuItem_OnClick)

	button:SetTextFontObject("GameFontNormalSmall")
	button:SetText(name)
	button:SetHighlightTextColor(1, 1, 1)

	if not self.button then
		button:SetPoint("TOPLEFT", self, "TOPLEFT", 2, -2)
		self:SetHeight(self:GetHeight() + 26)
	else
		button:SetPoint("TOPLEFT", self.button, "BOTTOMLEFT", 0, 0)
		self:SetHeight(self:GetHeight() + 20)
	end
	self.button = button
end

function BongosMenu:AddMenu()
	local menu = CreateFrame("Frame", self:GetName() .. "Menu", self, "GooeyFrame")
	menu:SetWidth(52)
	menu.AddItem = TabbedMenu_AddItem
	menu:SetPoint("TOPRIGHT", self, "TOPLEFT", 6, -16)
	
	self.menu = menu
	return menu
end

--[[ Panel Functions ]]--

local function Panel_OnShow(self)
	local parent = self:GetParent()
	parent:SetWidth(self.width)
	parent:SetHeight(self.height)
end

function BongosMenu:AddPanel(name)
	local panel = setmetatable(CreateFrame("Frame", self:GetName() .. "Panel" .. name, self), Button_MT)
	panel:SetScript("OnShow", Panel_OnShow)
	panel:SetAllPoints(self)
	panel:Hide()

	panel.width = 210
	panel.height = 38

	if(not self.panels) then 
		self.panels = {} 
		self:AddMenu()
	end
	self.panels[name] = panel
	self.menu:AddItem(name)
	
	return panel
end

function BongosMenu:ShowPanel(name)
	local menuName = self.menu:GetName()
	for index, panel in pairs(self.panels) do
		if(index == name) then
			panel:Show()
			getglobal(menuName .. index):LockHighlight()
		else
			panel:Hide()
			getglobal(menuName .. index):UnlockHighlight()
		end
	end
end


--[[ General Slider ]]--

function BongosMenu:CreateSlider(name)
	local slider = CreateFrame("Slider", name, self, "GooeySlider")
	slider:SetWidth(200)
	slider:SetHeight(18)

	if(self.slider) then
		slider:SetPoint("BOTTOM", self.slider, "TOP", 0, 24)
	else
		slider:SetPoint("BOTTOM", self, "BOTTOM", 0, 24)
	end
	self.height = self.height + 43
	self.slider = slider

	return slider
end


--[[ Scale Slider ]]--

local function ScaleSlider_OnShow(self)
	self:SetValue(self:GetParent().frame:GetScale() * 100)
end

local function ScaleSlider_OnValueChanged(self, value)
	local parent = self:GetParent()
	if not parent.onShow then
		parent.frame:SetFrameScale(value / 100)
	end
	getglobal(self:GetName() .. "ValText"):SetText(value)
end

function BongosMenu:CreateScaleSlider(name)
	local slider = self:CreateSlider(name)
	slider:SetMinMaxValues(50, 150)
	slider:SetValueStep(1)

	getglobal(name .. "Text"):SetText(L.Scale)
	getglobal(name .. "Low"):SetText("50")
	getglobal(name .. "High"):SetText("150")

	slider:SetScript("OnShow", ScaleSlider_OnShow)
	slider:SetScript("OnValueChanged", ScaleSlider_OnValueChanged)

	return slider
end


--[[ Alpha Slider ]]--

local function AlphaSlider_OnShow(self)
	local alpha = self:GetParent().frame:GetFrameAlpha()
	self:SetValue(alpha * 100)
end

local function AlphaSlider_OnValueChanged(self, value)
	local parent = self:GetParent()
	if not parent.onShow then
		parent.frame:SetFrameAlpha(value / 100)
	end
	getglobal(self:GetName() .. "ValText"):SetText(value)
end

function BongosMenu:CreateAlphaSlider(name)
	local slider = self:CreateSlider(name)
	slider:SetMinMaxValues(0, 100)
	slider:SetValueStep(1)

	getglobal(name .. "Text"):SetText(L.Opacity)
	getglobal(name .. "Low"):SetText("0")
	getglobal(name .. "High"):SetText("100")

	slider:SetScript("OnShow", AlphaSlider_OnShow)
	slider:SetScript("OnValueChanged", AlphaSlider_OnValueChanged)

	return slider
end

--fading
-- local function FadeSlider_OnShow(self)
	-- local alpha = select(2, self:GetParent().frame:GetFrameAlpha())
	-- self:SetValue(alpha * 100)
-- end

-- local function FadeSlider_OnValueChanged(self, value)
	-- local parent = self:GetParent()
	-- if not parent.onShow then
		-- parent.frame:SetFadeALpha(value / 100)
	-- end
	-- getglobal(self:GetName() .. "ValText"):SetText(value)
-- end

-- function BongosMenu:CreateFadeSlider(name)
	-- local slider = self:CreateAlphaSlider(name)
	-- getglobal(name .. "Text"):SetText("Faded Opacity")
	-- slider:SetScript("OnShow", FadeSlider_OnShow)
	-- slider:SetScript("OnValueChanged", FadeSlider_OnValueChanged)

	-- return slider
-- end

--spacing
function BongosMenu:CreateSpacingSlider(name)
	local slider = self:CreateSlider(name)
	slider:SetMinMaxValues(0, 32)
	slider:SetValueStep(1)

	getglobal(name .. "Text"):SetText(L.Spacing)
	getglobal(name .. "Low"):SetText("0")
	getglobal(name .. "High"):SetText("32")
	
	return slider
end


--[[ General Checkbutton ]]--

function BongosMenu:CreateCheckButton(name)
	local button = CreateFrame("CheckButton", name, self, "GooeyCheckButton")
	if(self.button) then
		button:SetPoint("TOP", self.button, "BOTTOM", 0, 2)
	else
		button:SetPoint("TOPLEFT", self, "TOPLEFT", 6, -28)
	end
	self.height = self.height + 30
	self.button = button

	return button
end

--fade when in combat
-- local function FadeInCombat_OnClick(self)
	-- if self:GetChecked() then
		-- self:GetParent().frame:SetFadeMode(1)
	-- else
		-- self:GetParent().frame:SetFadeMode(0)
	-- end

	-- local unfade = getglobal(self:GetParent():GetName() .. "FadeOutCombat")
	-- unfade:SetChecked(false)
-- end

-- local function FadeInCombat_OnShow(self)
	-- self:SetChecked(self:GetParent().frame.sets.fadeMode == 1)
-- end

-- function BongosMenu:CreateFadeInCombatButton(name)
	-- local button = self:CreateCheckButton(name)
	-- button:SetScript("OnClick", FadeInCombat_OnClick)
	-- button:SetScript("OnShow", FadeInCombat_OnShow)
	-- button:SetText("Fade In Combat")

	-- return button
-- end

--fade out of combat
-- local function FadeOutCombat_OnClick(self)
	-- if self:GetChecked() then
		-- self:GetParent().frame:SetFadeMode(2)
	-- else
		-- self:GetParent().frame:SetFadeMode(0)
	-- end

	-- local fade = getglobal(self:GetParent():GetName() .. "FadeInCombat")
	-- fade:SetChecked(false)
-- end

-- local function FadeOutCombat_OnShow(self)
	-- self:SetChecked(self:GetParent().frame.sets.fadeMode == 2)
-- end

-- function BongosMenu:CreateFadeOutCombatButton(name)
	-- local button = self:CreateCheckButton(name)
	-- button:SetScript("OnShow", FadeOutCombat_OnShow)
	-- button:SetScript("OnClick", FadeOutCombat_OnClick)
	-- button:SetText("Fade Out Of Combat")

	-- return button
-- end