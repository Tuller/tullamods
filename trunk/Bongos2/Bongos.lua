--[[
	Bongos.lua
		Driver for bongos bars
--]]

Bongos = DongleStub("Dongle-1.0"):New("Bongos")
local CURRENT_VERSION = GetAddOnMetadata("Bongos2", "Version")
local L = BONGOS_LOCALS
L.SetFadeAlphaDesc = "Sets opacity when faded for <barList>"
L.SetFadeModeDesc = "Sets when to automatically fade out <barList>. 0: never; 1: inCombat; 2: outOfCombat"


--[[ Startup ]]--

function Bongos:Initialize()
	self:RegisterMessage('DONGLE_PROFILE_CREATED')
	self:RegisterMessage('DONGLE_PROFILE_CHANGED')
	self:RegisterMessage('DONGLE_PROFILE_DELETED')
	self:RegisterMessage('DONGLE_PROFILE_COPIED')
	self:RegisterMessage('DONGLE_PROFILE_RESET')

	local defaults = {
		profile = {
			version = CURRENT_VERSION,
			sticky = true,
			bars = {}
		}
	}

	self.db = self:InitializeDB("Bongos2DB", defaults)
	self.profile = self.db.profile

	local cMajor, cMinor = CURRENT_VERSION:match("(%d+)%.(%d+)")
	local major, minor = self.profile.version:match("(%d+)%.(%d+)")

	if major ~= cMajor then
		self.db:ResetProfile()
		self:Print(L.UpdatedIncompatible)
	elseif minor ~= cMinor then
		self:UpdateSettings()
	end

	self:RegisterSlashCommands()
end

function Bongos:Enable()
	self:LoadModules()
end

function Bongos:UpdateVersion()
	self.profile.version = CURRENT_VERSION
	self:Print(format(L.Updated, self.profile.version))
end

function Bongos:LoadModules()
	for name, module in self:IterateModules() do
		assert(module.Load, format('Bongos Module %s: Missing Load function', name))
		module:Load()
	end
	BBar:ForAll('Reanchor')
end

function Bongos:UnloadModules()
	for name, module in self:IterateModules() do
		assert(module.Unload, format('Bongos Module %s: Missing Unload function', name))
		module:Unload()
	end
end


--[[ Profile Functions ]]--

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
	end
end

function Bongos:CopyProfile(name)
	local profile = self:MatchProfile(name)
	if profile and profile ~= self.db:GetCurrentProfile() then
		self:UnloadModules()
		self.db:CopyProfile(profile)
	end
end

function Bongos:ResetProfile()
	self:UnloadModules()
	self.db:ResetProfile()
end

function Bongos:ListProfiles()
	self:Print("Available Profiles:")
	for i, k in ipairs(self.db:GetProfiles()) do
		self:Print(k)
	end
end

--utility profile functions
function Bongos:MatchProfile(name)
	local profileList = self.db:GetProfiles()

	local name = name:lower()
	local nameRealm = format('%s - %s', name, GetRealmName():lower())

	for i, k in ipairs(profileList) do
		local key = k:lower()
		if key == nameRealm or key == name then
			return k
		end
	end
end


--[[ Events ]]--

function Bongos:DONGLE_PROFILE_CREATED(event, db, parent, sv_name, profile_key)
	self:Print(format("Created new profile \"%s\"", profile_key))
end

function Bongos:DONGLE_PROFILE_CHANGED(event, db, parent, sv_name, profile_key)
	self:Print(format("Loaded profile \"%s\"", profile_key))
	self.profile = self.db.profile
	self:LoadModules()
end

function Bongos:DONGLE_PROFILE_DELETED(event, db, parent, sv_name, profile_key)
	self:Print(format("Deleted profile \"%s\"", profile_key))
end

function Bongos:DONGLE_PROFILE_COPIED(event, db, parent, sv_name, profile_key, intoProfile_key)
	self:Print(format("Copied profile \"%s\" to \"%s\"", profile_key, intoProfile_key))
	self:LoadModules()
end

function Bongos:DONGLE_PROFILE_RESET(event, db, parent, sv_name, profile_key)
	self:Print(format("Reset profile \"%s\"", profile_key))
	self:LoadModules()
end


--[[ Config Functions ]]--

function Bongos:SetLock(enable)
	if enable then
		self.profile.locked = true
		BBar:ForAll('Lock')
	else
		self.profile.locked = nil
		BBar:ForAll('Unlock')
	end
end

function Bongos:IsLocked()
	return self.profile.locked
end

function Bongos:SetSticky(enable)
	if enable then
		self.profile.sticky = true
	else
		self.profile.sticky = nil
	end
	BBar:ForAll('Reanchor')
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
	local cmdStr = "|cFF33FF99%s|r: %s"

	local slash = self:InitializeSlashCommand("Bongos Commands", "BONGOS", "bongos", "bgs", "bob")

	slash:RegisterSlashHandler(format(cmdStr, "lock", L.LockBarsDesc), "lock", "ToggleLockedBars")
	slash:RegisterSlashHandler(format(cmdStr, "sticky", L.StickyBarsDesc), "sticky", "ToggleStickyBars")

	slash:RegisterSlashHandler(format(cmdStr, "scale <barList> <scale>", L.SetScaleDesc), "scale (.+) ([%d%.]+)", "SetBarScale")
	slash:RegisterSlashHandler(format(cmdStr, "setalpha <barList> <opacity>", L.SetAlphaDesc), "setalpha (.+) ([%d%.]+)", "SetBarAlpha")

	slash:RegisterSlashHandler(format(cmdStr, "show <barList>", L.ShowBarsDesc), "show (.+)", "ShowBars")
	slash:RegisterSlashHandler(format(cmdStr, "hide <barList>", L.HideBarsDesc), "hide (.+)", "HideBars")
	slash:RegisterSlashHandler(format(cmdStr, "toggle <barList>", L.ToggleBarsDesc), "toggle (.+)", "ToggleBars")

	slash:RegisterSlashHandler(format(cmdStr, "set <profle>", L.SetDesc), "set (%w+)", "SetProfile")
--	slash:RegisterSlashHandler(format(cmdStr, "copy <profile>", L.CopyDesc), "copy (%w+)", "CopyProfile")
	slash:RegisterSlashHandler(format(cmdStr, "load <profile>", L.CopyDesc), "load (%w+)", "CopyProfile")
	slash:RegisterSlashHandler(format(cmdStr, "delete <profile>", L.DeleteDesc), "delete (%w+)", "DeleteProfile")
	slash:RegisterSlashHandler(format(cmdStr, "reset", L.ResetDesc), "reset", "ResetProfile")
	slash:RegisterSlashHandler(format(cmdStr, "list", L.ListDesc), "list", "ListProfiles")
	
	slash:RegisterSlashHandler(format(cmdStr, "fadealpha <barList> <opacity>", L.SetFadeAlphaDesc), "fadealpha (.+) ([%d%.]+)", "SetFadeAlpha")
	slash:RegisterSlashHandler(format(cmdStr, "fademode <barList> <0 | 1 | 2>", L.SetFadeModeDesc), "fademode (.+) ([0-2])", "SetFadeMode")
	
	self.slash = slash
end

function Bongos:ToggleLockedBars()
	self:SetLock(not self.profile.locked)
end

function Bongos:ToggleStickyBars()
	self:SetSticky(not self.profile.sticky)
end

function Bongos:SetBarScale(args, scale)
	local scale = tonumber(scale)

	if scale and scale > 0 and scale <= 10 then
		for _,barList in pairs({strsplit(' ', args)}) do
			BBar:ForBar(barList, 'SetFrameScale', scale)
		end
	end
end

function Bongos:SetBarAlpha(args, alpha)
	local alpha = tonumber(alpha)

	if alpha and alpha >= 0 and alpha <= 1 then
		for _,barList in pairs({strsplit(' ', args)}) do
			BBar:ForBar(barList, 'SetFrameAlpha', alpha)
		end
	end
end

function Bongos:SetFadeMode(args, mode)
	local mode = tonumber(mode)
	self:Print('setfademode', args, mode)

	for _,barList in pairs({strsplit(' ', args)}) do
		BBar:ForBar(barList, 'SetFadeMode', mode)
	end
end

function Bongos:SetFadeAlpha(args)
	local alpha = tonumber(alpha)

	if alpha and alpha >= 0 and alpha <= 1 then
		for _,barList in pairs({strsplit(' ', args)}) do
			BBar:ForBar(barList 'SetFadeAlpha', alpha)
		end
	end
end

function Bongos:ShowBars(args)
	for _, barList in pairs({strsplit(' ', args)}) do
		BBar:ForBar(barList, 'ShowFrame')
	end
end

function Bongos:HideBars(args)
	for _, barList in pairs({strsplit(' ', args)}) do
		BBar:ForBar(barList, 'HideFrame')
	end
end

function Bongos:ToggleBars(args)
	for _, barList in pairs({strsplit(' ', args)}) do
		BBar:ForBar(barList, 'ToggleFrame')
	end
end