--[[
	Sage Pet
		A pet frame based on Sage
--]]

SagePet = Sage:NewModule("Sage-Pet")

local DEBUFF_SIZE = 25
local BUFF_SIZE = 16


--[[ Update Functions ]]--

local function Frame_UpdateCombatStatus(self)
	self.info.inCombat = self.inCombat
	self.info:UpdateNameColor()
end

local function Frame_Update(self)
	self:UpdateCombatStatus()

	self.info:UpdateAll()
	self.health:UpdateAll()
	self.mana:Update()
	self.buff:Update()
	self.debuff:Update()
end

local function Frame_OnCreate(self)
	self.Update = Frame_Update
	self.UpdateCombatStatus = Frame_UpdateCombatStatus

	local debuff = SageBuff:Create(self, self.id, nil, true)
	debuff:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -16)
	debuff:SetWidth(DEBUFF_SIZE * 2)
	debuff:SetHeight(DEBUFF_SIZE)
	self.extraWidth = (self.extraWidth or 0) + debuff:GetWidth()
	self.debuff = debuff

	local info = SageInfo:Create(self)
	info:SetPoint("TOPLEFT", self)
	info:SetPoint("BOTTOMRIGHT", self.debuff, "TOPLEFT")
	self.info = info

	local health = SageHealth:Create(self)
	health:SetPoint("TOPLEFT", self.info, "BOTTOMLEFT")
	health:SetPoint("BOTTOMRIGHT", self.info, "BOTTOMRIGHT", 0, -18)
	self.health = health

	local mana = SageMana:Create(self)
	mana:SetPoint("TOPLEFT", self.health, "BOTTOMLEFT")
	mana:SetPoint("BOTTOMRIGHT", self.health, "BOTTOMRIGHT", 0, -10)
	self.mana = mana

	local cast = SageCast:Create(self, nil, true)
	cast:SetPoint("TOPLEFT", self.mana, "TOPLEFT")
	cast:SetPoint("BOTTOMRIGHT", self.mana, "TOPRIGHT", 0, -2)
	cast.bar.icon:SetWidth(10); cast.bar.icon:SetHeight(10)
	self.cast = cast

	local buff = SageBuff:Create(self)
	buff:SetPoint("TOPLEFT", self.mana, "BOTTOMLEFT", 0, -1)
	buff:SetPoint("TOPRIGHT", self.mana, "BOTTOMRIGHT", 0, -1)
	buff:SetHeight(BUFF_SIZE)
	self.buff = buff

	if self.sets.showCombatText then
		SageCombat:Register(self)
	end

	self.click:SetPoint("TOPLEFT", self.info)
	self.click:SetPoint("BOTTOMRIGHT", self.mana)

	self:SetHeight(BUFF_SIZE + 10 + 18 + 16)
end


--[[ Events ]]--

function SagePet:Enable()
	PetFrame:UnregisterAllEvents()
	PetFrame:Hide()
end

function SagePet:Load()
	local defaults = {
		y = 1081.4287109375,
		x = 167.7142791748047,
		combatTextSize = 18,
		anchor = "playerRT",
		showCombatText = true,
		width = 100,
	}

	local frame = SageFrame:Create("pet", Frame_OnCreate, defaults)

	self.frame = frame
	frame.info:UpdateWidth()

	self:RegisterEvent("UNIT_PET")
	self:RegisterEvent("PET_ATTACK_START", "OnCombatEvent")
	self:RegisterEvent("PET_ATTACK_STOP", "OnCombatEvent")

	if(UnitExists("pet")) then
		self.frame:Update()
	end
end

function SagePet:Unload()
	self:UnregisterAllEvents()
	self.frame:Destroy()
end

function SagePet:UNIT_PET(event, unit)
	if(unit == "player") then
		self.frame:Update()
	end
end

function SagePet:OnCombatEvent(event)
	self.frame.inCombat = (event == "PET_ATTACK_START")
	self.frame:UpdateCombatStatus()
end

function SagePet:LoadOptions()
	SageOptions:AddPanel("Pet", self.frame.id)
end