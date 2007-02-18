--[[
	BagnonFrame
		A container frame for categories, tabs, bags, money, and purchasing bags
--]]

BagnonFrame = CreateFrame('Frame')
local Frame_mt = {__index = BagnonFrame}

local DEFAULT_COLS = 8
local DEFAULT_SPACING = 1
local DEFAULT_STRATA = 'HIGH'

local currentPlayer = UnitName('player')
local visible = {}
local used = {}
local backdrop = {
  bgFile = 'Interface\\ChatFrame\\ChatFrameBackground',
  edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
  edgeSize = 16,
  tile = true, tileSize = 16,
  insets = {left = 4, right = 4, top = 4, bottom = 4}
}


--[[ utility functions ]]--

local function NormalSort(a, b)
	return a ~= -2 and (b == -2 or a < b)
end

local function ReverseSort(a, b)
	return a ~= 2 and not(b == -2 or a < b)
end


--[[ Frame Events ]]--

local function OnClick() this:GetParent():OnClick(arg1) end
local function OnDoubleClick() this:GetParent():OnDoubleClick(arg1) end
local function OnMouseDown() this:GetParent():OnMouseDown() end
local function OnMouseUp() this:GetParent():OnMouseUp() end

local function OnEnter()
	this:GetParent():OnEnter(this)
end

local function OnLeave()
	this:GetParent():OnLeave(this)
end

local function OnShow()
	visible[this] = true
	this:UpdateAllItems()
end

local function OnHide()
	visible[this] = nil

	if BagnonMenu and BagnonMenu.frame == this then
		BagnonMenu:Hide()
	end
	
	if BagnonSpot and BagnonSpot.frame == this then
		BagnonSpot:Hide()
	end
end

local function Frame_Create(id)
	local name = format('Bagnon%d', id)
	local frame = CreateFrame('Frame', name, UIParent)
	setmetatable(frame, Frame_mt)

	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:SetBackdrop(backdrop)
	frame.borderSize = 16

	local close = CreateFrame('Button', name .. 'Close', frame, 'UIPanelCloseButton')
	close:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 6 - frame.borderSize/2, 6 - frame.borderSize/2)
	
	if BagnonDB then
		local playerDropdown = CreateFrame('Button', name .. 'DropDown', frame, 'BagnonDBUIDropDownButton')
		playerDropdown:SetPoint('TOPLEFT', frame, 'TOPLEFT', frame.borderSize/2 -2, -6)
	end

	local title = CreateFrame('Button', name .. 'Title', frame)
	if BagnonDB then
		title:SetPoint('TOPLEFT', frame, 'TOPLEFT', 26 + frame.borderSize/2, -10)
	else
		title:SetPoint('TOPLEFT', frame, 'TOPLEFT', 6 + frame.borderSize/2, -10)
	end
	title:SetPoint('BOTTOMRIGHT', frame, 'TOPRIGHT', -26, -16 - frame.borderSize/2)
	frame.paddingY = 16

	local titleText = title:CreateFontString()
	titleText:SetAllPoints(title)
	titleText:SetJustifyH('LEFT')
	titleText:SetFontObject('GameFontNormal')
	title:SetFontString(titleText)

	title:SetHighlightTextColor(1, 1, 1)
	title:SetTextColor(1, 0.82, 0)
	title:RegisterForClicks('LeftButtonUp', 'LeftButtonDown', 'RightButtonUp', 'RightButtonDown')

	title:SetScript('OnClick', OnClick)
	title:SetScript('OnDoubleClick', OnDoubleClick)
	title:SetScript('OnEnter', OnEnter)
	title:SetScript('OnLeave', OnLeave)
	title:SetScript('OnMouseUp', OnMouseUp)
	title:SetScript('OnMouseDown', OnMouseDown)

	frame:Hide()

	return frame
end


--[[ Frame Constructor ]]--

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
	used[frame] = true
	visible[frame] = true

	if not frame:IsUserPlaced() then
		frame:SetPoint('CENTER', UIParent)
	end

	table.sort(frame:GetVisibleBags(), NormalSort)
	frame:UpdateTitle()

	frame:UpdateAllItems()
	frame:Show()
end

function BagnonFrame.New(name, sets, bags, isBank)
	local frame = TPool.Get('BagnonFrame', Frame_Create)
	frame:SetParent(UIParent)

	LoadSettings(frame, sets)

	frame.shownBags = sets.bags
	frame.showBags = sets.showBags
	frame.bags = bags

	frame:SetTitle(name)

	frame:AddItemFrame()
	frame:AddMoneyFrame()
	frame:AddBagFrame()
	if isBank then
		frame:AddPurchaseFrame()
	end
	frame:SetScript('OnShow', OnShow)
	frame:SetScript('OnHide', OnHide)

	PlaceAndUpdate(frame)

	return frame
end


--[[ Frame Events ]]--

function BagnonFrame:OnClick(button)
	if button == 'RightButton' then
		BagnonMenu_Show(self)
	end
end

function BagnonFrame:OnDoubleClick(button)
	if button == 'LeftButton' then
		BagnonSpot_Show(self)
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
	if BagnonLib.GetSets().showTooltips then
		BagnonLib.AnchorTooltip(title)

		GameTooltip:SetText(self:GetTitle(), 1, 1, 1)
		GameTooltip:AddLine(BAGNON_TITLE_SHOW_MENU)
		GameTooltip:AddLine(BAGNON_SPOT_TOOLTIP)
		GameTooltip:Show()
	end
end

function BagnonFrame:OnLeave()
	GameTooltip:Hide()
end


--[[
	Update Functions
---]]


--[[ bag updating ]]--

function BagnonFrame:ShowBag(bag, enable)
	if enable then
		if not self:BagIsVisible(bag) then
			local bags = self:GetVisibleBags()
			table.insert(bags, bag)
			table.sort(bags, NormalSort)

			self:GetItemFrame():AddBag(bag)
		end
	else
		local index = self:BagIsVisible(bag)
		if index then
			local bags = self:GetVisibleBags()
			table.remove(bags, index)
			table.sort(bags, NormalSort)

			self:GetItemFrame():RemoveBag(bag)
		end
	end
	self:Layout()
end

function BagnonFrame:BagIsVisible(bag)
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

function BagnonFrame:UpdateLock(bag, slot, locked)
	if self:BagIsVisible(bag) then
		self:GetItemFrame():UpdateLock(bag, slot, locked)
	end
end

function BagnonFrame:UpdateCooldown(bag, slot)
	if self:BagIsVisible(bag) then
		self:GetItemFrame():UpdateCooldown(bag, slot)
	end
end

function BagnonFrame:UpdateItem(bag, slot, texture)
	if self:BagIsVisible(bag) then
		self:GetItemFrame():UpdateItem(bag, slot, texture)
		self:Layout()
	end
end

function BagnonFrame:UpdateAllItems()
	self:GetItemFrame():UpdateAllItems()
	self:Layout()
end


--[[ item removal ]]--

function BagnonFrame:RemoveItem(bag, slot)
	self:GetItemFrame():RemoveItem(bag, slot)
	self:Layout()
end

function BagnonFrame:RemoveAllItems()
	self:GetItemFrame():RemoveAllItems()
end


--[[ spot searching ]]--

function BagnonFrame:UpdateSearch()
	self:GetItemFrame():UpdateSearch()
end


--[[ cached data viewing ]]--

function BagnonFrame:SetPlayer(player)
	self.player = player

	self:RemoveAllItems()
	self:UpdateAllItems()
	self:UpdateTitle()
	self:UpdateMoneyFrame()
	
	local bagFrame = self:GetBagFrame()
	if bagFrame then
		bagFrame:Update()
	end
	
	local purchaseFrame = self:GetPurchaseFrame()
	if purchaseFrame then
		purchaseFrame:UpdateVisibility()
	end
end

function BagnonFrame:GetPlayer()
	return self.player or currentPlayer
end


--[[
	Layout Functions
--]]

function BagnonFrame:Layout(cols, space)
	cols = cols or self.cols or DEFAULT_COLS
	space = space or self.space or DEFAULT_SPACING
	self.cols = self.cols or DEFAULT_COLS
	self.space = self.space or DEFAULT_SPACING

	if not(self:IsShown() and (self.sizeChanged or self.cols ~= cols or self.space ~= space)) then return end
	self.sizeChanged = nil

	cols = cols or self.cols or DEFAULT_COLS
	space = space or self.space or DEFAULT_SPACING
	self.cols = cols
	self.space = space

	local borderSize = self.borderSize or 0
	local paddingY = self.paddingY or 0
	local height = 0
	local width = 0

	local itemFrame = self:GetItemFrame()
	itemFrame:Layout()
	itemFrame:ClearAllPoints()
	itemFrame:SetPoint('TOPLEFT', self, 'TOPLEFT', borderSize/2, -(paddingY + borderSize/2))

	height = itemFrame:GetHeight() + paddingY + borderSize
	width  = itemFrame:GetWidth()

	local purchaseFrame = self:GetPurchaseFrame()
	if purchaseFrame and purchaseFrame:ShouldShow() then
		purchaseFrame:SetPoint('TOPLEFT', self, 'TOPLEFT', borderSize/2 - 3, -height)

		height = height + purchaseFrame:GetHeight() + 8
		width = max(width, purchaseFrame:GetWidth())
	end

	local moneyFrame = self:GetMoneyFrame()
	local bagFrame = self:GetBagFrame()

	if bagFrame and moneyFrame then
		height = height + max(bagFrame:GetHeight(), moneyFrame:GetHeight()) + 4
		width = max(width, moneyFrame:GetWidth() + bagFrame:GetTitleWidth(), bagFrame:GetWidth())
	elseif bagFrame then
		height = height + bagFrame:GetHeight() + 4
		width = max(width, bagFrame:GetWidth())
	elseif moneyFrame then
		height = height + moneyFrame:GetHeight() + 4
		width = max(width, moneyFrame:GetWidth())
	end

	if bagFrame then
		bagFrame:ClearAllPoints()
		bagFrame:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', borderSize/2, borderSize/2 - 4)
	end

	if moneyFrame then
		moneyFrame:ClearAllPoints()
		moneyFrame:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', 10 - borderSize/2, borderSize/2)
	end

	width = max(width + borderSize, 48)
	height = max(height, 48)

	self:SetHeight(height)
	self:SetWidth(width)
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



--[[
	Subframes
--]]


--[[ Item Frame ]]--

function BagnonFrame:AddItemFrame()
	if not self.itemFrame then
		self.itemFrame = BagnonCat.New(self)
	end
end

function BagnonFrame:GetItemFrame()
	return self.itemFrame
end


--[[ Title Frame ]]--

function BagnonFrame:SetTitle(name)
	self.name = name
	self:UpdateTitle()
end

function BagnonFrame:UpdateTitle()
	getglobal(self:GetName() .. 'Title'):SetText(self:GetTitle())
end

function BagnonFrame:GetTitle()
	return format(self.name or self:GetName(), self:GetPlayer())
end


--[[ Bag Frame ]]--

function BagnonFrame:AddBagFrame()
	if not self.bagFrame then
		self.bagFrame = BagnonBagFrame.New(self, self:IsBagFrameShown())
	end
end

function BagnonFrame:UpdateBagFrame()
	if self.bagFrame then
		self.bagFrame:ShowBags(self.showBags)
	end
end

function BagnonFrame:GetBagFrame()
	return self.bagFrame
end

function BagnonFrame:IsBagFrameShown()
	return self.showBags
end


--[[ Purchase Frame ]]--

function BagnonFrame:AddPurchaseFrame()
	if not self.purchaseFrame then
		self.purchaseFrame = BagnonPurchase.New(self)
	end
end

function BagnonFrame:GetPurchaseFrame()
	return self.purchaseFrame
end


--[[ Money Frame ]]--

function BagnonFrame:AddMoneyFrame()
	if not self.moneyFrame then
		self.moneyFrame = BagnonMoney.New(self)
	end
end

function BagnonFrame:UpdateMoneyFrame()
	if self.moneyFrame then
		self.moneyFrame:Update()
	end
end

function BagnonFrame:GetMoneyFrame()
	return self.moneyFrame
end


--[[ Utility Functions ]]--

function BagnonFrame.ForAll(action, ...)
	if type(action) == 'string' then
		for frame in pairs(used) do
			frame[action](frame, ...)
		end
	else
		for frame in pairs(used) do
			action(frame, ...)
		end
	end
end

function BagnonFrame.ForAllVisible(action, ...)
	if type(action) == 'string' then
		for frame in pairs(visible) do
			frame[action](frame, ...)
		end
	else
		for frame in pairs(visible) do
			action(frame, ...)
		end
	end
end

function BagnonFrame.ForAllVisibleNonCached(action, ...)
	if type(action) == 'string' then
		for frame in pairs(visible) do
			if frame:GetPlayer() == currentPlayer then
				frame[action](frame, ...)
			end
		end
	else
		for frame in pairs(visible) do
			if frame:GetPlayer() == currentPlayer then
				action(frame, ...)
			end
		end
	end
end


--[[
	Inventory Events
--]]

BVent:AddAction('BAGNON_SLOT_UPDATE', function(action, event, ...)
	BagnonFrame.ForAllVisibleNonCached('UpdateItem', ...)
end)

BVent:AddAction('BAGNON_SLOT_ADDED', function(action, event, ...)
	BagnonFrame.ForAllVisibleNonCached('UpdateItem', ...)
end)

BVent:AddAction('BAGNON_SLOT_UPDATE_LOCK', function(action, event, ...)
	BagnonFrame.ForAllVisibleNonCached('UpdateLock', ...)
end)

BVent:AddAction('BAGNON_SLOT_UPDATE_COOLDOWN', function(action, event, ...)
	BagnonFrame.ForAllVisibleNonCached('UpdateCooldown', ...)
end)

BVent:AddAction('BAGNON_SLOT_REMOVED', function(action, event, ...)
	BagnonFrame.ForAllVisibleNonCached('RemoveItem', ...)
end)