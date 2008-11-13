--[[
	InfoBar
		Displays level, name, and status icons (pvp, master loot, party leader, raid icon, ...)
			Colors level by difficulty
			Colors name by a lot of things (reaction, threat, etc)
--]]

local InfoBar = Sage:CreateClass('Frame')
Sage.InfoBar = InfoBar

local LEVEL_OFFSET = 2
local frames = {}

local function IndexToUnit(index)
	if index then
		return ((index == 0) and 'player') or 'party' .. index
	end
end

local function GetLeaderIndex()
	local leader = GetPartyLeaderIndex()
	if leader == 0 then
		leader = IsPartyLeader() and 0
	end
	return IndexToUnit(leader)
end

local function GetMasterLooter()
	local _,looter = GetLootMethod()
	return IndexToUnit(looter)
end


--[[ Usable Functions ]]--

function InfoBar:New(parent, font, levelFont, hasPartyInfo)
	local f = self:Bind(CreateFrame('Frame', parent:GetName() .. 'Info', parent))
	f.hasPartyInfo = hasPartyInfo

	f:SetScript('OnShow', self.OnShow)
	f:AddStrings(font, levelFont)
	f:AddIcons(hasPartyInfo)
	f:UpdateUnit()

	table.insert(frames, f)
	return f
end

function InfoBar:NewParty(parent, font, levelFont)
	return self:New(parent, font, levelFont, true)
end

function InfoBar:AddStrings(font, levelFont)
	local level = self:CreateFontString(nil, 'OVERLAY')
	level:SetFontObject(levelFont or font)
	level:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', LEVEL_OFFSET, 0)
	level:SetHeight(12)
	level:SetJustifyH('LEFT')
	level:SetJustifyV('BOTTOM')
	self.level = level

	local name = self:CreateFontString(nil, 'OVERLAY')
	name:SetFontObject(font)
	name:SetHeight(12)
	name:SetJustifyH('LEFT')
	name:SetJustifyV('BOTTOM')
	name:SetPoint('BOTTOMLEFT', level, 'BOTTOMRIGHT', LEVEL_OFFSET, 0)
	name:SetPoint('BOTTOMRIGHT')
	self.name = name
end

function InfoBar:AddIcons(hasPartyInfo)
	local pvp = self:CreateTexture(nil, 'OVERLAY')
	pvp:SetWidth(32)
	pvp:SetHeight(32)
	pvp:SetPoint('RIGHT', 10, -10)
	pvp:Hide()
	self.pvp = pvp

	local target = self:CreateTexture(nil, 'OVERLAY')
	target:SetTexture('Interface\\TargetingFrame\\UI-RaidTargetingIcons')
	target:SetWidth(18)
	target:SetHeight(18)
	target:SetPoint('RIGHT', -2, -6)
	target:Hide()
	self.target = target

	if hasPartyInfo then
		local leader = self:CreateTexture(nil, 'OVERLAY')
		leader:SetWidth(20)
		leader:SetHeight(18)
		leader:SetPoint('BOTTOM', self.level, 'TOP', -0.5, -4)
		leader:SetTexture('Interface\\GroupFrame\\UI-Group-LeaderIcon')
		leader:Hide()
		self.leader = leader

		local masterLoot = self:CreateTexture(nil, 'OVERLAY')
		masterLoot:SetWidth(16)
		masterLoot:SetHeight(16)
		masterLoot:SetPoint('TOP', self.level, 'BOTTOMLEFT', 0, 0)
		masterLoot:SetTexture('Interface\\GroupFrame\\UI-Group-MasterLooter')
		masterLoot:Hide()
		self.masterLoot = masterLoot
	end
end


--[[
	Events
--]]

function InfoBar:OnShow()
	self:UpdateAll()
end

function InfoBar:UNIT_FACTION(unit)
	if self.unit == unit then
		self:UpdatePvP()
	end
end

function InfoBar:UNIT_NAME_UPDATE(unit)
	if self.unit == unit then
		self:UpdateName()
	end
end

function InfoBar:UNIT_CLASSIFICATION_CHANGED(unit)
	if self.unit == unit then
		self:UpdateNameColor()
	end
end

function InfoBar:UNIT_LEVEL(unit)
	if self.unit == unit then
		self:UpdateLevel()
	end
end

function InfoBar:RAID_TARGET_UPDATE()
	self:UpdateUnitIcon()
end

function InfoBar:PARTY_LEADER_CHANGED()
	if self.hasPartyInfo then
		self:UpdatePartyLeader()
	end
end

function InfoBar:PARTY_MEMBERS_CHANGED()
	if self.hasPartyInfo then
		self:UpdatePartyLeader()
	end
end

function InfoBar:PARTY_LOOT_METHOD_CHANGED()
	if self.hasPartyInfo then
		self:UpdateMasterLooter()
	end
end

function InfoBar:UNIT_THREAT_SITUATION_UPDATE(unit)
	if unit == self.unit or unit == 'player' then
		self:UpdateNameColor()
	end
end


--[[
	Update Methods
--]]

function InfoBar:UpdateUnit(newUnit)
	local newUnit = newUnit or self:GetParent():GetAttribute('unit')
	if self.unit ~= newUnit then
		self.unit = newUnit

		if self:IsVisible() then
			self:UpdateAll()
		end
	end
end

function InfoBar:UpdateAll()
	self:UpdateLevel()
	self:UpdateUnitIcon()
	self:UpdateName()

	if self.hasPartyInfo then
		self:UpdatePartyLeader()
		self:UpdateMasterLooter()
	end
end

--Updates the name of the player and resizes the unitframe, if needed.
function InfoBar:UpdateName()
	self.name:SetText(UnitName(self.unit))
	self:UpdateNameColor()
end

function InfoBar:UpdateNameColor()
	self.name:SetVertexColor(self:GetNameStatusColor())
end

--Colors the name of the unit based on a bunch of different criteria
function InfoBar:GetNameStatusColor()
	local unit = self.unit
	local r, g, b

	-- player controlled units (party units are checked because they're not considered player controlled if far away for some reason)
	if UnitPlayerControlled(unit) or UnitInParty(unit) then
		r, g, b = self:GetPCColor(unit)
	else
		r, g, b = self:GetNPCColor(unit)
	end

	return max(r or 0, 0.4), max(g or 0, 0.4), max(b or 1, 0.4)
end

function InfoBar:GetPCColor(unit)
	if UnitIsUnit(unit, 'player') and IsResting() then
		return UnitSelectionColor(unit)
	end

	local threatLevel = UnitThreatSituation(unit)
	if threatLevel > 0 then
		return GetThreatStatusColor(threatLevel)
	end

	if UnitCanAttack(unit, 'player') or UnitCanAttack('player', unit) then
		return UnitSelectionColor(unit)
	end

	--update the player's name color based on their class
	local _, class = UnitClass(unit)
	if class then
		local color = _G['RAID_CLASS_COLORS'][class]
		return color.r, color.g, color.b
	end

	return UnitSelectionColor(unit)
end

function InfoBar:GetNPCColor(unit)
	if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
		return 0.7, 0.7, 0.7
	end

	local threatLevel = UnitThreatSituation('player', unit)
	if threatLevel > 0 then
		return GetThreatStatusColor(threatLevel)
	end

	return UnitSelectionColor(unit)
end

--adds/hides a flag if the unit is flagged for pvp
function InfoBar:UpdatePvP()
	if (not Sage:ShowingPVPIcons()) or self.target:IsShown() then
		self.pvp:Hide()
	else
		local unit = self.unit
		local pvpIcon = self.pvp
		local factionGroup = UnitFactionGroup(unit)

		if UnitIsPVPFreeForAll(unit) then
			pvpIcon:SetTexture('Interface\\TargetingFrame\\UI-PVP-FFA')
			pvpIcon:Show()
		elseif factionGroup and UnitIsPVP(unit) then
			pvpIcon:SetTexture('Interface\\TargetingFrame\\UI-PVP-' .. factionGroup)
			pvpIcon:Show()
		else
			pvpIcon:Hide()
		end
	end
	self:UpdateNamePosition()
end

--updates the level display for the unit, colors depending on relative level to the player
function InfoBar:UpdateLevel()
	local levelText = self.level
	local level = UnitLevel(self.unit)

	if level and level > 0 then
		local color = GetDifficultyColor(level)
		levelText:SetVertexColor(color.r, color.g, color.b)
		levelText:SetText(level)
	else
		levelText:SetText('??')
		levelText:SetVertexColor(1, 1, 1)
	end
end

--updates the raid target icon, hides the pvp icon if necessary
function InfoBar:UpdateUnitIcon()
	local index = GetRaidTargetIndex(self.unit)
	if index then
		SetRaidTargetIconTexture(self.target, index)
		self.target:Show()
	else
		self.target:Hide()
	end
	self:UpdatePvP()
end

function InfoBar:UpdateNamePosition()
	if self.target:IsShown() or self.pvp:IsShown() then
		self.name:SetPoint('BOTTOMRIGHT', -20, 0)
	else
		self.name:SetPoint('BOTTOMRIGHT')
	end
end

function InfoBar:UpdatePartyLeader()
	local leader = GetLeaderIndex()
	local leaderIcon = self.leader

	if leader and UnitIsUnit(self.unit, leader) then
		leaderIcon:Show()
	else
		leaderIcon:Hide()
	end
end

function InfoBar:UpdateMasterLooter()
	local looter = GetMasterLooter()
	local lootIcon = self.masterLoot

	if looter and UnitIsUnit(self.unit, looter) then
		lootIcon:Show()
	else
		lootIcon:Hide()
	end
end


--[[ Utility Functions ]]--

function InfoBar:ForAll(method, ...)
	for _,frame in pairs(frames) do
		frame[method](frame, ...)
	end
end

function InfoBar:ForAllVisible(method, ...)
	for _,frame in pairs(frames) do
		if frame:IsVisible() then
			frame[method](frame, ...)
		end
	end
end

function InfoBar:ForVisibleUnit(unit, method, ...)
	for _,frame in pairs(frames) do
		if frame.unit == unit and frame:IsVisible() then
			frame[method](frame, ...)
		end
	end
end


--[[ Events ]]--

do
	local f = CreateFrame('Frame')
	f:SetScript('OnEvent', function(self, event, ...)
		InfoBar:ForAllVisible(event, ...)
	end)

	f:RegisterEvent('UNIT_THREAT_SITUATION_UPDATE')
	f:RegisterEvent('UNIT_FACTION')
	f:RegisterEvent('UNIT_NAME_UPDATE')
	f:RegisterEvent('UNIT_CLASSIFICATION_CHANGED')
	f:RegisterEvent('UNIT_LEVEL')

	--non unit events
	f:RegisterEvent('RAID_TARGET_UPDATE')
	f:RegisterEvent('PARTY_LEADER_CHANGED')
	f:RegisterEvent('PARTY_MEMBERS_CHANGED')
	f:RegisterEvent('PARTY_LOOT_METHOD_CHANGED')
end