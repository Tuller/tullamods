--[[
	vBagnon\purchaseFrame.lua
		A frame for purchasing bank bag slots
--]]

BagnonPurchase = CreateFrame('Frame')
local Purchase_mt = {__index = BagnonPurchase}
local lastCreated = 0

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

local function PurchaseFrame_Create()
	local name = format('BagnonPurchase%s', lastCreated)
	local frame = CreateFrame('Frame', name)
	setmetatable(frame, Purchase_mt)

	frame:SetWidth(164); frame:SetHeight(22)

	local button = CreateFrame('Button', name .. 'Purchase', frame, 'UIPanelButtonTemplate')
	button:SetWidth(124); button:SetHeight(22)
	button:SetPoint('LEFT', frame)
	button:SetScript('OnClick', BuySlot)
	button:SetText(BANKSLOTPURCHASE)

	local cost = CreateFrame('Frame', name .. 'Cost', frame, 'SmallMoneyFrameTemplate')
	cost:SetPoint('LEFT', button, 'RIGHT', 2, 0)

	--super hack extreme, need to settype which for some reason takes this as an arg
	local oldthis = this
	this = cost
	MoneyFrame_SetType('STATIC')
	this = oldthis
	
	frame:SetScript('OnEvent', function(self) self:UpdateSlotCost() end)
	
	lastCreated = lastCreated + 1

	return frame
end


--[[ Constructor/Destructor ]]--

function BagnonPurchase.New(parent)
	local frame = PurchaseFrame_Create()
	BagnonUtil:Attach(frame, parent)

	frame:UpdateSlotCost()
	frame:RegisterEvent('PLAYER_MONEY')
	frame:RegisterEvent('PLAYERBANKBAGSLOTS_CHANGED')

	return frame
end


--[[ Update Functions ]]--

function BagnonPurchase:UpdateShown()
	local frame = self:GetParent():GetParent()
	local bagFrame = self:GetParent()
	local full = select(2, GetNumBankSlots())
	local atBank = BagnonUtil:AtBank()
	local cached = frame:GetPlayer() ~= UnitName('player')

	--hide if slots cannot be purchased, or if viewing a cached bank, or if told to do so, show otherwise
	if atBank and bagFrame.shown and not(cached or full) then
		self:Show()
	else
		self:Hide()
	end
end

function BagnonPurchase:UpdateSlotCost()
	local name = self:GetName() .. 'Cost'
	local costFrame = getglobal(name)
	local cost = GetBankSlotCost(GetNumBankSlots())

	if GetMoney() >= cost then
		SetMoneyFrameColor(name, 1, 1, 1)
	else
		SetMoneyFrameColor(name, 1, 0.1, 0.1)
	end
	MoneyFrame_Update(name, cost)
end