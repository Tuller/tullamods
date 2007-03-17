--[[
	BagnonFrame
		A container frame for categories, tabs, bags, money, and purchasing bags

	Each frame contains its own list of slots, index by what bag and what slot it is in
	The index, bag slot 0 is used to store size information about each bag.
--]]

BagnonFrame = CreateFrame('Frame')
local Frame_mt = {__index = BagnonFrame}
local L = BAGNON_LOCALS

local DEFAULT_COLS = 8
local DEFAULT_SPACING = 1
local DEFAULT_STRATA = 'HIGH'
local ITEM_SIZE = BagnonItem.SIZE

local currentPlayer = UnitName('player')
local lastCreated = 0
local util = BagnonUtil


--[[ utility functions ]]--

local function ToIndex(bag, slot)
	if bag < 0 then
		return bag * 100 - slot
	else
		return bag * 100 + slot
	end
end

local function NormalSort(a, b)
	return a ~= -2 and (b == -2 or a < b)
end

local function ReverseSort(a, b)
	return a ~= -2 and (b == -2 or a > b)
end

local function HideAttachedMenus(frame)
	if BagnonMenu:GetAnchor() == frame then
		BagnonMenu:Hide()
	end
	
	if BagnonSpot:GetAnchor() == frame then
		BagnonSpot:Hide()
	end

	if BagnonDBUICharacterList and BagnonDBUICharacterList.frame == frame then
		BagnonDBUICharacterList:Hide()
	end
end


--[[ stuff for creating a new frame ]]--

local function CreateTitle(parent)
	local title = CreateFrame('Button', parent:GetName() .. 'Title', parent)

	local text = title:CreateFontString()
	text:SetAllPoints(title)
	text:SetJustifyH('LEFT')
	text:SetFontObject('GameFontNormal')
	title:SetFontString(text)

	title:SetHighlightTextColor(1, 1, 1)
	title:SetTextColor(1, 0.82, 0)
	title:RegisterForClicks('LeftButtonUp', 'LeftButtonDown', 'RightButtonUp', 'RightButtonDown')

	title:SetScript('OnClick', function() this:GetParent():OnClick(arg1) end)
	title:SetScript('OnDoubleClick', function() this:GetParent():OnDoubleClick(arg1) end)
	title:SetScript('OnEnter', function() this:GetParent():OnEnter(this) end)
	title:SetScript('OnLeave', function() this:GetParent():OnLeave(this) end)
	title:SetScript('OnMouseUp', function() this:GetParent():OnMouseUp() end)
	title:SetScript('OnMouseDown', function() this:GetParent():OnMouseDown() end)

	return title
end

local function Frame_Create()
	local name = format('BagnonFrame%d', lastCreated)
	local frame = CreateFrame('Frame', name, UIParent)
	setmetatable(frame, Frame_mt)

	frame.slots = {}

	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:SetBackdrop({
	  bgFile = 'Interface\\ChatFrame\\ChatFrameBackground',
	  edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
	  edgeSize = 16,
	  tile = true, tileSize = 16,
	  insets = {left = 4, right = 4, top = 4, bottom = 4}
	})
	frame.borderSize = 16

	local close = CreateFrame('Button', name .. 'Close', frame, 'UIPanelCloseButton')
	close:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 6 - frame.borderSize/2, 6 - frame.borderSize/2)

	if BagnonDB then
		local playerDropdown = CreateFrame('Button', name .. 'DropDown', frame, 'BagnonDBUIDropDownButton')
		playerDropdown:SetPoint('TOPLEFT', frame, 'TOPLEFT', frame.borderSize/2 -2, -6)
	end

	local title = CreateTitle(frame)
	if BagnonDB then
		title:SetPoint('TOPLEFT', frame, 'TOPLEFT', 26 + frame.borderSize/2, -10)
	else
		title:SetPoint('TOPLEFT', frame, 'TOPLEFT', 6 + frame.borderSize/2, -10)
	end
	title:SetPoint('BOTTOMRIGHT', frame, 'TOPRIGHT', -24, -16 - frame.borderSize/2)
	frame.paddingY = 24

	frame:Hide()

	lastCreated = lastCreated + 1

	return frame
end

local function LoadSettings(frame, sets)
	frame.sets  = sets
	frame.cols  = sets.cols
	frame.space = sets.space

	local r,g,b,a = frame:GetBackgroundColor()
	frame:SetBackdropColor(r, g, b, a)
	frame:SetBackdropBorderColor(1, 1, 1, a)

	frame:SetAlpha(sets.alpha or 1)
	frame:SetScale(sets.scale or 1)

	frame:SetToplevel(sets.topLevel)
	frame:SetFrameStrata(sets.strata or DEFAULT_STRATA)
	frame:Reposition()
end

local function PlaceAndUpdate(frame)
	if not frame:IsUserPlaced() then
		frame:SetPoint('CENTER', UIParent)
	end

	frame:SortBags()

	if not frame:IsShown() then
		frame:Show()
	else
		frame:Regenerate()
	end
end


--[[ usable functions ]]--

function BagnonFrame.New(name, sets, bags, isBank)
	local frame = Frame_Create()
	frame:SetParent(UIParent)

	LoadSettings(frame, sets)

	frame.showBags = sets.showBags
	frame.shownBags = sets.bags
	frame.bags = bags
	frame.isBank = isBank

	frame.bagFrame = BagnonBagFrame.New(frame, bags, isBank, sets.showBags)
	frame.moneyFrame = BagnonMoney.New(frame)

	frame:SetTitleText(name)

	frame:SetScript('OnShow', function() frame:OnShow() end)
	frame:SetScript('OnHide', function() frame:OnHide() end)
	frame:SetScript('OnEvent', function() frame:OnEvent() end)

	frame:RegisterEvent('BAG_UPDATE')
	frame:RegisterEvent('ITEM_LOCK_CHANGED')
	frame:RegisterEvent('BAG_UPDATE_COOLDOWN')
	if isBank then
		frame:RegisterEvent('PLAYERBANKSLOTS_CHANGED')
	end

	PlaceAndUpdate(frame)

	return frame
end


--[[ frame events ]]--

function BagnonFrame:OnEvent()
	if self:IsShown() and not self:IsCached() then
		if event == 'BAG_UPDATE' then
			self:OnBagUpdate(arg1)
		elseif event == 'ITEM_LOCK_CHANGED' then
			self:UpdateLockedSlots()
		elseif event == 'BAG_UPDATE_COOLDOWN' then
			self:UpdateSlotsOnCooldown()
		elseif event == 'PLAYERBANKSLOTS_CHANGED' then
			self:OnBagUpdate(-1)
		end
	end
end

function BagnonFrame:OnClick(button)
	if button == 'RightButton' then
		BagnonMenu:Show(self)
	end
end

function BagnonFrame:OnDoubleClick(button)
	if button == 'LeftButton' then
		BagnonSpot:Show(self)
	end
end

function BagnonFrame:OnMouseDown()
	if not self:IsLocked() then
		self:StartMoving()
	end
end

function BagnonFrame:OnMouseUp()
	self:StopMovingOrSizing()
	self:SavePosition()
end

function BagnonFrame:OnEnter(title)
	util:AnchorTooltip(title)

	GameTooltip:SetText(self:GetTitleText(), 1, 1, 1)
	GameTooltip:AddLine(L.TipShowMenu)
	GameTooltip:AddLine(L.TipShowSearch)
	GameTooltip:Show()
end

function BagnonFrame:OnLeave()
	GameTooltip:Hide()
end

function BagnonFrame:OnShow()
	self:Regenerate()
end

function BagnonFrame:OnHide()
	HideAttachedMenus(self)

	if self:GetPlayer() ~= currentPlayer then
		self:SetPlayer(currentPlayer)
	end
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
	return self.shownBags
end


--[[ item updating ]]--

function BagnonFrame:AddItem(bag, slot)
	local item = BagnonItem.Get(self, bag, slot)
	self.slots[ToIndex(bag, slot)] = item
	item:Update()
end

function BagnonFrame:RemoveItem(bag, slot)
	local item = self.slots[ToIndex(bag, slot)]
	self.slots[ToIndex(bag, slot)] = nil
	item:Release()
end


--[[ Frame Updating ]]--

--add any added slots, removed any removed slots, update the rest of the slots held by the bag
function BagnonFrame:Regenerate()
	self.bagFrame:Update()

	local sizeChanged = false
	local slots = self.slots
	
	for _, bag in ipairs(self.shownBags) do
		local prevSize = slots[bag*100] or 0
		local size = util:GetBagSize(bag, self:GetPlayer())
		slots[bag * 100] = size

		for slot = 1, min(prevSize, size) do
			local item = self.slots[ToIndex(bag, slot)]
			item:Update()
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

	if sizeChanged then self:Layout() end
end

--add any added slots, removed any removed slots, update all the slots of the bag being updated
function BagnonFrame:OnBagUpdate(updatedBag)
	local sizeChanged = false
	local slots = self.slots

	for _, bag in ipairs(self.shownBags) do
		local prevSize = slots[bag*100] or 0
		local size = util:GetBagSize(bag, self:GetPlayer())
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

	if sizeChanged then self:Layout() end
end

function BagnonFrame:AddBag(bag)
	local prevSize = self.slots[bag * 100] or 0
	local size = util:GetBagSize(bag, self:GetPlayer())
	self.slots[bag * 100] = size

	for slot = 1, size do
		self:AddItem(bag, slot)
	end
	self:Layout()
end

function BagnonFrame:RemoveBag(bag)
	for slot = 1, util:GetBagSize(bag, self:GetPlayer()) do
		self:RemoveItem(bag, slot)
	end
	self:Layout()
end

function BagnonFrame:UpdateLockedSlots()
	for _, item in pairs(self.slots) do
		if not tonumber(item) then
			item:UpdateLock()
		end
	end
end

function BagnonFrame:UpdateSlotsOnCooldown()
	for bag = 0, 4 do
		for slot = 1, util:GetBagSize(bag) do
			local item = self.slots[ToIndex(bag,slot)]
			if item then
				item:UpdateCooldown()
			end
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
	self.player = player

	self:UpdateTitleText()
	self.bagFrame:Update()
	self.moneyFrame:Update()
	if self:IsShown() then
		self:Regenerate()
	end
end

function BagnonFrame:GetPlayer()
	return self.player or currentPlayer
end

function BagnonFrame:IsCached()
	return (self:GetPlayer() ~= currentPlayer) or (self.isBank and not util:AtBank())
end


--[[ layout ]]--

function BagnonFrame:Layout(cols, space)
	cols = cols or self.cols or DEFAULT_COLS
	space = space or self.space or DEFAULT_SPACING
	self.cols = cols
	self.space = space

	local borderSize = self.borderSize or 0
	local paddingY = self.paddingY or 0

	local width, height = self:LayoutItems(cols, space, borderSize/2, borderSize/2 + paddingY)

	local bags = self.bagFrame
	local money = self.moneyFrame

	bags:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', borderSize/2, borderSize/2)
	money:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', borderSize/2 - 2, borderSize/2)

	height = height + max(bags:GetHeight(), money:GetHeight())
	if bags.shown then
		height = height + 8
	end
	width = max(width, (money:GetWidth() + bags:GetToggleWidth() - 8), bags:GetWidth())

	width = max(width + borderSize, 48)
	height = max(height + borderSize + paddingY, 48)

	self:SetHeight(height); self:SetWidth(width)
end

function BagnonFrame:LayoutItems(cols, space, offX, offY)
	if not next(self.slots) then return 0, 0 end

	local itemSize = ITEM_SIZE + space
	local slots = self.slots
	local player = self:GetPlayer()

	local i = 0
	for _,bag in ipairs(self.shownBags) do
		for slot = 1, util:GetBagSize(bag, player) do
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
	return self.cols, self.space
end


--[[ positioning ]]--

function BagnonFrame:Lock(enable)
	if enable then
		self.sets.lock = true
	else
		self.sets.lock = nil
	end
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
	getglobal(self:GetName() .. 'Title'):SetText(self:GetTitleText())
end

function BagnonFrame:GetTitleText()
	return format(self.titleText or self:GetName(), self:GetPlayer())
end

--[[ Sorting ]]--

function BagnonFrame:SortBags()
	if self.sets.reverseSort then
		table.sort(self.sets.bags, ReverseSort)
	else
		table.sort(self.sets.bags, NormalSort)
	end
end