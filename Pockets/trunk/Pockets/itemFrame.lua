--[[
	Combuctor.lua
		The combuctor frame
--]]

PocketFrame = Pockets:NewModule('ItemFrame')
PocketFrame.obj = PocketUtil:CreateWidgetClass('Frame')
PocketFrame.obj:Hide()
PocketFrame.obj:SetScript('OnUpdate', function(self) PocketFrame:LayoutFrames() self:Hide() end)

local listeners = {}
local currentPlayer = UnitName('player')
local MIN_COLS = 6


--[[
	Module Functions
--]]

function PocketFrame:Enable()
	self:RegisterEvent('BAG_UPDATE_COOLDOWN', 'UpdateSlotCooldowns')

	self:RegisterMessage('POCKETS_SLOT_ADD', 'UpdateSlot')
	self:RegisterMessage('POCKETS_SLOT_REMOVE', 'RemoveItem')
	self:RegisterMessage('POCKETS_SLOT_UPDATE', 'UpdateSlot')
	self:RegisterMessage('POCKETS_SLOT_UPDATE_LOCK', 'UpdateSlotLock')
end

function PocketFrame:UpdateSlot(msg, ...)
	for frame in pairs(listeners) do
		if frame:UpdateSlot(...) then
			frame.needsLayout = true
			self.obj:Show()
		end
	end
end

function PocketFrame:RemoveItem(msg, ...)
	for frame in pairs(listeners) do
		if frame:RemoveItem(...) then
			frame.needsLayout = true
			self.obj:Show()
		end
	end
end

function PocketFrame:UpdateSlotLock(msg, ...)
	for frame in pairs(listeners) do
		frame:UpdateSlotLock(...)
	end
end

function PocketFrame:UpdateSlotCooldowns(msg, ...)
	for frame in pairs(listeners) do
		frame:UpdateSlotCooldowns()
	end
end

function PocketFrame:LayoutFrames()
	for frame in pairs(listeners) do
		if frame.needsLayout then
			frame.needsLayout = nil
			frame:Layout()
		end
	end
end


--[[
	Usable Commands
--]]

function PocketFrame:Show(anchor)
	if not self.frame then
		self.frame = self.obj:Create()
	end

	local f = self.frame
	if f.anchor ~= anchor then
		if f.anchor then
			UIFrameFadeOut(f.anchor, 0.2, 1, 0.3)
		end
		f.anchor = anchor
		f:ClearAllPoints()
		f:SetPoint('BOTTOMLEFT', anchor, 'TOPLEFT')
	end
	f:SetRule(anchor.rule)
	f:Show()
end


--[[
	ItemFrame Widget
--]]

--local functions
local function ToIndex(bag, slot)
	return (bag<0 and bag*100 - slot) or (bag*100 + slot)
end

local function ToBag(index)
	return (index > 0 and floor(index/100)) or ceil(index/100)
end

local ItemFrame = PocketFrame.obj

function ItemFrame:Create()
	local f = self:New(CreateFrame('Frame', nil, UIParent))
	f.items = {}
	f.bags = {0, 1, 2, 3, 4}
	f.count = 0
	f.borderSize = 4

	f:SetClampedToScreen(true)
	f:SetMovable(true)

	f:SetScript('OnShow', self.OnShow)
	f:SetScript('OnHide', self.OnHide)
	f:SetScript('OnUpdate', self.OnUpdate)
	f:UpdateListening()

	return f
end

function ItemFrame:OnShow()
	UIFrameFadeIn(self, 0.2)
	self:UpdateListening()
	self:Regenerate()
end

function ItemFrame:OnHide()
	if self.anchor then
		UIFrameFadeOut(self.anchor, 0.2, 1, 0.3)
	end
	self:UpdateListening()
end

function ItemFrame:SetRule(rule)
	if rule ~= self.rule then
		self.rule = rule
		self:Regenerate()
	end
end


function ItemFrame:OnUpdate(elapsed)
	local nextUpdate = self.nextUpdate or 0.05
	if nextUpdate < 0 then
		self.nextUpdate = 0.05
		if not(MouseIsOver(self, 1, -1, -1, 1) or MouseIsOver(self.anchor, 1, -1, -1, 1)) then
			self:Hide()
		end
	else
		self.nextUpdate = nextUpdate - elapsed
	end
end

function ItemFrame:UpdateListening()
	listeners[self] = self:IsShown()
end


--[[ Item Updating ]]--

--returns true if the item matches the given filter, false othewise
function ItemFrame:HasItem(bag, slot, link)
	--check for the bag
	local hasBag = false
	for _,bagID in pairs(self.bags) do
		if bag == bagID then
			hasBag = true
			break
		end
	end
	if not hasBag then
		return false
	end

	--do filter checks
	local rule = self.rule
	if rule then
		local link = link or PocketUtil:GetItemLink(bag, slot)
		if link then
			local name, link, quality, level, ilvl, type, subType, stackCount, equipLoc = GetItemInfo(link)

			local name =  name:lower()
			if not(rule == name or name:find(rule)) then
				local type = type:lower()
				if not(rule == type or type:find(rule)) then
					local subType = subType:lower()
					if not(rule == subType or subType:find(rule)) then
						local equipLoc = getglobal(equipLoc)
						if equipLoc then
							equipLoc = equipLoc:lower()
							if not(rule == equipLoc or equipLoc:find(rule)) then
								return false
							end
						else
							return false
						end
					end
				end
			end
			return true
		end
		return false
	end
	return true
end

function ItemFrame:AddItem(bag, slot)
	local index = ToIndex(bag, slot)
	local item = self.items[index]

	if item then
		item:Update()
	else
		local item = PocketItem:Get()
		item:Set(self, bag, slot)
		self.items[index] = item
		self.count = self.count + 1
		return true
	end
end

function ItemFrame:RemoveItem(bag, slot)
	local index = ToIndex(bag, slot)
	local item = self.items[index]

	if item then
		item:Release()
		self.items[index] = nil
		self.count = self.count - 1
		return true
	end
end

function ItemFrame:UpdateSlot(bag, slot, link)
	if self:HasItem(bag, slot, link) then
		return self:AddItem(bag, slot)
	end
	return self:RemoveItem(bag, slot)
end

function ItemFrame:UpdateSlotLock(bag, slot)
	local item = self.items[ToIndex(bag, slot)]
	if item then
		item:UpdateLock()
	end
end

function ItemFrame:UpdateSlotCooldown(bag, slot)
	local item = self.items[ToIndex(bag, slot)]
	if item then
		item:UpdateCooldown()
	end
end

function ItemFrame:UpdateSlotCooldowns()
	for _,item in pairs(self.items) do
		item:UpdateCooldown()
	end
end


--[[ Mass Item Changes ]]--

--update all items and layout the frame
function ItemFrame:Regenerate()
	local changed = false

	for _,bag in pairs(self.bags) do
		for slot = 1, PocketUtil:GetBagSize(bag) do
			if self:UpdateSlot(bag, slot) then
				changed = true
			end
		end
	end

	if changed then
		self:Layout()
	end
end

--add all items in the givem bag
function ItemFrame:AddBag(bag, layout)
	local changed = false

	for slot = 1, PocketUtil:GetBagSize(bag) do
		if self:UpdateSlot(bag, slot) then
			changed = true
		end
	end

	if layout and changed then
		self:Layout()
	end
	return changed
end

--remove all items in the given bag
function ItemFrame:RemoveBag(bag, layout)
	local items = self.items
	local changed = false

	for index,item in pairs(items) do
		if bag == ToBag(index) then
			changed = true
			item:Release()
			items[index] = nil
			self.count = self.count - 1
		end
	end

	if(layout and changed) then
		self:Layout()
	end
	return changed
end

--remove all items from the frame
function ItemFrame:RemoveAllItems()
	local items = self.items
	local changed = true

	for i,item in pairs(items) do
		changed = true
		item:Release()
		items[i] = nil
	end
	self.count = 0

	return changed
end

--completely regenerate the frame
function ItemFrame:ReloadAllItems()
	if self:RemoveAllItems() and self:IsVisible() then
		self:Regenerate()
	end
end


--[[ Item Layout ]]--

function ItemFrame:Layout()
	local borderSize = self.borderSize or 0
	local width, height = self:LayoutItems(ceil(self.count/4), 1, borderSize/2, borderSize/2)

	self:SetWidth(width+borderSize); self:SetHeight(height+borderSize)
end

function ItemFrame:LayoutItems(cols, space, offX, offY)
	if next(self.items) then
		local itemSize = PocketItem.SIZE + space
		local items = self.items
		local i = 0

		for _,bag in ipairs(self.bags) do
			for slot = 1, PocketUtil:GetBagSize(bag) do
				local item = items[ToIndex(bag, slot)]
				if item then
					i = i + 1
					local row = mod(i-1, cols)
					local col = ceil(i/cols) - 1
					item:SetPoint("TOPLEFT", self, "TOPLEFT", itemSize*row + offX, -(itemSize*col + offY))
					item:Show()
				end
			end
		end
		return itemSize*min(cols, i) - space, itemSize*ceil(i/cols) - space
	end
	return 0, 0
end