--[[
	bagInfo.lua
		Generic methods for accessing bag slot information
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local BagInfo = {}
Bagnon.BagInfo = BagInfo

--returns true if the given bagSlot for the given player is cached
function BagInfo:IsCached(player, bagSlot)
	if Bagnon.PlayerInfo:IsCached(player) then
		return true
	end
	
	if self:IsBank(bagSlot) or self:IsBankBag(bagSlot) then
		return not Bagnon.PlayerInfo:AtBank()
	end

	return false
end

--returns true if the given bagSlot is a purchasable bank slot
function BagInfo:IsBankBag(bagSlot)
	return bagSlot > NUM_BAG_SLOTS and bagSlot < (NUM_BAG_SLOTS + NUM_BANKBAGSLOTS + 1)
end

--returns true if the given bagSlot is the bank container slot
function BagInfo:IsBank(bagSlot)
	return bagSlot == BANK_CONTAINER
end

--returns true if the given bagSlot is the backpack
function BagInfo:IsBackpack(bagSlot)
	return bagSlot == BACKPACK_CONTAINER
end

--returns true if the given bagSlot is an optional inventory bag slot
function BagInfo:IsBackpackBag(bagSlot)
	return bagSlot > 0 and bagSlot < (NUM_BAG_SLOTS + 1)
end

--returns true if the given bagSlot is the keyring
function BagInfo:IsKeyRing(bagSlot)
	return bagSlot == KEYRING_CONTAINER
end

--returns the size of the given bag slot
function BagInfo:GetSize(player, bagSlot)
	local size = 0
	if self:IsCached(player, bagSlot) then
		if BagnonDB then
			size = (BagnonDB:GetBagData(bagSlot, player)) or 0
		end
	elseif self:IsBank() then
		size = NUM_BANKGENERIC_SLOTS
	elseif self:IsKeyRing(bagSlot) then
		size = GetKeyRingSize()
	else
		size = GetContainerNumSlots(bagSlot)
	end
	return size
end

--returns the itemLink, number of items in, and item icon texture of the given bagSlot
function BagInfo:GetItemInfo(player, bagSlot)
	local link, texture, count, size
	if self:IsBagSlotCached(player, bagSlot) then
		if BagnonDB then
			size, link, count, texture = BagnonDB:GetBagData(self:GetID(), self:GetPlayer())
		end
	else
		local invSlot = self:GetBagSlotInventorySlot(bagSlot)
		link = GetInventoryItemLink('player', invSlot)
		texture = GetInventoryItemTexture('player', invSlot)
		count = GetInventoryItemCount('player', invSlot)
	end
	return link, count, texture
end

--converts the given bag slot into an applicable inventory slot
function BagInfo:GetInventorySlot(bagSlot)
	if self:IsBagSlotBackpackSlot() then
		return ContainerIDToInventoryID(bagSlot)
	end
	if self:IsBagSlotBankSlot() then
		return BankButtonIDToInvSlotID(bagSlot, 1)
	end
	return nil
end


--[[ Item Slot Info ]]--

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local BagInfo = {}
Bagnon.BagInfo = BagInfo

function InventoryInfo:GetItemInfo(player, bag, slot)
	local link, count, texture, quality, readable, locked, lootable
	if self:IsBagSlotCached(player, bag) then
		if BagnonDB then
			link, count, texture, quality = BagnonDB:GetItemData(bag, slot, player)
		end
	else
		texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
	end
	return texture, count, locked, quality, readable, lootable, link
end