--[[
	BongosMainBar.lua
		Driver Module for Bongos_ActionBar
--]]

BongosActionConfig = {}

--[[ Config ]]--

--show tooltips
function BongosActionConfig:ShowTooltips(enable)
	Bongos.profile.showTooltips = enable or false
end

function BongosActionConfig:ShowingTooltips()
	return Bongos.profile.showTooltips
end

--lock button positions
function BongosActionConfig:LockButtons(enable)
	Bongos.profile.lockButtons = enable or false
end

function BongosActionConfig:ButtonsLocked()
	return Bongos.profile.lockButtons
end

--show empty buttons
function BongosActionConfig:ShowEmptyButtons(enable)
	Bongos.profile.showEmpty = enable or false
	BongosActionBar:UpdateVisibility()
end

function BongosActionConfig:ShowingEmptyButtons()
	return Bongos.profile.showEmpty
end

--show hotkeys
function BongosActionConfig:ShowHotkeys(enable)
	Bongos.profile.showHotkeys = enable or false
	BongosActionButton:ForAll('ShowHotkey', enable)
	BongosPetButton:ForAll('ShowHotkey', enable)
	BongosClassButton:ForAll('ShowHotkey', enable)
end

function BongosActionConfig:ShowingHotkeys()
	return Bongos.profile.showHotkeys
end


--[[ Actionbar Specific ]]--

--show macro text
function BongosActionConfig:ShowMacros(enable)
	Bongos.profile.showMacros = enable or false
	BongosActionButton:ForAll('ShowMacro', enable)
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
	local quickMoveKey = Bongos.profile.quickMoveKey
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
	Bongos.profile.rangeColoring = enable or false
	BongosActionButton:ForAll('UpdateUsable')
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

function BongosActionConfig:SetRightClickUnit(unit)
	Bongos.profile.rightClickUnit = unit
	for i = 1, BongosActionBar:GetNumber() do
		BBar:Get(i):SetRightClickUnit(unit)
	end
end

function BongosActionConfig:GetRightClickUnit()
	return Bongos.profile.rightClickUnit
end

function BongosActionConfig:SetSelfCastKey(key)
	SetActionSelfCastKey(key)
	Bongos.profile.selfCastKey = key
end

function BongosActionConfig:GetSelfCastKey()
	return Bongos.profile.selfCastKey
end

function BongosActionConfig:SetHighlightBuffs(enable)
	Bongos.profile.highlightBuffs = enable
	BongosActionButton:ForAll('UpdateState')
end

function BongosActionConfig:HighlightingBuffs()
	return Bongos.profile.highlightBuffs
end