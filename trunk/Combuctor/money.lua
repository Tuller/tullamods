--[[
	Combuctor\moneyFrame.lua
		Money frames for Combuctor windows
--]]

CombuctorMoneyFrame = {}
local L = LibStub('AceLocale-3.0'):GetLocale('Combuctor')

function CombuctorMoneyFrame:Create(parent)
	local frame = CreateFrame('Frame', parent:GetName() .. 'MoneyFrame', parent, 'SmallMoneyFrameTemplate')
	frame:SetScript('OnShow', self.Update)
	frame.Update = self.Update
	frame:Update()

	local click = CreateFrame('Button', nil, frame)
	click:SetFrameLevel(frame:GetFrameLevel() + 3)
	click:SetAllPoints(frame)

	click:SetScript('OnClick', self.OnClick)
	click:SetScript('OnEnter', self.OnEnter)
	click:SetScript('OnLeave', self.OnLeave)

	return frame
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
		GameTooltip:SetFormattedText(L.TotalOnRealm, GetRealmName())

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