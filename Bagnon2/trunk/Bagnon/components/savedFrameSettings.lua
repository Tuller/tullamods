--[[
	savedFrameSettings.lua
		Persistent frame settings
--]]

local SavedFrameSettings = {}
local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
Bagnon.SavedFrameSettings = SavedFrameSettings


--[[---------------------------------------------------------------------------
	Constructorish
--]]---------------------------------------------------------------------------

SavedFrameSettings.mt = {
	__index = SavedFrameSettings
}

SavedFrameSettings.objects = setmetatable({}, {__index = function(tbl, id)
	local obj = setmetatable({frameID = id}, FrameSettings.mt)
	tbl[id] = obj
	return obj
end)

function SavedFrameSettings:Get(id)
	return self.objects[id]
end


--[[---------------------------------------------------------------------------
	Accessor Methods
--]]---------------------------------------------------------------------------

function SavedFrameSettings:GetFrameID()
	return self.frameID
end

function SavedFrameSettings:GetDB()
	local settings = Bagnon.SavedSettings:GetFrameSettings(self:GetFrameID())
	
	if not settings then
		settings = self:GetDefaultSettings()
		Bagnon.SavedSettings:SetFrameSettings(self:GetFrameID(), settings)
	end
	
	return settings
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

--hide a bag
function SavedFrameSettings:HideBag(bag)
	local hiddenBags = self:GetDB().hiddenBags

	for i, hiddenBag in pairs(hiddenBags) do
		if bag == hiddenBag then
			table.remove(hiddenBags, bag)
			return
		end
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


--[[---------------------------------------------------------------------------
	Frame Defaults
--]]---------------------------------------------------------------------------

--generic
function SavedFrameSettings:GetDefaultFrameSettings()
	local frameID = self:GetFrameID()
	
	if frameID == 'keys' then
		return self:GetDefaultKeyRingSettings()
	elseif frameID == 'bank' then
		return self:GetDefaultBankSettings()
	end
	
	return self:GetDefaultInventorySettings()
end	

--inventory
function SavedFrameSettings:GetDefaultInventorySettings()
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
function SavedFrameSettings:GetDefaultBankSettings()
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
function SavedFrameSettings:GetDefaultKeyRingSettings()
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