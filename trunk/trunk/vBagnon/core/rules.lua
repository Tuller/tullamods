--[[
	vBagnon\rules.lua
		Helper functions for defining rule functions

		A rule function should take the form of
			function(itemLink)
				return < true | false | nil >
			end

		An itemLink looks like item:%d+:%d+:%d+:%d+, and is the second return of GetItemInfo
		
		vBagnon uses rule functions to define categories of items.
--]]

--[[ ItemLink Data Access ]]--

--returns an item's ID, lower case version of its name, its quality, level, type, subType, and equipLocation
local lastLink
local lastData = {}
function Bagnon_GetData(link)
	if link then
		if link ~= lastLink then
			local name, _, quality, iLevel, level, type, subType, _, loc = GetItemInfo(link)
			if name then
				lastLink = link
				lastData[1] = link
				lastData[2] = name:lower()
				lastData[3] = quality
				lastData[4] = iLevel
				lastData[5] = level
				lastData[6] = type
				lastData[7] = subType
				lastData[8] = loc
			else
				return
			end
		end
		return lastData[1], lastData[2], lastData[3], lastData[4], lastData[5], lastData[6], lastData[7], lastData[8]
	end
end

function Bagnon_HyperLinkToLink(hyperLink)
	return hyperLink:match("item:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+")
end

--[[ Logic ]]--

--returns a function that is equivalent to not f(x)
function Bagnon_Not(f)
	return function(...) return not f(...) end
end

--returns a function that is equivalent to f1(x) and f2(x) and f3(x) ...
function Bagnon_And(...)
	if select('#', ...) <= 0 then return nil end

	local args = {...}
	return function(...)
		for _, f in ipairs(args) do
			if not f(...) then
				return nil
			end
		end
		return true
	end
end

--returns a function g(x) that is equivalent to f1(x) or f2(x) or f3(x) ...
function Bagnon_Or(...)
	if select('#', ...) <= 0 then return nil end
	
	local args = {...}
	return function(...)
		for _, f in ipairs(args) do
			if f(...) then
				return true
			end
		end
		return nil
	end
end

function Bagnon_Nor(...)
	if select('#', ...) <= 0 then return nil end
	
	local args = {...}
	return function(...)
		for _, f in ipairs(args) do
			if f(...) then
				return nil
			end
		end
		return true
	end
end

--[[ Tag Logic ]]--

function Bagnon_Tagged(link, tag)
	return nil
end

--returns true if the given itemLink is tagged as tag1 and tag2 and tag3 ...
function Bagnon_TaggedAnd(...)
	if select('#', ...) <= 0 then return nil end
	
	local args = {...}
	return function(link)
		if link then
			for _, tag in ipairs(args) do
				if not Bagnon_Tagged(link, tag) then
					return nil
				end
			end
			return true
		end
	end
end

--returns true if the given itemLink is taged as either tag1 or tag2 or tag3 ...
function Bagnon_TaggedOr(...)
	if select('#', ...) <= 0 then return nil end

	local args = {...}
	return function(link)
		if link then
			for _, tag in ipairs(args) do
				if Bagnon_Tagged(Bagnon_HyperLinkToLink(link), tag) then
					return true
				end
			end
		end
	end
end

--[[ Rules ]]--

--takes a rule string, which can look like not(and(or(RuleName1, RuleName2), RuleName3))
--and converts it into a function
local createdRules = {}

local function ToRules(...)
	local rules = {}
	for i = 1, select('#', ...) do
		table.insert(rules, BagnonRule[select(i, ...)])
	end
	return Bagnon_Or(unpack(rules))
end

local function CreateRuleFromString(ruleString)
	local include, exclude, incTags, exTags = ruleString:match("(.*)%,(.*)%,(.*)%,(.*)")

	local includeRules
	if include and include ~= '' then
		includeRules = ToRules(strsplit(';', include))
	end

	local incTagsRule
	if incTags and incTags ~= '' then
		incTagsRule = Bagnon_TaggedOr(strsplit(';', incTags))
	end

	local excludeRules
	if exclude and exclude ~= '' then
		excludeRules = ToRules(strsplit(';', exclude))
	end

	local exTagsRule
	if exTags and exTags ~= '' then
		exTagsRule = Bagnon_TaggedOr(strsplit(';', exTags))
	end
	
	local f = Bagnon_And( Bagnon_Or(includeRules, incTagsRule), Bagnon_Nor(excludeRules, exTagsRule) )
	createdRules[ruleString] = f
	
	return f
end

function Bagnon_ToRuleString(include, exclude, includeTags, excludeTags)
	return format('%s,%s,%s,%s', include or '', exclude or '', includeTags or '', excludeTags or '')
end

function Bagnon_ToRule(rule)
	if type(rule) == 'function' then
		return rule
	end

	if rule and rule ~= '' then
		return createdRules[rule] or CreateRuleFromString(rule)
	end
end

BagnonRule = {}