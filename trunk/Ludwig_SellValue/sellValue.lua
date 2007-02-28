--[[
	Ludwig_SellValue -
		Originally based on SellValueLite, this addon allows viewing of sellvalues
--]]

local lastMoney = 0


--[[ Local Functions ]]--

local function pHook(action, method)
	return function(...)
		action(...)
		method(...)
	end
end

local function LinkToID(link)
	if link then
		return tonumber(link) or tonumber(link:match("(%d+):"))
	end
end

local function SaveCost(id, totalCost, count)
	if count and count > 0 and totalCost and totalCost > 0 then
		if not Ludwig_SellValues then
			Ludwig_SellValues = {}
		end
		Ludwig_SellValues[id] = totalCost / count
	end
end

local function AddMoneyToTooltip(frame, id, count)
    if frame and id and count and Ludwig_SellValues and not MerchantFrame:IsVisible() then
		local price = Ludwig_SellValues[id]
		if price then
			frame:AddLine(SELLVALUE_COST, 1, 1,	0)
			SetTooltipMoney(frame, price * count)
			frame:Show()
		end
    end
end


--[[  Function Hooks ]]--

GameTooltip.SetBagItem = pHook(GameTooltip.SetBagItem, function(self, bag, slot)
	local id = LinkToID(GetContainerItemLink(bag, slot))
	local count = select(2, GetContainerItemInfo(bag, slot))

	AddMoneyToTooltip(GameTooltip, id, count)
end)

GameTooltip.SetLootItem = pHook(GameTooltip.SetLootItem, function(self, slot)
	local id = LinkToID(GetLootSlotLink(slot))
	local count = select(3, GetLootSlotInfo(slot))

	AddMoneyToTooltip(self, id, count)
end)

GameTooltip.SetHyperlink = pHook(GameTooltip.SetHyperlink, function(self, link)
	AddMoneyToTooltip(self, LinkToID(link))
end)

GameTooltip.SetLootRollItem = pHook(GameTooltip.SetLootRollItem, function(self, id)
	local id = LinkToID(GetLootRollItemLink(id))
	local count = select(3, GetLootRollItemInfo(id))

	AddMoneyToTooltip(self, id, count)
end)

GameTooltip.SetAuctionItem = pHook(GameTooltip.SetAuctionItem , function(self, type, index)
	local id = LinkToID(GetAuctionItemLink(type, index))
	local count = select(3, GetAuctionItemInfo(type, index))

	AddMoneyToTooltip(self, id, count)
end)

GameTooltip.SetQuestItem = pHook(GameTooltip.SetQuestItem, function(self, type, id)
	AddMoneyToTooltip(self, LinkToID(GetQuestItemLink(type, id)), 1)
end)

GameTooltip.SetTradeSkillItem = pHook(GameTooltip.SetTradeSkillItem, function(self, type, id)
	if not id then
		AddMoneyToTooltip(self, LinkToID(GetTradeSkillItemLink(type)), 1)
	end
end)


--[[ Tooltip Scanner ]]--

local sellValue = CreateFrame("GameTooltip", "LudwigSVTooltip", nil, "GameTooltipTemplate")
sellValue:SetScript("OnEvent", function()
	for bag = 0, NUM_BAG_FRAMES do
		for slot = 1, GetContainerNumSlots(bag) do
			local id = LinkToID(GetContainerItemLink(bag, slot))
			if id then
				local count = select(2, GetContainerItemInfo(bag, slot))
				lastMoney = 0
				this:SetBagItem(bag, slot)
				SaveCost(id, lastMoney, count)
			end
		end
	end
end)
sellValue:RegisterEvent("MERCHANT_SHOW")

sellValue:SetScript("OnTooltipAddMoney", function()
	if not InRepairMode() then
		lastMoney = arg1
	end
end)