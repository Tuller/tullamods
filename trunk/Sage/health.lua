--[[
	Sage\healthBar.lua
		Handles healthBars
		
	MobHealth Versions Supported:
		Telos' MobHealth (preferred)
		MobInfo2
		
	TODO:
		MobInfo3 support
--]]

SageHealth = CreateFrame('StatusBar')
local StatusBar_mt = {__index = SageHealth}

local bars = {}

--[[ Local Functions ]]--

--update's the bar's color based on how much health the bar's parent unit has
local function UpdateHealthColor(bar, value)
	if not value then return end
	
	local r, g
	local min, max = bar:GetMinMaxValues()
	
	if (value < min) or (value > max) then
		return
	end
	
	if max - min > 0 then
		value = (value - min) / (max - min)
	else
		value = 0
	end
	
	if value > 0.5 then
		r = (1.0 - value) * 2
		g = 1.0
	else
		r = 1.0
		g = value * 2
	end

	bar:SetStatusBarColor(r, g, 0)
end

local function OnValueChanged()
	if not this.hasDebuff then
		UpdateHealthColor(this, this:GetValue())
	end
end

local function OnShow() this:UpdateAll() end

--[[ Setup the GetUnitHealth function based on which MobInfo addon is loaded, if any ]]--

local GetUnitHealth
if MobHealth3 then
	GetUnitHealth = function(unit)
		local value = UnitHealth(unit)
		local maxValue = UnitHealthMax(unit)

		if maxValue == 100 then
			value, maxValue = MobHealth3:GetUnitHealth(unit)
		end
		return value, maxValue
	end
elseif MobHealthFrame then
	local GetMobHealth;

	if MobHealth_PPP then
		--MobInfo2
		GetMobHealth = function(unit)
			local ppp = MobHealth_PPP(UnitName(unit) .. ":" .. UnitLevel(unit))
			if ppp and ppp ~= 0 then
				return math.floor(UnitHealth(unit) * ppp + 0.5), math.floor(UnitHealthMax(unit) * ppp + 0.5)
			end
			return UnitHealth(unit), UnitHealthMax(unit)
		end
	else
		--Telos' Mobhealth
		GetMobHealth = function(unit)
			local index = UnitName(unit) .. ":" .. UnitLevel(unit)
			local unitHealth = UnitHealth(unit)
			if MobHealthDB[index] then
				local _, _, pts, pct = string.find(MobHealthDB[index], "^(%d+)/(%d+)$")
				pts = tonumber(pts)
				pct = tonumber(pct)
				if pts and pct and pct ~= 0 then
					return math.floor(UnitHealth(unit) * (pts / pct) + 0.5), math.floor(UnitHealthMax(unit) * (pts / pct) + 0.5)
				end
			end
			return UnitHealth(unit), UnitHealthMax(unit)
		end
	end
	
	GetUnitHealth = function(unit)
		local value = UnitHealth(unit)
		local maxValue = UnitHealthMax(unit)

		if maxValue == 100 then
			value, maxValue = GetMobHealth(unit)
		end
		return value, maxValue
	end
else
	--default case
	GetUnitHealth = function(unit) return UnitHealth(unit), UnitHealthMax(unit) end
end

function SageHealth.Create(parent, id)
	local bar = CreateFrame("StatusBar", nil, parent)
	setmetatable(bar, StatusBar_mt)
	
	bar.id = id or parent.id
	bar:SetAlpha(parent:GetAlpha())

	bar.bg = bar:CreateTexture(nil, "BACKGROUND")
	bar.bg:SetAllPoints(bar)
	bar.bg:SetVertexColor(0.6, 0.1, 0.1, 0.6)

	bar.text = bar:CreateFontString(nil, "OVERLAY")
	bar.text:SetPoint('CENTER', bar)
	bar.text:SetFontObject(SageBarFont)
	--bar.text:SetAllPoints(bar)
	
	if Sage.ShowingText() then 
		bar.text:Show() 
	else
		bar.text:Hide() 
	end

	bars[bar.id] = bar

	bar:SetScript("OnValueChanged", OnValueChanged)
	bar:SetScript("OnShow", OnShow)
	bar:UpdateTexture()
	bar:UpdateAll()
			
	return bar
end

function SageHealth:UpdateAll()
	self:Update()
	if Sage.ColoringHealthOnDebuff() then
		self:UpdateDebuff()
	end
end

function SageHealth:Update()
	local unit = self.id
	local value, maxValue = GetUnitHealth(unit)
	self:SetMinMaxValues(0, maxValue)
	self:SetValue(value)
	
	--Change displayed text depending on if disconnected/dead/ghost/etc
	local text = self.text
	if text:IsShown() then
		if UnitIsDead(unit) then
			text:SetText(SAGE_DEAD)
		elseif UnitIsGhost(unit) then
			text:SetText(SAGE_GHOST)
		elseif not UnitIsConnected(unit) then
			text:SetText(SAGE_OFFLINE)
		else
			self:UpdateText(value, maxValue)
		end
	end
end

function SageHealth:UpdateDebuff()
	local unit = self.id
	self.hasDebuff = nil
	--colors the healthbar based on what the first debuff you have is
	if UnitCanAssist('player', unit) and Sage.ColoringHealthOnDebuff() then
		local sets = Sage.GetFrameSets(unit)
		local showCurable = (UnitCanAssist("player", unit) and sets and sets.showCurable)
		local debuffType = select(5, UnitDebuff(unit, 1, showCurable))

		if debuffType then
			self.hasDebuff = true
			local color = DebuffTypeColor[debuffType]
			self:SetStatusBarColor(color.r, color.g, color.b)
			return
		end
	end	
	--color by health amount if not debuffed
	UpdateHealthColor(self, self:GetValue())
end

SageHealth.UpdateTexture = SageStatusBar.UpdateTexture

function SageHealth:UpdateText(min, max)
	SageStatusBar.SetText(self.text, min, max, Sage.GetHealthTextMode())
end

--[[ Config Functions ]]--

--sets whether to always show health text or not
function SageHealth:ShowText(enable)
	local text = self.text
	if enable then
		text:Show()
		self:Update()
	else
		text:Hide()
	end
end

--sets whether to color health when debuffed or not
function SageHealth.SetColorOnDebuff(enable)
	if enable then
		SageHealth.ForAll(SageHealth.UpdateDebuff)
	else
		SageHealth.ForAll(function(bar) bar.hasDebuff = nil; UpdateHealthColor(bar, bar:GetValue()) end)
	end
end

function SageHealth.ForAll(action, ...)
	for _, bar in pairs(bars) do
		action(bar, ...)
	end
end

function SageHealth.Get(id)
	return bars[id]
end

--[[ Function Overrides ]]--

--an override make all healthbars smooth colored
HealthBar_OnValueChanged = function(v) UpdateHealthColor(this, v) end

--[[ Events - This Function also upadates the health percentage display of SInfo ]]--

local function OnEvent(_, _, unit)
	local bar = SageHealth.Get(unit)
	if bar and bar:IsVisible() then
		bar:Update()
	end
end
BVent:AddAction('UNIT_HEALTH', OnEvent)
BVent:AddAction('UNIT_MAXHEALTH', OnEvent)

local function OnBuffEvent(_, _, unit)
	local bar = SageHealth.Get(unit)
	if bar and bar:IsVisible() then
		bar:UpdateDebuff()
	end
end
BVent:AddAction('UNIT_AURA', OnBuffEvent)