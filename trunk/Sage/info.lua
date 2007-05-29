--[[
	The Infobar component of Sage
		Infobars display the unit's level, name, health percentage, pvp status, targeting icon
		Infobars can also includ master looter and party leadership status

		Additionally, this frame actually controls how wide its parent unitframe is, due to it being related to name width

		<frame>.extraWidth - an optional static amount to add to the width of a frame.
		The max height of an infobar with party information should be 20, and 16 without
--]]

SageInfo = CreateFrame('Frame')
local Frame_mt = {__index = SageInfo}

local frames = {}

local function OnShow()
	this:UpdateAll()
end

local function CreateSmallString(frame)
	local str = frame:CreateFontString(nil, "OVERLAY")
	str:SetFontObject(SageFontSmall)
	
	return str
end

local function CreateStrings(frame)
	frame.level = CreateSmallString(frame)
	frame.level:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 2, 0)
	frame.level:SetJustifyH("LEFT")

	frame.percent = CreateSmallString(frame)
	frame.percent:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 0)
	frame.percent:SetJustifyH("RIGHT")
	if not Sage.ShowingPercents() then
		frame.percent:Hide()
	end

	frame.name = frame:CreateFontString(nil, "OVERLAY")
	frame.name:SetFontObject(SageFont)
	frame.name:SetJustifyH("LEFT")
	frame.name:SetPoint("BOTTOMLEFT", frame.level, "BOTTOMRIGHT")
	frame.name:SetPoint("BOTTOMRIGHT", frame.percent, "BOTTOMLEFT")
end

local function CreateIcons(frame, hasPartyInfo)
	frame.pvp = frame:CreateTexture(nil, "OVERLAY")
	frame.pvp:SetWidth(48)
	frame.pvp:SetHeight(48)
	frame.pvp:SetPoint("CENTER", frame.level, "CENTER", 7, -10)
	frame.pvp:Hide()

	frame.target = frame:CreateTexture(nil, "OVERLAY")
	frame.target:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
	frame.target:SetWidth(25)
	frame.target:SetHeight(26)
	frame.target:SetPoint("CENTER", frame.level, "CENTER", -1, 0)
	frame.target:Hide()

	if hasPartyInfo then
		frame.leader = frame:CreateTexture(nil, "OVERLAY")
		frame.leader:SetWidth(20)
		frame.leader:SetHeight(18)
		frame.leader:SetPoint("BOTTOM", frame.level, "TOP", -0.5, -4)
		frame.leader:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
		frame.leader:Hide()

		frame.masterLoot = frame:CreateTexture(nil, "OVERLAY")
		frame.masterLoot:SetWidth(16)
		frame.masterLoot:SetHeight(16)
		frame.masterLoot:SetPoint("TOP", frame.level, "BOTTOMLEFT", 0, 0)
		frame.masterLoot:SetTexture("Interface\\GroupFrame\\UI-Group-MasterLooter")
		frame.masterLoot:Hide()
	end
end


--[[ Usable Functions ]]--

function SageInfo.Create(parent, hasPartyInfo)
	assert(parent, "No parent given")

	local frame = CreateFrame("Frame", nil, parent)
	frame:SetAlpha(parent:GetAlpha())
	setmetatable(frame, Frame_mt)

	frame.id = parent.id

	CreateStrings(frame)
	CreateIcons(frame, hasPartyInfo)

	frames[frame.id] = frame
	frame:UpdateAll()
	
	frame:SetScript("OnShow", OnShow)

	return frame
end


--[[ Update Functions ]]--

function SageInfo:UpdateAll()
	self:UpdateLevel()
	self:UpdateUnitIcon()
	self:UpdateName()

	if Sage.ShowingPercents() then
		self:UpdateHealthPercent()
	end
end

--Updates the name of the player and resizes the unitframe, if needed.
function SageInfo:UpdateName()
	self.name:SetText(UnitName(self.id))
end

--Colors the name of the unit based on a bunch of different criteria
function SageInfo:UpdateNameColor()
	local unit = self.id
	local r, g, b

	-- player controlled units
	if UnitPlayerControlled(unit) then
		if UnitCanAttack(unit, 'player') then
			--hostile units
			r = UnitReactionColor[2].r
			g = UnitReactionColor[2].g + 0.3
			b = UnitReactionColor[2].b + 0.3
		elseif UnitCanAttack('player', unit) then
			--pvp flagged players, when we're not in pvp
			r = UnitReactionColor[4].r
			g = UnitReactionColor[4].g
			b = UnitReactionColor[4].b
		elseif UnitIsPVP(unit) then
			--friendly flagged players
			r = UnitReactionColor[6].r
			g = UnitReactionColor[6].g
			b = UnitReactionColor[6].b
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
	local targetIcon = self.target
	local pvpIcon = self.pvp
	local unit = self.id

	if not targetIcon:IsShown() then
		local levelText = self.level
		local factionGroup = UnitFactionGroup(unit)

		if UnitIsPVPFreeForAll(unit) then
			levelText:SetFontObject(SageFontSmallOutline)
			pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
			pvpIcon:Show()
		elseif factionGroup and UnitIsPVP(unit) then
			levelText:SetFontObject(SageFontSmallOutline)
			pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-" .. factionGroup)
			pvpIcon:Show()
		else
			levelText:SetFontObject(SageFontSmall)
			pvpIcon:Hide()
		end
	else
		pvpIcon:Hide()
	end
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
		levelText:SetText("??")
		levelText:SetVertexColor(1, 1, 1)
	end
end

--updates the raid target icon, hides the pvp icon if necessary
function SageInfo:UpdateUnitIcon()
	local targetIcon = self.target
	local index = GetRaidTargetIndex(self.id)

	if index and index > 1 then
		SetRaidTargetIconTexture(targetIcon, index)
		targetIcon:Show()

		self.level:SetFontObject(SageFontSmallOutline)
	else
		targetIcon:Hide()
	end
	self:UpdatePvP()
end

function SageInfo:UpdateHealthPercent()
	local unit = self.id
	self.percent:SetText(floor(UnitHealth(unit) / UnitHealthMax(unit) * 100 + 0.5) .. "%")
end

function SageInfo:ShowPercent(enable)
	if enable then
		self.percent:Show()
		self:UpdateHealthPercent()
	else
		self.percent:SetText('')
		self.percent:Hide()
	end
	self:UpdateWidth()
end

function SageInfo:UpdateWidth()
	if InCombatLockdown() then SeeQ:Do(function() self:UpdateWidth() end) return end
	
	local parent = self:GetParent()
	local width = (parent.sets.minWidth or 0) + (parent.extraWidth or 0)

	self.name:SetWidth(parent.minWidth or 0)	
	self.level:SetText('00')

	width = width + self.level:GetStringWidth()

	if Sage.ShowingPercents() then
		self.percent:SetText('100%')
		width = width + self.percent:GetStringWidth()
	end

	self:UpdateAll()
	parent:SetWidth(width)
end


--[[ Access Functions ]]--

--If not an NPC, this returns the unit's class.  Else, it returns the given unit's creature type

function SageInfo.GetClass(unit)
	if UnitIsPlayer(unit) then 
		return UnitClass(unit) 
	end

	local cType = UnitCreatureType(unit)
	if cType == SAGE_UNKNOWN_CREATURE_TYPE then
		return ''
	end
	return cType
end

--Returns a string with the given's classification if the target special
function SageInfo.GetClassification(unit)
	local classification = UnitClassification(unit)
	if classification == "worldboss" then
		return SAGE_BOSS
	elseif classification == "rareelite" then
		return SAGE_RARE_ELITE
	elseif classification == "elite" then
		return SAGE_ELITE
	elseif classification == "rare" then
		return SAGE_RARE
	end
end


--[[ Utility Functions ]]--

function SageInfo.ForAll(action, ...)
	for _,frame in pairs(frames) do
		action(frame, ...)
	end
end

function SageInfo.Get(unit) 
	return frames[unit] 
end


--[[ Events ]]--

local function IfShown(action)
	return function(_, _, unit)
		local frame = SageInfo.Get(unit)
		if frame and frame:IsVisible() then
			action(frame)
		end
	end
end
BVent:AddAction('UNIT_FACTION', IfShown(SageInfo.UpdatePvP))
BVent:AddAction('UNIT_NAME_UPDATE', IfShown(SageInfo.UpdateName))
BVent:AddAction('UNIT_LEVEL', IfShown(SageInfo.UpdateLevel))
BVent:AddAction('RAID_TARGET_UPDATE',function() SageInfo.ForAll(SageInfo.UpdateUnitIcon) end)


local function OnHealthEvent(_, _, unit)
	if Sage.ShowingPercents() then
		local frame = SageInfo.Get(unit)
		if frame and frame:IsVisible() then
			frame:UpdateHealthPercent()
		end
	end
end
BVent:AddAction("UNIT_HEALTH", OnHealthEvent)
BVent:AddAction("UNIT_MAXHEALTH", OnHealthEvent)