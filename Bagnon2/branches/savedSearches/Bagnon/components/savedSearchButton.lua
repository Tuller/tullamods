--[[
	SavedSearchButton.lua
		A Bagnon saved search display widget
--]]

local SavedSearchButton = Bagnon.Classy:New('Button')
Bagnon.SavedSearchButton = SavedSearchButton

--constants
local SIZE = 20
local NORMAL_TEXTURE_SIZE = 64 * (SIZE/36)

local unused = {}

--[[
	constructor/destructor
--]]

function SavedSearchButton:New(searchID, frameID, parent)
	local b = self:Restore() or self:Create()
	b:SetParent(parent)
	b:SetFrameID(frameID)
	b:SetSearchID(searchID)
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

	local ct = b:CreateTexture()
	ct:SetTexture([[Interface\Buttons\CheckButtonHilight]])
	ct:SetAllPoints(b)
	ct:SetBlendMode('ADD')
	b:SetCheckedTexture(ct)

	local icon = b:CreateTexture()
	icon:SetAllPoints(b)
--	icon:SetTexture([[Interface\Buttons\Button-Backpack-Up]])
	b.icon = icon
	
	b:SetScript('OnShow', b.OnShow)
	b:SetScript('OnHide', b.OnHide)
	b:SetScript('OnEnter', b.OnEnter)
	b:SetScript('OnLeave', b.OnLeave)

	return b
end


--[[
	frame messages
--]]

function SavedSearchButton:SAVED_SEARCH_NAME_UPDATE(frameID, searchID, name)
	if self:IsSavedSearch(frameID, searchID) then
		self:UpdateTooltip()
	end
end

function SavedSearchButton:SAVED_SEARCH_ICON_UPDATE(frameID, searchID, icon)
	if self:IsSavedSearch(frameID, searchID) then
		self:UpdateIcon()
	end
end

function SavedSearchButton:UpdateMessages()
	self:UnregisterAllMessages()

	if self:IsVisible() then
		self:RegisterMessage('SAVED_SEARCH_NAME_UPDATE')
		self:RegisterMessage('SAVED_SEARCH_ICON_UPDATE')
	end
end


--[[
	frame events
--]]

function SavedSearchButton:OnShow()
	self:UpdateMessages()
	self:UpdateIcon()
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
	update methods
--]]

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


--[[
	saved search button properties
--]]

--set the id of the saved search this is attached to
function SavedSearchButton:SetSearchID(id)
	if self:GetSearchID() ~= id then
		self.searchID = id
		self:UpdateIcon()
		self:UpdateTooltip()
	end
end

function SavedSearchButton:GetSearchID()
	return self.searchID
end

function SavedSearchButton:GetSearchName()
	return self:GetSettings():GetSearchName(self:GetSearchID()) or self:GetSearchRule()
end

function SavedSearchButton:GetSearchIcon()
	return self:GetSettings():GetSearchIcon(self:GetSearchID()) or nil
end

function SavedSearchButton:GetSearchRule()
	return self:GetSettings():GetSearchRule(self:GetSearchID())
end


--[[
	frameID properties
--]]

--set the frameID that this object is attached to
function SavedSearchButton:SetFrameID(id)
	if self:GetFrameID() ~= id then
		self.frameID = id
		self:UpdateIcon()
		self:UpdateTooltip()
	end
end

function SavedSearchButton:GetFrameID()
	return self.frameID
end

function SavedSearchButton:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end