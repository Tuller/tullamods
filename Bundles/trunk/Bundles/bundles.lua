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
	local link = link or ''
	return format('%d,%d|%s', bag, slot, link)
end

local function indexToSlot(index)
	if index then
		local bag, slot, link = index:match('^(%-?%d+)%,(%d+)%|(.*)')
		if link == '' then link = nil end

		return bag, slot, link
	end
end

local function isSlotLocked(bag, slot)
	local locked = select(3, GetContainerItemInfo(bag, slot))
	return locked
end


--[[
	item searching
--]]

local function pushItem(items, bag, slot, link)
	tinsert(items, slotToIndex(bag, slot, link))
end

local function popItem(items)
	return indexToSlot(tremove(items, 1))
end

local function getItemsInSearch(search, bags)
	local items = {}

	for _, bag in ipairs(bags) do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			--i could implement basic caching for these searches at some point if speed becomes an issue
			if link and LIS:Find(link, search) then
				pushItem(items, bag, slot, link)
			end
		end
	end

	return items
end

local function getItems(bags)
	local items = {}

	for _, bag in ipairs(bags) do
		for slot = 1, GetContainerNumSlots(bag) do
			pushItem(items, bag, slot, GetContainerItemLink(bag, slot))
		end
	end

	return items
end

--[[
	item movement functionality
--]]

local mover = CreateFrame('Frame')
mover:Hide()
mover.DELAY = 0.05
mover.MAX_NO_MOVES = 50

--remove lingering references on hide
mover:SetScript('OnShow', function(self)
	self.elapsed = -1
	self.noMoveCount = 0
end)

mover:SetScript('OnHide', function(self, elapsed)
	self.bags = nil
	self.items = nil
	collectgarbage()
end)

mover:SetScript('OnUpdate', function(self, elapsed)
	if self.elapsed > 0 then
		self.elapsed = self.elapsed - elapsed
		return
	end
	self.elapsed = self.DELAY

	--pickup the next item from the stack
	local fromBag, fromSlot, fromLink = popItem(self.fromItems)
	if not(fromBag and fromSlot) then
		self:Hide()
		return
	end

	--try and place the item in the first empty slot we find
	local itemPlaced = false
	local toItems = self.toItems
	local newItems = {}

	while next(toItems) do
		local toBag, toSlot, toLink = popItem(toItems)

		if not(itemPlaced or toLink or isSlotLocked(fromBag, fromSlot) or isSlotLocked(toBag, toSlot)) then
			PickupContainerItem(fromBag, fromSlot)
			PickupContainerItem(toBag, toSlot)
			pushItem(newItems, toBag, toSlot, fromLink)

			itemPlaced = true
		else
			pushItem(newItems, toBag, toSlot, toLink)
		end
	end
	self.toItems = newItems

	--we were not able to move the item, so
	if not itemPlaced then
		pushItem(self.fromItems, fromBag, fromSlot, fromLink)
		self.noMoveCount = self.noMoveCount + 1
	end

	--infinite loop prevention
	if self.noMoveCount > self.MAX_NO_MOVES then
		self:Hide()
	end
end)

local function moveItems(fromItems, toItems)
	mover.fromItems = fromItems
	mover.toItems = toItems
	mover:Show()
end


--[[
	Bundles Core
--]]

Bundles = {}

local bagSets = {
	all = {KEYRING_CONTAINER, BACKPACK_CONTAINER, 1, 2, 3, 4, BANK_CONTAINER, 5, 6, 7, 8, 9, 10},
	keyring = {KEYRING_CONTAINER},
	inventory = {BACKPACK_CONTAINER, 1, 2, 3, 4},
	bank = {BANK_CONTAINER, 5, 6, 7, 8, 9, 10}
}

--a few aliases
bagSets.keys = bagSets.keyring
bagSets.bags = bagSets.inventory


local function getBags(set)
	if not set then return end

	return bagSets[set:lower()]
end

function Bundles:Find(search, loc)
	if not search then
		self:Print('No search given')
		return
	end

	local bags = getBags(loc)
	if not bags then
		self:Print(format("Invalid location '%s'", loc or 'nil'))
		return
	end
	
	local items = getItemsInSearch(search, bags)
	if next(items) then
		while next(items) do
			self:Print(popItem(items))
		end
	else
		self:Print(format('No items were found in %s for %s', search, loc))
	end
end

function Bundles:Move(search, fromLoc, toLoc)
	if not search then
		self:Print('No search given')
		return
	end

	local fromBags = getBags(fromLoc)
	if not fromBags then
		self:Print(format("Invalid location '%s'", fromLoc or 'nil'))
		return
	end

	local toBags = getBags(toLoc)
	if not toBags then
		self:Print(format("Invalid location '%s'", toLoc or 'nil'))
		return
	end

	local fromItems = getItemsInSearch(search, fromBags)
	if #fromItems < 0 then
		self:Print(format('No items were found in %s for %s', search, fromLoc))
		return
	end

	moveItems(fromItems, getItems(toBags))
end

function Bundles:Print(...)
	return print('|cff00ffffBundles|r:', ...)
end


--[[
	slash commands
--]]

do
	SlashCmdList['BundlesCOMMAND'] = function(msg)
		if not msg then return end

		local cmd, args = msg:match('^(%w+)%s(.+)$')
		if not cmd then
			Bundles:Print(format("Unknown command '%s'", msg))
			return
		end

		cmd = cmd:lower()
		if cmd == 'move' or cmd == 'mv' then
			local search, from, to = args:match('^([%w%p%s]+)%s(%w+)%s(%w+)$')
			if search and from and to then
				Bundles:Move(search, from, to)
			end
		elseif cmd == 'find' then
			local search, loc = args:match('^([%w%p%s]+)%s(%w+)$')
			if search and loc then
				Bundles:Find(search, loc)
				return
			end
			
			local search = args:match('^([%w%p%s]+)')
			if search then
				Bundles:Find(search, 'all')
				return
			end
		else
			Bundles:Print(format("Unknown command '%s'", cmd))
		end
	end
	SLASH_BundlesCOMMAND1 = '/bundle'
	SLASH_BundlesCOMMAND2 = '/bnd'
end