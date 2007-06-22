--[[
	Sage Pet
		A pet frame based on Sage
--]]

SagePet = Sage:NewModule("Sage-Pet")

local DEBUFF_SIZE = 25
local BUFF_SIZE = 16


--[[  Templates ]]--

local function HappyFrame_OnEnter(self)
	if self.tooltip then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tooltip)
		if self.tooltipDamage then
			GameTooltip:AddLine(self.tooltipDamage, "", 1, 1, 1)
		end
		if self.tooltipLoyalty then
			GameTooltip:AddLine(self.tooltipLoyalty, "", 1, 1, 1)
		end
		GameTooltip:Show()
	end
end

local function HappyFrame_OnLeave() GameTooltip:Hide() end

local function HappyFrame_Update(self)
	local happiness, damagePercentage, loyaltyRate = GetPetHappiness()
	local hasPetUI, isHunterPet = HasPetUI()

	if not(happiness and isHunterPet) then
		self:Hide()
	else
		self:Show()

		if happiness == 1 then
			self.icon:SetTexCoord(0.375, 0.5625, 0, 0.359375)
		elseif happiness == 2 then
			self.icon:SetTexCoord(0.1875, 0.375, 0, 0.359375)
		elseif happiness == 3 then
			self.icon:SetTexCoord(0, 0.1875, 0, 0.359375)
		end

		self.tooltip = getglobal("PET_HAPPINESS".. happiness)
		self.tooltipDamage = format(PET_DAMAGE_PERCENTAGE, damagePercentage)

		if loyaltyRate < 0 then
			self.tooltipLoyalty = LOSING_LOYALTY
		elseif loyaltyRate > 0 then
			self.tooltipLoyalty = GAINING_LOYALTY
		else
			self.tooltipLoyalty = nil
		end
	end
end

local function HappyFrame_Create(parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetWidth(26); frame:SetHeight(30)
	frame:EnableMouse(true)

	frame.icon = frame:CreateTexture(nil, "BACKGROUND")
	frame.icon:SetTexture("Interface\\PetPaperDollFrame\\UI-PetHappiness")
	frame.icon:SetAllPoints(frame)
	frame.Update = HappyFrame_Update

	frame:SetScript("OnEnter", HappyFrame_OnEnter)
	frame:SetScript("OnLeave", HappyFrame_OnLeave)

	return frame
end


--[[ Update Functions ]]--

local function Frame_UpdateCombatStatus(self)
	self.info.inCombat = self.inCombat
	self.info:UpdateNameColor()
end

local function Frame_Update(self)
	self:UpdateCombatStatus()

	if self.happy then self.happy:Update() end
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

	if select(2, UnitClass("player")) == "HUNTER" then
		local happy = HappyFrame_Create(self)
		happy:SetPoint("TOPRIGHT", self.debuff, "TOPLEFT", 0, 2)
		self.extraWidth = (self.extraWidth or 0) + happy:GetWidth()
		self.happy = happy
	end

	local info = SageInfo:Create(self)
	info:SetPoint("TOPLEFT", self)
	if self.happy then
		info:SetPoint("BOTTOMRIGHT", self.happy, "TOPLEFT", 0, -2)
	else
		info:SetPoint("BOTTOMRIGHT", self.debuff, "TOPLEFT")
	end
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
	buff:SetWidth(BUFF_SIZE * 8); buff:SetHeight(BUFF_SIZE)
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
		x = 11, y = 691, width = 70,
		anchor = "playerBL",
		combatTextSize = 18,
		showCombatText = true
	}

	local frame = SageFrame:Create("pet", Frame_OnCreate, defaults)
	frame:SetAttribute("showstates", "1")

	self.frame = frame
	frame.info:UpdateWidth()

	self:RegisterEvent("UNIT_PET")
	self:RegisterEvent("PET_ATTACK_START", "OnCombatEvent")
	self:RegisterEvent("PET_ATTACK_STOP", "OnCombatEvent")
	if frame.happy then
		self:RegisterEvent("UNIT_HAPPINESS")
	end
	
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

function SagePet:UNIT_HAPPINESS(event, unit)
	if(unit == "pet") then
		self.frame.happy:Update()
	end
end

function SagePet:OnCombatEvent(event)
	self.frame.inCombat = (event == "PET_ATTACK_START")
	self.frame:UpdateCombatStatus()
end

function SagePet:LoadOptions()
	local panel = SageOptions:AddPanel("Pet", "pet")
end