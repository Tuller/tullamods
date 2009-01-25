--[[
	menu.lua
		Code for the Dominos options panel
--]]

--omg speed globals
local _G = _G
local min = math.min
local max = math.max

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
	
	InterfaceOptions_AddCategory(f)

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

function Panel:NewWidthSlider(unitGroup)
end

function Panel:NewOpacitySlider(unitGroup)
end

function Panel:NewOOROpacitySlider(unitGroup)
end


--[[ Scale Slider ]]--

local function ScaleSlider_GetScale(self)
end

local function ScaleSlider_SetValue(self, value)
end

function Panel:NewScaleSlider(unitGroup)
end


--[[ Text Mode Selector ]]--

local function TextMode_OnSelect(self, value)
	return Sage.Frame:ForFrame(self.unitGroup, 'SetTextMode', value)
end

local function TextMode_GetSelectedValue(self)
	return Sage.Frame:GetSetting(self.unitGroup, 'textMode')
end

function Panel:NewTextModeSelector(unitGroup)
	local f = Options:NewRadioGroup(L.TextDisplay)
	f.unitGroup = unitGroup

	f:Add(L.AlwaysShowText, 'always')
	f:Add(L.NeverShowText, 'never')
	f:Add(L.MouseoverText, 'mouseover')
	f:Add(L.SmartText, 'smart')

	f.OnSelect = TextMode_OnSelect
	f.GetSelectedValue = TextMode_GetSelectedValue
	
	return f
end