--[[
	menu.lua
		Code for the OmniCC options panel
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3')
local Options = Bongos.Options

function Options:Load()
	self.name = 'Bongos'

	self:AddGeneralPanel()
	
	--------------------------------------------------------------------------
	--Actionbar Tab:

	--General
	--Enable Right Click Selfcast
	--Selfcast Key

	--Coloring					Display
	-- x Color OOM [ ];  			x Show Empty Buttons
	-- x Color OOR [ ]				x Show Tooltips
	-- x Highlight Buffs and Debuffs	x Show Hotkeys
	-- Buff Color [ ]  Debuff Color [ ]	x Show Bindings
	-------------------------------------------------------------------------
	InterfaceOptions_AddCategory(self) 
end


--[[ Panels ]]--

--General
--Enable Sticky Bars, Show Minimap Button, Scale, Opacity
--Show Minimap Button
--Scale
--Opacity
function Options:AddGeneralPanel()
	local panel = self:CreatePanel(L.General)
	panel:SetWidth(180); panel:SetHeight(200)
	panel:SetPoint('TOPLEFT', 10, -24)
	
	--show models
	local stickyBars = self:CreateCheckButton(L.EnableStickyBars, panel)
	stickyBars:SetScript('OnShow', function(self) self:SetChecked(Bongos:IsSticky()) end)
	stickyBars:SetScript('OnClick', function(self) Bongos:SetSticky(self:GetChecked()) end)
	stickyBars:SetPoint('TOPLEFT', 10, -8)

	--show cooldown pulse
	local showMinimap = self:CreateCheckButton(L.ShowMinimapButton, panel)
	showMinimap:SetScript('OnShow', function(self) self:SetChecked(Bongos:ShowingMinimap()) end)
	showMinimap:SetScript('OnClick', function(self) Bongos:SetShowMinimap(self:GetChecked()) end)
	showMinimap:SetPoint('TOP', stickyBars, 'BOTTOM')
	
	--minimum scale slider
	local scale = self:CreateSlider(L.Scale, panel, 50, 150, 1)
	scale:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(100)
		self.onShow = nil
	end)
	scale:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(value)
		if not self.onShow then
			Bongos.Bar:ForBar('all', 'SetFrameScale', value/100)
		end
	end)
	scale:SetPoint('TOPLEFT', showMinimap, 'BOTTOMLEFT', 0, -15)
	
	--minimum scale slider
	local opacity = self:CreateSlider(L.Opacity, panel, 0, 100, 1)
	opacity:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(100)
		self.onShow = nil
	end)
	opacity:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(value)
		if not self.onShow then
			Bongos.Bar:ForBar('all', 'SetFrameAlpha', value/100)
		end
	end)
	opacity:SetPoint('TOPLEFT', scale, 'BOTTOMLEFT', 0, -20)
	
	local faded = self:CreateSlider(L.FadedOpacity, panel, 0, 100, 1)
	faded:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(100)
		self.onShow = nil
	end)
	faded:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(value)
		if not self.onShow then
			Bongos.Bar:ForBar('all', 'SetFadeAlpha', value/100)
		end
	end)
	faded:SetPoint('TOPLEFT', opacity, 'BOTTOMLEFT', 0, -20)

	return panel
end


--[[
	Widget Templates
--]]

--panel
function Options:CreatePanel(name)
	local panel = CreateFrame('Frame', self:GetName() .. name, self, 'OptionFrameBoxTemplate')
	panel:SetBackdropBorderColor(0.4, 0.4, 0.4)
	panel:SetBackdropColor(0.15, 0.15, 0.15, 0.5)
	getglobal(panel:GetName() .. 'Title'):SetText(name)

	return panel
end

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

	function Options:CreateSlider(text, parent, low, high, step)
		local name = parent:GetName() .. text
		local slider = CreateFrame('Slider', name, parent, 'OptionsSliderTemplate')
		slider:SetScript('OnMouseWheel', Slider_OnMouseWheel)
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

		return slider
	end
end

--check button
function Options:CreateCheckButton(name, parent)
	local button = CreateFrame('CheckButton', parent:GetName() .. name, parent, 'OptionsCheckButtonTemplate')
	getglobal(button:GetName() .. 'Text'):SetText(name)

	return button
end

--basic dropdown
function Options:CreateDropdown(name, parent)
	local frame = CreateFrame('Frame', parent:GetName() .. name, parent, 'UIDropDownMenuTemplate')
	local text = frame:CreateFontString(nil, 'BACKGROUND')
	text:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT', 21, 0)
	text:SetFontObject('GameFontNormalSmall')
	text:SetText(name)

	return frame
end

--button
function Options:CreateButton(name, parent, width, height)
	local button = CreateFrame('Button', parent:GetName() .. name, parent, 'UIPanelButtonTemplate')
	button:SetText(name)
	button:SetWidth(width); button:SetHeight(height or width)

	return button
end

--color selector
do
	local colorSelectors, colorCopier

	--color copier: we use this to transfer color from one color selector to another
	local function ColorCopier_Create()
		local copier = CreateFrame('Frame')
		copier:SetWidth(24); copier:SetHeight(24)
		copier:Hide()

		copier:EnableMouse(true)
		copier:SetToplevel(true)
		copier:SetMovable(true)
		copier:RegisterForDrag('LeftButton')
		copier:SetFrameStrata('TOOLTIP')

		copier:SetScript('OnUpdate', function(self)
			local x, y = GetCursorPosition()
			self:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x - 8, y + 8)
		end)

		copier:SetScript('OnReceiveDrag', function(self)
			for _,selector in pairs(colorSelectors) do
				if MouseIsOver(selector, 8, -8, -8, 8) then
					selector:PasteColor()
					break
				end
			end
			self:Hide()
		end)

		copier:SetScript('OnMouseUp', copier.Hide)

		copier.bg = copier:CreateTexture()
		copier.bg:SetTexture('Interface/ChatFrame/ChatFrameColorSwatch')
		copier.bg:SetAllPoints(copier)

		return copier
	end

	local function ColorSelect_CopyColor(self)
		colorCopier = colorCopier or ColorCopier_Create()
		colorCopier.bg:SetVertexColor(self:GetNormalTexture():GetVertexColor())
		colorCopier:Show()
	end

	local function ColorSelect_PasteColor(self)
		self:SetColor(colorCopier.bg:GetVertexColor())
		colorCopier:Hide()
	end

	local function ColorSelect_SetColor(self, ...)
		self:GetNormalTexture():SetVertexColor(...)
		OmniCC:SetDurationColor(self.duration, ...)
	end

	local function ColorSelect_OnClick(self)
		if ColorPickerFrame:IsShown() then
			ColorPickerFrame:Hide()
		else
			self.r, self.g, self.b = OmniCC:GetDurationFormat(self:GetParent().duration)

			UIDropDownMenuButton_OpenColorPicker(self)
			ColorPickerFrame:SetFrameStrata('TOOLTIP')
			ColorPickerFrame:Raise()
		end
	end

	local function ColorSelect_OnEnter(self)
		local color = NORMAL_FONT_COLOR
		self.bg:SetVertexColor(color.r, color.g, color.b)
	end

	local function ColorSelect_OnLeave(self)
		local color = HIGHLIGHT_FONT_COLOR
		self.bg:SetVertexColor(color.r, color.g, color.b)
	end

	function Options:CreateColorSelector(name, parent, duration)
		local frame = CreateFrame('Button', parent:GetName() .. name, parent)
		frame:SetWidth(16); frame:SetHeight(16)
		frame:SetNormalTexture('Interface/ChatFrame/ChatFrameColorSwatch')
		frame.duration = duration

		local bg = frame:CreateTexture(nil, 'BACKGROUND')
		bg:SetWidth(14); bg:SetHeight(14)
		bg:SetTexture(1, 1, 1)
		bg:SetPoint('CENTER')
		frame.bg = bg

		frame.SetColor = ColorSelect_SetColor
		frame.PasteColor = ColorSelect_PasteColor
		frame.swatchFunc = function() frame:SetColor(ColorPickerFrame:GetColorRGB()) end
		frame.cancelFunc = function() frame:SetColor(frame.r, frame.g, frame.b) end

		frame:RegisterForDrag('LeftButton')
		frame:SetScript('OnDragStart', ColorSelect_CopyColor)
		frame:SetScript('OnClick', ColorSelect_OnClick)
		frame:SetScript('OnEnter', ColorSelect_OnEnter)
		frame:SetScript('OnLeave', ColorSelect_OnLeave)

		--register the color selector, and create the copier if needed
		if colorSelectors then
			table.insert(colorSelectors, frame)
		else
			colorSelectors = {frame}
		end

		return frame
	end
end

Options:Load()