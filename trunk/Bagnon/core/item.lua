--[[
	item.lua
		An item button
--]]

BagnonItem = CreateFrame("Button")
BagnonItem.SIZE = 37

local Item_mt = {__index = BagnonItem}
local UPDATE_DELAY = 0.1

local bagSearch, nameSearch, qualitySearch
local MAX_CONTAINER_ITEMS = MAX_CONTAINER_ITEMS
local unused = {}

-- this is set as teh button's parent, in order to preserve compatibility with normal bag slot functions/other mods
local function DummyBag_Get(parent, bag)
	local bagFrame = getglobal(parent:GetName() .. bag)
	if not bagFrame then
		bagFrame = CreateFrame("Frame", parent:GetName() .. bag, parent)
		bagFrame:SetID(bag)
		BagnonUtil:Attach(bagFrame, parent)
	end

	return bagFrame
end

--create a dummy item slot for tooltips and modified clicks of cached items
do
	local slot = CreateFrame('Button')
	slot:RegisterForClicks('anyUp')
	slot:Hide()

	local function Slot_OnEnter(self)
		local parent = self:GetParent()
		if parent.cached and parent.hasItem then
			parent:LockHighlight()

			BagnonUtil:AnchorTooltip(self)
			GameTooltip:SetHyperlink(BagnonDB:GetItemData(parent:GetBag(), parent:GetID(), parent:GetPlayer()))
			GameTooltip:Show()
		else
			self:Hide()
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


--[[ Item Creation ]]--

--creates an entierly new item slot, if no blizzard slots are available
local lastCreated = 0
local function Item_Create()
	local item

	if BagnonUtil:ReusingFrames() then
		local bag = ceil(lastCreated / MAX_CONTAINER_ITEMS)
		local slot = mod(lastCreated - 1, MAX_CONTAINER_ITEMS) + 1
		item = getglobal(format("ContainerFrame%dItem%d", bag, slot))
		if item then
			item:SetParent(nil)
			item:SetID(0)
		end
	end

	if not item then
		item = CreateFrame("Button", format("BagnonItem%d", lastCreated), nil, "ContainerFrameItemButtonTemplate")
	end
	item:ClearAllPoints()
	item:Show()
	setmetatable(item, Item_mt)

	local border = item:CreateTexture(nil, "OVERLAY")
	border:SetWidth(67); border:SetHeight(67)
	border:SetPoint("CENTER", item)
	border:SetTexture("Interface/Buttons/UI-ActionButton-Border")
	border:SetBlendMode("ADD")
	border:Hide()
	item.border = border

	item:UnregisterAllEvents()
	item:SetScript("OnEvent", nil)
	item:SetScript("OnUpdate", nil)
	item:SetScript("OnEnter", BagnonItem.OnEnter)
	item:SetScript("OnHide", BagnonItem.OnHide)
	item.UpdateTooltip = nil

	lastCreated = lastCreated + 1

	return item
end

--takes an item from the pool of unused items, or creates a new one
local function Item_Get()
	local item = next(unused)
	if item then
		unused[item] = nil
		item:Show()
		return item
	end
	return Item_Create()
end

--places the item in the pool of unused items
local function Item_Release(item)
	item:ClearAllPoints()
	if item:IsMovable() then
		item:SetUserPlaced(false)
	end
	item:SetParent(nil)
	item:Hide()

	unused[item] = true
end


--[[ Object Methods ]]--

function BagnonItem.Get(parent, bag, slot)
	local item = Item_Get()
	BagnonUtil:Attach(item, DummyBag_Get(parent, bag))
	item:SetID(slot)

	return item
end

function BagnonItem:Release()
	self.cached = nil
	self.hasItem = nil
	Item_Release(self)
end


--[[ Update Functions ]]--

-- Update the texture, lock status, and other information about an item
function BagnonItem:Update()
	local _, link, texture, count, locked, readable, quality
	local slot = self:GetID()
	local bag = self:GetBag()
	local player = self:GetPlayer()

	if BagnonUtil:IsCachedBag(bag, player) then
		link, count, texture, quality = BagnonDB:GetItemData(bag, slot, player)
		self.cached = true
	else
		texture, count, locked, _, readable = GetContainerItemInfo(bag, slot)
		self.readable = readable
		self.cached = nil
	end

	if texture then
		self.hasItem = link or GetContainerItemLink(bag, slot)
	else
		self.hasItem = nil
	end

	SetItemButtonDesaturated(self, locked)
	SetItemButtonTexture(self, texture)
	SetItemButtonCount(self, count)

	self:UpdateSlotBorder()
	self:UpdateBorder(quality)
	self:UpdateCooldown()

	if BagnonSpot:Searching() then
		self:UpdateSearch()
	end
end

function BagnonItem:UpdateSearch()
	local text, bag = BagnonSpot:GetSearch()

	if text or bag then
		if bag then
			if self:GetBag() ~= bag then
				self:Fade()
				return
			end
		end

		if text then
			local link = self.hasItem
			if link then
				local name, _, quality, itemLevel, minLevel, type, subType, _, equipLoc = GetItemInfo(link)

				if text and text ~= type:lower() then
					if not(subType and subType:lower():find(text)) then
						if not(getglobal(equipLoc)) or text ~= getglobal(equipLoc):lower() then
							if not name:lower():find(text) then
								self:Fade()
								return
							end
						end
					end
				end
			else
				self:Fade()
				return
			end
		end
		self:Unfade(true)
	else
		self:Unfade()
	end
end

function BagnonItem:UpdateBorder(quality)
	local border = self.border
	local link = self.hasItem

	if link and BagnonUtil:ShowingBorders() then
		if not quality then
			quality = select(3, GetItemInfo(link))
		end

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
	local normalTexture = getglobal(self:GetName() .. "NormalTexture")

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
	local cooldown = getglobal(self:GetName().. "Cooldown")

	if (not self.cached) and self.hasItem then
		local start, duration, enable = GetContainerItemCooldown(self:GetBag(), self:GetID())
		CooldownFrame_SetTimer(cooldown, start, duration, enable)
	else
		CooldownFrame_SetTimer(cooldown, 0, 0, 0)
	end
end


--[[ OnX Functions ]]--

function BagnonItem:OnModifiedClick(button)
	if self.cached then
		if self.hasItem then
			if button == "LeftButton" then
				if IsModifiedClick("DRESSUP") then
					DressUpItemLink((BagnonDB:GetItemData(self:GetBag(), self:GetID(), self:GetPlayer())))
				elseif IsModifiedClick("CHATLINK") then
					ChatFrameEditBox:Insert(BagnonDB:GetItemData(self:GetBag(), self:GetID(), self:GetPlayer()))
				end
			end
		end
	end
end

function BagnonItem:OnEnter()
	local bag, slot = self:GetBag(), self:GetID()
	if self.cached then
		if self.hasItem then
			self.dummySlot:SetParent(self)
			self.dummySlot:SetAllPoints(self)
			self.dummySlot:Show()
		end
	else
		self.dummySlot:Hide()

		--boo for special case bank code
		if bag == BANK_CONTAINER then
			if self.hasItem then
				BagnonUtil:AnchorTooltip(self)
				GameTooltip:SetInventoryItem("player", BankButtonIDToInvSlotID(slot))
				GameTooltip:Show()
			end
		else
			ContainerFrameItemButton_OnEnter(self)
		end
	end
end
BagnonItem.UpdateTooltip = BagnonItem.OnEnter

function BagnonItem:OnHide()
	self:Unfade()
	if self.hasStackSplit and self.hasStackSplit == 1 then
		StackSplitFrame:Hide()
	end
end

function BagnonItem:Fade()
	local parent = self:GetParent()
	if parent then
		self:SetAlpha(parent:GetAlpha() / 3)
	end
	self:UnlockHighlight()
end

function BagnonItem:Unfade(highlight)
	local parent = self:GetParent()
	if parent then
		self:SetAlpha(parent:GetAlpha())
	else
		self:SetAlpha(1)
	end

	if highlight and not self.hasItem then
		self:LockHighlight()
	else
		self:UnlockHighlight()
	end
end

function BagnonItem:GetPlayer()
	local bag = self:GetParent()
	if bag then
		local frame = bag:GetParent()
		if frame then
			return frame:GetPlayer()
		end
	end
end

function BagnonItem:GetBag()
	local bag = self:GetParent()
	if bag then
		return bag:GetID()
	end
end