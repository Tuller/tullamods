--[[
	CombuctorUtil
		A library of functions for accessing bag data
--]]

local CombuctorUtil = Combuctor:NewModule('Utility', 'AceEvent-3.0')
local currentPlayer = UnitName('player')

--[[ Bank ]]--

function CombuctorUtil:UpdateBank(event)
	self.atBank = (event == 'BANKFRAME_OPENED')
end

function CombuctorUtil:AtBank()
	return self.atBank
end


--[[ Item/Bag Info Wrapper Functions ]]--

--bag stuff
function CombuctorUtil:GetInvSlot(bag)
	return bag > 0 and ContainerIDToInventoryID(bag)
end

function CombuctorUtil:GetBagSize(bag, player)
	if self:IsCachedBag(bag, player) then
		return (BagnonDB and BagnonDB:GetBagData(bag, player)) or 0
	end
	return (bag == KEYRING_CONTAINER and GetKeyRingSize()) or GetContainerNumSlots(bag)
end

function CombuctorUtil:GetBagLink(bag, player)
	if self:IsCachedBag(bag, player) then
		return BagnonDB and (select(2, BagnonDB:GetBagData(bag, player)))
	end
	return GetInventoryItemLink('player', self:GetInvSlot(bag))
end

function CombuctorUtil:GetBagType(bag, player)
	if bag == KEYRING_CONTAINER then
		return 256
	elseif bag > 0 then
		local link = CombuctorUtil:GetBagLink(bag, player)
		return link and GetItemFamily(link)
	else
		return 0
	end
end

--item stuff
function CombuctorUtil:GetItemLink(bag, slot, player)
	if self:IsCachedBag(bag, player) then
		return BagnonDB and (BagnonDB:GetItemData(bag, slot, player))
	end
	return GetContainerItemLink(bag, slot)
end

function CombuctorUtil:GetItemCount(bag, slot, player)
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
function CombuctorUtil:IsCachedBag(bag, player)
	return currentPlayer ~= (player or currentPlayer) or (self:IsBankBag(bag) and not self:AtBank())
end

function CombuctorUtil:IsInventoryBag(bag)
	return bag == KEYRING_CONTAINER or (bag > -1 and bag < 5)
end

function CombuctorUtil:IsBankBag(bag)
	return (bag == BANK_CONTAINER or bag > 4)
end

--register those events
CombuctorUtil:RegisterEvent('BANKFRAME_OPENED', 'UpdateBank')
CombuctorUtil:RegisterEvent('BANKFRAME_CLOSED', 'UpdateBank')