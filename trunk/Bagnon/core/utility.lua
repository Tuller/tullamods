--[[
	BagnonUtil
		A library of functions for accessing bag data
--]]

BagnonUtil = {}
local L = BAGNON_LOCALS

--[[ Usable Functions ]]--

local currentPlayer = UnitName('player')

--[[ Bank ]]--

function BagnonUtil:AtBank()
	return Bagnon.atBank
end

--[[ Item/Bag Info Retrieval ]]--

function BagnonUtil:GetInvSlot(bag)
	if bag > 0 then
		return ContainerIDToInventoryID(bag)
	end
end

function BagnonUtil:GetBagSize(bag, player)
	if self:IsCachedBag(bag, player) then
		if BagnonDB then
			return BagnonDB:GetBagData(bag, player) or 0
		end
	else
		if bag == KEYRING_CONTAINER then
			return GetKeyRingSize()
		else
			return GetContainerNumSlots(bag)
		end
	end
	return 0
end

function BagnonUtil:GetBagLink(bag, player)
	if self:IsCachedBag(bag, player) then
		if BagnonDB then
			return select(2, BagnonDB:GetBagData(bag, player))
		end
	else
		return GetInventoryItemLink('player', self:GetInvSlot(bag))
	end
end

function BagnonUtil:GetItemLink(bag, slot, player)
	if self:IsCachedBag(bag, player) then
		if BagnonDB then
			return (BagnonDB:GetItemData(bag, slot, player))
		end
	else
		return GetContainerItemLink(bag, slot)
	end
end

function BagnonUtil:GetItemCount(bag, slot, player)
	if self:IsCachedBag(bag, player) then
		if BagnonDB then
			local link, count = BagnonDB:GetItemData(bag, slot, player)
			if link then
				return count or 1
			end
		end
		return 0
	else
		return select(2, GetContainerItemInfo(bag, slot)) or 0
	end
end


--[[ Bag Type Booleans ]]--

--returns true if the given bag is cached AND we have a way of reading data for it
function BagnonUtil:IsCachedBag(bag, player)
	return currentPlayer ~= (player or currentPlayer) or (not self:AtBank() and self:IsBankBag(bag))
end

function BagnonUtil:IsInventoryBag(bag)
	return bag == KEYRING_CONTAINER or (bag > -1 and bag < 5)
end

function BagnonUtil:IsBankBag(bag)
	return (bag == -1 or bag > 4)
end

--returns if the given bag is an ammo bag/soul bag
--bankslots, the main bag, and the keyring cannot be ammo slots
function BagnonUtil:IsAmmoBag(bag, player)
	if bag <= 0 then return nil end

	local link = self:GetBagLink(bag, player)
	if link then
		local type, subType = select(6, GetItemInfo(link))
		return (type == L.TypeQuiver or subType == L.SubTypeSoulBag)
	end
end

--returns if the given bag is a profession bag (herb bag, engineering bag, etc)
--bankslots, the main bag, and the keyring cannot be ammo slots
function BagnonUtil:IsProfessionBag(bag, player)
	if bag <= 0 then return nil end

	local link = self:GetBagLink(bag, player)
	if link then
		local type, subType = select(6, GetItemInfo(link))
		return type == L.TypeContainer and not(subType == L.SubTypeBag or subType == L.SubTypeSoulBag)
	end
end


--[[ Positioning Functions ]]--

function BagnonUtil:AnchorTooltip(frame)
	if frame:GetRight() >= (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(frame, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(frame, 'ANCHOR_RIGHT')
	end
end

function BagnonUtil:AnchorAtCursor(frame)
	local x,y = GetCursorPosition()
	local scale = UIParent:GetScale()

	frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x/scale - 32, y/scale + 32)
end

function BagnonUtil:Attach(frame, parent)
	frame:SetParent(parent)
	frame:SetAlpha(parent:GetAlpha())
	frame:SetFrameLevel(1)
end


--[[ Settings ]]--

function BagnonUtil:GetSets()
	return Bagnon.sets
end

function BagnonUtil:ShowingOwners()
	return Bagnon.sets.showOwners
end

function BagnonUtil:ShowingBorders()
	return Bagnon.sets.showBorders
end

function BagnonUtil:ReusingFrames()
	return Bagnon.sets.reuseFrames
end

function BagnonUtil:ReplacingBags()
	return Bagnon.sets.replaceBags
end

function BagnonUtil:ReplacingBank()
	return Bagnon.sets.replaceBank
end