--[[
	Sage_Player
		A Sage style PlayerFrame
--]]


--[[ Update Functions ]]--

local function UpdateMasterLooter(self)
	local lootMethod, lootMaster = GetLootMethod()
	if lootMaster == 0 and (GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0) then
		self.info.masterLoot:Show()
	else
		self.info.masterLoot:Hide()
	end
end

local function UpdatePartyLeader(self)
	if IsPartyLeader() then
		self.info.leader:Show()
	else
		self.info.leader:Hide()
	end
	UpdateMasterLooter(self)
end

--changes the player's name's color if in combat/resting/normal state
local function UpdateCombatStatus(self, inCombat)
	if InCombatLockdown() or inCombat then
		self.info.name:SetTextColor(1, 0.4, 0.4)
	elseif IsResting() then
		self.info.name:SetTextColor(0.6, 0.6, 1)
	else
		self.info.name:SetTextColor(1, 1, 1)
	end
end

--If in a raid, this function changes the player's level to indicate what raid group the player is in
local function UpdateGroupIndicator(self)
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


--[[ Events ]]--

--I could replace this using BEvent
local function OnEvent()
	if event == "PLAYER_REGEN_DISABLED" then
		UpdateCombatStatus(this, true)
	elseif event == "PLAYER_REGEN_ENABLED" then
		UpdateCombatStatus(this, false)
	elseif event == "PARTY_MEMBERS_CHANGED" or event == "PARTY_LEADER_CHANGED" or event == "RAID_ROSTER_UPDATE" then
		UpdatePartyLeader(this)
		UpdateGroupIndicator(this)
	elseif event == "PARTY_LOOT_METHOD_CHANGED" then
		UpdateMasterLooter(this)
	elseif event == "PLAYER_UPDATE_RESTING" then
		UpdateCombatStatus(this)
	elseif event == "PLAYER_ENTERING_WORLD" then
		this.health:UpdateAll()
		this.mana:Update()
		UpdateCombatStatus(this)
	end
end


--[[ Startup ]]--

--Unregisters the blizzard provided player frame
local function UnregisterBlizPlayerFrame()
	PlayerFrame:UnregisterAllEvents()
	PlayerFrameHealthBar:UnregisterAllEvents()
	PlayerFrameManaBar:UnregisterAllEvents()
	PlayerFrame:Hide()
end

--called when the player frame is first created, adds all of its buttons
local function OnCreate(self)
	UnregisterBlizPlayerFrame()

	self:SetScript("OnReceiveDrag", PlayerFrame_OnReceiveDrag)
	self:SetHeight(52)

	self.info = SageInfo.Create(self, true)
	self.info:SetPoint("TOPLEFT", self)
	self.info:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, -20)

	self.health = SageHealth.Create(self)
	self.health:SetPoint("TOPLEFT", self.info, "BOTTOMLEFT")
	self.health:SetPoint("BOTTOMRIGHT", self.info, "BOTTOMRIGHT", 0, -20)

	self.mana = SageMana.Create(self)
	self.mana:SetPoint("TOPLEFT", self.health, "BOTTOMLEFT")
	self.mana:SetPoint("BOTTOMRIGHT", self.health, "BOTTOMRIGHT", 0, -12)

	if self.sets.showCombatText then
		SageCombatText.Register(self)
	end

	self.click:SetPoint("TOPLEFT", self.info)
	self.click:SetPoint("BOTTOMRIGHT", self.mana)

--[[
	local class = select(2, UnitClass("player"))
	if class == "DRUID" and IsAddOnLoaded("DruidBar") then
		SDruidBar_Create(frame)
	end
--]]

	SagePlayerXP_Set(self.sets.showXp)
end

Sage.AddStartup(function()
	if not Sage.GetFrameSets('player') then
		Sage.SetFrameSets('player', {
			["y"] = 1097.579710817639,
			["x"] = 10.44926985428825,
			["showXp"] = 1,
			["minWidth"] = 100,
			["combatTextSize"] = 24,
			["showCombatText"] = 1,
		})
	end

	--Create|Load frame
	local frame = SageFrame.Create('player', OnCreate, OnDelete)
	frame.info:UpdateWidth()

	frame:SetScript("OnEvent", OnEvent)
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("PLAYER_REGEN_DISABLED")
	frame:RegisterEvent("PLAYER_REGEN_ENABLED")
	frame:RegisterEvent("PLAYER_UPDATE_RESTING")
	frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
	frame:RegisterEvent("PARTY_LEADER_CHANGED")
	frame:RegisterEvent("RAID_ROSTER_UPDATE")
	frame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")

	--update pvp/name etc
	UpdateCombatStatus(frame)
	UpdatePartyLeader(frame)
end)