--[[
	linkerator.lua
		Linkerator functionality for adapted for Ludwig
		Thanks to N00bZXI for the autocomplete changes
--]]

local function OnFullMatch(match)
	local list = Ludwig:GetItemsNamedLike(match)
	if list and list[1] then
		return (select(2, GetItemInfo(list[1])))
	end
	return match
end

local function OnPartialMatch(match)
	local list = Ludwig:GetItemsNamedLike(match)
	if list and list[1] then
		return '[[' .. GetItemInfo(list[1])
	end
	return '[[' .. match
end

local function Linkerator_OnChar(self, ...)
	local text = self:GetText()
	if text ~= '' then
		if text:match('%[%[(.+)%]') then
			self:SetText(text:gsub('%[%[(.+)%]', OnFullMatch))
		else
			self:SetText(text:gsub('%[%[(.+)', OnPartialMatch))
			self:HighlightText(#text, -1)
		end
	end
end

if ChatFrameEditBox:GetScript('OnChar') then
	ChatFrameEditBox:HookScript('OnChar', Linkerator_OnChar)
else
	ChatFrameEditBox:SetScript('OnChar', Linkerator_OnChar)
end