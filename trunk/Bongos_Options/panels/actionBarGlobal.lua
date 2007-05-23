--[[
	actionBarGlobal.lua
		This panel does things like enabling altcast, toggling range coloring, etc
--]]

local name

--[[ Panel ]]--

function BOptionsActionBarGlobal_OnLoad(self)
	name = self:GetName()
end

--[[ ActionBar Slider ]]--

function BOptionsNumActionbars_OnLoad(self)
	local name = self:GetName()
	getglobal(name .. "Text"):SetText("Action Bars")
	getglobal(name .. "Low"):SetText(1)
	getglobal(name .. "High"):SetText(120)
	
	self.vals = {1, 2, 3, 4, 5, 6, 8, 10, 12, 15, 20, 24, 30, 40, 60, 120}
end

function BOptionsNumActionbars_OnShow(self)
	self.onShow = true

	local numbars = BongosActionBar:GetNumber()
	for i,v in ipairs(self.vals) do
		if v == numbars then
			self:SetValue(i)
			break
		end
	end

	self.onShow = nil
end

function BOptionsNumActionbars_OnValueChanged(self, value)
	local numBars = self.vals[value]
	if not self.onShow then
		BongosActionBar:SetNumber(numBars)
	end
	getglobal(self:GetName() .. "ValText"):SetText(numBars)
end

--[[ Quick Move Dropdown ]]--

local info = {}
local function AddDropdownButton(text, value, selectedValue, action)
	info.text = text
	info.func = action
	info.value = value
	info.checked = value == selectedValue
	UIDropDownMenu_AddButton(info)
end

local function QuickMove_OnClick()
	UIDropDownMenu_SetSelectedValue(getglobal(name .. "QuickMove"), this.value)
	BongosActionConfig:SetQuickMoveMode(this.value)
end

function BOptionsQuickMove_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(getglobal(name .. "QuickMove"))

	AddDropdownButton("None", nil, selectedValue, QuickMove_OnClick)
	AddDropdownButton("Shift", 1, selectedValue, QuickMove_OnClick)
	AddDropdownButton("Control", 2, selectedValue, QuickMove_OnClick)
	AddDropdownButton("Alt", 3, selectedValue, QuickMove_OnClick)
end

--[[ Out of Range Coloring Functions ]]--

--set the background of the frame between opaque/transparent
function BOptionsRangeColor_OnClick(self)
	if ColorPickerFrame:IsShown() then
		ColorPickerFrame:Hide()
	else
		local red, green, blue = BongosActionConfig:GetRangeColor()

		ColorPickerFrame.func = BOptionsRangeColor_ColorChange
		ColorPickerFrame.cancelFunc = BOptionsRangeColor_CancelChanges

		getglobal(name .. "RangeColorNormalTexture"):SetVertexColor(red, green, blue)
		ColorPickerFrame:SetColorRGB(red, green, blue)
		ColorPickerFrame.previousValues = {r = red, g = green, b = blue}

		ShowUIPanel(ColorPickerFrame)
	end
end

function BOptionsRangeColor_ColorChange()
	local r, g, b = ColorPickerFrame:GetColorRGB()

	BongosActionConfig:SetRangeColor(r, g, b)

	getglobal(name .. "RangeColorNormalTexture"):SetVertexColor(r, g, b)
end

function BOptionsRangeColor_CancelChanges()
	local prevValues = ColorPickerFrame.previousValues

	BongosActionConfig:SetRangeColor(prevValues.r, prevValues.g, prevValues.b)

	getglobal(name .. "RangeColorNormalTexture"):SetVertexColor(prevValues.r, prevValues.g, prevValues.b)
end