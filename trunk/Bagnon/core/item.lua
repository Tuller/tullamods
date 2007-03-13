--[[
	item.lua
		An item button
--]]

BagnonItem = CreateFrame('Button')
BagnonItem.SIZE = 37

local util = BagnonUtil

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
		util:Attach(bagFrame, parent)
	end

	return bagFrame
end


--[[ Frame Events ]]--

local function OnUpdate()
	if not this.isLink and GameTooltip:IsOwned(this) then
		if not this.elapsed or this.elapsed < 0 then
			local start, duration, enable = GetContainerItemCooldown(this:GetBag(), this:GetID())
			if (start > 0 and duration > 0 and enable == 1) then
				this:OnEnter()
			end
			this.elapsed = UPDATE_DELAY
		else
			this.elapsed = this.elapsed - arg1
		end
	end
end

local function OnEnter()
	this.elapsed = nil
	this:OnEnter()
end

local function OnLeave()
	this.elapsed = nil
	this:OnLeave()
end

local function OnHide()
	this:OnHide()
end

local function PostClick()
	this:PostClick(arg1)
end


--[[ Item Creation ]]--

--creates an entierly new item slot, if no blizzard slots are available
local function Item_Create()
	local bag = ceil(lastCreated / MAX_ITEMS_PER_BAG)
	local slot = mod(lastCreated - 1, MAX_ITEMS_PER_BAG) + 1

	local item = getglobal(format('ContainerFrame%dItem%d', bag, slot))
	if item then
		item:SetParent(nil); item:SetID(0); item:Show()
	else
		item = CreateFrame('Button', format('BagnonItem%s', lastCreated), nil, 'ContainerFrameItemButtonTemplate')
	end
	setmetatable(item, Item_mt)
	item:ClearAllPoints()

	local border = item:CreateTexture(item:GetName() .. 'Border', 'OVERLAY')
	border:SetWidth(67); border:SetHeight(67)
	border:SetPoint('CENTER', item)
	border:SetTexture('Interface\\Buttons\\UI-ActionButton-Border')
	border:SetBlendMode('ADD')
	border:Hide()

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
	util:Attach(item, DummyBag_Get(parent, bag))
	item:SetID(slot)

	return item
end

function BagnonItem:Release()
	self.hasItem = nil
	self.isLink = nil
	Item_Release(self)
end


--[[ Update Functions ]]--

-- Update the texture, lock status, and other information about an item
function BagnonItem:Update()
	local _, texture, count, locked, readable, quality
	local slot = self:GetID()
	local bag = self:GetBag()
	local player = self:GetPlayer()

	if util:IsCachedBag(bag, player) then
		count, texture, quality = select(2, BagnonDB:GetItemData(bag, slot, player))
		self.isLink = true
	else
		texture, count, locked, _, readable = GetContainerItemInfo(bag, slot)
		self.readable = readable
		self.isLink = nil
	end

	if texture then
		self.hasItem = true
	else
		self.hasItem = nil
	end

	SetItemButtonDesaturated(self, locked)
	SetItemButtonTexture(self, texture)
	SetItemButtonCount(self, count)

	self:UpdateSlotBorder()

	if self.isLink then
		self:UpdateLinkBorder(quality)
	else
		self:UpdateBorder()
	end

	if GameTooltip:IsOwned(self) then
		self.elapsed = nil
		self:OnEnter()
	end

	if BagnonSpot:Searching() then
		self:UpdateSearch()
	end
end

function BagnonItem:UpdateSearch()
	local textSearch, bagSearch = BagnonSpot:GetSearch()

	if bagSearch then
		if self:GetParent():GetID() ~= bagSearch then
			self:Fade()
			return
		end
	end

	if textSearch then
		local link = util:GetItemLink(self:GetBag(), self:GetID(), self:GetPlayer())
		if link then
			local name, _, quality, itemLevel, minLevel, type, subType, _, equipLoc = GetItemInfo(link)

			if textSearch and textSearch ~= type:lower() then
				if not(subType) or textSearch ~= subType:lower() then
					if not(getglobal(equipLoc)) or textSearch ~= getglobal(equipLoc):lower() then
						if not name:lower():find(textSearch) then
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

	if textSearch or bagSearch then
		self:Unfade(true)
	else
		self:Unfade()
	end
end

function BagnonItem:UpdateBorder()
	local border = getglobal(self:GetName() .. 'Border')
	local link = GetContainerItemLink(self:GetBag() , self:GetID())

	if util:GetSets().qualityBorders and link then
		local hex = link:match('|cff([%l%d]+)|H')
		local r = tonumber(strsub(hex, 1, 2), 16)/256
		local g = tonumber(strsub(hex, 3, 4), 16)/256
		local b = tonumber(strsub(hex, 5, 6), 16)/256

		if not(r == g and r == b) then
			border:SetVertexColor(r, g, b, 0.5)
			border:Show()
		else
			border:Hide()
		end
	else
		border:Hide()
	end
end

function BagnonItem:UpdateLinkBorder(quality)
	local slot = self:GetID()
	local bag = self:GetBag()
	local player = self:GetPlayer()
	local border = getglobal(self:GetName() .. 'Border')

	if util:GetSets().qualityBorders and self.hasItem then
		if not quality then
			quality = select(3, GetItemInfo((BagnonDB:GetItemData(bag, slot, player))))
		end

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

function BagnonItem:UpdateSlotBorder()
	local bag = self:GetBag()
	local player = self:GetPlayer()
	local normalTexture = getglobal(self:GetName() .. 'NormalTexture')

	if bag == KEYRING_CONTAINER then
		normalTexture:SetVertexColor(1, 0.7, 0)
	elseif util:IsAmmoBag(bag, player) then
		normalTexture:SetVertexColor(1, 1, 0)
	elseif util:IsProfessionBag(bag , player) then
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

	if (not self.isLink) and self.hasItem then
		local start, duration, enable = GetContainerItemCooldown(self:GetBag(), self:GetID())
		CooldownFrame_SetTimer(cooldown, start, duration, enable)
	else
		CooldownFrame_SetTimer(cooldown, 0, 0, 0)
	end
end


--[[ OnX Functions ]]--

function BagnonItem:PostClick(mouseButton)
	if IsModifierKeyDown() then
		if this.isLink then
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

	if self.isLink then
		if self.hasItem then
			local player = self:GetPlayer()
			local link, count = BagnonDB:GetItemData(bag, slot, player)

			util:AnchorTooltip(self)
			GameTooltip:SetHyperlink(link, count)
		end
	else
		if bag == -1 then
			--this  is done instead of setting bank item because it allows me to hook tooltips properly, without screwing up some stuff
			local link = GetInventoryItemLink('player', BankButtonIDToInvSlotID(slot))
			if link then
				local count = GetInventoryItemCount('player', BankButtonIDToInvSlotID(slot))
				util:AnchorTooltip(self)
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

	if highlight and not util:GetItemLink(self:GetBag(), self:GetID(), self:GetPlayer()) then
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