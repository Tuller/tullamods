--[[
	ItemSearch
		An item text search engine of some sort

	Grammar:
		<search> 			:=	<intersect search>
		<intersect search> 	:=	<union search> & <union search> ; <union search>
		<union search>		:=	<negatable search>  | <negatable search> ; <negatable search>
		<negatable search> 	:=	!<primitive search> ; <primitive search>
		<primitive search>	:=	<tooltip search> ; <quality search> ; <type search> ; <text search>
		<tooltip search>	:=  bop ; boa ; bou ; boe ; quest
		<quality search>	:=	q:<text> ; q:<digit>
		<type search>		:=	t:<text>
		<text search>		:=	<text>

	I kindof half want to make a full parser for this
--]]


local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local ItemSearch = {}
Bagnon.ItemSearch = ItemSearch


--[[ general search ]]--

function ItemSearch:Find(itemLink, search)
	if not search then
		return true
	end

	if not itemLink then
		return false
	end

	local search = search:lower()
	if search:match('\124') then
		return self:FindUnionSearch(itemLink, strsplit('\124', search))
	end
	return self:FindUnionSearch(itemLink, search)
end


--[[ union search: <search>&<search> ]]--

function ItemSearch:FindUnionSearch(itemLink, ...)
	for i = 1, select('#', ...) do
		local search = select(i, ...)
		if search and search ~= '' then
			if search:match('\038') then
				if self:FindIntersectSearch(itemLink, strsplit('\038', search)) then
					return true
				end
			else
				if self:FindIntersectSearch(itemLink, search) then
					return true
				end
			end
		end
	end
	return false
end


--[[ intersect search: <search>|<search> ]]--

function ItemSearch:FindIntersectSearch(itemLink, ...)
	for i = 1, select('#', ...) do
		local search = select(i, ...)
		if search and search ~= '' then
			if not self:FindNegatableSearch(itemLink, search) then
				return false
			end
		end
	end
	return true
end


--[[ negated search: !<search> ]]--

function ItemSearch:FindNegatableSearch(itemLink, search)
	local negatedSearch = search:match('^\033(.+)$')
	if negatedSearch then
		return not self:FindTypedSearch(itemLink, negatedSearch)
	end
	return self:FindTypedSearch(itemLink, search)
end


--[[
	typed search:
		user defined search types

	A typed search object should look like the following:
		{
			string id
				unique identifier for the search type,

			string searchCapture = function isSearch(self, search)
				returns a capture if the given search matches this typed search
				returns nil if the search is not a match for this type

			bool isMatch = function findItem(self, itemLink, searchCapture)
				returns true if <itemLink> is in the search defined by <searchCapture>
		}
--]]

local typedSearches = {}
function ItemSearch:RegisterTypedSearch(typedSearchObj)
	typedSearches[typedSearchObj.id] = typedSearchObj
end

function ItemSearch:GetTypedSearches()
	return pairs(typedSearches)
end

function ItemSearch:GetTypedSearch(id)
	return typedSearches[id]
end

function ItemSearch:FindTypedSearch(itemLink, search)
	if not search then
		return false
	end

	for id, searchInfo in self:GetTypedSearches() do
		local capture = searchInfo:isSearch(search)
		if capture then
			return searchInfo:findItem(itemLink, capture)
		end
	end

	return self:GetTypedSearch('itemTypeGeneric'):findItem(itemLink, search) or self:GetTypedSearch('itemName'):findItem(itemLink, search)
end


--[[
	Basic typed searches
--]]


--[[ basic text search n:(.+) ]]--

local function search_IsInText(search, ...)
	for i = 1, select('#', ...) do
		local text = select(i, ...)
		text = text and tostring(text):lower()
		if text and (text == search or text:match(search)) then
			return true
		end
	end
	return false
end

ItemSearch:RegisterTypedSearch{
	id = 'itemName',

	isSearch = function(self, search)
		return search and search:match('^n:(.+)$')
	end,

	findItem = function(self, itemLink, search)
		local itemName = (GetItemInfo(itemLink))
		return search_IsInText(search, itemName)
	end
}


--[[ item type,subtype,equip loc search t:(.+) ]]--

ItemSearch:RegisterTypedSearch{
	id = 'itemTypeGeneric',

	isSearch = function(self, search)
		return search and search:match('^t:(.+)$')
	end,

	findItem = function(self, itemLink, search)
		local name, link, quality, iLevel, reqLevel, type, subType, maxStack, equipSlot = GetItemInfo(itemLink)
		if not name then
			return false
		end
		return search_IsInText(search, type, subType, _G[equipSlot])
	end
}


--[[ item quality search: q:(.+) ]]--

ItemSearch:RegisterTypedSearch{
	id = 'itemQuality',

	isSearch = function(self, search)
		return search and search:match('^q:(.+)$')
	end,

	findItem = function(self, itemLink, search)
		local name, link, quality = GetItemInfo(itemLink)
		if not name then
			return false
		end

		local qSearchNum = tonumber(search)
		if qSearchNum then
			return qSearchNum == quality
		end

		local qualityDesc = _G['ITEM_QUALITY' .. quality .. '_DESC']
		if qualityDesc then
			return search == qualityDesc:lower()
		end

		return false
	end
}


--[[ tooltip keyword search ]]--

local tooltipCache = setmetatable({}, {__index = function(t, k) local v = {} t[k] = v return v end})
local tooltipScanner = _G['BagnonTooltipScanner'] or CreateFrame('GameTooltip', 'BagnonTooltipScanner', UIParent, 'GameTooltipTemplate')

local function link_FindSearchInTooltip(itemLink, search)
	--look in the cache for the result
	local itemID = itemLink:match('item:(%d+)')
	local cachedResult = tooltipCache[search][itemID]
	if cachedResult ~= nil then
		return cachedResult
	end

	--no match?, pull in the resut from tooltip parsing
	tooltipScanner:SetOwner(UIParent, 'ANCHOR_NONE')
	tooltipScanner:SetHyperlink(itemLink)

	local result = false
	if tooltipScanner:NumLines() > 1 and _G[tooltipScanner:GetName() .. 'TextLeft2']:GetText() == search then
		result = true
	elseif tooltipScanner:NumLines() > 2 and _G[tooltipScanner:GetName() .. 'TextLeft3']:GetText() == search then
		result = true
	end
	tooltipScanner:Hide()

	tooltipCache[search][itemID] = result
	return result
end

ItemSearch:RegisterTypedSearch{
	id = 'tooltip',

	isSearch = function(self, search)
		return self.keywords[search]
	end,

	findItem = function(self, itemLink, search)
		return search and link_FindSearchInTooltip(itemLink, search)
	end,

	keywords = {
		['boe'] = ITEM_BIND_ON_EQUIP,
		['bop'] = ITEM_BIND_ON_PICKUP,
		['bou'] = ITEM_BIND_ON_USE,
		['quest'] = ITEM_BIND_QUEST,
		['boa'] = ITEM_BIND_TO_ACCOUNT
	}
}