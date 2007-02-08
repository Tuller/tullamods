--[[
	actionBarGlobal.lua
		This panel does things like enabling altcast, toggling range coloring, etc
--]]

local frameName

--[[ Panel ]]--

function BOptionsActionBarGlobal_OnLoad()
	frameName = this:GetName()
end

function BOptionsActionBarGlobal_OnShow()
	this.onShow = 1

	getglobal(frameName .. "LockButtons"):SetChecked(BActionConfig.ButtonsLocked())
	getglobal(frameName .. "ShowGrid"):SetChecked(BActionConfig.ShowGrid())

	getglobal(frameName .. "Tooltips"):SetChecked(BActionConfig.TooltipsShown())
	getglobal(frameName .. "Range"):SetChecked(BActionConfig.ColorOutOfRange())
	getglobal(frameName .. "MacroText"):SetChecked(BActionConfig.MacrosShown())
	getglobal(frameName .. "HotkeysText"):SetChecked(BActionConfig.HotkeysShown())
--[[
	if BActionConfig.GetUnit(2) then
		getglobal(frameName .. "RightClickSelfCast"):SetChecked(true)
	else
		getglobal(frameName .. "RightClickSelfCast"):SetChecked(false)
	end
	
	if BActionConfig.GetUnit(3) then
		getglobal(frameName .. "MiddleClickFocusCast"):SetChecked(true)
	else
		getglobal(frameName .. "MiddleClickFocusCast"):SetChecked(false)
	end
--]]
	local r, g, b = BActionConfig.GetRangeColor()
	getglobal(frameName .. "RangeColorNormalTexture"):SetVertexColor(r, g, b)

	UIDropDownMenu_SetSelectedValue(getglobal(frameName .. "QuickMove"), BActionConfig.GetQuickMoveMode())

	local numbars = BActionBar:GetNumber()
	for i,v in ipairs(getglobal(frameName .. "NumActionBars").vals) do
		if v == numbars then
			getglobal(frameName .. "NumActionBars"):SetValue(i)
			break
		end
	end
	
	this.onShow = nil
end

--[[ Quick Move Dropdown ]]--

local function AddDropdownButton(text, value, selectedValue, action)
	local info = {}
	info.text = text
	info.func = action
	info.value = value
	if value == selectedValue then
		info.checked = 1
	end
	UIDropDownMenu_AddButton(info)
end

function BOptionsQuickMove_OnShow()
	UIDropDownMenu_Initialize(this, BOptionsQuickMove_Initialize)
	UIDropDownMenu_SetWidth(72, this)
end

local function QuickMove_OnClick()
	UIDropDownMenu_SetSelectedValue(getglobal(frameName .. "QuickMove"), this.value)
	BActionConfig.SetQuickMoveMode(this.value)
end

function BOptionsQuickMove_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(getglobal(frameName .. "QuickMove"))

	AddDropdownButton("None", nil, selectedValue, QuickMove_OnClick)
	AddDropdownButton("Shift", 1, selectedValue, QuickMove_OnClick)
	AddDropdownButton("Control", 2, selectedValue, QuickMove_OnClick)
	AddDropdownButton("Alt", 3, selectedValue, QuickMove_OnClick)
end

--[[ Out of Range Coloring Functions ]]--

--set the background of the frame between opaque/transparent
function BOptionsRangeColor_OnClick()
	if ColorPickerFrame:IsShown() then
		ColorPickerFrame:Hide()
	else
		local red, green, blue = BActionConfig.GetRangeColor()

		ColorPickerFrame.func = BOptionsRangeColor_ColorChange
		ColorPickerFrame.cancelFunc = BOptionsRangeColor_CancelChanges

		getglobal(frameName .. "RangeColorNormalTexture"):SetVertexColor(red, green, blue)
		ColorPickerFrame:SetColorRGB(red, green, blue)
		ColorPickerFrame.previousValues = {r = red, g = green, b = blue}

		ShowUIPanel(ColorPickerFrame)
	end
end

function BOptionsRangeColor_ColorChange()
	local r, g, b = ColorPickerFrame:GetColorRGB()

	BActionConfig.SetRangeColor(r, g, b)

	getglobal(frameName .. "RangeColorNormalTexture"):SetVertexColor(r, g, b)
end

function BOptionsRangeColor_CancelChanges()
	local prevValues = ColorPickerFrame.previousValues

	BActionConfig.SetRangeColor(prevValues.r, prevValues.g, prevValues.b)

	getglobal(frameName .. "RangeColorNormalTexture"):SetVertexColor(prevValues.r, prevValues.g, prevValues.b)
end