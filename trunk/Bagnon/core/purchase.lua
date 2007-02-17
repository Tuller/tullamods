--[[
	vBagnon\purchaseFrame.lua
		A frame for purchasing bank bag slots
--]]

local used = {}

BagnonPurchase = CreateFrame('Frame')
local Purchase_mt = {__index = BagnonPurchase}


--[[ Local Functions ]]--

local function BuySlot()
	if not StaticPopupDialogs['CONFIRM_BUY_BANK_SLOT_BANKNON'] then
		StaticPopupDialogs['CONFIRM_BUY_BANK_SLOT_BANKNON'] = {
			text = TEXT(CONFIRM_BUY_BANK_SLOT),
			button1 = TEXT(YES),
			button2 = TEXT(NO),

			OnAccept = function() PurchaseSlot() end,

			OnShow = function() MoneyFrame_Update(this:GetName().. 'MoneyFrame', GetBankSlotCost(GetNumBankSlots())) end,

			hasMoneyFrame = 1,
			timeout = 0,
			hideOnEscape = 1,
		}
	end

	PlaySound('igMainMenuOption')
	StaticPopup_Show('CONFIRM_BUY_BANK_SLOT_BANKNON')
end

local function PurchaseFrame_Create(lastCreated)
	local name = 'BagnonPurchase' .. lastCreated

	local frame = CreateFrame('Frame', 'BagnonPurchase' .. lastCreated)
	setmetatable(frame, Purchase_mt)
	
	frame:SetWidth(164); frame:SetHeight(22)

	local purchaseButton = CreateFrame('Button', name .. 'Purchase', frame, 'UIPanelButtonTemplate')
	purchaseButton:SetWidth(124); purchaseButton:SetHeight(22)
	purchaseButton:SetPoint('LEFT', frame)
	purchaseButton:SetScript('OnClick', BuySlot)
	purchaseButton:SetText(BANKSLOTPURCHASE)
	
	local costFrame = CreateFrame('Frame', name .. 'Cost', frame, 'SmallMoneyFrameTemplate')
	costFrame:SetPoint('LEFT', purchaseButton, 'RIGHT', 2, 0)

	--super hack extreme, need to settype which for some reason takes this as an arg
	local oldthis = this
	this = costFrame
	MoneyFrame_SetType('STATIC')
	this = oldthis

	return frame
end


--[[ Constructor/Destructor ]]--

function BagnonPurchase.New(parent)
	local frame = TPool.Get('BagnonPurchase', PurchaseFrame_Create)
	BagnonLib.Attach(frame, parent)
	
	frame:UpdateSlotCost()
	frame:UpdateVisibility()
	parent.sizeChanged = true
	
	used[frame] = true
	return frame
end

function BagnonPurchase:Release()
	used[frame] = nil
	TPool.Release(self, 'BagnonPurchase')
end


--[[ Update Functions ]]--

function BagnonPurchase:UpdateVisibility(update)
	local parent = self:GetParent()

	local wasVisible = self:IsShown()
	local full = select(2, GetNumBankSlots())
	local cached = not(BagnonLib.AtBank() and parent:GetPlayer() == UnitName('player'))
	local bagsShown = parent:GetBagFrame():BagsShown()
	local layout
	
	--hide if slots cannot be purchased, or if viewing a cached bank, or if told to do so, show otherwise
	if full or cached or not bagsShown then
		self:Hide()
		layout = wasVisible
	else
		self:Show()
		layout = not wasVisible
	end

	if layout and update then
		parent.sizeChanged = true
		parent:Layout()
	end
end

function BagnonPurchase:UpdateSlotCost()
	local name = self:GetName() .. 'Cost'
	local costFrame = getglobal(costFrameName)
	local cost = GetBankSlotCost(GetNumBankSlots())

	if GetMoney() >= cost then
		SetMoneyFrameColor(name, 1, 1, 1)
	else
		SetMoneyFrameColor(name, 1, 0.1, 0.1)
	end
	MoneyFrame_Update(name, cost)
end


--[[ Events ]]--

local function ForAll_UpdateSlotCost()
	for frame in pairs(used) do
		frame:UpdateSlotCost()
	end
end
BVent:AddAction('PLAYER_MONEY', ForAll_UpdateSlotCost)
BVent:AddAction('PLAYERBANKBAGSLOTS_CHANGED', ForAll_UpdateSlotCost)

local function ForAll_UpdateVisibility()
	for frame in pairs(used) do
		frame:UpdateVisibility(true)
	end
end
BVent:AddAction('BANKFRAME_OPENED', ForAll_UpdateVisibility)
BVent:AddAction('BANKFRAME_CLOSED', ForAll_UpdateVisibility)