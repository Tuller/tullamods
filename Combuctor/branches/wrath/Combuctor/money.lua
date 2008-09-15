--[[
	Combuctor\moneyFrame.lua
		Money frames for Combuctor windows
--]]

local CombuctorMoneyFrame = Combuctor:CreateClass('Frame')
Combuctor.MoneyFrame = CombuctorMoneyFrame

local L = LibStub('AceLocale-3.0'):GetLocale('Combuctor')

function CombuctorMoneyFrame:New(parent)
	local f = self:Bind(CreateFrame('Frame', parent:GetName() .. 'MoneyFrame', parent, 'SmallMoneyFrameTemplate'))
	f:SetScript('OnShow', self.Update)
	f:Update()

	local click = CreateFrame('Button', f:GetName() .. 'Click', f)
	click:SetFrameLevel(f:GetFrameLevel() + 3)
	click:SetAllPoints(f)

	click:SetScript('OnClick', self.OnClick)
	click:SetScript('OnEnter', self.OnEnter)
	click:SetScript('OnLeave', self.OnLeave)

	return f
end

function CombuctorMoneyFrame:Update()
	local player = self:GetParent():GetPlayer()
	if player == UnitName('player') or not BagnonDB then
		MoneyFrame_Update(self:GetName(), GetMoney())
	else
		MoneyFrame_Update(self:GetName(), BagnonDB:GetMoney(player))
	end
end

--frame events
function CombuctorMoneyFrame:OnClick()
	local parent = self:GetParent()
	local name = parent:GetName()

	if MouseIsOver(getglobal(name .. 'GoldButton')) then
		OpenCoinPickupFrame(COPPER_PER_GOLD, MoneyTypeInfo[parent.moneyType].UpdateFunc(), parent)
		parent.hasPickup = 1
	elseif MouseIsOver(getglobal(name .. 'SilverButton')) then
		OpenCoinPickupFrame(COPPER_PER_SILVER, MoneyTypeInfo[parent.moneyType].UpdateFunc(), parent)
		parent.hasPickup = 1
	elseif MouseIsOver(getglobal(name .. 'CopperButton')) then
		OpenCoinPickupFrame(1, MoneyTypeInfo[parent.moneyType].UpdateFunc(), parent)
		parent.hasPickup = 1
	end
end

function CombuctorMoneyFrame:OnEnter()
	if BagnonDB then
		GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
		GameTooltip:SetText(format(L.TotalOnRealm, GetRealmName()))

		local money = 0
		for player in BagnonDB:GetPlayers() do
			money = money + BagnonDB:GetMoney(player)
		end

		SetTooltipMoney(GameTooltip, money)
		GameTooltip:Show()
	end
end

function CombuctorMoneyFrame:OnLeave()
	GameTooltip:Hide()
end