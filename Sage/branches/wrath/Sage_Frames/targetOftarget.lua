--[[
	target.lua
		A sage target frame
--]]

local TargetOfTarget = Sage:CreateClass('Frame', Sage.Frame)

--constants!
local BORDER_SIZE = 1
local HEALTH_HEIGHT = 14
local INFO_HEIGHT = 12

function TargetOfTarget:OnCreate()
	local info = Sage.InfoBar:NewParty(self, 'GameFontHighlightSmall')
	info:SetPoint('TOPLEFT', BORDER_SIZE, 0)
	info:SetPoint('TOPRIGHT', -BORDER_SIZE, 0)
	info:SetHeight(INFO_HEIGHT)
	self.info = info

	local health = Sage.HealthBar:New(self, 'GameFontHighlight')
	health:SetPoint('TOPLEFT', info, 'BOTTOMLEFT', 0, -BORDER_SIZE)
	health:SetPoint('TOPRIGHT', info, 'BOTTOMRIGHT', 0, -BORDER_SIZE)
	health:SetHeight(HEALTH_HEIGHT)
	self.health = health

	local threat = Sage.ThreatDisplay:New(self)
	threat:SetPoint('TOPLEFT', health, -BORDER_SIZE, BORDER_SIZE)
	threat:SetPoint('BOTTOMRIGHT', health, BORDER_SIZE, -BORDER_SIZE)
	self.threat = threat

	local click = Sage.ClickFrame:New(self)
	click:SetPoint('TOPLEFT', health)
	click:SetPoint('BOTTOMRIGHT', health)
	self.click = click
	
	self.drag = Sage.DragFrame:New(self)
end

function TargetOfTarget:GetDefaults()
	local settings = {
		point = 'TOPLEFT',
--		x = 20,
--		y = -80,
		alpha = 1,
		oorAlpha = 0.6,
		width = 100,
		updateFreq = 0.5,
		height = (BORDER_SIZE*2) + INFO_HEIGHT + HEALTH_HEIGHT,
		visibilityStates = '[target=player,nogroup]hide'
	}
	
	if self:GetAttribute('unit') == 'targettarget' then
		settings.y = 0
		settings.x = 416
	elseif self:GetAttribute('unit') == 'focustarget' then
		settings.y = 0
		settings.x = 170
	end
	
	return settings
end

function TargetOfTarget:OnUpdate(elapsed)
	self.nextUpdate = (self.nextUpdate or 0) - elapsed
	if self.nextUpdate < 0 then
		self.nextUpdate = self.sets.updateFreq
		self:ForChildren('OnShow')
	end
end

function TargetOfTarget:OnEvent(event, unit)
	if self:IsVisible() then
		if unit == self:GetAttribute('unit'):match('(%w+)target') then
			self:ForChildren('OnShow')
		end
	end
end


--[[ Module Code ]]--

local module = Sage:NewModule('TargetOfTarget', 'AceEvent-3.0')

function module:OnLoad()
	self:CreateTargetOfUnitFrame('target')
	self:CreateTargetOfUnitFrame('focus')
end

function module:OnUnload()
	Sage.Frame:Get('targettarget'):Free()
	Sage.Frame:Get('focustarget'):Free()
end

function module:LoadOptions()
	self:LoadUnitOptions('targettarget', 'Target of Target')
	self:LoadUnitOptions('focustarget', 'Target of Focus')
end

function module:LoadUnitOptions(group, title)
	local name = format('Sage%sOptions', group)
	local desc = format('Configuration settings for the Sage %s frame', title:lower())
	
	local panel = Sage.Options:New(name, title, desc, nil, GetAddOnMetadata('Sage', 'title'))
	
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

function module:CreateTargetOfUnitFrame(unit)
	local f = TargetOfTarget:New(unit .. 'target')
	f:SetScript('OnUpdate', f.OnUpdate)
	f:RegisterEvent('OnEvent', f.OnEvent)
	f:RegisterEvent('UNIT_TARGET')

	return f
end