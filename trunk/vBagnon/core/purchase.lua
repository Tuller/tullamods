--[[
	vBagnon\purchaseFrame.lua
		A frame for purchasing bank bag slots
--]]

local usedList = {}

BagnonPurchase = CreateFrame('Frame')
local Purchase_mt = {__index = BagnonPurchase}

--[[ Local Functions ]]--

local function BuySlot()
	if not StaticPopupDialogs["CONFIRM_BUY_BANK_SLOT_BANKNON"] then
		StaticPopupDialogs["CONFIRM_BUY_BANK_SLOT_BANKNON"] = {
			text = TEXT(CONFIRM_BUY_BANK_SLOT),
			button1 = TEXT(YES),
			button2 = TEXT(NO),

			OnAccept = function() PurchaseSlot() end,

			OnShow = function() MoneyFrame_Update(this:GetName().."MoneyFrame", GetBankSlotCost(GetNumBankSlots())) end,

			hasMoneyFrame = 1,
			timeout = 0,
			hideOnEscape = 1,
		}
	end
	PlaySound("igMainMenuOption")
	StaticPopup_Show("CONFIRM_BUY_BANK_SLOT_BANKNON")
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
	local oldthis = this
	this = costFrame
	MoneyFrame_SetType("STATIC")
	this = oldthis

	return frame
end

--[[ Constructor/Destructor ]]--

function BagnonPurchase.Create(parent)
	local frame = TPool.Get('BagnonPurchase', PurchaseFrame_Create)
	Bagnon_AttachToFrame(frame, parent)
	
	frame:UpdateSlotCost()
	
	usedList[frame.id] = frame
	return frame
end

function BagnonPurchase:Release()
	usedList[self.id] = nil
	TPool.Release(self, 'BagnonPurchase')
end

--[[ Update Functions ]]--

function BagnonPurchase:UpdateVisibility(hide, dontUpdate)
	local parent = self:GetParent()
	if parent then
		local wasVisible = self:IsShown()
		local full = select(2, GetNumBankSlots())
		local bagFrame = parent.bagFrame

		if full or hide or not(Bagnon_PlayerAtBank() and parent:GetPlayer() == UnitName('player')) then 
			self:Hide()
			if wasVisible and not dontUpdate then
				parent:ForceLayout()
			end
		elseif not(bagFrame) or bagFrame.shown then
			self:Show()
			if not(wasVisible or dontUpdate)then
				parent:ForceLayout()
			end
		else
			self:Hide()
			if wasVisible and not dontUpdate then
				parent:ForceLayout()
			end
		end
	end
end

function BagnonPurchase:UpdateSlotCost()
	local costFrameName = self:GetName() .. 'Cost'
	local costFrame = getglobal(costFrameName)
	local cost = GetBankSlotCost(GetNumBankSlots())

	if GetMoney() >= cost then
		SetMoneyFrameColor(costFrameName, 1, 1, 1)
	else
		SetMoneyFrameColor(costFrameName, 1, 0.1, 0.1)
	end
	MoneyFrame_Update(costFrameName, cost)
	
	self:UpdateVisibility()
end

--[[ Events ]]--

local function ForAll_UpdateSlotCost()
	for _, frame in pairs(usedList) do
		frame:UpdateSlotCost()
	end
end
BEvent:AddAction('PLAYER_MONEY', ForAll_UpdateSlotCost)
BEvent:AddAction('PLAYERBANKBAGSLOTS_CHANGED', ForAll_UpdateSlotCost)

local function ForAll_UpdateVisibility()
	for _, frame in pairs(usedList) do
		frame:UpdateVisibility()
	end
end
BEvent:AddAction('BANKFRAME_OPENED', ForAll_UpdateVisibility)
BEvent:AddAction('BANKFRAME_CLOSED', ForAll_UpdateVisibility)