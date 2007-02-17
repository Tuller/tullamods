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
local function SaveItemData(bagID, itemSlot)
	local texture, count = GetContainerItemInfo(bagID, itemSlot)
	local data
	
	if texture then
		data = BagnonForever_HyperlinkToShortLink(GetContainerItemLink(bagID, itemSlot))
		if count > 1 then
			data = data .. "," .. count
		end
	end

	BagnonForeverData[currentRealm][currentPlayer][bagID][itemSlot] = data
end

--saves all the data about the current player's bag
local function SaveBagData(bagID)
	--don't save bank data unless you're at the bank
	if BagnonLib.IsBankBag(bagID) and not BagnonLib.AtBank() then return end
	
	local size
	if bagID == KEYRING_CONTAINER then
		size = GetKeyRingSize()
	else
		size = GetContainerNumSlots(bagID)
	end
	
	if size > 0 then
		local link, count
		
		if bagID > 0 then
			link = BagnonForever_HyperlinkToShortLink(GetInventoryItemLink('player', BagnonLib.GetInvSlot(bagID)))
		end
		
		count = GetInventoryItemCount('player', BagnonLib.GetInvSlot(bagID))
		
		--save bag size
		BagnonForeverData[currentRealm][currentPlayer][bagID] = {}
		BagnonForeverData[currentRealm][currentPlayer][bagID].s = size .. "," .. count .. ","
		
		if link then
			BagnonForeverData[currentRealm][currentPlayer][bagID].s = BagnonForeverData[currentRealm][currentPlayer][bagID].s .. link
		end

		--save all item info
		for index = 1, size, 1 do
			SaveItemData(bagID, index)
		end
	else
		BagnonForeverData[currentRealm][currentPlayer][bagID] = nil
	end
end

local function SavePlayerMoney()
	BagnonForeverData[currentRealm][currentPlayer].g = GetMoney()
end

--save all bank data about the current player
local function SaveBankData()
	SaveBagData(-1)
	for bagID = 5, 11, 1 do
		SaveBagData(bagID)
	end
end

--save all inventory data about the current player
local function SaveAllData()
	--you know, this should probably be a constant
	for i = -2, 11, 1 do
		SaveBagData(i)
	end
	SavePlayerMoney()
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
	BagnonMsg(format(BAGNON_FOREVER_UPDATED, version))
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
		SaveAllData()
	end
	
	if BagnonForeverData.version ~= current then
		UpdateVersion(current)
	end
end

BVent:AddAction('BAG_UPDATE', function() SaveBagData(arg1) end)
BVent:AddAction('BANKFRAME_CLOSED', SaveBankData)
BVent:AddAction('BANKFRAME_OPENED', SaveBankData)
BVent:AddAction('PLAYER_MONEY', SavePlayerMoney)
BVent:AddAction('PLAYER_LOGIN', function() LoadVariables(); SavePlayerMoney(); SaveBagData(0) end)