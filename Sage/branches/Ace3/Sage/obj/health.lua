--[[
	SageHealth
		Handles healthbars

	MobHealth Versions Supported:
		Telos' MobHealth (preferred)
		MobInfo2
		MobInfo3
--]]

SageHealth = CreateFrame('StatusBar')
local Bar_MT = {__index = SageHealth}
local L = SAGE_LOCALS


--[[ Local Functions ]]--

--update's the bar's color based on how much health the bar's parent unit has
local function Bar_UpdateHealthColor(self, value)
	if UnitIsPlayer(self.id) and UnitClass(self.id) then
		local class = select(2, UnitClass(self.id))
		local r = RAID_CLASS_COLORS[class].r
		local g = RAID_CLASS_COLORS[class].g
		local b = RAID_CLASS_COLORS[class].b

		self:SetStatusBarColor(r, g, b)
	elseif self.id == 'pet' and select(2, HasPetUI()) then
		local happiness = GetPetHappiness()
		if happiness == 1 then
			self:SetStatusBarColor(0.9, 0, 0)
		elseif happiness == 2 then
			self:SetStatusBarColor(0.9, 0.9, 0)
		else
			self:SetStatusBarColor(0, 0.9, 0)
		end
	else
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
			local ppp = MobHealth_PPP(format('%s:%s', UnitName(unit), UnitLevel(unit)))
			if ppp and ppp ~= 0 then
				return floor(UnitHealth(unit) * ppp + 0.5), floor(UnitHealthMax(unit) * ppp + 0.5)
			end
			return UnitHealth(unit), UnitHealthMax(unit)
		end
	else
		--Telos' Mobhealth
		GetMobHealth = function(unit)
			local index = format('%s:%s', UnitName(unit), UnitLevel(unit))
			local health, healthMax = UnitHealth(unit), UnitHealthMax(unit)
			if MobHealthDB[index] then
				local pts, pct = MobHealthDB[index]:match('^(%d+)/(%d+)$')
				if(tonumber(pts) and tonumber(pct)) then
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

	bar:SetScript('OnValueChanged', Bar_UpdateHealthColor)
	bar:SetScript('OnShow', Bar_OnShow)
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

	--Change displayed text depending on if disconnected/dead/ghost/etc
	self:UpdateText()
end

function SageHealth:UpdateDebuff()
	local unit = self.id
	if(Sage:DebuffColoring() and UnitIsFriend('player', unit)) then
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
		local color = DebuffTypeColor[self.debuff or 'none']
		self:SetStatusBarColor(color.r, color.g, color.b)
	else
		self:UpdateHealthColor(self:GetValue())
	end
end

function SageHealth:UpdateHealthColor(value)
	if(not self.debuff) then
		if UnitIsFeignDeath(self.id) then
			self:SetStatusBarColor(0, 0.9, 0.78)
		else
			Bar_UpdateHealthColor(self, value)
		end
	end
end

--mode 1 = show only on mouseover, 2 = compact, 3 = full
function SageHealth:UpdateText()
	local unit, mode, text, entered = self.id, self.mode, self.text, self.entered
	local value = self:GetValue()
	local min, max = self:GetMinMaxValues()

	if(mode == 1 and not entered) then
		text:Hide()
	else
		if UnitIsFeignDeath(unit) then
			text:SetText(L.FeignDeath)
		elseif UnitIsDead(unit) then
			text:SetText(L.Dead)
		elseif UnitIsGhost(unit) then
			text:SetText(L.Ghost)
		elseif not UnitIsConnected(unit) then
			text:SetText(L.Offline)
		elseif(entered or mode == 3) then
			if(Sage:ShowingMaxValues()) then
				text:SetText(format('%d / %d', value, max))
			else
				text:SetText(value)
			end
		elseif(mode == 2) then
			if value == max then
				text:SetText('')
			else
				if UnitIsFriend(unit, 'player') then
					value = value - max
				end

				if value > -1000 then
					text:SetText(value)
				else
					text:SetFormattedText('%.1fk', value/1000)
				end
			end
		end
		text:Show()
	end
end
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

function SageHealth:OnHappyEvent()
	local bar = self:Get('pet')
	if bar and bar:IsVisible() then
		bar:UpdateHealthColor(GetUnitHealth('pet'))
	end
end