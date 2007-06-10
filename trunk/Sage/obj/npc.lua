--[[
	SageNPC
		Displays target info (class & type)
--]]

SageNPC = {}
local L = SAGE_LOCALS

function SageNPC:Create(parent, id)
	local npc = CreateFrame("Frame", nil, parent)
	npc.id = id or parent.id

	npc.class = npc:CreateFontString(nil, "OVERLAY")
	npc.class:SetFontObject(SageFont:GetSmallOutsideFont())
	npc.class:SetJustifyH("LEFT")
	npc.class:SetPoint("TOPLEFT", npc)
	
	npc.type = npc:CreateFontString(nil, "OVERLAY")
	npc.type:SetFontObject(SageFont:GetSmallOutsideFont())
	npc.type:SetJustifyH("RIGHT")
	npc.type:SetPoint("TOPRIGHT", npc)

	npc.Update = self.Update

	return npc
end

function SageNPC:Update()
	local unit = self.id
	self.class:SetText(SageNPC:GetClass(unit))
	self.type:SetText(SageNPC:GetClassification(unit))
end

--If not an NPC, this returns the unit"s class.  Else, it returns the given unit"s creature type
function SageNPC:GetClass(unit)
	if UnitIsPlayer(unit) then
		return UnitClass(unit)
	end
	local type = UnitCreatureType(unit)
	return (type == L.UnknownCreature and "") or type
end

--Returns a string with the given"s classification if the target special
function SageNPC:GetClassification(unit)
	local class = UnitClassification(unit)
	if class == "worldboss" then
		return L.Boss
	elseif class == "rareelite" then
		return L.RareElite
	elseif class == "elite" then
		return L.Elite
	elseif class == "rare" then
		return L.Rare
	end
end