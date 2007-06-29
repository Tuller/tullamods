--[[
	linkerator.lua
		Linkerator functionality for adapted for Ludwig
		Thanks to N00bZXI for the autocomplete changes
--]]

local function LinkifyName(head, text, tail)
	if not(head == "|h" or tail == "|h") then
		if(#text > 2) then
			local list = Ludwig:GetItemsNamedLike(text)
			if list and list[1] then
				return Ludwig:GetItemLink(list[1])
			end
		end
	end
	return format("%s[%s]%s", head, text, tail)
end

local function ParseChatMessage(text)
	return text:gsub("([|]?[h]?)%[(.-)%]([|]?[h]?)", LinkifyName)
end

local OnChar = ChatFrameEditBox:GetScript("OnChar")
ChatFrameEditBox:SetScript("OnChar", function(self, ...)
	if(OnChar) then
		OnChar(self, ...)
	end

	local text = self:GetText()
	if not(text == "" or text:sub(1,1) == "/") then
		local query = text:match("%[([^]]-)$")
		if(query and #query > 2) then
			local list = Ludwig:GetItemsNamedLike(query)
			if list and list[1] then
				local link = GetItemInfo(list[1])
				self:SetText(text:gsub("%[([^]]-)$", "[".. link:gsub("^".. query:lower():gsub("([%$%(%)%.%[%]%*%+%-%?%^%%])", "%%%1"), query)))
				self:HighlightText(#text, -1)
				return
			end
		else
			self:SetText(ParseChatMessage(text))
		end
	end
end)