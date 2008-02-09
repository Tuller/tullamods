--[[
	BongosMenu.lua
		GUI config functions for Sage
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
Bongos.Menu = Bongos:CreateWidgetClass('Frame')

local BongosMenu = Bongos.Menu
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3')


BongosMenu.bg = {
	bgFile = 'Interface/DialogFrame/UI-DialogBox-Background',
	edgeFile = 'Interface/DialogFrame/UI-DialogBox-Border',
	insets = {11, 12, 12, 11},
	tile = true,
	tileSize = 32,
	edgeSize = 32,
}

BongosMenu.extraWidth = 0
BongosMenu.extraHeight = 0

function BongosMenu:Create(name)
	local f = self:New(CreateFrame('Frame', 'Bongos3BarMenu' .. name, UIParent))
	f.panels = {}

	f:SetBackdrop(self.bg)
	f:SetBackdropColor(1, 1, 1, 0.8)
	f:EnableMouse(true)
	f:SetToplevel(true)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:SetFrameStrata('DIALOG')
	f:SetScript('OnMouseDown', self.StartMoving)
	f:SetScript('OnMouseUp', self.StopMovingOrSizing)

	--title text
	f.text = f:CreateFontString(nil, 'OVERLAY')
	f.text:SetPoint('TOP', 0, -15)
	f.text:SetFontObject('GameFontHighlight')

	--close button
	f.close = CreateFrame('Button', nil, f, 'UIPanelCloseButton')
	f.close:SetPoint('TOPRIGHT', -5, -5)

	return f
end

--tells the panel what frame we're pointed to
function BongosMenu:SetFrameID(id)
	for _,frame in pairs(self.panels) do
		frame.id = id
	end

	if tonumber(id) then
		self.text:SetText(format('ActionBar %s', id))
	else
		self.text:SetText(format('%s Bar', id:gsub('^%l', string.upper)))
	end
end

--shows a given panel
function BongosMenu:ShowPanel(name)
	for index, panel in pairs(self.panels) do
		if index == name then
			self:SetWidth(panel:GetWidth() + self.extraWidth)
			self:SetHeight(panel:GetHeight() + self.extraHeight)
			panel:Show()
		else
			panel:Hide()
		end
	end
end

function BongosMenu:AddPanel(name)
	local panel = self.Panel:Create(name, self)
	self.panels[name] = panel

	return panel
end

function BongosMenu:AddLayoutPanel()
	local panel = self:AddPanel(L.Layout)

	self.opacity = panel:CreateOpacitySlider()
	self.opacity:SetPoint('BOTTOMLEFT', 16, 14)

	self.fade = panel:CreateFadeSlider()
	self.fade:SetPoint('BOTTOM', self.opacity, 'TOP', 0, 20)

	self.scale = panel:CreateScaleSlider()
	self.scale:SetPoint('BOTTOM', self.fade, 'TOP', 0, 20)

	panel:SetWidth(186)
	panel:SetHeight(156)

	return panel
end


--[[
	Panel Components
--]]

--a panel is a subframe of a menu, basically
local Panel = Bongos:CreateWidgetClass('Frame')
BongosMenu.Panel = Panel

function Panel:Create(name, parent)
	local f = self:New(CreateFrame('Frame', parent:GetName() .. name, parent))
	f:SetPoint('TOPLEFT', 0, -28)
	f:SetPoint('BOTTOMRIGHT')
	f:Hide()

	return f
end


--[[ Checkbuttons ]]--

--checkbutton
function Panel:CreateCheckButton(name)
	local button = CreateFrame('CheckButton', self:GetName() .. name, self, 'OptionsCheckButtonTemplate')
	getglobal(button:GetName() .. 'Text'):SetText(name)

	return button
end


--[[ Sliders ]]--

--basic slider
do
	local function Slider_OnMouseWheel(self, arg1)
		local step = self:GetValueStep() * arg1
		local value = self:GetValue()
		local minVal, maxVal = self:GetMinMaxValues()

		if step > 0 then
			self:SetValue(min(value+step, maxVal))
		else
			self:SetValue(max(value+step, minVal))
		end
	end

	local function Slider_OnShow(self)
		self.showing = true
		if self.OnShow then
			self:OnShow()
		end
		self.showing = nil
	end

	local function Slider_OnValueChanged(self, value)
		if not self.showing then
			self:UpdateValue(value)
		end

		if self.UpdateText then
			self:UpdateText(value)
		else
			self.valText:SetText(value)
		end
	end

	function Panel:CreateSlider(text, low, high, step, OnShow, UpdateValue, UpdateText)
		local name = self:GetName() .. text

		local slider = CreateFrame('Slider', name, self, 'OptionsSliderTemplate')
		slider:SetMinMaxValues(low, high)
		slider:SetValueStep(step)
		slider:EnableMouseWheel(true)

		getglobal(name .. 'Text'):SetText(text)
		getglobal(name .. 'Low'):SetText('')
		getglobal(name .. 'High'):SetText('')

		local text = slider:CreateFontString(nil, 'BACKGROUND')
		text:SetFontObject('GameFontHighlightSmall')
		text:SetPoint('LEFT', slider, 'RIGHT', 7, 0)
		slider.valText = text

		slider.OnShow = OnShow
		slider.UpdateValue = UpdateValue
		slider.UpdateText = UpdateText
		
		slider:SetScript('OnShow', Slider_OnShow)
		slider:SetScript('OnValueChanged', Slider_OnValueChanged)
		slider:SetScript('OnMouseWheel', Slider_OnMouseWheel)

		return slider
	end
end

--scale
do
	local function Slider_OnShow(self)
		local id = self:GetParent().id
		self:SetValue(Bongos.Bar:Get(id):GetScale() * 100)
	end

	local function Slider_UpdateValue(self, value)
		local id = self:GetParent().id
		Bongos.Bar:Get(id):SetFrameScale(value/100)
	end

	function Panel:CreateScaleSlider()
		return self:CreateSlider(L.Scale, 50, 150, 1, Slider_OnShow, Slider_UpdateValue)
	end
end

--opacity
do
	local function Slider_OnShow(self)
		local id = self:GetParent().id
		self:SetValue(Bongos.Bar:Get(id):GetFrameAlpha() * 100)
	end

	local function Slider_UpdateValue(self, value)
		local id = self:GetParent().id
		Bongos.Bar:Get(id):SetFrameAlpha(value/100)
	end

	function Panel:CreateOpacitySlider()
		return self:CreateSlider(L.Opacity, 0, 100, 1, Slider_OnShow, Slider_UpdateValue)
	end
end

--faded opacity
do
	local function Slider_OnShow(self)
		local id = self:GetParent().id
		self:SetValue(select(2, Bongos.Bar:Get(id):GetFadedAlpha()) * 100)
	end

	local function Slider_UpdateValue(self, value)
		local id = self:GetParent().id
		Bongos.Bar:Get(id):SetFadeAlpha(value/100)
	end

	function Panel:CreateFadeSlider()
		return self:CreateSlider(L.FadedOpacity, 0, 100, 1, Slider_OnShow, Slider_UpdateValue)
	end
end

--spacing
do
	local function Slider_OnShow(self)
		local frame = Bongos.Bar:Get(self:GetParent().id)
		self:SetValue(frame:GetSpacing())
	end

	local function Slider_UpdateValue(self, value)
		Bongos.Bar:Get(self:GetParent().id):SetSpacing(value)
	end

	function Panel:CreateSpacingSlider()
		return self:CreateSlider(L.FadedOpacity, -8, 32, 1, Slider_OnShow, Slider_UpdateValue)
	end
end