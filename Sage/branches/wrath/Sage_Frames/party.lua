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
	f._sets = {}
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
	
	local buff = Sage.AuraContainer:New('Buffs', self, 'HELPFUL|PLAYER')
	buff:SetPoint('TOPLEFT', power, 'BOTTOMLEFT', 0, -BORDER_SIZE)
	buff:SetPoint('TOPRIGHT', power, 'BOTTOMRIGHT', 0, -BORDER_SIZE)
	buff:SetHeight(BUFF_SIZE)
	buff.showOnlyMyBuffs_Change = buff.SetFriendFilter
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
	
	--move buffs below the pet frame when its visible
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

function PartyFrame:showInRaid_Change(enable)
	if enable then
		self.sets.visibilityStates = nil
	else
		self.sets.visibilityStates = '[target=player,raid]hide'
	end
end

function PartyFrame:GetDefaults()
	return {
		point = 'TOPLEFT',
		x = 20,
		y = -40 - 100 * tonumber(self:GetAttribute('unit'):match('%d')),
		width = 120,
		extraWidth = BUFF_SIZE * 4 + 1,
		oorAlpha = 0.6,
		height = (BORDER_SIZE*2) + INFO_HEIGHT + HEALTH_HEIGHT + POWER_HEIGHT + BUFF_SIZE*2 + POWER_HEIGHT,
		showInRaid = false,
		visibilityStates = '[target=player,raid]hide'
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
	local panel = Sage.Options:New('SagePartyOptions', 'Party', 'Configuration settings for the Sage party frames', nil, GetAddOnMetadata('Sage', 'title'))
	local group = 'party'
	
	--buttons
	local showInRaid = panel:NewSettingCheckButton('Display Party Frames When in a Raid', group, 'showInRaid')
	showInRaid:SetPoint('TOPLEFT', 12, -72)
	
	local showOnlyMyBuffs = panel:NewSettingCheckButton("Show Only Buffs I've Cast", group, 'showOnlyMyBuffs', 'HELPFUL|PLAYER', 'HELPFUL')
	showOnlyMyBuffs:SetPoint('TOP', showInRaid, 'BOTTOM', 0, -2)

	--sliders
	local scale = panel:NewScaleSlider(group)
	scale:SetPoint('BOTTOMLEFT', 10, 10)
	scale:SetPoint('BOTTOMRIGHT', -40, 10)
	
	local oorOpacity = panel:NewOOROpacitySlider(group)
	oorOpacity:SetPoint('BOTTOMLEFT', scale, 'TOPLEFT', 0, 20)
	oorOpacity:SetPoint('BOTTOMRIGHT', scale, 'TOPRIGHT', 0, 20)
	
	local opacity = panel:NewOpacitySlider(group)
	opacity:SetPoint('BOTTOMLEFT', oorOpacity, 'TOPLEFT', 0, 20)
	opacity:SetPoint('BOTTOMRIGHT', oorOpacity, 'TOPRIGHT', 0, 20)
	
	local width = panel:NewWidthSlider(group)
	width:SetPoint('BOTTOMLEFT', opacity, 'TOPLEFT', 0, 20)
	width:SetPoint('BOTTOMRIGHT', opacity, 'TOPRIGHT', 0, 20)
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