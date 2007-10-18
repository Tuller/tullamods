--[[
	item.lua
		An item button
		
	TODO:
		Need to import some of the bagnon changes in respect to clicking cached items
--]]

local _G = getfenv(0)

--creates a new class of objects that inherits from objects of <type>, ex 'Frame', 'Button', 'StatusBar'
--does not chain inheritance
local function CreateWidgetClass(type)
	local class = CreateFrame(type)
	local mt = {__index = class}

	function class:New(o)
		if o then
			local type, cType = o:GetFrameType(), self:GetFrameType()
			assert(type == cType, format("'%s' expected, got '%s'", cType, type))
		end
		return setmetatable(o or CreateFrame(type), mt)
	end

	return class
end

local function DummyBag_Get(parent, id)
	local frame = parent['bag' .. id]
	if not frame then
		frame = CreateFrame('Frame', nil, parent)
		frame:SetID(id)
		parent['bag' .. id] = frame
	end
	return frame
end

local function ToIndex(bag, slot)
	return (bag<0 and bag*100 - slot) or (bag*100 + slot)
end


--[[
	The item widget
--]]

CombuctorItem = CreateWidgetClass('Button')
CombuctorItem.SIZE = 37

local itemID = 1
local unused = {}

function CombuctorItem:Create()
	local item = self:New(CreateFrame('Button', format('CombuctorItem%d', itemID), nil, 'ContainerFrameItemButtonTemplate'))
	--local item = self:New(self:GetBlizzard(itemID) or CreateFrame('Button', format('CombuctorItem%d', itemID), nil, 'ContainerFrameItemButtonTemplate'))
	item:ClearAllPoints()
	item:Show()

	local border = item:CreateTexture(nil, 'OVERLAY')
	border:SetWidth(67); border:SetHeight(67)
	border:SetPoint('CENTER', item)
	border:SetTexture('Interface/Buttons/UI-ActionButton-Border')
	border:SetBlendMode('ADD')
	border:Hide()
	item.border = border

	item.cooldown = _G[item:GetName() .. 'Cooldown']
	item.cooldown:SetFrameLevel(item:GetFrameLevel() + 4)

	item:UnregisterAllEvents()
	item:SetScript('OnEvent', nil)
	item:SetScript('OnEnter', CombuctorItem.OnEnter)
	item:SetScript('OnHide', CombuctorItem.OnHide)
	item:SetScript('PostClick', CombuctorItem.PostClick)
	item.UpdateTooltip = nil

	itemID = itemID + 1

	return item
end

function CombuctorItem:GetBlizzard(id)
	local bag = ceil(id / MAX_CONTAINER_ITEMS)
	local slot = (id-1) % MAX_CONTAINER_ITEMS + 1
	local item = _G[format('ContainerFrame%dCombuctorItem%d', bag, slot)]

	if item then
		item:SetParent(nil)
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
	self:SetParent(DummyBag_Get(parent, bag))
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
	SetItemButtonTexture(self, texture)
	SetItemButtonCount(self, count)

	self:UpdateBorder(quality)
	self:UpdateCooldown()
end

--colors the item border based on the quality of the item.  hides it for common/poor items
function CombuctorItem:UpdateBorder(quality)
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

function CombuctorItem:UpdateLock(locked)
	local locked = select(3, GetContainerItemInfo(self:GetBag(), self:GetID()))
	SetItemButtonDesaturated(self, locked)
end

function CombuctorItem:UpdateCooldown()
	if (not self.cached) and self.hasItem then
		local start, duration, enable = GetContainerItemCooldown(self:GetBag(), self:GetID())
		CooldownFrame_SetTimer(self.cooldown, start, duration, enable)
	else
		CooldownFrame_SetTimer(self.cooldown, 0, 0, 0)
	end
end


--[[ Frame Events ]]--

function CombuctorItem:PostClick(button)
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
		if self.hasItem then
			self:AnchorTooltip()
			GameTooltip:SetHyperlink(BagnonDB:GetItemData(bag, slot, self:GetPlayer()))
			GameTooltip:Show()
		end
	else
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