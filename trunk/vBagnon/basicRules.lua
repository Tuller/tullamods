--[[
	rules.lua
		Basic rules for vBagnon
--]]

--Rules for item quality
local function LoadQualityRules()
	for i = 0, 6 do
		BagnonRule[getglobal('ITEM_QUALITY' .. i .. '_DESC')] = function(link)
			local quality = select(3, Bagnon_GetData(link))
			return quality == i
		end
	end
end
LoadQualityRules()

--Rules for item type, subtype, and equip location
local function LoadTypeRules()
	for _, subType in pairs(BAGNON_SUBTYPE) do
		BagnonRule[subType] = function(link)
			return select(7, Bagnon_GetData(link)) == subType
		end
	end

	for _, type in pairs(BAGNON_TYPE) do
		BagnonRule[type] = function(link)
			return select(6, Bagnon_GetData(link)) == type
		end
	end

	for i = 1, select('#', GetAuctionItemClasses()) do
		for j = 1, select('#', GetAuctionItemSubClasses(i)) do
			for k = 1, select('#', GetAuctionInvTypes(i, j)) do
				local loc = select(k, GetAuctionInvTypes(i, j))
				BagnonRule[getglobal(loc)] = function(link)
					return select(8, Bagnon_GetData(link)) == loc
				end
			end
		end
	end
end
LoadTypeRules()

--All slots
BagnonRule[BAGNON_RULE_ALL] = function()
	return true 
end

--All slots with items
BagnonRule[BAGNON_RULE_ITEMS] = function(link) 
	return link 
end

--Empty slots
BagnonRule[BAGNON_RULE_EMPTY] = function(link) 
	return not link 
end

--[[ Bag Checks ]]--

--In the bank
BagnonRule[BAGNON_RULE_BANK] = function(_, bag)
	return Bagnon_IsBankBag(bag)
end

--In the player's inventory
BagnonRule[BAGNON_RULE_INVENTORY] = function(_, bag)
	return Bagnon_IsInventoryBag(bag)
end

--In an ammo/shard bag
BagnonRule[BAGNON_RULE_AMMO_SLOTS] = function(_, bag)
	return Bagnon_IsAmmoBag(bag)
end

--In a profession bag
BagnonRule[BAGNON_RULE_PROFESSION_SLOTS] = function(_, bag)
	return Bagnon_IsProfessionBag(bag)
end

--bandages
BagnonRule[BAGNON_RULE_BANDAGE] = function(link)
	local name, _, _, _, type = select(2, Bagnon_GetData(link))
	return type == BAGNON_TYPE['Consumable'] and name:find(BAGNON_STRING_BANDAGE)
end

--bandages
BagnonRule[BAGNON_RULE_TRASH] = function(link)
	local quality = select(3, Bagnon_GetData(link))
	return quality == 0
end

--[[ Class Specific ]]--

local PLAYER_CLASS = select(2, UnitClass('player'))

if PLAYER_CLASS == 'ROGUE' then
	--poisons
	BagnonRule[BAGNON_RULE_POISON] = function(link)
		local name, _, _, _, type = select(2, Bagnon_GetData(link))
		return type == BAGNON_TYPE['Consumable'] and name:find(BAGNON_STRING_POISON)
	end
end