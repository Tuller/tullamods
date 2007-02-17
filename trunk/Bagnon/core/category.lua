--[[
	BagnonCat
		Category frames for Bagnon windows

		A category frame is a frame that contains a set if item buttons
		defined by a specific rule

		Category frames have the following:
			a rule (nil for all items)
			a list of items

		BagnonCat.Get() should be used whenever a category frame is needed
--]]

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

	return frame
end


--[[ Object Methods ]]--

function BagnonCat.New(parent)
	local frame = TPool.Get('BagnonCat', Frame_Create)
	BagnonLib.Attach(frame, parent)
	
	return frame
end


--[[ Item Functions ]]--

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

function BagnonCat:RemoveItem(bag, slot)
	local index = ToIndex(bag, slot)
	local item = self.items[index]

	if item then
		self.items[index] = nil
		item:Release()
		self.count = self.count - 1
		self:GetParent().sizeChanged = true
	end
end

function BagnonCat:RemoveAllItems()
	local count = self.count

	for i, item in pairs(self.items) do
		self.items[i] = nil
		item:Release()
		self.count = self.count - 1
	end

	self:GetParent().sizeChanged = (self.count ~= count)
end


--[[ Bag Functions ]]--

function BagnonCat:AddBag(bag)
	local count = self.count
	local player = self:GetParent():GetPlayer()

	local size = BagnonLib.GetBagSize(bag, player)
	for slot = 1, size do
		self:AddItem(bag, slot)
	end

	self:GetParent().sizeChanged = (self.count ~= count)
end

function BagnonCat:RemoveBag(bag)
	local count = self.count

	for i in pairs(self.items) do
		local itemBag, itemSlot = ToSlot(i)
		if itemBag == bag then
			self:RemoveItem(itemBag, itemSlot)
		end
	end

	self:GetParent().sizeChanged = (self.count ~= count)
end

function BagnonCat:UpdateBag(bag)
	local size = BagnonLib.GetBagSize(bag, self:GetParent():GetPlayer())
	for slot = 1, size do
		self:AddItem(bag, slot)
	end
end


--[[ Update Functions ]]--

function BagnonCat:UpdateItem(bag, slot, link)
	local count = self.count

	if self:GetParent():BagIsVisible(bag) then
		self:AddItem(bag, slot)
	else
		self:RemoveItem(bag, slot)
	end

	self:GetParent().sizeChanged = (self.count ~= count)
end

function BagnonCat:UpdateAllItems()
	local count = self.count
	local player = self:GetParent():GetPlayer()
	local bags = self:GetParent():GetVisibleBags()

	for _, bag in ipairs(bags) do
		local size = BagnonLib.GetBagSize(bag, player)
		for slot = 1, size do
			self:AddItem(bag, slot)
		end
	end

	self:GetParent().sizeChanged = (self.count ~= count)
end

function BagnonCat:UpdateLock(bag, slot, locked)
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

function BagnonCat:Layout()
	if not next(self.items) then
		self:SetWidth(0); self:SetHeight(0); return
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