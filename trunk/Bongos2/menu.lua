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
	menu:SetWidth(220)
	menu:SetHeight(130)

	menu:RegisterForClicks('AnyUp')
	menu:SetScript('OnClick', Menu_OnClick)

	menu.text = menu:CreateFontString(nil, 'OVERLAY')
	menu.text:SetPoint('TOP', menu, 'TOP', 0, -10)
	menu.text:SetFontObject('GameFontHighlightLarge')

	local close = CreateFrame('Button', nil, menu, 'UIPanelCloseButton')
	close:SetPoint('TOPRIGHT', menu, 'TOPRIGHT', -2, -2)

	local opacity = self:CreateAlphaSlider(menu, name .. 'Opacity')
	opacity:SetPoint('BOTTOM', menu, 'BOTTOM', 0, 24)

	local scale = self:CreateScaleSlider(menu, name .. 'Scale')
	scale:SetPoint('BOTTOM', opacity, 'TOP', 0, 24)

	return menu
end


--[[ General Slider ]]--

function BongosMenu:CreateSlider(parent, name)
	local slider = CreateFrame('Slider', name, parent, 'GooeySlider')
	slider:SetWidth(200); slider:SetHeight(18)

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
	self:SetValue(self:GetParent().frame:GetAlpha() * 100)
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


--[[ General Checkbutton ]]--

function BongosMenu:CreateCheckButton(parent, name)
	return CreateFrame('CheckButton', name, parent, 'GooeyCheckButton')
end