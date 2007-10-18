--[[
	Combuctor\moneyFrame.lua
		Money frames for Combuctor windows
--]]

CombuctorMoney = CreateFrame("Button")
local Money_MT = {__index = CombuctorMoney}
local currentPlayer = UnitName("player")


--[[ Constructor ]]--

local function OnShow(self) self:OnShow() end
local function OnClick(self, arg1) self:GetParent():OnClick(arg1) end
local function OnEnter(self) self:GetParent():OnEnter() end
local function OnLeave(self) self:GetParent():OnLeave() end

local lastID = 0
local function MoneyFrame_Create()
	local name = format("CombuctorMoney%d", lastID)
	local frame = setmetatable(CreateFrame("Frame", name, nil, "SmallMoneyFrameTemplate"), Money_MT)
	frame:SetScript("OnShow", OnShow)

	local clickFrame = CreateFrame("Button", nil, frame)
	clickFrame:SetFrameLevel(frame:GetFrameLevel() + 2)
	clickFrame:SetAllPoints(frame)
	clickFrame:SetScript("OnClick", OnClick)
	clickFrame:SetScript("OnEnter", OnEnter)
	clickFrame:SetScript("OnLeave", OnLeave)

	lastID = lastID + 1

	return frame
end

function CombuctorMoney:Create(parent)
	local frame = MoneyFrame_Create()
	frame:SetParent(parent)
	frame:SetFrameLevel(1)
	frame:Update()

	return frame
end

function CombuctorMoney:Update()
	local parent = self:GetParent()
	if parent then
		local player = parent:GetPlayer()
		if player == currentPlayer or not BagnonDB then
			MoneyFrame_Update(self:GetName(), GetMoney())
		else
			MoneyFrame_Update(self:GetName(), BagnonDB:GetMoney(player))
		end
	end
end

--frame events
function CombuctorMoney:OnClick(button)
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

function CombuctorMoney:OnEnter()
	if BagnonDB then
		GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText(format("Total on %s", GetRealmName()))

		local money = 0
		for player in BagnonDB:GetPlayers() do
			money = money + BagnonDB:GetMoney(player)
		end

		SetTooltipMoney(GameTooltip, money)
		GameTooltip:Show()
	end
end

function CombuctorMoney:OnLeave()
	GameTooltip:Hide()
end

function CombuctorMoney:OnShow()
	self:Update()
end