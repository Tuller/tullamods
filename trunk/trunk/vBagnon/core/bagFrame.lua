--[[
	BagFrame.lua
--]]

--local msg = function(msg) ChatFrame1:AddMessage(msg or 'nil', 1, 1, 0) end

BagnonBagFrame = CreateFrame('Frame')
local Frame_mt = {__index = BagnonBagFrame}

local HEIGHT_SHOWN = 52
local HEIGHT_HIDDEN = 16
local visibleList = {}

--[[ Toggle Button ]]--

local function Toggle_OnClick()
	local parent = this:GetParent()
	if parent.shown then
		this:SetText(BAGNON_SHOWBAGS)
		parent:HideBags()
	else
		this:SetText(BAGNON_HIDEBAGS)
		parent:ShowBags()
	end

	parent:GetParent().sizeChanged = true
	parent:GetParent():Layout()
end

local function AddToggle(parent)
	local toggle = CreateFrame('Button', parent:GetName() .. 'Toggle', parent)

	local text = toggle:CreateFontString()
	text:SetPoint('BOTTOMLEFT', toggle)
	text:SetJustifyH('LEFT')
	text:SetFontObject('GameFontNormal')
	toggle:SetFontString(text)
	toggle:SetHighlightTextColor(1, 1, 1)
	toggle:SetTextColor(1, 0.82, 0)
	
	toggle:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	toggle:SetScript('OnClick', Toggle_OnClick)
	
	toggle:SetPoint('TOPLEFT', parent, 'BOTTOMLEFT', 0, 18)
	toggle:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', 0, 4)

	return toggle
end

--[[ Constructor ]]--

local function OnShow() this:OnShow() end
local function OnHide() this:OnHide() end

local function BagFrame_Create(lastCreated)
	local frame = CreateFrame('Frame', 'BagnonBags' .. lastCreated)
	setmetatable(frame, Frame_mt)

	frame.bagFrames = {}
	frame:SetScript('OnShow', OnShow)
	frame:SetScript('OnHide', OnHide)
	
	AddToggle(frame)

	return frame
end

--[[ Methods ]]--

function BagnonBagFrame.Create(parent, bags, showBags)
	local frame = TPool.Get('BagnonBagFrame', BagFrame_Create)
	Bagnon_AttachToFrame(frame, parent)
	frame.bags = bags

	if showBags then
		getglobal(frame:GetName() .. 'Toggle'):SetText(BAGNON_HIDEBAGS)
		frame:ShowBags()
	else
		getglobal(frame:GetName() .. 'Toggle'):SetText(BAGNON_SHOWBAGS)
		frame:HideBags()
	end

	return frame
end

function BagnonBagFrame:Release()
	TPool.Release(self, 'BagnonBagFrame')
end

function BagnonBagFrame:ShowBags()
	self.shown = true

	self:AddBags()
	self:SetHeight(HEIGHT_SHOWN)

	local purchaseFrame = self:GetParent().purchaseFrame
	if purchaseFrame then
		purchaseFrame:UpdateVisibility(false, true)
	end
	
	local sets = self:GetParent().sets
	if sets then
		sets.showBags = 1
	end
end

function BagnonBagFrame:HideBags()
	self.shown = nil

	self:RemoveAllBags()
	self:SetHeight(HEIGHT_HIDDEN)
	self:SetWidth(getglobal(self:GetName() .. 'Toggle'):GetTextWidth())
	
	local purchaseFrame = self:GetParent().purchaseFrame
	if purchaseFrame then
		purchaseFrame:UpdateVisibility(true, true)
	end
	
	local sets = self:GetParent().sets
	if sets then
		sets.showBags = nil
	end
end

function BagnonBagFrame:UpdateBag(bagID)
	local bag = self.bagFrames[bagID]
	if bag then
		bag:Update()
	end
end

function BagnonBagFrame:UpdateBags()
	for _, bag in pairs(self.bagFrames) do
		bag:Update()
	end
end

function BagnonBagFrame:UpdateLock()
	for _, bag in pairs(self.bagFrames) do
		bag:UpdateLock()
	end
end

function BagnonBagFrame:UpdateCursor()
	for _, bag in pairs(self.bagFrames) do
		bag:UpdateCursor()
	end
end

--adds bag buttons, and properly lays them out
function BagnonBagFrame:AddBag(bagID)
	local bag = BagnonBag.Get()
	bag:Set(self, bagID)
	self.bagFrames[bagID] = bag
	
	return bag
end

function BagnonBagFrame:AddBags()
	local width, prev

	for _, bagID in pairs(self.bags) do
		local bag = self.bagFrames[bagID] or self:AddBag(bagID)
		bag:ClearAllPoints()

		if prev then
			bag:SetPoint('BOTTOMLEFT', prev, 'BOTTOMRIGHT', 2, 0)
		else
			bag:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, 2)
		end

		width = (width or 0) + bag:GetWidth() + 2
		prev = bag
	end

	self:SetWidth(width or getglobal(self:GetName() .. 'Toggle'):GetTextWidth())
	self:UpdateBags()
end

function BagnonBagFrame:RemoveAllBags()
	for i, bag in pairs(self.bagFrames) do
		bag:Release()
		self.bagFrames[i] = nil
	end
end

--[[ OnX Functions ]]--

function BagnonBagFrame:OnShow()
	visibleList[self:GetID()] = self

	if self.shown then
		self:AddBags()
	end
end

function BagnonBagFrame:OnHide()
	visibleList[self:GetID()] = nil

	if self.shown then
		self:RemoveAllBags()
	end
end

--[[ Events ]]--

local function UpdateVisibleBags()
	for _, frame in pairs(visibleList) do
		frame:UpdateBags()
	end
end
BEvent:AddAction('BANKFRAME_OPENED', UpdateVisibleBags)
BEvent:AddAction('BAG_UPDATE', UpdateVisibleBags)
BEvent:AddAction('PLAYERBANKSLOTS_CHANGED', UpdateVisibleBags)
BEvent:AddAction('PLAYERBANKBAGSLOTS_CHANGED', UpdateVisibleBags)

BEvent:AddAction('ITEM_LOCK_CHANGED', function()
	for _, frame in pairs(visibleList) do
		frame:UpdateLock()
	end
end)

BEvent:AddAction('CURSOR_UPDATE', function()
	for _, frame in pairs(visibleList) do
		frame:UpdateCursor()
	end
end)