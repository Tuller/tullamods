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
    if id then
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
				local silver = mod(cost, 10000)/100
				local copper = mod(cost, 100)
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
end

local function HookScript(frame, event, action)
	local script = frame:GetScript(event)
	frame:SetScript(event, function(...)
		if script then
			script(...)
		end
		action(...)
	end)
end

local function AddSellFishCost(self)
	if not MerchantFrame:IsVisible() then
		local owner = self:GetOwner()
		local count
		if owner then
			local countText = (owner:GetName() and getglobal(owner:GetName() .. "Count")) or owner.count
			if countText then
				count = tonumber(countText:GetText()) or 1
			end
		end
		AddMoneyToTooltip(self, select(2, self:GetItem()), count)
	end
end

HookScript(GameTooltip, "OnTooltipSetItem", AddSellFishCost)
HookScript(ItemRefTooltip, "OnTooltipSetItem", AddSellFishCost)