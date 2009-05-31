--[[
	bagSlotInfo.lua
		Generic methods for accessing bag slot information
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local BagSlotInfo = {}
Bagnon.BagSlotInfo = BagSlotInfo


--[[ Slot Info ]]--

--returns true if the given bagSlot is a purchasable bank slot
function BagSlotInfo:IsBankBag(bagSlot)
	--assert(tonumber(bagSlot), 'Usage: BagSlotInfo:IsBankBag(bagSlot)')

	return bagSlot > NUM_BAG_SLOTS and bagSlot < (NUM_BAG_SLOTS + NUM_BANKBAGSLOTS + 1)
end

--returns true if the given bagSlot is the bank container slot
function BagSlotInfo:IsBank(bagSlot)
	--assert(tonumber(bagSlot), 'Usage: BagSlotInfo:IsBank(bagSlot)')

	return bagSlot == BANK_CONTAINER
end

--returns true if the given bagSlot is the backpack
function BagSlotInfo:IsBackpack(bagSlot)
	--assert(tonumber(bagSlot), 'Usage: BagSlotInfo:IsBackpack(bagSlot)')

	return bagSlot == BACKPACK_CONTAINER
end

--returns true if the given bagSlot is an optional inventory bag slot
function BagSlotInfo:IsBackpackBag(bagSlot)
	--assert(tonumber(bagSlot), 'Usage: BagSlotInfo:IsBackpackBag(bagSlot)')

	return bagSlot > 0 and bagSlot < (NUM_BAG_SLOTS + 1)
end

--returns true if the given bagSlot is the keyring
function BagSlotInfo:IsKeyRing(bagSlot)
	--assert(tonumber(bagSlot), 'Usage: BagSlotInfo:IsKeyRing(bagSlot)')

	return bagSlot == KEYRING_CONTAINER
end

--returns true if the given bagSlot for the given player is cached
function BagSlotInfo:IsCached(player, bagSlot)
	--assert(player and tonumber(bagSlot), 'Usage: BagSlotInfo:IsCached(player, bagSlot)')

	if Bagnon.PlayerInfo:IsCached(player) then
		return true
	end

	if self:IsBank(bagSlot) or self:IsBankBag(bagSlot) then
		return not Bagnon.PlayerInfo:AtBank()
	end

	return false
end

--returns true if the given bagSlot is purchasable for the given player and false otherwise
function BagSlotInfo:IsPurchasable(player, bagSlot)
	--assert(player and tonumber(bagSlot), 'Usage: BagSlotInfo:IsPurchasable(player, bagSlot)')

	local purchasedSlots
	if self:IsCached(player, bagSlot) then
		if BagnonDB then
			purchasedSlots = BagnonDB:GetNumBankSlots(player) or 0
		else
			purchasedSlots = 0
		end
	else
		purchasedSlots = GetNumBankSlots()
	end
	return bagSlot > (purchasedSlots + NUM_BAG_SLOTS)
end

function BagSlotInfo:IsLocked(player, bagSlot)
	--assert(player and tonumber(bagSlot), 'Usage: BagSlotInfo:IsLocked(player, bagSlot)')

	if self:IsBackpack(bagSlot) or self:IsKeyRing(bagSlot) or self:IsBank(bagSlot) or self:IsCached(player, bagSlot) then
		return false
	end
	return IsInventoryItemLocked(self:ToInventorySlot(bagSlot))
end


--[[ Slot Item Info ]]--

--returns how many items can fit in the given bag
function BagSlotInfo:GetSize(player, bagSlot)
	--assert(player and tonumber(bagSlot), 'Usage: BagSlotInfo:GetSize(player, bagSlot)')

	local size = 0
	if self:IsCached(player, bagSlot) then
		if BagnonDB then
			size = (BagnonDB:GetBagData(bagSlot, player)) or 0
		end
	elseif self:IsBank(bagSlot) then
		size = NUM_BANKGENERIC_SLOTS
	elseif self:IsKeyRing(bagSlot) then
		size = GetKeyRingSize()
	else
		size = GetContainerNumSlots(bagSlot)
	end
	return size
end

--returns the itemLink, number of items in, and item icon texture of the given bagSlot
function BagSlotInfo:GetItemInfo(player, bagSlot)
	--assert(player and tonumber(bagSlot), 'Usage: BagSlotInfo:GetItemInfo(player, bagSlot)')

	local link, texture, count, size
	if self:IsCached(player, bagSlot) then
		if BagnonDB then
			size, link, count, texture = BagnonDB:GetBagData(bagSlot, player)
		end
	else
		local invSlot = self:ToInventorySlot(bagSlot)
		link = GetInventoryItemLink('player', invSlot)
		texture = GetInventoryItemTexture('player', invSlot)
		count = GetInventoryItemCount('player', invSlot)
	end
	return link, count, texture
end


--[[ Conversion Methods ]]--

--converts the given bag slot into an applicable inventory slot
function BagSlotInfo:ToInventorySlot(bagSlot)
	--assert(tonumber(bagSlot), 'Usage: BagSlotInfo:ToInventorySlot(bagSlot)')

	if self:IsBackpackBag(bagSlot) then
		return ContainerIDToInventoryID(bagSlot)
	end
	if self:IsBankBag(bagSlot) then
		return BankButtonIDToInvSlotID(bagSlot, 1)
	end
	return nil
end