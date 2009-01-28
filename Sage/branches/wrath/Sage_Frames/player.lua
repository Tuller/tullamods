--[[
	player.lua
		A sage player frame
--]]

local PlayerFrame = Sage:CreateClass('Frame', Sage.Frame)
local BORDER_SIZE = 2
local HEALTH_HEIGHT = 20
local POWER_HEIGHT = 12
local INFO_HEIGHT = 14

function PlayerFrame:OnCreate()
	local info = Sage.InfoBar:NewParty(self, 'GameFontHighlight')
	info:SetPoint('TOPLEFT', BORDER_SIZE, 0)
	info:SetPoint('TOPRIGHT', -BORDER_SIZE, 0)
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
	
	--add a drag frame
	self.drag = Sage.DragFrame:New(self)
end

function PlayerFrame:GetDefaults()
	return {
		point = 'TOPLEFT',
		x = 20,
		y = -30,
		width = 150,
		height = (BORDER_SIZE*2) + INFO_HEIGHT + HEALTH_HEIGHT + POWER_HEIGHT,
		unitStates = '[target=vehicle,exists,bonusbar:5]vehicle;player',
	}
end


--[[ Module Code ]]--

local module = Sage:NewModule('PlayerFrame', 'AceEvent-3.0')

function module:OnLoad()
	self.frame = PlayerFrame:New('player')
	self:RegisterEvent('PLAYER_ENTERING_WORLD')
end

function module:OnUnload()
	self.frame:Free()
	self:UnregisterEvent('PLAYER_ENTERING_WORLD')
end

function module:LoadOptions()
	local panel = Sage.Options:New('SagePlayerOptions', 'Player', 'Configuration settings for the Sage player frame', nil, GetAddOnMetadata('Sage', 'title'))
	local group = 'player'

	--sliders
	local scale = panel:NewScaleSlider(group)
	scale:SetPoint('BOTTOMLEFT', 10, 10)
	scale:SetPoint('BOTTOMRIGHT', -40, 10)

	local opacity = panel:NewOpacitySlider(group)
	opacity:SetPoint('BOTTOMLEFT', scale, 'TOPLEFT', 0, 20)
	opacity:SetPoint('BOTTOMRIGHT', scale, 'TOPRIGHT', 0, 20)
	
	local width = panel:NewWidthSlider(group)
	width:SetPoint('BOTTOMLEFT', opacity, 'TOPLEFT', 0, 20)
	width:SetPoint('BOTTOMRIGHT', opacity, 'TOPRIGHT', 0, 20)
end

function module:PLAYER_ENTERING_WORLD()
	self.frame:ForChildren('OnShow')
end