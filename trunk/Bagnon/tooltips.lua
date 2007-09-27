--[[
	Bagnon Forever Localization file
		This provides a way to translate Bagnon_Forever into different languages.
--]]

--[[
	English
		Any gaps in the translations are filled by English words.
--]]

local L = BAGNON_LOCALS

local function AddOwners(frame, link)
	for player in BagnonDB:GetPlayers() do
		local invCount = BagnonDB:GetItemCount(link, -2, player)
		for bag = 0, 4 do
			invCount = invCount + BagnonDB:GetItemCount(link, bag, player)
		end

		local bankCount = BagnonDB:GetItemCount(link, -1, player)
		for bag = 5, 11 do
			bankCount = bankCount + BagnonDB:GetItemCount(link, bag, player)
		end

		local equipCount = BagnonDB:GetItemCount(link, "e", player)
		
		if (invCount + bankCount + equipCount) > 0 then
			local line = player .. ":"
			if invCount > 0 then
				line = line .. format(L.NumInBags, invCount)
			end
			if bankCount > 0 then
				line = line .. format(L.NumInBank, bankCount)
			end
			if equipCount > 0 then
				line = line .. L.NumEquipped
			end
			frame:AddLine(line, 0, 0.8, 1)
		end
	end
	frame:Show()
end

local SetItem = GameTooltip:GetScript("OnTooltipSetItem")
GameTooltip:SetScript("OnTooltipSetItem", function(self, ...)
	if SetItem then 
		SetItem(self, ...) 
	end

	if BagnonDB and Bagnon:ShowingOwners() then
		local itemLink = select(2, self:GetItem())
		if itemLink then
			AddOwners(self, itemLink)
		end
	end
end)

local SetItem = ItemRefTooltip:GetScript("OnTooltipSetItem")
ItemRefTooltip:SetScript("OnTooltipSetItem", function(self, ...)
	if SetItem then 
		SetItem(self, ...) 
	end

	if BagnonDB and Bagnon:ShowingOwners() then
		local itemLink = select(2, self:GetItem())
		if itemLink then
			AddOwners(self, itemLink)
		end
	end
end)