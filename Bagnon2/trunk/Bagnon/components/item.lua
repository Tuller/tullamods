--[[
	item.lua
		An item slot button
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local ItemSlot = Bagnon.Classy:New('Button')
ItemSlot:Hide()
Bagnon.ItemSlot = ItemSlot


--[[
	The item widget
--]]


--[[ ItemSlot Constructor ]]--

function ItemSlot:New(bag, slot, frameID, parent)
	local item = self:Restore() or self:Create()

	item:SetParent(item:GetDummyBag(parent, bag))
	item:SetID(slot)
	item:SetFrameID(frameID)

	if item:IsVisible() then
		item:UpdateEverything()
	else
		item:Show()
	end

	return item
end

--constructs a brand new item slot
function ItemSlot:Create()
	local id = self:GetNextItemSlotID()
--	local item = self:Bind(self:ConstructNewItemSlot(id))
	local item = self:Bind(self:GetBlizzardItemSlot(id) or self:ConstructNewItemSlot(id))

	--add a quality border texture
	local border = item:CreateTexture(nil, 'OVERLAY')
	border:SetWidth(67)
	border:SetHeight(67)
	border:SetPoint('CENTER', item)
	border:SetTexture([[Interface\Buttons\UI-ActionButton-Border]])
	border:SetBlendMode('ADD')
	border:Hide()
	item.border = border

	--hack, make sure the cooldown model stays visible
	item.cooldown = _G[item:GetName() .. 'Cooldown']

	--get rid of any registered frame events, and use my own
	item:SetScript('OnEvent', item.OnEvent)
	item:SetScript('OnEnter', item.OnEnter)
	item:SetScript('OnLeave', item.OnLeave)
	item:SetScript('OnShow', item.OnShow)
	item:SetScript('OnHide', item.OnHide)
	item:SetScript('PostClick', item.PostClick)
	item.UpdateTooltip = nil

	return item
end

--creates a new item slot for <id>
function ItemSlot:ConstructNewItemSlot(id)
	return CreateFrame('Button', 'BagnonItemSlot' .. id, nil, 'ContainerFrameItemButtonTemplate')
end

--returns an available blizzard item slot for <id>
function ItemSlot:GetBlizzardItemSlot(id)
	local bag = math.ceil(id / MAX_CONTAINER_ITEMS)
	local slot = (id-1) % MAX_CONTAINER_ITEMS + 1
	local item = _G[format('ContainerFrame%dItem%d', bag, slot)]

	if item then
		item:SetID(0)
		item:ClearAllPoints()
		return item
	end
end

--returns the next available item slot
function ItemSlot:Restore()
	local item = ItemSlot.unused and next(ItemSlot.unused)
	if item then
		ItemSlot.unused[item] = nil
		return item
	end
end

--gets the next unique item slot id
do
	local id = 1
	function ItemSlot:GetNextItemSlotID()
		local nextID = id
		id = id + 1
		return nextID
	end
end



--[[ ItemSlot Destructor ]]--

function ItemSlot:Free()
	self:Hide()
	self:SetParent(nil)
	self:UnregisterAllEvents()
	self:UnregisterAllItemSlotEvents()
	self:UnregisterAllMessages()

	ItemSlot.unused = ItemSlot.unused or {}
	ItemSlot.unused[self] = true
end


--[[ Events ]]--

function ItemSlot:ITEM_LOCK_CHANGED(event, bag, slot)
	if self:IsSlot(bag, slot) then
		self:UpdateLocked()
	end
end

function ItemSlot:ITEM_SLOT_UPDATE_COOLDOWN(msg, bag, slot)
	if self:IsSlot(bag, slot) then
		self:UpdateCooldown()
	end
end

function ItemSlot:ITEM_SLOT_ADD(msg, bag, slot)
	if self:IsSlot(bag, slot) then
		self:Update()
	end
end

function ItemSlot:ITEM_SLOT_UPDATE(msg, bag, slot)
	if self:IsSlot(bag, slot) then
		self:Update()
	end
end

function ItemSlot:BANK_OPENED(msg)
	self:UpdateEverything()
end

function ItemSlot:BANK_CLOSED(msg)
	self:UpdateEverything()
end

function ItemSlot:PLAYER_UPDATE(msg, frameID, player)
	if self:GetFrameID() == frameID then
		self:UpdateEverything()
	end
end

function ItemSlot:TEXT_SEARCH_UPDATE(msg, frameID, search)
	if self:GetFrameID() == frameID then
		self:UpdateSearch()
	end
end

function ItemSlot:TEXT_SEARCH_ENABLE(msg, frameID, search)
	if self:GetFrameID() == frameID then
		self:UpdateSearch()
	end
end

function ItemSlot:TEXT_SEARCH_DISABLE(msg, frameID, search)
	if self:GetFrameID() == frameID then
		self:UpdateSearch()
	end
end

function ItemSlot:BAG_SEARCH_UPDATE(msg, frameID, search)
	if self:GetFrameID() == frameID then
		self:UpdateBagSearch()
	end
end

function ItemSlot:ITEM_HIGHLIGHT_QUALITY_UPDATE(msg, enable)
	self:UpdateBorder()
end

function ItemSlot:ITEM_HIGHLIGHT_QUEST_UPDATE(msg, enable)
	self:UpdateBorder()
end

function ItemSlot:SHOW_EMPTY_ITEM_SLOT_TEXTURE_UPDATE(msg, enable)
	self:Update()
end

--event registration
function ItemSlot:RegisterItemSlotEvent(...)
	Bagnon.BagEvents:Listen(self, ...)
end

function ItemSlot:UnregisterItemSlotEvent(...)
	Bagnon.BagEvents:Ignore(self, ...)
end

function ItemSlot:UnregisterAllItemSlotEvents(...)
	Bagnon.BagEvents:IgnoreAll(self, ...)
end


--[[ Frame Events ]]--

function ItemSlot:OnEvent(event, ...)
	if self[event] then
		self[event](self, event, ...)
	end
end

function ItemSlot:OnShow()
	self:UpdateEverything()
end

function ItemSlot:OnHide()
	self:UpdateEvents()
	self:HideStackSplitFrame()
end

function ItemSlot:OnDragStart()
	if self:IsCached() and CursorHasItemSlot() then
		ClearCursor()
	end
end

function ItemSlot:OnModifiedClick(button)
	local link = self:IsCached() and self:GetItem()
	if link then
		HandleModifiedItemClick(link)
	end
end

function ItemSlot:OnEnter()
	local dummySlot = self:GetDummyItemSlot()

	if self:IsCached() then
		dummySlot:SetParent(self)
		dummySlot:SetAllPoints(self)
		dummySlot:Show()
	else
		dummySlot:Hide()

		if self:IsBank() then
			if self:GetItem() then
				self:AnchorTooltip()
				GameTooltip:SetInventoryItem('player', BankButtonIDToInvSlotID(self:GetID()))
				GameTooltip:Show()
				CursorUpdate(self)
			end
		else
			ContainerFrameItemButton_OnEnter(self)
		end
	end
end

function ItemSlot:OnLeave()
	GameTooltip:Hide()
	ResetCursor()
end


--[[ Update Methods ]]--

function ItemSlot:UpdateEverything()
	self:UpdateEvents()
	self:Update()
end


--register/unregister events based on visibility
function ItemSlot:UpdateEvents()
	self:UnregisterAllEvents()
	self:UnregisterAllItemSlotEvents()
	self:UnregisterAllMessages()

	if self:IsVisible() then
		self:RegisterMessage('PLAYER_UPDATE')
		self:RegisterMessage('TEXT_SEARCH_UPDATE')
		self:RegisterMessage('TEXT_SEARCH_ENABLE')
		self:RegisterMessage('TEXT_SEARCH_DISABLE')
		self:RegisterMessage('BAG_SEARCH_UPDATE')
		self:RegisterMessage('ITEM_HIGHLIGHT_QUEST_UPDATE')
		self:RegisterMessage('ITEM_HIGHLIGHT_QUALITY_UPDATE')
		self:RegisterMessage('SHOW_EMPTY_ITEM_SLOT_TEXTURE_UPDATE')

		if self:IsBankSlot() then
			self:RegisterItemSlotEvent('BANK_OPENED')
			self:RegisterItemSlotEvent('BANK_CLOSED')
		end

		if not self:IsCached() then
			self:RegisterEvent('ITEM_LOCK_CHANGED')
			self:RegisterItemSlotEvent('ITEM_SLOT_ADD')
			self:RegisterItemSlotEvent('ITEM_SLOT_UPDATE')
			self:RegisterItemSlotEvent('ITEM_SLOT_UPDATE_COOLDOWN')
		end
	end
end


-- Update the texture, lock status, and other information about an item
function ItemSlot:Update()
	if not self:IsVisible() then return end

	local texture, count, locked, quality, readable, lootable, link = self:GetItemSlotInfo()

	self:SetItem(link)
	self:SetTexture(texture)
	self:SetCount(count)
	self:SetLocked(locked)
	self:SetReadable(readable)
	self:SetBorderQuality(quality)
	self:UpdateCooldown()
	self:UpdateSlotColor()
	self:UpdateSearch()
	self:UpdateBagSearch()

	if GameTooltip:IsOwned(self) then
		self:UpdateTooltip()
	end
end

--item link
function ItemSlot:SetItem(itemLink)
	self.hasItem = itemLink or nil
end

function ItemSlot:GetItem()
	return self.hasItem
end

--item texture
function ItemSlot:SetTexture(texture)
	SetItemButtonTexture(self, texture or self:GetEmptyItemTexture())
end

function ItemSlot:GetEmptyItemTexture()
	if self:ShowingEmptyItemSlotTexture() then
		return [[Interface\PaperDoll\UI-Backpack-EmptySlot]]
	end
	return nil
end

function ItemSlot:UpdateSlotColor()
	if not self:GetItem() then
		if Bagnon.BagSlotInfo:IsAmmoBag(self:GetPlayer(), self:GetBag()) then
			SetItemButtonTextureVertexColor(self, 1, 1, 0.5)
			self:GetNormalTexture():SetVertexColor(1, 1, 0.5)
			return
		end
		
		if Bagnon.BagSlotInfo:IsTradeBag(self:GetPlayer(), self:GetBag()) then
			SetItemButtonTextureVertexColor(self, 0.5, 1, 0.5)
			self:GetNormalTexture():SetVertexColor(0.5, 1, 0.5)
			return
		end
		
		if Bagnon.BagSlotInfo:IsShardBag(self:GetPlayer(), self:GetBag()) then
			SetItemButtonTextureVertexColor(self, 0.5, 0.5, 1)
			self:GetNormalTexture():SetVertexColor(0.5, 0.5, 1)
			return
		end
	end
		
	SetItemButtonTextureVertexColor(self, 1, 1, 1)
	self:GetNormalTexture():SetVertexColor(1, 1, 1)
end

--item count
function ItemSlot:SetCount(count)
	SetItemButtonCount(self, count)
end

--readable status
function ItemSlot:SetReadable(readable)
	self.readable = readable
end

--locked status
function ItemSlot:SetLocked(locked)
	SetItemButtonDesaturated(self, locked)
end

function ItemSlot:UpdateLocked()
	self:SetLocked(self:IsLocked())
end

--returns true if the slot is locked, and false otherwise
function ItemSlot:IsLocked()
	return Bagnon.ItemSlotInfo:IsLocked(self:GetPlayer(), self:GetBag(), self:GetID())
end

--colors the item border based on the quality of the item.  hides it for common/poor items
function ItemSlot:SetBorderQuality(quality)
	local border = self.border

	if self:HighlightingQuestItems() then
		if self:IsQuestItem() then
			border:SetVertexColor(1, 1, 0, 0.5)
			border:Show()
			return
		end
	end

	if self:HighlightingItemsByQuality() then
		if self:GetItem() and quality and quality > 1 then
			local r, g, b = GetItemQualityColor(quality)
			border:SetVertexColor(r, g, b, 0.5)
			border:Show()
			return
		end
	end

	border:Hide()
end

function ItemSlot:UpdateBorder()
	local texture, count, locked, quality = self:GetItemSlotInfo()
	self:SetBorderQuality(quality)
end

--cooldown
function ItemSlot:UpdateCooldown()
	if self:GetItem() and (not self:IsCached()) then
		ContainerFrame_UpdateCooldown(self:GetBag(), self)
	else
		CooldownFrame_SetTimer(self.cooldown, 0, 0, 0)
		SetItemButtonTextureVertexColor(self, 1, 1, 1)
	end
end

--stack split frame
function ItemSlot:HideStackSplitFrame()
	if self.hasStackSplit and self.hasStackSplit == 1 then
		StackSplitFrame:Hide()
	end
end

--tooltip methods
ItemSlot.UpdateTooltip = ItemSlot.OnEnter

function ItemSlot:AnchorTooltip()
	if self:GetRight() >= (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end
end

--search
function ItemSlot:UpdateSearch()
	local shouldFade = false
	local search = self:GetItemSearch()
	if search and search ~= '' then
		local itemLink = self:GetItem()
		shouldFade = not(itemLink and Bagnon.ItemSearch:Find(itemLink, search))
	end
	if shouldFade then
		self:SetAlpha(0.4)
		SetItemButtonDesaturated(self, true)
		self.border:Hide()
	else
		self:SetAlpha(1)
		self:UpdateLocked()
		self:UpdateBorder()
		self:UpdateSlotColor()
	end
end

function ItemSlot:GetItemSearch()
	return self:GetSettings():IsTextSearchEnabled() and self:GetSettings():GetTextSearch()
end

--bag search
function ItemSlot:UpdateBagSearch()
	local search = self:GetBagSearch()
	if self:GetBag() == search then
		self:LockHighlight()
	else
		self:UnlockHighlight()
	end
end

function ItemSlot:GetBagSearch()
	return self:GetSettings():GetBagSearch()
end



--[[ Accessor Methods ]]--

function ItemSlot:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
		self:UpdateEverything()
	end
end

function ItemSlot:GetFrameID()
	return self.frameID
end

function ItemSlot:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end

function ItemSlot:GetPlayer()
	return self:GetSettings():GetPlayerFilter()
end

function ItemSlot:GetBag()
	return self:GetParent() and self:GetParent():GetID() or 1
end

function ItemSlot:IsSlot(bag, slot)
	return self:GetBag() == bag and self:GetID() == slot
end

function ItemSlot:IsCached()
	return Bagnon.BagSlotInfo:IsCached(self:GetPlayer(), self:GetBag())
end

function ItemSlot:IsBank()
	return Bagnon.BagSlotInfo:IsBank(self:GetBag())
end

function ItemSlot:IsBankSlot()
	local bag = self:GetBag()
	return Bagnon.BagSlotInfo:IsBank(bag) or Bagnon.BagSlotInfo:IsBankBag(bag)
end

function ItemSlot:AtBank()
	return Bagnon.PlayerInfo:AtBank()
end

function ItemSlot:GetItemSlotInfo()
	local texture, count, locked, quality, readable, lootable, link = Bagnon.ItemSlotInfo:GetItemInfo(self:GetPlayer(), self:GetBag(), self:GetID())
	return texture, count, locked, quality, readable, lootable, link
end

function ItemSlot:HighlightingItemsByQuality()
	return Bagnon.Settings:HighlightingItemsByQuality()
end

function ItemSlot:HighlightingQuestItems()
	return Bagnon.Settings:HighlightingQuestItems()
end

function ItemSlot:IsQuestItem()
	local itemLink = self:GetItem()
	if not itemLink then
		return false
	end
	return Bagnon.ItemSearch:Find(itemLink, 't:quest|quest')
end

function ItemSlot:ShowingEmptyItemSlotTexture()
	return Bagnon.Settings:ShowingEmptyItemSlotTextures()
end


--[[ Delicious Hacks ]]--

-- dummy slot - A hack, used to provide a tooltip for cached items without tainting other item code
function ItemSlot:GetDummyItemSlot()
	ItemSlot.dummySlot = ItemSlot.dummySlot or ItemSlot:CreateDummyItemSlot()
	return ItemSlot.dummySlot
end

function ItemSlot:CreateDummyItemSlot()
	local slot = CreateFrame('Button')
	slot:RegisterForClicks('anyUp')
	slot:SetToplevel(true)
	slot:Hide()

	local function Slot_OnEnter(self)
		local parent = self:GetParent()
		parent:LockHighlight()

		if parent:IsCached() and parent:GetItem() then
			ItemSlot.AnchorTooltip(self)
			GameTooltip:SetHyperlink(parent:GetItem())
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

	return slot
end


--dummy bag, a hack to enforce the internal blizzard rule that item:GetParent():GetID() == bagID
function ItemSlot:GetDummyBag(parent, bag)
	local dummyBags = parent.dummyBags

	--metatable magic to create a new frame on demand
	if not dummyBags then
		dummyBags = setmetatable({}, {
			__index = function(t, k)
				local f = CreateFrame('Frame', nil, parent)
				f:SetID(k)
				t[k] = f
				return f
			end
		})
		parent.dummyBags = dummyBags
	end

	return dummyBags[bag]
end