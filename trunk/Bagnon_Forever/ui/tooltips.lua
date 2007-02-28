--[[
	Ludwig_SellValue -
		Originally based on SellValueLite, this addon allows viewing of sellvalues
--]]

local currentPlayer = UnitName('player')

--[[ Local Functions ]]--

local function AddOwners(frame, id)
	if not(frame and id and BagnonLib.GetSets().showTooltips) then return end

	for player in BagnonDB.GetPlayers() do
		local invCount = BagnonDB.GetItemTotal(id, player, -2)
		for bagID = 0, 4 do
			invCount = invCount + BagnonDB.GetItemTotal(id, player, bagID)
		end

		local bankCount = BagnonDB.GetItemTotal(id, player, -1)
		for bagID = 5, 11 do
			bankCount = bankCount + BagnonDB.GetItemTotal(id, player, bagID)
		end

		local equipCount = BagnonDB.GetItemTotal(id, player, 'e')
		if (invCount + bankCount + equipCount) > 0 then
			local tooltipString = player .. ':'
			if invCount > 0 then
				tooltipString = tooltipString .. format(' (%s Bags)', invCount)
			end
			if bankCount > 0 then
				tooltipString = tooltipString .. format(' (%s Bank)', bankCount)
			end
			if equipCount > 0 then
				tooltipString = tooltipString .. format(' (Equipped)', bankCount)
			end
			frame:AddLine(tooltipString, 0, 0.8, 1)
		end
	end
	frame:Show()
end

local function pHook(action, method)
	return function(...)
		action(...)
		method(...)
	end
end


--[[  Function Hooks ]]--

GameTooltip.SetBagItem = pHook(GameTooltip.SetBagItem, function(self, bag, slot)
	AddOwners(self, GetContainerItemLink(bag, slot))
end)

GameTooltip.SetLootItem = pHook(GameTooltip.SetLootItem, function(self, slot)
	AddOwners(self, GetLootSlotLink(slot))
end)

GameTooltip.SetHyperlink = pHook(GameTooltip.SetHyperlink, function(self, link)
	AddOwners(self, link)
end)

GameTooltip.SetLootRollItem = pHook(GameTooltip.SetLootRollItem, function(self, rollID)
	AddOwners(self, GetLootRollItemLink(rollID))
end)

GameTooltip.SetAuctionItem = pHook(GameTooltip.SetAuctionItem, function(self, type, index)
	AddOwners(self, GetAuctionItemLink(type, index))
end)

GameTooltip.SetQuestItem = pHook(GameTooltip.SetQuestItem, function(self, type, id)
	AddOwners(self, GetQuestItemLink(type, id))
end)

GameTooltip.SetTradeSkillItem = pHook(GameTooltip.SetTradeSkillItem, function(self, type, id)
	if not id then
		AddOwners(self, GetTradeSkillItemLink(type))
	else
		AddOwners(self, GetTradeSkillReagentItemLink(type, id))
	end
end)