--[[
	SellFish/tooltips.lua -
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

local GOLD_TEXT = format("|cffffd700%s|r", "g")
local SILVER_TEXT = format("|cffc7c7cf%s|r", "s")
local COPPER_TEXT = format("|cffeda55f%s|r", "c")

local function AddMoneyToTooltip(tip, id, count)
	local cost = (GetSellValue(id) or 0) * (count or 1)
	if cost > 0 then
		local style = SellFishDB.style
		--blizard style
		if(style == 1) then
			SetTooltipMoney(tip, cost)
		--cola light
		elseif(style == 2) then
			local costText
			--yes, this code is from abacus (ckknight)
			if cost >= 10000 then
				costText = format("|cffffffff%.2f|r%s", cost/10000, GOLD_TEXT);
			elseif cost >= 100 then
				costText = format("|cffffffff%.2f|r%s", cost/100, SILVER_TEXT);
			else
				costText = format("|cffffffff%d|r%s", cost, COPPER_TEXT);
			end
			if count and count > 1 then
				tip:AddDoubleLine(format(SELLFISH_LOCALS.SellsForMany, count), costText, 0, 1, 1, 1, 1, 1, 0)
			else
				tip:AddDoubleLine(SELLFISH_LOCALS.SellsFor, costText, 0, 1, 1, 1, 1, 1, 0)
			end
		--item price
		elseif(style == 3) then
			local gold = floor(cost / 10000)
			local silver = cost % 10000 / 100
			local copper = cost % 100
			local text

			if(gold > 0) then
				text = format("|cffffffff%d|r%s", gold, GOLD_TEXT)
			end
			if(silver > 0) then
				if(text) then
					text = text .. format(" |cffffffff%d|r%s", silver, SILVER_TEXT)
				else
					text = format("|cffffffff%d|r%s", silver, SILVER_TEXT)
				end
			end
			if(copper > 0) then
				if(text) then
					text = text .. format(" |cffffffff%d|r%s", copper, COPPER_TEXT)
				else
					text = format("|cffffffff%d|r%s", copper, COPPER_TEXT)
				end
			end

			if count and count > 1 then
				tip:AddDoubleLine(format(SELLFISH_LOCALS.SellsForMany, count), text, 0, 1, 1, 1, 1, 1, 0)
			else
				tip:AddDoubleLine(SELLFISH_LOCALS.SellsFor, text, 0, 1, 1, 1, 1, 1, 0)
			end
		--money tooltips
		else
			SetTooltipMoney(tip, cost)
		end
		tip:Show()
	end
end

local function hookTip(tooltip, method, action)
	hooksecurefunc(tooltip, method, function(tip, ...)
		local link, count = action(...)
		if link then
			AddMoneyToTooltip(tip, link, count)
		end
	end)
end

--tooltip hooking code, inherited from Valuation (Polarina)
local hooks = {
	SetHyperlink = function(link, count)
		return link, count
	end,

	SetBagItem = function(bag, slot)
		if not MerchantFrame:IsVisible() then
			return GetContainerItemLink(bag, slot), select(2, GetContainerItemInfo(bag, slot))
		end
	end,

	SetInventoryItem = function(unit, slot)
		return GetInventoryItemLink(unit, slot), GetInventoryItemCount(unit, slot)
	end,

	SetLootItem = function(slot)
		if LootSlotIsItem(slot) then
			return GetLootSlotLink(slot), select(3, GetLootSlotInfo(slot))
		end
	end,

	SetLootRollItem = function(slot)
		return GetLootRollItemLink(slot), select(3, GetLootRollItemInfo(slot))
	end,

	SetAuctionItem = function(type, index)
		return GetAuctionItemLink(type, index), select(3, GetAuctionItemInfo(type, index))
	end,

	SetAuctionSellItem = function()
		return select(2, GetItemInfo(GetAuctionSellItemInfo())), select(3, GetAuctionSellItemInfo())
	end,

	SetCraftItem = function(skill, id)
		if id then
			return GetCraftReagentItemLink(skill, id), select(3, GetCraftReagentInfo(skill, id))
		end
		return GetCraftItemLink(skill), GetCraftItemNumMade(skill)
	end,

	SetTradeSkillItem = function(skill, id)
		if id then
			return GetTradeSkillReagentItemLink(skill, id), select(3, GetTradeSkillReagentInfo(skill, id))
		end
		return GetTradeSkillItemLink(skill), GetTradeSkillNumMade(skill)
	end,

	SetQuestItem = function(type, index)
		return GetQuestItemLink(type, index), select(3, GetQuestItemInfo(type, index))
	end,

	SetQuestLogItem = function(type, index)
		local link = GetQuestLogItemLink(type, index)
		if type == 'choice' then
			return link, select(3, GetQuestLogChoiceInfo(index))
		end
		return link, select(3, GetQuestLogRewardInfo(index))
	end,

	SetTradePlayerItem = function(id)
		return GetTradePlayerItemLink(id), select(3, GetTradePlayerItemInfo(id))
	end,

	SetTradeTargetItem = function(id)
		return GetTradeTargetItemLink(id), select(3, GetTradeTargetItemInfo(id))
	end,

	SetInboxItem = function(id)
		return GetInboxItemLink(id), select(3, GetInboxItem(id))
	end,
}

hookTip(ItemRefTooltip, 'SetHyperlink', hooks.SetHyperlink)

for method,func in pairs(hooks) do
	hookTip(GameTooltip, method, func)
end