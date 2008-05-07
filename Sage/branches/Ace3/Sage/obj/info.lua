--[[
	The Infobar component of Sage
		Infobars display the unit's level, name, health percentage, pvp status, targeting icon
		Infobars can also includ master looter and party leadership status

		Additionally, this frame actually controls how wide its parent unitframe is, due to it being related to name width

		<frame>.extraWidth - an optional static amount to add to the width of a frame.
		The max height of an infobar with party information should be 20, and 16 without
--]]

local InfoBar = Sage:CreateWidgetClass('Frame')
Sage.InfoBar = InfoBar
local Config = Sage.Config

--constants
local FFA_ICON = 'Interface\\TargetingFrame\\UI-PVP-FFA'
local PVP_ICON = 'Interface\\TargetingFrame\\UI-PVP-%s'
local RAID_TARGET_ICON = 'Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d'
local LEADER_ICON = 'Interface\\GroupFrame\\UI-Group-LeaderIcon'
local MASTER_LOOTER_ICON = 'Interface\\GroupFrame\\UI-Group-MasterLooter'
local LEVEL_OFFSET = 2


--[[ Constructor ]]--

function InfoBar:Create(parent, unit, hasPartyInfo)
	local bar = self:New(CreateFrame('Frame', nil, parent))
	bar.unit = unit or parent.unit
	bar:SetScript('OnShow', bar.UpdateAll)

	bar:AddStrings()
	bar:AddIcons(hasPartyInfo)
	bar:UpdateAll()
	
	self:Register(bar)

	return bar
end

function InfoBar:AddStrings()
	local level = self:CreateFontString(nil, 'OVERLAY')
	level:SetPoint('BOTTOMLEFT', LEVEL_OFFSET, 0)
	level:SetHeight(12)
	level:SetJustifyH('LEFT')
	level:SetJustifyV('BOTTOM')
	self.level = level

	local percent = self:CreateFontString(nil, 'OVERLAY')
	percent:SetPoint('BOTTOMRIGHT')
	percent:SetHeight(12)
	percent:SetJustifyH('RIGHT')
	percent:SetJustifyV('BOTTOM')
	if not Config:ShowPercents() then
		percent:Hide()
	end
	self.percent = percent

	local name = self:CreateFontString(nil, 'OVERLAY')
	name:SetHeight(12)
	name:SetJustifyH('LEFT')
	name:SetJustifyV('BOTTOM')
	name:SetPoint('BOTTOMLEFT', level, 'BOTTOMRIGHT')
	name:SetPoint('BOTTOMRIGHT', percent, 'BOTTOMLEFT')
	self.name = name
end

function InfoBar:AddIcons(hasPartyInfo)
	local pvp = self:CreateTexture(nil, 'OVERLAY')
	pvp:SetWidth(48); pvp:SetHeight(48)
	pvp:SetPoint('CENTER', self.level, 'CENTER', 7, -10)
	pvp:Hide()
	self.pvp = pvp

	local target = self:CreateTexture(nil, 'OVERLAY')
	target:SetWidth(25); target:SetHeight(26)
	target:SetPoint('CENTER', self.level, 'CENTER', -1, 0)
	target:Hide()
	self.target = target

	if hasPartyInfo then
		local leader = self:CreateTexture(nil, 'OVERLAY')
		leader:SetWidth(20)
		leader:SetHeight(18)
		leader:SetPoint('BOTTOM', self.level, 'TOP', -0.5, -4)
		leader:SetTexture(LEADER_ICON)
		leader:Hide()
		self.leader = leader

		local masterLoot = self:CreateTexture(nil, 'OVERLAY')
		masterLoot:SetWidth(16)
		masterLoot:SetHeight(16)
		masterLoot:SetPoint('TOP', self.level, 'BOTTOMLEFT', 0, 0)
		masterLoot:SetTexture(MASTER_LOOTER_ICON)
		masterLoot:Hide()
		self.masterLoot = masterLoot
	end
end


--[[ Update Functions ]]--

function InfoBar:UpdateAll()
	self:UpdateLevel()
	self:UpdateUnitIcon()
	self:UpdateName()
	self:UpdatePartyLeader(self:GetPartyLeader())
	self:UpdateMasterLooter(self:GetPartyLooter())

	if Config:ShowPercents() then
		self:UpdateHealthPercent()
	end
end


--[[ Name Display ]]--

--Updates the name of the player and resizes the unitframe, if needed.
function InfoBar:UpdateName()
	self.name:SetText(UnitName(self.id))
	self:UpdateNameColor()
end

function InfoBar:UpdateNameColor()
	self.name:SetVertexColor(self:GetNameColor())
end

--Colors the name of the unit based on a bunch of different criteria
function InfoBar:GetNameColor()
	local unit = self.unit

	-- players
	if UnitPlayerControlled(unit) or UnitInParty(unit) then
		if self.resting then
			return 0.6, 0.6, 1
		elseif self.combat then
			return 1, 0.3, 0.3
		--hostile units
		elseif UnitCanAttack(unit, 'player') then
			return 1, 0.3, 0.3
		--pvp flagged players, when we're not in pvp
		elseif UnitCanAttack('player', unit) then
			local c = UnitReactionColor[4]
			return max(c.r, 0.3), max(c.g, 0.3), max(c.b, 0.3)
		--update the player's name color based on their class
		else
			local class = select(2, UnitClass(unit))
			if class then
				local c = RAID_CLASS_COLORS[class]
				return max(c.r, 0.3), max(c.g, 0.3), max(c.b, 0.3)
			end
		end
	--tapped NPCs (gray)
	elseif UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
		return 0.6, 0.6, 0.6
	--all other NPCs
	else
		local reaction = UnitReaction(unit, 'player')
		if reaction then
			local c = UnitReactionColor[reaction]
			return max(c.r, 0.3), max(c.g, 0.3), max(c.b, 0.3)
		end
	end

	--everybody else
	return 0.6, 0.6, 1
end


--[[ Level Display ]]--

--updates the level display for the unit, colors depending on relative level to the player
function InfoBar:UpdateLevel()
	local levelText = self.level
	local level = UnitLevel(self.unit)

	if level and level > 0 then
		local c = GetDifficultyColor(level)
		levelText:SetVertexColor(max(c.r, 0.3), max(c.g, 0.3), max(c.b, 0.3))
		levelText:SetText(level)
	else
		levelText:SetText('??')
		levelText:SetVertexColor(1, 1, 1)
	end
end

--[[ HP Percentage Display ]]--

function InfoBar:UpdateHealthPercent()
	self.percent:SetFormattedText('%d\%', floor(UnitHealth(self.id) / UnitHealthMax(self.id) * 100 + 0.5))
end

function InfoBar:UpdatePercentDisplay(enable)
	if enable then
		self:UpdateHealthPercent()
		self.percent:Show()
	else
		self.percent:SetText('') --done for some sizing reasons
		self.percent:Hide()
	end
	self:UpdateWidth()
end


--[[ Raid Icon Display ]]--

--updates the raid target icon, hides the pvp icon if necessary
function InfoBar:UpdateUnitIcon()
	local index = GetRaidTargetIndex(self.unit)
	if index then
		self.target:SetTexture(RAID_TARGET_ICON:format(index))
		self.target:Show()
	else
		self.target:Hide()
	end
	self:UpdatePvP()
end


--[[ PvP Icon Display ]]--

--adds/hides a flag if the unit is flagged for pvp
function InfoBar:UpdatePvP()
	local pvpIcon = self.pvp

	if Config:ShowPvPIcons() then
		if self.target:IsShown() then
			pvpIcon:Hide()
		else
			local unit = self.unit
			local faction = UnitFactionGroup(unit)

			if UnitIsPVPFreeForAll(unit) then
				pvpIcon:SetTexture(FFA_ICON)
				pvpIcon:Show()
			elseif faction and UnitIsPVP(unit) then
				pvpIcon:SetTexture(PVP_ICON:format(faction))
				pvpIcon:Show()
			else
				pvpIcon:Hide()
			end
		end
	elseif pvpIcon:IsShown() then
		pvpIcon:Hide()
	end
	self:UpdateNameColor()
end


--[[ Party Icon Display ]]--

function InfoBar:UpdatePartyLeader(leader)
	local leaderIcon = self.leader
	if leaderIcon then
		if leader and UnitIsUnit(self.unit, leader) then
			leaderIcon:Show()
		else
			leaderIcon:Hide()
		end
	end
end

function InfoBar:UpdateMasterLooter(looter)
	local lootIcon = self.masterLoot
	if lootIcon then
		if looter and UnitIsUnit(self.unit, looter) then
			lootIcon:Show()
		else
			lootIcon:Hide()
		end
	end
end

local function GetPartyUnit(index)
	if index then
		return (index == 0 and 'player') or ('party' .. index)
	end
end

function InfoBar:GetPartyLeader()
	local index = GetPartyLeaderIndex()
	if index == 0 then
		index = IsPartyLeader() and 0
	end
	return GetPartyUnit(index)
end

function InfoBar:GetPartyLooter()
	return GetPartyUnit(select(2, GetLootMethod()))
end


--[[ Font Updating ]]--

function InfoBar:SetNameFont(font, size, outline)
	self.sets.nameFont = font
	self.sets.nameSize = size
	self.sets.nameOutline = outline
	self:UpdateNameFont()
end

function InfoBar:UpdateLevelFont()
	self.name:SetFont(self:GetNameFont())
end

function InfoBar:GetNameFont()
	return self.sets.nameFont, self.sets.nameSize, self.sets.nameOutline or (self.sets.forceLevelOutline and 'OUTLINE')
end

function InfoBar:SetNumberFont(font, size, outline)
	self.sets.numberFont = font
	self.sets.numberSize = size
	self.sets.numberOutline = outline
	self:UpdateNumberFont()
end

function InfoBar:SetLevelOutline(enable)
	self.forceLevelOutline = enable
	self:UpdateLevelFont()
end

function InfoBar:UpdateNumberFont()
	self.level:SetFont(self:GetLevelFont())
	self.hp:SetFont(self:GetNumberFont())
end

function InfoBar:GetLevelFont()
	return self.sets.levelFont, self.sets.levelSize, self.sets.levelOutline or (self.sets.forceLevelOutline and 'OUTLINE')
end

--[[ Events ]]--

function InfoBar:OnHealthEvent(unit)
	self:ForUnit(unit, 'UpdateHealthPercent', ...)
end

function InfoBar:UNIT_FACTION(unit)
	self:ForUnit(unit, 'UpdatePvP')
end

function InfoBar:UNIT_NAME_UPDATE(unit)
	self:ForUnit(unit, 'UpdateName')
	self:ForUnit(unit, 'UpdateNameColor')
end

function InfoBar:UNIT_CLASSIFICATION_CHANGED(unit)
	self:ForUnit(unit, 'UpdateNameColor')
end

function InfoBar:UNIT_LEVEL(unit)
	self:ForUnit(unit, 'UpdateLevel')
end

function InfoBar:RAID_TARGET_UPDATE()
	self:ForAll('UpdateUnitIcon')
end

function InfoBar:PARTY_LEADER_CHANGED()
	self:ForAll('UpdatePartyLeader', self:GetPartyLeader())
end

function InfoBar:PARTY_MEMBERS_CHANGED()
	if GetNumPartyMembers() == 0 then
		self:ForAll('UpdatePartyLeader', nil)
	end
end

function InfoBar:PARTY_LOOT_METHOD_CHANGED()
	self:ForAll('UpdateMasterLooter', self:GetPartyLooter())
end


--[[ Utility Functions ]]--

function InfoBar:ForAll(method, ...)
	local bars = self.bars
	if bars then
		for _,bar in pairs(bars) do
			bar[method](bar, ...)
		end
	end
end

function InfoBar:ForUnit(unit, method, ...)
	local bar = self:Get(unit)
	if bar and bar:IsVisible() then
		bar[method](bar, ...)
	end
end

function InfoBar:Register(bar)
	if not self.bars then 
		self.bars = {} 
	end
	self.bars[bar.unit] = bar
end

function InfoBar:Get(unit)
	return self.bars and self.bars[unit]
end