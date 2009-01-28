--[[
	Sage.lua
		Driver for Sage bars
--]]

Sage = LibStub('AceAddon-3.0'):NewAddon('Sage', 'AceEvent-3.0', 'AceConsole-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale('Sage')
local CURRENT_VERSION = GetAddOnMetadata('Sage', 'Version')

--[[ Startup ]]--

function Sage:OnInitialize()
	--register database events
	self.db = LibStub('AceDB-3.0'):New('SageDB', self:GetDefaults(), UnitClass('player'))
	self.db.RegisterCallback(self, 'OnNewProfile')
	self.db.RegisterCallback(self, 'OnProfileChanged')
	self.db.RegisterCallback(self, 'OnProfileCopied')
	self.db.RegisterCallback(self, 'OnProfileReset')
	self.db.RegisterCallback(self, 'OnProfileDeleted')

	--version update
	if SageVersion then
		if SageVersion ~= CURRENT_VERSION then
			self:UpdateSettings(SageVersion:match('(%w+)%.(%w+)%.(%w+)'))
			self:UpdateVersion()
		end
	--new user
	else
		SageVersion = CURRENT_VERSION
	end

	--slash command support
	self:RegisterSlashCommands()

	--create a loader for the options menu
	local f = CreateFrame('Frame', nil, InterfaceOptionsFrame)
	f:SetScript('OnShow', function(self)
		self:SetScript('OnShow', nil)
		LoadAddOn('Sage_Config')
		
		for _,module in Sage:IterateModules() do
			if module.LoadOptions then
				module:LoadOptions()
			end
		end
	end)
end

function Sage:OnEnable()
	self:Load()
end

--[[ Version Updating ]]--

function Sage:GetDefaults()
	return  {
		profile = {
			locked = true,
			sticky = true,
			showCastBars = true,
			debuffColoring = true,
			colorHealthByClass = false,
			showMaxValues = true,
			showPvPIcons = true,
			texture = 'Diagonal',
			rangeCheck = true,
			frames = {}
		}
	}
end

function Sage:UpdateSettings(major, minor, bugfix)
	--any version < 3.1 is poop
	if major == '3' and minor < '4' then
		self.db:Reset()
	end
	--do stuff
end

function Sage:UpdateVersion()
	SageVersion = CURRENT_VERSION
	self:Print(format(L.Updated, SageVersion))
end


--[[ Module Loading ]]--

function Sage:Load()
	for _,module in self:IterateModules() do
		module:OnLoad()
	end

	--anchor everything
	self.Frame:ForAll('Reanchor')
end

--unload is called when we're switching profiles
function Sage:Unload()
	for _,module in self:IterateModules() do
		module:OnUnload()
	end
end

function Sage:RegisterSlashCommands()
	self:RegisterChatCommand('sage', 'OnCmd')
	self:RegisterChatCommand('sg', 'OnCmd')
end



--[[ Profile Functions ]]--

function Sage:SaveProfile(name)
	local toCopy = self.db:GetCurrentProfile()
	if name and name ~= toCopy then
		self:Unload()
		self.db:SetProfile(name)
		self.db:CopyProfile(toCopy)
		self.isNewProfile = nil
		self:Load()
	end
end

function Sage:SetProfile(name)
	local profile = self:MatchProfile(name)
	if profile and profile ~= self.db:GetCurrentProfile() then
		self:Unload()
		self.db:SetProfile(profile)
		self.isNewProfile = nil
		self:Load()
	else
		self:Print(format(L.InvalidProfile, name or 'nil'))
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
		self:Unload()
		self.db:CopyProfile(name)
		self.isNewProfile = nil
		self:Load()
	end
end

function Sage:ResetProfile()
	self:Unload()
	self.db:ResetProfile()
	self.isNewProfile = true
	self:Load()
end

function Sage:ListProfiles()
	self:Print(L.AvailableProfiles)

	local current = self.db:GetCurrentProfile()
	for _,k in ipairs(self.db:GetProfiles()) do
		if k == current then
			print(' - ' .. k, 1, 1, 0)
		else
			print(' - ' .. k)
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

function Sage:OnNewProfile(msg, db, name)
	self.isNewProfile = true
	self:Print(format(L.ProfileCreated, name))
end

function Sage:OnProfileDeleted(msg, db, name)
	self:Print(format(L.ProfileDeleted, name))
end

function Sage:OnProfileChanged(msg, db, name)
	self:Print(format(L.ProfileLoaded, name))
end

function Sage:OnProfileCopied(msg, db, name)
	self:Print(format(L.ProfileCopied, name))
end

function Sage:OnProfileReset(msg, db)
	self:Print(format(L.ProfileReset, db:GetCurrentProfile()))
end


--[[
	Slash Commands
--]]

function Sage:OnCmd(args)
	local cmd = string.split(' ', args):lower() or args:lower()

	--frame functions
	if cmd == 'config' or cmd == 'lock' then
		self:ToggleLockedFrames()
	elseif cmd == 'scale' then
		self:ScaleFrames(select(2, string.split(' ', args)))
	elseif cmd == 'setalpha' then
		self:SetOpacityForFrames(select(2, string.split(' ', args)))
	--profile functions
	elseif cmd == 'save' then
		local name = string.join(' ', select(2, string.split(' ', args)))
		self:SaveProfile(name)
	elseif cmd == 'set' then
		local name = string.join(' ', select(2, string.split(' ', args)))
		self:SetProfile(name)
	elseif cmd == 'copy' then
		local name = string.join(' ', select(2, string.split(' ', args)))
		self:CopyProfile(name)
	elseif cmd == 'delete' then
		local name = string.join(' ', select(2, string.split(' ', args)))
		self:DeleteProfile(name)
	elseif cmd == 'reset' then
		self:ResetProfile()
	elseif cmd == 'list' then
		self:ListProfiles()
	elseif cmd == 'version' then
		self:PrintVersion()
	elseif cmd == 'help' or cmd == '?' then
		self:PrintHelp()
	--options stuff
	else
		if not self:ShowOptions() then
			self:PrintHelp()
		end
	end
end

function Sage:ShowOptions()
	if LoadAddOn('Sage_Config') then
		InterfaceOptionsFrame_OpenToCategory(self.Options)
		return true
	end
	return false
end

function Sage:PrintHelp(cmd)
	local function PrintCmd(cmd, desc)
		print(format(' - |cFF33FF99%s|r: %s', cmd, desc))
	end

	self:Print('Commands (/sg, /sage)')
	PrintCmd('config', L.ConfigDesc)
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


--version info
function Sage:PrintVersion()
	self:Print(SageVersion)
end


--[[
	Configuration Functions
--]]

--config mode toggle
Sage.locked = true

local function CreateConfigHelperDialog()
	local f = CreateFrame('Frame', 'SageConfigHelperDialog', UIParent)
	f:SetFrameStrata('DIALOG')
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetClampedToScreen(true)
	f:SetWidth(360)
	f:SetHeight(120)
	f:SetBackdrop{
		bgFile='Interface\\DialogFrame\\UI-DialogBox-Background' ,
		edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',
		tile = true,
		insets = {left = 11, right = 12, top = 12, bottom = 11},
		tileSize = 32,
		edgeSize = 32,
	}
	f:SetPoint('TOP', 0, -24)
	f:Hide()
	f:SetScript('OnShow', function() PlaySound('igMainMenuOption') end)
	f:SetScript('OnHide', function() PlaySound('gsTitleOptionExit') end)

	local tr = f:CreateTitleRegion()
	tr:SetAllPoints(f)

	local header = f:CreateTexture(nil, 'ARTWORK')
	header:SetTexture('Interface\\DialogFrame\\UI-DialogBox-Header')
	header:SetWidth(326); header:SetHeight(64)
	header:SetPoint('TOP', 0, 12)

	local title = f:CreateFontString('ARTWORK')
	title:SetFontObject('GameFontNormal')
	title:SetPoint('TOP', header, 'TOP', 0, -14)
	title:SetText(L.ConfigMode)

	local desc = f:CreateFontString('ARTWORK')
	desc:SetFontObject('GameFontHighlight')
	desc:SetJustifyV('TOP')
	desc:SetJustifyH('LEFT')
	desc:SetPoint('TOPLEFT', 18, -32)
	desc:SetPoint('BOTTOMRIGHT', -18, 48)
	desc:SetText(L.ConfigModeHelp)

	local exitConfig = CreateFrame('CheckButton', f:GetName() .. 'ExitConfig', f, 'OptionsButtonTemplate')
	_G[exitConfig:GetName() .. 'Text']:SetText(EXIT)
	exitConfig:SetScript('OnClick', function() Sage:SetLock(true) end)
	exitConfig:SetPoint('BOTTOMRIGHT', -14, 14)

	return f
end

function Sage:ShowConfigHelper()
	if not self.configHelper then
		self.configHelper = CreateConfigHelperDialog()
	end
	self.configHelper:Show()
end

function Sage:HideConfigHelper()
	if self.configHelper then
		self.configHelper:Hide()
	end
end

function Sage:SetLock(enable)
	self.locked = enable or false
	self.DragFrame:ForAll('UpdateVisibility')

	if self:Locked() then
		self:HideConfigHelper()
	else
		self:ShowConfigHelper()
	end
end

function Sage:Locked()
	return self.locked
end

function Sage:ToggleLockedFrames()
	self:SetLock(not self:Locked())
end


--sticky bars
function Sage:SetSticky(enable)
	self.db.profile.sticky = enable or false
	if not enable then
		self.Frame:ForAll('Stick')
		self.Frame:ForAll('Reposition')
	end
end

function Sage:Sticky()
	return self.db.profile.sticky
end


--scale
function Sage:ScaleFrames(...)
	local numArgs = select('#', ...)
	local scale = tonumber(select(numArgs, ...))

	if scale and scale > 0 and scale <= 10 then
		for i = 1, numArgs - 1 do
			self.Frame:ForFrame(select(i, ...), 'SetFrameScale', scale)
		end
	end
end


--opacity
function Sage:SetOpacityForFrames(...)
	local numArgs = select('#', ...)
	local alpha = tonumber(select(numArgs, ...))

	if alpha and alpha >= 0 and alpha <= 1 then
		for i = 1, numArgs - 1 do
			self.Frame:ForFrame(select(i, ...), 'SetFrameAlpha', alpha)
		end
	end
end


--status bar textures
function Sage:SetStatusBarTexture(texture)
	self.db.profile.texture = texture
	self:UpdateStatusBarTexture()
end

function Sage:GetStatusBarTexture()
	return LibStub('LibSharedMedia-3.0'):Fetch('statusbar', self.db.profile.texture)
end

function Sage:UpdateStatusBarTexture()
	self.StatusBar:ForAll('UpdateTexture', self:GetStatusBarTexture())
end


--pvp icon display
function Sage:ShowPVPIcons(enable)
	self.db.profile.showPvPIcons = enable or false
	self.InfoBar:ForAllVisible('UpdatePvP')
end

function Sage:ShowingPVPIcons()
	return self.db.profile.showPvPIcons
end


--healthbar coloring
function Sage:SetColorHealthByClass(enable)
	self.db.profile.colorHealthByClass = enable or false
	self.HealthBar:ForAllShown('UpdateAll')
end

function Sage:ColorHealthByClass()
	return self.db.profile.colorHealthByClass
end

--debuff coloring
function Sage:SetColorHealthByDebuff(enable)
	self.db.profile.debuffColoring = enable or false
	self.HealthBar:ForAllShown('UpdateAll')
end

function Sage:ColorHealthByDebuff()
	return self.db.profile.debuffColoring
end


--[[ Utility Methods ]]--

function Sage:CreateClass(type, parentClass)
	local class = CreateFrame(type)
	class.mt = {__index = class}

	if parentClass then
		class = setmetatable(class, {__index = parentClass})
		class.super = parentClass
	end

	function class:Bind(o)
		return setmetatable(o, self.mt)
	end

	return class
end

function Sage:SetFrameSets(id, sets)
	self.db.profile.frames[id] = sets
	return self.db.profile.frames[id]
end

function Sage:GetFrameSets(id)
	return self.db.profile.frames[id]
end


--[[ Stock Frame unregistration  - Code shamelessly stolen from oUF ]]--

local noop = function() end
function Sage:UnregisterUnitFrame(name)
	if not _G[name] then return end

	_G[name]:UnregisterAllEvents()
	_G[name]:Hide()
	_G[name].Show = noop

	_G[name..'HealthBar']:UnregisterAllEvents()
	_G[name..'ManaBar']:UnregisterAllEvents()
	if _G[name .. 'SpellBar'] then
		_G[name .. 'SpellBar']:UnregisterAllEvents()
	end
end

function Sage:UnregisterUnit(unit)
	if unit == 'player' then
		self:UnregisterUnitFrame('PlayerFrame')
	elseif unit == 'pet' then
		self:UnregisterUnitFrame('PetFrame')
	elseif unit == 'target' then
		self:UnregisterUnitFrame('TargetFrame')
		_G['ComboFrame']:UnregisterAllEvents()
		_G['ComboFrame']:Hide()
	elseif unit == 'focus' then
		self:UnregisterUnitFrame('FocusFrame')
	elseif unit == 'targettarget' then
		self:UnregisterUnitFrame('TargetOfTargetFrame')
	elseif unit:match('party(%d+)') then
		self:UnregisterUnitFrame('PartyMemberFrame' .. unit:match('party(%d+)'))
	end
end