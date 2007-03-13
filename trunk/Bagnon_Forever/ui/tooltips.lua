--[[
	Ludwig_SellValue -
		Originally based on SellValueLite, this addon allows viewing of sellvalues
--]]

local function AddOwners(frame, id)
	if not(frame and id and BagnonUtil:ShowingTooltips()) then return end

	for player in BagnonDB:GetPlayers() do
		local invCount = BagnonDB:GetItemCount(id, -2, player)
		for bag = 0, 4 do
			invCount = invCount + BagnonDB:GetItemCount(id, bag, player)
		end

		local bankCount = BagnonDB:GetItemCount(id, -1, player)
		for bag = 5, 11 do
			bankCount = bankCount + BagnonDB:GetItemCount(id, bag, player)
		end

		local equipCount = BagnonDB:GetItemCount(id, 'e', player)
		
		if (invCount + bankCount + equipCount) > 0 then
			local line = player .. ':'
			if invCount > 0 then
				line = line .. format(' %s Bags', invCount)
			end
			if bankCount > 0 then
				line = line .. format(' %s Bank', bankCount)
			end
			if equipCount > 0 then
				line = line .. format(' Equipped')
			end
			frame:AddLine(line, 0, 0.8, 1)
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