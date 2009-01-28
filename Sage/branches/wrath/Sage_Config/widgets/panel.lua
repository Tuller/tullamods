--[[
	menu.lua
		Code for the Dominos options panel
--]]

--omg speed globals
local _G = _G
local min = math.min
local max = math.max
local L = LibStub('AceLocale-3.0'):GetLocale('Sage-Config')

--panel object
local Panel = Sage:CreateClass('Frame')
Sage.Panel = Panel

function Panel:New(name, title, subtitle, icon, parent)
	local f = self:Bind(CreateFrame('Frame', name, UIParent))
	f.name = title
	f.parent = parent
	
	local text = f:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
	text:SetPoint('TOPLEFT', 16, -16)
	if icon then
		text:SetFormattedText('|T%s:%d|t %s', icon, 32, title)
	else
		text:SetText(title)
	end

	local subtext = f:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
	subtext:SetHeight(32)
	subtext:SetPoint('TOPLEFT', text, 'BOTTOMLEFT', 0, -8)
	subtext:SetPoint('RIGHT', f, -32, 0)
	subtext:SetNonSpaceWrap(true)
	subtext:SetJustifyH('LEFT')
	subtext:SetJustifyV('TOP')
	subtext:SetText(subtitle)
	
	InterfaceOptions_AddCategory(f, 'Sage')

	return f
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

	function Panel:NewSlider(text, low, high, step)
		local name = self:GetName() .. text
		local f = CreateFrame('Slider', name, self, 'OptionsSliderTemplate')
		f:SetScript('OnMouseWheel', Slider_OnMouseWheel)
		f:SetMinMaxValues(low, high)
		f:SetValueStep(step)
		f:EnableMouseWheel(true)

		_G[name .. 'Text']:SetText(text)
		_G[name .. 'Low']:SetText('')
		_G[name .. 'High']:SetText('')

		local text = f:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlightSmall')
		text:SetPoint('LEFT', f, 'RIGHT', 7, 0)
		f.valText = text

		return f
	end
end

--check button
function Panel:NewCheckButton(name)
	local b = CreateFrame('CheckButton', self:GetName() .. name, self, 'InterfaceOptionsCheckButtonTemplate')
	_G[b:GetName() .. 'Text']:SetText(name)

	return b
end

--basic dropdown
function Panel:NewDropdown(name)
	local f = CreateFrame('Frame', self:GetName() .. name, self, 'UIDropDownMenuTemplate')

	local text = f:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmall')
	text:SetPoint('BOTTOMLEFT', f, 'TOPLEFT', 21, 0)
	text:SetText(name)

	return f
end

--button
function Panel:NewButton(name, width, height)
	local b = CreateFrame('Button', self:GetName() .. name, self, 'UIPanelButtonTemplate')
	b:SetText(name)
	b:SetWidth(width)
	b:SetHeight(height or width)

	return b
end

--radio group
function Panel:NewRadioGroup(name)
	return Sage.RadioGroup:New(name, self)
end


--[[
	Specialized Widgets
		All of these sliders act on a unit group, which is the same as a <frameList>
--]]


--[[ Width ]]--

local function WidthSlider_OnShow(self)
	self.onShow = true
	self:SetValue(Sage.Frame:GetSetting(self.unitGroup, 'width') or 150)
	self.onShow = nil
end

local function WidthSlider_OnValueChanged(self, value)
	if not self.onShow then
		Sage.Frame:ForFrame(self.unitGroup, 'SetFrameWidth', value)
	end
	self.valText:SetText(value)
end

function Panel:NewWidthSlider(unitGroup)
	local f = self:NewSlider(L.Width, 100, 300, 5)
	f.unitGroup = unitGroup
	f:SetScript('OnShow', WidthSlider_OnShow)	
	f:SetScript('OnValueChanged', WidthSlider_OnValueChanged)

	return f
end


--[[ Opacity ]]--

local function OpacitySlider_OnShow(self)
	self.onShow = true
	local value = Sage.Frame:GetSetting(self.unitGroup, 'alpha') or 1
	self:SetValue(value * 100)
	self.onShow = nil
end

local function OpacitySlider_OnValueChanged(self, value)
	if not self.onShow then
		Sage.Frame:ForFrame(self.unitGroup, 'SetFrameAlpha', value/100)
	end
	self.valText:SetText(value)
end

function Panel:NewOpacitySlider(unitGroup)
	local f = self:NewSlider(L.Opacity, 0, 100, 1)
	f.unitGroup = unitGroup
	f:SetScript('OnShow', OpacitySlider_OnShow)	
	f:SetScript('OnValueChanged', OpacitySlider_OnValueChanged)

	return f
end


--[[ Out of Range Opacity ]]--

local function OOROpacitySlider_OnShow(self)
	self.onShow = true
	local value = Sage.Frame:GetSetting(self.unitGroup, 'oorAlpha') or Sage.Frame:GetSetting(self.unitGroup, 'alpha') or 1
	self:SetValue(value * 100)
	self.onShow = nil
end

local function OOROpacitySlider_OnValueChanged(self, value)
	if not self.onShow then
		Sage.Frame:ForFrame(self.unitGroup, 'SetOORAlpha', value/100)
	end
	self.valText:SetText(value)
end

function Panel:NewOOROpacitySlider(unitGroup)
	local f = self:NewSlider(L.OOROpacity, 0, 100, 1)
	f.unitGroup = unitGroup
	f:SetScript('OnShow', OOROpacitySlider_OnShow)	
	f:SetScript('OnValueChanged', OOROpacitySlider_OnValueChanged)

	return f
end


--[[ Scale Slider ]]--

--out of range opacity (friendly units only)
local function ScaleSlider_OnShow(self)
	self.onShow = true
	local value = Sage.Frame:GetSetting(self.unitGroup, 'scale') or 1
	self:SetValue(value * 100)
	self.onShow = nil
end

local function ScaleSlider_OnValueChanged(self, value)
	if not self.onShow then
		Sage.Frame:ForFrame(self.unitGroup, 'SetFrameScale', value/100)
	end
	self.valText:SetText(value)
end

function Panel:NewScaleSlider(unitGroup)
	local f = self:NewSlider(L.Scale, 50, 250, 1)
	f.unitGroup = unitGroup
	f:SetScript('OnShow', ScaleSlider_OnShow)	
	f:SetScript('OnValueChanged', ScaleSlider_OnValueChanged)
	
	return f
end


--[[ Text Mode Selector ]]--

local function TextMode_OnSelect(self, value)
	return Sage.Frame:ForFrame(self.unitGroup, 'SetTextMode', value)
end

local function TextMode_GetSelectedValue(self)
	return Sage.Frame:GetSetting(self.unitGroup, 'textMode') or 'smart'
end

function Panel:NewTextModeSelector(unitGroup)
	local f = self:NewRadioGroup(L.TextDisplay)
	f.unitGroup = unitGroup

	f:Add(L.AlwaysShowText, 'always')
	f:Add(L.NeverShowText, 'never')
	f:Add(L.MouseoverText, 'mouseover')
	f:Add(L.SmartText, 'smart')

	f.OnSelect = TextMode_OnSelect
	f.GetSelectedValue = TextMode_GetSelectedValue
	
	return f
end