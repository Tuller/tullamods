CSpell = Bongos:NewModule("Bongos-CSpell")


--[[ Constructor ]]--

local function Bar_OnCreate(self)
	local icon = self:CreateTexture(nil, "OVERLAY")
	icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	icon:SetAllPoints(self)
	icon:Hide()
	self.icon = icon

	local cooldown = CreateFrame("Cooldown", nil, self, "CooldownFrameTemplate")
	cooldown:SetAllPoints(self)
	cooldown:Hide()
	self.cooldown = cooldown

	self:SetSize(48)
end

function CSpell:Create(...)
	if(not self.frames) then self.frames = {} end

	for i = 1, select("#", ...) do
		local unit = select(i, ...)
		local frame = BBar:Create("spell" .. unit, Bar_OnCreate)

		self.frames[unit] = frame
		frame.unit = unit

		if(not frame:IsUserPlaced()) then
			frame:SetPoint("CENTER", UIParent)
		end
	end
end


--[[ Event Functions ]]--

function CSpell:Update(frame)
	if UnitChannelInfo(frame.unit) then
		self:OnSpellStart(frame)
	elseif UnitCastingInfo(frame.unit) then
		self:OnChannelStart(frame)
	else
		self:Finish(frame)
	end
end

function CSpell:OnSpellStart(frame)
	local name, nameSubtext, text, texture, startTime, endTime = UnitCastingInfo(frame.unit)
	if not(name) then frame.icon:Hide() return end

	frame.icon:SetTexture(texture)
	frame.icon:Show()

	frame.cooldown:SetReverse(false)
	CooldownFrame_SetTimer(frame.cooldown, startTime/1000, (endTime-startTime)/1000, 1)
end

function CSpell:OnSpellDelayed(frame)
	local name, nameSubtext, text, texture, startTime, endTime = UnitCastingInfo(frame.unit)
	if not(name) then frame.icon:Hide() return end

	CooldownFrame_SetTimer(frame.cooldown, startTime/1000, (endTime-startTime)/1000, 1)
end

function CSpell:OnChannelStart(frame)
	local name, nameSubtext, text, texture, startTime, endTime = UnitChannelInfo(frame.unit)
	if not(name) then frame.icon:Hide() return end

	frame.icon:SetTexture(texture)
	frame.icon:Show()

	frame.cooldown:SetReverse(true)
	CooldownFrame_SetTimer(frame.cooldown, startTime/1000, (endTime-startTime)/1000, 1)
	frame.channeling = true
end

function CSpell:OnChannelUpdate(frame)
	local name, nameSubtext, text, texture, startTime, endTime = UnitChannelInfo(frame.unit)
	if not(name) then frame.icon:Hide() return end

	frame.icon:SetTexture(texture)
	frame.icon:Show()

	CooldownFrame_SetTimer(frame.cooldown, startTime/1000, (endTime-startTime)/1000, 1)
end

function CSpell:Finish(frame)
	frame.icon:Hide()
	frame.cooldown:Hide()
	frame.channeling = nil
end

function CSpell:Get(unit)
	return self.frames and self.frames[unit]
end


--[[ Events ]]--

function CSpell:Load()
	self:Create("player", "target", "pet", "focus")

	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED")

	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")

	self:RegisterEvent("UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "OnSpellFinish")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "OnSpellFinish")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "OnSpellFinish")
end

function CSpell:Unload()
	if(self.frames) then
		for _,frame in pairs(self.frames) do
			frame:Destroy()
		end
	end
end

function CSpell:PLAYER_FOCUS_CHANGED(event)
	local frame = self:Get("focus")
	if(frame) then
		self:Update(frame)
	end
end

function CSpell:PLAYER_TARGET_CHANGED(event)
	local frame = self:Get("target")
	if(frame) then
		self:Update(frame)
	end
end

function CSpell:UNIT_SPELLCAST_START(event, unit)
	local frame = self:Get(unit)
	if(frame) then
		self:OnSpellStart(frame)
	end
end

function CSpell:UNIT_SPELLCAST_DELAYED(event, unit)
	local frame = self:Get(unit)
	if(frame) then
		self:OnSpellDelayed(frame)
	end
end

function CSpell:UNIT_SPELLCAST_CHANNEL_START(event, unit)
	local frame = self:Get(unit)
	if(frame) then
		self:OnChannelStart(frame)
	end
end

function CSpell:UNIT_SPELLCAST_CHANNEL_UPDATE(event, unit)
	local frame = self:Get(unit)
	if(frame) then
		self:OnChannelUpdate(frame)
	end
end

function CSpell:UNIT_SPELLCAST_STOP(event, unit)
	local frame = self:Get(unit)
	if(frame and not frame.channeling) then
		self:Finish(frame)
	end
end

function CSpell:OnSpellFinish(event, unit)
	local frame = self:Get(unit)
	if(frame) then
		self:Finish(frame)
	end
end