--[[
	SageMana
		Handles mana/rage/energy/focus bars
--]]


local ManaBar = Sage:CreateObjectClass('StatusBar', Sage.StatusBar)
Sage.ManaBar = ManaBar
local Config = Sage.Config

--[[ Constructor ]]--

function ManaBar:Create(...)
	local bar = self:New(self.super:Create(...))
	bar:SetScript('OnShow', bar.Update)
	
	if self.bars then
		self.bars[bar.id] = bar
	else
		self.bars = {[bar.id] = bar}
	end
	
	return bar
end


--[[ Events ]]--

function ManaBar:OnEvent(event, unit)
	local bar = self:Get(unit)
	if bar and bar:IsVisible() then
		bar:Update()
	end
end

ManaBar:RegisterEvent('UNIT_MANA')
ManaBar:RegisterEvent('UNIT_RAGE')
ManaBar:RegisterEvent('UNIT_FOCUS')
ManaBar:RegisterEvent('UNIT_ENERGY')
ManaBar:RegisterEvent('UNIT_MAXMANA')
ManaBar:RegisterEvent('UNIT_MAXRAGE')
ManaBar:RegisterEvent('UNIT_MAXFOCUS')
ManaBar:RegisterEvent('UNIT_MAXENERGY')
ManaBar:RegisterEvent('UNIT_DISPLAYPOWER')


--[[ Update Functions ]]--

function ManaBar:Update()
	local unit = self.id
	local max = UnitManaMax(unit)
	self:SetMinMaxValues(0, max)
	
	if UnitIsConnected(unit) then
		--update mana bar color
		local power = UnitPowerType(unit)
		local info = ManaBarColor[power]
		self:SetStatusBarColor(info.r, info.g, info.b)

		local r, g, b = self:GetComplement(self:GetStatusBarColor())
		self.bg:SetVertexColor(r, g, b, 0.6)

		if power == 1 then --rage
			self:SetValue(max - UnitMana(unit))
		else
			self:SetValue(UnitMana(unit))
		end
	else
		self:SetValue(maxMana)
		self:SetStatusBarColor(0.5, 0.5, 0.5)
	end

	self:OnTextUpdate()
end

--the update text function is indeed rather complex
function ManaBar:OnTextUpdate()
	local unit, mode, text, entered = self.id, self.mode, self.text, self.entered
	local value = self:GetValue()
	local min, max = self:GetMinMaxValues()

	if mode == 'mouseover' and not entered then --mouseover mode, not moused over
		text:Hide()
	elseif UnitIsGhost(unit) or UnitIsDead(unit) or not UnitIsConnected(unit) then --disconnected
		text:Hide()
	elseif entered or mode == 'always' then
		if Config:ShowMaximum(unit) then
			text:SetFormattedText('%d / %d', value, max)
		else
			text:SetText(value)
		end
		text:Show()
	elseif mode == 'smart' then --smart mode
		if UnitPowerType(unit) == 1 and value == 0 then --rage at nothing
			text:Hide()
		elseif UnitPowerType(unit) ~= 1 and value == max then --mana, energy, focus at full
			text:Hide()
		else
			if value < 1000 then --use x.yk formatting for numbers >= 1000
				text:SetText(value)
			else
				text:SetFormattedText('%.1fk', value / 1000)
			end
			text:Show()
		end
	end
end

--[[ Utility Functions ]]--

function ManaBar:Get(id)
	return self.bars and self.bars[id]
end