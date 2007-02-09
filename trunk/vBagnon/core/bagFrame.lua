--[[
	BagFrame.lua
--]]

BagnonBagFrame = CreateFrame('Frame')
local Frame_mt = {__index = BagnonBagFrame}

local HEIGHT_SHOWN = 52
local HEIGHT_HIDDEN = 16
local visible = {}


--[[ Toggle Button ]]--

local function Toggle_OnClick()
	local parent = this:GetParent()
	if parent.shown then
		this:SetText(BAGNON_SHOWBAGS)
	else
		this:SetText(BAGNON_HIDEBAGS)
	end
	parent:ShowBags(not parent.shown)
	parent:GetParent().sizeChanged = true
	parent:GetParent():Layout()
end

local function Toggle_Create(parent)
	local toggle = CreateFrame('Button', nil, parent)

	local text = toggle:CreateFontString()
	text:SetPoint('BOTTOMLEFT', toggle)
	text:SetJustifyH('LEFT')
	text:SetFontObject('GameFontNormal')
	toggle:SetFontString(text)
	toggle:SetHighlightTextColor(1, 1, 1)
	toggle:SetTextColor(1, 0.82, 0)

	toggle:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	toggle:SetScript('OnClick', Toggle_OnClick)

	toggle:SetPoint('TOPLEFT', parent, 'BOTTOMLEFT', 0, 18)
	toggle:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', 0, 4)

	return toggle
end


--[[ Constructor ]]--

local function OnShow() this:OnShow() end
local function OnHide() this:OnHide() end

local function BagFrame_Create(id)
	local frame = CreateFrame('Frame', format('BagnonBagFrame%s', id))
	setmetatable(frame, Frame_mt)

	frame.frames = {}
	frame.toggle = Toggle_Create(frame)

	frame:SetScript('OnShow', OnShow)
	frame:SetScript('OnHide', OnHide)

	return frame
end


--[[ Constructor/Destructor ]]--

function BagnonBagFrame.New(parent, show)
	local frame = TPool.Get('BagnonBagFrame', BagFrame_Create)
	BagnonLib.Attach(frame, parent)

	if show then
		frame.toggle:SetText(BAGNON_HIDEBAGS)
	else
		frame.toggle:SetText(BAGNON_SHOWBAGS)
	end
	frame:ShowBags(show)

	return frame
end

function BagnonBagFrame:Release()
	self:RemoveAllBags()
	TPool.Release(self, 'BagnonBagFrame')
end


--[[ Show/Hide Bags ]]--

function BagnonBagFrame:ShowBags(enable)
	if enable then
		self.shown = true
		self:GetParent().showBags = true
		self:Update()
	else
		self.shown = nil
		self:GetParent().showBags = nil
		self:RemoveAllBags()
	end
	self:Layout()
end


--[[ Updating ]]--

function BagnonBagFrame:Update()
	for _,bag in pairs(self.frames) do
		bag:Update()
	end
end

function BagnonBagFrame:UpdateLock()
	for _,bag in pairs(self.frames) do
		bag:UpdateLock()
	end
end

function BagnonBagFrame:UpdateCursor()
	for _,bag in pairs(self.frames) do
		bag:UpdateCursor()
	end
end

function BagnonBagFrame:RemoveAllBags()
	for i, bag in pairs(self.frames) do
		self.frames[i] = nil
		bag:Release()
	end
end


--[[ Layout Functions ]]--

function BagnonBagFrame:NewBag(id)
	self.frames[id] = BagnonBag.New(self, id)
	return self.frames[id]
end

function BagnonBagFrame:Layout()
	local width = 0
	if self.shown then
		local prev
		local bags = self:GetParent():GetBags()
		for _,id in pairs(bags) do
			local bag = self.frames[id] or self:NewBag(id)
			bag:ClearAllPoints()

			if prev then
				bag:SetPoint('BOTTOMLEFT', prev, 'BOTTOMRIGHT', 2, 0)
			else
				bag:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, 2)
			end

			width = width + bag:GetWidth() + 2
			prev = bag
		end
		self:SetHeight(HEIGHT_SHOWN)
	else
		self:SetHeight(HEIGHT_HIDDEN)
	end
	self:SetWidth(max(width, self.toggle:GetTextWidth()))
end


--[[ Frame Events ]]--

function BagnonBagFrame:OnShow()
	visible[self] = true
	if self.shown then
		self:Update()
	end
end

function BagnonBagFrame:OnHide()
	visible[self] = nil
end


--[[ Events ]]--

local function UpdateVisibleBags()
	for frame in pairs(visible) do
		if frame.shown then
			frame:Update()
		end
	end
end
BVent:AddAction('BANKFRAME_OPENED', UpdateVisibleBags)
BVent:AddAction('BAG_UPDATE', UpdateVisibleBags)
BVent:AddAction('PLAYERBANKSLOTS_CHANGED', UpdateVisibleBags)
BVent:AddAction('PLAYERBANKBAGSLOTS_CHANGED', UpdateVisibleBags)

BVent:AddAction('ITEM_LOCK_CHANGED', function()
	for frame in pairs(visible) do
		if frame.shown then
			frame:UpdateLock()
		end
	end
end)

BVent:AddAction('CURSOR_UPDATE', function()
	for frame in pairs(visible) do
		if frame.shown then
			frame:UpdateCursor()
		end
	end
end)