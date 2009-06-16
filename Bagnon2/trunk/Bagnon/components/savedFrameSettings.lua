--[[
	savedFrameSettings.lua
		Persistent frame settings
--]]

local SavedFrameSettings = {}
local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
Bagnon.SavedFrameSettings = SavedFrameSettings


--[[---------------------------------------------------------------------------
	Local Functions of Justice
--]]---------------------------------------------------------------------------

local function removeDefaults(tbl, defaults)
	for k, v in pairs(defaults) do
		if type(tbl[k]) == 'table' and type(v) == 'table' then
			removeDefaults(tbl[k], v)

			if not next(tbl[k]) then
				tbl[k] = nil
			end
		elseif tbl[k] == v then
			print('remove default', k, v)
			tbl[k] = nil
		end
	end
end

local function copyDefaults(tbl, defaults)
	for k, v in pairs(defaults) do
		if not tbl[k] then
			if type(v) == 'table' then
				tbl[k] = copyDefaults({}, v)
			else
				tbl[k] = v
			end
		end
	end
	return tbl
end


--[[---------------------------------------------------------------------------
	Constructorish
--]]---------------------------------------------------------------------------

SavedFrameSettings.mt = {
	__index = SavedFrameSettings
}

SavedFrameSettings.objects = setmetatable({}, {__index = function(tbl, id)
	local obj = setmetatable({frameID = id}, SavedFrameSettings.mt)
	tbl[id] = obj
	return obj
end})

function SavedFrameSettings:Get(id)
	return self.objects[id]
end


--[[---------------------------------------------------------------------------
	Events
--]]---------------------------------------------------------------------------

--create an event handler
do
	local f = CreateFrame('Frame')
	f:SetScript('OnEvent', function(self, event, ...)
		local action = SavedFrameSettings[event]
		if action then
			action(SavedFrameSettings, event, ...)
		end
	end)

	f:RegisterEvent('PLAYER_LOGOUT')
end

--remove any settings that are set to defaults upon logout
function SavedFrameSettings:PLAYER_LOGOUT()
	self:ClearDefaults()
end


--[[---------------------------------------------------------------------------
	Accessor Methods
--]]---------------------------------------------------------------------------

--get settings for all frames
--only one instance of this for everything (hence the lack of self use)
function SavedFrameSettings:GetGlobalDB()
	if not SavedFrameSettings.db then
		SavedFrameSettings.db = _G['BagnonFrameSettings']

		if SavedFrameSettings.db then
			if self:IsDBOutOfDate() then
				self:UpgradeDB()
			end
		else
			SavedFrameSettings.db = {
				frames = {},
				version = self:GetAddOnVersion()
			}
			_G['BagnonFrameSettings'] = SavedFrameSettings.db
		end
	end
	return SavedFrameSettings.db
end

--get frame specific settings
function SavedFrameSettings:GetDB()
	if not self.frameDB then
		self.frameDB = self:GetGlobalDB().frames[self:GetFrameID()]

		if not self.frameDB then
			self.frameDB = {}
			self:GetGlobalDB().frames[self:GetFrameID()] = self.frameDB
		end

		copyDefaults(self.frameDB, self:GetDefaultSettings())
	end
	return self.frameDB
end

function SavedFrameSettings:GetFrameID()
	return self.frameID
end


--[[---------------------------------------------------------------------------
	Upgrade Methods
--]]---------------------------------------------------------------------------

function SavedFrameSettings:UpgradeDB()
	local major, minor, bugfix = self:GetDBVersion():match('(%w+)%.(%w+)%.(%w+)')
	--do upgrade stuff

	self:GetGlobalDB().version = self:GetAddOnVersion()
end

function SavedFrameSettings:IsDBOutOfDate()
	return self:GetDBVersion() ~= self:GetAddOnVersion()
end

function SavedFrameSettings:GetDBVersion()
	return self:GetGlobalDB().version
end

function SavedFrameSettings:GetAddOnVersion()
	return GetAddOnMetadata('Bagnon', 'Version')
end

function SavedFrameSettings:ClearDefaults()
	local db = self:GetGlobalDB()

	for frameID, settings in pairs(db.frames) do
		removeDefaults(settings, self:GetDefaultSettings(frameID))
		
		if not next(settings) then
			db[frameID] = nil
		end
	end
end


--[[---------------------------------------------------------------------------
	Update Methods
--]]---------------------------------------------------------------------------

--[[ Frame Color ]]--

--background
function SavedFrameSettings:SetColor(r, g, b, a)
	local color = self:GetDB().frameColor
	color[1] = r
	color[2] = g
	color[3] = b
	color[4] = a
end

function SavedFrameSettings:GetColor()
	return unpack(self:GetDB().frameColor)
end

--border
function SavedFrameSettings:SetBorderColor(r, g, b, a)
	local color = self:GetDB().frameBorderColor
	color[1] = r
	color[2] = g
	color[3] = b
	color[4] = a
end

function SavedFrameSettings:GetBorderColor()
	return unpack(self:GetDB().frameBorderColor)
end


--[[ Frame Position ]]--

function SavedFrameSettings:SetPosition(point, x, y)
	local db = self:GetDB()
	db.point = point
	db.x = x
	db.y = y
end

function SavedFrameSettings:GetPosition()
	local db = self:GetDB()
	return db.point, db.x, db.y
end


--[[ Frame Scale ]]--

function SavedFrameSettings:SetScale(scale)
	self:GetDB().scale = scale
end

function SavedFrameSettings:GetScale()
	return self:GetDB().scale
end


--[[ Frame Opacity ]]--

function SavedFrameSettings:SetOpacity(opacity)
	self:GetDB().opacity = opacity
end

function SavedFrameSettings:GetOpacity()
	return self:GetDB().opacity
end


--[[ Frame Layer]]--

function SavedFrameSettings:SetLayer(layer)
	self:GetDB().frameLayer = layer
end

function SavedFrameSettings:GetLayer()
	return self:GetDB().frameLayer
end


--[[ Frame Components ]]--

function SavedFrameSettings:HasBagFrame()
	return self:GetDB().hasBagFrame
end

function SavedFrameSettings:HasMoneyFrame()
	return self:GetDB().hasMoneyFrame
end

function SavedFrameSettings:HasDBOFrame()
	return self:GetDB().hasDBOFrame
end


--[[ Frame Bags ]]--

--show a bag
function SavedFrameSettings:ShowBag(bag)
	local hiddenBags = self:GetDB().hiddenBags

	for i, hiddenBag in pairs(hiddenBags) do
		if bag == hiddenBag then
			table.remove(hiddenBags, i)
			return
		end
	end
end

--hide a bag
function SavedFrameSettings:HideBag(bag)
	local hiddenBags = self:GetDB().hiddenBags
	local found = false

	for i, hiddenBag in pairs(hiddenBags) do
		if bag == hiddenBag then
			found = true
			break
		end
	end

	if not found then
		table.insert(hiddenBags, bag)
	end
end

--get all available bags
function SavedFrameSettings:GetBags()
	return self:GetDB().availableBags
end

--get all hidden bags
function SavedFrameSettings:GetHiddenBags()
	return self:GetDB().hiddenBags
end


--[[ Item Frame Layout ]]--

--columns
function SavedFrameSettings:SetItemFrameColumns(columns)
	self:GetDB().itemFrameColumns = columns
end

function SavedFrameSettings:GetItemFrameColumns()
	return self:GetDB().itemFrameColumns
end

--spacing
function SavedFrameSettings:SetItemFrameSpacing(spacing)
	self:GetDB().itemFrameSpacing = spacing
end

function SavedFrameSettings:GetItemFrameSpacing()
	return self:GetDB().itemFrameSpacing
end


--[[ Databroker Display Object ]]--

function SavedFrameSettings:SetBrokerDisplayObject(objectName)
	self:GetDB().dataBrokerObject = objectName
end

function SavedFrameSettings:GetBrokerDisplayObject()
	return self:GetDB().dataBrokerObject
end


--[[---------------------------------------------------------------------------
	Frame Defaults
--]]---------------------------------------------------------------------------

--generic
function SavedFrameSettings:GetDefaultSettings(frameID)
	local frameID = frameID or self:GetFrameID()

	if frameID == 'keys' then
		return self:GetDefaultKeyRingSettings()
	elseif frameID == 'bank' then
		return self:GetDefaultBankSettings()
	end

	return self:GetDefaultInventorySettings()
end

--inventory
function SavedFrameSettings:GetDefaultInventorySettings()
	local defaults = SavedFrameSettings.invDefaults or {
		--bag settings
		availableBags = {BACKPACK_CONTAINER, 1, 2, 3, 4},
		hiddenBags = {},

		--frame
		frameColor = {0, 0, 0, 0.5},
		frameBorderColor = {1, 1, 1, 1},
		scale = 1,
		opacity = 1,
		point = 'BOTTOMRIGHT',
		x = 0,
		y = 150,
		frameLayer = 'HIGH',

		--itemFrame
		itemFrameColumns = 8,
		itemFrameSpacing = 2,

		--optional components
		hasMoneyFrame = true,
		hasBagFrame = true,
		hasDBOFrame = true,

		--dbo display object
		dataBrokerObject = 'BagnonLauncher',
	}

	SavedFrameSettings.invDefaults = defaults
	return defaults
end

--bank
function SavedFrameSettings:GetDefaultBankSettings()
	local defaults = SavedFrameSettings.bankDefaults or {
		--bag settings
		availableBags = {BANK_CONTAINER, 5, 6, 7, 8, 9, 10, 11},
		hiddenBags = {},

		--frame
		frameColor = {0, 0, 0, 0.5},
		frameBorderColor = {1, 1, 0, 1},
		scale = 1,
		opacity = 1,
		point = 'BOTTOMLEFT',
		x = 0,
		y = 150,
		frameLayer = 'HIGH',

		--itemFrame
		itemFrameColumns = 10,
		itemFrameSpacing = 2,

		--optional components
		hasMoneyFrame = true,
		hasBagFrame = true,
		hasDBOFrame = true,

		--dbo display object
		dataBrokerObject = 'BagnonLauncher',
	}
	SavedFrameSettings.bankDefaults = defaults
	return defaults
end

--keys
function SavedFrameSettings:GetDefaultKeyRingSettings()
	local defaults = SavedFrameSettings.keyDefaults or {
		--bag settings
		availableBags = {KEYRING_CONTAINER},
		hiddenBags = {},

		--frame,
		frameColor = {0, 0, 0, 0.5},
		frameBorderColor = {0, 1, 1, 1},
		scale = 1,
		opacity = 1,
		point = 'BOTTOMRIGHT',
		x = -350,
		y = 150,
		frameLayer = 'HIGH',

		--itemFrame
		itemFrameColumns = 4,
		itemFrameSpacing = 2,

		--optional components
		hasMoneyFrame = false,
		hasBagFrame = false,
		hasDBOFrame = false,

		--dbo display object
		dataBrokerObject = 'BagnonLauncher',
	}
	SavedFrameSettings.keyDefaults = defaults
	return defaults
end