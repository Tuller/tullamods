--[[
	BagnonCat
		Category frames for Bagnon windows

		A category frame is a frame that contains a set if item buttons
		defined by a specific rule

		Category frames have the following:
			a rule (nil for all items)
			a list of items
			a title

		BagnonCat.Get() should be used whenever a category frame is needed
--]]

local function msg(message)
	ChatFrame1:AddMessage(message or 'nil', 0.7, 0.5, 1)
end

BagnonCat = CreateFrame('Frame')
local Frame_mt = {__index = BagnonCat}

local ITEM_SIZE = BagnonItem.SIZE

local function ToIndex(bag, slot)
	if bag > 0 then
		return bag * 100 + slot
	else
		return bag * 100 - slot
	end
end

local function ToSlot(index)
	local slot = mod(abs(index), 100)
	if index > 0 then
		return (index - slot)/100, slot
	else
		return (index + slot)/100, slot
	end
end

local function Frame_Create(id)
	local frame = CreateFrame('Frame', format('BagnonCat%d', id), UIParent)
	setmetatable(frame, Frame_mt)

	frame.paddingY = 6
	frame.count = 0
	frame.items = {}
	
	--msg('Frame_Create ' .. id)

	return frame
end


--[[ Object Methods ]]--

function BagnonCat.Get()
	--msg('Get')
	return TPool.Get('BagnonCat', Frame_Create)
end

--set's a frame to the given parameters
function BagnonCat:Set(parent)
	--msg(format('Set %s, %s', self:GetName(), parent:GetName()))
	BagnonLib.Attach(self, parent)
	self:UpdateAllItems()
end

--sticks the frame into the unused list, frees all items on the frame
function BagnonCat:Release()
	--msg('Release ' .. self:GetName())
	self:GetParent().sizeChanged = true
	self:RemoveAllItems()
	TPool.Release(self, 'BagnonCat')
end


--[[ Item Functions ]]--

--adds a specific item to the frame
function BagnonCat:AddItem(bag, slot)
	local index = ToIndex(bag, slot)
	local items = self.items
	local item = items[index]

	if not item then
		item = BagnonItem.Get(self, bag, slot)
		items[index] = item
		self.count = self.count + 1
	end
	item:Update()
	item:UpdateCooldown()
end

--releases a specific item from the frame
function BagnonCat:RemoveItem(bag, slot, update)
	local index = ToIndex(bag, slot)
	local item = self.items[index]

	if item then
		self.items[index] = nil
		item:Release()
		self.count = self.count - 1
	end
end

--releases all items from the frame, and clears the frame's list of items
function BagnonCat:RemoveAllItems()
	--msg(format('Remove All Items %s', self:GetName()))
	local count = self.count

	for i, item in pairs(self.items) do
		self.items[i] = nil
		item:Release()
		self.count = self.count - 1
	end

	if self.count ~= count then
		self:GetParent().sizeChanged = true
	end
end


--[[ Bag Functions ]]--

--adds all items of the given bag to the frame
function BagnonCat:AddBag(bag)
	--msg(format('Add Bag %s, %s', self:GetName(), bag))
	
	local count = self.count
	local player = self:GetParent():GetPlayer()

	local size = BagnonLib.GetBagSize(bag, player)
	for slot = 1, size do
		self:AddItem(bag, slot)
	end

	if self.count ~= count then
		self:GetParent().sizeChanged = true
	end
end

--removes all items of the given bag from the frame
function BagnonCat:RemoveBag(bag)
	--msg(format('Remove Bag %s, %s', self:GetName(), bag))
	
	local count = self.count

	for i in pairs(self.items) do
		local itemBag, itemSlot = ToSlot(i)
		if itemBag == bag then
			self:RemoveItem(itemBag, itemSlot)
		end
	end

	if self.count ~= count then
		self:GetParent().sizeChanged = true
	end
end

function BagnonCat:UpdateBag(bag)
	local size = BagnonLib.GetBagSize(bag, self:GetParent():GetPlayer())
	for slot = 1, size do
		self:AddItem(bag, slot)
	end
end


--[[ Update Functions ]]--

--updates the given item slot
function BagnonCat:UpdateItem(bag, slot, link)
	--msg(format('Update Item %s, %s, %s, %s', self:GetName(), bag, slot, link or 'empty'))
	
	local count = self.count

	if self:GetParent():BagIsVisible(bag) then
		self:AddItem(bag, slot)
	else
		self:RemoveItem(bag, slot)
	end

	if self.count ~= count then
		self:GetParent().sizeChanged = true
	end
end

--updates all item slots of all visible bags
function BagnonCat:UpdateAllItems()
	--msg(format('Update All Items %s', self:GetName()))
	
	local count = self.count
	local player = self:GetParent():GetPlayer()
	local bags = self:GetParent():GetVisibleBags()

	for _, bag in ipairs(bags) do
		local size = BagnonLib.GetBagSize(bag, player)
		for slot = 1,  size do
			self:AddItem(bag, slot)
		end
	end

	if self.count ~= count then
		self:GetParent().sizeChanged = true
	end
end

function BagnonCat:UpdateLock(bag, slot, locked)
	--msg(format('Update Lock %s, %s, %s, %s', self:GetName(), bag, slot, locked or 'unlock'))
	
	local item = self.items[ToIndex(bag, slot)]
	if item then
		item:UpdateLock(locked)
	end
end

function BagnonCat:UpdateCooldown(bag, slot)
	local item = self.items[ToIndex(bag, slot)]
	if item then
		item:UpdateCooldown()
	end
end


--[[ Layout ]]--

--lays out all item slots, based on the parent frame's column and spacing settings
function BagnonCat:Layout()
	--msg(format('Layout %s', self:GetName()))

	if not next(self.items) then
		--msg('No Items')
		self:SetWidth(0); self:SetHeight(0)
		return
	end

	local columns, spacing = self:GetParent():GetLayout()
	local itemSize = ITEM_SIZE + spacing*2
	local offset = spacing / 2
	local items = self.items
	local player = self:GetParent():GetPlayer()
	local bags = self:GetParent():GetVisibleBags()
	local paddingY = self.paddingY or 0

	local i = 0
	for _,bag in ipairs(bags) do
		local size = BagnonLib.GetBagSize(bag, player)
		for slot = 1, size do
			local item = items[ToIndex(bag, slot)]
			if item then
				i = i + 1
				local row = mod(i - 1, columns)
				local col = ceil(i / columns) - 1
				item:SetPoint('TOPLEFT', self, 'TOPLEFT', itemSize * row + offset, -(itemSize * col + offset + paddingY))
			end
		end
	end

	self:SetWidth(itemSize * min(columns, i) - spacing)
	self:SetHeight(itemSize * ceil(i / columns) - spacing + paddingY)
end