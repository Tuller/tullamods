--[[
	Combuctor.lua
		The combuctor frame
--]]

CombuctorItemFrame = Combuctor:NewModule('ItemFrame')
CombuctorItemFrame.obj = CombuctorUtil:CreateWidgetClass('Button')
CombuctorItemFrame.obj:Hide()
CombuctorItemFrame.obj:SetScript('OnUpdate', function(self) CombuctorItemFrame:LayoutFrames() self:Hide() end)

local listeners = {}
local currentPlayer = UnitName('player')
local MIN_COLS = 6


--[[
	Module Functions
--]]

function CombuctorItemFrame:OnEnable()
	self:RegisterEvent('BAG_UPDATE_COOLDOWN', 'UpdateSlotCooldowns')

	self:RegisterMessage('COMBUCTOR_SLOT_ADD', 'UpdateSlot')
	self:RegisterMessage('COMBUCTOR_SLOT_REMOVE', 'RemoveItem')
	self:RegisterMessage('COMBUCTOR_SLOT_UPDATE', 'UpdateSlot')
	self:RegisterMessage('COMBUCTOR_SLOT_UPDATE_LOCK', 'UpdateSlotLock')

	self:RegisterMessage('COMBUCTOR_BANK_OPENED', 'UpdateBankFrames')
	self:RegisterMessage('COMBUCTOR_BANK_CLOSED', 'UpdateBankFrames')
end

function CombuctorItemFrame:Create(parent)
	return self.obj:Create(parent)
end

function CombuctorItemFrame:UpdateSlot(msg, ...)
	for frame in pairs(listeners) do
		if frame:GetPlayer() == currentPlayer then
			if frame:UpdateSlot(...) then
				frame.needsLayout = true
				self.obj:Show()
			end
		end
	end
end

function CombuctorItemFrame:RemoveItem(msg, ...)
	for frame in pairs(listeners) do
		if frame:GetPlayer() == currentPlayer then
			if frame:RemoveItem(...) then
				frame.needsLayout = true
				self.obj:Show()
			end
		end
	end
end

function CombuctorItemFrame:UpdateSlotLock(msg, ...)
	for frame in pairs(listeners) do
		if frame:GetPlayer() == currentPlayer then
			frame:UpdateSlotLock(...)
		end
	end
end

function CombuctorItemFrame:UpdateSlotCooldowns(msg, ...)
	for frame in pairs(listeners) do
		if frame:GetPlayer() == currentPlayer then
			frame:UpdateSlotCooldowns()
		end
	end
end

function CombuctorItemFrame:UpdateBankFrames()
	for frame in pairs(listeners) do
		if frame.isBank then
			frame:Regenerate()
		end
	end
end

function CombuctorItemFrame:LayoutFrames()
	for frame in pairs(listeners) do
		if frame.needsLayout then
			frame.needsLayout = nil
			frame:Layout()
		end
	end
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

local ItemFrame = CombuctorItemFrame.obj

function ItemFrame:Create(parent)
	local f = self:New()
	f:SetParent(parent)
	f.items = {}
	f.bags = {}
	f.filter = parent.filter
	f.count = 0

	f:RegisterForClicks('anyUp')
	f:SetScript('OnShow', self.OnShow)
	f:SetScript('OnHide', self.UpdateListening)
	f:SetScript('OnClick', self.PlaceItem)
	f:UpdateListening()

	return f
end

function ItemFrame:OnShow()
	self:UpdateListening()
	self:Regenerate()
end

function ItemFrame:UpdateListening()
	listeners[self] = self:IsVisible()
end


--[[ Player Selection ]]--

function ItemFrame:SetPlayer(player)
	self.player = player
	self:ReloadAllItems()
end

function ItemFrame:GetPlayer()
	return self.player or currentPlayer
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
	if not hasBag then return false end

	--do filter checks
	local f = self.filter
	if next(f) then
		local link = link or CombuctorUtil:GetItemLink(bag, slot, self:GetPlayer())
		if not link then return false end

		local name, _, quality, _, level, type, subType, _, equipLoc = GetItemInfo(link)
		if f.quality and quality ~= f.quality then
			return false
		elseif f.minLevel and level < f.minLevel then
			return false
		elseif f.maxLevel and level > f.maxLevel then
			return false
		elseif f.type and type ~= f.type then
			return false
		elseif f.subType and subType ~= f.subType then
			return false
		elseif f.equipLoc and equipLoc ~= f.equipLoc then
			return false
		elseif f.name then
			--smart text search: will attempt to match type, subtype, and equip locations in addition to names
			local name = name:lower()
			if not(f.name == name or name:find(f.name)) then
				local type = type:lower()
				if not(f.name == type or type:find(f.name)) then
					local subType = subType:lower()
					if not(f.name == subType or subType:find(f.name)) then
						local equipLoc = getglobal(equipLoc)
						if equipLoc then
							equipLoc = equipLoc:lower()
							if not(f.name == equipLoc or equipLoc:find(f.name)) then
								return false
							end
						else
							return false
						end
					end
				end
			end
		end
	end
	return true
end

function ItemFrame:AddItem(bag, slot)
	local index = ToIndex(bag, slot)
	local item = self.items[index]

	if item then
		item:Update()
		item:Highlight(self.highlightBag == bag)
	else
		local item = CombuctorItem:Get()
		item:Set(self, bag, slot)
		item:Highlight(self.highlightBag == bag)

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
	local player = self:GetPlayer()

	for _,bag in pairs(self.bags) do
		for slot = 1, CombuctorUtil:GetBagSize(bag, player) do
			if self:UpdateSlot(bag, slot) then
				changed = true
			end
		end
	end

	if changed then
		self:Layout()
	end
end

function ItemFrame:SetBags(newBags)
	local visible = self:IsVisible()
	local bags = self.bags
	local changed = false

	--go through newbags and determine if we have bank slots or not
	self.isBank = false
	for _,bag in pairs(newBags) do
		if CombuctorUtil:IsBankBag(bag) then
			self.isBank = true
			break
		end
	end

	--go through all bags in newBags, inserting and removing when necessary
	--requires that both bag sets be sorted
	local i = 1
	repeat
		local bag, newBag = bags[i], newBags[i]
		if bag then
			if bag < newBag then
				table.remove(bags, i)
				if self:RemoveBag(bag) then
					changed = true
				end
			else
				if bag > newBag then
					table.insert(bags, i, newBag)
					if visible and self:AddBag(newBag) then
						changed = true
					end
				end
				i = i + 1
			end
		else
			bags[i] = newBag
			if visible and self:AddBag(newBag) then
				changed = true
			end
			i = i + 1
		end
	until i > #newBags

	--remove any extra bags from newBags
	local size = #bags
	for i = #newBags + 1, size do
		if self:RemoveBag(bags[i]) then
			changed = true
		end
		bags[i] = nil
	end

	--layout the frame if we're shown and the bag set changed
	if visible and changed then
		self:Layout()
	end
end

--add all items in the givem bag
function ItemFrame:AddBag(bag, layout)
	local player = self:GetPlayer()
	local changed = false

	for slot = 1, CombuctorUtil:GetBagSize(bag, player) do
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

--layout all the item buttons, scaling ot fit inside the fram
--todo: dividers for bags v bank
function ItemFrame:Layout(spacing)
	--figure out the layout
	local width, height = self:GetWidth(), self:GetHeight()
	local spacing = spacing or 2
	local count = self.count
	local size = 36 + spacing*2
	local cols = (self:GetParent().isBank and 10) or 6 - 1
	local scale, rows

	repeat
		cols = cols + 1
		scale = width / (size*cols)
		rows = floor(height / (size*scale))
	until(cols*rows >= count)

	--layout the items
	local player = self:GetPlayer()
	local items = self.items
	local i = 0

	for _,bag in ipairs(self.bags) do
		for slot = 1, CombuctorUtil:GetBagSize(bag, player) do
			local item = items[ToIndex(bag, slot)]
			if item then
				i = i + 1
				local row = mod(i-1,cols)
				local col = ceil(i/cols)-1
				item:ClearAllPoints()
				item:SetScale(scale)
				item:SetPoint('TOPLEFT', self, 'TOPLEFT', size*row + spacing, -(size*col + spacing))
				item:Show()
			end
		end
	end
end


--[[ Item Slot Highlighting ]]--

--highlights an item if it belongs to the selected bag
function ItemFrame:HighlightBag(bag)
	self.highlightBag = bag
	for _,item in pairs(self.items) do
		item:Highlight(item:GetBag() == bag)
	end
end


--[[ Item Placement Functions ]]--

--places the item in the first available slot in the current player's visible bags\
--TODO: make this work on the tabs, too
function ItemFrame:PlaceItem()
	if CursorHasItem() then
		local player = self:GetPlayer()
		for _,bag in ipairs(self.bags) do
			if not CombuctorUtil:IsCachedBag(bag, player) then
				for slot = 1, GetContainerNumSlots(bag) do
					if not GetContainerItemLink(bag, slot) then
						PickupContainerItem(bag, slot)
					end
				end
			end
		end
	end
end