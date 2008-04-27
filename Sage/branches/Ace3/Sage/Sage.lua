--[[
	Sage.lua
		Driver for Sage frames
--]]

Sage = LibStub('AceAddon-3.0'):NewAddon('Sage', 'AceEvent-3.0', 'AceConsole-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale('Sage')
local SML = LibStub('LibSharedMedia-3.0') --shared media library

local CURRENT_VERSION = GetAddOnMetadata('Sage', 'Version')
local TEXTURE_PATH = 'Interface\\AddOns\\Sage\\textures\\%s'
local BLIZZ_TEXTURE = 'Interface/TargetingFrame/UI-StatusFrame'


--[[ Startup ]]--

function Sage:OnInitialize()
	local defaults = {
		class = {
			sticky = true,
			showCastFrames = true,
			showPercents = false,
			outlineFrameFonts = false,
			outlineOutsideFonts = false,
			debuffColoring = true,
			showMaxValues = true,
			showPvP = true,
			fontSize = 14,
			barTexture = SML:GetDefault(SML.MediaType.STATUSBAR),
			rangeCheck = true,
			frames = {}
		}
	}

	self.db = LibStub('AceDB-3.0'):New('SageDB', defaults, (UnitClass('player')))

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

	if SageVersion then
		local major, minor, build = SageVersion:match('(%w+)%.(%w+)%.(%d+)')
		local cMajor, cMinor, cBuld = CURRENT_VERSION:match('(%w+)%.(%w+)%.(%d+)')
		
		if major ~= cMajor then
			self.db:Reset()
		elseif minor ~= cMinor then
			self:UpdateSettings(major, minor)
			self:UpdateVersion()
		elseif build ~= cBuild then
			self:UpdateVersion()
		end

		--settings change
		if major ~= cMajor then
			self:UpdateSettings(major, minor)
		end
	end

	self:RegisterSlashCommands()

	--create a loader for the options menu
	local f = CreateFrame('Frame', nil, InterfaceOptionsFrame)
	f:SetScript('OnShow', function(self)
		self:SetScript('OnShow', nil)
		LoadAddOn('Sage_Options')
	end)
end

function Sage:OnEnable()
	self:LoadModules()
end

function Sage:UpdateSettings(major, minor)
	--update settingsamagig
end

function Sage:UpdateVersion()
	SageVersion = CURRENT_VERSION
	self:Print(format(L.Updated, SageVersion))
end

function Sage:LoadModules()
	for name, module in self:IterateModules() do
		if module.Load then
			module:Load(self.isNewProfile)
		end
	end

	self.Frame:ForAll('Reanchor')
	self.newProfile = nil
end

function Sage:UnloadModules()
	for name, module in self:IterateModules() do
		if module.Unload then
			module:Unload()
		end
	end
end


--[[ Profile Functions ]]--

function Sage:SaveProfile(name)
	local toCopy = self.db:GetCurrentProfile()
	if name and name ~= toCopy then
		self:UnloadModules()
		self.db:SetProfile(name)
		self.db:CopyProfile(toCopy)
		self.isNewProfile = nil
		self:LoadModules()
	end
end

function Sage:SetProfile(name)
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

function Sage:DeleteProfile(name)
	local profile = self:MatchProfile(name)
	if profile and profile ~= self.db:GetCurrentProfile() then
		self.db:DeleteProfile(profile)
	else
		self:Print(L.CantDeleteCurrentProfile)
	end
end

function Sage:CopyProfile(name)
	if name and name ~= self.db:GetCurrentProfile() then
		self:UnloadModules()
		self.db:CopyProfile(name)
		self.isNewProfile = nil
		self:LoadModules()
	end
end

function Sage:ResetProfile()
	self:UnloadModules()
	self.db:ResetProfile()
	self.isNewProfile = true
	self:LoadModules()
end

function Sage:ListProfiles()
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

function Sage:MatchProfile(name)
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

function Sage:OnNewProfile(profileName)
	self.isNewProfile = true
	self:Print('Created Profile: ' .. profileName)
end

function Sage:OnProfileDeleted(profileName)
	self:Print('Deleted Profile: ' .. profileName)
end

function Sage:OnProfileChanged(newProfileName)
	self:Print('Changed Profile: ' .. newProfileName)
end

function Sage:OnProfileCopied(sourceProfile)
	self:Print('Copied Profile: ' .. sourceProfile)
end

function Sage:OnProfileReset()
	self:Print('Reset Profile: ' .. self.db:GetCurrentProfile())
end

function Sage:UpdateVersion()
	SageVersion = CURRENT_VERSION
	self:Print(format(L.Updated, SageVersion))
end


--[[ Slash Commands ]]--

function Sage:RegisterSlashCommands()
	self:RegisterChatCommand('sage', 'OnCmd')
	self:RegisterChatCommand('sg', 'OnCmd')
end

function Sage:OnCmd(args)
	local cmd = string.split(' ', args):lower() or args:lower()

	if cmd == 'lock' then
		self:ToggleLockedFrames()
	elseif cmd == 'sticky' then
		self:ToggleStickyFrames()
	elseif cmd == 'scale' then
		self:ScaleFrames(select(2, string.split(' ', args)))
	elseif cmd == 'setalpha' then
		self:SetOpacityForFrames(select(2, string.split(' ', args)))
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

function Sage:ToggleLockedFrames()
	self:SetLock(not self:IsLocked())
end

function Sage:ToggleStickyFrames()
	self:SetSticky(not self.db.profile.sticky)
end

function Sage:ScaleFrames(...)
	local numArgs = select('#', ...)
	local scale = tonumber(select(numArgs, ...))

	if scale and scale > 0 and scale <= 10 then
		for i = 1, numArgs - 1 do
			self.Frame:ForFrame(select(i, ...), 'SetFrameScale', scale)
		end
	end
end

function Sage:SetOpacityForFrames(...)
	local numArgs = select('#', ...)
	local alpha = tonumber(select(numArgs, ...))

	if alpha and alpha >= 0 and alpha <= 1 then
		for i = 1, numArgs - 1 do
			self.Frame:ForFrame(select(i, ...), 'SetFrameAlpha', alpha)
		end
	end
end

function Sage:Cleanup()
	local frames = self.db.profile.frames
	for id in pairs(frames) do
		if not self.Frame:Get(id) then
			frames[id] = nil
		end
	end
end

function Sage::PrintVersion()
	self:Print(SageVersion)
end

function Sage:PrintHelp(cmd)
	local function PrintCmd(cmd, desc)
		DEFAULT_CHAT_FRAME:AddMessage(format(' - |cFF33FF99%s|r: %s', cmd, desc))
	end

	self:Print('Commands (/sage or /sg)')
	PrintCmd('lock', L.LockDesc)
	PrintCmd('sticky', L.StickyFramesDesc)
	PrintCmd('scale <frameList> <scale>', L.SetScaleDesc)
	PrintCmd('setalpha <frameList> <opacity>', L.SetAlphaDesc)
	PrintCmd('save <profile>', L.SaveDesc)
	PrintCmd('set <profile>', L.SetDesc)
	PrintCmd('copy <profile>', L.CopyDesc)
	PrintCmd('delete <profile>', L.DeleteDesc)
	PrintCmd('reset', L.ResetDesc)
	PrintCmd('list', L.ListDesc)
	PrintCmd('version', L.PrintVersionDesc)
end

function Sage:ShowOptions()
	if LoadAddOn('Sage_Options') then
		InterfaceOptionsFrame_OpenToFrame('Sage')
		return true
	end
	return nil
end


--[[ Settings Access ]]--

function Sage:SetFrameSets(id, sets)
	local id = tonumber(id) or id
	self.db.profile.frames[id] = sets

	return self.db.profile.frames[id]
end

function Sage:GetFrameSets(id)
	return self.db.profile.frames[tonumber(id) or id]
end

function Sage:GetFrames()
	return pairs(self.db.profile.frames)
end


--[[ Utility Functions ]]--

--utility function: create a widget class
function Sage:CreateWidgetClass(type, parentClass)
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



--[[ Event Actions ]]--

function Sage:RegisterEvents()
	self:RegisterEvent('ADDON_LOADED', 'LoadOptions')

	self:RegisterEvent('UNIT_HEALTH', 'UpdateHealth')
	self:RegisterEvent('UNIT_MAXHEALTH', 'UpdateHealth')
	self:RegisterEvent('UNIT_HAPPINESS')

	self:RegisterEvent('UNIT_AURA', 'UpdateBuff')

	self:RegisterEvent('UNIT_FACTION', 'UpdateInfo')
	self:RegisterEvent('UNIT_NAME_UPDATE', 'UpdateInfo')
	self:RegisterEvent('UNIT_LEVEL', 'UpdateInfo')
	self:RegisterEvent('RAID_TARGET_UPDATE', 'UpdateInfo')

	self:RegisterEvent('PARTY_LEADER_CHANGED', 'UpdateInfo')
	self:RegisterEvent('PARTY_LOOT_METHOD_CHANGED', 'UpdateInfo')
	self:RegisterEvent('PARTY_MEMBERS_CHANGED', 'UpdateInfo')

	self:SetShowCastFrames(self:ShowingCastFrames())
end

function Sage:UpdateHealth(event, ...)
	SageHealth:OnEvent(...)
	if self:ShowingPercents() then
		SageInfo:OnHealthEvent(...)
	end
end

function Sage:UNIT_HAPPINESS()
	SageHealth:OnHappyEvent()
end

function Sage:UpdateBuff(event, ...)
	SageBuff:OnEvent(...)
	SageHealth:OnBuffEvent(...)
end

function Sage:UpdateInfo(event, ...)
	SageInfo[event](SageInfo, ...)
end

function Sage:UpdateCast(event, ...)
	SageCast[event](SageCast, ...)
end


--[[ Config Functions ]]--

--access
function Sage:SetFrameSets(id, sets)
	local id = tonumber(id) or id
	self.profile.frames[id] = sets
	return self.profile.frames[id]
end

function Sage:GetFrameSets(id)
	return self.profile.frames[tonumber(id) or id]
end

--lock frame positions
function Sage:SetLock(enable)
	self.profile.locked = enable or false
	SageFrame:ForAll((enable and 'Lock') or 'Unlock')
end

function Sage:IsLocked()
	return self.profile.locked
end

function Sage:ToggleLock()
	self:SetLock(not self:IsLocked())
end

--auto docking frames
function Sage:SetSticky(enable)
	self.profile.sticky = enable or false
	SageFrame:ForAll('Reanchor')
end

function Sage:IsSticky()
	return self.profile.sticky
end

function Sage:ToggleSticky()
	self:SetSticky(not self:IsSticky())
end

--bar textures
function Sage:SetFrameTexture(texture)
	self.profile.barTexture = texture
--	self.StatusBar:UpdateTextures()
end

function Sage:GetFrameTexture()
	return SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.barTexture)
end

--font size
function Sage:SetFontSize(size)
	self.profile.fontSize = size
	self.font:Update()
	SageFont:Update()
end

function Sage:GetFontSize()
	return self.profile.fontSize or DEFAULT_FONT_SIZE
end

--outline statusbar fonts
function Sage:SetOutlineFrameFonts(enable)
	self.profile.outlineFrameFonts = enable or false
	SageFont:UpdateFrameFonts()
end

function Sage:OutlineFrameFonts()
	return self.profile.outlineFrameFonts
end

--outline outside fonts
function Sage:SetOutlineOutsideFonts(enable)
	self.profile.outlineOutsideFonts = enable or false
	SageFont:UpdateOutsideFonts()
end

function Sage:OutlineOutsideFonts()
	return self.profile.outlineOutsideFonts
end

--color healthframes when debuffed
function Sage:SetDebuffColoring(enable)
	self.profile.debuffColoring = enable or false
	SageHealth:ForAll('UpdateDebuff')
end

function Sage:DebuffColoring()
	return self.profile.debuffColoring
end

--health percentages
function Sage:SetShowPercents(enable)
	self.profile.showPercents = enable or false
	SageInfo:ForAll('UpdatePercents')
end

function Sage:ShowingPercents()
	return self.profile.showPercents
end

--cast frames
function Sage:SetShowCastFrames(enable)
	self.profile.showCastFrames = enable or false

	if enable then
		self:RegisterEvent('UNIT_SPELLCAST_START', 'UpdateCast')
		self:RegisterEvent('UNIT_SPELLCAST_DELAYED', 'UpdateCast')
		self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START', 'UpdateCast')
		self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_UPDATE', 'UpdateCast')
		self:RegisterEvent('UNIT_SPELLCAST_STOP', 'UpdateCast')
		self:RegisterEvent('UNIT_SPELLCAST_FAILED', 'UpdateCast')
		self:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED', 'UpdateCast')
		self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP', 'UpdateCast')
	else
		self:UnregisterEvent('UNIT_SPELLCAST_START')
		self:UnregisterEvent('UNIT_SPELLCAST_DELAYED')
		self:UnregisterEvent('UNIT_SPELLCAST_CHANNEL_START')
		self:UnregisterEvent('UNIT_SPELLCAST_CHANNEL_UPDATE')
		self:UnregisterEvent('UNIT_SPELLCAST_STOP')
		self:UnregisterEvent('UNIT_SPELLCAST_FAILED')
		self:UnregisterEvent('UNIT_SPELLCAST_INTERRUPTED')
		self:UnregisterEvent('UNIT_SPELLCAST_CHANNEL_STOP')
	end
	SageCast:ForAll('Update')
end

function Sage:ShowingCastFrames()
	return self.profile.showCastFrames
end

function Sage:SetShowMaxValues(enable)
	self.profile.showMaxValues = enable or false
	SageFrame:UpdateAll()
end

function Sage:ShowingMaxValues()
	return self.profile.showMaxValues
end

--show pvp icons
function Sage:SetShowPvP(enable)
	self.profile.showPvP = enable or false
	SageInfo:ForAll('UpdatePvP')
end

function Sage:ShowingPvP()
	return self.profile.showPvP
end


--[[ Per Unit Settings ]]--

function Sage:GetUnitSetting(unit, setting)
	local sets = self:GetFrameSets((unit == 'party' and 'party1') or unit)
	return sets and sets[setting]
end

--show curable debuffs
function Sage:SetShowCurable(unit, enable)
	SageFrame:ForFrame(unit, 'SetShowCurable', enable)
end

function Sage:ShowingCurable(unit)
	return self:GetUnitSetting(unit, 'showCurable')
end

--show castable buffs
function Sage:SetShowCastable(unit, enable)
	SageFrame:ForFrame(unit, 'SetShowCastable', enable)
end

function Sage:ShowingCastable(unit)
	return self:GetUnitSetting(unit, 'showCastable')
end

--frame opacity
function Sage:SetOpacity(unit, alpha)
	SageFrame:ForFrame(unit, 'SetFrameAlpha', alpha)
end

function Sage:GetOpacity(unit)
	return self:GetUnitSetting(unit, 'alpha') or 1
end

--frame scale
function Sage:SetScale(unit, scale)
	SageFrame:ForFrame(unit, 'SetFrameScale', scale)
end

function Sage:GetScale(unit)
	return self:GetUnitSetting(unit, 'scale') or 1
end

--frame width
function Sage:SetWidth(unit, width)
	SageFrame:ForFrame(unit, 'SetFrameWidth', width)
end

function Sage:GetWidth(unit)
	return self:GetUnitSetting(unit, 'width') or 0
end

--show castable buffs
function Sage:SetShowCombatText(unit, enable)
	SageFrame:ForFrame(unit, 'SetShowCombatText', enable)
end

function Sage:ShowingCombatText(unit)
	return self:GetUnitSetting(unit, 'showCombatText')
end

--text display mode
function Sage:SetTextMode(unit, mode)
	SageFrame:ForFrame(unit, 'SetTextMode', mode)
end

function Sage:GetTextMode(unit)
	return self:GetUnitSetting(unit, 'textMode') or 1
end