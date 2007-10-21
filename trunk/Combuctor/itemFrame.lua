--[[
	Combuctor.lua
		The combuctor frame
--]]

CombuctorItemFrame = Combuctor:NewModule('Combuctor-ItemFrame')
CombuctorItemFrame.obj = CombuctorUtil:CreateWidgetClass('Button')
local listeners = {}
local currentPlayer = UnitName('player')

--[[
	Module Functions
--]]

function CombuctorItemFrame:Enable()
	self:RegisterMessage('COMBUCTOR_SLOT_ADD', 'UpdateSlot')
	self:RegisterMessage('COMBUCTOR_SLOT_REMOVE', 'RemoveItem')
	self:RegisterMessage('COMBUCTOR_SLOT_UPDATE', 'UpdateSlot')
	self:RegisterMessage('COMBUCTOR_SLOT_UPDATE_LOCK', 'UpdateSlotLock')
	self:RegisterMessage('COMBUCTOR_SLOT_UPDATE_COOLDOWN', 'UpdateSlotCooldown')

	self:RegisterMessage('COMBUCTOR_BANK_OPENED', 'UpdateBankFrames')
	self:RegisterMessage('COMBUCTOR_BANK_CLOSED', 'UpdateBankFrames')
end

function CombuctorItemFrame:Create(parent)
	return self.obj:Create(parent)
end

function CombuctorItemFrame:UpdateSlot(msg, ...)
	for frame in pairs(listeners) do
		if frame:UpdateSlot(...) then
			frame:Layout()
		end
	end
end

function CombuctorItemFrame:UpdateSlotLock(msg, ...)
	for frame in pairs(listeners) do
		frame:UpdateSlotLock(...)
	end
end

function CombuctorItemFrame:UpdateSlotCooldown(msg, ...)
	for frame in pairs(listeners) do
		frame:UpdateSlotCooldown(...)
	end
end

function CombuctorItemFrame:RemoveItem(msg, ...)
	for frame in pairs(listeners) do
		if frame:RemoveItem(...) then
			frame:Layout()
		end
	end
end

function CombuctorItemFrame:UpdateBankFrames()
	for frame in pairs(listeners) do
		if frame.isBank then
			frame:ReloadAllItems()
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
	f.filter = {}
	f.count = 0
	f:RegisterForClicks('anyUp')
	f:RegisterForDrag('LeftButton')

	f:SetScript('OnShow', self.OnShow)
	f:SetScript('OnClick', self.PlaceItem)
	f:SetScript('OnReceiveDrag', self.PlaceItem)
	f:UpdateEvents()

	return f
end

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

function ItemFrame:OnShow()
	self:UpdateEvents()
	self:Layout()
end

function ItemFrame:UpdateEvents()
	listeners[self] = (self:IsVisible() and self:GetPlayer() == UnitName('player'))
end

function ItemFrame:SetFilter(key, value)
	local prevValue = self.filter[key]
	if prevValue ~= value then
		self.filter[key] = value
		self:Regenerate()
	end
end

--reset all filters
function ItemFrame:Reset()
	local f = self.filter
	local changed
	for k in pairs(f) do
		if(f[k] ~= nil) then
			changed = true
			f[k] = nil
		end
	end

	if changed then
		self:Regenerate()
	end
end

function ItemFrame:SetPlayer(player)
	self.player = player
	self:ReloadAllItems()
	self:UpdateEvents()
end

function ItemFrame:GetPlayer()
	return self.player or currentPlayer
end


--[[ Item Updating ]]--

--returns true if the item matches the given filter, false othewise
function ItemFrame:HasItem(bag, slot, link)
	local f = self.filter
	if next(f) then
		local link = link or CombuctorUtil:GetItemLink(bag, slot, self:GetPlayer())
		if not link then
			return false
		end

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
			local name = name:lower()
			if not(f.name == name or name:find(f.name)) then
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
	else
		local item = CombuctorItem:Get()
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


--[[ Mass Item Changes ]]--

--update all items and layout the frame
function ItemFrame:Regenerate()
	local changed = false
	local player = self:GetPlayer()
	for _,bag in ipairs(self.bags) do
		for slot = 1, CombuctorUtil:GetBagSize(bag, player) do
			local altered = self:UpdateSlot(bag, slot)
			changed = changed or altered
		end
	end

	if changed then
		self:Layout()
	end
end

--set the display to use the given bag set, and remove any bags that are not in the new set
function ItemFrame:SetBags(newBags)
	local bags = self.bags
	if bags ~= newBags then
		self.bags = newBags
		self.isBank = nil

		for _,bag in pairs(self.bags) do
			if CombuctorUtil:IsBankBag(bag) then
				self.isBank = true
				break
			end
		end

		--remove any items from bags that are not in the new set
		local changed
		if bags then
			for _,i in pairs(bags) do
				local found = false
				for _,j in pairs(newBags) do
					if(i == j) then
						found = true
						break
					end
				end
				if not found then
					local altered = self:RemoveBag(i)
					changed = changed or altered
				end
			end
		end

		--add in any items from bags that were not in the old set
		if self:IsShown() then
			if not bags then
				self:Regenerate()
			else
				for _,i in pairs(newBags) do
					local found = false
					for _,j in pairs(bags) do
						if(i == j) then
							found = true
							break
						end
					end
					if not found then
						local altered = self:AddBag(i)
						changed = changed or altered
					end
				end

				if changed then
					self:Layout()
				end
			end
		end
	end
end

--add all items in the givem bag
function ItemFrame:AddBag(bag, layout)
	local player = self:GetPlayer()
	local changed = false

	for slot = 1, CombuctorUtil:GetBagSize(bag, player) do
		local added = self:UpdateSlot(bag, slot)
		changed = changed or added
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
			item:Release()
			items[index] = nil
			self.count = self.count - 1
			changed = true
		end
	end

	if(layout and changed) then
		self:Layout()
	end
	return changed
end

--remove bank items from the frame
function ItemFrame:RemoveBankItems()
	local items = self.items
	local changed = false

	for index,item in pairs(items) do
		if CombuctorUtil:IsBankBag(ToBag(index)) then
			item:Release()
			items[index] = nil
			self.count = self.count - 1
			changed = true
		end
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
	if self:RemoveAllItems() and self:IsShown() then
		self:Regenerate()
	end
end


--[[ Item Layout ]]--

--layout all the item buttons, scaling ot fit inside the fram
--todo: dividers for bags v bank
function ItemFrame:Layout(spacing)
	if not self:IsVisible() then return end

	--figure out the layout
	local width, height = self:GetWidth(), self:GetHeight()
	local spacing = spacing or 2
	local count = self.count
	local size = 37 + spacing*2
	local cols = 0
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


--[[
	Filtering
--]]


--[[ Reset ]]--

--reset all filters
function ItemFrame:Reset()
	local f = self.filter
	local changed
	for i in pairs(f) do
		if(f[i] ~= nil) then
			changed = true
			f[i] = nil
		end
	end

	if changed then
		self:Regenerate()
	end
end