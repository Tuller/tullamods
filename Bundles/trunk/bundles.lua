--[[
	bundles.lua
		A thingy to mass move items from one inventory type to another
		
	I'm sure I've looked at both quicksort and bankstack for this
--]]

local LIS = LibStub('LibItemSearch-1.0')
local abs = math.abs
local modf = math.modf
local tremove = table.remove
local tinsert = table.insert
local format = string.format

--[[
	utility stuff
--]]

local function slotToIndex(bag, slot, link)
	return format('%s,%s|%d', bag, slot, link)
end

local function indexToSlot(index)
	local bag, slot, link = index:match('^(%-?%d+)%,(%d+)%|(.+)')
	return bag, slot, link
end


--[[
	item searching
--]]

local function getItemsInSearch(search, bags)
	local items = {}
	
	for _, bag in ipairs(bags) do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			--i could implement basic caching for these searches at some point if speed becomes an issue
			if link and LIS:Find(link, search) then
				tinsert(items, slotToIndex(bag, slot, link))
			end
		end	
	end
	
	return items	
end


--[[
	item movement functionality
--]]

local mover = CreateFrame('Frame')

mover:SetScript('OnHide', function(self, elapsed)
	--remove lingering references on hide
	self.destBag = nil
	self.destSlot = nil
	self.bags = nil
	self.items = nil
end)

mover:SetScript('OnUpdate', function(self, elapsed)
	if self.elapsed > 0 then
		self.elapsed = self.elapsed - elapsed
		return
	end	
	self.elapsed = 0.05

	--if we're holding an item, then try and place it
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
	
	--check to see if there are any remaining items to place
	--if not, then quit
	if not(items and #items > 0) then
		self:Hide()
		return
	end
	
	--pickup the next item from the stack
	local fromBag, fromSlot, fromLink = indexToSlot(tremove(items))
	print('get', fromBag, fromSlot, fromLink)
	PickupContainerItem(fromBag, fromSlot)
	
	--determine where to put the item
	local foundAHome = false
	
	--if stackable
	--try and place the item in the first unfilled stack we find for the item
	
	--try and place the item in the first empty slot we find
	for _, toBag in ipairs(self.bags) do
		for toSlot = 1, GetContainerNumSlots(toBag) do
			local toLink = GetContainerItemLink(toBag, toSlot)
			if not toLink then
				self.destBag = toBag
				self.destSlot = toSlot
				foundAHome = true
				break
			end
		end
		
		if foundAHome then 
			break
		end
	end
	
	--we were unable to find a spot for the item
	--so, stop trying to move things
	if not foundAHome then
		self:Hide()
	end
end)

local function moveItems(items, toBags)
	mover.items = items
	mover.bags = toBags
	mover:Show()
end


--[[ 
	waffle town, usa 
--]]

Bundles = {}

local bagSets = {
	KEYRING = {KEYRING_CONTAINER},
	INVENTORY = {BACKPACK_CONTAINER, 1, 2, 3, 4},
	BANK = {BANK_CONTAINER, 5, 6, 7, 8, 9, 10}
}

function Bundles:GetBags(type)
	return bagSets[type:upper()]
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