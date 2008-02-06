--[[
	Bongos.lua
		Driver for bongos bars
--]]

local Bongos = LibStub('AceAddon-3.0'):NewAddon('Bongos3', 'AceEvent-3.0', 'AceConsole-3.0')
Bongos3 = Bongos
Bongos.dbName = 'Bongos3DB'

local CURRENT_VERSION = GetAddOnMetadata('Bongos', 'Version') .. '.' .. ('$Rev$'):match('%d+')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3')


--[[ Startup ]]--

function Bongos:OnEnable()
	local defaults = {
		profile = {
			sticky = true,
			showMinimap = true,
			bars = {},
		}
	}

	self.db = LibStub('AceDB-3.0'):New(self.dbName, defaults)
	self.profile = self.db.profile

	if Bongos3Version then
		local cMinor = GetAddOnMetadata('Bongos', 'Version')
		local minor = Bongos3Version:match('(%d+).')

		--settings change
		if minor ~= cMinor then
			self:UpdateSettings()
		end
	end

	--version update
	if Bongos3Version ~= CURRENT_VERSION then
		self:UpdateVersion()
	end

	self:LoadModules()
	self:RegisterSlashCommands()
end

function Bongos:UpdateSettings()
end

function Bongos:UpdateVersion()
	Bongos3Version = CURRENT_VERSION
	self:Print(L.Updated:format(Bongos3Version))
end

function Bongos:LoadModules()
	for name, module in self:IterateModules() do
		assert(module.Load, format('Bongos Module %s: Missing Load function', name))
		module:Load()
	end
	Bongos:UpdateMinimapButton()
	self.Bar:ForAll('Reanchor')
end

function Bongos:UnloadModules()
	for name, module in self:IterateModules() do
		assert(module.Unload, format('Bongos Module %s: Missing Unload function', name))
		module:Unload()
	end
end

function Bongos:LoadOptions(event, addon)
	if addon == 'Bongos_Options' then
		for name, module in self:IterateModules() do
			if module.LoadOptions then
				module:LoadOptions()
			end
		end
		self.Options:ShowPanel(L.General)
		self:UnregisterEvent(event)
	end
end


--[[ Profile Functions ]]--

function Bongos:SaveProfile(profile)
	local currentProfile = self.db:GetCurrentProfile()
	if profile and profile ~= self.db:GetCurrentProfile() then
		self:UnloadModules()
		self.copying = true
		self.db:SetProfile(profile)
		self.db:CopyProfile(currentProfile)
		self.copying = nil
	end
end

function Bongos:SetProfile(name)
	local profile = self:MatchProfile(name)
	if profile and profile ~= self.db:GetCurrentProfile() then
		self:UnloadModules()
		self.db:SetProfile(profile)
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
	local profile = self:MatchProfile(name)
	if profile and profile ~= self.db:GetCurrentProfile() then
		self:UnloadModules()
		self.copying = true
		self.db:ResetProfile()
		self.db:CopyProfile(profile)
		self.copying = nil
	end
end

function Bongos:ResetProfile()
	self:UnloadModules()
	self.db:ResetProfile()
end

function Bongos:ListProfiles()
	self:Print(L.AvailableProfiles)
	for _,k in ipairs(self.db:GetProfiles()) do
		DEFAULT_CHAT_FRAME:AddMessage(" - " .. k)
	end
end

function Bongos:MatchProfile(name)
	local profileList = self.db:GetProfiles()

	local name = name:lower()
	local nameRealm = name .. ' - ' .. GetRealmName():lower()
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

-- function Bongos:DONGLE_PROFILE_CREATED(event, db, parent, sv_name, profile_key)
	-- if(sv_name == self.dbName) then
		-- self.profile = self.db.profile
		-- db.version = CURRENT_VERSION
		-- self:Print(format(L.ProfileCreated , profile_key))
	-- end
-- end

-- function Bongos:DONGLE_PROFILE_CHANGED(event, db, parent, sv_name, profile_key)
	-- if(sv_name == self.dbName) then
		-- self.profile = self.db.profile
		-- if not self.copying then
			-- self:LoadModules()
			-- self:Print(format(L.ProfileLoaded, profile_key))
		-- end
	-- end
-- end

-- function Bongos:DONGLE_PROFILE_DELETED(event, db, parent, sv_name, profile_key)
	-- if(sv_name == self.dbName) then
		-- self:Print(format(L.ProfileDeleted, profile_key))
	-- end
-- end

-- function Bongos:DONGLE_PROFILE_COPIED(event, db, parent, sv_name, profile_key, intoProfile_key)
	-- if(sv_name == self.dbName) then
		-- self.profile = self.db.profile
		-- self:LoadModules()
		-- self:Print(format(L.ProfileCopied, profile_key, intoProfile_key))
	-- end
-- end

-- function Bongos:DONGLE_PROFILE_RESET(event, db, parent, sv_name, profile_key)
	-- if(sv_name == self.dbName) then
		-- if not self.copying then
			-- self.profile = self.db.profile
			-- self:LoadModules()
			-- self:Print(format(L.ProfileReset, profile_key))
		-- end
	-- end
-- end


--[[ Config Functions ]]--

function Bongos:SetLock(enable)
	self.profile.locked = enable or false
	if enable then
		self.Bar:ForAll('Lock')
	else
		self.Bar:ForAll('Unlock')
	end
end

function Bongos:IsLocked()
	return self.profile.locked
end

function Bongos:SetSticky(enable)
	self.profile.sticky = enable or false
	self.Bar:ForAll('Reanchor')
end

function Bongos:IsSticky()
	return self.profile.sticky
end


--[[ Settings Access ]]--

function Bongos:SetBarSets(id, sets)
	local id = tonumber(id) or id
	self.profile.bars[id] = sets

	return self.profile.bars[id]
end

function Bongos:GetBarSets(id)
	return self.profile.bars[tonumber(id) or id]
end


--[[ Slash Commands ]]--

function Bongos:RegisterSlashCommands()
	self:RegisterChatCommand('bongos', 'OnCmd')
	self:RegisterChatCommand('bob', 'OnCmd')
	self:RegisterChatCommand('bgs', 'OnCmd')
	self:RegisterChatCommand('bg3', 'OnCmd')
end

function Bongos:OnCmd(args)
	local cmd = string.split(' ', args):lower()

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
		self:SaveProfile(select(2, string.split(' ', args)))
	elseif cmd == 'set' then
		self:SetProfile(select(2, string.split(' ', args)))
	elseif cmd == 'copy' then
		self:CopyProfile(select(2, string.split(' ', args)))
	elseif cmd == 'delete' then
		self:DeleteProfile(select(2, string.split(' ', args)))
	elseif cmd == 'reset' then
		self:ResetProfile()
	elseif cmd == 'list' then
		self:ListProfiles()
	elseif cmd == 'version' then
		self:PrintVersion()
	elseif cmd == 'cleanup' then
		self:Cleanup()
	elseif cmd == 'options' or cmd == '' then
		self:ToggleOptionsMenu()
	else
		self:PrintHelp()
	end
end

function Bongos:ToggleOptionsMenu()
	local enabled = select(4, GetAddOnInfo('Bongos_Options'))
	if enabled then
		if self.Options then
			self.Options:Toggle()
		else
			LoadAddOn('Bongos_Options')
		end
	else
		self:PrintHelp()
	end
end

function Bongos:ToggleLockedBars()
	self:SetLock(not self.profile.locked)
end

function Bongos:ToggleStickyBars()
	self:SetSticky(not self.profile.sticky)
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
	local bars = self.profile.bars
	for id in pairs(self.profile.bars) do
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
	PrintCmd('/bongos', L.ShowOptionsDesc)
	PrintCmd('lock', L.LockBarsDesc)
	PrintCmd('sticky', L.StickyBarsDesc)
	PrintCmd('scale <barList> <scale>', L.SetScaleDesc)
	PrintCmd('setalpha <barList> <opacity>', L.SetAlphaDesc)
	PrintCmd('setfade <barList> <opacity>', L.SetFadeDesc)
	PrintCmd('show <barList>', L.ShowBarsDesc)
	PrintCmd('hide <barList>', L.HideBarsDesc)
	PrintCmd('toggle <barList>', L.ToggleBarsDesc)
	PrintCmd('save <barList>', L.SaveDesc)
	PrintCmd('set <barList>', L.SetDesc)
	PrintCmd('copy <barList>', L.CopyDesc)
	PrintCmd('delete <barList>', L.DeleteDesc)
	PrintCmd('reset', L.ResetDesc)
	PrintCmd('list', L.ListDesc)
	PrintCmd('version', L.PrintVersionDesc)
end


--minimap functions
function Bongos:SetShowMinimap(enable)
	self.profile.showMinimap = enable or false
	self:UpdateMinimapButton()
end

function Bongos:ShowingMinimap()
	return self.profile.showMinimap
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
	self.profile.minimapPos = angle
end

function Bongos:GetMinimapButtonPosition(angle)
	return self.profile.minimapPos
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