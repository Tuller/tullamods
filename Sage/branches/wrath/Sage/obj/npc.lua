--[[
	NPC Info Bar
		Displays target info (class & type)
--]]

local NPCInfoBar = Sage:CreateClass('Frame')
Sage.NPCInfoBar = NPCInfoBar

local L = LibStub('AceLocale-3.0'):GetLocale('Sage')

function NPCInfoBar:New(parent, font)
	local f = self:Bind(CreateFrame('Frame', parent:GetName() .. 'NPCInfo', parent))
	f:SetScript('OnShow', self.OnShow)

	f.class = f:CreateFontString(nil, 'OVERLAY')
	f.class:SetFontObject(font)
	f.class:SetJustifyH('LEFT')
	f.class:SetPoint('TOPLEFT')

	f.type = f:CreateFontString(nil, 'OVERLAY')
	f.type:SetFontObject(font)
	f.type:SetJustifyH('RIGHT')
	f.type:SetPoint('TOPRIGHT')

	f:UpdateUnit()

	return f
end

function NPCInfoBar:OnShow()
	self:Update()
end

function NPCInfoBar:UpdateUnit(newUnit)
	local newUnit = newUnit or self:GetParent():GetAttribute('unit')
	if self.unit ~= newUnit then
		self.unit = newUnit

		if self:IsVisible() then
			self:Update()
		end
	end
end

function NPCInfoBar:Update()
	self.class:SetText(self:GetClass())
	self.type:SetText(self:GetClassification())
end

--If not an NPC, this returns the unit's class.  Else, it returns the given unit's creature type
function NPCInfoBar:GetClass()
	local unit = self.unit

	if UnitRace(unit) then
		return UnitClass(unit)
	else
		local type = UnitCreatureFamily(unit) or UnitCreatureType(unit)
		return (type == 'Unknown Creature' and '') or type
	end
end

--Returns a string with the given's classification if the target special
function NPCInfoBar:GetClassification()
	local unit = self.unit
	local class = UnitClassification(unit)

	if class == 'worldboss' then
		return 'Boss'
	elseif class == 'rareelite' then
		return 'Rare Elite'
	elseif class == 'elite' then
		return 'Elite'
	elseif class == 'rare' then
		return 'Rare'
	end
end