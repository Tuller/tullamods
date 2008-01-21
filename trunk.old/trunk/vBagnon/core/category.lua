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

BagnonCat = CreateFrame("Frame")
local Frame_mt = {__index = BagnonCat}

local currentPlayer = UnitName('player')
--local msg = function(msg) ChatFrame1:AddMessage(msg or 'nil', 0.5, 1, 1) end

local function SlotToIndex(bag, slot)
	if bag > 0 then
		return bag * 100 + slot
	else
		return bag * 100 - slot
	end
end

local function IndexToSlot(index)
	local slot = mod(abs(index), 100)
	if index > 0 then
		return (index - slot)/100, slot
	else
		return (index + slot)/100, slot
	end
end

local function CreateCategoryFrame(lastCreated)
	local name = "BagnonCat" .. lastCreated
	local frame = CreateFrame("Frame", name, UIParent)
	setmetatable(frame, Frame_mt)

	frame.paddingY = 6
	frame.items = {}

	return frame
end

--[[ Object Methods ]]--

function BagnonCat.Get()
	return TPool.Get('BagnonCat', CreateCategoryFrame)
end

--set's a frame to the given parameters
function BagnonCat:Set(parent, rule)
--	msg('set ' .. self.id)

	self.rule = rule
	
	Bagnon_AttachToFrame(self, parent)
	
	self:UpdateAllSlots()
end

--sticks the frame into the unused list, frees all items on the frame
function BagnonCat:Release()
--	msg('release ' .. self.id)
	
	self.rule = nil
	self:RemoveAllItems()
	TPool.Release(self, 'BagnonCat')
end

--[[ Item Functions ]]--

--adds a specific item to the frame
function BagnonCat:AddItem(bag, slot)
	local index = SlotToIndex(bag, slot)
	local items = self.items
	local item = items[index]

	if not item then
		item = BagnonItem.Get()
		item:Set(self, bag, slot)

		items[index] = item
		self.count = (self.count or 0) + 1
	end
	item:Update()
end

--releases a specific item from the frame
function BagnonCat:RemoveItem(bag, slot, update)
	local index = SlotToIndex(bag, slot)
	local item = self.items[index]

	if item then
		self.items[index] = nil
		item:Release()
		
		if self.count then
			self.count = self.count - 1
		end
		
		if update then
			self:GetParent().sizeChanged = true
		end
	end
end

--releases all items from the frame, and clears the frame's list of items
function BagnonCat:RemoveAllItems()
--	msg('remove all items ' .. self.id)
	
	if next(self.items) then
		for i, item in pairs(self.items) do
			self.items[i] = nil
			item:Release()
		end
		self:GetParent().sizeChanged = true	
	end
	
	self:SetWidth(0)
	self:SetHeight(0)
	self.count = nil
end


--[[ Bag Functions ]]--

function BagnonCat:AddBag(bag)
	local oldCount = self.count
	local rule = self.rule
	local player = self:GetPlayer()
	
	if rule then
		for slot = 1, Bagnon_GetSize(bag, player) do
			if rule(Bagnon_GetItemLink(player, bag, slot), bag) then
				self:AddItem(bag, slot)
			end
		end
	end

	if self.count ~= oldCount then
		self:GetParent().sizeChanged = true
	end
end

function BagnonCat:RemoveBag(bag)
	for i in pairs(self.items) do
		local iBag, iSlot = IndexToSlot(i)
		if iBag == bag then
			self:RemoveItem(iBag, iSlot)
		end
	end

	if self.count ~= oldCount then
		self:GetParent().sizeChanged = true
	end
end

--[[ Update Functions ]]--

function BagnonCat:UpdateSlot(bag, slot, itemLink)
	local oldCount = self.count
	local rule = self.rule

	if self:GetParent():HasBag(bag) and rule and rule(itemLink, bag) then
		self:AddItem(bag, slot)
	else
		self:RemoveItem(bag, slot)
	end

	if self.count ~= oldCount then
		self:GetParent().sizeChanged = true
	end
end

--cycles through all possible slots
function BagnonCat:UpdateAllSlots()
--	msg('update all slots ' .. self.id)
	
	local rule = self.rule
	local oldCount = self.count
	local player = self:GetPlayer()

	for _, bag in ipairs(self:GetParent():GetBags()) do
		for slot = 1, Bagnon_GetSize(bag, player) do
			if rule and rule(Bagnon_GetItemLink(player, bag, slot), bag) then
				self:AddItem(bag, slot)
			else
				self:RemoveItem(bag, slot)
			end
		end
	end

	if self.count ~= oldCount then
		self:GetParent().sizeChanged = true
	end
end

function BagnonCat:UpdateLock(bag, slot, locked)
	local item = self.items[SlotToIndex(bag, slot)]
	if item then
		item:UpdateLock(locked)
	end
end

function BagnonCat:UpdateBorders()
	for _, item in pairs(self.items) do
		item:UpdateBorder()
	end
end

--[[ Highlighting ]]--

function BagnonCat:HighlightRule(rule, highlight)
	if highlight and rule then
		local player = self:GetPlayer()
	
		for _, item in pairs(self.items) do
			local bag = item:GetParent():GetID()
			local slot = item:GetID()

			if rule(Bagnon_GetItemLink(player, bag, slot), bag) then
				item:Unfade(true)
			else
				item:Fade()
			end
		end
	else
		for _, item in pairs(self.items) do
			item:Unfade()
		end
	end
end

function BagnonCat:HighlightBag(bag, highlight)
	if highlight then
		for _, item in pairs(self.items) do
			if item:GetParent():GetID() == bag then
				item:Unfade(true)
			else
				item:Fade()
			end
		end
	else
		for _, item in pairs(self.items) do
			item:Unfade()
		end
	end
end

--[[ Search ]]

function BagnonCat:UpdateSearch()
	for _, item in pairs(self.items) do
		item:UpdateSearch()
	end
end

--[[ Layout ]]--

function BagnonCat:Layout()
--	msg('layout ' .. self.id)

	local columns, spacing = self:GetParent():GetLayout()
	local itemSize = (BagnonItem.SIZE + spacing*2)
	local offset = spacing / 2
	local i = 0
	local items = self.items
	local player = self:GetPlayer()

	for _, bag in ipairs(self:GetParent():GetBags()) do
		for slot = 1, Bagnon_GetSize(bag, player) do
			local item = items[SlotToIndex(bag, slot)]
			if item then
				i = i + 1
				local row = mod(i - 1, columns)
				local col = ceil(i / columns) - 1
				item:SetPoint("TOPLEFT", self, "TOPLEFT", itemSize * row + offset, -itemSize * col - offset - (self.paddingY or 0))
			end
		end
	end

	if i > 0 then
		self:SetWidth(itemSize * math.min(columns, i) - spacing)
		self:SetHeight(itemSize * ceil(i / columns) - spacing + (self.paddingY or 0))
	else
		self:SetWidth(0); self:SetHeight(0)
	end
end

function BagnonCat:GetPlayer()
	return self:GetParent():GetPlayer()
end