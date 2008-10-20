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
			showPercents = false,
			outlineBarFonts = false,
			outlineOutsideFonts = false,
			debuffColoring = true,
			showMaxValues = true,
			showPvP = true,
			fontSize = 14,
			barTexture = 'Armory2',
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
		module:Load()
	end

	--anchor everything
	self.Frame:ForAll('Reanchor')
end

--unload is called when we're switching profiles
function Sage:Unload()
	for _,module in self:IterateModules() do
		module:Unload()
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


--[[ Slash Commands ]]--

function Sage:OnCmd(args)
	--do something
end



--[[ The one true class thingy ]]--

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


--[[ Settings...Setting ]]--

function Sage:SetFrameSets(id, sets)
	local id = tonumber(id) or id
	self.db.profile.frames[id] = sets

	return self.db.profile.frames[id]
end

function Sage:GetFrameSets(id)
	return self.db.profile.frames[tonumber(id) or id]
end


--[[ Config Functions ]]--

Sage.locked = false

function Sage:SetLock(enable)
	self.locked = enable or false
end

function Sage:Locked()
	return self.locked
end

function Sage:SetSticky(enable)
	self.db.profile.sticky = enable or false
end

function Sage:Sticky()
	return self.db.profile.sticky
end