--[[
	SavedSearchButton.lua
		A Bagnon saved search display widget
--]]

local SavedSearchButton = Bagnon.Classy:New('Button')
Bagnon.SavedSearchButton = SavedSearchButton

--constants
local SIZE = 24
local NORMAL_TEXTURE_SIZE = 64 * (SIZE/36)

local unused = {}

--[[
	constructor/destructor
--]]

function SavedSearchButton:New(parent, searchInfo)
	local b = self:Restore() or self:Create()
	b:SetParent(parent)
	b:Show()
	
	return b
end

function SavedSearchButton:Free()
	b:UnregisterAllEvents()
	b:Hide()
	
	unused[b] = true
end

function SavedSearchButton:Restore()
	local b = next(unused)
	if b then
		unused[b] = nil
		return b
	end
end

function SavedSearchButton:Create()
	local b = self:Bind(CreateFrame('Button'))
	b:SetWidth(SIZE)
	b:SetHeight(SIZE)
	b:RegisterForClicks('anyUp')

	local nt = b:CreateTexture()
	nt:SetTexture([[Interface\Buttons\UI-Quickslot2]])
	nt:SetWidth(NORMAL_TEXTURE_SIZE)
	nt:SetHeight(NORMAL_TEXTURE_SIZE)
	nt:SetPoint('CENTER', 0, -1)
	b:SetNormalTexture(nt)

	local pt = b:CreateTexture()
	pt:SetTexture([[Interface\Buttons\UI-Quickslot-Depress]])
	pt:SetAllPoints(b)
	b:SetPushedTexture(pt)

	local ht = b:CreateTexture()
	ht:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
	ht:SetAllPoints(b)
	b:SetHighlightTexture(ht)

	local icon = b:CreateTexture()
	icon:SetAllPoints(b)
	b.icon = icon
	
	b:SetScript('OnShow', b.OnShow)
	b:SetScript('OnHide', b.OnHide)
	b:SetScript('OnEnter', b.OnEnter)
	b:SetScript('OnLeave', b.OnLeave)
	b:SetScript('OnClick', b.OnClick)

	return b
end


--[[
	frame events
--]]

function SavedSearchButton:OnShow()
	self:UpdateMessages()
end

function SavedSearchButton:OnHide()
	self:UpdateMessages()
end

function SavedSearchButton:OnEnter()
	if self:GetRight() > (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end
	
	self:UpdateTooltip()
end

function SavedSearchButton:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end

function SavedSearchButton:OnClick()
	self:GetSettings():EnableTextSearch()
	Bagnon.Settings:SetTextSearch(self:GetSearchRule())
end

--[[
	messages
--]]

function SavedSearchButton:UpdateMessages()
	self:UnregisterAllMessages()
	
	if self:IsVisible() then
		self:RegisterMessage('TEXT_SEARCH_ENABLE', 'UpdateFade')
		self:RegisterMessage('TEXT_SEARCH_DISABLE', 'UpdateFade')
		self:RegisterMessage('TEXT_SEARCH_UPDATE', 'UpdateFade')
	end
end

--[[
	update methods
--]]

function SavedSearchButton:UpdateEverything()
	self:UpdateMessages()
	self:UpdateIcon()
	self:UpdateTooltip()
	self:UpdateFade()
end

function SavedSearchButton:UpdateIcon()
	if self:IsVisible() then
		self.icon:SetTexture(self:GetSearchIcon())
	end
end

function SavedSearchButton:UpdateTooltip()
	if GameTooltip:IsOwned(self) then
		GameTooltip:SetText(self:GetSearchName())
		GameTooltip:Show()
	end
end

function SavedSearchButton:UpdateFade()
	local shouldFade = self:IsTextSearchEnabled() and (self:GetTextSearch() ~= self:GetSearchRule())
	if shouldFade then
		self:SetAlpha(0.4)
		self.icon:SetDesaturated(true)
	else
		self:SetAlpha(1)
		self.icon:SetDesaturated(false)
	end
end

function SavedSearchButton:IsTextSearchEnabled()
	return self:GetSettings():IsTextSearchEnabled()
end

function SavedSearchButton:GetTextSearch()
	return Bagnon.Settings:GetTextSearch()
end



--[[
	saved search button properties
--]]

function SavedSearchButton:SetSearchInfo(searchInfo)
	self.search = searchInfo
	self:UpdateEverything()
end

function SavedSearchButton:GetSearchInfo()
	local search = self.search
	if search then
		return search.name, search.icon, search.rule
	end
end

function SavedSearchButton:GetSearchName()
	local name, icon, rule = self:GetSearchInfo()
	return name or rule or 'Unknown Search'
end

do
	local UNKNOWN_ICON = [[Interface\Icons\INV_Misc_QuestionMark]]
	function SavedSearchButton:GetSearchIcon()
		local name, icon, rule = self:GetSearchInfo()
		return icon or UNKNOWN_ICON
	end
end

function SavedSearchButton:GetSearchRule()
	local name, icon, rule = self:GetSearchInfo()
	return rule or ''
end

function SavedSearchButton:GetSettings()
	return self:GetParent():GetSettings()
end