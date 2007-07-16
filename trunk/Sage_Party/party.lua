--[[
	Sage Party
		Sage based party frames
--]]

SageParty = Sage:NewModule("Sage-Party")

local L = SAGE_LOCALS
L.ShowInRaid = "Show Party in Raid"
L.EnableRangeCheck = "Fade out of Range"

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
	frame.health.UpdateText = function(self)
		self.mode = parent.health.mode
		SageHealth.UpdateText(self)
	end
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
	self:SetFrameLevel(0)
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
	frame:Hide()
	return frame
end

function SageParty:ShouldShow()
	return GetNumPartyMembers() > 0 and (GetNumRaidMembers() <= 5 or self:ShowingInRaid())
end

function SageParty:GetDefaults()
	return  {
		{
			width = 120,
			y = 916.4287109375,
			x = 11.71428298950195,
			combatTextSize = 24,
			showCombatText = true,
			anchor = "focusBR",
			textMode = 2,
			showCastable = true,
		},
		{
			width = 120,
			y = 834.4287719726563,
			x = 11.71428298950195,
			combatTextSize = 24,
			anchor = "party1BC",
			textMode = 2,
			showCombatText = true,
			showCastable = true,
		},
		{
			width = 120,
			y = 752.4287719726563,
			x = 11.71428298950195,
			combatTextSize = 24,
			anchor = "party2BC",
			textMode = 2,
			showCombatText = true,
			showCastable = true,
		},
		{
			width = 120,
			y = 670.4288330078125,
			x = 11.71428298950195,
			combatTextSize = 24,
			anchor = "party3BC",
			textMode = 2,
			showCombatText = true,
			showCastable = true,
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
end

function SageParty:Load()
	if(not self.motherFrames) then self.motherFrames = {} end
	self.motherFrame = self.motherFrame or PartyParent_Create()
	self.motherFrame:SetFrameLevel(0)

	local defaults = SageParty:GetDefaults()
	for i = 1, MAX_PARTY_MEMBERS do
		local frame = SageFrame:Create("party" .. i, Frame_OnCreate, defaults[i])
		frame:SetParent(self.motherFrame)
		frame:SetFrameLevel(0)
		frame:SetID(i)
		frame.info:UpdateWidth()
		self.motherFrames[i] = frame
	end

	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "UpdateMembers")
	self:RegisterEvent("RAID_ROSTER_UPDATE", "UpdateMembers")
	self:RegisterEvent("UNIT_DYNAMIC_FLAGS", "UpdateAggro")
	self:RegisterEvent("UNIT_FLAGS", "UpdateAggro")
	self:SetRangeSpell(self:GetRangeSpell())
	self:UpdateMembers()
end

function SageParty:Unload()
	self:UnregisterAllEvents()
	for _,frame in pairs(self.motherFrames) do
		frame:Destroy()
	end
end

function SageParty:PLAYER_REGEN_ENABLED()
	if self:ShouldShow() then
		self.motherFrame:Show()
	else
		self.motherFrame:Hide()
	end
end

function SageParty:UpdateMembers()
	if self:ShouldShow() then
		self.motherFrame:Show()
		for _, frame in pairs(self.motherFrames) do
			frame:Update()
		end
	else
		self.motherFrame:Hide()
	end
end

function SageParty:UpdateAggro(event, unit)
	if(self.motherFrame:IsShown()) then
		for i in pairs(self.motherFrames) do
			if(unit == "party" .. i) then
				local info = SageInfo:Get(unit)
				local inCombat = UnitAffectingCombat(unit)
				if(info.inCombat ~= inCombat) then
					info.inCombat = inCombat
					info:UpdateNameColor()
				end
				return
			end
		end
	end
end

function SageParty:LoadOptions()
	local panel = SageOptions:AddPanel("Party")

	--show party in raid
	local function ShowInRaid_OnClick(self)
		SageParty:SetShowInRaid(self:GetChecked())
	end
	local function ShowInRaid_OnShow(self)
		self:SetChecked(SageParty:ShowingInRaid())
	end
	panel:AddCheckButton(L.ShowInRaid, ShowInRaid_OnClick, ShowInRaid_OnShow)
	
	local function RangeCheck_OnClick(self)
		SageParty:SetRangeCheck(self:GetChecked())
	end
	local function RangeCheck_OnShow(self)
		self:SetChecked(SageParty:CheckingRange())
	end
	local button = panel:AddCheckButton(L.EnableRangeCheck, RangeCheck_OnClick, RangeCheck_OnShow)
	
	--range check button
	local icon = CreateFrame("Button", nil, button)
	icon:SetWidth(24); icon:SetHeight(24)
	icon:SetPoint("LEFT", button:GetName() .. "Text", "RIGHT", 4, 0)
	icon:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
	icon:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
	icon:RegisterForDrag("LeftButton")
	icon:SetScript("OnReceiveDrag", function(self)
		if CursorHasSpell() then
			local id, book = select(2, GetCursorInfo())
			if(SpellHasRange(GetSpellName(id, book))) then
				self:SetNormalTexture(GetSpellTexture(id, book))
				SageParty:SetRangeSpell(GetSpellName(id, book))
			end
			ClearCursor()
		end
	end)
	icon:SetScript("OnShow", function(self)
		self:SetNormalTexture(SageParty:GetRangeSpellIcon())
	end)
	icon:SetScript("OnClick", function() 
		if(SpellBookFrame:IsShown()) then 
			HideUIPanel(SpellBookFrame) 
		else 
			ShowUIPanel(SpellBookFrame)
		end
	end)

	panel:AddUnitOptions("party")
end

function SageParty:ShowingInRaid()
	return HIDE_PARTY_INTERFACE == "0"
end

function SageParty:SetShowInRaid(enable)
	HIDE_PARTY_INTERFACE = (enable and "0") or "1"
	self:UpdateMembers()
end


--[[ Out of Range Checking ]]--

local function RangeCheck_OnUpdate(self, elapsed)
	self.nextUpdate = (self.nextUpdate or 0) - elapsed
	if(self.nextUpdate <= 0) then
		self.nextUpdate = 1
		local spell = self.spell
		for i = 1, MAX_PARTY_MEMBERS do
			local frame = SageFrame:Get("party" .. i)
			if(frame) then
				if(IsSpellInRange(spell, frame.id) == 1) then
					frame:SetAlpha(frame:GetFrameAlpha())
				else
					frame:SetAlpha(0.6 * frame:GetFrameAlpha())
				end
			end
		end
	end
end

function SageParty:SetRangeCheck(enable)
	Sage.profile.rangeCheck = enable or false
	self:UpdateRangeCheck()
end

function SageParty:CheckingRange()
	return Sage.profile.rangeCheck
end

function SageParty:SetRangeSpell(spell)
	Sage.profile.rangeSpell = spell
	self:UpdateRangeCheck()
end

function SageParty:GetRangeSpell()
	return Sage.profile.rangeSpell
end

function SageParty:GetRangeSpellIcon()
	local unknown = "Interface\\Icons\\INV_Misc_QuestionMark"
	local spell = self:GetRangeSpell()
	if(spell and spell ~= "") then
		local id = 1
	
		local spellName = GetSpellName(id, BOOKTYPE_SPELL)
		while(spellName) do
			if(spellName == spell) then
				return GetSpellTexture(id, BOOKTYPE_SPELL)
			end
			id = id + 1
			spellName = GetSpellName(id, BOOKTYPE_SPELL)
		end
	end
	return unknown
end

function SageParty:UpdateRangeCheck()
	local spell = self:CheckingRange() and self:GetRangeSpell()
	if(spell) then
		self.motherFrame.spell = spell
		self.motherFrame:SetScript("OnUpdate", RangeCheck_OnUpdate)
	else
		self.motherFrame:SetScript("OnUpdate", nil)
		for i = 1, MAX_PARTY_MEMBERS do
			local frame = SageFrame:Get("party" .. i)
			if(frame) then
				frame:SetAlpha(frame:GetFrameAlpha())
			end
		end
	end
end