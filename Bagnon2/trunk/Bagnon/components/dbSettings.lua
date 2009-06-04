--[[
	dbSettings.lua
		Database access for Bagnon
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local SavedSettings = {}
Bagnon.SavedSettings = SavedSettings


--[[ 
	Database
--]]

function SavedSettings:GetDB()
	if not self.db then
		self.db = _G['BagnonSets']
		if self.db then
			self:UpgradeDB()
		else
			self.db = self:GetDefaultSettings()
			_G['BagnonSets'] = self.db
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

	self:GetDB().version = self:GetAddOnVersion()
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
		--hide all frames
		for i, frameID in self:GetAvailableFrames() do
			Bagnon.Callbacks:SendMessage('FRAME_HIDE', frameID)
		end
		
		--set profile index
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

function SavedSettings:DeleteProfile(profileName)
	assert(profileName, 'Usage: SavedSettings:GetProfile(profileName)')
	
	if self:GetProfileName() ~= profileName then
		self:GetDB().profiles[profileName] = nil
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
		frames = {}
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
		profileName = 'Default'
		db.indexes[self:GetPlayerIndex()] = profileName
	end
	
	return profileName
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

--frames for current profile
function SavedSettings:GetAvailableFrames(tbl)
	local frames = tbl or {}

	for frameID in pairs(self:GetCurrentProfile().frames) do
		table.insert(frames, frameID)
	end
	
	table.sort(frames)
	return ipairs(frames)
end