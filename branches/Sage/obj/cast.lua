--[[
	SageCast.lua
		Unit casting bars
--]]

SageCast = CreateFrame("StatusBar")
local Bar_MT = {__index = SageCast}

--[[ Constructor ]]--

local function Frame_Update(self) self.bar:Update() end
local function Bar_OnUpdate(self) self:OnUpdate() end

function SageCast:Create(parent, id, noText)
	local frame = CreateFrame("Frame", nil, parent)
	frame.id = id or parent.id
	frame.Update = Frame_Update
	frame:SetScript("OnShow", Frame_Update)

	local bar
	if(noText) then
		bar = setmetatable(SageBar:Create(frame, id), Bar_MT)
	else
		bar = setmetatable(SageBar:Create(frame, id, SageFont:GetSmallBarFont(), true), Bar_MT)
	end
	bar:Hide()
	bar:SetScript("OnUpdate", Bar_OnUpdate)
	bar:UpdateTexture()
	frame.bar = bar

	local icon = bar:CreateTexture(nil, "OVERLAY")
	icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	icon:SetWidth(12); icon:SetHeight(12)
	bar.icon = icon

	icon:SetPoint("TOPLEFT", frame)
	bar:SetPoint("TOPLEFT", icon, "TOPRIGHT")
	bar:SetPoint("BOTTOMRIGHT", frame)

	if(not self.bars) then self.bars = {} end
	self.bars[bar.id] = bar

	return frame
end

function SageCast:Update()
	if(Sage:ShowingCastBars()) then
		if UnitCastingInfo(self.id) then
			self:OnSpellStart()
		elseif UnitChannelInfo(self.id) then
			self:OnChannelStart()
		else
			self:Finish()
		end
	else
		self:Finish()
	end
end

SageCast.UpdateTexture = SageBar.UpdateTexture


--[[ Event Functions ]]--

function SageCast:OnSpellStart()
	local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(self.id)
	if not(name) or isTradeSkill then self:Hide() return end

	--bar coloring, only really works for people who do not clickcast
	if IsHelpfulSpell(name) then
		self:SetStatusBarColor(0, 1, 1)
		self.bg:SetVertexColor(0, 0.6, 0.6, 0.4)
	elseif IsHarmfulSpell(name) then
		self:SetStatusBarColor(1, 0, 1)
		self.bg:SetVertexColor(0.6, 0, 0.6, 0.4)
	else
		self:SetStatusBarColor(1, 1, 0)
		self.bg:SetVertexColor(0.6, 0.6, 0, 0.4)
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
			self:SetStatusBarColor(1, 0.7, 0)
			self.casting = true
			self.channeling = nil
		end
	end
end

function SageCast:OnChannelStart()
	local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(self.id)
	if not(name) or isTradeSkill then self:Hide() return end

	local target = self.id .. "target"
	if self.text and UnitExists(target) then
		if UnitCanAssist(self.id,  target) then
			self:SetStatusBarColor(0, 1, 1)
			self.bg:SetVertexColor(0, 0.6, 0.6, 0.4)
		else
			self:SetStatusBarColor(1, 0, 1)
			self.bg:SetVertexColor(0.6, 0, 0.6, 0.4)
		end
	else
		self:SetStatusBarColor(1, 1, 0)
		self.bg:SetVertexColor(0.6, 0.6, 0, 0.4)
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
			if(self.text) then
				self.text:SetText(format("%.1fs", self.maxValue - value))
			end
		end
	elseif self.channeling then
		local value = min(GetTime(), self.endTime)

		if value == self.endTime then
			self:Finish()
		else
			self:SetValue(self.startTime + (self.endTime - value))
			if(self.text) then
				self.text:SetText(format("%.1fs", self.endTime - value))
			end
		end
	end
end

function SageCast:OnSpellStop()
	if(not self.channeling) then
		self:Finish()
	end
end

function SageCast:Finish()
	self.casting = nil
	self.channeling = nil

	self:SetStatusBarColor(0, 1, 0)
	self:Hide()
end


--[[ Utility Functions ]]--

--sets whether to color health when debuffed or not
function SageCast:ForAll(method, ...)
	local bars = self.bars
	if(bars) then
		for _,bar in pairs(bars) do
			bar[method](bar, ...)
		end
	end
end

function SageCast:ForUnit(unit, method, ...)
	local bar = self:Get(unit)
	if(bar) then
		bar[method](bar, ...)
	end
end

function SageCast:Get(id)
	return self.bars and self.bars[id]
end


--[[ Events ]]--

function SageCast:PLAYER_ENTERING_WORLD()
	self:ForAll("Update")
end

function SageCast:UNIT_SPELLCAST_START(unit)
	self:ForUnit(unit, "OnSpellStart")
end

function SageCast:UNIT_SPELLCAST_DELAYED(unit)
	self:ForUnit(unit, "OnSpellDelayed")
end

function SageCast:UNIT_SPELLCAST_CHANNEL_START(unit)
	self:ForUnit(unit, "OnChannelStart")
end

function SageCast:UNIT_SPELLCAST_CHANNEL_UPDATE(unit)
	self:ForUnit(unit, "OnChannelUpdate")
end

--finish events
function SageCast:UNIT_SPELLCAST_STOP(unit)
	self:ForUnit(unit, "OnSpellStop")
end

function SageCast:UNIT_SPELLCAST_FAILED(unit)
	self:ForUnit(unit, "Finish")
end

function SageCast:UNIT_SPELLCAST_INTERRUPTED(unit)
	self:ForUnit(unit, "Finish")
end

function SageCast:UNIT_SPELLCAST_CHANNEL_STOP(unit)
	self:ForUnit(unit, "Finish")
end