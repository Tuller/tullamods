--[[
	BagnonUtil
		A library of functions for accessing bag data
--]]

BagnonUtil = {}


local currentPlayer = UnitName("player")
local typeContainer = select(3, GetAuctionItemClasses())
local typeQuiver = select(7, GetAuctionItemClasses())
local subTypeBag = select(1, GetAuctionItemSubClasses(3))
local subTypeSoulBag = select(2, GetAuctionItemSubClasses(3))
local atBank = false


--[[ Bank ]]--

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event)
	atBank = (event == "BANKFRAME_OPENED")
end)
f:RegisterEvent("BANKFRAME_OPENED")
f:RegisterEvent("BANKFRAME_CLOSED")

function BagnonUtil:AtBank()
	return atBank
end


--[[ Item/Bag Info Wrapper Functions ]]--

function BagnonUtil:GetInvSlot(bag)
	return bag > 0 and ContainerIDToInventoryID(bag)
end

function BagnonUtil:GetBagSize(bag, player)
	if self:IsCachedBag(bag, player) then
		return (BagnonDB and BagnonDB:GetBagData(bag, player)) or 0
	end
	return (bag == KEYRING_CONTAINER and GetKeyRingSize()) or GetContainerNumSlots(bag)
end

function BagnonUtil:GetBagLink(bag, player)
	if self:IsCachedBag(bag, player) then
		return BagnonDB and (select(2, BagnonDB:GetBagData(bag, player)))
	end
	return GetInventoryItemLink("player", self:GetInvSlot(bag))
end

function BagnonUtil:GetItemLink(bag, slot, player)
	if self:IsCachedBag(bag, player) then
		return BagnonDB and (BagnonDB:GetItemData(bag, slot, player))
	end
	return GetContainerItemLink(bag, slot)
end

function BagnonUtil:GetItemCount(bag, slot, player)
	if self:IsCachedBag(bag, player) then
		if BagnonDB then
			local link, count = BagnonDB:GetItemData(bag, slot, player)
			if link then
				return count or 1
			end
		else
			return 0
		end
	end
	return select(2, GetContainerItemInfo(bag, slot)) 
end


--[[ Bag Type Comparisons ]]--

--returns true if the given bag is cached AND we have a way of reading data for it
function BagnonUtil:IsCachedBag(bag, player)
	return currentPlayer ~= (player or currentPlayer) or (self:IsBankBag(bag) and not self:AtBank())
end

function BagnonUtil:IsInventoryBag(bag)
	return bag == KEYRING_CONTAINER or (bag > -1 and bag < 5)
end

function BagnonUtil:IsBankBag(bag)
	return (bag == BANKFRAME_CONTAINER or bag > 4)
end

--returns if the given bag is an ammo bag/soul bag
--bankslots, the main bag, and the keyring cannot be ammo slots
function BagnonUtil:IsAmmoBag(bag, player)
	if bag > 0 then
		local link = self:GetBagLink(bag, player)
		if link then
			local type, subType = select(6, GetItemInfo(link))
			return (type == typeQuiver or subType == subTypeSoulBag)
		end
	end
end

--returns if the given bag is a profession bag (herb bag, engineering bag, etc)
--bankslots, the main bag, and the keyring cannot be ammo slots
function BagnonUtil:IsProfessionBag(bag, player)
	if bag > 0 then
		local link = self:GetBagLink(bag, player)
		if link then
			local type, subType = select(6, GetItemInfo(link))
			return type == typeContainer and not(subType == subTypeBag or subType == subTypeSoulBag)
		end
	end
end