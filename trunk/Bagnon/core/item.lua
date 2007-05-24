--[[
	item.lua
		An item button
--]]

BagnonItem = CreateFrame('Button')
BagnonItem.SIZE = 37

local Item_mt = {__index = BagnonItem}
local UPDATE_DELAY = 0.3

local bagSearch, nameSearch, qualitySearch
local MAX_ITEMS_PER_BAG = 36

local unused = {}
local lastCreated = 1

--[[ this is set as the button's parent, in order to preserve compatiblity with normal bag slot functions and other mods ]]--

local function DummyBag_Get(parent, bag)
	local bagFrame = getglobal(parent:GetName() .. bag)
	if not bagFrame then
		bagFrame = CreateFrame('Frame', parent:GetName() .. bag, parent)
		bagFrame:SetID(bag)
		BagnonUtil:Attach(bagFrame, parent)
	end

	return bagFrame
end


--[[ Frame Events ]]--

local function OnUpdate(self, elapsed)
	if not self.cached and GameTooltip:IsOwned(self) then
		if not self.elapsed or self.elapsed < 0 then
			local start, duration, enable = GetContainerItemCooldown(self:GetBag(), self:GetID())
			if (start > 0 and duration > 0 and enable == 1) then
				self:OnEnter()
			end
			self.elapsed = UPDATE_DELAY
		else
			self.elapsed = self.elapsed - elapsed
		end
	end
end

local function OnEnter(self)
	self.elapsed = nil
	self:OnEnter()
end

local function OnLeave(self)
	self.elapsed = nil
	self:OnLeave()
end

local function OnHide(self)
	self:OnHide()
end

local function PostClick(self, button)
	self:PostClick(button)
end


--[[ Item Creation ]]--

--creates an entierly new item slot, if no blizzard slots are available
local function Item_Create()
	local item

	if BagnonUtil:ReusingFrames() then
		local bag = ceil(lastCreated / MAX_ITEMS_PER_BAG)
		local slot = mod(lastCreated - 1, MAX_ITEMS_PER_BAG) + 1
		item = getglobal(format('ContainerFrame%dItem%d', bag, slot))
		if item then
			item:SetParent(nil)
			item:SetID(0)
		end
	end
	item = item or CreateFrame('Button', format('BagnonItem%s', lastCreated), nil, 'ContainerFrameItemButtonTemplate')
	item:ClearAllPoints()
	item:Show()
	setmetatable(item, Item_mt)

	local border = item:CreateTexture(nil, 'OVERLAY')
	border:SetWidth(67); border:SetHeight(67)
	border:SetPoint('CENTER', item)
	border:SetTexture('Interface\\Buttons\\UI-ActionButton-Border')
	border:SetBlendMode('ADD')
	border:Hide()
	item.border = border

	item:UnregisterAllEvents()
	item:SetScript('OnEvent', nil)
	item:SetScript('OnEnter', OnEnter)
	item:SetScript('OnLeave', OnLeave)
	item:SetScript('OnUpdate', OnUpdate)
	item:SetScript('OnHide', OnHide)
	item:SetScript('PostClick', PostClick)

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

	if GameTooltip:IsOwned(self) then
		self.elapsed = nil
		self:OnEnter()
	end

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

	if BagnonUtil:ShowingBorders() and link then
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
	local cooldown = getglobal(self:GetName().. 'Cooldown')

	if (not self.cached) and self.hasItem then
		local start, duration, enable = GetContainerItemCooldown(self:GetBag(), self:GetID())
		CooldownFrame_SetTimer(cooldown, start, duration, enable)
	else
		CooldownFrame_SetTimer(cooldown, 0, 0, 0)
	end
end


--[[ OnX Functions ]]--

function BagnonItem:PostClick(mouseButton)
	if IsModifierKeyDown() then
		if this.cached then
			if this.hasItem then
				if mouseButton == 'LeftButton' then
					if IsControlKeyDown() then
						DressUpItemLink((BagnonDB:GetItemData(self:GetBag(), self:GetID(), self:GetPlayer())))
					elseif IsShiftKeyDown() then
						ChatFrameEditBox:Insert(BagnonDB:GetItemData(self:GetBag(), self:GetID(), self:GetPlayer()))
					end
				end
			end
		else
			ContainerFrameItemButton_OnModifiedClick(mouseButton)
		end
	end
end

function BagnonItem:OnEnter()
	if not self:GetParent() then return end

	local bag = self:GetBag()
	local slot = self:GetID()

	if self.cached then
		if self.hasItem then
			local player = self:GetPlayer()
			local link, count = BagnonDB:GetItemData(bag, slot, player)

			BagnonUtil:AnchorTooltip(self)
			GameTooltip:SetHyperlink(link, count)
		end
	else
		if bag == -1 then
			--this  is done instead of setting bank item because it allows me to hook tooltips properly, without screwing up some stuff
			local link = self.hasItem
			if link then
				local count = GetInventoryItemCount('player', BankButtonIDToInvSlotID(slot))
				BagnonUtil:AnchorTooltip(self)
				GameTooltip:SetHyperlink(link, count)
			end
		else
			--hack to prevent a ContainerFrameItemButton_OnEnter issue
			local prethis = this
			this = self
			ContainerFrameItemButton_OnEnter(self)
			this = prethis
		end
	end
end

function BagnonItem:OnLeave()
	self.updateTooltip = nil
	GameTooltip:Hide()
	ResetCursor()
end

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