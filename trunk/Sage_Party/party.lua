--[[
	Sage Party
		Sage based party frames
--]]

SageParty = Sage:NewModule("Sage-Party")

local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local MAX_PARTY_MEMBERS = 4
local DEBUFF_SIZE = 32
local BUFF_SIZE = 16


--[[ Pet Frame Code ]]--

local function PetFrame_OnShow(self)
	self:GetParent().buff:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
end

local function PetFrame_OnHide(self)
	local parent = self:GetParent()
	parent.buff:SetPoint("TOPLEFT", parent.mana, "BOTTOMLEFT")
end

local function PetFrame_Create(parent, id)
	local frame = SageClick:Create(parent, id)
	frame.health = SageHealth:Create(frame, id)
	frame.health:SetAllPoints(frame)
	frame:SetScript("OnShow", PetFrame_OnShow)
	frame:SetScript("OnHide", PetFrame_OnHide)
	frame:Hide()
	RegisterUnitWatch(frame)

	return frame
end


--[[ Frame Functions ]]--

local function Frame_Update(self)
	self.info.inCombat = UnitAffectingCombat(self.id)
	self.info:UpdateAll()
	self.health:UpdateAll()
	self.pet.health:UpdateAll()
	self.mana:Update()
	self.buff:Update()
	self.debuff:Update()
end

local function Frame_OnShow(self)
	self:Update()
end

local function Frame_OnCreate(self)
	self.Update = Frame_Update
	self.UpdateNameColor = Frame_UpdateNameColor

	self.debuff = SageBuff:Create(self, nil, nil, true)
	self.debuff:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -20)
	self.debuff:SetWidth(DEBUFF_SIZE * 2)
	self.debuff:SetHeight(DEBUFF_SIZE)
	self.extraWidth = (self.extraWidth or 0) + self.debuff:GetWidth()

	self.info = SageInfo:Create(self, nil, true)
	self.info:SetPoint("TOPLEFT", self)
	self.info:SetPoint("BOTTOMRIGHT", self.debuff, "TOPLEFT")

	self.health = SageHealth:Create(self)
	self.health:SetPoint("TOPLEFT", self.info, "BOTTOMLEFT")
	self.health:SetPoint("BOTTOMRIGHT", self.info, "BOTTOMRIGHT", 0, -20)

	self.mana = SageMana:Create(self)
	self.mana:SetPoint("TOPLEFT", self.health, "BOTTOMLEFT")
	self.mana:SetPoint("BOTTOMRIGHT", self.health, "BOTTOMRIGHT", 0, -12)

	self.cast = SageCast:Create(self, nil, true)
	self.cast:SetPoint("TOPLEFT", self.mana, "TOPLEFT")
	self.cast:SetPoint("BOTTOMRIGHT", self.mana, "TOPRIGHT", 0, -3)

	self.buff = SageBuff:Create(self)
	self.buff:SetWidth(BUFF_SIZE * 8)
	self.buff:SetHeight(BUFF_SIZE)

	self.pet = PetFrame_Create(self, "partypet" .. self.id:match("%d+"))
	self.pet:SetPoint("TOPLEFT", self.mana, "BOTTOMLEFT")
	self.pet:SetPoint("BOTTOMRIGHT", self.mana, "BOTTOMRIGHT", 0, -12)

	if self.sets.showCombatText then
		SageCombat:Register(self)
	end

	self.click:SetPoint("TOPLEFT", self.info)
	self.click:SetPoint("BOTTOMRIGHT", self.mana)

	self:SetScript("OnShow", Frame_OnShow)
	self:SetHeight(BUFF_SIZE + 20 + 20 + 12 + 12)
end


--[[ Events ]]--

--range checking code, taken from perfectraid
local function PartyParent_Create()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetFrameLevel(0); frame:Hide()

	local spells = {
		["DRUID"] = "Healing Touch",
		["SHAMAN"] = "Healing Wave",
		["PRIEST"] = "Lesser Heal",
		["PALADIN"] = "Holy Light",
	}
	local spell = spells[select(2, UnitClass("player"))]

	if(spell) then
		frame:SetScript("OnUpdate", function(self, elapsed)
			self.nextUpdate = (self.nextUpdate or 0) - elapsed
			if(self.nextUpdate <= 0) then
				self.nextUpdate = 1
				for i = 1, MAX_PARTY_MEMBERS do
					local frame = SageFrame:Get("party" .. i)
					if(IsSpellInRange(spell, frame.id) == 1) then
						frame:SetAlpha(frame:GetFrameAlpha())
					else
						frame:SetAlpha(0.6 * frame:GetFrameAlpha())
					end
				end
			end
		end)
	end

	return frame
end

function SageParty:ShouldShow()
	return GetNumPartyMembers() > 0 and (GetNumRaidMembers() <= 5 or Sage:ShowingPartyInRaid())
end

function SageParty:GetDefaults()
	return  {
		{
			x = 11, y = 629,
			minWidth = 100,
			showCombatText = true,
			anchor = "petBL",
			combatTextSize = 24,
			showCastable = true
		},
		{
			x = 20, y = 956,
			minWidth = 100,
			showCombatText = true,
			anchor = "party1BL",
			combatTextSize = 24,
			showCastable = true
		},
		{
			x = 20, y = 904,
			minWidth = 100,
			showCombatText = true,
			anchor = "party2BL",
			combatTextSize = 24,
			showCastable = true
		},
		{
			x = 20, y = 852,
			minWidth = 100,
			showCombatText = true,
			anchor = "party3BL",
			combatTextSize = 24,
			showCastable = true
		},
	}
end

function SageParty:Enable()
	ShowPartyFrame = function() return end
	for i = 1, MAX_PARTY_MEMBERS do
		getglobal(format("PartyMemberFrame%d", i)):UnregisterAllEvents()
		getglobal(format("PartyMemberFrame%dHealthBar", i)):UnregisterAllEvents()
		getglobal(format("PartyMemberFrame%dManaBar", i)):UnregisterAllEvents()
	end
	HidePartyFrame()

	self.frames = {}
end

function SageParty:Load()
	if(not self.frames) then self.frames = {} end
	self.parent = self.parent or PartyParent_Create()
	self.parent:SetFrameLevel(0)

	local defaults = SageParty:GetDefaults()
	for i = 1, MAX_PARTY_MEMBERS do
		local frame = SageFrame:Create("party" .. i, Frame_OnCreate, defaults[i])
		frame:SetParent(self.parent)
		frame:SetFrameLevel(0)
		frame:SetID(i)
		frame.info:UpdateWidth()
		self.frames[i] = frame
	end

	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "UpdateMembers")
	self:RegisterEvent("RAID_ROSTER_UPDATE", "UpdateMembers")
	self:RegisterEvent("UNIT_FLAGS", "UpdateAggro")
	self:UpdateMembers()
end

function SageParty:Unload()
	self:UnregisterAllEvents()
	for _,frame in pairs(self.frames) do
		frame:Destroy()
	end
end

function SageParty:UpdateMembers(event)
	if self:ShouldShow() then
		self.parent:Show()
		for _, frame in pairs(self.frames) do
			frame:Update()
		end
	else
		self.parent:Hide()
	end
end

function SageParty:UpdateAggro(event, unit)
	if(self.parent:IsShown()) then
		for _,frame in pairs(self.frames) do
			local prevFlag = frame.info.inCombat
			frame.info.inCombat = UnitAffectingCombat(frame.id)
			if(prevFlag ~= frame.info.inCombat) then
				frame.info:UpdateNameColor()
			end
		end
	end
end