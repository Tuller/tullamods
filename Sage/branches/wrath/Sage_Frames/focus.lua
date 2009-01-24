--[[
	target.lua
		A sage target frame
--]]

local FocusFrame = Sage:CreateClass('Frame', Sage.Frame)

--constants!
local BORDER_SIZE = 2
local HEALTH_HEIGHT = 20
local POWER_HEIGHT = 12
local INFO_HEIGHT = 14
local NPC_HEIGHT = 14
local BUFF_SIZE = 17 + 2

local function HookScript(f, method, func)
	if f:GetScript(method) then
		f:HookScript(method, func)
	else
		f:SetScript(method, func)
	end
end

function FocusFrame:OnCreate()
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

	local click = Sage.ClickFrame:New(self)
	click:SetPoint('TOPLEFT', health)
	click:SetPoint('BOTTOMRIGHT', power)
	self.click = click
	
	local npc = Sage.NPCInfoBar:New(self, 'GameFontHighlightSmall')
	npc:SetPoint('TOPLEFT', power, 'BOTTOMLEFT', 0, -BORDER_SIZE)
	npc:SetPoint('TOPRIGHT', power, 'BOTTOMRIGHT', 0, -BORDER_SIZE)
	npc:SetHeight(NPC_HEIGHT)
	self.npc = npc
	
	local debuff = Sage.AuraContainer:New('Debuffs', self, 'HARMFUL|PLAYER', 'HELPFUL|PLAYER', 1.25)
	debuff:SetPoint('TOPLEFT', npc, 'BOTTOMLEFT')
	debuff:SetPoint('TOPRIGHT', npc, 'BOTTOMRIGHT')
	debuff:SetHeight(BUFF_SIZE * 2)
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
	
	self:LoadDynamicAnchoringScripts()
end

function FocusFrame:LoadDynamicAnchoringScripts()
	hooksecurefunc(self.power, 'OnShowDisplay', function()
		self.npc:SetPoint('TOPLEFT', self.power, 'BOTTOMLEFT', 0, -BORDER_SIZE)
		self.npc:SetPoint('TOPRIGHT', self.power, 'BOTTOMRIGHT', 0, -BORDER_SIZE)
		self.threat:SetPoint('BOTTOMRIGHT', self.power, BORDER_SIZE, -BORDER_SIZE)
	end)
	
	hooksecurefunc(self.power, 'OnHideDisplay', function()
		self.npc:SetPoint('TOPLEFT', self.health, 'BOTTOMLEFT', 0, -BORDER_SIZE)
		self.npc:SetPoint('TOPRIGHT', self.health, 'BOTTOMRIGHT', 0, -BORDER_SIZE)
		self.threat:SetPoint('BOTTOMRIGHT', self.health, BORDER_SIZE, -BORDER_SIZE)
	end)
end

function FocusFrame:GetDefaults()
	return {
		point = 'TOPLEFT',
		x = 170,
		y = -30,
		width = 150 + BUFF_SIZE * 4 + 1,
		oorAlpha = 0.6,
		height = (BORDER_SIZE*2) + INFO_HEIGHT + HEALTH_HEIGHT + POWER_HEIGHT + NPC_HEIGHT + BUFF_SIZE*2,
	}
end


--[[ Module Code ]]--

local module = Sage:NewModule('FocusFrame', 'AceEvent-3.0')

function module:OnLoad()
	self.frame = FocusFrame:New('focus')
	self:RegisterEvent('PLAYER_FOCUS_CHANGED')
end

function module:OnUnload()
	self.frame:Free()
	self:UnregisterEvent('PLAYER_FOCUS_CHANGED')
end

function module:LoadOptions()
	--create options panel code here
end

--force update of all child frames when the player's target changes
function module:PLAYER_FOCUS_CHANGED()
	self.frame:ForChildren('OnShow')
end