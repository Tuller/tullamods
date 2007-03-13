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
		return tonumber(link) or tonumber(link:match("item:(%d+)") or tonumber(select(2, GetItemInfo(link)):match("item:(%d+)")))
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
    if id and count and Ludwig_SellValues and not MerchantFrame:IsVisible() then
		local price = Ludwig_SellValues[id]
		if price then
			frame:AddLine(SELLVALUE_COST, 1, 1,	0)
			SetTooltipMoney(frame, price * count)
			frame:Show()
		end
    end
end

--[[  Function Hooks ]]--

local function IsValidTooltip(frame)
	return (frame == GameTooltip) and frame:IsVisible()
end

GameTooltip.SetBagItem = pHook(GameTooltip.SetBagItem, function(self, bag, slot)
	if IsValidTooltip(self) then
		local id = LinkToID(GetContainerItemLink(bag, slot))
		local count = select(2, GetContainerItemInfo(bag, slot))

		AddMoneyToTooltip(GameTooltip, id, count)
	end
end)

GameTooltip.SetLootItem = pHook(GameTooltip.SetLootItem, function(self, slot)
	if IsValidTooltip(self) then
		local id = LinkToID(GetLootSlotLink(slot))
		local count = select(3, GetLootSlotInfo(slot))

		AddMoneyToTooltip(self, id, count)
	end
end)

GameTooltip.SetHyperlink = pHook(GameTooltip.SetHyperlink, function(self, link)
	if IsValidTooltip(self) then
		AddMoneyToTooltip(self, LinkToID(link))
	end
end)

GameTooltip.SetLootRollItem = pHook(GameTooltip.SetLootRollItem, function(self, id)
	if IsValidTooltip(self) then
		local id = LinkToID(GetLootRollItemLink(id))
		local count = select(3, GetLootRollItemInfo(id))

		AddMoneyToTooltip(self, id, count)
	end
end)

GameTooltip.SetAuctionItem = pHook(GameTooltip.SetAuctionItem , function(self, type, index)
	if IsValidTooltip(self) then
		local id = LinkToID(GetAuctionItemLink(type, index))
		local count = select(3, GetAuctionItemInfo(type, index))

		AddMoneyToTooltip(self, id, count)
	end
end)

GameTooltip.SetQuestItem = pHook(GameTooltip.SetQuestItem, function(self, type, id)
	if IsValidTooltip(self) then
		AddMoneyToTooltip(self, LinkToID(GetQuestItemLink(type, id)), 1)
	end
end)

GameTooltip.SetTradeSkillItem = pHook(GameTooltip.SetTradeSkillItem, function(self, type, id)
	if IsValidTooltip(self) then
		if not id then
			AddMoneyToTooltip(self, LinkToID(GetTradeSkillItemLink(type)), 1)
		end
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