--[[
	BagnonForever.lua
		Records inventory data about the current player
		
	BagnonForeverData has the following format, which was adapted from KC_Items
	BagnonForeverData = {
		Realm
			Character
				BagID = size,count,[link]
					ItemSlot = link,[count]
				Money = money
	}
	
	TODO:
		Use special events to save data
--]]

--local globals
local currentPlayer = UnitName("player") --the name of the current player that's logged on
local currentRealm = GetRealmName() --what currentRealm we're on

--[[ Utility Functions ]]--

--takes a hyperlink (what you see in chat) and converts it to a shortened item link.
--a shortened item link is either the item:w:x:y:z form without the 'item:' part, or just the item's ID (the 'w' part)
function BagnonForever_HyperlinkToShortLink(hyperLink)
	if hyperLink then
		local a,b,c,d,e,f,g,h = hyperLink:match("(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+)")
		if tonumber(b) == 0 and tonumber(c) == 0 and tonumber(d) == 0 and tonumber(e) == 0 and
			tonumber(f) == 0 and tonumber(g) == 0 and tonumber(h) == 0 then
			return a
		end
		return hyperLink:match("%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+")
	end
end


--[[  Storage Functions ]]--

--saves data about a specific item the current player has
local function SaveItemData(bag, slot)
	local texture, count = GetContainerItemInfo(bag, slot)
	local data = BagnonForeverData[currentRealm][currentPlayer][bag]
	
	if texture then
		local link = BagnonForever_HyperlinkToShortLink(GetContainerItemLink(bag, slot))
		if count > 1 then
			data[slot] = format('%s,%s', link, count)
		else
			data[slot] = link
		end
	else
		data[slot] = nil
	end
end

--saves all the data about the current player's bag
local function SaveBagData(bag)
	--don't save bank data unless you're at the bank
	if BagnonLib.IsBankBag(bag) and not BagnonLib.AtBank() then return end
	
	local size
	if bag == KEYRING_CONTAINER then
		size = GetKeyRingSize()
	else
		size = GetContainerNumSlots(bag)
	end
	
	local data = BagnonForeverData[currentRealm][currentPlayer]
	
	if size > 0 then
		if not data[bag] then
			data[bag]  = {}
		end
	
		local link, count
		
		if bag > 0 then
			link = BagnonForever_HyperlinkToShortLink(GetInventoryItemLink('player', BagnonLib.GetInvSlot(bag)))
		end	
		count = GetInventoryItemCount('player', BagnonLib.GetInvSlot(bag))
		
		--save bag size
		if link then
			data[bag].s = format('%s,%s,%s', size, count, link)
		else
			data[bag].s = format('%s,%s,', size, count)
		end

		--save all item info
		for index = 1, size, 1 do
			SaveItemData(bag, index)
		end
	elseif data[bag] then
		data[bag] = nil
	end
end

local function SavePlayerMoney()
	BagnonForeverData[currentRealm][currentPlayer].g = GetMoney()
end

--save all bank data about the current player
local function SaveBankData()
	SaveBagData(-1)
	for bag = 5, 11, 1 do
		SaveBagData(bag)
	end
end

local function SaveEquipmentData()
	local data = BagnonForeverData[currentRealm][currentPlayer]['e']
	if not data then
		BagnonForeverData[currentRealm][currentPlayer]['e'] = {}
		data = BagnonForeverData[currentRealm][currentPlayer]['e']
	end

	for i = 0, 19 do
		local link = GetInventoryItemLink('player', i)  
		if link then
			link = BagnonForever_HyperlinkToShortLink(link)
			local count = GetInventoryItemCount('player', i)
			if count > 1 then
				data[i] = format('%s,%s', link, count)
			else
				data[i] = link
			end
		else
			data[i] = nil
		end
	end
end


--[[ Removal Functions ]]--

--removes all saved data about the given player
function BagnonForever_RemovePlayer(player, realm)
	if BagnonForeverData[realm] then
		BagnonForeverData[realm][player] = nil
	end
end


--[[ Startup Functions ]]--

local function UpdateVersion(current)
	BagnonForeverData.version = current	
	BagnonMsg(format(BAGNON_FOREVER_UPDATED, current))
end


--[[
	BagnonForever's settings are set to default under the following conditions
		No saved variables (duh)
		Versions that did not know about the wowVersion (should only be on new installs)
		Right after any WoW Patch
		
	I think that the itemcache is rebuilt whenever there's an update to the game, so saved data becomes corrupt.
--]]
local function LoadVariables()	
	local current = GetAddOnMetadata('Bagnon', 'Version')
	
	if not BagnonForeverData then
		BagnonForeverData = {version = current}
	end
	
	if not BagnonForeverData[currentRealm] then
		BagnonForeverData[currentRealm] = {}
	end
	
	if not BagnonForeverData[currentRealm][currentPlayer] then
		BagnonForeverData[currentRealm][currentPlayer] = {}
	end
	
	if BagnonForeverData.version ~= current then
		UpdateVersion(current)
	end
end

BVent:AddAction('UNIT_INVENTORY_CHANGED', function()
	if arg1 == 'player' then
		SaveEquipmentData()
	end
end)

BVent:AddAction('BAG_UPDATE', function() SaveBagData(arg1) end)
BVent:AddAction('BANKFRAME_CLOSED', SaveBankData)
BVent:AddAction('BANKFRAME_OPENED', SaveBankData)
BVent:AddAction('PLAYER_MONEY', SavePlayerMoney)
BVent:AddAction('PLAYER_LOGIN', function()
	LoadVariables()
	SavePlayerMoney()
	SaveBagData(0)
	SaveEquipmentData() 
end)