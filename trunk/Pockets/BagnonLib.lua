--[[
	BagnonLib
		A library of functions for accessing and updating bag slot information

	Based on SpecialEvents-Bags by Tekkub Stoutwrithe (tekkub@gmail.com)

	BAGNON_SLOT_ADD
	args:		bag, slot, link, count, locked, coolingDown
		called when a new slot becomes available to the player

	BAGNON_SLOT_UPDATE
	args:		bag, slot, link, count, locked, coolingDown
		called when an item slot is updated

	BAGNON_SLOT_UPDATE_LOCK
		args:		bag, slot, locked
		called when an item slot is locked or unlocked

	BAGNON_SLOT_UPDATE_COOLDOWN
	args:		bag, slot, coolingDown
		called when an item"s cooldown starts/ends

	BAGNON_SLOT_REMOVE
	args:		bag, slot
		called when an item slot is removed from being in use
--]]

BagnonLib = DongleStub("Dongle-1.0"):New("BagnonLib")
BagnonLib.atBank = false
BagnonLib.firstVisit = true

local slots = {}

local function ToIndex(bag, slot)
	return (bag < 0 and bag*100 - slot) or bag*100 + slot
end

local function GetBagSize(bag)
	return (bag == KEYRING_CONTAINER and GetKeyRingSize()) or GetContainerNumSlots(bag)
end

function BagnonLib:Initialize()
	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("ITEM_LOCK_CHANGED")
	self:RegisterEvent("BAG_UPDATE_COOLDOWN")
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")

	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("BANKFRAME_CLOSED")
end


--[[ Update Functions ]]--

--all info
function BagnonLib:AddItem(bag, slot)
	local index = ToIndex(bag,slot)
	if not slots[index] then slots[index] = {} end

	local data = slots[index]
	local link = GetContainerItemLink(bag, slot)
	local count, locked = select(2, GetContainerItemInfo(bag, slot))
	local start, duration, enable = GetContainerItemCooldown(bag, slot)
	local onCooldown = (start > 0 and duration > 0 and enable == 1)

	data[1] = link; data[2] = count; data[3] = locked; data[4] = onCooldown

	self:TriggerMessage("BAGNON_SLOT_ADD", bag, slot, link, count, locked, onCooldown)
end

function BagnonLib:RemoveItem(bag, slot)
	local data = slots[ToIndex(bag, slot)]
	if data and next(data) then
		for i in pairs(data) do data[i] = nil end
		self:TriggerMessage("BAGNON_SLOT_REMOVE", bag, slot)
	end
end

function BagnonLib:UpdateItem(bag, slot)
	local data = slots[ToIndex(bag, slot)]
	if data then
		local prevLink = data[1]
		local prevCount = data[2]

		local link = GetContainerItemLink(bag, slot)
		local count, locked = select(2, GetContainerItemInfo(bag, slot))
		local start, duration, enable = GetContainerItemCooldown(bag, slot)
		local onCooldown = (start > 0 and duration > 0 and enable == 1)

		if prevLink ~= link or prevCount ~= count then
			data[1] = link; data[2] = count; data[3] = locked; data[4] = onCooldown
			self:TriggerMessage("BAGNON_SLOT_UPDATE", bag, slot, link, count, locked, onCooldown)
		end
	end
end

function BagnonLib:UpdateItems(bag)
	for slot = 1, GetBagSize(bag) do
		self:UpdateItem(bag, slot)
	end
end

--lock
function BagnonLib:UpdateLock(bag, slot)
	local data = slots[ToIndex(bag,slot)]
	if data and data[1] then
		local prevLocked = data[3]
		local locked = select(3, GetContainerItemInfo(bag, slot))
		if prevLocked ~= locked then
			data[3] = locked
			self:TriggerMessage("BAGNON_SLOT_UPDATE_LOCK", bag, slot, locked)
		end
	end
end

function BagnonLib:UpdateLocks(bag)
	for slot = 1, GetBagSize(bag) do
		self:UpdateLock(bag, slot)
	end
end

--cooldowns
function BagnonLib:UpdateCooldown(bag, slot)
	local data = slots[ToIndex(bag,slot)]
	if data and data[1] then
		local prevOnCooldown = data[4]
		local start, duration, enable = GetContainerItemCooldown(bag, slot)
		local onCooldown = (start > 0 and duration > 0 and enable == 1)

		if prevOnCooldown ~= onCooldown then
			data[4] = onCooldown
			self:TriggerMessage("BAGNON_SLOT_UPDATE_COOLDOWN", bag, slot, onCooldown)
		end
	end
end

function BagnonLib:UpdateCooldowns(bag)
	for slot = 1, GetBagSize(bag) do
		self:UpdateCooldown(bag, slot)
	end
end

--bag sizes
function BagnonLib:UpdateBagSize(bag)
	local prevSize = slots[bag*100] or 0
	local newSize = GetBagSize(bag) or 0
	slots[bag*100] = newSize

	if prevSize > newSize then
		for slot = newSize+1, prevSize do
			self:RemoveItem(bag, slot)
		end
	elseif prevSize < newSize then
		for slot = prevSize+1, newSize do
			self:AddItem(bag, slot)
		end
	end
end

function BagnonLib:UpdateBagSizes()
	if self.atBank then
		for bag = 1, GetNumBankSlots() + 4 do
			self:UpdateBagSize(bag)
		end
	else
		for bag = 1, 4 do
			self:UpdateBagSize(bag)
		end
	end
	self:UpdateBagSize(KEYRING_CONTAINER)
end


--[[ Events ]]--

--player login
function BagnonLib:Enable()
	self:UpdateBagSize(KEYRING_CONTAINER)
	self:UpdateBagSize(0)
end

function BagnonLib:BAG_UPDATE(event, bag)
	self:UpdateBagSizes()
	self:UpdateItems(bag)
end

function BagnonLib:PLAYERBANKSLOTS_CHANGED()
	self:UpdateBagSizes()
	self:UpdateItems(BANK_CONTAINER)
end

function BagnonLib:BANKFRAME_OPENED()
	self.atBank = true
	if self.firstVisit then
		self.firstVisit = nil
		self:UpdateBagSize(BANK_CONTAINER)
		self:UpdateBagSizes()
	end
end

function BagnonLib:BANKFRAME_CLOSED()
	self.atBank = false
end

function BagnonLib:ITEM_LOCK_CHANGED()
	if self.atBank then
		for bag = -2, GetNumBankSlots() + 4 do
			self:UpdateLocks(bag)
		end
	else
		for bag = 0, 4 do
			self:UpdateLocks(bag)
		end
		self:UpdateLocks(KEYRING_CONTAINER)
	end
end

function BagnonLib:BAG_UPDATE_COOLDOWN()
	for bag = 0, 4 do
		self:UpdateCooldowns(bag)
	end
end