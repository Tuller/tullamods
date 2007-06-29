--[[
	item.lua
		An item button
--]]

PocketItem = CreateFrame("Button")
PocketItem.SIZE = 37

local Item_mt = {__index = PocketItem}
local UPDATE_DELAY = 0.3
local unused = {}
local lastCreated = 1

--[[ this is set as the button"s parent, in order to preserve compatiblity with normal bag slot functions and other mods ]]--

local function DummyBag_Get(parent, bag)
	local bagFrame = parent["bag" .. bag]
	if not bagFrame then
		bagFrame = CreateFrame("Frame", nil, parent)
		bagFrame:SetID(bag)
		PocketUtil:Attach(bagFrame, parent)
		parent["bag" .. bag] = bagFrame
	end
	return bagFrame
end

--[[ Frame Events ]]--

local function Item_OnUpdate(self, elapsed)
	if GameTooltip:IsOwned(self) then
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

local function Item_OnEnter(self)
	self.elapsed = nil
	self:OnEnter()
	self:SetScript("OnUpdate", Item_OnUpdate)
end

local function Item_OnLeave(self)
	self.elapsed = nil
	self:OnLeave()
	self:SetScript("OnUpdate", nil)
end

local function Item_OnHide(self)
	if(GameTooltip:IsOwned(self)) then
		self:OnLeave()
	end
	self:OnHide()
end

local function Item_Create()
	local item = CreateFrame("Button", format("PocketItem%s", lastCreated), nil, "ContainerFrameItemButtonTemplate")
	setmetatable(item, Item_mt)
	item:ClearAllPoints()
	item:Show()
	
	local count = getglobal(item:GetName() .. "Count")
	count:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", -2, 2)

	local border = item:CreateTexture(nil, "OVERLAY")
	border:SetWidth(67); border:SetHeight(67)
	border:SetPoint("CENTER", item)
	border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	border:SetBlendMode("ADD")
	border:Hide()
	item.border = border

	item:UnregisterAllEvents()
	item:SetScript("OnEvent", nil)
	item:SetScript("OnEnter", Item_OnEnter)
	item:SetScript("OnLeave", Item_OnLeave)
	item:SetScript("OnHide", Item_OnHide)

	lastCreated = lastCreated + 1
	return item
end

local function Item_Get()
	local item = next(unused)
	if item then
		unused[item] = nil
		item:Show()
		return item
	end
	return Item_Create()
end

local function Item_Release(self)
	if(GameTooltip:IsOwned(self)) then
		self:OnLeave()
	end
	self:ClearAllPoints()
	if self:IsMovable() then
		self:SetUserPlaced(false)
	end
	self:SetParent(nil)
	self:Hide()
	unused[self] = true
end


--[[ Object Methods ]]--

function PocketItem:Get(parent, bag, slot)
	local item = Item_Get()
	item:SetParent(DummyBag_Get(parent, bag))
	item:SetFrameLevel(2)
	item:SetID(slot)
	item:Update()

	return item
end

function PocketItem:Release()
	self.cached = nil
	self.hasItem = nil
	Item_Release(self)
end


--[[ Update Functions ]]--

function PocketItem:Update()
	local slot = self:GetID()
	local bag = self:GetBag()
	local texture, count, locked, _, readable = GetContainerItemInfo(bag, slot)

	self.readable = readable
	self.hasItem = texture and GetContainerItemLink(bag, slot)

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

function PocketItem:UpdateSlotBorder()
	local bag = self:GetBag()
	local normalTexture = getglobal(self:GetName() .. "NormalTexture")

	if bag == KEYRING_CONTAINER then
		normalTexture:SetVertexColor(1, 0.7, 0)
	elseif PocketUtil:IsAmmoBag(bag) then
		normalTexture:SetVertexColor(1, 1, 0)
	elseif PocketUtil:IsProfessionBag(bag) then
		normalTexture:SetVertexColor(0, 1, 0)
	else
		normalTexture:SetVertexColor(1, 1, 1)
	end
end

function PocketItem:UpdateLock(locked)
	local locked = select(3, GetContainerItemInfo(self:GetBag(), self:GetID()))
	SetItemButtonDesaturated(self, locked)
end

function PocketItem:UpdateCooldown()
	local cooldown = getglobal(self:GetName().. "Cooldown")
	if self.hasItem then
		local start, duration, enable = GetContainerItemCooldown(self:GetBag(), self:GetID())
		CooldownFrame_SetTimer(cooldown, start, duration, enable)
	else
		CooldownFrame_SetTimer(cooldown, 0, 0, 0)
	end
end


--[[ OnX Functions ]]--

function PocketItem:OnEnter()
	if not self:GetParent() then return end

	local bag = self:GetBag()
	local slot = self:GetID()

	if bag == -1 then
		--this  is done instead of setting bank item because it allows me to hook tooltips properly, without screwing up some stuff
		local link = self.hasItem
		if link then
			local count = GetInventoryItemCount("player", BankButtonIDToInvSlotID(slot))
			PocketUtil:AnchorTooltip(self)
			GameTooltip:SetHyperlink(link, count)
		end
	else
		ContainerFrameItemButton_OnEnter(self)
	end
end

function PocketItem:OnLeave()
	self.updateTooltip = nil
	GameTooltip:Hide()
	ResetCursor()
end

function PocketItem:OnHide()
	if self.hasStackSplit and self.hasStackSplit == 1 then
		StackSplitFrame:Hide()
	end
end

function PocketItem:GetBag()
	local bag = self:GetParent()
	return bag and bag:GetID()
end