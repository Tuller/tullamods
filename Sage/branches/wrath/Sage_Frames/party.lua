--[[
	player.lua
		A sage player frame
--]]

local PartyFrame = Sage:CreateClass('Frame', Sage.Frame)

--constants!
local BORDER_SIZE = 2
local HEALTH_HEIGHT = 20
local POWER_HEIGHT = 12
local INFO_HEIGHT = 14
local BUFF_SIZE = 17 + 2
local PARTY_PET_SIZE = 12

--[[ Party Pet Frame ]]--

local function PartyPet_UpdateUnit(self, unit)
	self:SetAttribute('unit', 'partypet' .. self:GetParent():GetAttribute('unit'):match('%d'))
end

function PartyFrame:NewPartyPet()
	local unit = 'partypet' .. self:GetAttribute('unit'):match('%d')

	local f = Sage.Frame:Bind(CreateFrame('Frame', format('Sage%sFrame', unit), self, 'SecureHandlerStateTemplate'))
	f.sets = setmetatable({}, {__index = self.sets})
	f:LoadUnitController()
	f:LoadVisibilityController()
	f:SetUnit(unit)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnHide', f.OnHide)
	f.id = unit

	local health = Sage.HealthBar:New(f, 'GameFontHighlightSmall')
	health:SetAllPoints(f)
	f.health = health
	
	--set clickable reigon to the portion containing health & power
	local click = Sage.ClickFrame:New(f)
	click:SetAllPoints(f)
	f.click = click
	
	f.UpdateUnit = PartyPet_UpdateUnit
	
	return f
end

function PartyFrame:OnCreate()
	self:SetID(self:GetAttribute('unit'):match('%d'))

	local info = Sage.InfoBar:NewParty(self, 'GameFontHighlight')
	info:SetPoint('TOPLEFT', BORDER_SIZE, 0)
	info:SetPoint('TOPRIGHT', -(BORDER_SIZE + BUFF_SIZE*4 + 1), 0)
	info:SetHeight(INFO_HEIGHT)
	self.info = info

	local health = Sage.HealthBar:New(self, 'GameFontHighlightLarge')
	health:SetPoint('TOPLEFT', info, 'BOTTOMLEFT', 0, -BORDER_SIZE)
	health:SetPoint('TOPRIGHT', info, 'BOTTOMRIGHT', 0, -BORDER_SIZE)
	health:SetHeight(HEALTH_HEIGHT)
	self.health = health

	local power = Sage.PowerBar:New(self, 'GameFontHighlightSmall')
	power:SetPoint('TOPLEFT', health, 'BOTTOMLEFT', 0, -BORDER_SIZE)
	power:SetPoint('TOPRIGHT', health, 'BOTTOMRIGHT', 0, -BORDER_SIZE)
	power:SetHeight(POWER_HEIGHT)
	self.power = power

	local threat = Sage.ThreatDisplay:New(self)
	threat:SetPoint('TOPLEFT', health, -BORDER_SIZE, BORDER_SIZE)
	threat:SetPoint('BOTTOMRIGHT', power, BORDER_SIZE, -BORDER_SIZE)
	self.threat = threat

	--set clickable reigon to the portion containing health & power
	local click = Sage.ClickFrame:New(self)
	click:SetPoint('TOPLEFT', health)
	click:SetPoint('BOTTOMRIGHT', power)
	self.click = click
	
	local buff = Sage.AuraContainer:New('Buffs', self, 'HELPFUL')
	buff:SetPoint('TOPLEFT', power, 'BOTTOMLEFT', 0, -BORDER_SIZE)
	buff:SetPoint('TOPRIGHT', power, 'BOTTOMRIGHT', 0, -BORDER_SIZE)
	buff:SetHeight(BUFF_SIZE)
	self.buff = buff

	local debuff = Sage.AuraContainer:New('Debuffs', self, 'HARMFUL')
	debuff:SetPoint('TOPLEFT', health, 'TOPRIGHT', 1, 0)
	debuff:SetPoint('BOTTOMLEFT', power, 'BOTTOMRIGHT', 1, 0)
	debuff:SetWidth(BUFF_SIZE * 4)
	self.debuff = debuff
	
	local cast = Sage.SpellBar:New(self)
	cast:SetAllPoints(health)
	self.cast = cast

	local partyPet = self:NewPartyPet()
	partyPet:SetPoint('TOPLEFT', power, 'BOTTOMLEFT', 0, -BORDER_SIZE)
	partyPet:SetPoint('TOPRIGHT', power, 'BOTTOMRIGHT', 0, -BORDER_SIZE)
	partyPet:SetHeight(POWER_HEIGHT)
	self.pet = partyPet
	
	partyPet:HookScript('OnShow', function()
		buff:SetPoint('TOPLEFT', partyPet, 'BOTTOMLEFT', 0, -BORDER_SIZE)
		buff:SetPoint('TOPRIGHT', partyPet, 'BOTTOMRIGHT', 0, -BORDER_SIZE)
	end)
	
	partyPet:HookScript('OnHide', function()
		buff:SetPoint('TOPLEFT', power, 'BOTTOMLEFT', 0, -BORDER_SIZE)
		buff:SetPoint('TOPRIGHT', power, 'BOTTOMRIGHT', 0, -BORDER_SIZE)
	end)
	
	--add a drag frame
	self.drag = Sage.DragFrame:New(self)
end

function PartyFrame:GetDefaults()
	return {
		point = 'TOPLEFT',
		x = 20,
		y = -40 - 100 * tonumber(self:GetAttribute('unit'):match('%d')),
		width = 120 + 16 + BUFF_SIZE*4 + 1,
		oorAlpha = 0.6,
		height = (BORDER_SIZE*2) + INFO_HEIGHT + HEALTH_HEIGHT + POWER_HEIGHT + BUFF_SIZE*2 + POWER_HEIGHT,
		visibilityStates = format('[target=%s,raid]hide', self:GetAttribute('unit'))
	}
end


--[[ Module Code ]]--

local module = Sage:NewModule('PartyFrame', 'AceEvent-3.0')

function module:OnLoad()
	for i = 1, 4 do
		PartyFrame:New('party' .. i)
	end

	module:RegisterEvent('PARTY_MEMBERS_CHANGED')
	module:RegisterEvent('UNIT_PET')
end

function module:OnUnload()
	for i = 1, 4 do
		Sage.Frame:Get('party' .. i):Free()
	end

	module:UnregisterEvent('PARTY_MEMBERS_CHANGED')
	module:UnregisterEvent('UNIT_PET')
end

function module:LoadOptions()
	--create options panel code here
end

function module:PARTY_MEMBERS_CHANGED()
	for i = 1, GetNumPartyMembers() do
		Sage.Frame:Get('party' .. i):ForChildren('OnShow')
	end
end

function module:UNIT_PET(msg, unit)
	if unit:match('party%d') then
		Sage.Frame:Get(unit).pet:ForChildren('OnShow')
	end
end