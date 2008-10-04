--[[
	itemFrame.lua
		A thingy that displays items
--]]

local ItemFrame = Combuctor:NewClass('Button')
Combuctor.ItemFrame = ItemFrame

--local bindings
local FrameEvents = Combuctor:GetModule('ItemFrameEvents')
local InvData = Combuctor:GetModule('InventoryData')
local Item = Combuctor.Item


--InvDataity functions
local function ToIndex(bag, slot)
	return (bag<0 and bag*100 - slot) or (bag*100 + slot)
end

local function ToBag(index)
	return (index > 0 and floor(index/100)) or ceil(index/100)
end


--[[
	Constructor
--]]

function ItemFrame:New(parent)
	local f = self:Bind(CreateFrame('Button', nil, parent))
	f.items = {}
	f.bags = parent.sets.bags
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
	if self:IsVisible() then
		FrameEvents:Register(self)
	else
		FrameEvents:Unregister(self)
	end
end


--[[ Player Filtering ]]--

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
	if not hasBag then
		return false
	end

	--do filter checks
	local f = self.filter
	if next(f) then
		local player = self:GetPlayer()
		local link = link or InvData:GetItemLink(bag, slot, player)
		local bagType = InvData:GetBagType(bag, player)

		local name, quality, level, ilvl, type, subType, stackCount, equipLoc
		if link then
			name, link, quality, level, ilvl, type, subType, stackCount, equipLoc = GetItemInfo(link)
		end

		if f.quality and quality ~= f.quality then
			return false
		elseif f.rule and not f.rule(player, bagType, name, link, quality, level, ilvl, type, subType, stackCount, equipLoc) then
			return false
		elseif f.subRule and not f.subRule(player, bagType, name, link, quality, level, ilvl, type, subType, stackCount, equipLoc) then
			return false
		--'smart' text search: will attempt to match type, subtype, and equip locations in addition to names
		elseif f.name then
			if name then
				local name = name and name:lower()
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
			else
				return false
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
		local item = Item:Get()
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


--[[
	Mass Item Changes
--]]

--update all items and layout the frame
function ItemFrame:Regenerate()
	local changed = false
	local player = self:GetPlayer()

	for _,bag in pairs(self.bags) do
		for slot = 1, InvData:GetBagSize(bag, player) do
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
		if InvData:IsBankBag(bag) then
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

	for slot = 1, InvData:GetBagSize(bag, player) do
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
	local width, height = self:GetWidth(), self:GetHeight()
	local spacing = spacing or 2
	local count = self.count
	local size = 36 + spacing*2
	local cols = 0
	local scale, rows
	local maxScale = Combuctor:GetMaxItemScale()

	repeat
		cols = cols + 1
		scale = width / (size*cols)
		rows = floor(height / (size*scale))
	until(scale <= maxScale and cols*rows >= count)

	--layout the items
	local player = self:GetPlayer()
	local items = self.items
	local i = 0

	for _,bag in ipairs(self.bags) do
		for slot = 1, InvData:GetBagSize(bag, player) do
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


--[[
	Item Placement Functionality
--]]

--places the item in the first available slot in the current player's visible bags
--todo: make smarter
function ItemFrame:PlaceItem()
	if CursorHasItem() then
		local player = self:GetPlayer()
		for _,bag in ipairs(self.bags) do
			--this check is basically in case i decide, 'you know what would be awesome? bank and items in the same frame' again
			if not InvData:IsCachedBag(bag, player) then
				for slot = 1, GetContainerNumSlots(bag) do
					if not GetContainerItemLink(bag, slot) then
						PickupContainerItem(bag, slot)
					end
				end
			end
		end
	end
end