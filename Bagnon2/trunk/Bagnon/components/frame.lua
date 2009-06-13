--[[
	frame.lua
		A Bagnon frame widget
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')

local Frame = Bagnon.Classy:New('Frame')
Frame:Hide()
Bagnon.Frame = Frame

function Frame:New(frameID)
	local f = self:Bind(CreateFrame('Frame', 'BagnonFrame' .. frameID, UIParent))
	f:Hide()
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)

	f:SetBackdrop{
	  bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
	  edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
	  edgeSize = 16,
	  tile = true, tileSize = 16,
	  insets = {left = 4, right = 4, top = 4, bottom = 4}
	}

	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnHide', f.OnHide)
	f:SetFrameStrata('HIGH')
	f:SetFrameID(frameID)
	f:UpdateEvents()

	return f
end


--[[ Messages ]]--

function Frame:FRAME_SHOW(msg, frameID)
	if self:GetFrameID() == frameID then
		self:Show()
	end
end

function Frame:FRAME_HIDE(msg, frameID)
	if self:GetFrameID() == frameID then
		self:Hide()
	end
end

function Frame:FRAME_MOVE_START(msg, frameID)
	if self:GetFrameID() == frameID then
		self:StartMoving()
	end
end

function Frame:FRAME_MOVE_STOP(msg, frameID)
	if self:GetFrameID() == frameID then
		self:StopMovingOrSizing()
		self:SavePosition()
	end
end

function Frame:FRAME_POSITION_UPDATE(msg, frameID)
	if self:GetFrameID() == frameID then
		self:UpdatePosition()
	end
end

function Frame:FRAME_SCALE_UPDATE(msg, frameID, scale)
	if self:GetFrameID() == frameID then
		self:UpdateScale()
	end
end

function Frame:FRAME_OPACITY_UPDATE(msg, frameID, opacity)
	if self:GetFrameID() == frameID then
		self:UpdateOpacity()
	end
end

function Frame:FRAME_COLOR_UPDATE(msg, frameID, r, g, b, a)
	if self:GetFrameID() == frameID then
		self:UpdateBackdrop()
	end
end

function Frame:FRAME_BORDER_COLOR_UPDATE(msg, frameID, r, g, b, a)
	if self:GetFrameID() == frameID then
		self:UpdateBackdropBorder()
	end
end

function Frame:BAG_FRAME_UPDATE_SHOWN(msg, frameID)
	if self:GetFrameID() == frameID then
		self:Layout()
	end
end

function Frame:BAG_FRAME_UPDATE_LAYOUT(msg, frameID)
	if self:GetFrameID() == frameID then
		self:Layout()
	end
end

function Frame:ITEM_FRAME_SIZE_CHANGE(msg, frameID)
	if self:GetFrameID() == frameID then
		self:Layout()
	end
end


--[[ Frame Events ]]--

function Frame:OnShow()
	PlaySound('igBackPackOpen')
	
	self:UpdateEvents()
	self:UpdateLook()
end

function Frame:OnHide()
	PlaySound('igBackPackClose')
	
	if self:IsBankFrame() then
		self:CloseBankFrame()
	end
	
	self:UpdateEvents()
end


--[[ Update Methods ]]--

function Frame:UpdateEvents()
	self:UnregisterAllMessages()
	self:RegisterMessage('FRAME_SHOW')
	self:RegisterMessage('FRAME_HIDE')

	if self:IsVisible() then
		self:RegisterMessage('FRAME_MOVE_START')
		self:RegisterMessage('FRAME_MOVE_STOP')
		self:RegisterMessage('FRAME_POSITION_UPDATE')
		self:RegisterMessage('FRAME_SCALE_UPDATE')
		self:RegisterMessage('FRAME_OPACITY_UPDATE')
		self:RegisterMessage('FRAME_COLOR_UPDATE')
		self:RegisterMessage('FRAME_BORDER_COLOR_UPDATE')

		self:RegisterMessage('BAG_FRAME_UPDATE_SHOWN')
		self:RegisterMessage('BAG_FRAME_UPDATE_LAYOUT')
		self:RegisterMessage('ITEM_FRAME_SIZE_CHANGE')
	end
end

function Frame:UpdateLook()
	if not self:IsVisible() then return end

	self:UpdateScale()
	self:UpdateOpacity()
	self:UpdateBackdrop()
	self:UpdateBackdropBorder()
	self:UpdatePosition()
	self:UpdateShown()
	self:Layout()
end

--set the frame's scale, while maintaining the same frame position
function Frame:UpdateScale()
	local oldScale = self:GetScale()
	local newScale = self:GetFrameScale()
	local point, x, y = self:GetFramePosition()
	local ratio = newScale / oldScale

	self:SetScale(newScale)
	self:GetSettings():SetFramePosition(point, x/ratio, y/ratio)
end

--opacity
function Frame:UpdateOpacity()
	self:SetAlpha(self:GetFrameOpacity())
end

--position
function Frame:SavePosition()
	local point, x, y = self:GetRelativePosition()
	if point then
		self:GetSettings():SetFramePosition(point, x, y)
	end
end

--get a frame's position relative to its parent
function Frame:GetRelativePosition()
	local parent = self:GetParent()
	local w, h = parent:GetWidth(), parent:GetHeight()
	local x, y = self:GetCenter()
	local s = self:GetScale()
	if not (x and y) then return end

	w = w/s h = h/s

	local dx, dy
	local hHalf = (x > w/2) and 'RIGHT' or 'LEFT'
	if hHalf == 'RIGHT' then
		dx = self:GetRight() - w
	else
		dx = self:GetLeft()
	end

	local vHalf = (y > h/2) and 'TOP' or 'BOTTOM'
	if vHalf == 'TOP' then
		dy = self:GetTop() - h
	else
		dy = self:GetBottom()
	end

	return vHalf..hHalf, dx, dy
end

function Frame:UpdatePosition()
	self:ClearAllPoints()
	self:SetPoint(self:GetFramePosition())
end

--color
function Frame:UpdateBackdrop()
	self:SetBackdropColor(self:GetFrameBackdropColor())
end

function Frame:UpdateBackdropBorder()
	self:SetBackdropBorderColor(self:GetFrameBackdropBorderColor())
end

--visibility
function Frame:UpdateShown()
	if self:IsFrameShown() then
		self:Show()
	else
		self:Hide()
	end
end

function Frame:Layout()
	if not self:IsVisible() then return end

	local width, height = 0, 0

	--place the top left menu buttons
	local tlMenuButtons = self.tlMenuButtons or {}
	self.tlMenuButtons = tlMenuButtons

	for i, button in pairs(tlMenuButtons) do
		button:Hide()
		tlMenuButtons[i] = nil
	end

	if self:HasPlayerSelector() then
		table.insert(tlMenuButtons, self:GetPlayerSelector())
	end

	if self:HasBagFrame() then
		table.insert(tlMenuButtons, self:GetBagToggle())
	end

	if self:HasSearchFrame() then
		table.insert(tlMenuButtons, self:GetSearchToggle())
	end

	for i, button in ipairs(tlMenuButtons) do
		 button:ClearAllPoints()
		if i == 1 then
			button:SetPoint('TOPLEFT', self, 'TOPLEFT', 8, -8)
		else
			button:SetPoint('TOPLEFT', tlMenuButtons[i-1], 'TOPRIGHT', 4, 0)
		end
		button:Show()
	end

	--place the top right menu buttons
	local closeButton = self:GetCloseButton()
	closeButton:SetPoint('TOPRIGHT', -2, -2)
	
	local optionsToggle = self:GetOptionsToggle()
	optionsToggle:ClearAllPoints()
	optionsToggle:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -32, -8)
	height = height + optionsToggle:GetHeight() + 16

	--place the title frame
	local titleFrame = self:GetTitleFrame()
	titleFrame:ClearAllPoints()
	
	if #tlMenuButtons > 0 then
		titleFrame:SetPoint('LEFT', tlMenuButtons[#tlMenuButtons], 'RIGHT', 4, 0)
	else
		titleFrame:SetPoint('TOPLEFT', self, 'TOPLEFT', 8, -8)
	end
	
	titleFrame:SetPoint('RIGHT', optionsToggle, 'LEFT', -4, 0)
	titleFrame:SetHeight(20)
	
	--hurray magic numbers
	width = max(width, titleFrame:GetTextWidth() + 24 * #tlMenuButtons + 48 + 16)

	--place the search frame
	local searchFrame = self:HasSearchFrame() and self:GetSearchFrame()
	if searchFrame then
		searchFrame:ClearAllPoints()
		
		if #tlMenuButtons > 0 then
			searchFrame:SetPoint('LEFT', tlMenuButtons[#tlMenuButtons], 'RIGHT', 2, 0)
		else
			searchFrame:SetPoint('TOPLEFT', self, 'TOPLEFT', 8, -8)
		end
		
		searchFrame:SetPoint('RIGHT', optionsToggle, 'LEFT', -2, 0)
		searchFrame:SetHeight(28)
	end

	--place the bag frame
	local bagFrame = self:HasBagFrame() and self:GetBagFrame()
	if bagFrame and self:IsBagFrameShown() then
		width = max(bagFrame:GetWidth() + 16, width)
		height = height + bagFrame:GetHeight() + 4

		bagFrame:ClearAllPoints()
		bagFrame:SetPoint('TOPLEFT', tlMenuButtons[1], 'BOTTOMLEFT', 0, -4)
	end

	--place the itemFrame
	local itemFrame = self:GetItemFrame()
	width = max(itemFrame:GetWidth() + 16, width)
	height = height + itemFrame:GetHeight() + 4

	itemFrame:ClearAllPoints()
	if bagFrame and self:IsBagFrameShown() then
		itemFrame:SetPoint('TOPLEFT', bagFrame, 'BOTTOMLEFT', 0, -4)
	else
		if #tlMenuButtons > 0 then
			itemFrame:SetPoint('TOPLEFT', tlMenuButtons[1], 'BOTTOMLEFT', 0, -4)
		else
			itemFrame:SetPoint('TOPLEFT', titleFrame, 'BOTTOMLEFT', 2, -4)
		end
	end

	--place the moneyFrame
	local moneyFrame = self:HasMoneyFrame() and self:GetMoneyFrame()
	if moneyFrame then
		width = max(moneyFrame:GetWidth() + 16, width)
		height = height + 22

		moneyFrame:ClearAllPoints()
		moneyFrame:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', 0, 10)
	end

	--place the broker display frame
	local brokerDisplay = self:HasBrokerDisplay() and self:GetBrokerDisplay()
	if brokerDisplay then
		brokerDisplay:ClearAllPoints()
		brokerDisplay:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', 8, 10)

		if moneyFrame then
			brokerDisplay:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -(moneyFrame:GetWidth() + 4), 10)
		else
			brokerDisplay:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -8, 10)
		end
	end

	--adjust size
	self:SetWidth(width)
	self:SetHeight(height)
	self:SavePosition()
end


--[[ Special Bank Events ]]--

function Frame:IsBankFrame()
	return self:GetFrameID() == 'bank'
end

function Frame:CloseBankFrame()
	if Bagnon.PlayerInfo:AtBank() then
		CloseBankFrame()
	end
end


--[[ Frame Components ]]--

--close button
function Frame:GetCloseButton()
	if not self.closeButton then
		self.closeButton = self:CreateCloseButton()
	end
	return self.closeButton
end

function Frame:CreateCloseButton()
	local b = CreateFrame('Button', self:GetName() .. 'CloseButton', self, 'UIPanelCloseButton')
	b:SetScript('OnClick', function(self) self:GetParent():GetSettings():HideFrame(true) end) --force hide the frame

	return b
end

--search frame
function Frame:GetSearchFrame()
	if not self.searchFrame then
		self.searchFrame = self:CreateSearchFrame()
	end
	return self.searchFrame
end

function Frame:CreateSearchFrame()
	return Bagnon.SearchFrame:New(self:GetFrameID(), self)
end

function Frame:HasSearchFrame()
	return self:GetFrameID() ~= 'keys'
end

--search toggle
function Frame:GetSearchToggle()
	if not self.searchToggle then
		self.searchToggle = self:CreateSearchToggle()
	end
	return self.searchToggle
end

function Frame:CreateSearchToggle()
	return Bagnon.SearchToggle:New(self:GetFrameID(), self)
end

--bag frame
function Frame:GetBagFrame()
	if not self.bagFrame then
		self.bagFrame = self:CreateBagFrame()
	end
	return self.bagFrame
end

function Frame:CreateBagFrame()
	return Bagnon.BagFrame:New(self:GetFrameID(), self)
end

--bag toggle
function Frame:GetBagToggle()
	if not self.bagToggle then
		self.bagToggle = self:CreateBagToggle()
	end
	return self.bagToggle
end

function Frame:CreateBagToggle()
	return Bagnon.BagToggle:New(self:GetFrameID(), self)
end

--title frame
function Frame:GetTitleFrame()
	if not self.titleFrame then
		self.titleFrame = self:CreateTitleFrame()
	end
	return self.titleFrame
end

function Frame:CreateTitleFrame()
	--icky hardcoding
	if self:GetFrameID() == 'bank' then
		return Bagnon.TitleFrame:New(L.TitleBank, self:GetFrameID(), self)
	end
	if self:GetFrameID() == 'keys' then
		return Bagnon.TitleFrame:New(L.TitleKeys, self:GetFrameID(), self)
	end
	return Bagnon.TitleFrame:New(L.TitleBags, self:GetFrameID(), self)
end

--item frame
function Frame:GetItemFrame()
	if not self.itemFrame then
		self.itemFrame = self:CreateItemFrame()
	end
	return self.itemFrame
end

function Frame:CreateItemFrame()
	return Bagnon.ItemFrame:New(self:GetFrameID(), self)
end

--player selector
function Frame:GetPlayerSelector()
	if not self.playerSelector then
		self.playerSelector = self:CreatePlayerSelector()
	end
	return self.playerSelector
end

function Frame:CreatePlayerSelector()
	return Bagnon.PlayerSelector:New(self:GetFrameID(), self)
end

function Frame:HasPlayerSelector()
	return BagnonDB and true or false
end

--money frame
function Frame:GetMoneyFrame()
	if not self.moneyFrame then
		self.moneyFrame = self:CreateMoneyFrame()
	end
	return self.moneyFrame
end

function Frame:CreateMoneyFrame()
	return Bagnon.MoneyFrame:New(self:GetFrameID(), self)
end

function Frame:HasMoneyFrame()
	return self:GetSettings():FrameHasMoneyFrame()
end

--broker display
function Frame:GetBrokerDisplay()
	if not self.brokerDisplay then
		self.brokerDisplay = self:CreateBrokerDisplay()
	end
	return self.brokerDisplay
end

function Frame:CreateBrokerDisplay()
	return Bagnon.BrokerDisplay:New(1, self:GetFrameID(), self)
end

function Frame:HasBrokerDisplay()
	return self:GetSettings():FrameHasBrokerDisplay()
end

--options toggle
function Frame:GetOptionsToggle()
	if not self.optionsToggle then
		self.optionsToggle = self:CreateOptionsToggle()
	end
	return self.optionsToggle
end

function Frame:CreateOptionsToggle()
	return Bagnon.OptionsToggle:New(self:GetFrameID(), self)
end


--[[ Frame Settings Access ]]--

function Frame:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
		self:UpdateLook()
	end
end

function Frame:GetFrameID()
	return self.frameID
end

function Frame:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end

function Frame:GetFrameScale()
	return self:GetSettings():GetFrameScale()
end

function Frame:GetFrameOpacity()
	return self:GetSettings():GetFrameOpacity()
end

function Frame:GetFramePosition()
	return self:GetSettings():GetFramePosition()
end

function Frame:IsFrameShown()
	return self:GetSettings():IsFrameShown()
end

function Frame:IsBagFrameShown()
	return self:GetSettings():IsBagFrameShown()
end

function Frame:GetFrameBackdropColor()
	return self:GetSettings():GetFrameColor()
end

function Frame:GetFrameBackdropBorderColor()
	return self:GetSettings():GetFrameBorderColor()
end

function Frame:HasBagFrame()
	return self:GetSettings():FrameHasBagFrame()
end

function Frame:HasBrokerDisplay()
	return self:GetSettings():FrameHasDBOFrame()
end