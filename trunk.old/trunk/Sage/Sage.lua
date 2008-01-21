--[[
	Sage.lua
		Driver for Sage bars
--]]

Sage = DongleStub('Dongle-1.0'):New('Sage')
Sage.dbName = 'Sage2DB'

local CURRENT_VERSION = GetAddOnMetadata('Sage', 'Version')
local TEXTURE_PATH = 'Interface\\AddOns\\Sage\\textures\\%s'
local BLIZZ_TEXTURE = 'Interface/TargetingFrame/UI-StatusBar'
local L = SAGE_LOCALS


--[[ Startup ]]--

function Sage:Enable()
	local defaults = {
		profile = {
			locked = true,
			sticky = true,
			showCastBars = true,
			showPercents = false,
			outlineBarFonts = false,
			outlineOutsideFonts = false,
			debuffColoring = true,
			showMaxValues = true,
			showPvP = true,
			fontSize = 14,
			barTexture = 'Armory2',
			rangeSpell = L.RangeCheckSpells[select(2, UnitClass('player'))],
			rangeCheck = true,
			frames = {}
		}
	}

	self.db = self:InitializeDB(self.dbName, defaults, 'Default')
	self.profile = self.db.profile

	if(not SageVersion) then
		self:UpdateSettings()
	else
		local cMajor, cMinor = CURRENT_VERSION:match('(%w+)%.(%w+)')
		local major, minor = SageVersion:match('(%w+)%.(%w+)')

		if major ~= cMajor then
			self.db:ResetDB('Default')
			self.profile = self.db.profile
			self:Print(L.UpdatedIncompatible)
		elseif minor ~= cMinor then
			self:UpdateSettings()
		end
	end
	if SageVersion ~= CURRENT_VERSION then
		self:UpdateVersion()
	end

	self:RegisterEvents()
	self:RegisterSlashCommands()
	self:LoadModules()

	self:RegisterMessage('DONGLE_PROFILE_CREATED')
	self:RegisterMessage('DONGLE_PROFILE_CHANGED')
	self:RegisterMessage('DONGLE_PROFILE_DELETED')
	self:RegisterMessage('DONGLE_PROFILE_COPIED')
	self:RegisterMessage('DONGLE_PROFILE_RESET')
end

function Sage:UpdateSettings()
end

function Sage:UpdateVersion()
	SageVersion = CURRENT_VERSION
	self:Print(format(L.Updated, SageVersion))
end

function Sage:LoadModules()
	SageFont:Update()
	for name, module in self:IterateModules() do
		assert(module.Load, format('Sage Module %s: Missing Load function', name))
		module:Load()
	end
	SageFrame:ForAll('Reanchor')
	self:SetShowPercents(self:ShowingPercents())
end

function Sage:UnloadModules()
	for name, module in self:IterateModules() do
		assert(module.Unload, format('Sage Module %s: Missing Unload function', name))
		module:Unload()
	end
end

function Sage:RegisterEvents()
	self:RegisterEvent('ADDON_LOADED', 'LoadOptions')

	self:RegisterEvent('UNIT_HEALTH', 'UpdateHealth')
	self:RegisterEvent('UNIT_MAXHEALTH', 'UpdateHealth')

	self:RegisterEvent('UNIT_MANA', 'UpdateMana')
	self:RegisterEvent('UNIT_RAGE', 'UpdateMana')
	self:RegisterEvent('UNIT_FOCUS', 'UpdateMana')
	self:RegisterEvent('UNIT_ENERGY', 'UpdateMana')
	self:RegisterEvent('UNIT_MAXMANA', 'UpdateMana')
	self:RegisterEvent('UNIT_MAXRAGE', 'UpdateMana')
	self:RegisterEvent('UNIT_MAXFOCUS', 'UpdateMana')
	self:RegisterEvent('UNIT_MAXENERGY', 'UpdateMana')
	self:RegisterEvent('UNIT_DISPLAYPOWER', 'UpdateMana')

	self:RegisterEvent('UNIT_AURA', 'UpdateBuff')

	self:RegisterEvent('UNIT_FACTION', 'UpdateInfo')
	self:RegisterEvent('UNIT_NAME_UPDATE', 'UpdateInfo')
	self:RegisterEvent('UNIT_LEVEL', 'UpdateInfo')
	self:RegisterEvent('RAID_TARGET_UPDATE', 'UpdateInfo')

	self:RegisterEvent('PARTY_LEADER_CHANGED', 'UpdateInfo')
	self:RegisterEvent('PARTY_LOOT_METHOD_CHANGED', 'UpdateInfo')
	self:RegisterEvent('PARTY_MEMBERS_CHANGED', 'UpdateInfo')

	self:SetShowCastBars(self:ShowingCastBars())
end


--[[ Event Actions ]]--

function Sage:LoadOptions(event, addon)
	if(addon == 'Sage_Options') then
		for name, module in self:IterateModules() do
			if(module.LoadOptions) then
				module:LoadOptions()
			end
		end
		SageOptions:ShowPanel('General')
	end
end

function Sage:UpdateHealth(event, ...)
	SageHealth:OnEvent(...)
	if self:ShowingPercents() then
		SageInfo:OnHealthEvent(...)
	end
end

function Sage:UpdateMana(event, ...)
	SageMana:OnEvent(...)
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


--[[ Profile Functions ]]--

function Sage:SaveProfile(profile)
	local currentProfile = self.db:GetCurrentProfile()
	if profile and profile ~= self.db:GetCurrentProfile() then
		self:UnloadModules()
		self.copying = true
		self.db:SetProfile(profile)
		self.db:CopyProfile(currentProfile)
		self.copying = nil
	end
end

function Sage:SetProfile(name)
	local profile = self:MatchProfile(name)
	if profile and profile ~= self.db:GetCurrentProfile() then
		self:UnloadModules()
		self.db:SetProfile(profile)
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
	local profile = self:MatchProfile(name)
	if profile and profile ~= self.db:GetCurrentProfile() then
		self:UnloadModules()
		self.copying = true
		self.db:ResetProfile()
		self.db:CopyProfile(profile)
		self.copying = nil
	end
end

function Sage:ResetProfile()
	self:UnloadModules()
	self.db:ResetProfile()
end

function Sage:ListProfiles()
	self:Print(L.AvailableProfiles)
	for _,k in ipairs(self.db:GetProfiles()) do
		DEFAULT_CHAT_FRAME:AddMessage(' - ' .. k)
	end
end

function Sage:MatchProfile(name)
	local profileList = self.db:GetProfiles()

	local name = name:lower()
	local nameRealm = format('%s - %s', name, GetRealmName():lower())
	local match

	for i, k in ipairs(profileList) do
		local key = k:lower()
		if key == name then
			return k
		elseif key == nameRealm then
			match = k
		end
	end
	return match
end


--[[ Messages ]]--

function Sage:DONGLE_PROFILE_CREATED(event, db, parent, sv_name, profile_key)
	if(sv_name == self.dbName) then
		self.profile = self.db.profile
		db.version = CURRENT_VERSION
		self:Print(format(L.ProfileCreated , profile_key))
	end
end

function Sage:DONGLE_PROFILE_CHANGED(event, db, parent, sv_name, profile_key)
	if(sv_name == self.dbName) then
		self.profile = self.db.profile
		if not self.copying then
			self:LoadModules()
			self:Print(format(L.ProfileLoaded, profile_key))
		end
	end
end

function Sage:DONGLE_PROFILE_DELETED(event, db, parent, sv_name, profile_key)
	if(sv_name == self.dbName) then
		self:Print(format(L.ProfileDeleted, profile_key))
	end
end

function Sage:DONGLE_PROFILE_COPIED(event, db, parent, sv_name, profile_key, intoProfile_key)
	if(sv_name == self.dbName) then
		self.profile = self.db.profile
		self:LoadModules()
		self:Print(format(L.ProfileCopied, profile_key, intoProfile_key))
	end
end

function Sage:DONGLE_PROFILE_RESET(event, db, parent, sv_name, profile_key)
	if(sv_name == self.dbName) then
		if not self.copying then
			self.profile = self.db.profile
			self:LoadModules()
			self:Print(format(L.ProfileReset, profile_key))
		end
	end
end


--[[ Slash Commands ]]--

function Sage:RegisterSlashCommands()
	local cmdStr = '|cFF33FF99%s|r: %s'

	local slash = self:InitializeSlashCommand('Sage Commands', 'SAGE', 'sage', 'sg')
	slash:RegisterSlashHandler(format(cmdStr, '/sage', 'Toggles the option menu'), '^$', 'ShowMenu')
	slash:RegisterSlashHandler(format(cmdStr, 'lock', L.LockFramesDesc), '^lock$', 'ToggleLock')
	slash:RegisterSlashHandler(format(cmdStr, 'sticky', L.StickyFramesDesc), '^sticky$', 'ToggleSticky')

	slash:RegisterSlashHandler(format(cmdStr, 'scale <frameList> <scale>', L.SetScaleDesc), '^scale (.+) ([%d%.]+)', 'SetFrameScale')
	slash:RegisterSlashHandler(format(cmdStr, 'setalpha <frameList> <opacity>', L.SetAlphaDesc), '^setalpha (.+) ([%d%.]+)', 'SetFrameAlpha')
	slash:RegisterSlashHandler(format(cmdStr, 'texture <texture>', 'Sets the statusbar texture'), '^texture (.+)', 'SetBarTexture')

	slash:RegisterSlashHandler(format(cmdStr, 'save <profle>', L.SaveDesc), 'save (%w+)', 'SaveProfile')
	slash:RegisterSlashHandler(format(cmdStr, 'set <profle>', L.SetDesc), 'set (%w+)', 'SetProfile')
	slash:RegisterSlashHandler(format(cmdStr, 'copy <profile>', L.CopyDesc), 'copy (%w+)', 'CopyProfile')
	slash:RegisterSlashHandler(format(cmdStr, 'delete <profile>', L.DeleteDesc), '^delete (%w+)', 'DeleteProfile')
	slash:RegisterSlashHandler(format(cmdStr, 'reset', L.ResetDesc), '^reset$', 'ResetProfile')
	slash:RegisterSlashHandler(format(cmdStr, 'list', L.ListDesc), '^list$', 'ListProfiles')
	slash:RegisterSlashHandler(format(cmdStr, 'version', L.PrintVersionDesc), '^version$', 'PrintVersion')

	self.slash = slash
end

function Sage:PrintVersion()
	self:Print(SageVersion)
end

function Sage:ShowMenu()
	local enabled = select(4, GetAddOnInfo('Sage_Options'))
	if enabled then
		if SageOptions then
			SageOptions:Toggle()
		else
			LoadAddOn('Sage_Options')
		end
	else
		self.slash:PrintUsage()
	end
end

function Sage:SetFrameScale(args, scale)
	local scale = tonumber(scale)
	if scale and scale > 0 and scale <= 10 then
		for _,frameList in pairs({strsplit(' ', args)}) do
			SageFrame:ForFrame(frameList, 'SetFrameScale', scale)
		end
	end
end

function Sage:SetFrameAlpha(args, alpha)
	local alpha = tonumber(alpha)
	if alpha and alpha >= 0 and alpha <= 1 then
		for _,frameList in pairs({strsplit(' ', args)}) do
			SageFrame:ForFrame(frameList, 'SetFrameAlpha', alpha)
		end
	end
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

--auto docking bars
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
function Sage:SetBarTexture(texture)
	self.profile.barTexture = texture
	SageBar:UpdateAllTextures()
end

function Sage:GetBarTexture(texID)
	local texID = texID or (self.profile.barTexture or 'blizzard')

	if(AceLibrary) then
		local SML = AceLibrary:HasInstance('SharedMedia-1.0') and AceLibrary('SharedMedia-1.0')
		if(SML) then
			local texture = SML:Fetch('statusbar', texID, true)
			if(texture) then
				return texture
			end
		end
	end
	return (texID:lower() == 'blizzard' and BLIZZ_TEXTURE) or format(TEXTURE_PATH, texID)
end

--font size
function Sage:SetFontSize(size)
	self.profile.fontSize = size
	SageFont:Update()
end

function Sage:GetFontSize()
	return self.profile.fontSize or DEFAULT_FONT_SIZE
end

--outline statusbar fonts
function Sage:SetOutlineBarFonts(enable)
	self.profile.outlineBarFonts = enable or false
	SageFont:UpdateBarFonts()
end

function Sage:OutlineBarFonts()
	return self.profile.outlineBarFonts
end

--outline outside fonts
function Sage:SetOutlineOutsideFonts(enable)
	self.profile.outlineOutsideFonts = enable or false
	SageFont:UpdateOutsideFonts()
end

function Sage:OutlineOutsideFonts()
	return self.profile.outlineOutsideFonts
end

--color healthbars when debuffed
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

--cast bars
function Sage:SetShowCastBars(enable)
	self.profile.showCastBars = enable or false
	if(enable) then
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

function Sage:ShowingCastBars()
	return self.profile.showCastBars
end

function Sage:SetShowMaxValues(enable)
	self.profile.showMaxValues = enable or false
	SageBar:UpdateAll()
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