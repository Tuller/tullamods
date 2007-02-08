--[[
	settings.lua
		Variable configuration, loading, and updating
--]]

BActionConfig = {}

--show tooltips
function BActionConfig.SetTooltips(enable)
	if enable then
		BActionDB.tooltips = 1
	else
		BActionDB.tooltips = nil
	end
end

function BActionConfig.TooltipsShown()
	return BActionDB.tooltips
end

--lock button positions
function BActionConfig.SetButtonsLocked(enable)
	if enable then
		BActionDB.buttonsLocked = 1
	else
		BActionDB.buttonsLocked = nil
	end
end

function BActionConfig.ButtonsLocked()
	return BActionDB.buttonsLocked
end

--show empty buttons
function BActionConfig.SetShowGrid(enable)
	if enable then
		BActionDB.showGrid = 1
	else
		BActionDB.showGrid = nil
	end

	BActionBar.UpdateVisibilityForAll(enable)
	if UnitExists('pet') then
		BPetButton.ForAll(BPetButton.UpdateVisibility)
	end
end

function BActionConfig.ShowGrid()
	return BActionDB.showGrid
end

--show hotkeys
function BActionConfig.SetHotkeys(enable)
	if enable then
		BActionDB.hideHotkeys = nil
	else
		BActionDB.hideHotkeys = 1
	end

	BActionButton.ForAll(BActionButton.ShowHotkey, enable)
	BPetButton.ForAll(BPetButton.ShowHotkey, enable)
	BClassButton.ForAll(BClassButton.ShowHotkey, enable)
end

function BActionConfig.HotkeysShown()
	return not(BActionDB and BActionDB.hideHotkeys)
end

--show macro text
function BActionConfig.SetMacroText(enable)
	if enable then
		BActionDB.hideMacroText = nil
	else
		BActionDB.hideMacroText = 1
	end
	BActionButton.ForAll(BActionButton.ShowMacro, enable)
end

function BActionConfig.MacrosShown()
	return not BActionDB.hideMacroText
end


--[[ Actionbar Specific Settings ]]--

--set the key to pick up buttons
function BActionConfig.SetQuickMoveMode(mode)
	BActionDB.quickMove = mode
end

function BActionConfig.GetQuickMoveMode()
	return BActionDB.quickMove
end

function BActionConfig.IsQuickMoveKeyDown()
	local quickMoveKey = BActionDB.quickMove
	if quickMoveKey then
		if quickMoveKey == 1 and IsShiftKeyDown() then
			return true
		end
		if quickMoveKey == 2 and IsControlKeyDown() then
			return true
		end
		return quickMoveKey == 3 and IsAltKeyDown()
	end
end

--set range color
function BActionConfig.SetColorOutOfRange(enable)
	if enable then
		BActionDB.colorOutOfRange = 1
	else
		BActionDB.colorOutOfRange = nil
	end
	BActionButton.ForAllShown(BActionButton.UpdateUsable)
end

function BActionConfig.ColorOutOfRange()
	return BActionDB.colorOutOfRange
end

function BActionConfig.SetRangeColor(red, green, blue)
	BActionDB.rangeColor = {r = red, g = green, b = blue}
end

function BActionConfig.GetRangeColor()
	local rangeColor = BActionDB.rangeColor
	if rangeColor then
		return rangeColor.r, rangeColor.g, rangeColor.b
	end
end

--page skipping
function BActionConfig.SetPageSkip(skip)
	if skip == 0 then
		BActionDB.skip = nil
	else
		BActionDB.skip = skip
	end
	BActionButton.ForAll(BActionButton.UpdateAllPages)
end

function BActionConfig.GetPageSkip()
	return BActionDB.skip or 0
end

--targeting
function BActionConfig.SetUnit(id, unit)
	BActionDB['unit' .. id] = unit

	for i = 1, BActionBar.GetNumber() do
		BActionBar.Get(i):SetUnit(id, unit)
	end
end

function BActionConfig.GetUnit(id)
	return BActionDB['unit' .. id]
end


--[[ Startup Functions ]]--

local function LoadDefaults(currentVersion)
	BActionDB = {
		version = currentVersion,
		buttonsLocked = 1,
		tooltips = 1,
		quickMove = 1,
		colorOutOfRange = 1,
		rangeColor = {r = 1, g = 0.5, b = 0.5},
	}
end

local function UpdateSettings(version)
	BActionDB.version = version
end

Bongos.AddVarInit(function()
	local version = GetAddOnMetadata('Bongos_ActionBar', 'Version')
	if TLib.NeedToInit(BActionDB, version) then
		LoadDefaults(version)
	end

	if TLib.NeedToUpdate(BActionDB, version) then
		UpdateSettings(version)
	end
	BProfile.RegisterForSave('BActionDB')
end)