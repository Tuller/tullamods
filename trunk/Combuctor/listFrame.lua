--[[
	listFrame.lua
		A combuctor list view
--]]

CombuctorListFrame = Combuctor:NewModule('Combuctor-ListFrame')
CombuctorListFrame.obj = CombuctorUtil:CreateWidgetClass('Button')
CombuctorListFrame.obj:Hide()
CombuctorListFrame.obj:SetScript('OnUpdate', function(self) CombuctorListFrame:UpdateNeededSlots() self:Hide() end)


--[[
	Module Functions
--]]

local listeners = {}
local slotsToUpdate = {}
local currentPlayer = UnitName('player')

function CombuctorListFrame:Enable()
	self:RegisterMessage('COMBUCTOR_SLOT_ADD', 'OnSlotUpdate')
	self:RegisterMessage('COMBUCTOR_SLOT_REMOVE', 'OnSlotUpdate')
	self:RegisterMessage('COMBUCTOR_SLOT_UPDATE', 'OnSlotUpdate')
	self:RegisterMessage('COMBUCTOR_BANK_OPENED', 'UpdateBankFrames')
	self:RegisterMessage('COMBUCTOR_BANK_CLOSED', 'UpdateBankFrames')
end

function CombuctorListFrame:Create(...)
	return self.obj:Create(...)
end

--register the bag slot as needing an update
function CombuctorListFrame:OnSlotUpdate(msg, bag, slot)
	self:Print(msg)
	if not slotsToUpdate[bag] then
		slotsToUpdate[bag] = {[slot] = true}
	else
		slotsToUpdate[bag][slot] = true
	end
	self.obj:Show()
end

function CombuctorListFrame:UpdateBankFrames()
	for frame in pairs(listeners) do
		if frame.isBank then
			frame:Regenerate()
		end
	end
end

function CombuctorListFrame:UpdateNeededSlots()
	self:Print('UpdateNeededSlots')

	for frame in pairs(listeners) do
		local changed = false
		for bag,slots in pairs(slotsToUpdate) do
			for slot in pairs(slots) do
				if frame:UpdateSlot(bag, slot) then
					changed = true
				end
			end
		end
		if changed then
			frame:Layout()
		end
	end

	for bag,slots in pairs(slotsToUpdate) do
		for slot in pairs(slots) do
			info[slot] = nil
		end
	end
end


--[[
	List Frame Object
--]]

local BUTTON_HEIGHT = 20
local ITEM_HEIGHT = 15
local NUM_SHOWN = 17

--utility functions
local function ToIndex(bag, slot)
	return (bag<0 and bag*100 - slot) or (bag*100 + slot)
end

local function ToSlot(index)
	local sign = index > 0 and 1 or -1
	local index = abs(index)
	local bag = floor(index/100)
	local slot = index % 100

	return bag*sign, slot
end

local function ToShortLink(link)
	if link then
		local a,b,c,d,e,f,g = link:match('(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):%-?%d+')
		if(b == '0' and b == c and c == d and d == e and e == f and f == g) then
			return a
		end
		return format('item:%s:%s:%s:%s:%s:%s:%s:0', a, b, c, d, e, f, g)
	end
end

local ListFrame = CombuctorListFrame.obj

function ListFrame:Create(parent)
	local f = self:New(CreateFrame('Button', parent:GetName() .. 'ListFrame', parent))
	f.items = {}
	f.bags = {}
	f.filter = {}
	f.displayList = {}
	f.buttons = {}

	f.dummyItem = f:CreateDummyItem()

	for i = 1, NUM_SHOWN do
		f:CreateButton(i)
	end

	f.scroll = CreateFrame('ScrollFrame',  f:GetName() .. 'Scroll', f, 'FauxScrollFrameTemplate')
	f.scroll:SetPoint('TOPLEFT')
	f.scroll:SetPoint('BOTTOMRIGHT', 0, 2)
	f.scroll:SetScript('OnShow', function() f:OnScrollShow() end)
	f.scroll:SetScript('OnHide', function() f:OnScrollHide() end)
	f.scroll:SetScript('OnVerticalScroll', function() FauxScrollFrame_OnVerticalScroll(ITEM_HEIGHT, function() f:Layout() end) end)

	f:RegisterForClicks('anyUp')
	f:SetScript('OnShow', self.OnShow)
	f:SetScript('OnHide', self.UpdateListening)
	f:SetScript('OnClick', self.PlaceItem)
	f:UpdateListening()

	return f
end

function ListFrame:OnShow()
	self:UpdateListening()
	self:Regenerate()
end

function ListFrame:UpdateListening()
	listeners[self] = self:IsVisible()
end

function ListFrame:OnScrollShow()
	self.buttons[1]:SetPoint('TOPRIGHT')
end

function ListFrame:OnScrollHide()
	self.buttons[1]:SetPoint('TOPRIGHT', 20, 0)
end


--[[ Item Updating ]]--

--returns true if the item matches the given filter, false othewise
function ListFrame:HasItem(bag, slot, link)
	if not link then return false end

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

function ListFrame:AddItem(bag, slot, link)
	local index = ToIndex(bag, slot)
	local link = ToShortLink(link)
	local count = CombuctorUtil:GetItemCount(bag, slot, self:GetPlayer())

	local slots = self.items[link]
	if slots then
		slots[index] = count
		self:UpdateLink(link)
	else
		self.items[link] = {[index] = count}
		self:AddLink(link)
		return true
	end
end

function ListFrame:RemoveItem(bag, slot, prevLink)
	if prevLink then
		local index = ToIndex(bag, slot)
		local link = ToShortLink(prevLink)
		local count = CombuctorUtil:GetItemCount(bag, slot, self:GetPlayer())

		local items = self.items[link]
		if items then
			items[index] = nil
			if next(items) then
				self:UpdateLink(link)
			else
				self:RemoveLink(link)
				return true
			end
		end
	end
end

function ListFrame:UpdateSlot(bag, slot, link)
	local link = link or CombuctorUtil:GetItemLink(bag, slot, self:GetPlayer())
	if self:HasItem(bag, slot, link) then
		return self:AddItem(bag, slot, link)
	end
	return self:RemoveItem(bag, slot, link)
end


--[[ Link Updating ]]--

function ListFrame:AddLink(link)
	tinsert(self.displayList, link)
end

function ListFrame:RemoveLink(link)
	self.items[link] = nil

	for i,v in pairs(self.displayList) do
		if v == link then
			tremove(self.displayList, i)
			break
		end
	end
end

function ListFrame:UpdateLink(link)
	for _,button in pairs(self.buttons) do
		if button.link == link then
			button:SetCount(self:GetLinkCount(link))
		end
	end
end

function ListFrame:GetLinkCount(link)
	local total = 0
	local slots = self.items[link]
	if slots then
		for _,count in pairs(slots) do
			total = total + count
		end
	end
	return total
end


--[[ Mass Item Changes ]]--

--update all items and layout the frame
function ListFrame:Regenerate()
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
		self:Layout(true)
	end
end

function ListFrame:SetBags(newBags)
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
		self:Layout(true)
	end
end

--add all items in the givem bag
function ListFrame:AddBag(bag)
	local player = self:GetPlayer()
	local changed = false

	for slot = 1, CombuctorUtil:GetBagSize(bag, player) do
		if self:UpdateSlot(bag, slot) then
			changed = true
		end
	end
	return changed
end

--remove all items in the given bag
function ListFrame:RemoveBag(bag)
	local changed = false
	local player = self:GetPlayer()
	for slot = 1, CombuctorUtil:GetBagSize(bag, player) do
		if self:RemoveItem(bag, slot, CombuctorUtil:GetItemLink(bag, slot, player)) then
			changed = true
		end
	end
	return changed
end

--remove all items from the frame
function ListFrame:RemoveAllItems()
	if next(self.items) then
		self.items = {}
		self.displayList = {}
		return true
	end
end

--completely regenerate the frame
function ListFrame:ReloadAllItems()
	if self:RemoveAllItems() and self:IsVisible() then
		self:Regenerate()
	end
end


--[[ Filtering Code ]]--

function ListFrame:SetFilter(key, value)
	if self.filter[key] ~= value then
		self.filter[key] = value
		self:Regenerate()
	end
end

--reset all filters
function ListFrame:ResetFilters()
	local f = self.filter
	if next(f) then
		for k in pairs(f) do
			f[k] = nil
		end
		self:Regenerate()
	end
end


--[[ Player Selection ]]--

function ListFrame:SetPlayer(player)
	self.player = player
	self:ReloadAllItems()
end

function ListFrame:GetPlayer()
	return self.player or currentPlayer
end


--[[ Item Layout ]]--

--sorts by quality, then name
local function Ludwig_Sort(id1, id2)
	local name1, _, quality1 = GetItemInfo(id1)
	local name2, _, quality2 = GetItemInfo(id2)

	if quality1 ~= quality2 then
		return quality1 > quality2
	end
	return name1 < name2
end

function ListFrame:Layout(shouldSort)
	local displayList = self.displayList
	if shouldSort then
		table.sort(displayList, Ludwig_Sort)
	end

	local size = #displayList
	FauxScrollFrame_Update(self.scroll, size, NUM_SHOWN, ITEM_HEIGHT)

	local offset = self.scroll.offset
	for i,button in ipairs(self.buttons) do
		local index = i + offset
		if index > size then
			button:Hide()
		else
			local link = displayList[index]
			local name,_,quality,_,_,_,_,_,_,icon = GetItemInfo(link)
			local r,g,b = GetItemQualityColor(quality)
			button:SetCount(self:GetLinkCount(link))
			button:SetText(name)
			button:SetTextColor(r, g, b)
			button.icon:SetTexture(icon)
			button.link = link
			button:Show()
		end
	end
end


--[[ Item Placement Functions ]]--

--places the item in the first available slot in the current player's visible bags\
--TODO: make this work on the tabs, too
function ListFrame:PlaceItem()
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

local function ListButton_OnEnter(self)
	local parent = self:GetParent()
	local bag, slot = ToSlot(next(parent.items[self.link]))
	parent:SetID(bag)

	local dummyItem = self:GetParent().dummyItem
	dummyItem:SetID(slot)
	dummyItem:SetAllPoints(self)
	dummyItem:Show()
end

local function ListButton_SetCount(self, count)
	if count > 1 then
		self.count:SetText(count)
		self.count:Show()
	else
		self.count:Hide()
	end
end

function ListFrame:CreateButton(id)
	local button = CreateFrame('Button', nil, self)
	button:SetHighlightTexture('Interface/QuestFrame/UI-QuestTitleHighlight')
	button:RegisterForClicks('anyUp')
	button:SetHeight(20)
	button.SetCount = ListButton_SetCount

	local icon = button:CreateTexture(nil, 'BACKGROUND')
	icon:SetWidth(20); icon:SetHeight(20)
	icon:SetPoint('LEFT', 6, 0)
	icon:SetTexCoord(0.09, 0.91, 0.09, 0.91)
	button.icon = icon

	local count = button:CreateFontString(nil, 'OVERLAY')
	count:SetPoint('RIGHT', 2, 0)
	count:SetFontObject('GameFontHighlight')
	count:SetJustifyH('RIGHT')
	button.count = count

	local text = button:CreateFontString()
	text:SetPoint('TOPLEFT', 28, 0)
	text:SetPoint('BOTTOMRIGHT', -28, 0)
	text:SetJustifyH('LEFT')
	text:SetFontObject('GameFontNormal')
	button:SetFontString(text)

	button:SetScript('OnEnter', ListButton_OnEnter)
	if id > 1 then
		button:SetPoint('TOPLEFT', self.buttons[id-1], 'BOTTOMLEFT')
		button:SetPoint('TOPRIGHT', self.buttons[id-1], 'BOTTOMRIGHT')
	else
		button:SetPoint('TOPLEFT')
	end
	self.buttons[id] = button

	return button
end

local function DummyItem_OnEnter(self)
	local parent = self:GetParent()
	local player = parent:GetPlayer()
	local bag = parent:GetID()
	local slot = self:GetID()

	if self:GetRight() >= (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end

	if CombuctorUtil:IsCachedBag(bag, player) then
		GameTooltip:SetHyperlink(CombuctorUtil:GetItemLink(bag, slot, player))
	else
		--boo for special case bank code
		if bag == BANK_CONTAINER then
			GameTooltip:SetInventoryItem('player', BankButtonIDToInvSlotID(slot))
		else
			ContainerFrameItemButton_OnEnter(self)
		end
	end
end

local function DummyItem_OnLeave(self)
	GameTooltip:Hide()
	self:Hide()
end

function ListFrame:CreateDummyItem()
	local dummy = CreateFrame('Button', self:GetName() .. 'DummyItem', self, 'ContainerFrameItemButtonTemplate')
	dummy:SetNormalTexture(nil); dummy:SetPushedTexture(nil)
	dummy:SetHighlightTexture('Interface/QuestFrame/UI-QuestTitleHighlight')
	dummy:SetToplevel(true)
	dummy:Hide()
	dummy:SetScript('OnEnter', DummyItem_OnEnter)
	dummy.UpdateTooltip = DummyItem_OnEnter
	dummy:SetScript('OnLeave', DummyItem_OnLeave)

	return dummy
end