--[[
	BagnonFrame
		Method for Bagnon inventory frames
--]]

BagnonFrame = CreateFrame('Frame')
local Frame_mt = {__index = BagnonFrame}

local DEFAULT_COLS = 8
local DEFAULT_SPACING = 1
local DEFAULT_STRATA = 'HIGH'

local usedList = {}
local visibleList = {}
--local msg = function(msg) ChatFrame1:AddMessage(msg or 'nil', 0.5, 0.5, 1) end

local function Swap(list, i, j)
	local temp = list[i]
	list[i] = list[j]
	list[j] = temp
end

local function NormalSort(a, b)
	return a ~= -2 and (b == -2 or a < b)
end

local function HideAttachedMenus(frame)
	--hide menus
	if BagnonMenu and BagnonMenu.frame == frame then
		BagnonMenu:Hide()
	end
	
	if BagnonCatMenu and BagnonCatMenu.frame == frame then
		BagnonCatMenu:Hide()
	end
	
	if BagnonCatAdd and BagnonCatAdd.frame == frame then
		BagnonCatAdd:Hide()
	end
	
	if BagnonSpot and BagnonSpot.frame == frame then
		BagnonSpot:Hide()
	end	
end

--[[ Frame Constructor ]]--

local function OnClick()
	this:GetParent():OnClick(arg1)
end

local function OnDoubleClick()
	this:GetParent():OnDoubleClick(arg1)
end

local function OnMouseDown()
	this:GetParent():OnMouseDown()
end

local function OnMouseUp()
	this:GetParent():OnMouseUp()
end

local function OnEnter()
	if this:GetParent().sets then
		this:GetParent():OnEnter(this)
	end
end

local function OnLeave()
	this:GetParent():OnLeave()
end

local function OnShow()
	visibleList[this.id] = this
	this:UpdateAllSlots()
end

local function OnHide()
	visibleList[this.id] = nil
	HideAttachedMenus(this)
end

local function Temp_OnHide()
	visibleList[this.id] = nil
	HideAttachedMenus(this)

	this:Release()	
end


--[[ Settings Loading Functions ]]--

local function LoadDefaultSettings(frame)
	frame:SetAlpha(1); frame:SetScale(1)
	
	frame:SetToplevel(false)
	frame:SetFrameStrata(DEFAULT_STRATA)
	
	frame:SetBackdropColor(random()/2, random()/2, random()/2, 0.5)
	frame:SetBackdropBorderColor(1, 1, 1, 0.5)
end

local function LoadSettings(frame, sets)
	frame.sets  = sets
	frame.cols  = sets.cols
	frame.space = sets.space

	local bgSets = sets.bg
	frame:SetBackdropColor(bgSets.r, bgSets.g, bgSets.b, bgSets.a)
	frame:SetBackdropBorderColor(1, 1, 1, bgSets.a)

	frame:SetAlpha(sets.alpha or 1)
	frame:SetScale(sets.scale or 1)

	frame:SetToplevel(sets.topLevel)
	frame:SetFrameStrata(sets.strata or DEFAULT_STRATA)
	frame:Reposition()

	return sets.bags, sets.cats
end


--[[ Frame Creation ]]--

local function InventoryFrame_Create(lastCreated)
	local name = "Bagnon" .. lastCreated
	local frame = CreateFrame("Frame", name, UIParent)
	setmetatable(frame, Frame_mt)

	frame.catFrames = {}

	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:SetBackdrop({ 
	  bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
	  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	  edgeSize = 16, 
	  tile = true, tileSize = 16,
	  insets = {left = 4, right = 4, top = 4, bottom = 4}
	})
	frame.borderSize = 16

	local closeButton = CreateFrame("Button", name .. "Close", frame, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 6 - frame.borderSize/2, 6 - frame.borderSize/2)

	local title = CreateFrame('Button', name .. 'Title', frame)
	title:SetPoint("TOPLEFT", frame, "TOPLEFT", 6 + frame.borderSize/2, -10)
	title:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -26, -16 - frame.borderSize/2)
	title:SetScript('OnClick', OnClick)
	title:SetScript('OnDoubleClick', OnDoubleClick)
	title:SetScript('OnEnter', OnEnter)
	title:SetScript('OnLeave', OnLeave)
	frame.paddingY = 16

	local titleText = title:CreateFontString(name .. 'TitleText')
	titleText:SetAllPoints(title)
	titleText:SetJustifyH('LEFT')
	titleText:SetFontObject('GameFontNormal')
	title:SetFontString(titleText)

	title:SetHighlightTextColor(1, 1, 1)
	title:SetTextColor(1, 0.82, 0)
	title:RegisterForClicks('LeftButtonUp', 'LeftButtonDown', 'RightButtonUp', 'RightButtonDown')
	title:SetScript("OnMouseUp", OnMouseUp)
	title:SetScript("OnMouseDown", OnMouseDown)

	return frame
end


--[[ Methods ]]--

function BagnonFrame.Create(name, bags, cats)
	local frame = TPool.Get('BagnonFrame', InventoryFrame_Create)
	frame:SetParent(UIParent)

	LoadDefaultSettings(frame)

	frame:Set(name, bags, cats, true)	
	frame:SetScript('OnHide', Temp_OnHide)
	frame:SetScript('OnShow', OnShow)

	usedList[frame.id] = frame
	visibleList[frame.id] = frame

	return frame
end
	
function BagnonFrame.CreateSaved(name, sets, defaultBags, isBank)
	local frame = TPool.Get('BagnonFrame', InventoryFrame_Create)
	frame:SetParent(UIParent)

	local bags, cats = LoadSettings(frame, sets)

	frame:Set(name, bags, cats, nil)
	frame:AddTabs(BagnonTabList.Create(frame))	
	frame:AddBagFrame(BagnonBagFrame.Create(frame, defaultBags, sets.showBags))
	frame:AddMoneyFrame(BagnonMoney.Create(frame))
	if isBank then
		frame:AddPurchaseFrame(BagnonPurchase.Create(frame))
	end	
	frame:Layout()	

	frame:SetScript('OnHide', OnHide)
	frame:SetScript('OnShow', OnShow)

	usedList[frame.id] = frame
	visibleList[frame.id] = frame

	return frame
end

function BagnonFrame.GetUsed()
	return pairs(usedList)
end

function BagnonFrame.GetVisible()
	return pairs(visibleList)
end


--[[ Frame Methods ]]--

function BagnonFrame:Set(name, bags, cats)
--	msg('set ' .. self.id)
	
	self.cats = cats
	self.bags = bags
	table.sort(self.bags, NormalSort)

	self:SetTitle(name)
	self:UpdateAllCatFrames()
end

function BagnonFrame:Release()
--	msg('release ' .. self.id)
	
	usedList[self.id] = nil
	self.sets = nil
	self.cols = nil
	self.space = nil

	self:RemoveBagFrame()
	self:RemoveTabs()
	self:RemoveMoneyFrame()
	self:RemovePurchaseFrame()
	self:RemoveAllCategories()

	self:SetScript('OnHide', nil)
	self:SetScript('OnShow', nil)

	TPool.Release(self, 'BagnonFrame')
end


--[[ Category Functions ]]--

--adds a specific item to the frame
function BagnonFrame:AddCat(name, rule, hide)
--	msg('add cat ' .. self.id .. ': ' .. #self.cats + 1)
	
	local nextCat = #self.cats + 1
	
	table.insert(self.cats, {
		['name'] = name, 
		['rule'] = rule, 
		['hide'] = hide,
	})

	self:UpdateTabs()
	self:UpdateCatFrame(nextCat)
end

function BagnonFrame:RemoveCat(index)
--	msg('remove cat ' .. self.id .. ': ' .. index)
	
	if self.cats[index] then
		self.cats[index] = nil
	end

	self:UpdateTabs()
	self:RemoveCatFrame(index)
end

function BagnonFrame:SetCat(index, name, rule, hide)
--	msg('set cat ' .. self.id .. ': ' .. index .. ', ' .. name)
	
	local cat = self:GetCat(index)
	if cat then
		cat.name = name
		cat.rule = rule
		cat.hide = hide
	else
		self.cats[index] = {
			['name'] = name, 
			['rule'] = rule,
			['hide'] = hide,
		}
	end

	self:UpdateTabs()
	self:UpdateCatFrame(index)
end

function BagnonFrame:ToggleCat(index)
--	msg('toggle cat ' .. self.id .. ': ' .. index)
	
	local cat = self:GetCat(index)
	if cat.hide then
		cat.hide = nil
	else
		cat.hide = 1
	end

	self:UpdateCatFrame(index)
end

function BagnonFrame:SwapCats(i, j)
--	msg('swap cats ' .. self.id .. ': ' .. i .. ', ' .. j)	
	Swap(self.cats, i, j)

	--removal is done to prevent excess slots from being created
	self:RemoveCatFrame(i, true)
	self:RemoveCatFrame(j, true)
	self:UpdateCatFrame(i, true)
	self:UpdateCatFrame(j, true)

	self:Layout()
end

function BagnonFrame:GetCat(index)
	return self.cats[index]
end

function BagnonFrame:GetCatRule(index)
	local cat = self.cats[index]
	if cat then
		return Bagnon_ToRule(cat.rule)
	end
end

function BagnonFrame:GetCatSlotCount(index)
	local cat = self:GetCat(index)
	local player = self:GetPlayer()
	local rule = self:GetCatRule(index)

	if cat and rule then
		local emptyCount = 0
		local itemCount = 0
		
		for _, bag in ipairs(self:GetBags()) do
			for slot = 1, Bagnon_GetSize(bag, player) do
				if rule(Bagnon_GetItemLink(player, bag, slot), bag) then
					local count = Bagnon_GetItemCount(player, bag, slot)
					if count == 0 then
						emptyCount = emptyCount + 1
					else
						itemCount = itemCount + count
					end
				end
			end
		end
		return itemCount, emptyCount
	end
	return 0, 0
end

function BagnonFrame:GetNumCats()
	local max = 0
	for i in pairs(self.cats) do
		if i > max then
			max = i
		end
	end
	return max
end


--[[ Category Frames ]]--

function BagnonFrame:AddCatFrame(index)
--	msg('add cat frame ' .. self.id .. ': ' .. index)
	
	local catFrame = BagnonCat.Get()
	self.catFrames[index] = catFrame
	
	return catFrame
end

function BagnonFrame:RemoveCatFrame(index, dontUpdate)	
	local catFrame = self:GetCatFrame(index)

	if catFrame then
--		msg('remove cat frame ' .. self.id .. ': ' .. index)

		catFrame:Release()
		self.catFrames[index] = nil
		
		if not dontUpdate then
			self:Layout()
		end
	end
end

function BagnonFrame:UpdateCatFrame(index, dontUpdate)
	local cat = self:GetCat(index)
	if cat.hide then
		self:RemoveCatFrame(index)
	else
--		msg('update cat frame ' .. self.id .. ': ' .. index)

		local catFrame = self:GetCatFrame(index) or self:AddCatFrame(index)
		catFrame:Set(self, Bagnon_ToRule(cat.rule))
	end

	if not dontUpdate then
		self:Layout()
	end
end

function BagnonFrame:UpdateAllCatFrames()
--	msg('update all cat frames ' .. self.id)
	
	for i in pairs(self.cats) do
		self:UpdateCatFrame(i, true)
	end

	self:UpdateTabs()
	self:Layout()
end

function BagnonFrame:GetCatFrame(index)
	return self.catFrames[index]
end


--[[ Cat Frame and Settings ]]--

function BagnonFrame:RemoveAllCategories()
--	msg('update all categories ' .. self.id)
	
	for i in pairs(self.cats) do
		self.cats[i] = nil
	end
	
	for i, catFrame in pairs(self.catFrames) do
		catFrame:Release()
		self.catFrames[i] = nil
	end

	self:UpdateTabs()
	self:Layout()
end


--[[ Slot Updating ]]--

function BagnonFrame:UpdateAllSlots()
--	msg('update all slots ' .. self.id)
	
	for _, catFrame in pairs(self.catFrames) do
		catFrame:UpdateAllSlots()
	end
	
	self:UpdateTabs()
	self:Layout()
end

function BagnonFrame:UpdateSlot(bag, slot, itemLink)
	if self:IsVisible() and self:HasBag(bag) then
		for _, catFrame in pairs(self.catFrames) do
			catFrame:UpdateSlot(bag, slot, itemLink)
		end
		self:Layout()
	end	
end

function BagnonFrame:RemoveSlot(bag, slot)
	if self:IsVisible() and self:HasBag(bag) then
		for _, catFrame in pairs(self.catFrames) do
			catFrame:RemoveItem(bag, slot, true)
		end
		self:Layout()
	end
end

function BagnonFrame:UpdateLock(bag, slot, locked)
	if self:IsVisible() and self:HasBag(bag) then
		for _, catFrame in pairs(self.catFrames) do
			catFrame:UpdateLock(bag, slot, locked)
		end
	end
end

function BagnonFrame:UpdateBorders()
	if self:IsVisible() then
		for _, catFrame in pairs(self.catFrames) do
			catFrame:UpdateBorders()
		end
	end
end


--[[ Slot Highlighting ]]--

function BagnonFrame:HighlightBag(bag, highlight)
	if self:HasBag(bag) then
		if not BagnonSpot_Searching() then
			for _, catFrame in pairs(self.catFrames) do
				catFrame:HighlightBag(bag, highlight)
			end
		end
	end
end

function BagnonFrame:HighlightRule(rule, highlight)
	if not BagnonSpot_Searching() then
		for _, catFrame in pairs(self.catFrames) do
			catFrame:HighlightRule(rule, highlight)
		end
	end
end

--[[ Spot Search ]]--

function BagnonFrame:UpdateSearch()
	for _, catFrame in pairs(self.catFrames) do
		catFrame:UpdateSearch()
	end
end


--[[ Title ]]--

function BagnonFrame:SetTitle(text)
	getglobal(self:GetName() .. "Title"):SetText(text or self:GetName())
end

function BagnonFrame:GetTitle()
	return getglobal(self:GetName() .. "Title"):GetText()
end


--[[ Player ]]--

function BagnonFrame:GetPlayer()
	return self.player or UnitName('player')
end


--[[ Bag List ]]--

function BagnonFrame:HasBag(bag)
	for _, bagSlot in pairs(self.bags) do
		if bag == bagSlot then
			return true
		end
	end
end

function BagnonFrame:AddBag(...)
	for i = 1, select('#', ...) do
		local newBag = select(i, ...)
		local found

		for _, bag in pairs(self.bags) do
			if bag == newBag then
				found = true
				break
			end
		end

		if not found then
			table.insert(self.bags, newBag)

			for _, catFrame in pairs(self.catFrames) do
				catFrame:AddBag(newBag)
			end
		end
	end

	table.sort(self.bags, NormalSort)
	self:Layout()
end

function BagnonFrame:RemoveBag(...)
	for i = 1, select('#', ...) do
		local newBag = select(i, ...)

		for j, bag in pairs(self.bags) do
			if bag == newBag then
				table.remove(self.bags, j)

				for _, catFrame in pairs(self.catFrames) do
					catFrame:RemoveBag(newBag)
				end
				break
			end
		end
	end
	self:Layout()
end

function BagnonFrame:ToggleBag(...)
	for i = 1, select('#', ...) do
		local newBag = select(i, ...)

		if self:HasBag(newBag) then
			self:RemoveBag(newBag)
		else
			self:AddBag(newBag)
		end
	end
end

function BagnonFrame:GetBags()
	return self.bags
end


--[[ Bag Frame ]]--

function BagnonFrame:AddBagFrame(bagFrame)
	self.bagFrame = bagFrame
	self.sizeChanged = true
end

function BagnonFrame:RemoveBagFrame()
	local bagFrame = self.bagFrame
	if bagFrame then
		bagFrame:Release()
		self.bagFrame = nil
		self.sizeChanged = true
	end
end


--[[ Tab List ]]--

function BagnonFrame:AddTabs(tabList)
	self.tabList = tabList
	self.sizeChanged = true
end

function BagnonFrame:UpdateTabs()
	local tabList = self.tabList
	if tabList then
		tabList:UpdateAllTabs()
	end
end

function BagnonFrame:RemoveTabs()
	local tabList = self.tabList
	if tabList then
		tabList:Release()
		self.tabList = nil
		self.sizeChanged = true
	end
end


--[[ Money Frame ]]--

function BagnonFrame:AddMoneyFrame(moneyFrame)
	self.moneyFrame = moneyFrame
	self.sizeChanged = true
end

function BagnonFrame:RemoveMoneyFrame()
	local moneyFrame = self.moneyFrame
	if moneyFrame then
		moneyFrame:Release()
		self.moneyFrame = nil
		self.sizeChanged = true
	end
end


--[[ Purchase Frame ]]--

function BagnonFrame:AddPurchaseFrame(purchaseFrame)
	self.purchaseFrame = purchaseFrame
	self.sizeChanged = true
end

function BagnonFrame:RemovePurchaseFrame()
	local purchaseFrame = self.purchaseFrame
	if purchaseFrame then
		purchaseFrame:Release()
		self.purchaseFrame = nil
		self.sizeChanged = true
	end
end


--[[ Layout Functions ]]--

function BagnonFrame:Layout(cols, space)
--	msg('check layout ' .. self.id)
	
	local layoutChanged = self:IsVisible() and (self.sizeChanged or not(self.cols == (cols or DEFAULT_COLS) and self.space == (space or DEFAULT_SPACING)))
	if not layoutChanged then return end
	
--	msg('layout ' .. self.id)

	self.sizeChanged = nil

	self.cols = cols or self.cols or DEFAULT_COLS
	self.space = space or self.space or DEFAULT_SPACING

	cols = self.cols
	space = self.space

	local borderSize = self.borderSize or 0
	local paddingY = self.paddingY or 0
	local totalHeight = paddingY + borderSize/2
	local totalWidth = borderSize
	
	--layout tab frame
	local tabList = self.tabList
	if tabList then
		tabList:SetPoint('TOPLEFT', self, 'TOPLEFT', borderSize/2, -(totalHeight + 6))
		totalWidth = totalWidth + tabList:GetWidth()
		totalHeight = totalHeight + tabList:GetHeight() + 4
	end
	
	--layout category frames
	for i = 1, self:GetNumCats() do
		local catFrame = self:GetCatFrame(i)
		if catFrame then
			catFrame:Layout()
			if catFrame:GetWidth() + borderSize > totalWidth then
				totalWidth = catFrame:GetWidth() + borderSize
			end
		end
	end

	local prev, mostLeft, rowWidth

	for i = 1, self:GetNumCats() do
		local catFrame = self:GetCatFrame(i)
		if catFrame and next(catFrame.items) then
			catFrame:ClearAllPoints()
			if prev then
				if rowWidth + catFrame:GetWidth() > totalWidth then
					catFrame:SetPoint('TOPLEFT', mostLeft, 'BOTTOMLEFT', 0, -space)
					mostLeft = catFrame
					rowWidth = 0

					totalHeight = totalHeight + catFrame:GetHeight() + space
				else
					catFrame:SetPoint('BOTTOMLEFT', prev, 'BOTTOMRIGHT', 8, 0)
				end
			else
				mostLeft = catFrame
				catFrame:SetPoint('TOPLEFT', self, 'TOPLEFT', borderSize/2, -totalHeight)
				rowWidth = 0
				
				totalHeight = totalHeight + catFrame:GetHeight()
			end
			rowWidth = rowWidth + catFrame:GetWidth() + 8
			prev = catFrame
		end
	end
	totalHeight = totalHeight + borderSize/2
	
	--layout purchase frame
	local purchaseFrame = self.purchaseFrame
	if purchaseFrame and purchaseFrame:IsShown() then
		purchaseFrame:SetPoint('TOPLEFT', self, 'TOPLEFT', borderSize/2 - 4, -(totalHeight + 3))
		
		totalWidth = math.max(totalWidth, purchaseFrame:GetWidth() + borderSize)
		totalHeight = totalHeight + purchaseFrame:GetHeight() + 6
	end
	
	--layout the bag and money frames
	local bagFrame = self.bagFrame
	local moneyFrame = self.moneyFrame

	if bagFrame and not bagFrame.shown and moneyFrame then
		totalWidth = math.max(totalWidth, bagFrame:GetWidth() + moneyFrame:GetWidth() + borderSize)
		totalHeight = totalHeight + bagFrame:GetHeight() + 6
	elseif bagFrame then
		totalWidth = math.max(totalWidth, bagFrame:GetWidth() + borderSize)
		totalHeight = totalHeight + bagFrame:GetHeight() + 6
	elseif moneyFrame then
		totalWidth = math.max(totalWidth, moneyFrame:GetWidth() + borderSize)
		totalHeight = totalHeight + moneyFrame:GetHeight() + 6
	end

	if bagFrame then
		bagFrame:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', borderSize/2, -totalHeight + 3)
	end
	
	if moneyFrame then
		moneyFrame:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 12 - borderSize/2, -totalHeight + 6)
	end
	
	--adjust width to fit title
	totalWidth = math.max(totalWidth, getglobal(self:GetName() .. 'TitleText'):GetStringWidth() + 48)

	self:SetHeight(totalHeight); self:SetWidth(totalWidth)
end

function BagnonFrame:ForceLayout()
	self.sizeChanged = true
	self:Layout()
end

function BagnonFrame:GetLayout()
	return (self.cols or DEFAULT_COLS), (self.space or DEFAULT_SPACING)
end


--[[ Positioning ]]--

function BagnonFrame:Reposition()
	local sets = self.sets

	if sets and sets.x then
		local parent = self:GetParent()

		local ratio
		if sets.parentScale then
			ratio = sets.parentScale / parent:GetScale()
		else
			ratio = 1
		end

		self:ClearAllPoints()
		self:SetScale(sets.scale)
		self:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", sets.x * ratio, sets.y * ratio)
		self:SetUserPlaced(true)
	end
end

function BagnonFrame:SavePosition()
	if self.sets then
		self.sets.x = self:GetLeft()
		self.sets.y = self:GetTop()
		self.sets.scale = self:GetScale()
		self.sets.parentScale = self:GetParent():GetScale()
	end
end


--[[ OnX Functions ]]--

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
	if not(self.sets and self.sets.locked) then
		self:StartMoving()
	end
end

function BagnonFrame:OnMouseUp()
	self:StopMovingOrSizing()
	self:SavePosition()
end

function BagnonFrame:OnEnter(title)
	if Bagnon_GetPlayerSets().showTooltips then
		Bagnon_AnchorTooltip(title)
	
		GameTooltip:SetText(self:GetTitle(), 1, 1, 1)
		GameTooltip:AddLine(BAGNON_TITLE_SHOW_MENU)
		GameTooltip:AddLine(BAGNON_SPOT_TOOLTIP)
		GameTooltip:Show()
	end
end

function BagnonFrame:OnLeave()
	GameTooltip:Hide()
end


--[[ Events ]]--

BEvent:AddAction('BANKFRAME_CLOSED', function()
	for _, frame in BagnonFrame.GetVisible() do
		frame:UpdateAllSlots()
	end
end)

BEvent:AddAction('SPECIAL_BAG_SLOT_UPDATE', function()
	for _, frame in BagnonFrame.GetVisible() do
		frame:UpdateSlot(arg1, arg2, arg3)
	end
end)

BEvent:AddAction('SPECIAL_BAG_SLOT_UPDATE_LOCK', function() 
	for _, frame in BagnonFrame.GetVisible() do
		frame:UpdateLock(arg1, arg2, arg3)
	end
end)

BEvent:AddAction('SPECIAL_BAG_SLOT_REMOVED', function()
	for _, frame in BagnonFrame.GetUsed() do
		frame:RemoveSlot(arg1, arg2)
	end
end)