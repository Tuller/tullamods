--[[
	Menu.lua
		Functions for the Bagnon right click options menu
--]]

local menu
local MENU_NAME = 'BagnonMenu'
local MAX_COLS = 32
local MAX_SPACING = 32
local MIN_SCALE = 50
local MAX_SCALE = 150
local FRAMESTRATA = {'LOW', 'MEDIUM', 'HIGH'}

local function GetFrameLevel(levelString)
	for i, level in pairs(FRAMESTRATA) do
		if level == levelString then
			return i
		end
	end
	return 2
end

--[[ Config Functions ]]--

local function SetStrata(frame, strata)
	frame.sets.strata = FRAMESTRATA[strata]
	frame:SetFrameStrata(FRAMESTRATA[strata])
end

local function SetCols(frame, cols)
	frame.sets.cols = cols
	frame:Layout(cols)
end

local function SetSpacing(frame, space)
	frame.sets.space = space
	frame:Layout(frame.cols, space)
end

--transparency
local function SetAlpha(frame, alpha)
	if not alpha or alpha == 1 then
		frame.sets.alpha = nil
	else
		frame.sets.alpha = alpha
	end
	frame:SetAlpha(alpha)
end

--returns the adjusted x and y coordinates for a frame at the given scale
local function GetRelativeCoords(frame, scale)
	local ratio = frame:GetScale() / scale
	return frame:GetLeft() * ratio, frame:GetTop() * ratio
end

--scale
local function SetScale(frame, scale)
	frame.sets.scale = scale
	
	local x, y = GetRelativeCoords(frame, scale)

	frame:SetScale(scale)
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x, y)
	frame:SavePosition()
end

--lock position
local function SetLock(frame, checked)
	frame:Lock(checked)
end

--set toplevel
local function SetToplevel(frame, checked)
	if checked then
		frame.sets.topLevel = 1
		frame:SetToplevel(true)
	else
		frame.sets.topLevel = nil
		frame:SetToplevel(false)
	end
end

--[[ Color Picker ]]--

local function BGColor_OnColorChange()
	local r, g, b = ColorPickerFrame:GetColorRGB()
	local frame = ColorPickerFrame.frame
	local bgSets = frame.sets.bg
	local a = bgSets.a
	
	bgSets.r = r
	bgSets.g = g
	bgSets.b = b
	
	frame:SetBackdropColor(r, g, b, a)
	frame:SetBackdropBorderColor(1, 1, 1, a)
	getglobal(MENU_NAME .. 'BGColorNormalTexture'):SetVertexColor(r, g, b, a)
end

local function BGColor_OnAlphaChange()
	local frame = ColorPickerFrame.frame
	local alpha = 1 - OpacitySliderFrame:GetValue()
	local bgSets = frame.sets.bg

	bgSets.a = alpha

	frame:SetBackdropColor(bgSets.r, bgSets.g, bgSets.b, alpha)
	frame:SetBackdropBorderColor(1, 1, 1, alpha)
	getglobal(MENU_NAME .. 'BGColorNormalTexture'):SetVertexColor(bgSets.r, bgSets.g, bgSets.b, alpha)
end

local function BGColor_CancelChanges() 
	local prevValues = ColorPickerFrame.previousValues
	local frame = ColorPickerFrame.frame
	
	local bgSets = frame.sets.bg	
	bgSets.r = prevValues.r
	bgSets.g = prevValues.g
	bgSets.b = prevValues.b
	bgSets.a = prevValues.opacity
	
	frame:SetBackdropColor(prevValues.r, prevValues.g, prevValues.b, prevValues.opacity)
	frame:SetBackdropBorderColor(1, 1, 1, prevValues.opacity)
	getglobal(MENU_NAME .. 'BGColorNormalTexture'):SetVertexColor(prevValues.r, prevValues.g, prevValues.b, prevValues.opacity)
end

--set the background of the frame between opaque/transparent
local function BGColor_OnClick(frame)
	if ColorPickerFrame:IsShown() then
		ColorPickerFrame:Hide()
	else
		local bgSets = frame.sets.bg
		
		ColorPickerFrame.frame = frame	
		ColorPickerFrame.hasOpacity = 1
		ColorPickerFrame.opacity = 1 - bgSets.a
		ColorPickerFrame.previousValues = {r = bgSets.r, g = bgSets.g, b = bgSets.b, opacity = bgSets.a}
		
		ColorPickerFrame.func = BGColor_OnColorChange
		ColorPickerFrame.opacityFunc = BGColor_OnAlphaChange
		ColorPickerFrame.cancelFunc = BGColor_CancelChanges
		
		ColorPickerFrame:SetColorRGB(bgSets.r, bgSets.g, bgSets.b)
		
		getglobal(MENU_NAME .. 'BGColorNormalTexture'):SetVertexColor(bgSets.r, bgSets.g, bgSets.b, bgSets.a)
		
		ShowUIPanel(ColorPickerFrame)
	end
end

--[[ Show the Menu ]]--

local function CreateMenu()
	local menu = CreateFrame('Button', MENU_NAME, UIParent, 'GooeyPopup')
	menu:SetWidth(230); menu:SetHeight(316)
	
	menu:RegisterForClicks('LeftButtonDown', 'LeftButtonUp', 'RightButtonUp')
	menu:SetScript('OnClick', function() this:Hide() end)
	menu:SetScript('OnHide', function() this:SetParent(UIParent) end)
	
	local title = menu:CreateFontString(MENU_NAME .. 'Title', 'ARTWORK')
	title:SetFontObject('GameFontHighlightLarge')
	title:SetPoint('TOP', menu, 'TOP', 0, -8)
	
	local closeButton = CreateFrame('Button', MENU_NAME .. 'Close', menu, 'UIPanelCloseButton')
	closeButton:SetPoint('TOPRIGHT', menu, 'TOPRIGHT', -1, -1)
	
	--[[ Check Buttons ]]--
	
	local lockButton = CreateFrame('CheckButton', MENU_NAME .. 'Lock', menu, 'GooeyCheckButton')
	lockButton:SetPoint('TOPLEFT', menu, 'TOPLEFT', 6, -30)
	lockButton:SetScript('OnClick', function() SetLock(menu.frame, this:GetChecked()) end)
	lockButton:SetText(BAGNON_OPTIONS_LOCK)
	
	local topLevelButton = CreateFrame('CheckButton', MENU_NAME .. 'TopLevel', menu, 'GooeyCheckButton')
	topLevelButton:SetPoint('TOPLEFT', lockButton, 'BOTTOMLEFT')
	topLevelButton:SetScript('OnClick', function() SetToplevel(menu.frame, this:GetChecked()) end)
	topLevelButton:SetText(BAGNON_OPTIONS_TOPLEVEL)
	
	local colorPicker = CreateFrame('Button', MENU_NAME .. 'BGColor', menu, 'GooeyColorPicker')
	colorPicker:SetPoint('TOPLEFT', topLevelButton, 'BOTTOMLEFT', 4, 2)
	colorPicker:SetScript('OnClick', function() BGColor_OnClick(menu.frame) end)
	colorPicker:SetText(BAGNON_OPTIONS_BACKGROUND)

	--[[ Sliders ]]--
	
	--strata
	local strataSlider = CreateFrame('Slider', MENU_NAME .. 'Level', menu, 'BagnonSlider')
	strataSlider:SetPoint('BOTTOM', menu, 'BOTTOM', 0, 20)
	strataSlider:SetValueStep(1)
	strataSlider:SetMinMaxValues(1, #FRAMESTRATA)
	strataSlider:SetScript('OnValueChanged', function() 
		if not menu.onShow then SetStrata(menu.frame, this:GetValue()) end
		getglobal(this:GetName() .. 'ValText'):SetText(FRAMESTRATA[this:GetValue()])
	end)
	getglobal(MENU_NAME .. 'LevelText'):SetText(BAGNON_OPTIONS_STRATA)
	
	--opacity
	local alphaSlider = CreateFrame('Slider', MENU_NAME .. 'Opacity', menu, 'BagnonSlider')
	alphaSlider:SetPoint('BOTTOM', strataSlider, 'BOTTOM', 0, 40)
	alphaSlider:SetValueStep(1)
	alphaSlider:SetMinMaxValues(0, 100)
	alphaSlider:SetScript('OnValueChanged', function() 
		if not menu.onShow then SetAlpha(menu.frame, this:GetValue() / 100) end
		getglobal(this:GetName() .. 'ValText'):SetText(this:GetValue())
	end)
	getglobal(MENU_NAME .. 'OpacityText'):SetText(BAGNON_OPTIONS_OPACITY)
	getglobal(MENU_NAME .. 'OpacityLow'):SetText('0%')
	getglobal(MENU_NAME .. 'OpacityHigh'):SetText('100%')
	
	--scale
	local scaleSlider = CreateFrame('Slider', MENU_NAME .. 'Scale', menu, 'BagnonSlider')
	scaleSlider:SetPoint('BOTTOM', alphaSlider, 'BOTTOM', 0, 40)
	scaleSlider:SetValueStep(1)
	scaleSlider:SetMinMaxValues(MIN_SCALE, MAX_SCALE)
	scaleSlider:SetScript('OnValueChanged', function() 
		if not menu.onShow then SetScale(menu.frame, this:GetValue() / 100) end
		getglobal(this:GetName() .. 'ValText'):SetText(this:GetValue())
	end)
	getglobal(MENU_NAME .. 'ScaleText'):SetText(BAGNON_OPTIONS_SCALE)
	getglobal(MENU_NAME .. 'ScaleLow'):SetText(MIN_SCALE .. '%')
	getglobal(MENU_NAME .. 'ScaleHigh'):SetText(MAX_SCALE .. '%')
	
	--spacing
	local spacingSlider = CreateFrame('Slider', MENU_NAME .. 'Spacing', menu, 'BagnonSlider')
	spacingSlider:SetPoint('BOTTOM', scaleSlider, 'BOTTOM', 0, 40)
	spacingSlider:SetValueStep(1)
	spacingSlider:SetMinMaxValues(0, MAX_SPACING)
	spacingSlider:SetScript('OnValueChanged', function() 
		if not menu.onShow then SetSpacing(menu.frame, this:GetValue()) end
		getglobal(this:GetName() .. 'ValText'):SetText(this:GetValue())
	end)
	getglobal(MENU_NAME .. 'SpacingText'):SetText(BAGNON_OPTIONS_SPACING)
	getglobal(MENU_NAME .. 'SpacingLow'):SetText(0)
	getglobal(MENU_NAME .. 'SpacingHigh'):SetText(MAX_SPACING)

	--columns
	local colsSlider = CreateFrame('Slider', MENU_NAME .. 'Columns', menu, 'BagnonSlider')
	colsSlider:SetPoint('BOTTOM', spacingSlider, 'BOTTOM', 0, 40)
	colsSlider:SetValueStep(1)
	colsSlider:SetMinMaxValues(1, MAX_COLS)
	colsSlider:SetScript('OnValueChanged', function() 
		if not menu.onShow then SetCols(menu.frame, this:GetValue()) end
		getglobal(this:GetName() .. 'ValText'):SetText(this:GetValue())
	end)
	getglobal(MENU_NAME .. 'ColumnsText'):SetText(BAGNON_OPTIONS_COLUMNS)
	getglobal(MENU_NAME .. 'ColumnsLow'):SetText(1)
	getglobal(MENU_NAME .. 'ColumnsHigh'):SetText(MAX_COLS)
	
	return menu
end

--[[ Show Menu ]]--

function BagnonMenu_Show(frame)
	if not menu then
		menu = CreateMenu(MENU_NAME)
	end
	menu.frame = frame
	
	menu.onShow = 1

	getglobal(MENU_NAME .. 'Title'):SetText('Frame Settings')
	
	local sets = frame.sets

	--Set values
	getglobal(MENU_NAME .. 'Lock'):SetChecked(frame:IsLocked())
	getglobal(MENU_NAME .. 'TopLevel'):SetChecked(sets.topLevel)

	local r, g, b, a = frame:GetBackgroundColor()
	getglobal(MENU_NAME .. 'BGColorNormalTexture'):SetVertexColor(r, g, b, a)

	local cols, spacing = frame:GetLayout()
	getglobal(MENU_NAME .. 'Columns'):SetValue(cols)
	getglobal(MENU_NAME .. 'Spacing'):SetValue(spacing)
	getglobal(MENU_NAME .. 'Scale'):SetValue(frame:GetScale() * 100)
	getglobal(MENU_NAME .. 'Opacity'):SetValue(frame:GetAlpha() * 100)
	getglobal(MENU_NAME .. 'Level'):SetValue(GetFrameLevel(sets.strata))

	--a nifty thing I saw in meta map adapted for my usage
	--places the options menu at the cursor's position
	local x, y = GetCursorPosition()
	x = x / UIParent:GetScale()
	y = y / UIParent:GetScale()

	menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x - 32, y + 48)
	menu:Show()
	
	menu.onShow = nil
end