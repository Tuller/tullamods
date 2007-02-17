--[[
	Database.lua
		BagnonForever's implementation of BagnonDB
--]]

--[[ 
	This check isn't absolutely necessary, but it'll warn users if they're using more than one database addon.
	Nothing under this block of code should be loaded if BagnonDB already exists.
--]]
if BagnonDB then
	error("Already using " .. (BagnonDB.addon or "another addon") .. " to view cached data.")
	return
else
	BagnonDB = {addon = 'vBagnon_Forever'}
end

--local globals
local currentPlayer = UnitName('player') --the name of the current player that's logged on
local currentRealm = GetRealmName() --what currentRealm we're on

--[[ 
	Access  Functions 
--]]


--[[ 
	BagnonDB.GetPlayers()	
		returns:
			iterator of all players on this realm with data
		usage:  
			for playerName, data in BagnonDB.GetPlayers()
--]]
function BagnonDB.GetPlayers()
	return pairs(BagnonForeverData[currentRealm])
end


--[[ 
	BagnonDB.GetBags(player)	
		returns:
			iterator of all bagsIDs for the given player
		usage:  
			for bagID, data in BagnonDB.GetBags("playerName")
--]]
function BagnonDB.GetBags(player)
	if player and BagnonForeverData[currentRealm][player] then
		return ipairs(BagnonForeverData[currentRealm][player])
	end
end


--[[ 
	BagnonDB.GetItems(player, bagID)	
		returns:
			iterator of all itemSlots with stuff in the given bag
		usage:  
			for bagID, data in BagnonDB.GetBags("playerName", bagID)
--]]
function BagnonDB.GetItems(player, bagID)
	if player and bagID and BagnonForeverData[currentRealm][player] and BagnonForeverData[currentRealm][player][bagID] then
		return ipairs(BagnonForeverData[currentRealm][player][bagID])
	end
end


--[[ 
	BagnonDB.GetMoney(player)
		args:
			player (string)
				the name of the player we're looking at.  This is specific to the current realm we're on
		
		returns:
			(number) How much money, in copper, the given player has
--]]
function BagnonDB.GetMoney(player)
	if BagnonForeverData[currentRealm][player] then
		return BagnonForeverData[currentRealm][player].g or 0
	end
	return 0
end


--[[ 
	BagnonDB.GetBagData(player, bagID)	
		args:
			player (string)
				the name of the player we're looking at.  This is specific to the current realm we're on
			bagID (number)
				the number of the bag we're looking at.
		
		returns:
			size (number)
				How many items the bag can hold (number)
			link (string)
				The itemlink of the bag, in the format item:w:x:y:z (string)
			count (number)
				How many items are in the bag.  This is used by ammo and soul shard bags
--]]
function BagnonDB.GetBagData(player, bagID)
	local playerData = BagnonForeverData[currentRealm][player]
	if playerData then
		local bagData = playerData[bagID]	
		if bagData then
			local bagDataStats = bagData.s
			local size, count, link = bagDataStats:match('(%d+),(%d+),([%w%-_:]*)')

			if size ~= '' then
				if link ~= '' then
					if tonumber(link) then
						link = format('%s:0:0:0:0:0:0:0', link)
					end
					link = format('item:%s', link)
				else
					link = nil
				end

				return size, link, tonumber(count)
			end
		end
	end
end

--[[ 
	BagnonDB.GetItemData(player, bagID, itemSlot)
		args:
			player (string)
				the name of the player we're looking at.  This is specific to the current realm we're on
			bagID (number)
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
function BagnonDB.GetItemData(player, bagID, itemSlot)
	local playerData = BagnonForeverData[currentRealm][player]
	if playerData then
		local bagData = playerData[bagID]

		if bagData then
			local itemData = bagData[itemSlot]
			
			if itemData then
				local itemLink, count = itemData:match('([%d%-:]+),*(%d*)')
				if tonumber(itemLink) then
					itemLink = format('%s:0:0:0:0:0:0:0', itemLink)
				end
				itemLink = format('item:%s', itemLink)
				
				local hyperLink, quality, _, _, _, _, _, _, texture = select(2, GetItemInfo(itemLink))
				return hyperLink, tonumber(count), texture, quality
			end
		end
	end
end

--[[
	Returns how many of the specific item id the given player has in the given bag
--]]
function BagnonDB.GetItemTotal(id, player, bagID)
	local count = 0
	local playerData = BagnonForeverData[currentRealm][player]

	if playerData then
		local bagData = playerData[bagID]
		if bagData then
			for itemSlot in pairs(bagData) do
				if tonumber(itemSlot) then
					local itemLink, itemCount = BagnonDB.GetItemData(player, bagID, itemSlot)

					if itemLink then
						local itemID = tonumber(itemLink)
						if not itemID then
							itemID = tonumber(itemLink:match('(%d+):'))
						end

						if tonumber(id) == itemID then
							count = count + (itemCount or 1)
						end
					end
				end
			end
		end
	end
	return tonumber(count)
end