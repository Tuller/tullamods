--[[
	database.lua
		The database portion Of Ludwig

	Available Functions
		Ludwig_GetItems(name, quality, type, subType, equipLocation, minLevel, maxLevel)
			returns a list Of itemIDs with the given qualities

		Ludwig_GetItemsNamedExactly(searchString)
			returns either a list Of an itemID named exactly <searchString>, or returns a list Of ids Of the best matches

		Ludwig_GetItemName(itemID, inColor)
			returns the name Of a given itemID, optionally in color

		Ludwig_GetHyperLink(itemID)
			returns the hyperlink for a given itemID

	TODO:
		Any speed improvements
--]]


--[[ constants ]]--

local MAXID = 50000
local MAXIMUM_LEVEL = 70


--[[ globals ]]

local db --the database itself
local lw_s --this is a hack to allow for 3 variables when sorting.  Its used to give the name filter
local filterList = {}
local searchList = {}


--[[
	Sorting Functions
--]]

--returns the difference between two strings, where one is known to be within the other.
local function GetDist(str1, str2)
	--a few optimizations for when we already know distance
	if str1 == str2 then
		return 0
	end

	if not str1 and str2 then
		if str2 then
			return str2:len()
		end
		return 0
	end

	if not str2 then
		return str1:len()
	end

	return abs(str1:len() - str2:len())
end

--sorts a list by rarity, either closeness to the searchString if there's been a search, then level, then name
local function LudwigSort(id1, id2)
	local name1 = db[id1][1]
	local name2 = db[id2][1]
	local rarity1 = db[id1][2]
	local rarity2 = db[id2][2]
	local level1 = db[id1][3]
	local level2 = db[id2][3]

	if rarity1 ~= rarity2 then
		return rarity1 > rarity2
	end
	
	if lw_s then
		local dist1 = GetDist(lw_s, name1)
		local dist2 = GetDist(lw_s, name2)

		if dist1 ~= dist2 then
			return dist1 < dist2
		end
	end

	if level1 ~= level2 then
		return level1 > level2
	end

	return name1 < name2
end

local function isBetterMatch(id1, id2)
	return GetDist(lw_s, db[id1][1]) < GetDist(lw_s, db[id2][1])
end

--[[
	Access Functions
--]]

local function GetAllItems()
	if not db then db = {} end

	for i = 1, MAXID do
		if not db[i] then
			local itemName, _, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, _, itemEquipLoc, invTexture = GetItemInfo(i)
			if itemName and itemRarity >= (Ludwig_MinQuality or 0) then
				db[i] = {itemName, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemEquipLoc, invTexture}
			end
		end
	end
end

--returns a list Of item IDs matching the qualities given
function Ludwig_GetItems(name, quality, type, subType, equipLoc, minLevel, maxLevel)
	if not db then
		GetAllItems()
	end

	if name and name ~= '' then
		name = name:lower()
		--this is a hack to obtain better performance, we're not filtering searches by closeness for short strings
		if name:len() > 2 then
			lw_s = name
		else
			lw_s = nil
		end
	else
		lw_s = nil
		name = nil
	end
	
	for i in pairs(filterList) do
		filterList[i] = nil
	end

	for i, item in pairs(db) do
		local addItem = true
		if quality and item[2] ~= quality then
			addItem = nil
		elseif minLevel and item[4] < minLevel then
			addItem = nil
		elseif maxLevel and item[4] > maxLevel then
			addItem = nil
		elseif type and item[5] ~= type then
			addItem = nil
		elseif subType and item[6] ~= subType then
			addItem = nil
		elseif equipLoc and item[7] ~= equipLoc then
			addItem = nil
		elseif name then
			local itemName = item[1]:lower()
			if not(name == itemName or itemName:find(name)) then
				addItem = nil
			end
		end
		if addItem then
			table.insert(filterList, i)
		end
	end
	--this sorting function is the last real performance hit to ludwig
	table.sort(filterList, LudwigSort)

	return filterList
end

--Returns either a list containing an itemID for an item named exactly the searchTerm, or it returns a list Of best matches.  Used for linkerator
function Ludwig_GetItemsNamedLike(searchTerm)
	if searchTerm == '' then return end

	if not db then
		GetAllItems()
	end
	
	for i in pairs(searchList) do
		searchList[i] = nil
	end

	searchTerm = searchTerm:lower()

	for i, item in pairs(db) do
		local name = item[1]:lower()
		if name:find(searchTerm) then
			table.insert(searchList, i)
			if name == searchTerm then
				break
			end
		end
	end

	lw_s = searchTerm
	if next(searchList) then
		table.sort(searchList, isBetterMatch)
	end
	return searchList
end

--[[
	Per Item Access
		These functions all take an itemID (just a number), and return something about it
--]]

--returns the name of a given item
function Ludwig_GetName(id, inColor)
	if db[id] then
		if inColor then
			local hex = select(4, GetItemQualityColor(db[id][2]))
			return format('%s%s|r', hex, db[id][1])
		end
		return db[id][1]
	end
end

--returns a full hyperlink for the item
--format for a link is |cff<color>|Hitem:<id>:0:0:0|h[<name>]|h|r
function Ludwig_GetHyperLink(id)
	return (select(2, GetItemInfo(id)))
end

function Ludwig_GetTexture(id)
	if db[id] then
		return db[id][8]
	end
end

--[[
	Config Functions
--]]

--refresh the database
function Ludwig_Reload()
	GetAllItems()
end

--set the maximum amount Of ids to look through.  Yes, this sets a constant's value
function Ludwig_SetMaxID(maxID)
	MAXID = maxID
end

--set the minimum quality of items to look at
function Ludwig_SetMinQuality(quality)
	Ludwig_MinQuality = tonumber(quality)
end