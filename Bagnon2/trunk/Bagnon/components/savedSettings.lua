--[[
	dbSettings.lua
		Database access for Bagnon
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local SavedSettings = {}
Bagnon.SavedSettings = SavedSettings


--[[ 
	Database
--]]

function SavedSettings:GetDB()
	if not self.db then
		self.db = _G['BagnonSettings']
		if self.db then
			self:UpgradeDB()
		else
			self.db = self:GetDefaultSettings()
			_G['BagnonSettings'] = self.db
			Bagnon:Print(L.NewUser)
		end
	end

	return self.db
end


--[[ Initialization ]]--

function SavedSettings:GetDefaultSettings()
	local db = {
		indexes = {
		},

		profiles = {
		},

		version = self:GetAddOnVersion()
	}

	return db
end


--[[ Upgrading ]]--

function SavedSettings:UpgradeDB()
	if not self:IsDBOutOfDate() then return end
	
	local major, minor, bugfix = self:GetDBVersion():match('(%w+)%.(%w+)%.(%w+)')
	--do upgrade stuff

	self:GetDB().version = self:GetAddOnVersion()
	Bagnon:Print(string.format(L.Updated, self:GetDBVersion()))
end

function SavedSettings:IsDBOutOfDate()
	return self:GetDBVersion() ~= self:GetAddOnVersion()
end

function SavedSettings:GetDBVersion()
	return self:GetDB().version
end

function SavedSettings:GetAddOnVersion()
	return GetAddOnMetadata('Bagnon', 'Version')
end


--[[ 
	Profile
--]]

function SavedSettings:SetProfile(profileName)
	assert(profileName, 'Usage: SavedSettings:SetProfile(profileName)')

	if profileName ~= self:GetCurrentProfileName() then
		self:GetDB().indexes[self:GetPlayerIndex()] = profileName
	end
end

function SavedSettings:GetProfile(profileName)
	assert(profileName, 'Usage: SavedSettings:GetProfile(profileName)')
	
	local db = self:GetDB()
	local profile = db.profiles[profileName]
	if not profile then
		profile = self:GetDefaultProfileSettings(profileName)
		db.profiles[profileName] = profile
	end
	
	return profile
end

function SavedSettings:DeleteProfile(profileToDelete)
	assert(profileToDelete, 'Usage: SavedSettings:GetProfile(profileToDelete)')
	
	if self:GetProfileName() ~= profileToDelete then
		self:GetDB().profiles[profileToDelete] = nil
		
		--remove any player settings that reference this profile
		local indexes = self:GetDB().indexes
		for i, profileName in pairs(indexes) do
			if profileName == profileToDelete then
				indexes[i] = nil
			end
		end
	end
end
	

--profiles listing
function SavedSettings:GetAvailableProfiles(tbl)
	local profiles = tbl or {}
	
	for profileName in pairs(self:GetDB().profiles) do
		table.insert(profiles, profileName)
	end
	
	table.sort(profiles)
	return ipairs(profiles)
end

function SavedSettings:GetDefaultProfileSettings(profileName)
	return {
		frames = {},
		highlightItemsByQuality = true,
		highlightQuestItems = true,
		showEmptyItemSlotTexture = true,
		lockFramePositions = true,
		reverseSlotOrder = false,
	}
end


--[[
	Player Profile Access
--]]

function SavedSettings:GetCurrentProfile()
	return self:GetProfile(self:GetCurrentProfileName())
end

function SavedSettings:GetCurrentProfileName()
	local db = self:GetDB()

	local profileName = db.indexes[self:GetPlayerIndex()]
	if not profileName then
		profileName = self:GetDefaultProfileName()
		db.indexes[self:GetPlayerIndex()] = profileName
	end
	
	return profileName
end

function SavedSettings:GetDefaultProfileName()
	return (UnitClass('player'))
end

function SavedSettings:GetPlayerIndex()
	return UnitName('player') .. ' - ' .. GetRealmName()
end


--[[
	Frames
--]]

function SavedSettings:SetFrameSettings(frameID, settings)
	self:GetCurrentProfile().frames[frameID] = settings
end

function SavedSettings:GetFrameSettings(frameID)
	return self:GetCurrentProfile().frames[frameID]
end