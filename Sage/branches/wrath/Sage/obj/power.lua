--[[
	PowerBar Object
--]]

local PowerBar = Sage:CreateClass('StatusBar', Sage.StatusBar)
Sage.PowerBar = PowerBar


local bars = {}
function PowerBar:New(parent, font)
	local bar = self.super.New(self, 'Power', parent, font)
	bar:SetScript('OnShow', self.Update)
	bar:UpdateUnit()

	table.insert(bars, bar)
	return bar
end

function PowerBar:NewFrequent(parent, font)
	local f = self:New(parent, font)
	f:SetScript('OnUpdate', self.OnUpdate)

	return f
end

--[[ Events ]]--

function PowerBar:OnUpdate()
	local unit = self.unit

	if UnitIsConnected(unit) then
		local powerType, powerToken = UnitPowerType(unit)
		local value, max = UnitPower(unit, powerType), UnitPowerMax(unit, powerType)
		local prevVal = self:GetValue()
		local _, prevMax = self:GetMinMaxValues()

		if not(prevVal == value and prevMax == max) then
			self:Update()
		end
	end
end

function PowerBar:UNIT_MANA(unit)
	if self.unit == unit then
		self:Update()
	end
end


--[[ Update Methods ]]--

function PowerBar:UpdateUnit(newUnit)
	local newUnit = newUnit or self:GetParent():GetAttribute('unit')
	if self.unit ~= newUnit then
		self.unit = newUnit

		if self:IsVisible() then
			self:Update()
		end
	end
end

function PowerBar:GetUnit()
	return self.unit
end

function PowerBar:Update()
	local unit = self.unit
	local powerType, powerToken = UnitPowerType(unit)
	if powerType == 0 or UnitIsPlayer(unit) then
		self:Show()
	else
		self:Hide()
		return
	end

	local value, max = UnitPower(unit, powerType), UnitPowerMax(unit, powerType)
	self:SetMinMaxValues(0, max)
	self.powerToken = powerToken

	if UnitIsConnected(unit) then
		local color = _G['PowerBarColor'][powerToken]
		self:SetColor(color.r, color.g, color.b)
		self:SetValue(value)
	else
		self:SetValue(max)
		self:SetStatusBarColor(0.5, 0.5, 0.5)
	end

	if self.text then
		self:UpdateText()
	end
end

function PowerBar:UpdateText()
	local text = self.text
	local unit = self:GetUnit()
	local value = self:GetValue()
	local min, max = self:GetMinMaxValues()

	if UnitIsGhost(unit) or UnitIsDead(unit) or not UnitIsConnected(unit) then
		text:SetText('')
	else
		if self.powerToken == 'RAGE' and value == 0 then
			text:SetText('')
		elseif self.powerToken ~= 'RAGE' and value == max then
			text:SetText('')
		elseif value < 1000 then
			text:SetText(value)
		else
			text:SetFormattedText('%.1fk', value / 1000)
		end
	end
end


--[[ Utility Functions ]]--

function PowerBar:ForAll(method, ...)
	for _,f in self:GetAll() do
		f[method](f, ...)
	end
end

function PowerBar:ForAllShown(method, ...)
	for _,f in self:GetAll() do
		if f:GetParent():IsVisible() then
			f[method](f, ...)
		end
	end
end

function PowerBar:GetAll()
	return pairs(bars)
end

--[[ Event Handler ]]--

do
	local f = CreateFrame('Frame')

	f:SetScript('OnEvent', function(self, event, ...)
		PowerBar:ForAllShown('UNIT_MANA', ...)
	end)

	f:RegisterEvent('UNIT_MANA')
	f:RegisterEvent('UNIT_MAXMANA')
	f:RegisterEvent('UNIT_RAGE')
	f:RegisterEvent('UNIT_MAXRAGE')
	f:RegisterEvent('UNIT_FOCUS')
	f:RegisterEvent('UNIT_MAXFOCUS')
	f:RegisterEvent('UNIT_ENERGY')
	f:RegisterEvent('UNIT_RUNIC_POWER')
	f:RegisterEvent('UNIT_MAXRUNIC_POWER')
	f:RegisterEvent('UNIT_DISPLAYPOWER')
end