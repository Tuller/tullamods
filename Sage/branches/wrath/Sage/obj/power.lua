--[[
	PowerBar Object
--]]

local PowerBar = Sage:CreateClass('StatusBar', Sage.StatusBar)
Sage.PowerBar = PowerBar

local bars = {}
function PowerBar:New(parent, font)
	local bar = self.super.New(self, 'Power', parent, font)
	bar:SetScript('OnShow', self.Update)
	bar:SetScript('OnUpdate', self.OnUpdate)
	bar:Update()

	table.insert(bars, bar)
	return bar
end

--[[ Events ]]--

function PowerBar:OnUpdate()
	local unit = self:GetAttribute('unit')

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

--[[ Update Methods ]]--

function PowerBar:Update()
	local unit = self:GetAttribute('unit')
	local powerType, powerToken = UnitPowerType(unit)
	local value, max = UnitPower(unit, powerType), UnitPowerMax(unit, powerType)

	self:SetMinMaxValues(0, max)
	self.powerToken = powerToken

	if UnitIsConnected(unit) then
		local color = _G['PowerBarColor'][powerToken]
		self:SetStatusBarColor(color.r, color.g, color.b)
		self.bg:SetTexture(0.6, 0.3, 0.1, 0.6)

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
	local unit = self:GetAttribute('unit')
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
		if f:IsVisible() then
			f[method](f, ...)
		end
	end
end

function PowerBar:GetAll()
	return pairs(bars)
end