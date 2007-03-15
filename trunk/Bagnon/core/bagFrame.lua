--[[
	BagFrame.lua
--]]

BagnonBagFrame = CreateFrame('Frame')
local Frame_mt = {__index = BagnonBagFrame}

local lastCreated = 0

local function Toggle_OnClick()
	this:GetParent():ShowBags(not this:GetParent().shown, true)
end

local function Toggle_New(parent, shown)
	local toggle = CreateFrame('Button', nil, parent)
	toggle:SetPoint('BOTTOMLEFT', parent)

	local text = toggle:CreateFontString()
	text:SetPoint('BOTTOMLEFT', toggle)
	text:SetJustifyH('LEFT')
	text:SetFontObject('GameFontNormal')

	toggle:SetFontString(text)
	toggle:SetHighlightTextColor(1, 1, 1)
	toggle:SetTextColor(1, 0.82, 0)
	toggle:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	toggle:SetScript('OnClick', Toggle_OnClick)
	toggle:SetPoint('BOTTOMLEFT', parent)
	toggle:SetHeight(18)
	toggle:SetWidth(18)

	return toggle
end

local function BagFrame_OnEvent()
	if this.shown then
		if event == 'BAG_UPDATE' or event == 'PLAYERBANKSLOTS_CHANGED' or event == 'PLAYERBANKBAGSLOTS_CHANGED' then
			this:Update()
		elseif event == 'ITEM_LOCK_CHANGED' then
			this:UpdateLock()
		elseif event == 'CURSOR_UPDATE' then
			this:UpdateCursor()
		elseif event == 'BANKFRAME_OPENED' or event == 'BANKFRAME_CLOSED' then
			this:UpdatePurchase()
		end
	end
end

local function BagFrame_Create()
	local frame = CreateFrame('Frame', format('BagnonBag%s', lastCreated))
	setmetatable(frame, Frame_mt)
	frame.bags = {}
	frame:SetScript('OnEvent', BagFrame_OnEvent)

	lastCreated = lastCreated + 1

	return frame
end


--[[ Usable Functions ]]--

function BagnonBagFrame.New(parent, bags, isBank, shown)
	local frame = BagFrame_Create()
	BagnonUtil:Attach(frame, parent)

	frame.toggle = Toggle_New(frame, shown)

	for i, bagID in ipairs(bags) do
		frame.bags[i] = BagnonBag.New(frame, bagID)
	end

	if isBank then
		frame.purchase = BagnonPurchase.New(frame)
		frame.purchase:SetPoint('TOPLEFT', frame, 'TOPLEFT', -2, 2)
		frame:RegisterEvent('BANKFRAME_OPENED')
		frame:RegisterEvent('BANKFRAME_CLOSED')
	end

	frame:RegisterEvent('BAG_UPDATE')
	frame:RegisterEvent('PLAYERBANKSLOTS_CHANGED')
	frame:RegisterEvent('PLAYERBANKBAGSLOTS_CHANGED')
	frame:RegisterEvent('ITEM_LOCK_CHANGED')
	frame:RegisterEvent('CURSOR_UPDATE')

	frame:ShowBags(shown)

	return frame
end

function BagnonBagFrame:Layout()
	local width = self:GetToggleWidth()
	local height = 18

	if self.shown then
		if self.purchase and self.purchase:IsShown() then
			height = height + self.purchase:GetHeight() + 4
		end

		local bagWidth = 0
		for i, bag in ipairs(self.bags) do
			bag:Show()
			bag:ClearAllPoints()
			if i > 1 then
				bag:SetPoint('BOTTOMLEFT', self.bags[i-1], 'BOTTOMRIGHT', 2, 0)
			else
				height = height + bag:GetHeight()

				if self.purchase and self.purchase:IsShown() then
					bag:SetPoint('TOPLEFT', self.purchase, 'BOTTOMLEFT', 2, -4)
				else
					bag:SetPoint('TOPLEFT', self, 'TOPLEFT', 2, 0)
				end
			end
			bagWidth = bagWidth + bag:GetWidth() + 2
		end

		if self.purchase then
			width = max(bagWidth, width, self.purchase:GetWidth())
		else
			width = max(bagWidth, width)
		end
	else
		if self.purchase then
			self.purchase:Hide()
		end
		for _,bag in ipairs(self.bags) do
			bag:Hide()
		end
	end

	self:SetWidth(width)
	self:SetHeight(height)
end

function BagnonBagFrame:UpdatePurchase()
	if self.purchase then
		local wasShown = self.purchase:IsShown()
		self.purchase:UpdateShown()
		self:Layout()
		self:GetParent():Layout()
	end
end

function BagnonBagFrame:ShowBags(show, updateParent)
	self.shown = show
	
	if self.purchase then
		self.purchase:UpdateShown()
	end

	if show then
		self.toggle:SetText(BAGNON_HIDEBAGS)
		self.toggle:SetWidth(self.toggle:GetTextWidth())
	else
		self.toggle:SetText(BAGNON_SHOWBAGS)
		self.toggle:SetWidth(self.toggle:GetTextWidth())
	end

	self:Layout()

	if updateParent then
		self:GetParent():Layout()
	end
end

function BagnonBagFrame:Update()
	self:UpdateBags()
	self:UpdatePurchase()
end

function BagnonBagFrame:UpdateBags()
	for _, bag in pairs(self.bags) do
		bag:Update()
	end
end

function BagnonBagFrame:UpdateLock()
	for _, bag in pairs(self.bags) do
		bag:UpdateLock()
	end
end

function BagnonBagFrame:UpdateCursor()
	for _, bag in pairs(self.bags) do
		bag:UpdateCursor()
	end
end

function BagnonBagFrame:GetToggleWidth()
	return self.toggle:GetTextWidth()
end