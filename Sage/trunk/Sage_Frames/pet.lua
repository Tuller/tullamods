--[[
	target.lua
		A sage target frame
--]]

local PetFrame = Sage:CreateClass('Frame', Sage.Frame)

--constants!
local BORDER_SIZE = 1
local HEALTH_HEIGHT = 14
local POWER_HEIGHT = 8
local INFO_HEIGHT = 12
local BUFF_SIZE = 10 + 2

function PetFrame:OnCreate()
	local info = Sage.InfoBar:NewParty(self, 'GameFontHighlightSmall')
	info:SetPoint('TOPLEFT', BORDER_SIZE, 0)
	info:SetPoint('TOPRIGHT', -(BORDER_SIZE + BUFF_SIZE*4 + 1), 0)
	info:SetHeight(INFO_HEIGHT)
	self.info = info

	local health = Sage.HealthBar:New(self, 'GameFontHighlight')
	health:SetPoint('TOPLEFT', info, 'BOTTOMLEFT', 0, -BORDER_SIZE)
	health:SetPoint('TOPRIGHT', info, 'BOTTOMRIGHT', 0, -BORDER_SIZE)
	health:SetHeight(HEALTH_HEIGHT)
	self.health = health

	local power = Sage.PowerBar:New(self)
	power:SetPoint('TOPLEFT', health, 'BOTTOMLEFT', 0, -BORDER_SIZE)
	power:SetPoint('TOPRIGHT', health, 'BOTTOMRIGHT', 0, -BORDER_SIZE)
	power:SetHeight(POWER_HEIGHT)
	self.power = power

	local threat = Sage.ThreatDisplay:New(self)
	threat:SetPoint('TOPLEFT', health, -BORDER_SIZE, BORDER_SIZE)
	threat:SetPoint('BOTTOMRIGHT', power, BORDER_SIZE, -BORDER_SIZE)
	self.threat = threat

	local click = Sage.ClickFrame:New(self)
	click:SetPoint('TOPLEFT', health)
	click:SetPoint('BOTTOMRIGHT', power)
	self.click = click
	
	local debuff = Sage.AuraContainer:New('Debuffs', self, 'HARMFUL|PLAYER', 'HELPFUL|PLAYER', 1.25)
	debuff:SetPoint('TOPLEFT', power, 'BOTTOMLEFT')
	debuff:SetPoint('TOPRIGHT', power, 'BOTTOMRIGHT')
	debuff:SetHeight(BUFF_SIZE * 2)
	debuff.showOnlyMyBuffs_Change = debuff.SetFriendFilter
	self.debuff = debuff

	local buff = Sage.AuraContainer:New('Buffs', self, 'HELPFUL', 'HARMFUL')
	buff:SetPoint('TOPLEFT', health, 'TOPRIGHT', 1, 0)
	buff:SetPoint('BOTTOMLEFT', power, 'BOTTOMLEFT', 1, 0)
	buff:SetWidth(BUFF_SIZE * 4)
	self.buff = buff
	
	local cast = Sage.SpellBar:New(self)
	cast:SetAllPoints(health)
	self.cast = cast
	
	self.drag = Sage.DragFrame:New(self)
end

function PetFrame:GetDefaults()
	return {
		point = 'TOPLEFT',
		x = 20,
		y = -80,
		alpha = 1,
		oorAlpha = 0.6,
		width = 100,
		extraWidth = BUFF_SIZE * 4 + 1,
		height = (BORDER_SIZE*2) + INFO_HEIGHT + HEALTH_HEIGHT + POWER_HEIGHT + BUFF_SIZE*2,
		unitStates = '[target=vehicle,exists,bonusbar:5]player;pet',
	}
end


--[[ Module Code ]]--

local module = Sage:NewModule('PetFrame', 'AceEvent-3.0')

function module:OnLoad()
	self.frame = PetFrame:New('pet')
	self:RegisterEvent('UNIT_PET')
end

function module:OnUnload()
	self.frame:Free()
	self:UnregisterEvent('UNIT_PET')
end

function module:LoadOptions()
	local panel = Sage.Options:New('SagePetOptions', 'Pet', 'Configuration settings for the Sage pet frame', nil, GetAddOnMetadata('Sage', 'title'))
	local group = 'pet'
	
	--buttons
	local showOnlyMyBuffs = panel:NewSettingCheckButton("Show Only Buffs I've Cast", group, 'showOnlyMyBuffs', 'HELPFUL|PLAYER', 'HELPFUL')
	showOnlyMyBuffs:SetPoint('TOPLEFT', 12, -72)

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

--force update of all child frames when the player's target changes
function module:UNIT_PET(...)
	local msg, unit = ...
	if unit == 'player' then
		self.frame:ForChildren('OnShow')
	end
end