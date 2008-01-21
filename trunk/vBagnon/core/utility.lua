--[[
	vBagnon\utility.lua
		Helper functions for Bagnon
--]]

local currentPlayer = UnitName("player")
local playerID = currentPlayer .. ':' .. GetRealmName()

local function GetBagID(bag, player)
	if player and player ~= currentPlayer then
		if BagnonDB then
			return select(2, BagnonDB.GetBagData(player, bag))
		end
	else
		return GetInventoryItemLink('player', Bagnon_GetInvSlot(bag))
	end
end


--[[ Boolean functions ]]--

function Bagnon_IsInventoryBag(bag)
	return bag == KEYRING_CONTAINER or (bag > -1 and bag < 5)
end

function Bagnon_IsBankBag(bag)
	return bag == -1 or (bag > 4 and bag < 12)
end

function Bagnon_GetShownBags(type)
	local sets = Bagnon_GetPlayerSets()[type]
	if sets then
		return pairs(sets.bags)
	end
end

--returns if the given bag is an ammo bag/soul bag
function Bagnon_IsAmmoBag(bag, player)
	--bankslots, the main bag, and the keyring cannot be ammo slots
	if bag <= 0 then return end

	local id = GetBagID(bag, player)
	if id then
		local type, subType = select(6, GetItemInfo(id))
		return (type == BAGNON_TYPE['Quiver'] or subType == BAGNON_SUBTYPE['Soul Bag'])
	end
end

--returns if the given bag is a profession bag (herb bag, engineering bag, etc)
function Bagnon_IsProfessionBag(bag, player)
	--bankslots, the main bag, and the keyring cannot be profession bags
	if bag <= 0 then return end

	local id = GetBagID(bag, player)
	if id then
		local type, subType = select(6, GetItemInfo(id))
		return type == BAGNON_TYPE['Container'] and not (subType == BAGNON_SUBTYPE['Bag'] or subType == BAGNON_SUBTYPE['Soul Bag'])
	end
end


--[[ Detection for Cached Frames.  Only works if we have cached data available ]]--

function Bagnon_IsCachedBag(player, bag) 
	if BagnonDB then
		return currentPlayer ~= (player or currentPlayer) or (not Bagnon_PlayerAtBank() and Bagnon_IsBankBag(bag))
	end
end


--[[ Positioning ]]--

function Bagnon_AnchorTooltip(frame)
	if frame:GetRight() >= (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
	else
		GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
	end
end

function Bagnon_AttachToFrame(frame, parent)
	frame:SetParent(parent)
	frame:SetAlpha(parent:GetAlpha())
	frame:SetFrameLevel(1)
end

function Bagnon_AnchorAtCursor(frame)
	local x, y = GetCursorPosition()
	x = x / UIParent:GetScale()
	y = y / UIParent:GetScale()
				
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x - 32, y + 32)
end


--[[ Messaging ]]--

--send a message to the player
function BagnonMsg(msg)
	ChatFrame1:AddMessage(msg or 'nil', 0, 0.7, 1)
end


--[[ Wrapper Functions ]]--

function Bagnon_GetInvSlot(bag)
	local invSlot
	if bag <= 0 then
		return nil
	else
		invSlot = ContainerIDToInventoryID(bag)
	end
	return invSlot
end

function Bagnon_GetSize(bag, player)
	if Bagnon_IsCachedBag(player, bag) then
		return BagnonDB.GetBagData(player, bag) or 0
	else
		if Bagnon_IsBankBag(bag) and not Bagnon_PlayerAtBank() then
			return 0
		elseif bag == KEYRING_CONTAINER then
			return GetKeyRingSize()
		end
		return GetContainerNumSlots(bag)
	end
end

function Bagnon_GetItemLink(player, bag, slot)
	if Bagnon_IsCachedBag(player, bag) then
		return (BagnonDB.GetItemData(player, bag, slot))
	else
		return GetContainerItemLink(bag, slot)
	end
end

function Bagnon_GetItemCount(player, bag, slot)
	if Bagnon_IsCachedBag(player, bag) then
		local link, count = BagnonDB.GetItemData(player, bag, slot)
		if link and not count then
			return 1
		elseif count then
			return count
		end
		return 0
	else
		return select(2, GetContainerItemInfo(bag, slot)) or 0
	end
end


--[[ Player Stuff ]]--

function Bagnon_GetPlayerID()
	return playerID
end

function Bagnon_GetPlayerSets()
	return BagnonSets[playerID]
end