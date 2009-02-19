--[[
	database.lua
		The database portion Of Ludwig
--]]

Ludwig = {}

local MAXID = 60000 --probably need to increase this to 40k by Wrath
local lastSearch --this is a hack to allow for 3 variables when sorting.  Its used to give the name filter


--[[ Sorting Functions ]]--

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
	local item1 = Ludwig:GetItemInfo(id1)
	local item2 = Ludwig:GetItemInfo(id2)
	local name1 = item1.search
	local name2 = item2.search
	local rarity1 = item1[3]
	local rarity2 = item2[3]
	local level1 = item1[4]
	local level2 = item2[4]

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
	local item1, item2 = Ludwig:GetItemInfo(id1), Ludwig:GetItemInfo(id2)
	return GetDist(lastSearch, item1.search) < GetDist(lastSearch, item2.search)
end

local function ToSearch(name)
	return name:gsub('%p', '%%%1')
end


--[[ Usable Functions ]]--

do
	--a cache of GetItemInfo
	local GetItemInfo = _G['GetItemInfo']
	local itemInfo = setmetatable({}, {__index = function(t, id)
		local name, link, rarity, iLevel, reqLevel, type, subType, stackCount, equipLoc, texture = GetItemInfo(id)
		if name then
			t[id] = {
				name, 
				link, 
				rarity, 
				iLevel, 
				reqLevel, 
				type, 
				subType, 
				stackCount, 
				equipLoc, 
				texture, 
				['search'] = name:lower()
			}
			return t[id]
		end
	end})
	
	function Ludwig:RefreshDB()
		for id = 1, MAXID do
			local k = itemInfo[id]
		end
	end
	
	function Ludwig:GetAllItems()
		return pairs(itemInfo)
	end
	
	function Ludwig:GetItemInfo(id)
		return itemInfo[id]
	end
end


--[[ Search Methods ]]--

do
	local results = {}
	function Ludwig:GetItems(name, quality, type, subType, equipLoc, minLevel, maxLevel)
		local search
		if name and #name > 2 then
			name = name:lower()
			search = ToSearch(name)
		else
			search = nil
		end
		lastSearch = name

		for k, v in pairs(results) do results[k] = nil end
		for id, info in self:GetAllItems() do
			local inSet = true

			if quality and info[3] ~= quality then
				inSet = nil
			elseif minLevel and info[5] < minLevel then
				inSet = nil
			elseif maxLevel and info[5] > maxLevel then
				inSet = nil
			elseif type and info[6] ~= type then
				inSet = nil
			elseif subType and info[7] ~= subType then
				inSet = nil
			elseif equipLoc and info[9] ~= equipLoc then
				inSet = nil
			elseif search and not(info.search == name or info.search:match(search))then
				inSet = nil
			end

			if inSet then
				table.insert(results, id)
			end
		end

		table.sort(results, SortByEverything)
		return results
	end
end

do
	local results = {}
	function Ludwig:GetItemsNamedLike(name)
		if (not name) or name == '' then return end
		
		local name = name:lower()
		local search = '^' .. ToSearch(name)
		lastSearch = name

		for k, v in pairs(results) do results[k] = nil end
		for id, info in self:GetAllItems() do
			if info.search == name or info.search:find(search) then
				table.insert(results, id)
				if info.search == name then
					break
				end
			end
		end

		table.sort(results, SortByDistance)
		return results
	end
end


--[[ Item Info Utility Methods ]]--

function Ludwig:GetItemName(id, inColor)
	local info = self:GetItemInfo(id)
	local name = info and info[1]

	if name and inColor then
		local rarity = info[3]
		local hex = (select(4, GetItemQualityColor(rarity)))
		return format('%s%s|r', hex, name)
	end
	return name
end

function Ludwig:GetItemLink(id)
	local info = self:GetItemInfo(id)
	return info and info[2]
end

function Ludwig:GetItemTexture(id)
	local info = self:GetItemInfo(id)
	return info and info[10]
end

--queries the server for items from startID to endID.  don't run too many of these at once, or you WILL be disconnected
function Ludwig:Scan(startID, endID)
	local tip = self.spider or CreateFrame('GameTooltip', 'LudwigSpiderTooltip', UIParent, 'GameTooltipTemplate')
	self.spider = tip

	local nextUpdate = 0
	local id = startID or 1
	local endID = endID or MAXID

	CreateFrame('Frame'):SetScript('OnUpdate', function(self, elapsed)
		if nextUpdate < 0 then
			nextUpdate = 1

			--skip over any items we've seen already
			while Ludwig:GetItemInfo(id) do id = id + 1 end

			--we've reached an id that's not been 'seen', query the server for item info
			tip:SetHyperlink(format('item:%d', id))

			id = id + 1
			if id > endID then
				self:Hide()
			end
		else
			nextUpdate = nextUpdate - elapsed
		end
	end)
end