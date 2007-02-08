--[[
	Sage Party
		Party frames based on Sage
--]]

--local constants
local MAX_PARTY_MEMBERS = 4
local DEBUFF_SIZE = 32
local BUFF_SIZE = 16
local SageParty = CreateFrame('Frame', nil, UIParent)

--local globals
local frames = {}

local function CanShowParty()
	return GetNumPartyMembers() > 0 and (GetNumRaidMembers() == 0 or SageDB.alwaysShowParty)
end


--[[
	Individual Party Frame Code
--]]

--[[ Update Functions ]]--

local function LayoutBuffs(self, count)
	self:LayoutIcons(count)
end

local function LayoutDebuffs(self, count)
	self:LayoutIcons(count)
end

--color red in combat, else if we know the unit's class, color it that, else color grey
local function UpdateNameColor(frame)
	if SComm and SComm.InCombat(frame.id) then
		frame.info.name:SetTextColor(1, 0.3, 0.3)
	else
		local class = select(2, UnitClass(frame.id))
		if class then
			local color = RAID_CLASS_COLORS[class]
			frame.info.name:SetTextColor(color.r, color.g, color.b)
		else
			frame.info.name:SetTextColor(0.7, 0.7, 0.7)
		end
	end
end

local function UpdatePet(frame)
	if UnitExists(frame.pet.id) then
		SeeQ:ShowFrame(frame.pet)
	else
		SeeQ:HideFrame(frame.pet)
	end
end

--update everything about the target
local function UpdateAll(frame)
	UpdateNameColor(frame)
	UpdatePet(frame)

	frame.info:UpdateAll()
	frame.health:UpdateAll()
	frame.mana:Update()
	frame.buff:Update()
	frame.debuff:Update()
end
SParty_UpdateAll = UpdateAll

--[[
	Event Handler Code
--]]

--[[ Update Functions ]]--

local function UpdateMembers()
	if not CanShowParty() then
		SageParty:Hide()
	else
		SageParty:Show()
		for _, frame in pairs(frames) do
			UpdateAll(frame)
		end
	end
end
SParty_UpdateMembers = UpdateMembers

local function UpdateLeader()
	local leader = GetPartyLeaderIndex()
	if leader then
		for _, frame in pairs(frames) do
			if leader == frame:GetID() then
				frame.info.leader:Show()
			else
				frame.info.leader:Hide()
			end
		end
	else
		for _, frame in pairs(frames) do
			frame.info.leader:Hide()
		end
	end
end

local function UpdateMasterLooter()
	local lootMaster = select(2, GetLootMethod())
	if lootMaster then
		for _, frame in pairs(frames) do
			if lootMaster == frame:GetID() then
				frame.info.masterLoot:Show()
			else
				frame.info.masterLoot:Hide()
			end
			frame.info:UpdateWidth()
		end
	else
		for _, frame in pairs(frames) do
			frame.info.masterLoot:Hide()
			frame.info:UpdateWidth()
		end
	end
end

local function OnPetUpdate(_, _, unit)
	for _, frame in pairs(frames) do
		UpdatePet(frame)
	end
end

--[[ OnX ]]--

local function OnCombatUpdate(_, _, unit)
	local frame = frames[unit]
	if frame then
		UpdateNameColor(frame)
	end
end

--[[ Startup ]]--

local function AddEvents()
	BVent:AddAction('PARTY_MEMBERS_CHANGED', UpdateMembers)
	BVent:AddAction('RAID_ROSTER_UPDATE', UpdateMembers)
	BVent:AddAction('PARTY_LEADER_CHANGED', UpdateLeader)
	BVent:AddAction('PARTY_LOOT_METHOD_CHANGED', UpdateMasterLooter)
	BVent:AddAction('SAGE_COMBAT_UPDATE', OnCombatUpdate)
	BVent:AddAction('UNIT_PET', OnPetUpdate)
end

local function RemoveEvents()
	BVent:RemoveAction('PARTY_MEMBERS_CHANGED', UpdateMembers)
	BVent:RemoveAction('RAID_ROSTER_UPDATE', UpdateMembers)
	BVent:RemoveAction('PARTY_LEADER_CHANGED', UpdateLeader)
	BVent:RemoveAction('PARTY_LOOT_METHOD_CHANGED', UpdateMasterLooter)
	BVent:RemoveAction('SAGE_COMBAT_UPDATE', OnCombatUpdate)
	BVent:RemoveAction('UNIT_PET', OnPetUpdate)
end

local function OnPetShow()
	local parent = this:GetParent()
	parent:SetHeight(parent:GetHeight() + 18)
	parent.buff:ClearAllPoints()
	parent.buff:SetPoint("TOPLEFT", this, "BOTTOMLEFT")	
end

local function OnPetHide()
	local parent = this:GetParent()
	parent:SetHeight(parent:GetHeight() - 18)
	parent.buff:ClearAllPoints()
	parent.buff:SetPoint("TOPLEFT", parent.mana, "BOTTOMLEFT")	
end

local function OnCreate(self)
	self.debuff = SageDebuff.Create(self, LayoutDebuffs)
	self.debuff:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -20)
	self.debuff:SetWidth(DEBUFF_SIZE * 2)
	self.debuff:SetHeight(DEBUFF_SIZE)
	self.extraWidth = (self.extraWidth or 0) + self.debuff:GetWidth()

	self.info = SageInfo.Create(self, true)
	self.info:SetPoint("TOPLEFT", self)
	self.info:SetPoint("BOTTOMRIGHT", self.debuff, "TOPLEFT")

	self.health = SageHealth.Create(self)
	self.health:SetPoint("TOPLEFT", self.info, "BOTTOMLEFT")
	self.health:SetPoint("BOTTOMRIGHT", self.info, "BOTTOMRIGHT", 0, -20)

	self.mana = SageMana.Create(self)
	self.mana:SetPoint("TOPLEFT", self.health, "BOTTOMLEFT")
	self.mana:SetPoint("BOTTOMRIGHT", self.health, "BOTTOMRIGHT", 0, -12)

	self.pet = SagePartyPet.Create(self)
	self.pet:SetPoint("TOPLEFT", self.mana, "BOTTOMLEFT")
	self.pet:SetPoint("BOTTOMRIGHT", self.mana, "BOTTOMRIGHT", 0, -18)
	self.pet:SetScript('OnShow', OnPetShow)	
	self.pet:SetScript('OnHide', OnPetHide)

	self.buff = SageBuff.Create(self, LayoutBuffs)
	self.buff:SetPoint("TOPLEFT", self.mana, "BOTTOMLEFT")
	self.buff:SetWidth(BUFF_SIZE * 8)
	self.buff:SetHeight(BUFF_SIZE)

	if self.sets.showCombatText then
		SageCombatText.Register(self)
	end
	
	self.click:SetPoint('TOPLEFT', self.info)
	self.click:SetPoint('BOTTOMRIGHT', self.mana)

	self:SetHeight(BUFF_SIZE + 20 + 20 + 12)
	UpdatePet(self)

	frames[self.id] = self
end

local function UnregisterBlizzParty()
	ShowPartyFrame = function() return end
	for i = 1, MAX_PARTY_MEMBERS do
		getglobal(format("PartyMemberFrame%d", i)):UnregisterAllEvents()
		getglobal(format("PartyMemberFrame%dHealthBar", i)):UnregisterAllEvents()
		getglobal(format("PartyMemberFrame%dManaBar", i)):UnregisterAllEvents()
	end
	HidePartyFrame()
end

local function LoadDefaults()
	if not Sage.GetFrameSets('party1') then
		Sage.SetFrameSets('party1', {
			["combatTextSize"] = 24,
			["x"] = 10.99999888241293,
			["showCombatText"] = 1,
			["anchor"] = "petBL",
			["minWidth"] = 100,
			["y"] = 628.9999677389865
		})
	end

	if not Sage.GetFrameSets('party2') then
		Sage.SetFrameSets('party2', {
			["combatTextSize"] = 24,
			["x"] = 20,
			["showCombatText"] = 1,
			["anchor"] = "party1BL",
			["minWidth"] = 100,
			["y"] = 956,
		})
	end

	if not Sage.GetFrameSets('party3') then
		Sage.SetFrameSets('party3', {
			["combatTextSize"] = 24,
			["x"] = 20,
			["showCombatText"] = 1,
			["anchor"] = "party2BL",
			["minWidth"] = 100,
			["y"] = 904,
		})
	end

	if not Sage.GetFrameSets('party4') then
		Sage.SetFrameSets('party4', {
			["combatTextSize"] = 24,
			["x"] = 20,
			["showCombatText"] = 1,
			["anchor"] = "party3BL",
			["minWidth"] = 100,
			["y"] = 852,
		})
	end
end

Sage.AddStartup(function()
	UnregisterBlizzParty()

	LoadDefaults()

	for i = 1, MAX_PARTY_MEMBERS do
		local frame
		if i == 1 then
			frame = SageFrame.Create(format('party%d', i), OnCreate, RemoveEvents)
		else
			frame = SageFrame.Create(format('party%d', i), OnCreate)
		end
		frame:SetID(i)
		frame:SetParent(SageParty)
		frame.info:UpdateWidth()
	end

	AddEvents()
	UpdateMembers()
end)