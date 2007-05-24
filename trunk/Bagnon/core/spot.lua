--[[
	spot.lua
		Searching functionality for Bagnon
--]]

BagnonSpot = {}

local function SearchBox_Create()
	local frame = CreateFrame('EditBox', nil, UIParent, 'GooeyPopup')
	frame:SetAutoFocus(false)
	frame:SetTextInsets(8, 8, 0, 0)
	frame:SetFontObject('ChatFontNormal')

	frame:SetScript('OnShow', function(self) self:SetFocus(); self:HighlightText() end)
	frame:SetScript('OnTextChanged', function(self) BagnonSpot:SetTextSearch(self:GetText()) end)
	frame:SetScript('OnEscapePressed', function(self) BagnonSpot:Hide() end)
	
	return frame
end

--shows the search box
function BagnonSpot:Show(anchor)
	if self:GetAnchor() == anchor then
		self:Hide()
	else
		if not self.frame then
			self.frame = SearchBox_Create()
		end

		self.frame.anchor = anchor
		self.frame:Show()
		self.frame:SetPoint("TOPLEFT", anchor:GetName() .. "Title", "TOPLEFT", -8, 6)
		self.frame:SetPoint("BOTTOMRIGHT", anchor:GetName() .. "Title", "BOTTOMRIGHT", -4, -6)
		self:SetTextSearch(self.frame:GetText())
	end
end

--hides the search box
function BagnonSpot:Hide()
	if self.frame and self.frame:IsShown() then
		self.frame.anchor = nil
		self.frame:Hide()
		self:ClearTextSearch()
	end
end

--sets the text search to the given text
function BagnonSpot:SetTextSearch(text)
	if text and text ~= '' then
		self.textSearch = text:lower()
	else
		self.textSearch = nil
	end
	self:UpdateFrames()
end

function BagnonSpot:SetBagSearch(bag)
	self.bagSearch = bag
	self:UpdateFrames()
end

--clears all searches
function BagnonSpot:ClearTextSearch()
	self.textSearch = nil
	self:UpdateFrames()
end

function BagnonSpot:ClearAllSearches()
	self.textSearch = nil
	self.bagSearch = nil
	self:UpdateFrames()
end

--updates all highlighting for frames
function BagnonSpot:UpdateFrames()	
	local bags = Bagnon:GetInventory()
	if bags and bags:IsShown() then
		bags:UpdateSearch()
	end
	
	local bank = Bagnon:GetBank()
	if bank and bank:IsShown() then
		bank:UpdateSearch()
	end
end


--[[ Access ]]--

function BagnonSpot:Searching()
	return (self.textSearch or self.bagSearch)
end

--returns the text of what we're searching for
function BagnonSpot:GetSearch()
	return self.textSearch, self.bagSearch
end

--returns what frame the edit box is anchored to, if any
function BagnonSpot:GetAnchor()
	if self.frame then
		return self.frame.anchor
	end
end