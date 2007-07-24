--[[
	Bagnon-ItemEvents
		Sends dongle messages when certain events happen to items in the player's inventory

	BAGNON_ITEM_GAINED
	args:		bag, slot, link
		called when a new item is put into a slot

	BAGNON_ITEM_LOST
	args:		bags, slot, newLink, oldLink
		called when newLink replaces oldLink in the given slot, and the count of oldLink changes

	BAGNON_ITEM_SWAPPED
	args:		bag, slot, newLink, oldLink
		called when newLink replaces oldLink, but the counts of each item remain the same

	BAGNON_ITEM_COUNT_CHANGED
	args:		bag, slot, link
		called when the count of link in the given slot changes
--]]

local events = DongleStub("Dongle-1.0"):New("Bagnon-ItemEvents")
local counts, items = {}, {}


--[[ Local Functions ]]--

local function ToIndex(bag, slot)
	return (bag < 0 and bag*100 - slot) or bag*100 + slot
end

local function GetBagSize(bag)
	return (bag == KEYRING_CONTAINER and GetKeyRingSize()) or GetContainerNumSlots(bag)
end

local function IsBankBag(bag)
	return (bag == BANK_CONTAINER or bag > 4)
end


--[[ Events ]]--

function events:Enable()
	self:RegisterMessage("BAGNON_BAGS_LOADED")
end

function events:BAGNON_BAGS_LOADED()
	self:UpdateItemCounts()

	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("BANKFRAME_CLOSED")
	self:RegisterMessage("BAGNON_SLOT_ADD", "OnSlotChanged")
	self:RegisterMessage("BAGNON_SLOT_UPDATE", "OnSlotChanged")
end

function events:BANKFRAME_OPENED()
	self:UnregisterMessage("BAGNON_SLOT_ADD")
	self:UnregisterMessage("BAGNON_SLOT_UPDATE")
end

function events:BANKFRAME_CLOSED()
	self:UpdateItemCounts()
	self:RegisterMessage("BAGNON_SLOT_ADD", "OnSlotChanged")
	self:RegisterMessage("BAGNON_SLOT_UPDATE", "OnSlotChanged")
end

function events:OnSlotChanged(msg, bag, slot, link)
	if(not IsBankBag(bag)) then
		self:UpdateSlot(bag, slot, link, true)
	end
end


--[[ Update Functions ]]--

function events:UpdateCount(link)
	local prevCount = counts[link] or 0
	local newCount = GetItemCount(link) or 0
	counts[link] = (newCount ~= 0 and newCount) or nil

	return prevCount ~= newCount
end

function events:UpdateSlot(bag, slot, link, fireEvents)
	local index = ToIndex(bag, slot)
	local prevLink = items[index]
	local itemGained, itemLost, itemSwapped, countChanged
	items[index] = link

	--same item in the slot
	if(prevLink == link) then
		--count changed
		if(link and self:UpdateCount(link)) then
			countChanged = true
		end
	--slot item changed
	else
		if(prevLink) then
			--count change, we probably lost the old item
			if(self:UpdateCount(prevLink)) then
				itemLost = true
			--no count change, two items switched places
			else
				itemSwapped = true
			end
		end

		if(link) then
			--count changed, we probably gained a new item
			if(self:UpdateCount(link)) then
				itemGained = true
			--no count change, two items switched places
			else
				itemSwapped = true
			end
		end
	end

	if(fireEvents) then
		if(itemGained) then
			self:TriggerMessage("BAGNON_ITEM_GAINED", bag, slot, link)
		elseif(itemLost) then
			self:TriggerMessage("BAGNON_ITEM_LOST", bag, slot, link, prevLink)
		elseif(itemSwapped) then
			self:TriggerMessage("BAGNON_ITEM_SWAPPED", bag, slot, link, prevLink)
		elseif(countChanged) then
			self:TriggerMessage("BAGNON_ITEM_COUNT_CHANGED", bag, slot, link)
		end
	end
end

function events:UpdateItemCounts()
	for slot = 0, GetBagSize(KEYRING_CONTAINER) do
		self:UpdateSlot(KEYRING_CONTAINER, slot, GetContainerItemLink(KEYRING_CONTAINER, slot))
	end

	for bag = 0, 4 do
		for slot = 0, GetBagSize(bag) do
			self:UpdateSlot(bag, slot, GetContainerItemLink(bag, slot))
		end
	end
end