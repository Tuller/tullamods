--[[
	SpellBar.lua
		Unit casting bars
--]]

local SpellBar = Sage:CreateClass('Frame')
Sage.SpellBar = SpellBar

local min = math.min
local GetTime = _G['GetTime']
local frames = {}

function SpellBar:New(parent, font)
	local f = self:Bind(CreateFrame('Frame', parent:GetName() .. 'Cast', parent))
	f:SetScript('OnShow', self.OnShow)
	f:SetScript('OnUpdate', self.OnUpdate)
	f:SetScript('OnSizeChanged', self.OnSizeChanged)
	f:SetFrameLevel(f:GetFrameLevel() + 1)

	local icon = f:CreateTexture(f:GetName() .. 'Icon', 'ARTWORK')
	icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	icon:SetPoint('BOTTOMLEFT', f)
	icon:SetAlpha(0.5)
	f.icon = icon

	local bar = Sage.StatusBar:New('Bar', f)
	bar:SetPoint('BOTTOMLEFT', icon, 'BOTTOMRIGHT')
	bar:SetPoint('BOTTOMRIGHT', f)
	bar:SetScript('OnUpdate', self.OnUpdate)
	f.bar = bar

	if font then
		local text = f:CreateFontString(f:GetName() .. 'Text', 'OVERLAY')
		text:SetPoint('CENTER', icon)
		text:SetFontObject(font)
		f.text = text
	end

	table.insert(frames, f)
	f:UpdateUnit()

	return f
end

function SpellBar:OnShow()
	self:Update()
end

function SpellBar:OnUpdate()
	if self.casting then
		local value = min(GetTime(), self.maxValue)

		if value == self.maxValue then
			self:Finish()
		else
			self.bar:SetValue(value)

			if self.text then
				self.text:SetFormattedText('%.1f', self.maxValue - value)
			end
		end
	elseif self.channeling then
		local value = min(GetTime(), self.endTime)

		if value == self.endTime then
			self:Finish()
		else
			self.bar:SetValue(self.startTime + (self.endTime - value))

			if self.text then
				self.text:SetFormattedText('%.1f', self.endTime - value)
			end
		end
	end
end

function SpellBar:OnSizeChanged()
	local height = self:GetHeight()
	self.icon:SetWidth(height)
	self.icon:SetHeight(height)
	self.bar:SetHeight(height * 0.25)
end

function SpellBar:Update()
	if UnitCastingInfo(self.unit) then
		self:OnSpellStart()
	elseif UnitChannelInfo(self.unit) then
		self:OnChannelStart()
	else
		self:Finish()
	end
end

function SpellBar:UpdateUnit(newUnit)
	local newUnit = newUnit or self:GetParent():GetAttribute('unit')
	if self.unit ~= newUnit then
		self.unit = newUnit
		self:Update()
	end
end


--[[ Event Functions ]]--

function SpellBar:OnSpellStart()
	local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(self.unit)
	if not(name) or isTradeSkill then
		self:Hide()
		return
	end

	if IsHelpfulSpell(name) then
		self.bar:SetColor(0, 1, 1)
	elseif IsHarmfulSpell(name) then
		self.bar:SetColor(1, 0, 1)
	else
		self.bar:SetColor(1, 1, 0)
	end

	self.startTime = startTime / 1000
	self.maxValue = endTime / 1000

	self.bar:SetMinMaxValues(self.startTime, self.maxValue)
	self.bar:SetValue(self.startTime)

	self.icon:SetTexture(texture)

	self.casting = true
	self.channeling = nil
	self:Show()
end

function SpellBar:OnSpellDelayed()
	if self:IsVisible() then
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(self.unit)
		if not(name) or isTradeSkill then
			self:Hide()
			return
		end

		self.startTime = startTime / 1000
		self.maxValue = endTime / 1000

		self.bar:SetMinMaxValues(self.startTime, self.maxValue)

		if not self.casting then
			self.bar:SetColor(1, 0.7, 0)
			self.casting = true
			self.channeling = nil
		end
	end
end

function SpellBar:OnChannelStart()
	local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(self.unit)
	if not(name) or isTradeSkill then
		self:Hide()
		return
	end

	if IsHelpfulSpell(name) then
		self.bar:SetColor(0, 1, 1)
	elseif IsHarmfulSpell(name) then
		self.bar:SetColor(1, 0, 1)
	else
		self.bar:SetColor(1, 1, 0)
	end

	self.startTime = startTime / 1000
	self.endTime = endTime / 1000
	self.duration = self.endTime - self.startTime
	self.maxValue = self.startTime

	self.bar:SetMinMaxValues(self.startTime, self.endTime)
	self.bar:SetValue(self.endTime)
	self.icon:SetTexture(texture)

	self.casting = nil
	self.channeling = true
	self:Show()
end

function SpellBar:OnChannelUpdate()
	if self:IsVisible() then
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(self.unit)
		if not(name) or isTradeSkill then
			self:Hide()
			return
		end

		self.startTime = startTime / 1000
		self.endTime = endTime / 1000
		self.maxValue = self.startTime
		self.bar:SetMinMaxValues(self.startTime, self.endTime)
	end
end

function SpellBar:OnSpellStop()
	if not self.channeling then
		self:Finish()
	end
end

function SpellBar:Finish()
	self.casting = nil
	self.channeling = nil
	self.bar:SetColor(0, 1, 0)
	self:Hide()
end


--[[ Utility Functions ]]--

--sets whether to color health when debuffed or not
function SpellBar:ForVisibleUnit(unit, method, ...)
	for _,f in pairs(frames) do
		if f.unit == unit and f:GetParent():IsVisible() then
			f[method](f, ...)
		end
	end
end

function SpellBar:ForAllVisible(method, ...)
	for _,f in pairs(frames) do
		if f:GetParent():IsVisible() then
			f[method](f, ...)
		end
	end
end

--[[ Events ]]--

do
	local f = CreateFrame('Frame')
	f:SetScript('OnEvent', function(self, event, unit)
		if event == 'UNIT_SPELLCAST_START' then
			SpellBar:ForVisibleUnit(unit, 'OnSpellStart')
		elseif event == 'UNIT_SPELLCAST_DELAYED' then
			SpellBar:ForVisibleUnit(unit, 'OnSpellDelayed')
		elseif event == 'UNIT_SPELLCAST_CHANNEL_START' then
			SpellBar:ForVisibleUnit(unit, 'OnChannelStart')
		elseif event == 'UNIT_SPELLCAST_CHANNEL_UPDATE' then
			SpellBar:ForVisibleUnit(unit, 'OnChannelUpdate')
		elseif event == 'UNIT_SPELLCAST_STOP' then
			SpellBar:ForVisibleUnit(unit, 'OnSpellStop')
		elseif event == 'UNIT_SPELLCAST_FAILED' or event == 'UNIT_SPELLCAST_INTERRUPTED' or event == 'UNIT_SPELLCAST_CHANNEL_STOP' then
			SpellBar:ForVisibleUnit(unit, 'Finish')
		elseif event == 'PLAYER_ENTERING_WORLD' then
			SpellBar:ForAllVisible('Update')
		end
	end)

	f:RegisterEvent('PLAYER_ENTERING_WORLD')
	f:RegisterEvent('UNIT_SPELLCAST_START')
	f:RegisterEvent('UNIT_SPELLCAST_DELAYED')
	f:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START')
	f:RegisterEvent('UNIT_SPELLCAST_CHANNEL_UPDATE')
	f:RegisterEvent('UNIT_SPELLCAST_STOP')
	f:RegisterEvent('UNIT_SPELLCAST_FAILED')
	f:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED')
	f:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP')
end