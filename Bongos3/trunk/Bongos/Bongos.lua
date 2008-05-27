--[[
	Bongos.lua
		Driver for bongos bars
--]]

local Bongos = LibStub('AceAddon-3.0'):NewAddon('Bongos3', 'AceEvent-3.0', 'AceConsole-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3')
local CURRENT_VERSION = GetAddOnMetadata('Bongos', 'Version')
Bongos3 = Bongos


--[[ Startup ]]--

function Bongos:OnInitialize()
	local defaults = {
		profile = {
			sticky = true,
			showMinimap = true,
			bars = {},
		}
	}

	--register database events
	self.db = LibStub('AceDB-3.0'):New('Bongos3DB', defaults)

	self.db:RegisterCallback('OnNewProfile', function(msg, db, ...)
		self:OnNewProfile(...)
	end)
	self.db:RegisterCallback('OnProfileChanged', function(msg, db, ...)
		self:OnProfileChanged(...)
	end)
	self.db:RegisterCallback('OnProfileCopied', function(msg, db, ...)
		self:OnProfileCopied(...)
	end)
	self.db:RegisterCallback('OnProfileReset', function(msg, db, ...)
		self:OnProfileReset(...)
	end)
	self.db:RegisterCallback('OnProfileDeleted', function(msg, db, ...)
		self:OnProfileDeleted(...)
	end)

	--version update
	if Bongos3Version then
		local major, minor = Bongos3Version:match('(%w+)%.(%w+)')
		local cMajor, cMinor = CURRENT_VERSION:match('(%w+)%.(%w+)')

		--settings change
		if major ~= cMajor then
			self:UpdateSettings(major, minor)
		elseif minor ~= cMinor then
			self:UpdateVersion()
		end
	else
		Bongos3Version = CURRENT_VERSION
	end

	self.lockBG = self:CreateLockBG()
	self:RegisterSlashCommands()

	--create a loader for the options menu
	local f = CreateFrame('Frame', nil, InterfaceOptionsFrame)
	f:SetScript('OnShow', function(self)
		self:SetScript('OnShow', nil)
		LoadAddOn('Bongos_Options')
	end)
end

function Bongos:OnEnable()
	self:LoadModules()
end

function Bongos:UpdateSettings(major, minor)
	--keybinding reset for Beta.7 and under versions
	if major == 'Beta' and tonumber(minor) < 8 then
		for _,profile in pairs(Bongos3DB.profiles) do
			for _,sets in pairs(profile.bars) do
				sets.bindings = nil
			end
		end
	end
	self:UpdateVersion()
end

function Bongos:UpdateVersion()
	Bongos3Version = CURRENT_VERSION
	self:Print(format(L.Updated, Bongos3Version))
end

function Bongos:LoadModules()
	for name, module in self:IterateModules() do
		if module.Load then
			module:Load(self.isNewProfile)
		end
	end

	self:UpdateMinimapButton()
	self.Bar:ForAll('Reanchor')
	self.newProfile = nil
end

function Bongos:UnloadModules()
	for name, module in self:IterateModules() do
		if module.Unload then
			module:Unload()
		end
	end
end


--[[ Profile Functions ]]--

function Bongos:SaveProfile(name)
	local toCopy = self.db:GetCurrentProfile()
	if name and name ~= toCopy then
		self:UnloadModules()
		self.db:SetProfile(name)
		self.db:CopyProfile(toCopy)
		self.isNewProfile = nil
		self:LoadModules()
	end
end

function Bongos:SetProfile(name)
	local profile = self:MatchProfile(name)
	if profile and profile ~= self.db:GetCurrentProfile() then
		self:UnloadModules()
		self.db:SetProfile(profile)
		self.isNewProfile = nil
		self:LoadModules()
	else
		self:Print(format(L.InvalidProfile, name or 'null'))
	end
end

function Bongos:DeleteProfile(name)
	local profile = self:MatchProfile(name)
	if profile and profile ~= self.db:GetCurrentProfile() then
		self.db:DeleteProfile(profile)
	else
		self:Print(L.CantDeleteCurrentProfile)
	end
end

function Bongos:CopyProfile(name)
	if name and name ~= self.db:GetCurrentProfile() then
		self:UnloadModules()
		self.db:CopyProfile(name)
		self.isNewProfile = nil
		self:LoadModules()
	end
end

function Bongos:ResetProfile()
	self:UnloadModules()
	self.db:ResetProfile()
	self.isNewProfile = true
	self:LoadModules()
end

function Bongos:ListProfiles()
	self:Print(L.AvailableProfiles)
	local current = self.db:GetCurrentProfile()
	for _,k in ipairs(self.db:GetProfiles()) do
		if k == current then
			DEFAULT_CHAT_FRAME:AddMessage(' - ' .. k, 1, 1, 0)
		else
			DEFAULT_CHAT_FRAME:AddMessage(' - ' .. k)
		end
	end
end

function Bongos:MatchProfile(name)
	local name = name:lower()
	local nameRealm = name .. ' - ' .. GetRealmName():lower()
	local match

	for i, k in ipairs(self.db:GetProfiles()) do
		local key = k:lower()
		if key == name then
			return k
		elseif key == nameRealm then
			match = k
		end
	end
	return match
end


--[[ Profile Events ]]--

function Bongos:OnNewProfile(profileName)
	self.isNewProfile = true
	self:Print('Created Profile: ' .. profileName)
end

function Bongos:OnProfileDeleted(profileName)
	self:Print('Deleted Profile: ' .. profileName)
end

function Bongos:OnProfileChanged(newProfileName)
	self:Print('Changed Profile: ' .. newProfileName)
end

function Bongos:OnProfileCopied(sourceProfile)
	self:Print('Copied Profile: ' .. sourceProfile)
end

function Bongos:OnProfileReset()
	self:Print('Reset Profile: ' .. self.db:GetCurrentProfile())
end


--[[ Config Functions ]]--

Bongos.locked = true

function Bongos:CreateLockBG()
	local f = CreateFrame('Frame', nil, UIParent)
	f:SetFrameStrata('BACKGROUND')
	f:SetFrameLevel(0)
	f:SetAllPoints(f:GetParent())
	f:Hide()

	--create the background
	f.bg = f:CreateTexture()
	f.bg:SetTexture(0, 0, 0, 0.5)
	f.bg:SetAllPoints(f)

	return f
end

function Bongos:SetLock(enable)
	self.locked = enable or nil
	if self.locked then
		self.Bar:ForAll('Lock')
		self.lockBG:Hide()
		self:SendMessage('BONGOS_LOCK_ENABLE')
	else
		self.Bar:ForAll('Unlock')
		self.lockBG:Show()
		self:SendMessage('BONGOS_LOCK_DISABLE')
	end
end

function Bongos:IsLocked()
	return self.locked
end

function Bongos:SetSticky(enable)
	self.db.profile.sticky = enable or false
	if not enable then
		self.Bar:ForAll('Stick')
	end
end

function Bongos:IsSticky()
	return self.db.profile.sticky
end


--[[ Settings Access ]]--

function Bongos:SetBarSets(id, sets)
	local id = tonumber(id) or id
	self.db.profile.bars[id] = sets

	return self.db.profile.bars[id]
end

function Bongos:GetBarSets(id)
	return self.db.profile.bars[tonumber(id) or id]
end

function Bongos:GetBars()
	return pairs(self.db.profile.bars)
end


--[[ Slash Commands ]]--

function Bongos:RegisterSlashCommands()
	self:RegisterChatCommand('bongos', 'OnCmd')
	self:RegisterChatCommand('bob', 'OnCmd')
	self:RegisterChatCommand('bgs', 'OnCmd')
	self:RegisterChatCommand('bg3', 'OnCmd')
end

function Bongos:OnCmd(args)
	local cmd = string.split(' ', args):lower() or args:lower()

	if cmd == 'config' or cmd == 'lock' then
		self:ToggleLockedBars()
	elseif cmd == 'sticky' then
		self:ToggleStickyBars()
	elseif cmd == 'scale' then
		self:ScaleBars(select(2, string.split(' ', args)))
	elseif cmd == 'setalpha' then
		self:SetOpacityForBars(select(2, string.split(' ', args)))
	elseif cmd == 'setfade' then
		self:SetFadeForBars(select(2, string.split(' ', args)))
	elseif cmd == 'show' then
		self:ShowBars(select(2, string.split(' ', args)))
	elseif cmd == 'hide' then
		self:HideBars(select(2, string.split(' ', args)))
	elseif cmd == 'toggle' then
		self:ToggleBars(select(2, string.split(' ', args)))
	elseif cmd == 'save' then
		local profileName = string.join(' ', select(2, string.split(' ', args)))
		self:SaveProfile(profileName)
	elseif cmd == 'set' then
		local profileName = string.join(' ', select(2, string.split(' ', args)))
		self:SetProfile(profileName)
	elseif cmd == 'copy' then
		local profileName = string.join(' ', select(2, string.split(' ', args)))
		self:CopyProfile(profileName)
	elseif cmd == 'delete' then
		local profileName = string.join(' ', select(2, string.split(' ', args)))
		self:DeleteProfile(profileName)
	elseif cmd == 'reset' then
		self:ResetProfile()
	elseif cmd == 'list' then
		self:ListProfiles()
	elseif cmd == 'version' then
		self:PrintVersion()
	elseif cmd == 'cleanup' then
		self:Cleanup()
	elseif cmd == 'help' or cmd == '?' then
		self:PrintHelp()
	else
		if not self:ShowOptions() then
			self:PrintHelp()
		end
	end
end

function Bongos:ToggleLockedBars()
	self:SetLock(not self:IsLocked())
end

function Bongos:ToggleStickyBars()
	self:SetSticky(not self.db.profile.sticky)
end

function Bongos:ScaleBars(...)
	local numArgs = select('#', ...)
	local scale = tonumber(select(numArgs, ...))

	if scale and scale > 0 and scale <= 10 then
		for i = 1, numArgs - 1 do
			self.Bar:ForBar(select(i, ...), 'SetFrameScale', scale)
		end
	end
end

function Bongos:SetOpacityForBars(...)
	local numArgs = select('#', ...)
	local alpha = tonumber(select(numArgs, ...))

	if alpha and alpha >= 0 and alpha <= 1 then
		for i = 1, numArgs - 1 do
			self.Bar:ForBar(select(i, ...), 'SetFrameAlpha', alpha)
		end
	end
end

function Bongos:SetFadeForBars(...)
	local numArgs = select('#', ...)
	local alpha = tonumber(select(numArgs, ...))

	if alpha and alpha >= 0 and alpha <= 1 then
		for i = 1, numArgs - 1 do
			self.Bar:ForBar(select(i, ...), 'SetFadeAlpha', alpha)
		end
	end
end

function Bongos:ShowBars(...)
	for i = 1, select('#', ...) do
		self.Bar:ForBar(select(i, ...), 'ShowFrame')
	end
end

function Bongos:HideBars(...)
	for i = 1, select('#', ...) do
		self.Bar:ForBar(select(i, ...), 'HideFrame')
	end
end

function Bongos:ToggleBars(...)
	for i = 1, select('#', ...) do
		self.Bar:ForBar(select(i, ...), 'ToggleFrame')
	end
end

function Bongos:Cleanup()
	local bars = self.db.profile.bars
	for id in pairs(bars) do
		if not self.Bar:Get(id) then
			bars[id] = nil
		end
	end
end

function Bongos:PrintVersion()
	self:Print(Bongos3Version)
end

function Bongos:PrintHelp(cmd)
	local function PrintCmd(cmd, desc)
		DEFAULT_CHAT_FRAME:AddMessage(format(' - |cFF33FF99%s|r: %s', cmd, desc))
	end

	self:Print('Commands (/bongos, /bob, or /bgs)')
	PrintCmd('config', L.ConfigDesc)
	PrintCmd('sticky', L.StickyBarsDesc)
	PrintCmd('scale <barList> <scale>', L.SetScaleDesc)
	PrintCmd('setalpha <barList> <opacity>', L.SetAlphaDesc)
	PrintCmd('setfade <barList> <opacity>', L.SetFadeDesc)
	PrintCmd('show <barList>', L.ShowBarsDesc)
	PrintCmd('hide <barList>', L.HideBarsDesc)
	PrintCmd('toggle <barList>', L.ToggleBarsDesc)
	PrintCmd('save <profile>', L.SaveDesc)
	PrintCmd('set <profile>', L.SetDesc)
	PrintCmd('copy <profile>', L.CopyDesc)
	PrintCmd('delete <profile>', L.DeleteDesc)
	PrintCmd('reset', L.ResetDesc)
	PrintCmd('list', L.ListDesc)
	PrintCmd('version', L.PrintVersionDesc)
end


--minimap functions
function Bongos:SetShowMinimap(enable)
	self.db.profile.showMinimap = enable or false
	self:UpdateMinimapButton()
end

function Bongos:ShowingMinimap()
	return self.db.profile.showMinimap
end

function Bongos:UpdateMinimapButton()
	if self:ShowingMinimap() then
		self.Minimap:UpdatePosition()
		self.Minimap:Show()
	else
		self.Minimap:Hide()
	end
end

function Bongos:SetMinimapButtonPosition(angle)
	self.db.profile.minimapPos = angle
end

function Bongos:GetMinimapButtonPosition(angle)
	return self.db.profile.minimapPos
end

function Bongos:ShowOptions()
	if LoadAddOn('Bongos_Options') then
		InterfaceOptionsFrame_OpenToFrame('Bongos')
		return true
	end
	return false
end

--utility function: create a widget class
function Bongos:CreateWidgetClass(type, parentClass)
	local class = CreateFrame(type)
	class.mt = {__index = class}

	if parentClass then
		class = setmetatable(class, {__index = parentClass})
		class.super = parentClass
	end

	function class:New(o)
		if o then
			local type, cType = o:GetFrameType(), self:GetFrameType()
			assert(type == cType, format("'%s' expected, got '%s'", cType, type))
		end
		return setmetatable(o or CreateFrame(type), self.mt)
	end

	return class
end