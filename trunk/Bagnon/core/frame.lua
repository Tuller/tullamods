--[[
	BagnonFrame
		A container frame for categories, tabs, bags, money, and purchasing bags

	Each frame contains its own list of slots, index by what bag and what slot it is in
	The index, bag slot 0 is used to store size information about each bag.
--]]


BagnonFrame = BagnonUtil:CreateWidgetClass('Frame')
local L = BAGNON_LOCALS
local DEFAULT_COLS = 8
local DEFAULT_SPACING = 1
local DEFAULT_STRATA = 'HIGH'
local ITEM_SIZE = BagnonItem.SIZE


--[[ TitleFrame Object ]]--

local TitleFrame = {}
do
	function TitleFrame:Create(parent)
		local title = CreateFrame('Button', nil, parent)

		local text = title:CreateFontString()
		text:SetAllPoints(title)
		text:SetJustifyH('LEFT')
		text:SetFontObject('GameFontNormal')
		title:SetFontString(text)

		title:SetHighlightTextColor(1, 1, 1)
		title:SetTextColor(1, 0.82, 0)
		title:RegisterForClicks('anyUp')

		title:SetScript('OnClick', self.OnClick)
		title:SetScript('OnDoubleClick', self.OnDoubleClick)
		title:SetScript('OnMouseUp', self.OnMouseUp)
		title:SetScript('OnMouseDown', self.OnMouseDown)
		title:SetScript('OnEnter', self.OnEnter)
		title:SetScript('OnLeave', self.OnLeave)
		
		return title
	end

	function TitleFrame:OnClick(button)
		if button == 'RightButton' then
			BagnonMenu:Show(self:GetParent())
		end
	end

	function TitleFrame:OnDoubleClick(button)
		if button == 'LeftButton' then
			BagnonSpot:Show(self:GetParent())
		end
	end

	function TitleFrame:OnMouseDown()
		if IsAltKeyDown() or not self:GetParent():IsLocked() then
			self.isMoving = true
			self:GetParent():StartMoving()
		end
	end

	function TitleFrame:OnMouseUp()
		if self.isMoving then
			self.isMoving = nil

			self:GetParent():StopMovingOrSizing()
			self:GetParent():SavePosition()
		end
	end

	function TitleFrame:OnEnter()
		if self:GetRight() > (GetScreenWidth() / 2) then
			GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
		else
			GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		end

		GameTooltip:SetText(self:GetText(), 1, 1, 1)
		GameTooltip:AddLine(L.TipShowMenu)
		GameTooltip:AddLine(L.TipShowSearch)
		GameTooltip:Show()
	end

	function TitleFrame:OnLeave()
		GameTooltip:Hide()
	end
end


--[[ Bagnon Frame Stuff ]]--

local function ToIndex(bag, slot)
	return (bag<0 and bag*100 - slot) or (bag*100 + slot)
end

local id = 0
function BagnonFrame:Create(name, sets, bags, isBank)
	local frame = self:New(CreateFrame('Frame', format('BagnonFrame%d', id), UIParent))
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)

	frame.slots = {}
	frame.showBags = sets.showBags
	frame.visibleBags = sets.bags
	frame.borderSize = 16
	frame.paddingY = 24
	frame.isBank = isBank

	frame:SetBackdrop{
	  bgFile = 'Interface/ChatFrame/ChatFrameBackground',
	  edgeFile = 'Interface/Tooltips/UI-Tooltip-Border',
	  edgeSize = 16,
	  tile = true, tileSize = 16,
	  insets = {left = 4, right = 4, top = 4, bottom = 4}
	}
	
	frame:LoadSettings(sets)
	frame:SetScript('OnShow', self.OnShow)
	frame:SetScript('OnHide', self.OnHide)
	frame:SetScript('OnEvent', self.OnEvent)

	local close = CreateFrame('Button', name .. 'Close', frame, 'UIPanelCloseButton')
	close:SetPoint('TOPRIGHT', 6 - frame.borderSize/2, 6 - frame.borderSize/2)

	if BagnonDB then
		local playerDropdown = CreateFrame('Button', name .. 'DropDown', frame, 'BagnonDBUIDropDownButton')
		playerDropdown:SetPoint('TOPLEFT', frame.borderSize/2 -2, -6)
	end

	frame.title = TitleFrame:Create(frame)
	if BagnonDB then
		frame.title:SetPoint('TOPLEFT', 26 + frame.borderSize/2, -10)
	else
		frame.title:SetPoint('TOPLEFT', 6 + frame.borderSize/2, -10)
	end
	frame.title:SetPoint('BOTTOMRIGHT', frame, 'TOPRIGHT', -24, -16 - frame.borderSize/2)
	frame:SetTitleText(name)

	frame.bagFrame = BagnonBagFrame:Create(frame, bags, frame.showBags)
	frame.moneyFrame = BagnonMoneyFrame:Create(frame)

	--load up the thing
	frame:UpdateEvents()
	frame:Regenerate()

	id = id + 1
	return frame
end


--[[ frame events ]]--

function BagnonFrame:OnEvent(event, bag)
	if event == 'BANKFRAME_OPENED' or event == 'BANKFRAME_CLOSED' then
		self:Regenerate()
	elseif self:GetPlayer() == UnitName('player') then
		if event == 'BAG_UPDATE' then
			self:OnBagUpdate(bag)
		elseif event == 'ITEM_LOCK_CHANGED' then
			self:UpdateLockedSlots()
		elseif event == 'BAG_UPDATE_COOLDOWN' then
			self:UpdateSlotsOnCooldown()
		elseif event == 'PLAYERBANKSLOTS_CHANGED' then
			self:OnBagUpdate(BANK_CONTAINER)
		end
	end
end

function BagnonFrame:UpdateEvents()
	if self:IsShown() then
		if self.isBank then
			self:RegisterEvent('PLAYERBANKSLOTS_CHANGED')
			self:RegisterEvent('BANKFRAME_OPENED')
			self:RegisterEvent('BANKFRAME_CLOSED')
		end
		self:RegisterEvent('BAG_UPDATE')
		self:RegisterEvent('ITEM_LOCK_CHANGED')
		self:RegisterEvent('BAG_UPDATE_COOLDOWN')
	else
		self:UnregisterAllEvents()
	end
end

function BagnonFrame:OnShow()
	self:UpdateEvents()
	self:Regenerate()
end

function BagnonFrame:OnHide()
	if BagnonMenu:GetAnchor() == self then
		BagnonMenu:Hide()
	end
	if BagnonSpot:GetAnchor() == self then
		BagnonSpot:Hide()
	end

	self:SetPlayer(UnitName('player'))
	self:UpdateEvents()
end


--[[ bag updating ]]--

function BagnonFrame:ShowBag(bag, enable)
	if enable then
		if not self:ShowingBag(bag) then
			local bags = self:GetVisibleBags()
			table.insert(bags, bag)
			self:SortBags()

			self:AddBag(bag, true)
		end
	else
		local index = self:ShowingBag(bag)
		if index then
			local bags = self:GetVisibleBags()
			table.remove(bags, index)
			self:SortBags()

			self:RemoveBag(bag)
		end
	end
end

function BagnonFrame:ShowingBag(bag)
	for i, visibleBag in pairs(self:GetVisibleBags()) do
		if visibleBag == bag then
			return i
		end
	end
end

function BagnonFrame:GetBags()
	return self.bags
end

function BagnonFrame:GetVisibleBags()
	return self.visibleBags
end


--[[ item updating ]]--

function BagnonFrame:AddItem(bag, slot)
	local item = BagnonItem:Create()
	item:Set(self, bag, slot)

	self.slots[ToIndex(bag, slot)] = item
end

function BagnonFrame:RemoveItem(bag, slot)
	local item = self.slots[ToIndex(bag, slot)]
	if item then
		self.slots[ToIndex(bag, slot)] = nil
		item:Release()
	end
end


--[[ Frame Updating ]]--

--add any added slots, removed any removed slots, update the rest of the slots held by the bag
function BagnonFrame:Regenerate()
	self.bagFrame:Update()

	local sizeChanged = false
	local slots = self.slots

	for _,bag in pairs(self:GetVisibleBags()) do
		local prevSize = slots[bag*100] or 0
		local size = BagnonUtil:GetBagSize(bag, self:GetPlayer())
		slots[bag*100] = size

		for slot = 1, min(prevSize, size) do
			self.slots[ToIndex(bag, slot)]:Update()
		end

		if size > prevSize then
			for slot = prevSize + 1, size do
				self:AddItem(bag, slot)
			end
			sizeChanged = true
		elseif size < prevSize then
			for slot = size + 1, prevSize do
				self:RemoveItem(bag, slot)
			end
			sizeChanged = true
		end
	end

	if sizeChanged then
		self:Layout()
	end
end

--add any added slots, removed any removed slots, update all the slots of the bag being updated
function BagnonFrame:OnBagUpdate(updatedBag)
	local sizeChanged = false
	local slots = self.slots

	for _, bag in pairs(self:GetVisibleBags()) do
		local prevSize = slots[bag*100] or 0
		local size = BagnonUtil:GetBagSize(bag, self:GetPlayer())
		slots[bag * 100] = size

		if bag == updatedBag then
			for slot = 1, min(prevSize, size) do
				local item = self.slots[ToIndex(bag, slot)]
				item:Update()
			end
		end

		if size > prevSize then
			for slot = prevSize + 1, size do
				self:AddItem(bag, slot)
			end
			sizeChanged = true
		elseif size < prevSize then
			for slot = size + 1, prevSize do
				self:RemoveItem(bag, slot)
			end
			sizeChanged = true
		end
	end

	if sizeChanged then
		self:Layout()
	end
end

function BagnonFrame:AddBag(bag)
	local prevSize = self.slots[bag*100] or 0
	local size = BagnonUtil:GetBagSize(bag, self:GetPlayer())
	self.slots[bag*100] = size

	for slot = 1, size do
		self:AddItem(bag, slot)
	end
	self:Layout()
end

function BagnonFrame:RemoveBag(bag)
	for slot = 1, BagnonUtil:GetBagSize(bag, self:GetPlayer()) do
		self:RemoveItem(bag, slot)
	end
	self:Layout()
end

function BagnonFrame:UpdateLockedSlots()
	for _,item in pairs(self.slots) do
		if not tonumber(item) then
			item:UpdateLock()
		end
	end
end

function BagnonFrame:UpdateSlotsOnCooldown()
	for _,item in pairs(self.slots) do
		if not tonumber(item) then
			item:UpdateLock()
		end
	end
end


--[[ spot searching ]]--

function BagnonFrame:UpdateSearch()
	for _, item in pairs(self.slots) do
		if not tonumber(item) then
			item:UpdateSearch()
		end
	end
end


--[[ cached data viewing ]]--

function BagnonFrame:SetPlayer(player)
	if player ~= self:GetPlayer() then
		self.player = player

		self:UpdateTitleText()
		self.moneyFrame:Update()
		if self:IsShown() then
			self:Regenerate()
		end
	end
end

function BagnonFrame:GetPlayer()
	return self.player or UnitName('player')
end


--[[ layout ]]--

function BagnonFrame:Layout(cols, space)
	cols = cols or self.sets.cols or DEFAULT_COLS
	space = space or self.sets.space or DEFAULT_SPACING
	self.sets.cols = cols
	self.sets.space = space

	local borderSize = self.borderSize or 0
	local paddingY = self.paddingY or 0

	local width, height = self:LayoutItems(cols, space, borderSize/2, borderSize/2 + paddingY)

	local bags = self.bagFrame
	local money = self.moneyFrame

	bags:SetPoint('BOTTOMLEFT', borderSize/2, borderSize/2)
	money:SetPoint('BOTTOMRIGHT', borderSize/2 - 2, borderSize/2)

	height = height + max(bags:GetHeight(), money:GetHeight())
	if bags.shown then
		height = height + 8
	end
	width = max(width, (money:GetWidth() + bags:GetToggleWidth() - 8), bags:GetWidth())

	width = max(width + borderSize, 48)
	height = max(height + borderSize + paddingY, 48)

	self:SetHeight(height)
	self:SetWidth(width)
end

function BagnonFrame:LayoutItems(cols, space, offX, offY)
	if not next(self.slots) then return 0, 0 end

	local itemSize = ITEM_SIZE + space
	local slots = self.slots
	local player = self:GetPlayer()

	local i = 0
	for _,bag in ipairs(self:GetVisibleBags()) do
		for slot = 1, BagnonUtil:GetBagSize(bag, player) do
			local item = slots[ToIndex(bag, slot)]
			if item then
				i = i + 1
				local row = mod(i - 1, cols)
				local col = ceil(i / cols) - 1
				item:SetPoint('TOPLEFT', self, 'TOPLEFT', itemSize * row + offX, -(itemSize * col + offY))
			end
		end
	end

	return itemSize * min(cols, i) - space, itemSize * ceil(i / cols) - space
end

function BagnonFrame:GetLayout()
	return self.sets.cols, self.sets.space
end


--[[ Sorting ]]--

local function NormalSort(a, b)
	return a ~= -2 and (b == -2 or a < b)
end

local function ReverseSort(a, b)
	return a ~= -2 and (b == -2 or a > b)
end

function BagnonFrame:SortBags()
	if self.sets.reverseSort then
		table.sort(self.sets.bags, ReverseSort)
	else
		table.sort(self.sets.bags, NormalSort)
	end
end

--[[ Settings Loading ]]--

function BagnonFrame:LoadSettings(sets)
	self.sets  = sets

	local r,g,b,a = self:GetBackgroundColor()
	self:SetBackdropColor(r, g, b, a)
	self:SetBackdropBorderColor(1, 1, 1, a)

	self:SetAlpha(sets.alpha or 1)
	self:SetScale(sets.scale or 1)

	self:SetToplevel(sets.topLevel)
	self:SetFrameStrata(sets.strata or DEFAULT_STRATA)
	self:Reposition()

	if not self:IsUserPlaced() then
		frame:SetPoint('CENTER')
	end

	self:SortBags()
end

--[[ positioning ]]--

function BagnonFrame:Lock(enable)
	self.sets.lock = enable or nil
end

function BagnonFrame:IsLocked()
	return self.sets.lock
end

function BagnonFrame:Reposition()
	local x, y, scale, parentScale = self:GetPosition()

	if x and y then
		local parent = self:GetParent()

		local ratio
		if parentScale then
			ratio = parentScale / parent:GetScale()
		else
			ratio = 1
		end

		self:ClearAllPoints()
		self:SetScale(scale)
		self:SetPoint('TOPLEFT', parent, 'BOTTOMLEFT', x * ratio, y * ratio)
		self:SetUserPlaced(true)
	else
		self:SetUserPlaced(false)
		if not self:IsUserPlaced() then
			self:SetPoint('CENTER')
		end
	end
end

function BagnonFrame:SavePosition()
	local sets = self.sets
	if sets then
		sets.x = self:GetLeft()
		sets.y = self:GetTop()
		sets.scale = self:GetScale()
		sets.parentScale = self:GetParent():GetScale()
	end
end

function BagnonFrame:GetPosition()
	local sets = self.sets
	if sets then
		return sets.x, sets.y, sets.scale, sets.parentScale
	end
end


--[[ coloring ]]--

function BagnonFrame:GetBackgroundColor()
	local sets = self.sets
	if sets then
		local bg = sets.bg
		return bg.r, bg.g, bg.b, bg.a
	end
end


--[[ title ]]--

function BagnonFrame:SetTitleText(text)
	self.titleText = text
	self:UpdateTitleText()
end

function BagnonFrame:UpdateTitleText()
	self.title:SetText(self:GetTitleText())
end

function BagnonFrame:GetTitleText()
	return format(self.titleText or self:GetName(), self:GetPlayer())
end