--[[
	BongosMainBar.lua
		Driver Module for Bongos_ActionBar
--]]

BongosActionConfig = {}

--[[ Config ]]--

--show tooltips
function BongosActionConfig:ShowTooltips(enable)
	if enable then
		Bongos.profile.showTooltips = true
	else
		Bongos.profile.showTooltips = false
	end
end

function BongosActionConfig:ShowingTooltips()
	return Bongos.profile.showTooltips
end

--lock button positions
function BongosActionConfig:LockButtons(enable)
	if enable then
		Bongos.profile.lockButtons = true
	else
		Bongos.profile.lockButtons = false
	end
end

function BongosActionConfig:ButtonsLocked()
	return Bongos.profile.lockButtons
end

--show empty buttons
function BongosActionConfig:ShowEmptyButtons(enable)
	if enable then
		Bongos.profile.showEmpty = true
	else
		Bongos.profile.showEmpty = false
	end

	BongosActionButton:ForAll("UpdateVisibility")
	if UnitExists("pet") then
		BongosPetButton:ForAll("UpdateVisibility")
	end
end

function BongosActionConfig:ShowingEmptyButtons()
	return Bongos.profile.showEmpty
end

--show hotkeys
function BongosActionConfig:ShowHotkeys(enable)
	if enable then
		Bongos.profile.showHotkeys = true
	else
		Bongos.profile.showHotkeys = false
	end

	BongosActionButton:ForAll("ShowHotkey", enable)
	BongosPetButton:ForAll("ShowHotkey", enable)
	BongosClassButton:ForAll("ShowHotkey", enable)
end

function BongosActionConfig:ShowingHotkeys()
	return Bongos.profile.showHotkeys
end


--[[ Actionbar Specific ]]--

--show macro text
function BongosActionConfig:ShowMacros(enable)
	if enable then
		Bongos.profile.showMacros = true
	else
		Bongos.profile.showMacros = false
	end
	BongosActionButton:ForAll("ShowMacro", enable)
end

function BongosActionConfig:ShowingMacros()
	return Bongos.profile.showMacros
end

--set the key to pick up buttons
function BongosActionConfig:SetQuickMoveMode(mode)
	Bongos.profile.quickMoveKey = mode
end

function BongosActionConfig:GetQuickMoveMode()
	return Bongos.profile.quickMoveKey
end

function BongosActionConfig:IsQuickMoveKeyDown()
	local quickMoveKey = self.profile.quickMoveKey
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
function BongosActionConfig:SetRangeColoring(enable)
	if enable then
		Bongos.profile.rangeColoring = true
	else
		Bongos.profile.rangeColoring = false
	end
	BongosActionButton:ForAllShown("UpdateUsuable")
end

function BongosActionConfig:RangeColoring()
	return Bongos.profile.rangeColoring
end

function BongosActionConfig:SetRangeColor(red, green, blue)
	Bongos.profile.rangeColor = {r = red, g = green, b = blue}
end

function BongosActionConfig:GetRangeColor()
	local rangeColor = Bongos.profile.rangeColor
	if rangeColor then
		return rangeColor.r, rangeColor.g, rangeColor.b
	end
end

function BongosActionConfig:GetRightClickUnit()
	Bongos.profile.rightClickUnit
end