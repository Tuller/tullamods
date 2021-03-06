--[[
	The Infobar component of Sage
		Infobars display the unit's level, name, health percentage, pvp status, targeting icon
		Infobars can also includ master looter and party leadership status

		Additionally, this frame actually controls how wide its parent unitframe is, due to it being related to name width

		<frame>.extraWidth - an optional static amount to add to the width of a frame.
		The max height of an infobar with party information should be 20, and 16 without
--]]

SageInfo = CreateFrame('Frame')
local Frame_MT = {__index = SageInfo}
local L = SAGE_LOCALS

local LEVEL_OFFSET = 2
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local UnitReactionColor = UnitReactionColor

--this is an exercise in
local function IndexToUnit(index)
	if(index) then
		return ((index == 0) and 'player') or 'party' .. index
	end
end

local function GetLeaderIndex()
	local leader = GetPartyLeaderIndex()
	if(leader == 0) then
		leader = IsPartyLeader() and 0
	end
	return IndexToUnit(leader)
end

local function Bar_CreateStrings(self)
	local level = self:CreateFontString(nil, 'OVERLAY')
	level:SetFontObject(SageFont:GetLevelFont())
	level:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', LEVEL_OFFSET, 0)
	level:SetHeight(12)
	level:SetJustifyH('LEFT'); level:SetJustifyV('BOTTOM')
	self.level = level

	local percent = self:CreateFontString(nil, 'OVERLAY')
	percent:SetFontObject(SageFont:GetSmallOutsideFont())
	percent:SetPoint('BOTTOMRIGHT', self)
	percent:SetHeight(12)
	percent:SetJustifyH('RIGHT'); percent:SetJustifyV('BOTTOM')
	if not Sage:ShowingPercents() then percent:Hide() end
	self.percent = percent

	local name = self:CreateFontString(nil, 'OVERLAY')
	name:SetFontObject(SageFont:GetOutsideFont())
	name:SetHeight(12)
	name:SetJustifyH('LEFT'); name:SetJustifyV('BOTTOM')
	name:SetPoint('BOTTOMLEFT', level, 'BOTTOMRIGHT')
	name:SetPoint('BOTTOMRIGHT', percent, 'BOTTOMLEFT')
	self.name = name
end

local function Bar_CreateIcons(self, hasPartyInfo)
	local pvp = self:CreateTexture(nil, 'OVERLAY')
	pvp:SetWidth(48); pvp:SetHeight(48)
	pvp:SetPoint('CENTER', self.level, 'CENTER', 7, -10)
	pvp:Hide()
	self.pvp = pvp

	local target = self:CreateTexture(nil, 'OVERLAY')
	target:SetTexture('Interface\\TargetingFrame\\UI-RaidTargetingIcons')
	target:SetWidth(25); target:SetHeight(26)
	target:SetPoint('CENTER', self.level, 'CENTER', -1, 0)
	target:Hide()
	self.target = target

	if hasPartyInfo then
		local leader = self:CreateTexture(nil, 'OVERLAY')
		leader:SetWidth(20); leader:SetHeight(18)
		leader:SetPoint('BOTTOM', self.level, 'TOP', -0.5, -4)
		leader:SetTexture('Interface\\GroupFrame\\UI-Group-LeaderIcon')
		leader:Hide()
		self.leader = leader

		local masterLoot = self:CreateTexture(nil, 'OVERLAY')
		masterLoot:SetWidth(16); masterLoot:SetHeight(16)
		masterLoot:SetPoint('TOP', self.level, 'BOTTOMLEFT', 0, 0)
		masterLoot:SetTexture('Interface\\GroupFrame\\UI-Group-MasterLooter')
		masterLoot:Hide()
		self.masterLoot = masterLoot
	end
end

local function Bar_OnShow(self)
	self:UpdateAll()
end


--[[ Usable Functions ]]--

function SageInfo:Create(parent, id, hasPartyInfo)
	local bar = setmetatable(CreateFrame('Frame', nil, parent), Frame_MT)
	bar.id = id or parent.id
	bar:SetScript('OnShow', Bar_OnShow)

	Bar_CreateStrings(bar)
	Bar_CreateIcons(bar, hasPartyInfo)

	bar:UpdateAll()

	if(not self.bars) then self.bars = {} end
	self.bars[bar.id] = bar

	return bar
end


--[[ Update Functions ]]--

function SageInfo:UpdateAll()
	self:UpdateLevel()
	self:UpdateUnitIcon()
	self:UpdateName()
	self:UpdatePartyLeader(GetLeaderIndex())
	self:UpdateMasterLooter(IndexToUnit(select(2, GetLootMethod())))

	if Sage:ShowingPercents() then
		self:UpdateHealthPercent()
	end
end

--Updates the name of the player and resizes the unitframe, if needed.
function SageInfo:UpdateName()
	self.name:SetText(UnitName(self.id))
	self:UpdateNameColor()
end

--Colors the name of the unit based on a bunch of different criteria
function SageInfo:UpdateNameColor()
	local unit = self.id
	local r, g, b

	-- player controlled units (party units are checked because they're not considered player controlled if far away for some reason)
	if UnitPlayerControlled(unit) or UnitInParty(unit) then
		if self.isResting then
			r = 0.6; g = 0.6; b = 1;
		elseif self.inCombat then
			r = 1; g = 0.4; b = 0.4;
		elseif UnitCanAttack(unit, 'player') then
			--hostile units
			r = UnitReactionColor[2].r
			g = UnitReactionColor[2].g + 0.3
			b = UnitReactionColor[2].b + 0.3
		elseif UnitCanAttack('player', unit) then
			--pvp flagged players, when we're not in pvp
			r = UnitReactionColor[4].r
			g = UnitReactionColor[4].g
			b = UnitReactionColor[4].b
		-- elseif UnitIsPVP(unit) then
			--friendly flagged players
			-- r = UnitReactionColor[6].r
			-- g = UnitReactionColor[6].g
			-- b = UnitReactionColor[6].b
		else
			--update the player's name color based on their class
			local class = select(2, UnitClass(unit))
			if class then
				r = RAID_CLASS_COLORS[class].r
				g = RAID_CLASS_COLORS[class].g
				b = RAID_CLASS_COLORS[class].b
			else
				r = 0.6; g = 0.6; b = 1
			end
		end
	--tapped NPCs
	elseif UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
		r = 0.6; g = 0.6; b = 0.6
	--all other NPCs
	else
		local reaction = UnitReaction(unit, 'player')
		if reaction then
			r = UnitReactionColor[reaction].r + 0.3
			g = UnitReactionColor[reaction].g + 0.3
			b = UnitReactionColor[reaction].b + 0.3
		else
			r = 0.6; g = 0.6; b = 1
		end
	end
	self.name:SetVertexColor(r, g, b)
end

--adds/hides a flag if the unit is flagged for pvp
function SageInfo:UpdatePvP()
	if Sage:ShowingPvP() then
		if(self.target:IsShown()) then
			self.pvp:Hide()
		else
			local unit = self.id
			local pvpIcon = self.pvp
			local factionGroup = UnitFactionGroup(unit)

			if UnitIsPVPFreeForAll(unit) then
				self.level:SetFontObject(SageFont:GetLevelFont())
				pvpIcon:SetTexture('Interface\\TargetingFrame\\UI-PVP-FFA')
				pvpIcon:Show()
			elseif factionGroup and UnitIsPVP(unit) then
				self.level:SetFontObject(SageFont:GetLevelFont())
				pvpIcon:SetTexture('Interface\\TargetingFrame\\UI-PVP-' .. factionGroup)
				pvpIcon:Show()
			else
				self.level:SetFontObject(SageFont:GetSmallOutsideFont())
				pvpIcon:Hide()
			end
		end
	elseif self.pvp:IsShown() then
		self.pvp:Hide()
		self.level:SetFontObject(SageFont:GetSmallOutsideFont())
	end
	self:UpdateNameColor()
end

--updates the level display for the unit, colors depending on relative level to the player
function SageInfo:UpdateLevel()
	local levelText = self.level
	local level = UnitLevel(self.id)

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
function SageInfo:UpdateUnitIcon()
	local index = GetRaidTargetIndex(self.id)
	if index then
		SetRaidTargetIconTexture(self.target, index)
		self.target:Show()
		self.level:SetFontObject(SageFont:GetLevelFont())
	else
		self.target:Hide()
	end
	self:UpdatePvP()
end

function SageInfo:UpdateHealthPercent()
	local unit = self.id
	self.percent:SetText(floor(UnitHealth(unit) / UnitHealthMax(unit) * 100 + 0.5) .. '%')
end

function SageInfo:UpdatePercents()
	if Sage:ShowingPercents() then
		self.percent:Show()
		self:UpdateHealthPercent()
	else
		self.percent:SetText('')
		self.percent:Hide()
	end
	self:UpdateWidth()
end

function SageInfo:UpdateWidth()
	local parent = self:GetParent()
	local width = parent:GetFrameWidth()

	self.level:SetText('00')
	--the +2 here is from the offset of level text
	local textWidth = self.level:GetStringWidth() + LEVEL_OFFSET

	if Sage:ShowingPercents() then
		self.percent:SetText('100%')
		textWidth = textWidth + self.percent:GetStringWidth()
	end
	self.name:SetWidth(max(width-textWidth, 0))

	self:UpdateAll()
	parent:SetWidth(max(width, textWidth) + (parent.extraWidth or 0))
end

function SageInfo:UpdatePartyLeader(leader)
	local leaderIcon = self.leader
	if(leaderIcon) then
		if(leader and UnitIsUnit(self.id, leader)) then
			leaderIcon:Show()
		else
			leaderIcon:Hide()
		end
	end
end

function SageInfo:UpdateMasterLooter(looter)
	local lootIcon = self.masterLoot
	if(lootIcon) then
		if(looter and UnitIsUnit(self.id, looter)) then
			lootIcon:Show()
		else
			lootIcon:Hide()
		end
	end
end


--[[ Events ]]--

function SageInfo:OnHealthEvent(unit)
	local frame = self:Get(unit)
	if frame and frame:IsVisible() then
		frame:UpdateHealthPercent()
	end
end

function SageInfo:UNIT_FACTION(unit)
	self:ForUnit(unit, 'UpdatePvP')
end

function SageInfo:UNIT_NAME_UPDATE(unit)
	self:ForUnit(unit, 'UpdateName')
	self:ForUnit(unit, 'UpdateNameColor')
end

function SageInfo:UNIT_CLASSIFICATION_CHANGED(unit)
	self:ForUnit(unit, 'UpdateNameColor')
end

function SageInfo:UNIT_LEVEL(unit)
	self:ForUnit(unit, 'UpdateLevel')
end

function SageInfo:RAID_TARGET_UPDATE()
	self:ForAll('UpdateUnitIcon')
end

function SageInfo:PARTY_LEADER_CHANGED()
	self:ForAll('UpdatePartyLeader', GetLeaderIndex())
end

function SageInfo:PARTY_MEMBERS_CHANGED()
	if(GetNumPartyMembers() == 0) then
		self:ForAll('UpdatePartyLeader', nil)
	end
end

function SageInfo:PARTY_LOOT_METHOD_CHANGED()
	self:ForAll('UpdateMasterLooter', IndexToUnit(select(2, GetLootMethod())))
end


--[[ Utility Functions ]]--

function SageInfo:ForAll(method, ...)
	local bars = self.bars
	if(bars) then
		for _,bar in pairs(bars) do
			bar[method](bar, ...)
		end
	end
end

function SageInfo:ForUnit(unit, method, ...)
	local bar = self:Get(unit)
	if(bar and bar:IsVisible()) then
		bar[method](bar, ...)
	end
end

function SageInfo:Get(id)
	return self.bars and self.bars[id]
end