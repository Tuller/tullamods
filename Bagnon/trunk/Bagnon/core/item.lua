--[[
	item.lua
		An item button
--]]

BagnonItem = BagnonUtil:CreateWidgetClass('Button')
BagnonItem.SIZE = 37

--create a dummy item slot for tooltips and modified clicks of cached items
do
	local slot = CreateFrame('Button')
	slot:RegisterForClicks('anyUp')
	slot:Hide()

	local function Slot_OnEnter(self)
		local parent = self:GetParent()
		local link = parent.hasItem

		parent:LockHighlight()
		if parent.cached and link then
			BagnonItem.AnchorTooltip(self)
			GameTooltip:SetHyperlink(link)
			GameTooltip:Show()
		end
	end

	local function Slot_OnLeave(self)
		GameTooltip:Hide()
		self:Hide()
	end

	local function Slot_OnHide(self)
		local parent = self:GetParent()
		if parent then
			parent:UnlockHighlight()
		end
	end

	local function Slot_OnClick(self, button)
		self:GetParent():OnModifiedClick(button)
	end

	slot.UpdateTooltip = Slot_OnEnter
	slot:SetScript('OnClick', Slot_OnClick)
	slot:SetScript('OnEnter', Slot_OnEnter)
	slot:SetScript('OnLeave', Slot_OnLeave)
	slot:SetScript('OnShow', Slot_OnEnter)
	slot:SetScript('OnHide', Slot_OnHide)

	BagnonItem.dummySlot = slot
end


--[[
	The item widget
--]]

local itemID = 1
local unused = {}

function BagnonItem:Create()
	local button = CreateFrame('Button', format('BagnonItem%d', itemID), nil, 'ContainerFrameItemButtonTemplate')
	item = self:New(button)
	item:ClearAllPoints()

	local border = item:CreateTexture(nil, 'OVERLAY')
	border:SetWidth(67); border:SetHeight(67)
	border:SetPoint('CENTER', item)
	border:SetTexture('Interface/Buttons/UI-ActionButton-Border')
	border:SetBlendMode('ADD')
	border:Hide()
	item.border = border

	item.cooldown = getglobal(item:GetName() .. 'Cooldown')

	item:UnregisterAllEvents()
	item:SetScript('OnEvent', nil)
	item:SetScript('OnEnter', self.OnEnter)
	item:SetScript('OnHide', self.OnHide)
	item:SetScript('PostClick', self.PostClick)
	item.UpdateTooltip = nil

	itemID = itemID + 1

	return item
end

function BagnonItem:Get()
	local item = next(unused)
	if item then
		unused[item] = nil
		return item
	end
	return self:Create()
end

function BagnonItem:Set(parent, bag, slot)
	self:SetParent(self:GetDummyBag(parent, bag))
	self:SetID(slot)
	self:Update()
end

function BagnonItem:Release()
	unused[self] = true

	self.cached = nil
	self.hasItem = nil
	self:SetParent(nil)
	self:Unfade()
	self:Hide()
end

function BagnonItem:GetDummyBag(parent, id)
	if not parent.dummyBags then
		parent.dummyBags = {}
	end

	local frame = parent.dummyBags[id]
	if not frame then
		frame = CreateFrame('Frame', nil, parent)
		frame:SetID(id)
		parent.dummyBags[id] = frame
	end

	return frame
end


--[[ Update Functions ]]--

-- Update the texture, lock status, and other information about an item
function BagnonItem:Update()
	local slot = self:GetID()
	local bag = self:GetBag()
	local player = self:GetPlayer()
	local link, count, texture, quality, locked, readable, cached = BagnonUtil:GetItemInfo(bag, slot, player)

	self.readable = readable
	self.cached = cached
	self.hasItem = texture and link

	SetItemButtonDesaturated(self, locked)
	SetItemButtonTexture(self, texture)
	SetItemButtonCount(self, count)

	self:UpdateBorder(quality)
	self:UpdateSlotBorder()
	self:UpdateCooldown()

	if GameTooltip:IsOwned(self) then
		self:UpdateTooltip()
	end

	self:UpdateFade()
end

--colors the item border based on the quality of the item.  hides it for common/poor items
function BagnonItem:UpdateBorder(quality)
	local border = self.border
	local link = self.hasItem

	if link and BagnonUtil:ShowingBorders() then
		if quality and quality > 1 then
			local r, g, b = GetItemQualityColor(quality)
			border:SetVertexColor(r, g, b, 0.5)
			border:Show()
		else
			border:Hide()
		end
	else
		border:Hide()
	end
end

function BagnonItem:UpdateSlotBorder()
	local bag = self:GetBag()
	local player = self:GetPlayer()
	local normalTexture = getglobal(self:GetName() .. 'NormalTexture')

	if bag == KEYRING_CONTAINER then
		normalTexture:SetVertexColor(1, 0.7, 0)
	elseif BagnonUtil:IsAmmoBag(bag, player) then
		normalTexture:SetVertexColor(1, 1, 0)
	elseif BagnonUtil:IsProfessionBag(bag , player) then
		normalTexture:SetVertexColor(0, 1, 0)
	else
		normalTexture:SetVertexColor(1, 1, 1)
	end
end

function BagnonItem:UpdateLock(locked)
	local locked = select(3, GetContainerItemInfo(self:GetBag(), self:GetID()))
	SetItemButtonDesaturated(self, locked)
end

function BagnonItem:UpdateCooldown()
	if (not self.cached) and self.hasItem then
		local start, duration, enable = GetContainerItemCooldown(self:GetBag(), self:GetID())
		CooldownFrame_SetTimer(self.cooldown, start, duration, enable)
	else
		self.cooldown:Hide()
	end
end


--[[ Spot Searching ]]--

function BagnonItem:UpdateFade()
	if not BagnonSpot:Searching() then
		self:Unfade()
	elseif self:InBagSearch(BagnonSpot:GetBagSearch()) and self:InItemSearch(BagnonSpot:GetTextSearch()) then
		self:Unfade(true)
	else
		self:Fade()
	end
end

function BagnonItem:Fade()
	local parent = self:GetParent()
	if parent then
		self:SetAlpha(0.3)
	end
	self:UnlockHighlight()
end

function BagnonItem:Unfade(highlight)
	self:SetAlpha(1)
	if highlight and not self.hasItem then
		self:LockHighlight()
	else
		self:UnlockHighlight()
	end
end


--[[ Search Matching ]]--

--intersect search
function BagnonItem:InBagSearch(...)
	local myBag = self:GetBag()
	for i = 1, select('#', ...) do
		local bag = select(i, ...)
		if bag and myBag ~= bag then
			return false
		end
	end
	return true
end

--deal with intersect searches
function BagnonItem:InItemSearch(...)
	for i = 1, select('#', ...) do
		local search = select(i, ...)
		if not self:InSingleItemSearch(search) then
			return false
		end
	end
	return true
end

--utility function to do a lot of basic text searches at once
local function searchIsInText(search, ...)
	for i = 1, select('#', ...) do
		local text = select(i, ...)
		text = text and text:lower()
		if text and (text == search or text:match(search)) then
			return true
		end
	end
	return false
end

local tooltipSearches = {
	['boe'] = ITEM_BIND_ON_EQUIP,
	['bop'] = ITEM_BIND_ON_PICKUP,
	['bou'] = ITEM_BIND_ON_USE,
	['quest'] = ITEM_BIND_QUEST,
	['boa'] = ITEM_BIND_TO_ACCOUNT
}

function BagnonItem:InSingleItemSearch(search)
	local link = self.hasItem
	--no link == no item, so fail
	if not link then
		return false
	end

	local name, itemLink, quality, itemLevel, reqLevel, type, subType, stackCount, equipLoc = GetItemInfo(link)
	--no name == no returns from getiteminfo, so fail
	if not name then
		return false
	end

	local tooltipSearch = tooltipSearches[search]
	if tooltipSearch then
		return self:IsSearchInTooltip(tooltipSearch)
	end

	--item info searches
	if searchIsInText(search, name, type, subType, _G[equipLoc]) then
		return true
	end

	--quality searches, look for either number or text (epic, etc)
	if quality == tonumber(search) or searchIsInText(search, _G['ITEM_QUALITY' .. quality .. '_DESC']) then
		return true
	end

	return false
end

do
	local searchTooltip = CreateFrame('GameTooltip', 'BagnonItemSearchTooltip', UIParent, 'GameTooltipTemplate')
	function BagnonItem:IsSearchInTooltip(search)
		local result = false
		
		searchTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
		searchTooltip:SetHyperlink(self.hasItem)
		
		if searchTooltip:NumLines() > 1 and _G[searchTooltip:GetName() .. 'TextLeft2']:GetText() == search then
			result = true 
		elseif searchTooltip:NumLines() > 2 and _G[searchTooltip:GetName() .. 'TextLeft3']:GetText() == search then
			result = true
		end		
		
		searchTooltip:Hide()
		return result
	end
end


--[[ Frame Events ]]--

function BagnonItem:OnModifiedClick(button)
	if self.cached then
		if self.hasItem then
			if button == 'LeftButton' then
				if IsModifiedClick('DRESSUP') then
					DressUpItemLink((BagnonDB:GetItemData(self:GetBag(), self:GetID(), self:GetPlayer())))
				elseif IsModifiedClick('CHATLINK') then
					ChatFrameEditBox:Insert(BagnonDB:GetItemData(self:GetBag(), self:GetID(), self:GetPlayer()))
				end
			end
		end
	end
end

function BagnonItem:OnEnter()
	local bag, slot = self:GetBag(), self:GetID()
	if self.cached then
		self.dummySlot:SetParent(self)
		self.dummySlot:SetAllPoints(self)
		self.dummySlot:Show()
	else
		self.dummySlot:Hide()

		--boo for special case bank code
		if bag == BANK_CONTAINER then
			if self.hasItem then
				self:AnchorTooltip()
				GameTooltip:SetInventoryItem('player', BankButtonIDToInvSlotID(slot))
				GameTooltip:Show()
			end
		else
			ContainerFrameItemButton_OnEnter(self)
		end
	end
end
BagnonItem.UpdateTooltip = BagnonItem.OnEnter

function BagnonItem:OnHide()
	if self.hasStackSplit and self.hasStackSplit == 1 then
		StackSplitFrame:Hide()
	end
end


--[[ Convenience Functions ]]--

function BagnonItem:GetPlayer()
	local bag = self:GetParent()
	if bag then
		local frame = bag:GetParent()
		return frame and frame:GetPlayer()
	end
	return currentPlayer
end

function BagnonItem:GetBag()
	local bag = self:GetParent()
	return bag and bag:GetID()
end

function BagnonItem:AnchorTooltip()
	if self:GetRight() >= (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end
end