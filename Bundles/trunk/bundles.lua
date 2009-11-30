local LIS = LibStub('LibItemSearch-1.0')
local abs = math.abs
local modf = math.modf
local tremove = table.remove
local tinsert = table.insert
local format = string.format

--[[ Utility Methods ]]

local function slotToIndex(bag, slot, link)
	local slotIndex
	if bag < 0 then
		slotIndex = (100 * bag) - slot
	else
		slotIndex = (100 * bag) + slot
	end
	return slotIndex .. '|' .. link
end

local function indexToSlot(index)
	local slotIndex, link = index:match('^(%-?%d+)%|(.+)')
	local bag, slot = modf(slotIndex / 100)
	slot = abs(slot * 100)
	return bag, slot, link
end

local function getItemsInSearch(search, bags)
	local items = {}
	
	for _, bag in ipairs(bags) do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link and LIS:Find(link, search) then
				tinsert(items, slotToIndex(bag, slot, link))
			end
		end	
	end
	
	return items	
end

local mover = CreateFrame('Frame')
mover:SetScript('OnUpdate', function(self, elapsed)
	if self.destBag and self.destSlot then
		if CursorHasItem() then
			print('put', self.destBag, self.destSlot)
			PickupContainerItem(self.destBag, self.destSlot)
			self.destBag = nil
			self.destSlot = nil
		end
		return
	end
	
	local items = self.items
	if not(items and #items > 0) then
		self:Hide()
		return
	end
	
	local fromBag, fromSlot, fromLink = indexToSlot(tremove(items))
	print('get', fromBag, fromSlot, fromLink)
	PickupContainerItem(fromBag, fromSlot)
	
	local itemPlaced = false
	
	--try and place the item in an empty slot
	for _, toBag in ipairs(self.bags) do
		for toSlot = 1, GetContainerNumSlots(toBag) do
			local toLink = GetContainerItemLink(toBag, toSlot)
			if not toLink then
				self.destBag = toBag
				self.destSlot = toSlot
				itemPlaced = true
				break
			end
		end
		if itemPlaced then break end
	end
	
	if not itemPlaced then
		Bundles:Print('nothing placed')
		self:Hide()
	end
end)

local function moveItems(items, toBags)
	print('move items', unpack(items), unpack(toBags))
	mover.items = items
	mover.bags = toBags
	mover:Show()
end


--[[ Bundles ]]--

Bundles = {}

Bundles._locations = {
	KEYRING = {KEYRING_CONTAINER},
	INVENTORY = {BACKPACK_CONTAINER, 1, 2, 3, 4},
	BANK = {BANK_CONTAINER, 5, 6, 7, 8, 9, 10}
}

function Bundles:GetBags(type)
	return self._locations[type:upper()]
end


function Bundles:Move(search, fromLoc, toLoc)
	if not search then
		self:Print('No search given')
		return
	end

	local fromBags = self:GetBags(fromLoc)
	if not fromBags then
		self:Print(format("Invalid location '%s'", fromLoc or 'nil'))
		return
	end

	local toBags = self:GetBags(toLoc)
	if not toBags then
		self:Print(format("Invalid location '%s'", toLoc or 'nil'))
		return
	end
	
	local items = getItemsInSearch(search, fromBags)
	if #items < 0 then
		self:Print(format('No items were found in %s for %s', search, fromLoc))
		return
	end
	
	moveItems(items, toBags)
end

function Bundles:Print(...)
	return print('Bundles', ...)
end