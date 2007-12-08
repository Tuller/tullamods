--[[
	item.lua
		An item button
--]]

CombuctorItem = CombuctorUtil:CreateWidgetClass('Button')
CombuctorItem.SIZE = 37

--create a dummy item slot for tooltips and modified clicks of cached items
do
	local slot = CreateFrame('Button')
	slot:RegisterForClicks('anyUp')
	slot:SetToplevel(true)
	slot:Hide()

	local function Slot_OnEnter(self)
		local parent = self:GetParent()
		local link = parent.hasItem

		parent:LockHighlight()
		if parent.cached and link then
			CombuctorItem.AnchorTooltip(self)
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

	CombuctorItem.dummySlot = slot
end


--[[
	The item widget
--]]

local itemID = 1
local unused = {}

function CombuctorItem:Create()
	local item = self:New(self:GetBlizzard(itemID) or CreateFrame('Button', format('CombuctorItem%d', itemID), nil, 'ContainerFrameItemButtonTemplate'))
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
	item:SetScript('PostClick', self.PostClick)
	item.UpdateTooltip = nil

	itemID = itemID + 1

	return item
end

function CombuctorItem:GetBlizzard(id)
	local bag = ceil(id / MAX_CONTAINER_ITEMS)
	local slot = (id-1) % MAX_CONTAINER_ITEMS + 1
	local item = getglobal(format('ContainerFrame%dItem%d', bag, slot))

	if item then
		item:SetID(0)
		return item
	end
end

function CombuctorItem:Get()
	local item = next(unused)
	if item then
		unused[item] = nil
		return item
	end
	return self:Create()
end

function CombuctorItem:Set(parent, bag, slot)
	self:SetParent(self:GetDummyBag(parent, bag))
	self:SetID(slot)
	self:Update()

	return item
end

function CombuctorItem:Release()
	unused[self] = true

	self.cached = nil
	self.hasItem = nil
	self:SetParent(nil)
	self:Hide()
end

function CombuctorItem:GetDummyBag(parent, id)
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
function CombuctorItem:Update()
	local _, link, texture, count, locked, readable, quality
	local slot = self:GetID()
	local bag = self:GetBag()
	local player = self:GetPlayer()

	if CombuctorUtil:IsCachedBag(bag, player) then
		if BagnonDB then
			link, count, texture, quality = BagnonDB:GetItemData(bag, slot, player)
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
function CombuctorItem:UpdateBorder(quality)
	local border = self.border
	local link = self.hasItem

	if link then
		local quality = quality or select(3, GetItemInfo(link))
		if quality > 1 then
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

function CombuctorItem:UpdateLock(locked)
	local locked = select(3, GetContainerItemInfo(self:GetBag(), self:GetID()))
	SetItemButtonDesaturated(self, locked)
end

function CombuctorItem:UpdateCooldown()
	if (not self.cached) and self.hasItem then
		local start, duration, enable = GetContainerItemCooldown(self:GetBag(), self:GetID())
		CooldownFrame_SetTimer(self.cooldown, start, duration, enable)
	elseif self.cooldown:IsShown() then
		CooldownFrame_SetTimer(self.cooldown, 0, 0, 0)
	end
end


--[[ Frame Events ]]--

function CombuctorItem:OnDragStart()
	if self.cached and CursorHasItem() then
		ClearCursor()
	end
end

function CombuctorItem:OnModifiedClick(button)
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

function CombuctorItem:OnEnter()
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
CombuctorItem.UpdateTooltip = CombuctorItem.OnEnter

function CombuctorItem:OnHide()
	if self.hasStackSplit and self.hasStackSplit == 1 then
		StackSplitFrame:Hide()
	end
end

function CombuctorItem:Highlight(enable)
	if enable then
		self:LockHighlight()
	else
		self:UnlockHighlight()
	end
end


--[[ Convenience Functions ]]--

function CombuctorItem:GetPlayer()
	local bag = self:GetParent()
	if bag then
		local frame = bag:GetParent()
		return frame and frame:GetPlayer()
	end
	return currentPlayer
end

function CombuctorItem:GetBag()
	local bag = self:GetParent()
	return bag and bag:GetID()
end

function CombuctorItem:AnchorTooltip()
	if self:GetRight() >= (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end
end