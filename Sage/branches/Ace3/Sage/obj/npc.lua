--[[
	SageNPC
		Displays target info (class & type)
--]]

local NPCInfo = Sage:CreateObjectClass('Frame')
Sage.NPCInfo = NPCInfo

function NPCInfo:Create(parent, id)
	local npc = self:New(CreateFrame('Frame', nil, parent))
	npc.id = id or parent.id

	npc.class = npc:CreateFontString(nil, 'OVERLAY')
	npc.class:SetJustifyH('LEFT')
	npc.class:SetPoint('TOPLEFT')

	npc.type = npc:CreateFontString(nil, 'OVERLAY')
	npc.type:SetJustifyH('RIGHT')
	npc.type:SetPoint('TOPRIGHT')

	return npc
end

function NPCInfo:SetFont(...)
	self.class:SetFont(...)
	self.type:SetFont(...)
end

function NPCInfo:Update()
	self.class:SetText(self:GetClass(self.id))
	self.type:SetText(self:GetClassification(self.id))
end

--If not an NPC, this returns the unit's class.  Else, it returns the given unit's creature type
function NPCInfo:GetClass(unit)
	if UnitRace(unit) then
		return UnitClass(unit)
	end

	local type = UnitCreatureFamily(unit) or UnitCreatureType(unit)
	return (type == L.UnknownCreature and '') or type
end

--Returns a string with the given's classification if the target special
function NPCInfo:GetClassification(unit)
	local class = UnitClassification(unit)
	if class == 'worldboss' then
		return L.Boss
	elseif class == 'rareelite' then
		return L.RareElite
	elseif class == 'elite' then
		return L.Elite
	elseif class == 'rare' then
		return L.Rare
	end
end