--[[
	Sage Pet
		A pet frame based on Sage
--]]

local DEBUFF_SIZE = 25
local BUFF_SIZE = 16
local inCombat

--[[  Templates ]]--

local function HappyFrame_OnEnter()
	if this.tooltip then
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetText(this.tooltip)
		if this.tooltipDamage then
			GameTooltip:AddLine(this.tooltipDamage, "", 1, 1, 1)
		end
		if this.tooltipLoyalty then
			GameTooltip:AddLine(this.tooltipLoyalty, "", 1, 1, 1)
		end
		GameTooltip:Show()
	end
end

local function HappyFrame_OnLeave()
	GameTooltip:Hide()
end

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

		self.tooltip = getglobal('PET_HAPPINESS'.. happiness)
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
	frame:SetWidth(26)
	frame:SetHeight(30)
	frame:SetAlpha(parent:GetAlpha())
	frame:EnableMouse(true)
	
	frame.icon = frame:CreateTexture(nil, 'BACKGROUND')
	frame.icon:SetTexture("Interface\\PetPaperDollFrame\\UI-PetHappiness")
	frame.icon:SetAllPoints(frame)
	frame.Update = HappyFrame_Update
	
	frame:SetScript("OnEnter", HappyFrame_OnEnter)
	frame:SetScript("OnLeave", HappyFrame_OnLeave)
	
	return frame
end

--[[ Update Functions ]]--

local function LayoutBuffs(self, count)
	self:LayoutIcons(count)
end

local function LayoutDebuffs(self, count)
	self:LayoutIcons(count)
end

local function UpdateCombatStatus(frame)
	if inCombat then
		frame.info.name:SetTextColor(1,0.4,0.4)
	else
		frame.info.name:SetTextColor(1,1,1)
	end
end

local function UpdateAll(frame)
	UpdateCombatStatus(frame)

	if frame.happy then
		frame.happy:Update()
	end
	frame.info:UpdateAll()
	frame.health:UpdateAll()
	frame.mana:Update()
	frame.buff:Update()
	frame.debuff:Update()
end

--[[ Event Handler ]]--

local function OnEvent()
	if event == 'UNIT_PET' and arg1 == 'player' then
		UpdateAll(this)
	elseif event == 'PET_ATTACK_START' then
		inCombat = true
		UpdateCombatStatus(this)
	elseif event == 'PET_ATTACK_STOP' then
		inCombat = nil
		UpdateCombatStatus(this)
	elseif event == 'UNIT_HAPPINESS' and arg1 == 'pet' then
		this.happy:Update()
	end
end

--[[ Startup Functions ]]--

local function AddEvents(frame)
	frame:SetScript("OnEvent", OnEvent)
	
	frame:RegisterEvent("UNIT_PET")
	frame:RegisterEvent("PET_ATTACK_START")
	frame:RegisterEvent("PET_ATTACK_STOP")
	if frame.happy then
		frame:RegisterEvent("UNIT_HAPPINESS")
	end
end

--this function adds all the stuff to the pet frame, like healthbars and the unit's name
local function UnregsterBlizzPetFrame()
	PetFrame:UnregisterAllEvents()
	PetFrame:Hide()
end

local function OnCreate(self)
	UnregsterBlizzPetFrame()
	
	local PLAYER_CLASS = select(2, UnitClass('player'))
	
	self.debuff = SageDebuff.Create(self, LayoutDebuffs)
	self.debuff:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -16)
	self.debuff:SetWidth(DEBUFF_SIZE * 2)
	self.debuff:SetHeight(DEBUFF_SIZE)
	self.extraWidth = (self.extraWidth or 0) + self.debuff:GetWidth()

	if PLAYER_CLASS == "HUNTER" then
		self.happy = HappyFrame_Create(self)
		self.happy:SetPoint("TOPRIGHT", self.debuff, "TOPLEFT", 0, 2)
		self.extraWidth = (self.extraWidth or 0) + self.happy:GetWidth()
	end

	self.info = SageInfo.Create(self)
	self.info:SetPoint("TOPLEFT", self)
	if self.happy then
		self.info:SetPoint("BOTTOMRIGHT", self.happy, "TOPLEFT", 0, -2)
	else
		self.info:SetPoint("BOTTOMRIGHT", self.debuff, "TOPLEFT")
	end

	self.health = SageHealth.Create(self)
	self.health:SetPoint("TOPLEFT", self.info, "BOTTOMLEFT")
	self.health:SetPoint("BOTTOMRIGHT", self.info, "BOTTOMRIGHT", 0, -18)

	self.mana = SageMana.Create(self)
	self.mana:SetPoint("TOPLEFT", self.health, "BOTTOMLEFT")
	self.mana:SetPoint("BOTTOMRIGHT", self.health, "BOTTOMRIGHT", 0, -10)

	self.buff = SageBuff.Create(self, LayoutBuffs)
	self.buff:SetPoint("TOPLEFT", self.mana, "BOTTOMLEFT", 0, -1)
	self.buff:SetWidth(BUFF_SIZE * 8)
	self.buff:SetHeight(BUFF_SIZE)
	
	if self.sets.showCombatText then
		SageCombatText.Register(self)
	end
	
	self.click:SetPoint('TOPLEFT', self.info)
	self.click:SetPoint('BOTTOMRIGHT', self.mana)
	
	self:SetHeight(BUFF_SIZE + 10 + 18 + 16)
end

Sage.AddStartup(function()
	if not Sage.GetFrameSets('pet') then
		Sage.SetFrameSets('pet', {
			["combatTextSize"] = 18,
			["x"] = 10.99999888241293,
			["showCombatText"] = 1,
			["anchor"] = "playerBL",
			["minWidth"] = 70,
			["y"] = 690.9999744445089,
		})
	end

	local frame = SageFrame.Create('pet', OnCreate)
	frame.info:UpdateWidth()
	AddEvents(frame)
end)