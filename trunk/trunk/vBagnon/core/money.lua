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

function BagnonMoney.Create(parent)
	local frame = TPool.Get('BagnonMoneyFrame', MoneyFrame_Create)
	Bagnon_AttachToFrame(frame, parent)
	
	return frame
end

function BagnonMoney:Release()
	TPool.Release(self, 'BagnonMoneyFrame')
end

--[[ OnX ]]--

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

function BagnonMoney.OnEnter()
	return
end

function BagnonMoney.OnLeave()
	GameTooltip:Hide()
end

function BagnonMoney:OnShow()
	local parent = self:GetParent()
	if parent and parent:GetPlayer() == currentPlayer then
		MoneyFrame_UpdateMoney()
	end
end