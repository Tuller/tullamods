--[[
	BongosMenu.lua
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
Bongos.Menu = Bongos:CreateWidgetClass('Frame')

local BongosMenu = Bongos.Menu
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3')


BongosMenu.bg = {
	bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
	edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
	insets = {11, 12, 12, 11},
	tile = true,
	tileSize = 32,
	edgeSize = 32,
}

BongosMenu.extraWidth = 20
BongosMenu.extraHeight = 40

function BongosMenu:Create(name)
	local f = self:New(CreateFrame('Frame', 'Bongos3BarMenu' .. name, UIParent))
	f.panels = {}

	f:SetBackdrop(self.bg)
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
			self:SetWidth(max(panel.width + self.extraWidth, 186))
			self:SetHeight(max(panel.height + self.extraHeight, 40))
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
	
	panel:CreateOpacitySlider()
	panel:CreateFadeSlider()
	panel:CreateScaleSlider()

	return panel
end


--[[
	Panel Components
--]]

--a panel is a subframe of a menu, basically
local Panel = Bongos:CreateWidgetClass('Frame')
BongosMenu.Panel = Panel

Panel.width = 0
Panel.height = 0

function Panel:Create(name, parent)
	local f = self:New(CreateFrame('Frame', parent:GetName() .. name, parent))
	f:SetPoint('TOPLEFT', 10, -32)
	f:SetPoint('BOTTOMRIGHT', -10, 10)
	f:Hide()

	return f
end


--[[ Checkbuttons ]]--

--checkbutton
function Panel:CreateCheckButton(name)
	local button = CreateFrame('CheckButton', self:GetName() .. name, self, 'OptionsCheckButtonTemplate')
	getglobal(button:GetName() .. 'Text'):SetText(name)
	
	local prev = self.checkbutton
	if prev then
		button:SetPoint('TOP', prev, 'BOTTOM', 0, 2)
	else
		button:SetPoint('TOPLEFT', 0, 2)
	end
	self.height = self.height + 28
	self.checkbutton = button

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
		
		local prev = self.slider
		if prev then
			slider:SetPoint('BOTTOM', prev, 'TOP', 0, 12)
			self.height = self.height + 32
		else
			slider:SetPoint('BOTTOMLEFT', 4, 6)
			self.height = self.height + 36
		end
		self.slider = slider
		
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
		return self:CreateSlider(L.Spacing, -8, 32, 1, Slider_OnShow, Slider_UpdateValue)
	end
end