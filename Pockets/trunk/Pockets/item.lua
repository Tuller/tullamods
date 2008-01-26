--[[
	item.lua
		An item button
--]]

PocketItem = PocketUtil:CreateWidgetClass('Button')
PocketItem.SIZE = 37

--[[
	The item widget
--]]

local itemID = 1
local unused = {}

function PocketItem:Create()
	local item = self:New(CreateFrame('Button', format('PocketItem%d', itemID), nil, 'ContainerFrameItemButtonTemplate'))
	item:ClearAllPoints()

	local border = item:CreateTexture(nil, 'OVERLAY')
	border:SetWidth(67); border:SetHeight(67)
	border:SetPoint('CENTER', item)
	border:SetTexture('Interface/Buttons/UI-ActionButton-Border')
	border:SetBlendMode('ADD')
	border:Hide()
	item.border = border

	item.cooldown = getglobal(item:GetName() .. 'Cooldown')
	item.cooldown:SetFrameLevel(4)

	item:UnregisterAllEvents()
	item:SetScript('OnEvent', nil)
	item:SetScript('OnEnter', self.OnEnter)
	item:SetScript('OnHide', self.OnHide)
	item.UpdateTooltip = nil

	itemID = itemID + 1

	return item
end

function PocketItem:Get()
	local item = next(unused)
	if item then
		unused[item] = nil
		return item
	end
	return self:Create()
end

function PocketItem:Set(parent, bag, slot)
	self:SetParent(self:GetDummyBag(parent, bag))
	self:SetID(slot)
	self:Update()

	return item
end

function PocketItem:Release()
	unused[self] = true

	self.cached = nil
	self.hasItem = nil
	self:SetParent(nil)
	self:Hide()
end

function PocketItem:GetDummyBag(parent, id)
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
function PocketItem:Update()
	local _, link, texture, count, locked, readable, quality
	local slot = self:GetID()
	local bag = self:GetBag()

	if PocketUtil:IsCachedBag(bag) then
		if BagnonDB then
			link, count, texture, quality = BagnonDB:GetItemData(bag, slot)
			self.readable = nil
			self.cached = true
		end
	else
		texture, count, locked, _, readable = GetContainerItemInfo(bag, slot)
		self.readable = readable
		self.cached = nil
	end

	self.hasItem = texture and (link or GetContainerItemLink(bag, slot))

	SetItemButtonDesaturated(self, locked)
	SetItemButtonTexture(self, texture or 'Interface/PaperDoll/UI-Backpack-EmptySlot')
	SetItemButtonCount(self, count)

	self:UpdateBorder(quality)
	self:UpdateCooldown()

	if GameTooltip:IsOwned(self) then
		self:UpdateTooltip()
	end
end

--colors the item border based on the quality of the item.  hides it for common/poor items
function PocketItem:UpdateBorder(quality)
	local border = self.border
	local link = self.hasItem

	if link then
		local quality = quality or select(3, GetItemInfo(link))
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

function PocketItem:UpdateLock(locked)
	local locked = select(3, GetContainerItemInfo(self:GetBag(), self:GetID()))
	SetItemButtonDesaturated(self, locked)
end

function PocketItem:UpdateCooldown()
	if self.hasItem then
		local start, duration, enable = GetContainerItemCooldown(self:GetBag(), self:GetID())
		CooldownFrame_SetTimer(self.cooldown, start, duration, enable)
	elseif self.cooldown:IsShown() then
		CooldownFrame_SetTimer(self.cooldown, 0, 0, 0)
	end
end


--[[ Frame Events ]]--

function PocketItem:OnEnter()
	local bag, slot = self:GetBag(), self:GetID()
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
PocketItem.UpdateTooltip = PocketItem.OnEnter

function PocketItem:OnHide()
	if self.hasStackSplit and self.hasStackSplit == 1 then
		StackSplitFrame:Hide()
	end
end


--[[ Convenience Functions ]]--

function PocketItem:GetBag()
	local bag = self:GetParent()
	return bag and bag:GetID()
end

function PocketItem:AnchorTooltip()
	if self:GetRight() >= (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end
end