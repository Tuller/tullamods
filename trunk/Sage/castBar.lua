SageCast = CreateFrame('StatusBar')
local StatusBar_mt = {__index = SageCast}

local bars = {}

local function OnUpdate() this:OnUpdate() end


--[[ Constructor ]]--

function SageCast.Create(parent, id)
	local bar = CreateFrame('StatusBar', nil, parent)
	setmetatable(bar, StatusBar_mt)

	bar:SetAlpha(parent:GetAlpha())

	bar.bg = bar:CreateTexture(nil, "BACKGROUND")
	bar.bg:SetAllPoints(bar)

	bar.text = bar:CreateFontString(nil, "OVERLAY")
	bar.text:SetPoint('CENTER', bar)
	bar.text:SetFontObject(SageBarFontSmall)
	
	bar.icon = bar:CreateTexture(nil, "ARTWORK")
	bar.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	bar.icon:SetWidth(14); bar.icon:SetHeight(14)
	bar.icon:SetPoint('LEFT')

	bar.id = parent.id or id
	bar.show = true

	bar:UpdateTexture()
	bar:Hide()
	bar:SetScript('OnUpdate', OnUpdate)

	bars[bar.id] = bar

	return bar
end

function SageCast:Update()
	if UnitChannelInfo(self.id) then
		self:OnSpellStart()
	elseif UnitCastingInfo(self.id) then
		self:OnChannelStart()
	else
		self:Finish()
	end
end

SageCast.UpdateTexture = SageStatusBar.UpdateTexture


--[[ Event Functions ]]--

function SageCast:OnSpellStart()
	local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(self.id)
	if not(name) or isTradeSkill then self:Hide() return end
	
	local target = self.id .. "target"
	if UnitExists(target) and UnitCanAssist(self.id, target) then
		self:SetStatusBarColor(0, 1, 1)
		self.bg:SetVertexColor(0, 0.6, 0.6, 0.4)
	else
		self:SetStatusBarColor(1, 0, 1)
		self.bg:SetVertexColor(0.6, 0, 0.6, 0.4)
	end

--	self:SetStatusBarColor(1, 0.7, 0)
--	self.bg:SetVertexColor(0.6, 0.42, 0, 0.4)
	self.startTime = startTime / 1000
	self.maxValue = endTime / 1000

	-- startTime to maxValue		no endTime
	self:SetMinMaxValues(self.startTime, self.maxValue)
	self:SetValue(self.startTime)
	self.text:SetText(text)

	if self.icon then
		self.icon:SetTexture(texture)
	end

	self.casting = 1
	self.channeling = nil

	if self.show then self:Show() end
end

function SageCast:OnSpellFail(isInterrupt)
	self:Finish()
end

function SageCast:OnSpellDelayed()
	if self:IsShown() then
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(self.id)
		if not(name) or isTradeSkill then self:Hide() return end

		self.startTime = startTime / 1000
		self.maxValue = endTime / 1000
		self:SetMinMaxValues(self.startTime, self.maxValue)

		if not self.casting then
			self:SetStatusBarColor(1, 0.7, 0)
			self.casting = 1
			self.channeling = nil
		end
	end
end

function SageCast:OnChannelStart()
	local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(self.id)
	if not(name) or isTradeSkill then self:Hide() return end

	local target = self.id .. "target"
	if UnitExists(target) and UnitCanAssist(self.id,  target) then
		self:SetStatusBarColor(0, 1, 1)
		self.bg:SetVertexColor(0, 0.6, 0.6, 0.4)
	else
		self:SetStatusBarColor(1, 0, 1)
		self.bg:SetVertexColor(0.6, 0, 0.6, 0.4)
	end

--	self:SetStatusBarColor(0, 1, 0)
--	self.bg:SetVertexColor(0, 0.6, 0, 0.4)
	self.startTime = startTime / 1000
	self.endTime = endTime / 1000
	self.duration = self.endTime - self.startTime
	self.maxValue = self.startTime

	self:SetMinMaxValues(self.startTime, self.endTime)
	self:SetValue(self.endTime)

	if self.icon then
		self.icon:SetTexture(texture)
	end

	self.casting = nil
	self.channeling = 1

	if self.show then self:Show() end
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

function SageCast:OnStop()
	self:Finish()
end


--[[ On Update Functions ]]--

function SageCast:OnUpdate()
	if self.casting then
		local value = min(GetTime(), self.maxValue)

		if value == self.maxValue then
			self:Finish()
		else
			self:SetValue(value)
			self.text:SetText(format('%.1fs', self.maxValue - value))
		end
	elseif self.channeling then
		local value = min(GetTime(), self.endTime)

		if value == self.endTime then
			self:Finish()
		else
			self:SetValue(self.startTime + (self.endTime - value))
			self.text:SetText(format('%.1fs', self.endTime - value))
		end
	end
end

function SageCast:Finish()
	self.casting = nil
	self.channeling = nil

	self:SetStatusBarColor(0, 1, 0)
	self:Hide()
end


--[[ Access ]]--

function SageCast.Get(id)
	return bars[id]
end


--[[ Events ]]--

BVent:AddAction('UNIT_SPELLCAST_START', function()
	local bar = SageCast.Get(arg1)
	if bar then
		bar:OnSpellStart()
	end
end)

--hide bar
BVent:AddAction('UNIT_SPELLCAST_STOP', function()
	local bar = SageCast.Get(arg1)
	if bar then
		bar:OnStop()
	end
end)

--hide bar?
BVent:AddAction('UNIT_SPELLCAST_FAILED', function()
	local bar = SageCast.Get(arg1)
	if bar then
		bar:OnSpellFail()
	end
end)

--casting stopped
BVent:AddAction('UNIT_SPELLCAST_INTERRUPTED', function()
	local bar = SageCast.Get(arg1)
	if bar then
		bar:OnSpellFail(true)
	end
end)

--casting delayed
BVent:AddAction('UNIT_SPELLCAST_DELAYED', function()
	local bar = SageCast.Get(arg1)
	if bar then
		bar:OnSpellDelayed()
	end
end)

--update casting
BVent:AddAction('UNIT_SPELLCAST_CHANNEL_START', function()
	local bar = SageCast.Get(arg1)
	if bar then
		bar:OnChannelStart()
	end
end)

--update channeling
BVent:AddAction('UNIT_SPELLCAST_CHANNEL_UPDATE', function()
	local bar = SageCast.Get(arg1)
	if bar then
		bar:OnChannelUpdate()
	end
end)

--hide bar
BVent:AddAction('UNIT_SPELLCAST_CHANNEL_STOP', function()
	local bar = SageCast.Get(arg1)
	if bar then
		bar:OnStop(true)
	end
end)

BVent:AddAction('PLAYER_ENTERING_WORLD', function()
	for _, bar in pairs(bars) do
		bar:Update()
	end
end)