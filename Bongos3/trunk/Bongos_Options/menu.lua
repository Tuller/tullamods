--[[
	menu.lua
		Code for the Bongos options panel
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3')
local Options = Bongos:CreateWidgetClass('Frame')

function Options:Load()
	local f = self:New(CreateFrame('Frame', 'BongosOptions', UIParent))
	f.name = 'Bongos'
	InterfaceOptions_AddCategory(f)
	Bongos.Options = f

	local AB = Bongos:GetModule('ActionBar', true)
	if AB then
		local f = self:New(CreateFrame('Frame', 'BongosABOptions', UIParent))
		f.name = ACTIONBARS_LABEL or 'Action Bars' --2.3 hack, since ACTIONBARS_LABEL does not exist there
		f.parent = 'Bongos'
		InterfaceOptions_AddCategory(f)
		AB.Options = f
	end
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
	getglobal(panel:GetName() .. 'Title'):SetFontObject('GameFontNormal')

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
	local button = CreateFrame('CheckButton', parent:GetName() .. name, parent, 'InterfaceOptionsCheckButtonTemplate')
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
	local ColorSelect = Bongos:CreateWidgetClass('Button')
	local selectors = {}

	function ColorSelect:Create(name, parent, SaveColor, LoadColor)
		local f = self:New(CreateFrame('Button', parent:GetName() .. name, parent))
		f:SetWidth(24); f:SetHeight(24)
		f:SetNormalTexture('Interface/ChatFrame/ChatFrameColorSwatch')
		f.SaveColor = SaveColor
		f.LoadColor = LoadColor
		f.swatchFunc = function() f:SetColor(ColorPickerFrame:GetColorRGB()) end
		f.cancelFunc = function() f:SetColor(f.r, f.g, f.b) end

		local bg = f:CreateTexture(nil, 'BACKGROUND')
		bg:SetWidth(21); bg:SetHeight(21)
		bg:SetTexture(1, 1, 1)
		bg:SetPoint('CENTER')
		f.bg = bg

		local text = f:CreateFontString(nil, 'ARTWORK')
		text:SetFontObject('GameFontHighlightSmall')
		text:SetPoint('LEFT', f, 'RIGHT', 2, 0)
		text:SetText(name)
		f.text = text

		f:RegisterForDrag('LeftButton')
		f:SetScript('OnDragStart', self.CopyColor)
		f:SetScript('OnClick', self.OnClick)
		f:SetScript('OnEnter', self.OnEnter)
		f:SetScript('OnLeave', self.OnLeave)
		f:SetScript('OnShow', self.OnShow)

		--register the color selector, and create the copier if needed
		table.insert(selectors, f)
		return f
	end

	function ColorSelect:CopyColor()
		local copier = self.copier or self:CreateCopier()
		copier.bg:SetVertexColor(self:GetNormalTexture():GetVertexColor())
		copier:Show()
	end

	function ColorSelect:PasteColor()
		self:SetColor(self.copier.bg:GetVertexColor())
		self.copier:Hide()
	end

	function ColorSelect:SetColor(...)
		self:GetNormalTexture():SetVertexColor(...)
		self:SaveColor(...)
	end

	function ColorSelect:OnClick()
		if ColorPickerFrame:IsShown() then
			ColorPickerFrame:Hide()
		else
			self.r, self.g, self.b = self:LoadColor()

			UIDropDownMenuButton_OpenColorPicker(self)
			ColorPickerFrame:SetFrameStrata('TOOLTIP')
			ColorPickerFrame:Raise()
		end
	end
	
	function ColorSelect:OnShow()
		local r, g, b = self:LoadColor()
		self:GetNormalTexture():SetVertexColor(r, g, b)
	end

	function ColorSelect:OnEnter()
		local color = NORMAL_FONT_COLOR
		self.bg:SetVertexColor(color.r, color.g, color.b)
	end

	function ColorSelect:OnLeave()
		local color = HIGHLIGHT_FONT_COLOR
		self.bg:SetVertexColor(color.r, color.g, color.b)
	end

	--color copier: we use this to transfer color from one color selector to another
	function ColorSelect:CreateCopier()
		local f = CreateFrame('Frame')
		f:SetWidth(24); f:SetHeight(24)
		f:EnableMouse(true)
		f:SetToplevel(true)
		f:SetMovable(true)
		f:RegisterForDrag('LeftButton')
		f:SetFrameStrata('TOOLTIP')
		f:Hide()

		f:SetScript('OnUpdate', function(self)
			local x, y = GetCursorPosition()
			self:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x - 8, y + 8)
		end)

		f:SetScript('OnReceiveDrag', function(self)
			for _,selector in pairs(selectors) do
				if MouseIsOver(selector, 8, -8, -8, 8) then
					selector:PasteColor()
					break
				end
			end
			self:Hide()
		end)

		f:SetScript('OnMouseUp', f.Hide)

		f.bg = f:CreateTexture()
		f.bg:SetTexture('Interface/ChatFrame/ChatFrameColorSwatch')
		f.bg:SetAllPoints(f)

		ColorSelect.copier = f
		return f
	end

	function Options:CreateColorSelector(name, parent, SaveColor, LoadColor)
		return ColorSelect:Create(name, parent, SaveColor, LoadColor)
	end
end

Options:Load()