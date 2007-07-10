--[[
	Bongos.lua
		Driver for bongos bars
--]]

Bongos = DongleStub("Dongle-1.0"):New("Bongos")
local CURRENT_VERSION = GetAddOnMetadata("Bongos2", "Version")
local L = BONGOS_LOCALS


--[[ Startup ]]--

function Bongos:Enable()
	self:RegisterMessage("DONGLE_PROFILE_CREATED")
	self:RegisterMessage("DONGLE_PROFILE_CHANGED")
	self:RegisterMessage("DONGLE_PROFILE_DELETED")
	self:RegisterMessage("DONGLE_PROFILE_COPIED")
	self:RegisterMessage("DONGLE_PROFILE_RESET")
	self:RegisterEvent("ADDON_LOADED", "LoadOptions")

	local defaults = {
		profile = {
			sticky = true,
			lockButtons = true,
			showTooltips = true,
			showHotkeys = true,
			showMacros = true,
			rangeColoring = true,
			showEmpty = false,
			showMinimap = true,
			selfCastKey = "ALT",
			rangeColor = {r = 1, g = 0.5, b = 0.5},
			quickMoveKey = 1,
			mapx = -24, mapy = -76,
			bars = {}
		}
	}

	self.db = self:InitializeDB("Bongos2DB", defaults)
	self.profile = self.db.profile

	--handle upgrading from <= 1.5 to 1.6+ because I'm a moron sometimes
	if(not BongosVersion) then
		self:UpdateSettings()
	else
		local cMajor, cMinor = CURRENT_VERSION:match("(%d+)%.(%d+)")
		local major, minor = BongosVersion:match("(%d+)%.(%d+)")

		--compatibility break
		if major ~= cMajor then
			self.db:ResetProfile()
			self:Print(L.UpdatedIncompatible)
		--settings change
		elseif minor ~= cMinor then
			self:UpdateSettings()
		--bugfix update, just inc version
		elseif BongosVersion ~= CURRENT_VERSION then
			self:UpdateVersion()
		end
	end

	self:RegisterSlashCommands()
	self:LoadModules()
end

function Bongos:UpdateVersion()
	BongosVersion = CURRENT_VERSION
	self:Print(format(L.Updated, BongosVersion))
end

function Bongos:UpdateSettings()
	if(BongosActionBar) then
		BongosActionBar:ConvertBindings()
	end
	self:UpdateVersion()
end

function Bongos:LoadModules()
	for name, module in self:IterateModules() do
		assert(module.Load, format("Bongos Module %s: Missing Load function", name))
		module:Load()
	end
	BBar:ForAll("Reanchor")
	self:LoadMinimap()
end

function Bongos:UnloadModules()
	for name, module in self:IterateModules() do
		assert(module.Unload, format("Bongos Module %s: Missing Unload function", name))
		module:Unload()
	end
end

function Bongos:LoadOptions(event, addon)
	if(addon == "Bongos2_Options") then
		for name, module in self:IterateModules() do
			if(module.LoadOptions) then
				module:LoadOptions()
			end
		end
		BongosOptions:ShowPanel(L.General)
		self:UnregisterEvent(event)
	end
end


--[[ Profile Functions ]]--

function Bongos:SaveProfile(profile)
	local currentProfile = self.db:GetCurrentProfile()
	if profile and profile ~= self.db:GetCurrentProfile() then
		self.copyProfile = currentProfile
		self:UnloadModules()
		self.db:SetProfile(profile)
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
		self.db:CopyProfile(profile)
	end
end

function Bongos:ResetProfile()
	self:UnloadModules()
	self.db:ResetProfile()
end

function Bongos:ListProfiles()
	self:Print(L.AvailableProfiles)
	for i, k in ipairs(self.db:GetProfiles()) do
		self:Print(k)
	end
end

--utility profile functions
function Bongos:MatchProfile(name)
	local profileList = self.db:GetProfiles()

	local name = name:lower()
	local nameRealm = format("%s - %s", name, GetRealmName():lower())

	for i, k in ipairs(profileList) do
		local key = k:lower()
		if key == name or key == nameRealm then
			return k
		end
	end
end


--[[ Events ]]--

function Bongos:DONGLE_PROFILE_CREATED(event, db, parent, sv_name, profile_key)
	if(sv_name == "Bongos2DB") then
		self.profile = self.db.profile
		if(BongosActionBar) then
			BongosActionBar:ConvertBindings()
		end
		self:Print(format(L.ProfileCreated , profile_key))
	end
end

function Bongos:DONGLE_PROFILE_CHANGED(event, db, parent, sv_name, profile_key)
	if(sv_name == "Bongos2DB") then
		self.profile = self.db.profile
		if(self.copyProfile) then
			self.db:CopyProfile(self.copyProfile)
			self.copyProfile = nil
		else
			self:LoadModules()
		end
		self:Print(format(L.ProfileLoaded, profile_key))
	end
end

function Bongos:DONGLE_PROFILE_DELETED(event, db, parent, sv_name, profile_key)
	if(sv_name == "Bongos2DB") then
		self:Print(format(L.ProfileDeleted, profile_key))
	end
end

function Bongos:DONGLE_PROFILE_COPIED(event, db, parent, sv_name, profile_key, intoProfile_key)
	if(sv_name == "Bongos2DB") then
		self.profile = self.db.profile
		self:LoadModules()
		self:Print(format(L.ProfileCopied, profile_key, intoProfile_key))
	end
end

function Bongos:DONGLE_PROFILE_RESET(event, db, parent, sv_name, profile_key)
	if(sv_name == "Bongos2DB") then
		self.profile = self.db.profile
		self:LoadModules()
		self:Print(format(L.ProfileReset, profile_key))
	end
end


--[[ Config Functions ]]--

function Bongos:SetLock(enable)
	self.profile.locked = enable or false
	if enable then
		BBar:ForAll("Lock")
	else
		BBar:ForAll("Unlock")
	end
end

function Bongos:IsLocked()
	return self.profile.locked
end

function Bongos:SetSticky(enable)
	self.profile.sticky = enable or false
	BBar:ForAll("Reanchor")
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
	slash:RegisterSlashHandler(format(cmdStr, "/bob", L.ShowOptionsDesc), "^$", "ShowMenu")
	slash:RegisterSlashHandler(format(cmdStr, "config", L.LockBarsDesc), "^config$", "ToggleLockedBars")
	slash:RegisterSlashHandler(format(cmdStr, "lock", L.LockBarsDesc), "^lock$", "ToggleLockedBars")
	slash:RegisterSlashHandler(format(cmdStr, "sticky", L.StickyBarsDesc), "^sticky$", "ToggleStickyBars")

	slash:RegisterSlashHandler(format(cmdStr, "scale <barList> <scale>", L.SetScaleDesc), "^scale (.+) ([%d%.]+)", "SetBarScale")
	slash:RegisterSlashHandler(format(cmdStr, "setalpha <barList> <opacity>", L.SetAlphaDesc), "^setalpha (.+) ([%d%.]+)", "SetBarAlpha")

	slash:RegisterSlashHandler(format(cmdStr, "show <barList>", L.ShowBarsDesc), "^show (.+)", "ShowBars")
	slash:RegisterSlashHandler(format(cmdStr, "hide <barList>", L.HideBarsDesc), "^hide (.+)", "HideBars")
	slash:RegisterSlashHandler(format(cmdStr, "toggle <barList>", L.ToggleBarsDesc), "^toggle (.+)", "ToggleBars")

	slash:RegisterSlashHandler(format(cmdStr, "save <profle>", L.SaveDesc), "save (%w+)", "SaveProfile")
	slash:RegisterSlashHandler(format(cmdStr, "set <profle>", L.SetDesc), "set (%w+)", "SetProfile")
	slash:RegisterSlashHandler(format(cmdStr, "copy <profile>", L.CopyDesc), "copy (%w+)", "CopyProfile")
	slash:RegisterSlashHandler(format(cmdStr, "delete <profile>", L.DeleteDesc), "^delete (%w+)", "DeleteProfile")
	slash:RegisterSlashHandler(format(cmdStr, "reset", L.ResetDesc), "^reset$", "ResetProfile")
	slash:RegisterSlashHandler(format(cmdStr, "list", L.ListDesc), "^list$", "ListProfiles")
	slash:RegisterSlashHandler(format(cmdStr, "version", L.PrintVersionDesc), "^version$", "PrintVersion")

	self.slash = slash
end

function Bongos:ShowMenu()
	local enabled = select(4, GetAddOnInfo("Bongos2_Options"))
	if enabled then
		if BongosOptions then
			BongosOptions:Toggle()
		else
			LoadAddOn("Bongos2_Options")
		end
	else
		self.slash:PrintUsage()
	end
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
		for _,barList in pairs({strsplit(" ", args)}) do
			BBar:ForBar(barList, "SetFrameScale", scale)
		end
	end
end

function Bongos:SetBarAlpha(args, alpha)
	local alpha = tonumber(alpha)

	if alpha and alpha >= 0 and alpha <= 1 then
		for _,barList in pairs({strsplit(" ", args)}) do
			BBar:ForBar(barList, "SetFrameAlpha", alpha)
		end
	end
end

function Bongos:PrintVersion()
	self:Print(BongosVersion)
end

function Bongos:ShowBars(args)
	for _, barList in pairs({strsplit(" ", args)}) do
		BBar:ForBar(barList, "ShowFrame")
	end
end

function Bongos:HideBars(args)
	for _, barList in pairs({strsplit(" ", args)}) do
		BBar:ForBar(barList, "HideFrame")
	end
end

function Bongos:ToggleBars(args)
	for _, barList in pairs({strsplit(" ", args)}) do
		BBar:ForBar(barList, "ToggleFrame")
	end
end

--minimap functions
function Bongos:LoadMinimap()
	local x, y = Bongos:GetMapCoords()
	BongosMinimapFrame:ClearAllPoints()
	BongosMinimapFrame:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", x, y)

	if not self:ShowingMinimap() then
		BongosMinimapFrame:Hide()
	end
end

function Bongos:SetShowMinimap(enable)
	self.profile.showMinimap = enable or false
	if enable then
		BongosMinimapFrame:Show()
	else
		BongosMinimapFrame:Hide()
	end
end

function Bongos:ShowingMinimap()
	return self.profile.showMinimap
end

function Bongos:SetMapCoords(x, y)
	self.profile.mapx = x
	self.profile.mapy = y
end

function Bongos:GetMapCoords()
	return self.profile.mapx, self.profile.mapy
end

function Bongos:CleanUp()
	local bars = self.profile.bars
	for id in pairs(self.profile.bars) do
		if not BBar:Get(id) then
			bars[id] = nil
		end
	end
end