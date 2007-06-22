--[[
	Sage_Player
		A Sage style PlayerFrame
--]]

SagePlayer = Sage:NewModule("Sage-Player")
local L = SAGE_LOCALS
L.ShowXP = "Show Experience"


--Unregisters the blizzard provided player frame
local function UnregisterBlizPlayerFrame()
	PlayerFrame:UnregisterAllEvents()
	PlayerFrameHealthBar:UnregisterAllEvents()
	PlayerFrameManaBar:UnregisterAllEvents()
	PlayerFrame:Hide()
end


--[[ Frame Functions ]]--

--changes the player's name's color if in combat/resting/normal state
local function Frame_UpdateCombatStatus(self, inCombat)
	self.info.isResting = IsResting()
	self.info.inCombat = inCombat or InCombatLockdown()
	self.info:UpdateNameColor()
end

--If in a raid, this function changes the player's level to indicate what raid group the player is in
local function Frame_UpdateGroupIndicator(self)
	local numRaidMembers = GetNumRaidMembers()
	if numRaidMembers > 0 then
		for i = 1, MAX_RAID_MEMBERS do
			if i <= numRaidMembers then
				local name, rank, subgroup = GetRaidRosterInfo(i)
				if name == UnitName(self.id) then
					self.info.level:SetText(subgroup)
					self.info.level:SetVertexColor(1, 1, 1)
					return
				end
			else
				break
			end
		end
	else
		self.info:UpdateLevel()
	end
end

--called when the player frame is first created, adds all of its buttons
local function Frame_OnCreate(self)
	UnregisterBlizPlayerFrame()
	self.UpdateMasterLooter = Frame_UpdateMasterLooter
	self.UpdatePartyLeader = Frame_UpdatePartyLeader
	self.UpdateCombatStatus = Frame_UpdateCombatStatus
	self.UpdateGroupIndicator = Frame_UpdateGroupIndicator

	self:SetScript("OnReceiveDrag", PlayerFrame_OnReceiveDrag)
	self:SetHeight(52)

	self.info = SageInfo:Create(self, nil, true)
	self.info:SetPoint("TOPLEFT", self)
	self.info:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, -20)

	self.health = SageHealth:Create(self)
	self.health:SetPoint("TOPLEFT", self.info, "BOTTOMLEFT")
	self.health:SetPoint("BOTTOMRIGHT", self.info, "BOTTOMRIGHT", 0, -20)

	self.mana = SageMana:Create(self)
	self.mana:SetPoint("TOPLEFT", self.health, "BOTTOMLEFT")
	self.mana:SetPoint("BOTTOMRIGHT", self.health, "BOTTOMRIGHT", 0, -12)

	if self.sets.showCombatText then
		SageCombat:Register(self)
	end

	self.click:SetPoint("TOPLEFT", self.info)
	self.click:SetPoint("BOTTOMRIGHT", self.mana)
end


--[[ Events ]]--

function SagePlayer:Load()
	local defaults = {
		x = 10, y = 1098,
		width = 100,
		showXP = true,
		showCombatText = true,
		combatTextSize = 24,
	}

	--Create|Load frame
	local frame = SageFrame:Create("player", Frame_OnCreate, defaults)
	self.frame = frame
	frame.info:UpdateWidth()
	frame:UpdateCombatStatus()

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnCombatEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnCombatEvent")
	self:RegisterEvent("PLAYER_UPDATE_RESTING", "OnCombatEvent")
	self:RegisterEvent("RAID_ROSTER_UPDATE", "OnPartyEvent")
	self:SetShowXP(self:ShowingXP())
end

function SagePlayer:Unload()
	self:UnregisterAllEvents()
	self.frame:Destroy()
end

function SagePlayer:PLAYER_ENTERING_WORLD()
	local frame = self.frame
	frame.health:UpdateAll()
	frame.mana:Update()
	frame:UpdateCombatStatus()
end

function SagePlayer:OnCombatEvent(event)
	self.frame:UpdateCombatStatus(event == "PLAYER_REGEN_DISABLED")
end

function SagePlayer:OnPartyEvent()
	self.frame:UpdateGroupIndicator()
end

function SagePlayer:LoadOptions()
	local panel = SageOptions:AddPanel("Player")
	
	local function ShowXP_OnClick(self)
		SagePlayer:SetShowXP(self:GetChecked())
	end
	local function ShowXP_OnShow(self)
		self:SetChecked(SagePlayer:ShowingXP())
	end
	panel:AddCheckButton(L.ShowXP, ShowXP_OnClick, ShowXP_OnShow)
	panel:AddUnitOptions("player")
end