--[[
	Kost/tooltips.lua -
		Based on SellValueLite and ColaLight, allows viewing of sell values from anywhere
		This portion provides tooltip hooking functionality

	Copyright (C) 2007 Tuller
	ColaLight (C) 2006  Murazorz

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
	02110-1301, USA.
--]]

local function AddMoneyToTooltip(tip, id, count)
    if id then
		local cost = GetSellValue(id, count)
        if cost and cost > 0 then
			--short format: cola light style tooltips
			if LudwigSV_ShortFormat then
				local costText
				--yes, this code is from abacus (ckknight)
				if cost >= 10000 then
					costText = format("|cffffffff%.1f|r|cffffd700%s|r", cost / 10000, 'g');
				elseif cost >= 100 then
					costText = format("|cffffffff%.1f|r|cffc7c7cf%s|r", cost / 100, 's');
				else
					costText = format("|cffffffff%d|r|cffeda55f%s|r", cost, 'c');
				end
				if count and count > 1 then
					tip:AddDoubleLine(format("Sells for (%s):", count), costText, 0, 1, 1, 1, 1, 1, 0)
				else
					tip:AddDoubleLine("Sells for:", costText, 0, 1, 1, 1, 1, 1, 0)
				end
			--money tooltips
			else
				SetTooltipMoney(tip, cost)
			end
			tip:Show()
		end
	end
end

local function hookTip(action, method)
	return function(tip, ...)
		local arg = action(tip, ...)

		if (tip == GameTooltip or tip == ItemRefTooltip) then
			local link, count = method(...)
			AddMoneyToTooltip(tip, link, count)
		end
		return arg;
	end
end

GameTooltip.SetBagItem = hookTip(GameTooltip.SetBagItem, function(bag, slot)
	if not(MerchantFrame:IsVisible()) then 
		return GetContainerItemLink(bag, slot), select(2, GetContainerItemInfo(bag, slot))
	end
end)

GameTooltip.SetLootItem = hookTip(GameTooltip.SetLootItem, function(slot)
	return GetLootSlotLink(slot), select(3, GetLootSlotInfo(slot))
end)

GameTooltip.SetLootRollItem = hookTip(GameTooltip.SetLootRollItem, function(slot)
	return GetLootRollItemLink(slot), select(3, GetLootRollItemInfo(slot))
end)

GameTooltip.SetHyperlink = hookTip(GameTooltip.SetHyperlink, function(link, count)
	return link, count
end)

ItemRefTooltip.SetHyperlink = hookTip(ItemRefTooltip.SetHyperlink, function(link, count)
	return link, count
end)

GameTooltip.SetAuctionItem = hookTip(GameTooltip.SetAuctionItem , function(type, index)
	return GetAuctionItemLink(type, index), select(3, GetAuctionItemInfo(type, index))
end)

GameTooltip.SetQuestItem = hookTip(GameTooltip.SetQuestItem, function(type, index)
	return GetQuestItemLink(type, index), select(2, GetQuestItemInfo(type, index))
end)

GameTooltip.SetCraftItem = hookTip(GameTooltip.SetCraftItem, function(skill, id)
	if id then
		return GetCraftReagentItemLink(skill, id), select(2, GetCraftReagentInfo(skill, id))
	end
	return GetCraftItemLink(skill)
end)

GameTooltip.SetInventoryItem = hookTip(GameTooltip.SetInventoryItem , function(unit, slot)
	return GetInventoryItemLink(unit, slot), GetInventoryItemCount(unit, slot)
end)

GameTooltip.SetTradeSkillItem = hookTip(GameTooltip.SetTradeSkillItem, function(skill, id)
	if id then
		return GetTradeSkillReagentItemLink(skill, id), select(3, GetTradeSkillReagentInfo(skill, id))
	end
	return GetTradeSkillItemLink(skill)
end)

GameTooltip.SetQuestLogItem = hookTip(GameTooltip.SetQuestLogItem, function(index, slot)
	return GetQuestLogItemLink(index, slot), select(3, GetQuestLogRewardInfo(slot))
end)

GameTooltip.SetTradePlayerItem = hookTip(GameTooltip.SetTradePlayerItem, function(id)
	return GetTradePlayerItemLink(id), select(3, GetTradeTargetItemInfo(id))
end)

GameTooltip.SetTradeTargetItem = hookTip(GameTooltip.SetTradeTargetItem, function(id)
	return GetTradeTargetItemLink(id), select(3, GetTradeTargetItemInfo(id))
end)

GameTooltip.SetInboxItem = hookTip(GameTooltip.SetInboxItem, function(id)
	return GetInboxItemLink(id), select(3, GetInboxItem(id))
end)