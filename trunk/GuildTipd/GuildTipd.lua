--[[
	GuildTipd, based on Priority Mail (tekkub) and Guildentipper (fizzwidget)
--]]

local OnSetUnit = GameTooltip:GetScript("OnTooltipSetUnit")
GameTooltip:SetScript("OnTooltipSetUnit", function(tooltip)
	if OnSetUnit then
		OnSetUnit(tooltip)
	end
	
	local unit = 'mouseover'
	if UnitExists(unit) and UnitPlayerControlled(unit) then
		--add the player's guildname
		local guildName = GetGuildInfo(unit)
		if guildName then
			tooltip:AddLine(guildName, 0, 1, 0)
		end
	
		--add the player's afk status, taken from GuildenTipper
		local nameField = getglobal(tooltip:GetName() .. 'TextLeft1')
		if UnitIsAFK(unit) then
			local lineText = nameField:GetText();
			if (lineText and lineText:sub(1, CHAT_FLAG_AFK:len()) ~= CHAT_FLAG_AFK) then
				nameField:SetText(CHAT_FLAG_AFK..lineText);
			end
		end

		--add the player's dnd status, taken from GuildenTipper
		if UnitIsDND(unit) then
			local lineText = nameField:GetText();
			if (lineText and lineText:sub(1, CHAT_FLAG_DND:len()) ~= CHAT_FLAG_DND) then
				nameField:SetText(CHAT_FLAG_DND..lineText);
			end
		end
		GameTooltip:Show();
	end
end)