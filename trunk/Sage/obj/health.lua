--[[
	SageHealth
		Handles healthbars

	MobHealth Versions Supported:
		Telos" MobHealth (preferred)
		MobInfo2
		MobInfo3
--]]

SageHealth = CreateFrame("StatusBar")
local Bar_MT = {__index = SageHealth}
local L = SAGE_LOCALS


--[[ Local Functions ]]--

--update"s the bar"s color based on how much health the bar"s parent unit has
local function Bar_UpdateHealthColor(self, value)
	if not value then return end

	local r, g
	local min, max = self:GetMinMaxValues()

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

	self:SetStatusBarColor(r, g, 0)
end

function HealthBar_OnValueChanged(value)
	Bar_UpdateHealthColor(this, value) 
end


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
			local ppp = MobHealth_PPP(format("%s:%s", UnitName(unit), UnitLevel(unit)))
			if ppp and ppp ~= 0 then
				return floor(UnitHealth(unit) * ppp + 0.5), floor(UnitHealthMax(unit) * ppp + 0.5)
			end
			return UnitHealth(unit), UnitHealthMax(unit)
		end
	else
		--Telos" Mobhealth
		GetMobHealth = function(unit)
			local index = format("%s:%s", UnitName(unit), UnitLevel(unit))
			local health, healthMax = UnitHealth(unit), UnitHealthMax(unit)
			if MobHealthDB[index] then
				local pts, pct = MobHealthDB[index]:match("^(%d+)/(%d+)$")
				if(pts ~= "" and pct ~= "") then
					local ppp = tonumber(pts) / tonumber(pct)
					return floor(health * ppp + 0.5), floor(healthMax * ppp + 0.5)
				end
			end
			return health, healthMax
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
	GetUnitHealth = function(unit)
		return UnitHealth(unit), UnitHealthMax(unit)
	end
end


--[[ Frame Events ]]--

local function Bar_OnValueChanged(self, value)
	if not self.debuff then
		self:UpdateHealthColor(value)
	end
end

local function Bar_OnShow(self)
	self:UpdateAll()
end


--[[ Usable Stuff ]]--

function SageHealth:Create(parent, id)
	local bar = setmetatable(SageBar:Create(parent, id, SageFont:GetBarFont()), Bar_MT)
	bar:SetStatusBarColor(0, 1, 0)
	bar.bg:SetVertexColor(0.6, 0, 0, 0.6)

	bar:SetScript("OnValueChanged", Bar_OnValueChanged)
	bar:SetScript("OnShow", Bar_OnShow)
	bar:UpdateAll()
	bar:UpdateTexture()

	if(not self.bars) then self.bars = {} end
	self.bars[bar.id] = bar

	return bar
end

function SageHealth:UpdateAll()
	self:Update()
	self:UpdateDebuff()
end

function SageHealth:Update()
	local unit = self.id
	local value, maxValue = GetUnitHealth(unit)
	self:SetMinMaxValues(0, maxValue)
	self:SetValue(value)
	
	--low health fading
	if(value > 0 and value/maxValue <= 0.4 and (UnitIsUnit(unit, "player") or UnitInParty(unit))) then
		if(self.critical) then
			self.bg.flashTimer = 0
		else
			self.critical = true
			self.bg:SetVertexColor(0.6, 0, 0, 1)
			UIFrameFlash(self.bg, 0.4, 0.4, 60, true, 0, 0)
		end
	elseif(self.critical) then
		self.critical = nil
		UIFrameFadeRemoveFrame(self.bg)
		UIFrameFlashRemoveFrame(self.bg)
		self.bg.flashTimer = nil		
		self.bg:SetVertexColor(0.6, 0, 0, 0.6)
	end

	--Change displayed text depending on if disconnected/dead/ghost/etc
	local text = self.text
	if text:IsShown() then
		if UnitIsFeignDeath(unit) then
			text:SetText(L.FeignDeath)
		elseif UnitIsDead(unit) then
			text:SetText(L.Dead)
		elseif UnitIsGhost(unit) then
			text:SetText(L.Ghost)
		elseif not UnitIsConnected(unit) then
			text:SetText(L.Offline)
		else
			self:SetText(value, maxValue, Sage:GetHealthTextMode(self.id))
		end
	end
end

function SageHealth:UpdateDebuff()
	local unit = self.id
	if(Sage:DebuffColoring() and UnitIsFriend("player", unit)) then
		local sets = Sage:GetFrameSets(unit)
		local showCurable = sets and sets.showCurable
		local i = 1
		local name, _, _, _, type = UnitDebuff(unit, i, showCurable)
		while(name and not type) do
			i = i + 1
			name, _, _, _, type = UnitDebuff(unit, i, showCurable)
		end
		self.debuff = type
	else
		self.debuff = nil
	end

	if self.debuff then
		local color = DebuffTypeColor[self.debuff or "none"]
		self:SetStatusBarColor(color.r, color.g, color.b)
	else
		self:UpdateHealthColor(self:GetValue())
	end
end

function SageHealth:UpdateHealthColor(value)
	if(not self.debuff) then
		if UnitIsFeignDeath(self.id) then
			self:SetStatusBarColor(0, 0.9, 0.78)
			-- self:SetStatusBarColor(1, 0.3, 0.6)
		else
			Bar_UpdateHealthColor(self, value)
		end
	end
end

function SageHealth:UpdateText()	
	self:Update()
end

SageHealth.SetText = SageBar.SetText
SageHealth.ShowText = SageBar.ShowText
SageHealth.UpdateTexture = SageBar.UpdateTexture

--[[ Utility Functions ]]--

function SageHealth:ForAll(method, ...)
	local bars = self.bars
	if(bars) then
		for _,bar in pairs(bars) do
			bar[method](bar, ...)
		end
	end
end

function SageHealth:Get(id)
	return self.bars and self.bars[id]
end


--[[ Events ]]--

function SageHealth:OnEvent(unit)
	local bar = self:Get(unit)
	if bar and bar:IsVisible() then
		bar:Update()
	end
end

function SageHealth:OnBuffEvent(unit)
	local bar = self:Get(unit)
	if bar and bar:IsVisible() then
		bar:UpdateDebuff()
	end
end