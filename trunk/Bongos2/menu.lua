--[[
	BongosMenu.lua
		GUI config functions for Bongos
--]]

local L = BONGOS_LOCALS

BongosMenu = {}

local function Menu_OnClick(self)
	self:Hide()
end

function BongosMenu:Create(name)
	local menu = CreateFrame('Button', name, UIParent, 'GooeyPopup')
	menu:SetWidth(210)
	menu:SetHeight(230)

	menu:RegisterForClicks('AnyUp')
	menu:SetScript('OnClick', Menu_OnClick)

	menu.text = menu:CreateFontString(nil, 'OVERLAY')
	menu.text:SetPoint('TOP', menu, 'TOP', 0, -10)
	menu.text:SetFontObject('GameFontHighlightLarge')

	local close = CreateFrame('Button', nil, menu, 'UIPanelCloseButton')
	close:SetPoint('TOPRIGHT', menu, 'TOPRIGHT', -2, -2)

	local fadeInCombat = BongosMenu:CreateFadeInCombatButton(menu, name .. 'FadeInCombat')
	fadeInCombat:SetPoint('TOPLEFT', menu, 'TOPLEFT', 6, -28)

	local fadeOutCombat = BongosMenu:CreateFadeOutCombatButton(menu, name .. 'FadeOutCombat')
	fadeOutCombat:SetPoint('TOP', fadeInCombat, 'BOTTOM', 0, 2)

	local fade = self:CreateFadeSlider(menu, name .. 'FadeOpacity')
	fade:SetPoint('BOTTOM', menu, 'BOTTOM', 0, 24)

	local opacity = self:CreateAlphaSlider(menu, name .. 'Opacity')
	opacity:SetPoint('BOTTOM', fade, 'TOP', 0, 24)

	local scale = self:CreateScaleSlider(menu, name .. 'Scale')
	scale:SetPoint('BOTTOM', opacity, 'TOP', 0, 24)

	return menu
end


--[[ General Slider ]]--

local function Slider_OnValueChanged(self, value)
	local parent = self:GetParent()
	if not parent.onShow then
		self:OnValueChanged(value)
	end
	self:UpdateText(value)
end

local function Slider_OnShow(self)
	self:UpdateText()
end

function BongosMenu:CreateSlider(parent, name)
	local slider = CreateFrame('Slider', name, parent, 'GooeySlider')
	slider:SetWidth(200)
	slider:SetHeight(18)

	slider:SetScript("OnValueChanged", Slider_OnValueChanged)
	slider:SetScript("OnShow", Slider_OnShow)

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
	getglobal(self:GetName() .. 'ValText'):SetText(value)
end

function BongosMenu:CreateScaleSlider(parent, name)
	local slider = self:CreateSlider(parent, name)
	slider:SetMinMaxValues(50, 150)
	slider:SetValueStep(1)

	getglobal(name .. 'Text'):SetText(L.Scale)
	getglobal(name .. 'Low'):SetText('50')
	getglobal(name .. 'High'):SetText('150')

	slider:SetScript('OnShow', ScaleSlider_OnShow)
	slider:SetScript('OnValueChanged', ScaleSlider_OnValueChanged)

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
	getglobal(self:GetName() .. 'ValText'):SetText(value)
end

function BongosMenu:CreateAlphaSlider(parent, name)
	local slider = self:CreateSlider(parent, name)
	slider:SetMinMaxValues(0, 100)
	slider:SetValueStep(1)

	getglobal(name .. 'Text'):SetText(L.Opacity)
	getglobal(name .. 'Low'):SetText('0')
	getglobal(name .. 'High'):SetText('100')

	slider:SetScript('OnShow', AlphaSlider_OnShow)
	slider:SetScript('OnValueChanged', AlphaSlider_OnValueChanged)

	return slider
end

--fading
local function FadeSlider_OnShow(self)
	local alpha = select(2, self:GetParent().frame:GetFrameAlpha())
	self:SetValue(alpha * 100)
end

local function FadeSlider_OnValueChanged(self, value)
	local parent = self:GetParent()
	if not parent.onShow then
		parent.frame:SetFadeALpha(value / 100)
	end
	getglobal(self:GetName() .. 'ValText'):SetText(value)
end

function BongosMenu:CreateFadeSlider(parent, name)
	local slider = self:CreateAlphaSlider(parent, name)
	getglobal(name .. 'Text'):SetText("Faded Opacity")
	slider:SetScript('OnShow', FadeSlider_OnShow)
	slider:SetScript('OnValueChanged', FadeSlider_OnValueChanged)

	return slider
end

--spacing
function BongosMenu:CreateSpacingSlider(parent, name)
	local slider = self:CreateSlider(parent, name)
	slider:SetMinMaxValues(0, 32)
	slider:SetValueStep(1)

	getglobal(name .. 'Text'):SetText(L.Spacing)
	getglobal(name .. 'Low'):SetText('0')
	getglobal(name .. 'High'):SetText('32')
	
	return slider
end


--[[ General Checkbutton ]]--

function BongosMenu:CreateCheckButton(parent, name)
	return CreateFrame('CheckButton', name, parent, 'GooeyCheckButton')
end

--fade when in combat
local function FadeInCombat_OnClick(self)
	if self:GetChecked() then
		self:GetParent().frame:SetFadeMode(1)
	else
		self:GetParent().frame:SetFadeMode(0)
	end

	local unfade = getglobal(self:GetParent():GetName() .. 'FadeOutCombat')
	unfade:SetChecked(false)
end

local function FadeInCombat_OnShow(self)
	self:SetChecked(self:GetParent().frame.sets.fadeMode == 1)
end

function BongosMenu:CreateFadeInCombatButton(parent, name)
	local button = self:CreateCheckButton(parent, name)
	button:SetScript('OnClick', FadeInCombat_OnClick)
	button:SetScript('OnShow', FadeInCombat_OnShow)
	button:SetText("Fade In Combat")

	return button
end

--fade out of combat
local function FadeOutCombat_OnClick(self)
	if self:GetChecked() then
		self:GetParent().frame:SetFadeMode(2)
	else
		self:GetParent().frame:SetFadeMode(0)
	end

	local fade = getglobal(self:GetParent():GetName() .. 'FadeInCombat')
	fade:SetChecked(false)
end

local function FadeOutCombat_OnShow(self)
	self:SetChecked(self:GetParent().frame.sets.fadeMode == 2)
end

function BongosMenu:CreateFadeOutCombatButton(parent, name)
	local button = self:CreateCheckButton(parent, name)
	button:SetScript('OnShow', FadeOutCombat_OnShow)
	button:SetScript('OnClick', FadeOutCombat_OnClick)
	button:SetText("Fade Out Of Combat")

	return button
end