--[[
	Database.lua
		BagnonForever's implementation of BagnonDB
--]]

if not BagnonDB then
	BagnonDB = Bagnon:NewModule("Bagnon-DB")
	BagnonDB.addon = "Bagnon_Forever"
else
	error(format('Already using %s to view cached data', BagnonDB.addon or '<Unknown>'))
	return
end

local util = BagnonUtil
local currentPlayer = UnitName("player") --the name of the current player that's logged on
local currentRealm = GetRealmName() --what currentRealm we're on

local function ToIndex(bag, slot)
	if not tonumber(bag) then
		return bag .. slot
	elseif bag < 0 then
		return bag * 100 - slot
	else
		return bag * 100 + slot
	end
end

--[[
	Startup Functions
--]]

function BagnonDB:Initialize()
	local cVersion = GetAddOnMetadata('Bagnon_Forever', 'Version')
	if not(BagnonForeverDB and BagnonForeverDB.version) then
		BagnonForeverDB = {version = cVersion}
	end
	self.db = BagnonForeverDB
	
	local realm = GetRealmName()
	if not self.db[realm] then
		self.db[realm] = {}
	end
	self.rdb = self.db[realm]

	local player = UnitName("player")
	if not self.rdb[player] then
		self.rdb[player] = {}
	end
	self.pdb = self.rdb[player]
	
	if self.db.version ~= cVersion then
		self:UpdateVersion(cVersion)
	end
end

function BagnonDB:UpdateVersion(cVersion)
	self.db.version = cVersion
	self:Print(format('Updated to v%s', self.db.version))
end

function BagnonDB:Enable()
	self:RegisterEvent('BANKFRAME_OPENED')
	self:RegisterEvent('PLAYER_MONEY')
	self:RegisterEvent('BAG_UPDATE')
	self:RegisterEvent('PLAYERBANKSLOTS_CHANGED')
	self:RegisterEvent('UNIT_INVENTORY_CHANGED')
	
	self:SaveMoney()
	self:SaveBagAll(0)
	self:SaveBagAll(-2)
	self:SaveEquipment()
end

--[[ 
	Access  Functions 
		Bagnon requires all of these functions to be present when attempting to view cached data
--]]

--[[ 
	BagnonDB:GetPlayers()	
		returns:
			iterator of all players on this realm with data
		usage:  
			for playerName, data in BagnonDB:GetPlayers()
--]]
function BagnonDB:GetPlayers()
	return pairs(self.rdb)
end


--[[ 
	BagnonDB:GetMoney(player)
		args:
			player (string)
				the name of the player we're looking at.  This is specific to the current realm we're on
		
		returns:
			(number) How much money, in copper, the given player has
--]]
function BagnonDB:GetMoney(player)
	local playerData = self.rdb[player]
	if playerData then
		return playerData.g or 0
	end
	return 0
end


--[[ 
	BagnonDB:GetBagData(bag, player)	
		args:
			player (string)
				the name of the player we're looking at.  This is specific to the current realm we're on
			bag (number)
				the number of the bag we're looking at.
		
		returns:
			size (number)
				How many items the bag can hold (number)
			link (string)
				The itemlink of the bag, in the format item:w:x:y:z (string)
			count (number)
				How many items are in the bag.  This is used by ammo and soul shard bags
--]]
function BagnonDB:GetBagData(bag, player)
	local playerDB = self.rdb[player]
	if playerDB then
		local bagInfo
		if tonumber(bag) then
			bagInfo = playerDB[bag * 100]
		else
			bagInfo = playerDB[bag]
		end

		if bagInfo then
			local size, count, link = bagInfo:match('(%d+),(%d+),([%w%-_:]*)')
			if size ~= '' then
				if link ~= '' then
					if tonumber(link) then
						link = format('item:%s:0:0:0:0:0:0:0', link)
					else
						link = format('item:%s', link)
					end
				else
					link = nil
				end
				return tonumber(size), link, tonumber(count)
			end
		end
	end
end

--[[ 
	BagnonDB:GetItemData(bag, slot, player)
		args:
			player (string)
				the name of the player we're looking at.  This is specific to the current realm we're on
			bag (number)
				the number of the bag we're looking at.
			itemSlot (number)
				the specific item slot we're looking at
				
		returns:
			itemLink (string)
				The itemlink of the item, in the format item:w:x:y:z
			count (number)
				How many of there are of the specific item
			texture (string)
				The filepath of the item's texture
--]]
function BagnonDB:GetItemData(bag, slot, player)
	local playerDB = self.rdb[player]
	if playerDB then
		local itemInfo = playerDB[ToIndex(bag, slot)]
		if itemInfo then
			local link, count = itemInfo:match('([%d%-:]+),*(%d*)')
			if tonumber(link) then
				link = format('item:%s:0:0:0:0:0:0:0', link)
			else
				link = format('item:%s', link)
			end
			
			local hyperLink, quality, _, _, _, _, _, _, texture = select(2, GetItemInfo(link))
			return hyperLink, tonumber(count), texture, tonumber(quality)
		end
	end
end

--[[
	Returns how many of the specific item id the given player has in the given bag
--]]
function BagnonDB:GetItemCount(itemLink, bag, player)
	local total = 0
	local id = tonumber(itemLink) or itemLink:match('item:(%d+)')

	local size = (self:GetBagData(bag, player)) or 0
	for slot = 1, size do
		local link, count = self:GetItemData(bag, slot, player)
		if link and link:match('item:(%d+)') == id then
			total = total + (count or 1)
		end
	end

	return total
end

--[[
	Storage Functions
		How we store the data (duh)
--]]

--takes a hyperlink (what you see in chat) and converts it to a shortened item link.
--a shortened item link is either the item:w:x:y:z form without the 'item:' part, or just the item's ID (the 'w' part)
local function ToShortLink(link)
	if link then
		local a,b,c,d,e,f,g,h = link:match("(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+)")
		if tonumber(b) == 0 and tonumber(c) == 0 and tonumber(d) == 0 and tonumber(e) == 0 and
			tonumber(f) == 0 and tonumber(g) == 0 and tonumber(h) == 0 then
			return a
		end
		return link:match("%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+")
	end
end

local function GetBagSize(bag)
	if bag == KEYRING_CONTAINER then
		return GetKeyRingSize() or 0
	end
	if bag == 'e' then
		return 19
	end
	return GetContainerNumSlots(bag) or 0
end


--[[  Storage Functions ]]--

function BagnonDB:SaveMoney()
	self.pdb.g = GetMoney()
end

--saves all the player's equipment data information
function BagnonDB:SaveEquipment()
	for slot = 0, 19 do
		local link = GetInventoryItemLink('player', slot)  
		local index = ToIndex('e', slot)

		if link then
			link = ToShortLink(link)
			local count = GetInventoryItemCount('player', slot)
			if count > 1 then
				self.pdb[index] = format('%s,%s', link, count)
			else
				self.pdb[index] = link
			end
		else
			self.pdb[index] = nil
		end
	end
end

--saves data about a specific item the current player has
function BagnonDB:SaveItem(bag, slot)
	local texture, count = GetContainerItemInfo(bag, slot)
	local index = ToIndex(bag, slot)

	if texture then
		local link = ToShortLink(GetContainerItemLink(bag, slot))
		if count > 1 then
			self.pdb[index] = format('%s,%s', link, count)
		else
			self.pdb[index] = link
		end
	else
		self.pdb[index] = nil
	end
end

--saves all information about the given bag, EXCEPT the bag's contents
function BagnonDB:SaveBag(bag)
	local size = GetBagSize(bag)
	local data = self.pdb

	if size > 0 then
		local link
		if bag > 0 then
			link = ToShortLink(GetInventoryItemLink('player', util:GetInvSlot(bag)))
		end	
		local count = GetInventoryItemCount('player', util:GetInvSlot(bag))
		
		self.pdb[bag*100] = format('%s,%s,%s', size, count, (link or ''))
	else
		self.pdb[bag*100] = nil
	end
end

--saves both relevant information about the given bag, and all information about items in the given bag
function BagnonDB:SaveBagAll(bag)
	self:SaveBag(bag)
	for slot = 1, GetBagSize(bag) do
		self:SaveItem(bag, slot)
	end
end

function BagnonDB:OnBagUpdate(bag)
	if util:AtBank() then
		for i = 1, 11 do
			self:SaveBag(i)
		end
	else
		for i = 1, 4 do
			self:SaveBag(i)
		end
	end

	for slot = 1, GetBagSize(bag) do
		self:SaveItem(bag, slot)
	end
end


--[[ Removal Functions ]]--

--removes all saved data about the given player
function BagnonDB:RemovePlayer(player, realm)
	if self.db[realm] then
		self.db[realm][player] = nil
	end
end


--[[  Events ]]--

function BagnonDB:PLAYER_MONEY()
	self:SaveMoney()
end

function BagnonDB:BAG_UPDATE(event, bag)
	if not(util:IsCachedBag(bag)) or util:AtBank() then
		self:OnBagUpdate(bag)
	end
end

function BagnonDB:PLAYERBANKSLOTS_CHANGED()
	self:OnBagUpdate(-1)
end

function BagnonDB:BANKFRAME_OPENED()
	self:SaveBagAll(-1)
	for bag = 5, 11 do
		self:SaveBagAll(bag)
	end
end

function BagnonDB:UNIT_INVENTORY_CHANGED(event, unit)
	if unit == 'player' then
		self:SaveEquipment()
	end
end