--[[
	vBagnon\moneyFrame.lua
		Money frames for Bagnon windows
--]]

BagnonMoney = CreateFrame('Button')
local Money_mt = {__index = BagnonMoney}

local currentPlayer = UnitName('player')


--[[ Constructor ]]--

local function OnShow()  this:OnShow() end
local function OnClick() this:GetParent():OnClick(arg1) end
local function OnEnter() this:GetParent():OnEnter() end
local function OnLeave() this:GetParent():OnLeave() end

local function MoneyFrame_Create(lastCreated)
	local frame = CreateFrame('Frame', 'BagnonMoney' .. lastCreated, nil, 'SmallMoneyFrameTemplate')
	setmetatable(frame, Money_mt)
	frame:SetScript('OnShow', OnShow)

	local clickFrame = CreateFrame('Button', nil, frame)
	clickFrame:SetFrameLevel(frame:GetFrameLevel() + 2)
	clickFrame:SetAllPoints(frame)
	clickFrame:SetScript('OnClick', OnClick)
	clickFrame:SetScript('OnEnter', OnEnter)
	clickFrame:SetScript('OnLeave', OnLeave)

	return frame
end


--[[ Constructor/'Destructor' ]]--

function BagnonMoney.Get(parent)
	local frame = TPool.Get('BagnonMoneyFrame', MoneyFrame_Create)
	frame:Update()
	BagnonLib.Attach(frame, parent)
	
	return frame
end

function BagnonMoney:Release()
	TPool.Release(self, 'BagnonMoneyFrame')
end


--[[ Update ]]--

function BagnonMoney:Update()
	local parent = self:GetParent()
	if parent then
		local player = parent:GetPlayer()
		if player == currentPlayer or not BagnonDB then
			MoneyFrame_Update(self:GetName(), GetMoney())
		else
			MoneyFrame_Update(self:GetName(), BagnonDB.GetMoney(player))
		end
	end
end


--[[ Frame Events ]]--

function BagnonMoney:OnClick(button)
	local name = self:GetName()

	if MouseIsOver(getglobal(name .. "GoldButton")) then
		OpenCoinPickupFrame(COPPER_PER_GOLD, MoneyTypeInfo[self.moneyType].UpdateFunc(), self)
		self.hasPickup = 1
	elseif MouseIsOver(getglobal(name .. "SilverButton")) then
		OpenCoinPickupFrame(COPPER_PER_SILVER, MoneyTypeInfo[self.moneyType].UpdateFunc(), self)
		self.hasPickup = 1
	elseif MouseIsOver(getglobal(name .. "CopperButton")) then
		OpenCoinPickupFrame(1, MoneyTypeInfo[self.moneyType].UpdateFunc(), self)
		self.hasPickup = 1
	end
end

--Alters the tooltip of bagnon moneyframes to show total gold across all characters on the current realm
function BagnonMoney:OnEnter()
	if BagnonDB and BagnonSettings.showTooltips then
		GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
		GameTooltip:SetText(format(BAGNON_FOREVER_MONEY_ON_REALM, GetRealmName()))

		local money = 0
		for player in BagnonDB.GetPlayers() do
			money = money + BagnonDB.GetMoney(player)
		end

		SetTooltipMoney(GameTooltip, money)
		GameTooltip:Show()
	end
end

function BagnonMoney:OnLeave()
	GameTooltip:Hide()
end

function BagnonMoney:OnShow()
	self:Update()
end