--[[
	Tipachu
		Adds item icons to tooltips
--]]

--[[
	Item Hooking
--]]

local function hookItem(tip)
	local _G = _G
	local set = tip:GetScript('OnTooltipSetItem')

	tip:SetScript('OnTooltipSetItem', function(self, ...)
		local name, link = self:GetItem()
		local icon = link and GetItemIcon(link)
		if icon then
			local title = _G[self:GetName() .. 'TextLeft1']
			if title and not title:GetText():find('|T' .. icon) then --make sure the icon does not display twice on recipies, which fire OnTooltipSetItem twice
				title:SetFormattedText('|T%s:%d|t %s', icon, TipachuSize or 24, title:GetText())
			end
		end

		if set then
			return set(self, ...)
		end
	end)
end
hookItem(GameTooltip)
hookItem(ItemRefTooltip)


--[[
	Spell Hooking
--]]

local function hookSpell(tip)
	local _G = _G
	local set = tip:GetScript('OnTooltipSetSpell')

	tip:SetScript('OnTooltipSetSpell', function(self, ...)
		local name, rank, icon = GetSpellInfo(self:GetSpell())
		if icon then
			local title = _G[self:GetName() .. 'TextLeft1']
			if title and not title:GetText():find('|T' .. icon) then --make sure the icon does not display twice on recipies, which fire OnTooltipSetItem twice
				title:SetFormattedText('|T%s:%d|t %s', icon, TipachuSize or 24, title:GetText())
			end
		end

		if set then
			return set(self, ...)
		end
	end)
end
hookSpell(GameTooltip)
hookSpell(ItemRefTooltip)