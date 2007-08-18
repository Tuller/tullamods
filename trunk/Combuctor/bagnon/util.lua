--[[
	BagnonUtil
		A library of functions for accessing bag data
--]]

BagnonUtil = {}
BagnonUtil.atBank = false

local LIBRARY_VERSION_MAJOR = "BagnonUtil"
local LIBRARY_VERSION_MINOR = tonumber(string.match("$Revision: 44 $", "(%d+)") or 1)


--[[ Usable Functions ]]--

local currentPlayer = UnitName("player")
local typeContainer = select(3, GetAuctionItemClasses())
local typeQuiver = select(7, GetAuctionItemClasses())
local subTypeBag = select(1, GetAuctionItemSubClasses(3))
local subTypeSoulBag = select(2, GetAuctionItemSubClasses(3))


--[[ Bank ]]--

function BagnonUtil:SetAtBank(atBank)
	self.atBank = atBank or nil
end

function BagnonUtil:AtBank()
	return self.atBank
end


--[[ Item/Bag Info Retrieval ]]--

function BagnonUtil:GetInvSlot(bag)
	return bag > 0 and ContainerIDToInventoryID(bag)
end

function BagnonUtil:GetBagSize(bag, player)
	if self:IsCachedBag(bag, player) then
		return (BagnonDB and (BagnonDB:GetBagData(bag, player))) or 0
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
	if(bag == BANKFRAME_CONTAINER) then
		GetInventoryItemLink("player", BankButtonIDToInvSlotID(slot))
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
	return (select(2, GetContainerItemInfo(bag, slot)))
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
	return (bag == BANKFRAME_CONTAINER or bag > 4)
end

--returns if the given bag is an ammo bag/soul bag
--bankslots, the main bag, and the keyring cannot be ammo slots
function BagnonUtil:IsAmmoBag(bag, player)
	if bag <= 0 then return nil end

	local link = self:GetBagLink(bag, player)
	if link then
		local type, subType = select(6, GetItemInfo(link))
		return (type == typeQuiver or subType == subTypeSoulBag)
	end
end

--returns if the given bag is a profession bag (herb bag, engineering bag, etc)
--bankslots, the main bag, and the keyring cannot be ammo slots
function BagnonUtil:IsProfessionBag(bag, player)
	if bag <= 0 then return nil end

	local link = self:GetBagLink(bag, player)
	if link then
		local type, subType = select(6, GetItemInfo(link))
		return type == typeContainer and not(subType == subTypeBag or subType == subTypeSoulBag)
	end
end


--[[ Positioning Functions ]]--

function BagnonUtil:AnchorTooltip(frame)
	if frame:GetRight() >= (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
	else
		GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
	end
end

-- function BagnonUtil:AnchorAtCursor(frame)
	-- local x,y = GetCursorPosition()
	-- local scale = UIParent:GetScale()

	-- frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x/scale - 32, y/scale + 32)
-- end

function BagnonUtil:Attach(frame, parent)
	frame:SetParent(parent)
	frame:SetFrameLevel(1)
end