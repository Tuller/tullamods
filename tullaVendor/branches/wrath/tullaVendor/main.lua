local f = CreateFrame('Frame')
f:SetScript('OnEvent', function(self, event)
	if event == 'MERCHANT_SHOW' then
		if CanMerchantRepair() then
			local repairAllCost, canRepair = GetRepairAllCost()
			if canRepair then
				RepairAllItems()
			end
		end

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
f:RegisterEvent('MERCHANT_SHOW')

do
	--make the minimap scrollable via the mousewheel
	local scroll = CreateFrame('Frame', nil, Minimap)
	scroll:SetAllPoints(Minimap)
	scroll:EnableMouse(false)
	scroll:EnableMouseWheel(true)
	scroll:SetScript('OnMouseWheel', function(self, arg1)
		if (Minimap:GetZoom() + arg1 <= Minimap:GetZoomLevels()) and (Minimap:GetZoom() + arg1 >= 0) then
			Minimap:SetZoom(Minimap:GetZoom() + arg1)
		end
	end)
	
	MiniMapWorldMapButton:Hide()
--	GameTimeFrame:Hide()
	MinimapZoomIn:Hide()
	MinimapZoomOut:Hide()
	
	MinimapZoneTextButton:Hide()
	MinimapToggleButton:Hide()
	MinimapBorderTop:Hide()
	
	MinimapCluster:ClearAllPoints()
	MinimapCluster:SetPoint('TOPRIGHT', 0, 12)
end