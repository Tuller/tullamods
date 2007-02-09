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

local function msg(message)
	ChatFrame1:AddMessage(message or 'nil', 0.3, 1, 0.3)
end

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
	if this:GetParent().sets then
		this:GetParent():OnEnter(this)
	end
end

local function OnShow()
	visible[this] = true
	this:UpdateAllCategories()
end

local function OnHide()
	visible[this] = nil
end

local function Temp_OnHide()
	visible[this] = nil
	this:Release()
end

local function Frame_Create(id)
	local name = format('Bagnon%d', id)
	local frame = CreateFrame('Frame', name, UIParent)
	setmetatable(frame, Frame_mt)

	frame.tabs = {}
	frame.frames = {}

	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:SetBackdrop(backdrop)
	frame.borderSize = 16

	local close = CreateFrame('Button', format('%sClose', name), frame, 'UIPanelCloseButton')
	close:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 6 - frame.borderSize/2, 6 - frame.borderSize/2)

	local title = CreateFrame('Button', format('%sTitle', name), frame)
	title:SetPoint('TOPLEFT', frame, 'TOPLEFT', 6 + frame.borderSize/2, -10)
	title:SetPoint('BOTTOMRIGHT', frame, 'TOPRIGHT', -26, -16 - frame.borderSize/2)
	frame.paddingY = 16

	local titleText = title:CreateFontString(format('%sTitleText', name))
	titleText:SetAllPoints(title)
	titleText:SetJustifyH('LEFT')
	titleText:SetFontObject('GameFontNormal')
	title:SetFontString(titleText)

	title:SetHighlightTextColor(1, 1, 1)
	title:SetTextColor(1, 0.82, 0)
	title:RegisterForClicks('LeftButtonUp', 'LeftButtonDown', 'RightButtonUp', 'RightButtonDown')

--	title:SetScript('OnClick', OnClick)
--	title:SetScript('OnDoubleClick', OnDoubleClick)
--	title:SetScript('OnEnter', OnEnter)
--	title:SetScript('OnLeave', OnLeave)
	title:SetScript('OnMouseUp', OnMouseUp)
	title:SetScript('OnMouseDown', OnMouseDown)

	frame:Hide()

	--msg('New Frame ' .. frame:GetName())
	return frame
end


--[[ creates a permament frame from the given settings ]]--

local function LoadSettings(frame, sets)
	--msg('Load Settings ' .. frame:GetName())
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
		--msg('Place ' .. frame:GetName())
		frame:SetPoint('CENTER', UIParent)
	end

	table.sort(frame:GetVisibleBags(), NormalSort)
	frame:SetTitle(frame.name or frame:GetName())
	frame:UpdateAllCategories()
end

function BagnonFrame.Create(name, sets, bags)
	local frame = TPool.Get('BagnonFrame', Frame_Create)
	frame:SetParent(UIParent)

	LoadSettings(frame, sets)

	frame.cats = sets.cats
	frame.shownBags = sets.bags
	frame.showBags = sets.showBags
	frame.bags = bags

	frame:SetTitle(name)
	frame:AddMoneyFrame()
	frame:AddBagFrame()
	frame:SetScript('OnShow', OnShow)
	frame:SetScript('OnHide', OnHide)

	PlaceAndUpdate(frame)

	return frame
end


--[[ creates a frame from the given settings that is destroyed when closed, intended for viewing other character's data ]]--

function BagnonFrame.CreateTempOfSaved(name, sets, bags)
	local frame = TPool.Get('BagnonFrame', Frame_Create)
	frame:SetParent(UIParent)
	frame:SetFrameStrata(DEFAULT_STRATA)
	frame:SetToplevel(false)

	local bg = sets.bg
	frame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
	frame:SetBackdropBorderColor(1, 1, 1, bg.a)

	frame.cols  = sets.cols
	frame.space = sets.space

	frame.cats = sets.cats
	frame.shownBags = sets.bags
	frame.showBags = sets.showBags
	frame.bags = bags

	frame:SetTitle(name)
	frame:AddMoneyFrame()
	frame:AddBagFrame()
	frame:SetScript('OnShow', OnShow)
	frame:SetScript('OnHide', Temp_OnHide)

	PlaceAndUpdate(frame)

	return frame
end


--[[ creates a frame that is destroyed upon being closed, intended for searching ]]--

function BagnonFrame.CreateTemp(name, cats, bags)
	local frame = TPool.Get('BagnonFrame', Frame_Create)
	frame:SetParent(UIParent)
	frame:SetFrameStrata(DEFAULT_STRATA)

	frame:SetBackdropColor(random()/2, random()/2, random()/2, 0.5)
	frame:SetBackdropBorderColor(1, 1, 1, 0.5)
	frame:SetToplevel(false)
	frame:SetFrameStrata(DEFAULT_STRATA)

	frame.cols  = nil
	frame.space = nil
	frame.showBags = nil

	frame.cats = cats
	frame.shownBags = bags
	frame.bags = bags

	frame:SetTitle(name)
	frame:SetScript('OnShow', OnShow)
	frame:SetScript('OnHide', Temp_OnHide)

	PlaceAndUpdate(frame)

	return frame
end


--[[ destroys the given frame ]]--

function BagnonFrame:Release()
	--msg(format('Release %s', self:GetName()))
	self:Hide()
	self:RemoveAllCategories()
	self:RemoveMoneyFrame()
	self:RemoveBagFrame()

	self.name = nil
	self.cols = nil
	self.space = nil
	self.shownBags = nil
	self.bags = nil
	self.sets = nil
	self.showBags = nil

	used[self] = nil
	visible[self] = nil
	self:SetScript('OnShow', nil)
	self:SetScript('OnHide', nil)
	TPool.Release(self, 'BagnonFrame')
end


--[[ Frame Event ]]--

function BagnonFrame:OnClick(mouseButton)
	if mouseButton == 'RightButton' then
		if self.sets then
			BagnonMenu_Show(self)
		end
	end
end

function BagnonFrame:OnDoubleClick(mouseButton)
	if mouseButton == 'LeftButton' then
		BagnonSpot_Show(self)
	end
end

function BagnonFrame:OnMouseDown()
	if not(self.sets and self:IsLocked()) then
		self:StartMoving()
	end
end

function BagnonFrame:OnMouseUp()
	self:StopMovingOrSizing()
	self:SavePosition()
end

function BagnonFrame:OnEnter(title)
	if BagnonLib.GetPlayerSets().showTooltips then
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


--[[ title ]]--

function BagnonFrame:SetTitle(name)
	self.name = name
	self:UpdateTitle()
end

function BagnonFrame:UpdateTitle()
	getglobal(self:GetName() .. 'Title'):SetText(format(self.name or self:GetName(), self:GetPlayer()))
end

function BagnonFrame:GetTitle()
	return self.name
end


--[[ layout ]]--

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

	for i in ipairs(self:GetAllCategories()) do
		local frame = self:GetCategoryFrame(i)
		if frame and frame:IsShown() then
			frame:Layout()
			if frame:GetWidth() > width then
				width = frame:GetWidth()
			end
		end
	end

	for i in ipairs(self:GetAllCategories()) do
		local frame = self:GetCategoryFrame(i)
		if frame and next(frame.items) then
			frame:ClearAllPoints()
			frame:SetPoint('TOPLEFT', self, 'TOPLEFT', borderSize/2, -(height + paddingY + borderSize/2))
			height = height + frame:GetHeight()
		end
	end
	height = height + paddingY + borderSize

	local bagFrame = self:GetBagFrame()
	if bagFrame and moneyFrame then
		height = height + max(bagFrame:GetHeight(), moneyFrame:GetHeight()) + 4
		width = max(width, moneyFrame:GetWidth() + bagFrame:GetWidth() + 4)
	elseif bagFrame then
		height = height + bagFrame:GetHeight() + 4
		width = max(width, bagFrame:GetWidth())
	elseif moneyFrame then
		height = height + moneyFrame:GetHeight() + 4
		width = max(width, moneyFrame:GetWidth())
	end

	local moneyFrame = self:GetMoneyFrame()
	local bagFrame = self:GetBagFrame()

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

	self:SetHeight(height); self:SetWidth(width)

	--msg('PostLayout ' .. self:GetName())
end

function BagnonFrame:GetLayout()
	return self.cols, self.space
end


--[[ locking ]]--

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


--[[ positioning ]]--

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


--[[ category methods ]]--

function BagnonFrame:AddCategory(...)
	self:SetCategory(#self.cats + 1, ...)
end

function BagnonFrame:SetCategory(index, title, show)
	--msg('SetCategory ' .. index .. ' ' .. (title or 'nil'))

	if not self.cats[index] then
		self.cats[index] = {}
	end

	self.cats[index].title = title
	self.cats[index].show = show
	self:UpdateCategory(index, true)
end

function BagnonFrame:RemoveCategory(index)
	--msg('RemoveCategory ' .. index)

	table.remove(self.cats, index)
	self:UpdateAllCategories()
end

function BagnonFrame:RemoveAllCategories()
	--msg('RemoveAllCategories ' .. index)

	for i in pairs(self.cats) do
		self.cats[i] = nil
		self:RemoveCategoryFrame(i)
	end

	for i,frame in pairs(self.frames) do
		self.frames[i] = nil
		frame:Release()
	end
end

function BagnonFrame:UpdateCategory(index, update)
	--msg('UpdateCategory ' .. index)

	local cat = self:GetCategory(index)
	if cat then
		local frame = self:GetCategoryFrame(index) or self:CreateCategoryFrame(index)
		frame:Set(self, cat.show)
	else
		self:RemoveCategoryFrame(index)
	end

	if update then
		self:Layout()
	end
end

function BagnonFrame:UpdateAllCategories()
	--msg('Update All Categories')

	local cats = self:GetAllCategories()
	if cats then
		for i in pairs(cats) do
			self:UpdateCategory(i, true)
		end

		for i, frame in pairs(self.frames) do
			if not self:GetCategory(i) then
				self.frames[i] = nil
				frame:Release()
			end
		end
	else
		self:RemoveAllCategoryFrames()
	end
	self:Layout()
end

function BagnonFrame:ShowCategory(index, show)
	--msg('ShowCategory ' .. index)

	local sets = self:GetCategorySettings(index)
	if show then
		sets.show = true
	else
		sets.show = nil
	end
	self:UpdateCategory(index, true)
end


--[[ category access ]]--

function BagnonFrame:IsCategoryShown(index)
	local sets = self:GetCategorySettings(index)
	if sets then
		return sets.show
	end
end

function BagnonFrame:GetCategoryRule(index)
	local frame = self:GetCategoryFrame(index)
	if frame then
		return frame:GetRule()
	end

	local sets = self:GetCategorySettings(index)
	if sets then
		return BagnonLib.ToRule(sets.name, sets.tag, sets.rule)
	end
end

function BagnonFrame:GetCategoryIcon(index)
	local sets = self:GetCategorySettings(index)
	if sets then
		return sets.icon
	end
end

function BagnonFrame:GetCategoryTitle(index)
	local sets = self:GetCategorySettings(index)
	if sets then
		return sets.name
	end
end

function BagnonFrame:GetCategory(index)
	return self.cats[index]
end

function BagnonFrame:GetAllCategories()
	return self.cats
end


--[[ category frame ]]--

function BagnonFrame:CreateCategoryFrame(index)
	--msg('CreateCategoryFrame ' .. index)

	self.frames[index] = BagnonCat.Get()
	return self.frames[index]
end

function BagnonFrame:RemoveCategoryFrame(index)
	--msg('RemoveCategoryFrame ' .. index)

	local frame = self.frames[index]
	if frame then
		self.frames[index] = nil
		frame:Release()
	end
end

function BagnonFrame:RemoveAllCategoryFrames()
	--msg('RemoveAllCategoryFrames ' .. index)

	for i, frame in pairs(self.frames) do
		self.frames[i] = nil
		frame:Release()
	end
end

function BagnonFrame:GetCategoryFrame(index)
	return self.frames[index]
end

function BagnonFrame:GetAllCategoryFrames()
	return self.frames
end


--[[ bag methods ]]--

function BagnonFrame:ShowBag(bag, enable)
	if enable then
		if not self:BagIsVisible(bag) then
			local bags = self:GetVisibleBags()
			table.insert(bags, bag)
			table.sort(bags, NormalSort)

			for _,frame in pairs(self:GetAllCategoryFrames()) do
				frame:AddBag(bag)
			end
		end
	else
		local index = self:BagIsVisible(bag)
		if index then
			local bags = self:GetVisibleBags()
			table.remove(bags, index)
			table.sort(bags, NormalSort)

			for _,frame in pairs(self:GetAllCategoryFrames()) do
				frame:RemoveBag(bag)
			end
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


--[[ tab functions ]]--

function BagnonFrame:UpdateTab(index)
	local tab = self.tabs[index]
	if tab then
		tab:Update()
	end
end

function BagnonFrame:GetAllTabs()
	return self.tabs
end


--[[ item updating ]]--

function BagnonFrame:UpdateLock(bag, slot, locked)
	--msg(format('UpdateLock %s, %s, %s', bag, slot, (locked or 'nil')))
	if self:BagIsVisible(bag) then
		for _, frame in pairs(self:GetAllCategoryFrames()) do
			 frame:UpdateLock(bag, slot, locked)
		end
	end
end

function BagnonFrame:UpdateCooldown(bag, slot)
	if self:BagIsVisible(bag) then
		for _, frame in pairs(self:GetAllCategoryFrames()) do
			 frame:UpdateCooldown(bag, slot)
		end
	end
end

function BagnonFrame:UpdateItem(bag, slot, texture)
	--msg(format('UpdateItem %s, %s, %s', bag, slot, (texture or 'empty')))

	if self:BagIsVisible(bag) then
		for _, frame in pairs(self:GetAllCategoryFrames()) do
			 frame:UpdateItem(bag, slot, texture)
		end
		self:Layout()
	end
end

function BagnonFrame:UpdateAllItems()
	--msg(format('UpdateAllItems'))

	for _, frame in pairs(self:GetAllCategoryFrames()) do
		frame:UpdateAllItems()
	end
	self:Layout()
end

function BagnonFrame:RemoveItem(bag, slot)
	--msg(format('RemoveItem %s, %s', bag, slot))

	for _, frame in pairs(self:GetAllCategoryFrames()) do
		frame:RemoveItem(bag, slot)
	end
	self:Layout()
end

function BagnonFrame:RemoveAllItems()
	--msg('RemoveAllItems')

	for _, frame in pairs(self:GetAllCategoryFrames()) do
		frame:RemoveAllItems()
	end
--	self:Layout()
end

function BagnonFrame:UpdateBank()
	for _,frame in pairs(self:GetAllCategoryFrames()) do
		if self:BagIsVisible(-1) then
			frame:UpdateBag(-1)
		end
		for bag = 5, 11 do
			if self:BagIsVisible(bag) then
				frame:UpdateBag(bag)
			end
		end
	end
end


--[[ spot searching ]]--

function BagnonFrame:HighlightRule(rule, enable)
	return
end

function BagnonFrame:HighlightBag(bag, enable)
	return
end

function BagnonFrame:HighlightLink(link, enable)
	return
end

function BagnonFrame:HighlightName(name, enable)
	return
end


--[[ cached data viewing ]]--

function BagnonFrame:SetPlayer(player)
	self.player = player
	self:RemoveAllItems()
	self:UpdateAllCategories()
	self:UpdateTitle()
	self:UpdateMoneyFrame()
end

function BagnonFrame:GetPlayer()
	return self.player or currentPlayer
end


--[[ Bag Frame ]]--

function BagnonFrame:AddBagFrame()
	if not self.bagFrame then
		local showBags = self:IsBagFrameShown()
		self.bagFrame = BagnonBagFrame.New(self, self:IsBagFrameShown())
	end
end

function BagnonFrame:RemoveBagFrame()
	if self.bagFrame then
		self.bagFrame:Release()
		self.bagFrame = nil
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


--[[ Money Frame ]]--

function BagnonFrame:AddMoneyFrame()
	if not self.moneyFrame then
		self.moneyFrame = BagnonMoney.Get(self)
	end
end

function BagnonFrame:RemoveMoneyFrame()
	if self.moneyFrame then
		self.moneyFrame:Release()
		self.moneyFrame = nil
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


--[[ Events ]]--

BVent:AddAction('BANKFRAME_OPENED', function()
	BagnonFrame.ForAllVisibleNonCached('UpdateBank')
end)

BVent:AddAction('BANKFRAME_CLOSED', function()
	BagnonFrame.ForAllVisibleNonCached('UpdateBank')
end)

BVent:AddAction('BAGNON_SLOT_UPDATE', function(action, event, ...)
	BagnonFrame.ForAllVisibleNonCached('UpdateItem', ...)
end)

BVent:AddAction('BAGNON_SLOT_UPDATE_LOCK', function(action, event, ...)
	BagnonFrame.ForAllVisibleNonCached('UpdateLock', ...)
end)

BVent:AddAction('BAGNON_SLOT_UPDATE_COOLDOWN', function(action, event, bag, slot)
	BagnonFrame.ForAllVisibleNonCached('UpdateCooldown', bag, slot)
end)

BVent:AddAction('BAGNON_SLOT_REMOVED', function(action, event, ...)
	BagnonFrame.ForAllVisibleNonCached('RemoveItem', ...)
end)