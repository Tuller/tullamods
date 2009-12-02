--[[
	bundles.lua
		A thingy to mass move items from one inventory type to another

	I'm sure I've looked at both quicksort and bankstack for this
--]]

local LIS = LibStub('LibItemSearch-1.0')
local tremove = table.remove
local tinsert = table.insert
local format = string.format
local tonumber = tonumber

--[[
	utility stuff
--]]

local function slotToStr(bag, slot, link, count)
	local link = link or ''
	local count = count or 0

	return format('%d,%d,%d|%s', bag, slot, count, link)
end

local function strToSlot(index)
	if index then
		local bag, slot, count, link = index:match('^(%-?%d+)%,(%d+)%,(%d+)%|(.*)')
		if link == '' then link = nil end

		return bag, slot, link, tonumber(count)
	end
end

local function isSlotLocked(bag, slot)
	local texture, count, locked = GetContainerItemInfo(bag, slot)
	return locked
end

--attempts to move an item from one slot to another
--returns true if the slots were not locked, and false otherwise
local function moveItem(fromBag, fromSlot, toBag, toSlot)
	if isSlotLocked(fromBag, fromSlot) or isSlotLocked(toBag, toSlot) then
		return false
	end

	PickupContainerItem(fromBag, fromSlot)
	PickupContainerItem(toBag, toSlot)
	return true
end


--[[
	item searching
--]]

local function getSlotsInSearch(search, bags)
	local slots = {}

	for _, bag in ipairs(bags) do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			if link and LIS:Find(link, search) then
				tinsert(slots, slotToStr(bag, slot, link, count))
			end
		end
	end

	return slots
end

local function getSlots(bags)
	local slots = {}

	for _, bag in ipairs(bags) do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
			tinsert(slots, slotToStr(bag, slot, link, count))
		end
	end

	return slots
end

--[[
	item movement functionality
--]]

local mover = CreateFrame('Frame')
mover:Hide()
mover.DELAY = 0.05

--remove lingering references on hide
mover:SetScript('OnShow', function(self)
	self.elapsed = -1
end)

mover:SetScript('OnHide', function(self, elapsed)
	self.fromSlots = nil
	self.toSlots = nil
end)

mover:SetScript('OnUpdate', function(self, elapsed)
	if self.elapsed > 0 then
		self.elapsed = self.elapsed - elapsed
		return
	end
	self.elapsed = self.DELAY

	--pickup the next item from the stack, quit if there are no more
	local fromBag, fromSlot, fromLink, fromCount = strToSlot(self.fromSlots[1])
	if not(fromBag and fromSlot) then
		self:Hide()
		return
	end

	local placed, locked = false, false
	local maxCount = select(8, GetItemInfo(fromLink))

	--try to place the item in the first stack that can fit it
	if fromCount < maxCount then
		for i, slotInfo in ipairs(self.toSlots) do
			local toBag, toSlot, toLink, toCount = strToSlot(slotInfo)

			--look for the same item and a different slot
			if (fromLink == toLink) and not(toBag == fromBag and toSlot == fromSlot) then
				--we've found a good place to put the item, so try to move it there
				if (fromCount + toCount) <= maxCount then
					if moveItem(fromBag, fromSlot, toBag, toSlot) then
						self.toSlots[i] = slotToStr(toBag, toSlot, fromLink, fromCount + toCount)
						placed = true
					else
						locked = true
					end
					break
				end
			end
		end
	end

	--try to place the item in the first empty slot we find
	if not (itemPlaced or slotLocked) then
		for i, slotInfo in ipairs(self.toSlots) do
			local toBag, toSlot, toLink, toCount = strToSlot(slotInfo)

			--we've found a good place to put the item, so try to move it there
			if not(toLink or (toBag == fromBag and toSlot == fromSlot)) then
				if moveItem(fromBag, fromSlot, toBag, toSlot) then
					self.toSlots[i] = slotToStr(toBag, toSlot, fromLink, fromCount)
					placed = true
				else
					locked = true
				end
			end
		end
	end

	--the item was placed, so remove it from the list of items to move
	if placed then
		tremove(self.fromSlots, 1)
	--the item was not placed, and the slot was not locked
	--therefore, we have no more remaining slots, so quit
	elseif not locked then
		self:Hide()
	end
end)

local function moveItems(fromSlots, toSlots)
	mover.fromSlots = fromSlots
	mover.toSlots = toSlots
	mover:Show()
end


--[[
	Bundles Core
--]]

Bundles = {}

local bagSets = {
	all = {KEYRING_CONTAINER, BACKPACK_CONTAINER, 1, 2, 3, 4, BANK_CONTAINER, 5, 6, 7, 8, 9, 10, 11},
	keyring = {KEYRING_CONTAINER},
	inventory = {BACKPACK_CONTAINER, 1, 2, 3, 4},
	bank = {BANK_CONTAINER, 5, 6, 7, 8, 9, 10, 11}
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

	local slots = getSlotsInSearch(search, bags)
	if next(slots) then
		for i, slotInfo in ipairs(slots) do
			self:Print(strToSlot(slotInfo))
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

	local fromSlots = getSlotsInSearch(search, fromBags)
	if #fromSlots < 0 then
		self:Print(format('No items were found in %s for %s', search, fromLoc))
		return
	end

	moveItems(fromSlots, getSlots(toBags))
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