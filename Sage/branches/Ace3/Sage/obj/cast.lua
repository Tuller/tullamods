--[[
	SageCast.lua
		Unit casting bars
--]]

local CastBar = Sage:CreateObjectClass('Frame')
Sage.CastBar = CastBar
local Config = Sage.Config

--[[ Constructor ]]--

local function OnUpdate(self) self:GetParent():OnUpdate() end

function CastBar:Create(parent, unit, ...)
	local frame = self:New(CreateFrame('Frame', nil, parent))
	frame:SetScript('OnShow', frame.Update)
	frame.id = unit or parent.unit
	
	frame.bar = Sage.StatusBar:Create(frame, unit, ...)
	frame.bar:SetScript('OnUpdate', OnUpdate)

	local bar = self:New(self.super:Create(...))
	bar:SetScript('OnShow', bar.Update)

	bar.updater = CreateFrame('Frame', nil, bar)
	bar.updater:SetScript('OnUpdate', OnUpdate)
	bar.updater:Hide()

	local icon = bar:CreateTexture(nil, 'OVERLAY')
	icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	icon:SetWidth(12)
	icon:SetHeight(12)
	icon:SetPoint('TOPLEFT', bar)
	bar.icon = icon

	icon:SetPoint('TOPLEFT', frame)
	bar:SetPoint('TOPLEFT', icon, 'TOPRIGHT')
	bar:SetPoint('BOTTOMRIGHT', frame)

	if not self.bars then self.bars = {} end
	self.bars[bar.id] = bar

	return bar
end


--[[ Events ]]--

function CastBar:OnEvent(event, ...)
	local func = self[event]
	if func then
		func(self, ...)
	end
end
CastBar:RegisterEvent('PLAYER_ENTERING_WORLD')
CastBar:RegisterEvent('UNIT_SPELLCAST_START')
CastBar:RegisterEvent('UNIT_SPELLCAST_DELAYED')
CastBar:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START')
CastBar:RegisterEvent('UNIT_SPELLCAST_CHANNEL_UPDATE')
CastBar:RegisterEvent('UNIT_SPELLCAST_STOP')
CastBar:RegisterEvent('UNIT_SPELLCAST_FAILED')
CastBar:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED')
CastBar:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP')


function CastBar:PLAYER_ENTERING_WORLD()
	self:ForAll('Update')
end

function CastBar:UNIT_SPELLCAST_START(unit)
	self:ForUnit(unit, 'OnSpellStart')
end

function CastBar:UNIT_SPELLCAST_DELAYED(unit)
	self:ForUnit(unit, 'OnSpellDelayed')
end

function CastBar:UNIT_SPELLCAST_CHANNEL_START(unit)
	self:ForUnit(unit, 'OnChannelStart')
end

function CastBar:UNIT_SPELLCAST_CHANNEL_UPDATE(unit)
	self:ForUnit(unit, 'OnChannelUpdate')
end

--finish events
function CastBar:UNIT_SPELLCAST_STOP(unit)
	self:ForUnit(unit, 'OnSpellStop')
end

function CastBar:UNIT_SPELLCAST_FAILED(unit)
	self:ForUnit(unit, 'Finish')
end

function CastBar:UNIT_SPELLCAST_INTERRUPTED(unit)
	self:ForUnit(unit, 'Finish')
end

function CastBar:UNIT_SPELLCAST_CHANNEL_STOP(unit)
	self:ForUnit(unit, 'Finish')
end


--[[ Event Functions ]]--

function SageCast:Update()
	local unit = self.id

	if Config:ShowingCastBars(unit) then
		if UnitCastingInfo(unit) then
			self:OnSpellStart()
		elseif UnitChannelInfo(unit) then
			self:OnChannelStart()
		else
			self:Finish()
		end
	else
		self:Finish()
	end
end

function SageCast:OnSpellStart()
	local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(self.id)
	if not(name) or isTradeSkill then self:Hide() return end

	if IsHelpfulSpell(name) then
		self:SetColor(0, 1, 1)
	elseif IsHarmfulSpell(name) then
		self:SetColor(1, 0, 1)
	else
		self:SetColor(1, 1, 0)
	end

	self.startTime = startTime / 1000
	self.maxValue = endTime / 1000

	self:SetMinMaxValues(self.startTime, self.maxValue)
	self:SetValue(self.startTime)

	self.icon:SetTexture(texture)

	self.casting = true
	self.channeling = nil
	self:Show()
end

function SageCast:OnSpellDelayed()
	if self:IsShown() then
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(self.id)
		if not(name) or isTradeSkill then self:Hide() return end

		self.startTime = startTime / 1000
		self.maxValue = endTime / 1000
		self:SetMinMaxValues(self.startTime, self.maxValue)

		if not self.casting then
			self:SetColor(1, 0.7, 0)
			self.casting = true
			self.channeling = nil
		end
	end
end

function SageCast:OnChannelStart()
	local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(self.id)
	if not(name) or isTradeSkill then self:Hide() return end

	if IsHelpfulSpell(name) then
		self:SetColor(0, 1, 1)
	elseif IsHarmfulSpell(name) then
		self:SetColor(1, 0, 1)
	else
		self:SetColor(1, 1, 0)
	end

	self.startTime = startTime / 1000
	self.endTime = endTime / 1000
	self.duration = self.endTime - self.startTime
	self.maxValue = self.startTime

	self:SetMinMaxValues(self.startTime, self.endTime)
	self:SetValue(self.endTime)

	self.icon:SetTexture(texture)

	self.casting = nil
	self.channeling = true
	self:Show()
end

function SageCast:OnChannelUpdate()
	if self:IsShown() then
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(self.id)
		if not(name) or isTradeSkill then self:Hide() return end

		self.startTime = startTime / 1000
		self.endTime = endTime / 1000
		self.maxValue = self.startTime
		self:SetMinMaxValues(self.startTime, self.endTime)
	end
end


--[[ On Update Functions ]]--

function SageCast:OnUpdate()
	if self.casting then
		local value = min(GetTime(), self.maxValue)

		if value == self.maxValue then
			self:Finish()
		else
			self:SetValue(value)
			if self.text then
				self.text:SetFormattedText('%.1fs', self.maxValue - value)
			end
		end
	elseif self.channeling then
		local value = min(GetTime(), self.endTime)

		if value == self.endTime then
			self:Finish()
		else
			self:SetValue(self.startTime + (self.endTime - value))
			if self.text then
				self.text:SetFormattedText('%.1fs', self.endTime - value)
			end
		end
	end
end

function SageCast:OnSpellStop()
	if not self.channeling then
		self:Finish()
	end
end

function SageCast:Finish()
	self.casting = nil
	self.channeling = nil

	self:SetColor(0, 1, 0)
	self:Hide()
end


--[[ Utility Functions ]]--

function CastBar:ForUnit(unit, method, ...)
	local bar = self:Get(unit)
	if bar then
		bar[method](bar, ...)
	end
end

function CastBar:Get(unit)
	return self.bars and self.bars[unit]
end