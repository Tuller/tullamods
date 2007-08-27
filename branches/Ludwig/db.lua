--[[
	database.lua
		The database portion Of Ludwig
--]]

local MAXID = 40000
local MAXIMUM_LEVEL = 70

local lastSearch --this is a hack to allow for 3 variables when sorting.  Its used to give the name filter
local filteredList = {}
local searchList = {}
local db, itemInfo


--[[ Sorting Functions ]]--

local GetItemInfo = GetItemInfo

--returns the difference between two strings, where one is known to be within the other.
local function GetDist(str1, str2)
	--a few optimizations for when we already know distance
	if str1 == str2 then
		return 0
	end

	if not str1 then
		return #str2
	end

	if not str2 then
		return #str1
	end

	return abs(#str1 - #str2)
end

--sorts a list by rarity, either closeness to the searchString if there's been a search, then level, then name
local function SortByEverything(id1, id2)
	local name1 = db[id1]
	local name2 = db[id2]
	local rarity1 = itemInfo[3][id1]
	local rarity2 = itemInfo[3][id2]
	local level1 = itemInfo[4][id1]
	local level2 = itemInfo[4][id2]

	if rarity1 ~= rarity2 then
		return rarity1 > rarity2
	end

	if lastSearch then
		local dist1 = GetDist(lastSearch, name1)
		local dist2 = GetDist(lastSearch, name2)
		if dist1 ~= dist2 then
			return dist1 < dist2
		end
	end

	if level1 ~= level2 then
		return level1 > level2
	end

	return name1 < name2
end

--sort by distance to the searchTerm
local function SortByDistance(id1, id2)
	return GetDist(lastSearch, db[id1]) < GetDist(lastSearch, db[id2])
end

local function CreateItemCacheTable()
	local info = {}
	for i = 1, 10 do
		info[i] = setmetatable({}, {
			__index = function(t, k)
				local stats = (select(i, GetItemInfo(k)))
				if stats then
					t[k] = stats
				end
				return stats
			end
		})
	end
	return info
end


--[[ Usable Functions ]]--

Ludwig = {}

function Ludwig:GetAllItems(refresh)
	if not itemInfo then
		itemInfo = CreateItemCacheTable()
	end

	if not db or refresh then
		db = db or {}
		for i = 1, MAXID do
			local name = itemInfo[1][i]
			if not db[i] and name then
				db[i] = name:lower()
			end
		end
	end
	return db
end

function Ludwig:GetItems(name, quality, type, subType, equipLoc, minLevel, maxLevel)
	local db = self:GetAllItems()
	local stats = itemInfo

	if name and name ~= '' then
		name = name:lower()
		--this is a hack to obtain better performance, we're not filtering searches by closeness for short strings
		if #name > 2 then
			lastSearch = name
		else
			lastSearch = nil
		end
	else
		lastSearch = nil
		name = nil
	end

	for i in pairs(filteredList) do
		filteredList[i] = nil
	end

	local count = 0

	for id, itemName in pairs(db) do
		local addItem = true
		if quality and stats[3][id] ~= quality then
			addItem = nil
		elseif minLevel and stats[5][id] < minLevel then
			addItem = nil
		elseif maxLevel and stats[5][id] > maxLevel then
			addItem = nil
		elseif type and stats[6][id] ~= type then
			addItem = nil
		elseif subType and stats[7][id] ~= subType then
			addItem = nil
		elseif equipLoc and stats[9][id] ~= equipLoc then
			addItem = nil
		elseif name then
			if not(name == itemName or itemName:find(name)) then
				addItem = nil
			end
		end

		if addItem then
			count = count + 1
			filteredList[count] = id
		end
	end

	table.sort(filteredList, SortByEverything)

	return filteredList
end

function Ludwig:GetItemsNamedLike(search)
	if search == '' then return end
	for i in pairs(searchList) do
		searchList[i] = nil
	end
	search = search:lower()

	local db = self:GetAllItems()
	for id, itemName in pairs(db) do
		if itemName == search or itemName:find("^".. search) then
			table.insert(searchList, id)
			if itemName == search then break end
		end
	end

	lastSearch = search
	if next(searchList) then
		table.sort(searchList, SortByDistance)
	end
	return searchList
end

function Ludwig:GetItemName(id, inColor)
	local stats = itemInfo
	local name = stats[1][id]
	if name and inColor then
		local rarity = stats[3][id]
		local hex = (select(4, GetItemQualityColor(rarity)))
		return format('%s%s|r', hex, name)
	end
	return name
end

function Ludwig:GetItemLink(id)
	return (select(2, GetItemInfo(id)))
end

function Ludwig:GetItemTexture(id)
	return itemInfo[10][id]
end

function Ludwig:ReloadDB()
	self:GetAllItems(true)
end