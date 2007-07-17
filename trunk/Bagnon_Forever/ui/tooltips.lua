--[[
	tooltips.lua
		Adds ownership information to visible tooltips.
--]]

local L = BAGNON_FOREVER_LOCALS

local function AddOwners(frame, id)
	if not(id and BagnonUtil:ShowingOwners()) then return end

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
				line = line .. format(L.Bags, invCount)
			end
			if bankCount > 0 then
				line = line .. format(L.Bank, bankCount)
			end
			if equipCount > 0 then
				line = line .. L.Equipped
			end
			frame:AddLine(line, 0, 0.8, 1)
		end
	end
	frame:Show()
end

local function pHook(action, method)
	return function(...)
		local ret = action(...)
		method(...)
		return ret
	end
end


--[[ Hooks ]]--

local function IsValidTooltip(frame)
	return (frame == GameTooltip or frame == ItemRefTooltip) and frame:IsVisible()
end

GameTooltip.SetBagItem = pHook(GameTooltip.SetBagItem, function(self, bag, slot)
	if IsValidTooltip(self) then
		AddOwners(self, GetContainerItemLink(bag, slot))
	end
end)

GameTooltip.SetLootItem = pHook(GameTooltip.SetLootItem, function(self, slot)
	if IsValidTooltip(self) then
		AddOwners(self, GetLootSlotLink(slot))
	end
end)

GameTooltip.SetHyperlink = pHook(GameTooltip.SetHyperlink, function(self, link)
	if IsValidTooltip(self) then
		AddOwners(self, link)
	end
end)

GameTooltip.SetLootRollItem = pHook(GameTooltip.SetLootRollItem, function(self, rollID)
	if IsValidTooltip(self) then
		AddOwners(self, GetLootRollItemLink(rollID))
	end
end)

GameTooltip.SetAuctionItem = pHook(GameTooltip.SetAuctionItem, function(self, type, index)
	if IsValidTooltip(self) then
		AddOwners(self, GetAuctionItemLink(type, index))
	end
end)

GameTooltip.SetQuestItem = pHook(GameTooltip.SetQuestItem, function(self, type, id)
	if IsValidTooltip(self) then
		AddOwners(self, GetQuestItemLink(type, id))
	end
end)

GameTooltip.SetTradeSkillItem = pHook(GameTooltip.SetTradeSkillItem, function(self, type, id)
	if IsValidTooltip(self) then
		if not id then
			AddOwners(self, GetTradeSkillItemLink(type))
		else
			AddOwners(self, GetTradeSkillReagentItemLink(type, id))
		end
	end
end)