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
	GameTimeFrame:Hide()
	MinimapZoomIn:Hide()
	MinimapZoomOut:Hide()
	
	MinimapZoneTextButton:Hide()
	MinimapToggleButton:Hide()
	MinimapBorderTop:Hide()
	
	MinimapCluster:ClearAllPoints()
	MinimapCluster:SetPoint('TOPRIGHT', 0, 12)
end

do
	--[[ Clock Functions ]]--

	local UPDATE_DELAY = 30

	local function Clock_UpdateTime(text, hours, minutes)
		local pm = hours >= 12
		hours = mod(hours, 12)
		if(hours == 0) then hours = 12 end

		if pm then
			text:SetText(format(TEXT(TIME_TWELVEHOURPM), hours, minutes))
		else
			text:SetText(format(TEXT(TIME_TWELVEHOURAM), hours, minutes))
		end
	end

	local function Clock_OnUpdate(self, elapsed)
		if self.nextUpdate > 0 then
			self.nextUpdate = self.nextUpdate - elapsed
		else
			self.nextUpdate = UPDATE_DELAY

			local hours, minutes = GetGameTime()
			hours = hours + (self.offset or 0)
			Clock_UpdateTime(self.text, hours, minutes)
		end
	end

	local function Clock_Create(parent)
		local clock = CreateFrame('Frame', nil, parent)
		clock:SetWidth(70) clock:SetHeight(24)

		local text = clock:CreateFontString(nil, 'OVERLAY')
		text:SetFontObject('GameFontNormalSmall')
		text:SetAllPoints(clock)
		clock.text = text

		clock.nextUpdate = 0
		clock:SetScript('OnUpdate', Clock_OnUpdate)
		clock:SetPoint('BOTTOM', parent)

		return clock
	end

	local clock = Clock_Create(MinimapCluster)
	clock.offset = 0
end