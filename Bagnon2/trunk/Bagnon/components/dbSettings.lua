--[[
	dbSettings.lua
		Database access for Bagnon
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local SavedSettings = {}
Bagnon.SavedSettings = SavedSettings


--[[ 
	Database Settings
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
	Profile Settings
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
		profile = self:GetDefaultProfileSettings()
		db.profiles[profileName] = profile
	end
	
	return profile
end

function SavedSettings:GetDefaultProfileSettings()
	local profile = {
		frames = {
			inventory = self:GetDefaultFrameSettings('inventory'),
			bank = self:GetDefaultFrameSettings('bank'),
			keys = self:GetDefaultFrameSettings('keys'),
		},
	}
	
	return profile
end


--[[ Iterators ]]--

--profiles
function SavedSettings:GetAvailableProfiles(tbl)
	local profiles = tbl or {}
	
	for profileName in pairs(self:GetDB().profiles) do
		table.insert(profiles, profileName)
	end
	
	table.sort(profiles)
	return ipairs(profiles)
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


--[[ 
	Frame Settings
--]]

function SavedSettings:GetFrameSettings(frameID)
	local frameSettings = self:GetCurrentProfile().frames[frameID]
	if not frameSettings then
		frameSettings = self:GetDefaultFrameSettings()
		self:GetCurrentProfile().frames[frameID] = frameSettings
	end
	return frameSettings
end


--[[ Frame Color ]]--

--background
function SavedSettings:SetFrameColor(frameID, r, g, b, a)
	local color = self:GetFrameSettings(frameID).frameColor
	color[1] = r
	color[2] = g
	color[3] = b
	color[4] = a
end

function SavedSettings:GetFrameColor(frameID)
	local r, g, b, a = unpack(self:GetFrameSettings(frameID).frameColor)
	return r, g, b, a
end

--border
function SavedSettings:SetFrameBorderColor(frameID, r, g, b, a)
	local color = self:GetFrameSettings(frameID).frameBorderColor
	color[1] = r
	color[2] = g
	color[3] = b
	color[4] = a
end

function SavedSettings:GetFrameBorderColor(frameID)
	local r, g, b, a = unpack(self:GetFrameSettings(frameID).frameBorderColor)
	return r, g, b, a
end


--[[ Frame Position ]]--

function SavedSettings:SetFramePosition(frameID, point, x, y)
	local sets = self:GetFrameSettings(frameID)
	sets.point = point
	sets.x = x
	sets.y = y
end

function SavedSettings:GetFramePosition(frameID)
	local sets = self:GetFrameSettings(frameID)
	return sets.point, sets.x, sets.y
end


--[[ Frame Scale ]]--

function SavedSettings:SetFrameScale(frameID, scale)
	self:GetFrameSettings(frameID).scale = scale
end

function SavedSettings:GetFrameScale(frameID)
	return self:GetFrameSettings(frameID).scale
end


--[[ Frame Opacity ]]--

function SavedSettings:SetFrameOpacity(frameID, opacity)
	self:GetFrameSettings(frameID).opacity = opacity
end

function SavedSettings:GetFrameOpacity(frameID)
	return self:GetFrameSettings(frameID).opacity
end


--[[ Frame Components ]]--

function SavedSettings:DoesFrameHaveBagFrame(frameID)
	return self:GetFrameSettings(frameID).hasBagFrame
end

function SavedSettings:DoesFrameHaveMoneyFrame(frameID)
	return self:GetFrameSettings(frameID).hasMoneyFrame
end

function SavedSettings:DoesFrameHaveDBOFrame(frameID)
	return self:GetFrameSettings(frameID).hasDBOFrame
end


--[[ Frame Bags ]]--

--show a bag
function SavedSettings:ShowFrameBag(frameID, bag)
	local hiddenBags = self:GetFrameSettings(frameID).hiddenBags
	local found = false
	
	for k, hiddenBag in pairs(hiddenBags) do
		if bag == hiddenBag then
			found = true
			break
		end
	end
	
	if not found then
		table.insert(hiddenBags, bag)
	end
end

--hide a bag
function SavedSettings:HideFrameBag(frameID, bag)
	local hiddenBags = self:GetFrameSettings(frameID).hiddenBags

	for k, hiddenBag in pairs(hiddenBags) do
		if bag == hiddenBag then
			table.remove(hiddenBags, bag)
			return
		end
	end
end

--get all available bags
function SavedSettings:GetFrameBags(frameID)
	return self:GetFrameSettings(frameID).availableBags
end

--get all hidden bags
function SavedSettings:GetFrameHiddenBags(frameID)
	return self:GetFrameSettings(frameID).hiddenBags
end


--[[ Item Frame Layout ]]--

--columns
function SavedSettings:SetItemFrameColumns(frameID, columns)
	self:GetFrameSettings(frameID).itemFrameColumns = columns
end

function SavedSettings:GetItemFrameColumns(frameID)
	return self:GetFrameSettings(frameID).itemFrameColumns
end

--spacing
function SavedSettings:SetItemFrameSpacing(frameID, spacing)
	self:GetFrameSettings(frameID).itemFrameSpacing = spacing
end

function SavedSettings:GetItemFrameSpacing(frameID)
	return self:GetFrameSettings(frameID).itemFrameSpacing
end


--[[ Frame Setting Defaults ]]--

--generic
function SavedSettings:GetDefaultFrameSettings(frameID)
	if frameID == 'keys' then
		return self:GetDefaultKeyRingSettings()
	end
	if frameID == 'bank' then
		return self:GetDefaultBankSettings()
	end
	return self:GetDefaultInventorySettings()
end	

--inventory
function SavedSettings:GetDefaultInventorySettings()
	return {
		--bag settings
		availableBags = {BACKPACK_CONTAINER, 1, 2, 3, 4},
		hiddenBags = {},

		--frame
		frameColor = {0, 0, 0, 0.5},
		frameBorderColor = {random(), random(), random(), 1},
		scale = 1,
		opacity = 1,
		point = 'RIGHT',
		x = 0,
		y = 0,

		--itemFrame
		itemFrameColumns = 8,
		itemFrameSpacing = 2,
		
		--optional components
		hasMoneyFrame = true,
		hasBagFrame = true,
		hasDBOFrame = true,

		--dbo display object
		dataBrokerObject = nil,
	}
end

--bank
function SavedSettings:GetDefaultBankSettings()
	return {
		--bag settings
		availableBags = {BANK_CONTAINER, 5, 6, 7, 8, 9, 10, 11},
		hiddenBags = {},

		--frame
		frameColor = {0, 0, 0, 0.5},
		frameBorderColor = {random(), random(), random(), 1},
		scale = 1,
		opacity = 1,
		point = 'LEFT',
		x = 0,
		y = 0,

		--itemFrame
		itemFrameColumns = 10,
		itemFrameSpacing = 2,
		
		--optional components
		hasMoneyFrame = true,
		hasBagFrame = true,
		hasDBOFrame = true,

		--dbo display object
		dataBrokerObject = nil,
	}
end

--keys
function SavedSettings:GetDefaultKeyRingSettings()
	return {
		--bag settings
		availableBags = {KEYRING_CONTAINER},
		hiddenBags = {},

		--frame,
		frameColor = {0, 0, 0, 0.5},
		frameBorderColor = {random(), random(), random(), 1},
		scale = 1,
		opacity = 1,
		point = 'RIGHT',
		x = 0,
		y = -400,

		--itemFrame
		itemFrameColumns = 4,
		itemFrameSpacing = 2,
		
		--optional components
		hasMoneyFrame = false,
		hasBagFrame = false,
		hasDBOFrame = false,

		--dbo display object
		dataBrokerObject = nil,
	}
end