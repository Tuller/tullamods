--[[
	PocketUtil
		A library of functions for accessing bag data
--]]

PocketUtil = {}
local L = BAGNON_LOCALS
local currentPlayer = UnitName("player")


--[[ Item/Bag Info Retrieval ]]--

function PocketUtil:GetInvSlot(bag)
	if bag > 0 then
		return ContainerIDToInventoryID(bag)
	end
end

function PocketUtil:GetBagSize(bag)
	return (bag == KEYRING_CONTAINER and GetKeyRingSize()) or GetContainerNumSlots(bag)
end

function PocketUtil:GetBagLink(bag)
	return GetInventoryItemLink("player", self:GetInvSlot(bag))
end

function PocketUtil:GetItemLink(bag, slot)
	return GetContainerItemLink(bag, slot)
end

function PocketUtil:GetItemCount(bag, slot)
	return select(2, GetContainerItemInfo(bag, slot)) or 0
end


--[[ Bag Type Booleans ]]--

--returns if the given bag is an ammo bag/soul bag
--bankslots, the main bag, and the keyring cannot be ammo slots
function PocketUtil:IsAmmoBag(bag)
	if bag <= 0 then return nil end

	local link = self:GetBagLink(bag)
	if link then
		local type, subType = select(6, GetItemInfo(link))
		return (type == L.TypeQuiver or subType == L.SubTypeSoulBag)
	end
end

--returns if the given bag is a profession bag (herb bag, engineering bag, etc)
--bankslots, the main bag, and the keyring cannot be ammo slots
function PocketUtil:IsProfessionBag(bag)
	if bag <= 0 then return nil end

	local link = self:GetBagLink(bag)
	if link then
		local type, subType = select(6, GetItemInfo(link))
		return type == L.TypeContainer and not(subType == L.SubTypeBag or subType == L.SubTypeSoulBag)
	end
end


--[[ Positioning Functions ]]--

function PocketUtil:AnchorTooltip(frame)
	if frame:GetRight() >= (GetScreenWidth()/2) then
		GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
	else
		GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
	end
end

function PocketUtil:Attach(frame, parent)
	frame:SetParent(parent)
	frame:SetFrameLevel(1)
end