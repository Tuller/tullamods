--[[
	Sage.lua
		Driver for Sage bars
--]]

Sage = LibStub('AceAddon-3.0'):NewAddon('Sage', 'AceEvent-3.0', 'AceConsole-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale('Sage')
local CURRENT_VERSION = GetAddOnMetadata('Sage', 'Version')


--[[ Startup ]]--

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
			showMaxValues = true,
			showPvPIcons = true,
			barTexture = 'Diagonal',
			rangeCheck = true,
			frames = {}
		}
	}
end

function Sage:UpdateSettings(major, minor, bugfix)
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
		DEFAULT_CHAT_FRAME:AddMessage(format(' - |cFF33FF99%s|r: %s', cmd, desc))
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

function Sage:SetLock(enable)
	self.locked = enable or false
	if self:Locked() then
		self.Frame:ForAll('Lock')
	else
		self.Frame:ForAll('Unlock')
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

function Sage:ShowingPVPIcons()
	return self.db.profile.showPvPIcons
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