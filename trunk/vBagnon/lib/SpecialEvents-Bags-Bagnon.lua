--[[
	Name: SpecialEvents-Bags-Bagnon
		Author: Tekkub Stoutwrithe (tekkub@gmail.com)
		Website: http://www.wowace.com/
		Description: Special events for bag/slot changes

	I've modified the code to use BEvent, and also to add a bit more functionality
]]

assert('BEvent', 'BEvent not loaded')

local bags = {}
local atBank = false

local function IsInventoryBag(bag) 
	return bag == KEYRING_CONTAINER or (bag > -1 and bag < 5) 
end

local function IsBankBag(bag) 
	return (bag == -1 or bag > 4) 
end

function Bagnon_PlayerAtBank() 
	return atBank 
end

local function GetSize(bag)
	if IsBankBag(bag) and not atBank then
		return 0
	elseif bag == KEYRING_CONTAINER then
		return GetKeyRingSize()
	end
	return GetContainerNumSlots(bag)
end


--[[ Update ]]--

local function RemoveData(bag)
	local bagData = bags[bag]	
	if not bagData then return end

	for slot in pairs(bagData) do
		bagData[slot][1] = nil
		bagData[slot][2] = nil
		BEvent:CallEvent('SPECIAL_BAG_SLOT_REMOVED', bag, slot)
	end
end

local function CheckAndUpdate(bag)
	if IsInventoryBag(bag) or IsBankBag(bag) then
		if not bags[bag] then bags[bag] = {} end
		
		local bagSize = GetSize(bag)
		for slot = 1, bagSize do
			if not bags[bag][slot] then bags[bag][slot] = {} end

			local itemData = bags[bag][slot]
			local oldLink = itemData[1]
			local oldCount = itemData[2]
			local itemLink = GetContainerItemLink(bag, slot)
			local count, locked = select(2, GetContainerItemInfo(bag, slot))

			if not(oldLink == itemLink and oldCount == count) then
				itemData[1] = itemLink
				itemData[2] = count
				BEvent:CallEvent('SPECIAL_BAG_SLOT_UPDATE', bag, slot, itemLink, count)
			end
			
			local oldLocked = itemData[3]
			if not(oldLocked == locked) then
				itemData[3] = locked
				BEvent:CallEvent('SPECIAL_BAG_SLOT_UPDATE_LOCK', bag, slot, locked)
			end
		end

		for slot, itemData in pairs(bags[bag]) do
			if slot > bagSize then
				itemData[1] = nil
				itemData[2] = nil
				itemData[3] = nil
				BEvent:CallEvent('SPECIAL_BAG_SLOT_REMOVED', bag, slot)
			end
		end
	end
end

local function UpdateLockForBag(bag)
	if not bags[bag] then bags[bag] = {} end
	
	local bagSize = GetSize(bag)
	for slot = 1, bagSize do
		if not bags[bag][slot] then bags[bag][slot] = {} end
		
		local oldLocked = bags[bag][slot][3]
		local locked = select(3, GetContainerItemInfo(bag, slot))	

		if oldLocked ~= locked then
			bags[bag][slot][3] = locked
			BEvent:CallEvent('SPECIAL_BAG_SLOT_UPDATE_LOCK', bag, slot, locked)
		end
	end
end

--[[ Events ]]--

BEvent:AddAction('PLAYER_LOGIN', function() 
	CheckAndUpdate(0)
	CheckAndUpdate(KEYRING_CONTAINER) 
end)

BEvent:AddAction('BAG_UPDATE', function() CheckAndUpdate(arg1) end)

BEvent:AddAction('PLAYERBANKSLOTS_CHANGED', function() 
	for bag = -2, GetNumBankSlots() + 4 do
		CheckAndUpdate(bag)
	end
end)

--[[ Bank Events ]]--

BEvent:AddAction('BANKFRAME_OPENED', function() 
	atBank = true 

	CheckAndUpdate(-1)
	for bag = 5, GetNumBankSlots() + 4 do
		CheckAndUpdate(bag)
	end
end)

BEvent:AddAction('BANKFRAME_CLOSED', function() atBank = nil end)

--[[ Key Events ]]--

--the keyring updates in size when the player levels up
BEvent:AddAction('PLAYER_LEVEL_UP', function() CheckAndUpdate(KEYRING_CONTAINER) end)

--[[ Lock Events ]]--

BEvent:AddAction('ITEM_LOCK_CHANGED', function()
	if atBank then
		for bag = -1, GetNumBankSlots() + 4 do
			UpdateLockForBag(bag)
		end
	else
		for bag = 0, 4 do
			UpdateLockForBag(bag)
		end
	end
	UpdateLockForBag(KEYRING_CONTAINER)
end)