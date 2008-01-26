local f = CreateFrame("Frame")

f:SetScript("OnEvent", function(self, event)
	if event == "MERCHANT_SHOW" then
		if CanMerchantRepair() then
			local repairAllCost, canRepair = GetRepairAllCost()
			if canRepair then
				RepairAllItems()
			end
		end

		local bag, slot
		for bag = 0, 4 do
			for slot = 0, GetContainerNumSlots(bag) do
				local link = GetContainerItemLink(bag, slot)
				if link and select(3, GetItemInfo(link)) == 0 then
					ShowMerchantSellCursor(1)
					UseContainerItem(bag, slot)
				end
			end
		end
	end
end)
f:RegisterEvent("MERCHANT_SHOW")