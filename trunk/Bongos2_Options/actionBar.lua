--[[
	actionBarGlobal.lua
		This panel does things like enabling altcast, toggling range coloring, etc
--]]

local L = BONGOS_LOCALS
L.ActionBar = "ActionBar"
L.LockButtons = "Lock Button Positions"
L.RightClickSelfCast = "Enable Right Click Selfcast"
L.RangeCheck = "Enable Range Checking"
L.ShowGrid = "Show Empty Buttons"
L.ShowTooltips = "Show ActionButton Tooltips"
L.ShowMacros = "Show Macro Text"
L.ShowHotkeys = "Show Hotkeys"
L.QuickMove = "Quick Move Key"
L.Ctrl = "Control"
L.Alt = "Alt"
L.Shift = "Shift"
L.NumActionBars = "Action Bars"
L.SelfCastKey = "Selfcast Key"

local keys = {NONE:upper(), SHIFT_KEY_TEXT:upper(), CTRL_KEY_TEXT:upper(), ("ALT"):upper()}

local info = {}
local function AddDropdownButton(text, value, selectedValue, action)
	info.text = text
	info.func = action
	info.value = value
	info.checked = value == selectedValue
	UIDropDownMenu_AddButton(info)
end

local function RangeColorPicker_SetScripts(self)
	local function OnColorChange()
		self:SetColor(ColorPickerFrame:GetColorRGB())
	end
	local function OnCancelChanges()
		local prevVals = ColorPickerFrame.previousValues
		self:SetColor(prevVals.r, prevVals.g, prevVals.b)
	end

	function self:SetColor(...)
		BongosActionConfig:SetRangeColor(...)
		self:GetNormalTexture():SetVertexColor(...)
	end

	self:SetScript("OnShow", function(self)
		self:GetNormalTexture():SetVertexColor(BongosActionConfig:GetRangeColor())
	end)

	self:SetScript("OnClick", function(self)
		if ColorPickerFrame:IsShown() then
			ColorPickerFrame:Hide()
		else
			local red, green, blue = BongosActionConfig:GetRangeColor()

			ColorPickerFrame.func = OnColorChange
			ColorPickerFrame.cancelFunc = OnCancelChanges

			self:GetNormalTexture():SetVertexColor(red, green, blue)
			ColorPickerFrame:SetColorRGB(red, green, blue)
			ColorPickerFrame.previousValues = {r = red, g = green, b = blue}

			ShowUIPanel(ColorPickerFrame)
		end
	end)
end

local function Panel_CreateRangeColorPicker(self)
	local picker = CreateFrame("Button", self:GetName() .. "RangeColor", self, "GooeyColorPicker")
	RangeColorPicker_SetScripts(picker)

	return picker
end

local function Panel_AddSelfCastDropDown(self)
	local dropDown = CreateFrame("Frame", self:GetName() .. L.SelfCastKey, self, "GooeyDropDown")
	getglobal(dropDown:GetName() .. "Label"):SetText(L.SelfCastKey)

	local function SelfCast_OnClick()
		UIDropDownMenu_SetSelectedValue(dropDown, this.value)
		BongosActionConfig:SetSelfCastKey(keys[this.value])
	end

	local function SelfCast_Initialize()
		local selected = UIDropDownMenu_GetSelectedValue(dropDown)
		for i,key in ipairs(keys) do
			AddDropdownButton(key, i, selected, SelfCast_OnClick)
		end
	end

	dropDown:SetScript("OnShow", function(self)
		UIDropDownMenu_Initialize(self, SelfCast_Initialize)
		UIDropDownMenu_SetWidth(72, self)
		local selected = GetActionSelfCastKey()

		for i,key in ipairs(keys) do
			if(selected == key) then
				UIDropDownMenu_SetSelectedValue(self, i)
				break
			end
		end
	end)

	self.height = self.height + 42

	return dropDown
end

local function Panel_AddQuickMoveDropDown(self)
	local dropDown = CreateFrame("Frame", self:GetName() .. "QuickMove", self, "GooeyDropDown")
	getglobal(dropDown:GetName() .. "Label"):SetText(L.QuickMove)

	local function QuickMove_OnClick()
		UIDropDownMenu_SetSelectedValue(dropDown, this.value)
		BongosActionConfig:SetQuickMoveMode(this.value>1 and this.value-1 or nil)
	end

	local function QuickMove_Initialize()
		local selected = UIDropDownMenu_GetSelectedValue(dropDown)
		for i,key in ipairs(keys) do
			AddDropdownButton(key, i, selected, QuickMove_OnClick)
		end
	end

	dropDown:SetScript("OnShow", function(self)
		UIDropDownMenu_Initialize(self, QuickMove_Initialize)
		UIDropDownMenu_SetWidth(72, self)
		local mode = BongosActionConfig:GetQuickMoveMode()
		UIDropDownMenu_SetSelectedValue(self, (mode and mode+1) or 1)
	end)

	self.height = self.height + 42

	return dropDown
end

function BongosOptions:AddActionBarPanel()
	local panel = self:AddPanel(L.ActionBar)

	local lockButtons = panel:AddCheckButton(L.LockButtons)
	lockButtons:SetScript("OnShow", function(self)
		self:SetChecked(BongosActionConfig:ButtonsLocked())
	end)
	lockButtons:SetScript("OnClick", function(self)
		BongosActionConfig:LockButtons(self:GetChecked())
	end)

	local rightClickSelfCast = panel:AddCheckButton(L.RightClickSelfCast)
	rightClickSelfCast:SetScript("OnShow", function(self)
		self:SetChecked(BongosActionConfig:GetRightClickUnit())
	end)
	rightClickSelfCast:SetScript("OnClick", function(self)
		if self:GetChecked() then
			BongosActionConfig:SetRightClickUnit("player")
		else
			BongosActionConfig:SetRightClickUnit(nil)
		end
	end)

	local rangeCheck = panel:AddCheckButton(L.RangeCheck)
	rangeCheck:SetScript("OnShow", function(self)
		self:SetChecked(BongosActionConfig:RangeColoring())
	end)
	rangeCheck:SetScript("OnClick", function(self)
		BongosActionConfig:SetRangeColoring(self:GetChecked())
	end)

	local rangeColor = Panel_CreateRangeColorPicker(panel)
	rangeColor:SetPoint("LEFT", rangeCheck:GetName() .. "Text", "RIGHT", 6, 0)

	local showGrid = panel:AddCheckButton(L.ShowGrid)
	showGrid:SetScript("OnShow", function(self)
		self:SetChecked(BongosActionConfig:ShowingEmptyButtons())
	end)
	showGrid:SetScript("OnClick", function(self)
		BongosActionConfig:ShowEmptyButtons(self:GetChecked())
	end)

	local tooltips = panel:AddCheckButton(L.ShowTooltips)
	tooltips:SetScript("OnShow", function(self)
		self:SetChecked(BongosActionConfig:ShowingTooltips())
	end)
	tooltips:SetScript("OnClick", function(self)
		BongosActionConfig:ShowTooltips(self:GetChecked())
	end)

	local macros = panel:AddCheckButton(L.ShowMacros)
	macros:SetScript("OnShow", function(self)
		self:SetChecked(BongosActionConfig:ShowingMacros())
	end)
	macros:SetScript("OnClick", function(self)
		BongosActionConfig:ShowMacros(self:GetChecked())
	end)

	local hotkeys = panel:AddCheckButton(L.ShowHotkeys)
	hotkeys:SetScript("OnShow", function(self)
		self:SetChecked(BongosActionConfig:ShowingHotkeys())
	end)
	hotkeys:SetScript("OnClick", function(self)
		BongosActionConfig:ShowHotkeys(self:GetChecked())
	end)

	local quickMove = Panel_AddQuickMoveDropDown(panel)
	quickMove:SetPoint("TOPLEFT", panel.button, "BOTTOMLEFT", -16, -4)

	local selfCastKey = Panel_AddSelfCastDropDown(panel)
	selfCastKey:SetPoint("TOPLEFT", quickMove, "BOTTOMLEFT", 0, 0)

	local vals = {1, 2, 3, 4, 5, 6, 8, 10, 12, 15, 20, 24, 30, 40, 60, 120}
	local numBars = panel:AddSlider(L.NumActionBars, 1, #vals, 1)
	numBars.high:SetText(vals[#vals])
	numBars:SetScript("OnShow", function(self)
		self.onShow = true
		local numBars = BongosActionBar:GetNumber()
		for i,v in ipairs(vals) do
			if v == numBars then
				self:SetValue(i)
				break
			end
		end
		self.onShow = nil
	end)
	numBars:SetScript("OnValueChanged", function(self, value)
		local numBars = vals[value]
		if not self.onShow then
			BongosActionBar:SetNumber(numBars)
		end
		self.text:SetText(numBars)
	end)

	return panel
end

BongosOptions:AddActionBarPanel()