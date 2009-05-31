--[[
	itemSlotInfo.lua
		Generic methods for accessing item slot information
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local ItemSlotInfo = {}
Bagnon.ItemSlotInfo = ItemSlotInfo


function ItemSlotInfo:GetItemInfo(player, bag, slot)
	local link, count, texture, quality, readable, locked, lootable
	if self:IsCached(player, bag, slot) then
		if BagnonDB then
			link, count, texture, quality = BagnonDB:GetItemData(bag, slot, player)
		end
	else
		texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
	end
	return texture, count, locked, quality, readable, lootable, link
end

function ItemSlotInfo:IsLocked(player, bag, slot)
	if self:IsCached(player, bag, slot) then
		return false
	end
	return (select(3, GetContainerItemInfo(bag, slot)))
end

function ItemSlotInfo:IsCached(player, bag, slot)
	return Bagnon.BagSlotInfo:IsCached(player, bag)
end