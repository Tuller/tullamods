--[[
	SageHealth
		Handles healthbars

	MobHealth Versions Supported:
		Telos' MobHealth (preferred)
		MobInfo2
		MobInfo3
--]]

local HealthBar = Sage:CreateObjectClass('StatusBar', Sage.StatusBar)
Sage.HealthBar = HealthBar
local Config = Sage.Config


--[[ Constructor ]]--

function HealthBar:Create(...)
	local bar = self:New(self.super:Create(...))
	bar:SetScript('OnShow', bar.UpdateAll)
	bar:SetScript('OnValueChanged', bar.UpdateColor)
	
	if self.bars then
		self.bars[bar.id] = bar
	else
		self.bars = {[bar.id] = bar}
	end
	
	return bar
end

function HealthBar:UpdateColor()
	local unit = self.id
	if self.debuff then
		local color = DebuffTypeColor[self.debuff or 'none']
		self:SetStatusBarColor(color.r, color.g, color.b)
	elseif unit == 'pet' and select(2, HasPetUI()) then
		local happiness = GetPetHappiness()
		if happiness == 1 then
			self:SetStatusBarColor(0.9, 0, 0)
		elseif happiness == 2 then
			self:SetStatusBarColor(0.9, 0.9, 0)
		else
			self:SetStatusBarColor(0, 0.9, 0)
		end
	elseif UnitIsFeignDeath(unit) then
		self:SetStatusBarColor(0, 0.9, 0.78)
	elseif UnitIsPlayer(unit) and Config:ColorHealthByClass() then
		local color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
		self:SetStatusBarColor(color.r, color.g, color.b)
	else
		self:SetStatusBarColor(0, 0.8, 0)
	end
	
	local r, g, b = self:GetComplement(self:GetStatusBarColor())
	self.bg:SetVertexColor(r, g, b, 0.6)
end


--[[ Events ]]--

function HealthBar:OnEvent(event, unit)
	local unit = (event == 'UNIT_HAPPINESS' and 'pet') or unit
	local bar = self:Get(unit)
	if bar and bar:IsVisible() then
		if event == 'UNIT_HEALTH' or event == 'UNIT_MAXHEALTH' then
			bar:UpdateHealth()
		elseif event == 'UNIT_HAPPINESS' then
			bar:UpdateColor()
		elseif event == 'UNIT_AURA' then
			bar:UpdateBuff()
		end
	end
end
HealthBar:RegisterEvent('UNIT_HAPPINESS')
HealthBar:RegisterEvent('UNIT_HEALTH')
HealthBar:RegisterEvent('UNIT_MAXHEALTH')
HealthBar:RegisterEvent('UNIT_AURA')


--[[ Setup the GetUnitHealth function based on which MobInfo addon is loaded, if any ]]--

local GetUnitHealth
do
	if MobHealth3 then	
		GetUnitHealth = function(unit)
			local value, maxValue = UnitHealth(unit), UnitHealthMax(unit)

			if maxValue == 100 then
				value, maxValue = MobHealth3:GetUnitHealth(unit)
			end
			return value, maxValue
		end
	elseif MobHealthFrame then
		local GetMobHealth

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
		--no mobhealth variant installed
		GetUnitHealth = function(unit)
			return UnitHealth(unit), UnitHealthMax(unit)
		end
	end
end

function SageHealth:UpdateAll()
	self:UpdateHealth()
	self:UpdateDebuff()
end

function SageHealth:UpdateHealth()
	local unit = self.id
	local value, max = GetUnitHealth(unit)

	self:SetMinMaxValues(0, max)
	self:SetValue(value)
	self:UpdateText()
end

function SageHealth:UpdateDebuff()
	local unit = self.id
	self.debuff = nil

	if Config:HighlightDebuffs(unit) and UnitIsFriend('player', unit) then
		local showCurable = Config:ShowOnlyCurable(unit)
		local name, _,
		local i = 1

		repeat
			name, _, _, _, self.debuff = UnitDebuff(unit, i, showCurable)
			i = i + 1
		until self.debuff or not name
	end

	self:UpdateColor()
end

--mode 1 = show only on mouseover, 2 = compact, 3 = full
function SageHealth:OnTextUpdate()
	local unit, mode, text, entered = self.id, self.mode, self.text, self.entered
	local value = self:GetValue()
	local min, max = self:GetMinMaxValues()

	if mode == 'mouseover' and not entered then
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
		elseif entered or mode == 'always' then
			if Config:ShowMaximum(unit) then
				text:SetText(format('%d / %d', value, max))
			else
				text:SetText(value)
			end
		elseif mode == 'smart' then
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


--[[ Utility Functions ]]--

function SageHealth:Get(id)
	return self.bars and self.bars[id]
end