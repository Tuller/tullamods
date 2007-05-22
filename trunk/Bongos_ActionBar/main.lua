--[[
	BongosMainBar.lua
		Driver Module for Bongos_ActionBar
--]]

BongosActionMain = Bongos:NewModule("Bongos-ActionMain")
local CURRENT_VERSION = GetAddOnMetadata("Bongos2_ActionBar", "Version")


--[[ startup / shutdown ]]--

function BongosActionMain:Initialize()
	local defaults = {
		profile = {
			lockButtons = true,
			showTooltips = true,
			showHotkeys = true,
			showMacros = true,
			rangeColoring = true,
			showEmpty = false,
			showHotkeys = false,
			rangeColor = {r = 1, g = 0.5, b = 0.5},
			quickMoveKey = 1,
			version = CURRENT_VERSION,
		}
	}

	self.db = self:InitializeDB("Bongos2ActionBarDB", defaults)
	self.profile = self.db.profile

	local cMajor, cMinor = CURRENT_VERSION:match("(%d+)%.(%d+)")
	local major, minor = self.profile.version:match("(%d+)%.(%d+)")

	if major ~= cMajor then
		self.db:ResetProfile()
--		self:Print(L.UpdatedIncompatible)
	elseif minor ~= cMinor then
		self:UpdateSettings()
	end
end

function BongosActionMain:UpdateVersion()
	self.db:ResetProfile()
	self.profile.version = CURRENT_VERSION
--	self:Print(format(L.Updated, self.profile.version))
end

function BongosActionMain:Load()
	for name, module in self:IterateModules() do
		assert(module.Load, format("%s: Missing Load function", name))
		module:Load()
	end
end

function BongosActionMain:Unload()
	for name, module in self:IterateModules() do
		assert(module.Unload, format("%s: Missing Unload function", name))
		module:Unload()
	end
end


--[[ Config ]]--

--show tooltips
function BongosActionMain:ShowTooltips(enable)
	if enable then
		self.profile.showTooltips = true
	else
		self.profile.showTooltips = false
	end
end

function BongosActionMain:ShowingTooltips()
	return self.profile.showTooltips
end

--lock button positions
function BongosActionMain:LockButtons(enable)
	if enable then
		self.profile.lockButtons = true
	else
		self.profile.lockButtons = false
	end
end

function BongosActionMain:ButtonsLocked()
	return self.profile.lockButtons
end

--show empty buttons
function BongosActionMain:ShowEmptyButtons(enable)
	if enable then
		self.profile.showEmpty = true
	else
		self.profile.showEmpty = false
	end

	BongosActionButton:ForAll("UpdateVisibility")
	if UnitExists("pet") then
		BongosPetButton:ForAll("UpdateVisibility")
	end
end

function BongosActionMain:ShowingEmptyButtons()
	return self.profile.showEmpty
end

--show hotkeys
function BongosActionMain:ShowHotkeys(enable)
	if enable then
		self.profile.showHotkeys = true
	else
		self.profile.showHotkeys = false
	end

	BongosActionButton:ForAll("ShowHotkey", enable)
	BongosPetButton:ForAll("ShowHotkey", enable)
	BongosClassButton:ForAll("ShowHotkey", enable)
end

function BongosActionMain:ShowingHotkeys()
	return self.profile.showHotkeys
end


--[[ Actionbar Specific ]]--

--show macro text
function BongosActionMain:ShowMacros(enable)
	if enable then
		self.profile.showMacros = true
	else
		self.profile.showMacros = false
	end
	BongosActionButton:ForAll("ShowMacro", enable)
end

function BongosActionMain:ShowingMacros()
	return self.profile.showMacros
end

--set the key to pick up buttons
function BongosActionMain:SetQuickMoveMode(mode)
	self.profile.quickMoveKey = mode
end

function BongosActionMain:GetQuickMoveMode()
	return self.profile.quickMoveKey
end

function BongosActionMain:IsQuickMoveKeyDown()
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
function BongosActionMain:SetRangeColoring(enable)
	if enable then
		self.profile.rangeColoring = true
	else
		self.profile.rangeColoring = false
	end
	BongosActionButton:ForAllShown("UpdateUsuable")
end

function BongosActionMain:RangeColoring()
	return self.profile.rangeColoring
end

function BongosActionMain:SetRangeColor(red, green, blue)
	self.profile.rangeColor = {r = red, g = green, b = blue}
end

function BongosActionMain:GetRangeColor()
	local rangeColor = self.profile.rangeColor
	if rangeColor then
		return rangeColor.r, rangeColor.g, rangeColor.b
	end
end