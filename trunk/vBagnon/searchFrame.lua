--[[
	vBagnon\searchFrame.lua
		An inventory frame that includes in its contents all items containing a specific name
		Multiple search frames can exist at once, and a search frame is destroyed by closing it

		Searches are performed by typing /find <item name>
--]]

local function ShowSearchFrame(title, ruleF)
	local frame = BagnonFrame.Create(title, {-2, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}, 
		{
			{name = BAGNON_RULE_INVENTORY, rule = Bagnon_And(ruleF, BagnonRule[BAGNON_RULE_INVENTORY])},
			{name = BAGNON_RULE_BANK, rule = Bagnon_And(ruleF, BagnonRule[BAGNON_RULE_BANK])},
		}
	)
	frame:SetPoint('CENTER', UIParent)
end

local function MatchNamed(names)
	return function(link)
		local n = select(2, Bagnon_GetData(link))
		if n then
			for _, name in pairs(names) do
				if name:sub(1, 1) == '!' then
					if n:find(name:sub(2)) then
						return false
					end
				elseif not n:find(name) then
					return false
				end
			end
			return true
		end
	end
end

--search for a name
SlashCmdList["BagnonSearchCOMMAND"] = function(text)
	if text and text ~= '' then
		local names = {strsplit(',', text:gsub(', ', ','):lower())}
		ShowSearchFrame(format(BAGNON_SEARCH_NAME, text), MatchNamed(names))
	end
end
SLASH_BagnonSearchCOMMAND1 = "/bgnfind"
SLASH_BagnonSearchCOMMAND2 = "/find"


--search for a rule
SlashCmdList["BagnonSearchCatCOMMAND"] = function(cat)
	if not cat or cat == '' then
		ShowSearchFrame(BAGNON_RULE_ITEMS, BagnonRule[BAGNON_RULE_ITEMS])
	else
		cat = cat:lower()
		for name, rule in pairs(BagnonRule) do
			if name:lower() == cat then
				ShowSearchFrame(name, rule)
			end
		end
	end
end
SLASH_BagnonSearchCatCOMMAND1 = "/bgnfindr"
SLASH_BagnonSearchCatCOMMAND2 = "/findr"


--[[
SlashCmdList["BagnonSearchTagCOMMAND"] = function(tag)
	if tag and tag ~= '' then
		ShowTempFrame(format(BAGNON_SEARCH_NAME, tag), function(itemLink)
			return BagnonTag_IsTagged(Bagnon_HyperLinkToLink(itemLink), tag)
		end)
	end
end
SLASH_BagnonSearchTagCOMMAND1 = "/bgnfindt"
SLASH_BagnonSearchTagCOMMAND2 = "/findt"
--]]