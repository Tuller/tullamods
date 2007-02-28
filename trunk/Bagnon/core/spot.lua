--[[
	spot.lua
		Scripts for Bagnon_Spot, which provides filtering functionality for Bagnon
--]]

local function ParseType(s)
	BagnonItem.SetTypeSearch(s)
	return ''
end

local function ParseQuality(q)
	BagnonItem.SetQualitySearch(q)
	return ''
end

local function ClearSearch()
	BagnonSpot:SetText('')
	BagnonItem.ClearSearch()
end

local function Search(text)
	if text and text ~= '' then
		text = text:lower()
		text = text:gsub('%s*q:(%d+)', ParseQuality)

		local name = text
		if name and name ~= '' then
			BagnonItem.SetNameSearch(name)
		else
			BagnonItem.SetNameSearch(nil)
		end
	else
		BagnonItem.SetNameSearch(nil)
	end
end

local function CreateSearchFrame()
	local search = CreateFrame('EditBox', 'BagnonSpot', UIParent, 'GooeyPopup')
	search:SetAutoFocus(false)
	search:SetTextInsets(8, 8, 0, 0)
	search:SetFontObject('ChatFontNormal')

	search:SetScript('OnShow', function() this:SetFocus() end)
	search:SetScript('OnHide', function() ClearSearch() end)
	search:SetScript('OnEscapePressed', function() this:Hide() end)
	search:SetScript('OnEditFocusLost', function() this:HighlightText() end)
	search:SetScript('OnTextChanged', function() Search(this:GetText()) end)
end

--[[ Usable Functions ]]--

function BagnonSpot_Show(frame)
	if not BagnonSpot then
		CreateSearchFrame()
	end

	BagnonSpot.frame = frame

	BagnonSpot:ClearAllPoints()
	BagnonSpot:SetPoint("TOPLEFT", frame:GetName() .. "Title", "TOPLEFT", -8, 6)
	BagnonSpot:SetPoint("BOTTOMRIGHT", frame:GetName() .. "Title", "BOTTOMRIGHT", -4, -6)

	ClearSearch()
	BagnonSpot:Show()
end