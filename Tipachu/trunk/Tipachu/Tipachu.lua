--[[
	Tuba
		Adds item icons to tooltips
--]]


local function hookItem(tip)
	local setItem = tip:GetScript('OnTooltipSetItem')
	local _G = getfenv(0)

	tip:SetScript('OnTooltipSetItem', function(self, ...)
		if set then
			set(self, ...)
		end

		local link = select(2, self:GetItem())
		if link and GetItemInfo(link) then
			local text = _G[self:GetName() .. 'TextLeft1']
			if text and text:GetText():sub(1, 2) ~= '|T' then
				text:SetFormattedText('|T%s:%d|t%s', GetItemIcon(link), TipachuSize or 24, text:GetText())
			end
		end
	end)
end

hookItem(GameTooltip)
hookItem(ItemRefTooltip)