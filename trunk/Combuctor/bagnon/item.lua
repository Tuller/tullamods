--[[
	item.lua
		An item button
--]]

BagnonItem = CreateFrame("Button")
BagnonItem.SIZE = 37

local Item_mt = {__index = BagnonItem}
local UPDATE_DELAY = 0.1

local bagSearch, nameSearch, qualitySearch
local MAX_ITEMS_PER_BAG = MAX_CONTAINER_ITEMS

local unused = {}
local lastCreated = 1

local _G = getfenv(0)


--[[ this is set as the button"s parent, in order to preserve compatiblity with normal bag slot functions and other mods ]]--

local function DummyBag_Get(parent, id)
	local frame = parent["bag" .. id]
	if not frame then
		frame = CreateFrame("Frame", nil, parent)
		frame:SetID(id)
		parent["bag" .. id] = frame
	end
	return frame
end


--[[ Frame Events ]]--

local function OnUpdate(self, elapsed)
	if GameTooltip:IsOwned(self) then
		if not self.elapsed or self.elapsed < 0 then
			self:OnEnter()
			self.elapsed = UPDATE_DELAY
		else
			self.elapsed = self.elapsed - elapsed
		end
	end
end

local function OnEnter(self)
	self.elapsed = nil
	self:OnEnter()
	self:SetScript("OnUpdate", OnUpdate)
end

local function OnLeave(self)
	self.elapsed = nil
	self:OnLeave()
	self:SetScript("OnUpdate", nil)
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
	local bag = ceil(lastCreated / MAX_CONTAINER_ITEMS)
	local slot = mod(lastCreated-1, MAX_CONTAINER_ITEMS) + 1
	local item = getglobal(format("ContainerFrame%dItem%d", bag, slot))
	if item then
		item:SetParent(nil)
		item:SetID(0)
	end

	item = item or CreateFrame("Button", format("BagnonItem%s", lastCreated), nil, "ContainerFrameItemButtonTemplate")
	item:ClearAllPoints()
	item:Show()
	setmetatable(item, Item_mt)

	local border = item:CreateTexture(nil, "OVERLAY")
	border:SetWidth(67); border:SetHeight(67)
	border:SetPoint("CENTER", item)
	border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	border:SetBlendMode("ADD")
	border:Hide()
	item.border = border

	local cooldown = _G[item:GetName() .. "Cooldown"]
	cooldown:SetFrameLevel(item:GetFrameLevel() + 3)
	item.cooldown = cooldown

	item:UnregisterAllEvents()
	item:SetScript("OnEvent", nil)
	item:SetScript("OnEnter", OnEnter)
	item:SetScript("OnLeave", OnLeave)
	item:SetScript("OnHide", OnHide)
	item:SetScript("PostClick", PostClick)

	lastCreated = lastCreated + 1

	return item
end

--takes an item from the pool of unused items, or creates a new one
local function Item_Get()
	local item = next(unused)
	if item then
		unused[item] = nil
		return item
	end
	return Item_Create()
end

--places the item in the pool of unused items
local function Item_Release(item)
	item:ClearAllPoints()
	item:SetParent(nil)
	item:Hide()

	unused[item] = true
end


--[[ Object Methods ]]--

function BagnonItem:Set(frame, bag, slot)
	local item = Item_Get()
	item:SetParent(DummyBag_Get(frame, bag))
	item:SetID(slot)
	item:Update()
	item:Show()

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
		if(BagnonDB) then
			link, count, texture, quality = BagnonDB:GetItemData(bag, slot, player)
			self.cached = true
		end
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
end

function BagnonItem:UpdateBorder(quality)
	local border = self.border
	local link = self.hasItem

	if link then
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
	local normalTexture = _G[self:GetName() .. "NormalTexture"]

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
		CooldownFrame_SetTimer(self.cooldown, 0, 0, 0)
	end
end


--[[ OnX Functions ]]--

function BagnonItem:PostClick(button)
	if IsModifierKeyDown() then
		if self.cached then
			if self.hasItem then
				if button == "LeftButton" then
					if IsControlKeyDown() then
						DressUpItemLink((BagnonDB:GetItemData(self:GetBag(), self:GetID(), self:GetPlayer())))
					elseif IsShiftKeyDown() then
						ChatFrameEditBox:Insert(BagnonDB:GetItemData(self:GetBag(), self:GetID(), self:GetPlayer()))
					end
				end
			end
		else
			ContainerFrameItemButton_OnModifiedClick(button)
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
			if IsShiftKeyDown() then
				GameTooltip_ShowCompareItem()
			end
		end
	else
		if bag == -1 then
			--this  is done instead of setting bank item because it allows me to hook tooltips properly, without screwing up some stuff
			local link = self.hasItem
			if link then
				local count = GetInventoryItemCount("player", BankButtonIDToInvSlotID(slot))
				BagnonUtil:AnchorTooltip(self)
				GameTooltip:SetHyperlink(link, count)
				if IsShiftKeyDown() then
					GameTooltip_ShowCompareItem()
				end
			end
		else
			ContainerFrameItemButton_OnEnter(self)
		end
	end
end

function BagnonItem:OnLeave()
	self.updateTooltip = nil
	GameTooltip:Hide()
	ResetCursor()
end

function BagnonItem:OnHide()
	if self.hasStackSplit and self.hasStackSplit == 1 then
		StackSplitFrame:Hide()
	end
end

function BagnonItem:GetPlayer()
	local bag = self:GetParent()
	if bag then
		local frame = bag:GetParent()
		return frame and frame.player
	end
end

function BagnonItem:GetBag()
	local bag = self:GetParent()
	return bag and bag:GetID()
end