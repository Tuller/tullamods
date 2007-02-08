--[[
	Sage\manaBar.lua
		Handles mana/rage/energy/focus bars
--]]

SageMana = CreateFrame('StatusBar')
local StatusBar_mt = {__index = SageMana}

local bars = {}

local function OnShow() this:Update() end


--[[ Usable Functions ]]--

function SageMana.Create(parent, id)
	local bar = CreateFrame('StatusBar', nil, parent)
	setmetatable(bar, StatusBar_mt)
	
	bar.id = id or parent.id
	bar:SetAlpha(parent:GetAlpha())
	bars[bar.id] = bar

	bar.bg = bar:CreateTexture(nil, "BACKGROUND")
	bar.bg:SetAllPoints(bar)

	bar.text = bar:CreateFontString(nil ,"OVERLAY")
	bar.text:SetPoint('CENTER', bar)
--	bar.text:SetAllPoints(bar)
	bar.text:SetFontObject(SageBarFontSmall)
	if not Sage.ShowingText() then 
		bar.text:Hide() 
	end
	
	bar:SetScript('OnShow', OnShow)
	bar:UpdateTexture()
	bar:Update()

	return bar
end

function SageMana:Update()
	local unit = self.id
	local maxMana = UnitManaMax(unit)
	self:SetMinMaxValues(0, maxMana)

	--set grey if disconnected
	if not UnitIsConnected(unit) then
		self:SetValue(maxMana)
		self:SetStatusBarColor(0.5, 0.5, 0.5)
		self.text:SetText("")
	else
		--update mana bar color
		local info = ManaBarColor[UnitPowerType(unit)]
		
		self:SetStatusBarColor(info.r, info.g, info.b)
		self.bg:SetVertexColor(info.r * 0.5, info.g * 0.5, info.b * 0.5, 0.6)

		local mana = UnitMana(unit)
		self:SetValue(mana)
		self:UpdateText()
	end
end

SageMana.UpdateTexture = SageStatusBar.UpdateTexture

function SageMana:UpdateText()
	SageStatusBar.SetText(self.text, UnitMana(self.id), UnitManaMax(self.id), Sage.GetManaTextMode())
end


--[[ Config Functions ]]--

function SageMana:ShowText(enable)
	local text = self.text
	if enable then
		text:Show()
		self:UpdateText()
	else
		text:Hide()
	end
end

--[[ Utility Functions ]]--

function SageMana.ForAll(action, ...)
	for _,bar in pairs(bars) do
		action(bar, ...)
	end
end

function SageMana.Get(id) 
	return bars[id] 
end

--[[ Events ]]--

local function OnEvent(_, _, unit)
	local bar = SageMana.Get(unit)
	if bar and bar:IsVisible() then
		bar:Update()
	end
end
BVent:AddAction('UNIT_MANA', OnEvent)
BVent:AddAction('UNIT_RAGE', OnEvent)
BVent:AddAction('UNIT_FOCUS', OnEvent)
BVent:AddAction('UNIT_ENERGY', OnEvent)
BVent:AddAction('UNIT_MAXMANA', OnEvent)
BVent:AddAction('UNIT_MAXRAGE', OnEvent)
BVent:AddAction('UNIT_MAXFOCUS', OnEvent)
BVent:AddAction('UNIT_MAXENERGY', OnEvent)
BVent:AddAction('UNIT_DISPLAYPOWER', OnEvent)