--[[
	Ludwig_SellValue -
		Originally based on SellValueLite, this addon allows viewing of sellvalues
--]]

local currentPlayer = UnitName('player')

--[[ Local Functions ]]--

local function LinkToID(link)
	if link then
		return tonumber(link:match('(%d+):'))
	end
end

local function AddOwners(frame, id)
	if not(frame and id and BagnonLib.GetPlayerSets().showTooltips) then return end
	
	for player in BagnonDB.GetPlayers() do
		if player ~= currentPlayer then
			local invCount = BagnonDB.GetItemTotal(id, player, -2)
			for bagID = 0, 4 do
				invCount = invCount + BagnonDB.GetItemTotal(id, player, bagID)
			end

			local bankCount = BagnonDB.GetItemTotal(id, player, -1)
			for bagID = 5, 11 do
				bankCount = bankCount + BagnonDB.GetItemTotal(id, player, bagID)
			end

			if (invCount + bankCount) > 0 then
				local tooltipString = player .. " has"
				if invCount > 0 then
					tooltipString = tooltipString .. " " .. invCount .. " (Bags)"
				end
				if bankCount > 0 then
					tooltipString = tooltipString .. " " .. bankCount .. " (Bank)"
				end
				frame:AddLine(tooltipString, 0, 0.8, 1)
			end
		end
	end
end

--[[  Function Hooks ]]--

--bag item
local Blizz_GameTooltip_SetBagItem = GameTooltip.SetBagItem;
GameTooltip.SetBagItem = function(self, bag, slot, ...)
	Blizz_GameTooltip_SetBagItem(self, bag, slot, ...)
	
	AddOwners(self, LinkToID(GetContainerItemLink(bag, slot, ...)))
	self:Show()
end

--loot item (items you see when looting a corpse)
local Bliz_GameTooltip_SetLootItem = GameTooltip.SetLootItem
GameTooltip.SetLootItem = function(self, slot)
	Bliz_GameTooltip_SetLootItem(self, slot)

	AddOwners(self, LinkToID(GetLootSlotLink(slot)))
	self:Show()
end

--hyperlink (bagnon, ludwig, and lootlink data)
local Bliz_SetHyperlink = GameTooltip.SetHyperlink
GameTooltip.SetHyperlink = function(self, link, count)
	if link then
		Bliz_SetHyperlink(self, link, count)

		local id = LinkToID(link)
		if id then
			AddOwners(self, id)
		else
			AddOwners(self, link)
		end
		self:Show()
	end
end

--items you see when the roll dialog pops up
local Bliz_GameTooltip_SetLootRollItem = GameTooltip.SetLootRollItem
GameTooltip.SetLootRollItem = function(self, rollID) 
	Bliz_GameTooltip_SetLootRollItem(self, rollID)

	AddOwners(self, LinkToID(GetLootRollItemLink(rollID)))
	self:Show()
end

--items you see when shift clicking, Do not think this works
local Bliz_SetItemRef = SetItemRef
SetItemRef = function(link, text, button)
	Bliz_SetItemRef(link, text, button)

	AddOwners(ItemRefTooltip, LinkToID(link))
	ItemRefTooltip:Show()
end

--items you see at the AH
local Bliz_GameTooltip_SetAuctionItem = GameTooltip.SetAuctionItem
GameTooltip.SetAuctionItem = function(self, type, index)
	Bliz_GameTooltip_SetAuctionItem(self, type, index)

	AddOwners(self, LinkToID(GetAuctionItemLink(type, index)))
	self:Show()
end