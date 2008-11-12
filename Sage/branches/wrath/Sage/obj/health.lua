--[[
	Healthbar Object
--]]

--omgspeed
local _G = _G
local UnitHealth = _G['UnitHealth']
local UnitHealthMax = _G['UnitHealthMax']
local UnitIsFriend = _G['UnitIsFriend']
local UnitDebuff = _G['UnitDebuff']
local UnitIsFeignDeath = _G['UnitIsFeignDeath']
local UnitIsDead = _G['UnitIsDead']
local UnitIsGhost = _G['UnitIsGhost']
local UnitIsConnected = _G['UnitIsConnected']
local playerClass = select(2, UnitClass('player'))


local HealthBar = Sage:CreateClass('StatusBar', Sage.StatusBar)
Sage.HealthBar = HealthBar

local bars = {}
function HealthBar:New(parent, font)
	local bar = self.super.New(self, 'Health', parent, font)
	bar:SetColor(0, 0.8, 0)
	bar:SetScript('OnShow', self.OnShow)
	bar:UpdateUnit()

	table.insert(bars, bar)
	return bar
end


--[[
	Event Handlers
--]]

function HealthBar:OnShow()
	self:UpdateAll()
end

function HealthBar:OnValueChanged(value)
	if not self.debuff then
		_G['HealthBar_OnValueChanged'](self, value, true)
	end
end

function HealthBar:UNIT_HEALTH(unit)
	if self.unit == unit then
		self:Update()
	end
end
HealthBar.UNIT_MAXHEALTH = HealthBar.UNIT_HEALTH

function HealthBar:UNIT_AURA(unit)
	if self.unit == unit then
		self:UpdateDebuff()
	end
end


--[[
	Update Methods
--]]

function HealthBar:UpdateUnit(newUnit)
	local newUnit = newUnit or self:GetParent():GetAttribute('unit')
	if self.unit ~= newUnit then
		self.unit = newUnit
		
		if self:IsVisible() then
			self:UpdateAll()
		end
	end
end

function HealthBar:UpdateAll()
	self:Update()
	self:UpdateDebuff()
end

function HealthBar:Update()
	local unit = self.unit

	local value, maxValue = UnitHealth(unit), UnitHealthMax(unit)
	self:SetMinMaxValues(0, maxValue)
	self:SetValue(value)

	--Change displayed text depending on if disconnected/dead/ghost/etc
	if self.text then
		self:UpdateText()
	end
end

function HealthBar:UpdateDebuff()
	local unit = self.unit

	if UnitIsFriend('player', unit) then
		local i = 1
		local name, _, _, _, type = UnitDebuff(unit, i)
		while(name and not type) do
			i = i + 1
			name, _, _, _, type = UnitDebuff(unit, i)
		end
		self.debuff = type
	else
		self.debuff = nil
	end

	self:UpdateHealthColor()
end

function HealthBar:UpdateHealthColor()
	local unit = self.unit

	if self.debuff then
		local color = Sage:GetDebuffColor(self.debuff)
		self:SetColor(color.r, color.g, color.b)
	elseif UnitIsFeignDeath(unit)  then
		self:SetColor(0, 0.9, 0.78)
	elseif UnitIsPlayer(unit) and UnitClass(unit) then
		local _,enClass = UnitClass(unit)
		local color = Sage:GetClassColor(enClass)
		self:SetColor(color.r, color.g, color.b)
	else
		self:SetColor(0.1, 0.8, 0.1)
	end
end

function HealthBar:UpdateText()
	local text = self.text
	local unit = self.unit
	local value = self:GetValue()
	local min, max = self:GetMinMaxValues()

	if UnitIsFeignDeath(unit) then
		text:SetText('Feign Death')
	elseif UnitIsDead(unit) then
		text:SetText('Dead')
	elseif UnitIsGhost(unit) then
		text:SetText('Ghost')
	elseif not UnitIsConnected(unit) then
		text:SetText('Offline')
	else
		if value == max then
			text:SetText('')
		elseif UnitIsFriend(unit, 'player') then
			local missing = value - max
			if missing > -1000 then
				text:SetText(missing)
			else
				text:SetFormattedText('%.1fk', missing/1000)
			end
		else
			if value < 1000 then
				text:SetText(value)
			else
				text:SetFormattedText('%.1fk', value/1000)
			end
		end
	end
--	text:Show()
end


--[[ Utility Functions ]]--

function HealthBar:ForAll(method, ...)
	for _,f in self:GetAll() do
		f[method](f, ...)
	end
end

function HealthBar:ForAllShown(method, ...)
	for _,f in self:GetAll() do
		if f:IsVisible() then
			f[method](f, ...)
		end
	end
end

function HealthBar:GetAll()
	return pairs(bars)
end


--[[ Event Handler ]]--

do
	local f = CreateFrame('Frame')

	f:SetScript('OnEvent', function(self, event, ...)
		HealthBar:ForAllShown(event, ...)
	end)

	f:RegisterEvent('UNIT_HEALTH')
	f:RegisterEvent('UNIT_MAXHEALTH')
	f:RegisterEvent('UNIT_AURA')
--	f:RegisterEvent('UNIT_HAPPINESS')
end