--[[
	itemFrame.lua
		An item slot container
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local ItemFrame = Bagnon.Classy:New('Frame')
ItemFrame:Hide()
Bagnon.ItemFrame = ItemFrame


--[[ Extreme Constants! ]]--

ItemFrame.ITEM_SIZE = 39


--[[ Constructor ]]--

local function throttledUpdater_OnUpdate(self, elapsed)
	local p = self:GetParent()
	if p:NeedsLayout() then
		p:Layout()
	end
	self:Hide()
end

function ItemFrame:New(frameID, parent)
	local f = self:Bind(CreateFrame('Frame', nil, parent))

	f.itemSlots = {}
	f.throttledUpdater = CreateFrame('Frame', nil, f)
	f.throttledUpdater:SetScript('OnUpdate', throttledUpdater_OnUpdate)
	f:SetFrameID(frameID)
	f:SetScript('OnSizeChanged', f.OnSizeChanged)

	return f
end


--[[ Messages ]]--

function ItemFrame:ITEM_SLOT_ADD(msg, bag, slot)
	self:AddItemSlot(bag, slot)
end

function ItemFrame:ITEM_SLOT_REMOVE(msg, bag, slot)
	self:RemoveItemSlot(bag, slot)
end

function ItemFrame:BANK_SHOW(msg)
	self:UpdateEverything()
end

function ItemFrame:BANK_HIDE(msg)
	self:UpdateEverything()
end

function ItemFrame:PLAYER_UPDATE(msg, frameID, player)
	if self:GetFrameID() == frameID then
		self:UpdateEverything()
	end
end

function ItemFrame:BAGS_UPDATE(msg, frameID)
	if self:GetFrameID() == frameID then
		self:UpdateEverything()
	end
end

function ItemFrame:BAG_SLOT_SHOW(msg, frameID, bagSlot)
	if self:GetFrameID() == frameID then
		self:AddAllItemSlotsForBag(bagSlot)
	end
end

function ItemFrame:BAG_SLOT_HIDE(msg, frameID, bagSlot)
	if self:GetFrameID() == frameID then
		self:RemoveAllItemSlotsForBag(bagSlot)
	end
end

function ItemFrame:ITEM_FRAME_SPACING_UPDATE(msg, frameID, spacing)
	if self:GetFrameID() == frameID then
		self:RequestLayout()
	end
end

function ItemFrame:ITEM_FRAME_COLUMNS_UPDATE(msg, frameID, columns)
	if self:GetFrameID() == frameID then
		self:RequestLayout()
	end
end

function ItemFrame:SLOT_ORDER_UPDATE(msg, frameID, enable)
	if self:GetFrameID() == frameID then
		self:RequestLayout()
	end
end

function ItemFrame:RegisterItemEvent(...)
	Bagnon.BagEvents:Listen(self, ...)
end

function ItemFrame:UnregisterItemEvent(...)
	Bagnon.BagEvents:Ignore(self, ...)
end

function ItemFrame:UnregisterAllItemEvents(...)
	Bagnon.BagEvents:IgnoreAll(self, ...)
end


--[[ Frame Events ]]--

function ItemFrame:OnShow()
	self:UpdateEverything()
end

function ItemFrame:OnHide()
	self:RemoveAllItemSlots()
	self:UpdateEvents()
end

function ItemFrame:OnSizeChanged()
	self:SendMessage('ITEM_FRAME_SIZE_CHANGE', self:GetFrameID())
end


--[[ Update Methods ]]--

function ItemFrame:UpdateEverything()
	self:UpdateEvents()

	if self:IsVisible() then
		self:ReloadAllItemSlots()
		self:RequestLayout()
	end
end

function ItemFrame:UpdateEvents()
	self:UnregisterAllItemEvents()
	self:UnregisterAllMessages()

	if self:IsVisible() then
		if not self:IsCached() then
			self:RegisterItemEvent('ITEM_SLOT_ADD')
			self:RegisterItemEvent('ITEM_SLOT_REMOVE')
			
			self:RegisterItemEvent('BANK_SHOW')
			self:RegisterItemEvent('BANK_HIDE')
		end
		self:RegisterMessage('BAGS_UPDATE')
		self:RegisterMessage('BAG_SLOT_SHOW')
		self:RegisterMessage('BAG_SLOT_HIDE')
		self:RegisterMessage('PLAYER_UPDATE')
		self:RegisterMessage('ITEM_FRAME_SPACING_UPDATE')
		self:RegisterMessage('ITEM_FRAME_COLUMNS_UPDATE')
		self:RegisterMessage('SLOT_ORDER_UPDATE')
	end
end


--[[ Item Slot Management ]]--

--if an item is not assigned to the given slotIndex, then add an item
function ItemFrame:AddItemSlot(bag, slot)
	if self:IsBagShown(bag) and not self:GetItemSlot(bag, slot) then
		local itemSlot = Bagnon.ItemSlot:New(bag, slot, self:GetFrameID(), self)
		self.itemSlots[self:GetSlotIndex(bag, slot)] = itemSlot
		self:RequestLayout()
	end
end

--removes any item slot associated with the given slotIndex
function ItemFrame:RemoveItemSlot(bag, slot)
	local itemSlot = self:GetItemSlot(bag, slot)
	if itemSlot then
		itemSlot:Free()
		self.itemSlots[self:GetSlotIndex(bag, slot)] = nil
		self:RequestLayout()
	end
end

--returns the item slot assigned to the given slotIndex
function ItemFrame:GetItemSlot(bag, slot)
	return self.itemSlots[self:GetSlotIndex(bag, slot)]
end

--takes a bag and a slot, and returns an array index
function ItemFrame:GetSlotIndex(bag, slot)
	if bag < 0 then
		return bag*100 - slot
	end
	return bag * 100 + slot
end

--remove all item slots from the frame
function ItemFrame:AddAllItemSlotsForBag(bag)
	for slot = 1, self:GetBagSize(bag) do
		self:AddItemSlot(bag, slot)
	end
end

function ItemFrame:RemoveAllItemSlotsForBag(bag)
	for slot = 1, self:GetBagSize(bag) do
		self:RemoveItemSlot(bag, slot)
	end
end

function ItemFrame:RemoveAllItemSlots()
	local itemSlots = self.itemSlots
	for i, itemSlot in pairs(itemSlots) do
		itemSlot:Free()
		itemSlots[i] = nil
	end
	self:RequestLayout()
end

--add all possible itemm slots ot the frame
function ItemFrame:ReloadAllItemSlots()
	self:RemoveAllItemSlots()

	for _, bag in self:GetVisibleBags() do
		for slot = 1, self:GetBagSize(bag) do
			self:AddItemSlot(bag, slot)
		end
	end
end


--[[ Layout Methods ]]--

--arranges itemSlots on the itemFrame, and adjusts size to fit
function ItemFrame:Layout()
	self.needsLayout = nil

	local columns = self:NumColumns()
	local spacing = self:GetSpacing()
	local effItemSize = self.ITEM_SIZE + spacing

	local i = 0
	for _, bag in self:GetVisibleBags() do
		for slot = 1, self:GetBagSize(bag) do
			local itemSlot = self:GetItemSlot(bag, slot)
			if itemSlot then
				i = i + 1
				local row = mod(i - 1, columns)
				local col = math.ceil(i / columns) - 1
				itemSlot:ClearAllPoints()
				itemSlot:SetPoint('TOPLEFT', self, 'TOPLEFT', effItemSize * row, -effItemSize * col)
			end
		end
	end

	local width = effItemSize * math.min(columns, i) - spacing
	local height = effItemSize * ceil(i / columns) - spacing
	self:SetWidth(width)
	self:SetHeight(height)
end

--request a layout update on this frame
function ItemFrame:RequestLayout()
	self.needsLayout = true
	self.throttledUpdater:Show()
end

--returns true if the frame should have its layout updated, and false otherwise
function ItemFrame:NeedsLayout()
	return self.needsLayout
end


--[[ Frame Properties ]]--

--frameID
function ItemFrame:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
		self:UpdateEverything()
	end
end

function ItemFrame:GetFrameID()
	return self.frameID
end

--frame settings
function ItemFrame:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end

--player info
function ItemFrame:GetPlayer()
	return self:GetSettings():GetPlayerFilter()
end

function ItemFrame:IsCached()
	return Bagnon.PlayerInfo:IsCached(self:GetPlayer())
end

--bag info
function ItemFrame:HasBag(bag)
	return self:GetSettings():HasBagSlot(slot)
end

function ItemFrame:GetBagSize(bag)
	return Bagnon.BagSlotInfo:GetSize(self:GetPlayer(), bag)
end

function ItemFrame:IsBagShown(bag)
	return self:GetSettings():IsBagSlotShown(bag)
end

function ItemFrame:GetVisibleBags()
	return self:GetSettings():GetVisibleBagSlots()
end

--layout info
function ItemFrame:NumColumns()
	return self:GetSettings():GetItemFrameColumns()
end

function ItemFrame:GetSpacing()
	return self:GetSettings():GetItemFrameSpacing()
end