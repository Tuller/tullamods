local MajorFrame = Sage:CreateClass('Frame', Sage.Frame)
local HEALTHBAR_HEIGHT = 20
local POWERBAR_HEIGHT = 12
local INFOBAR_HEIGHT = 18
local BORDER_SIZE = 2


--[[ Generic Major Frame ]]--

function MajorFrame:New(unit)
	local f = MajorFrame.super.New(self, unit)
	f:SetWidth(140)
	f:SetHeight(INFOBAR_HEIGHT + HEALTHBAR_HEIGHT + POWERBAR_HEIGHT + BORDER_SIZE*2)

	local info = Sage.InfoBar:NewParty(f, 'GameFontHighlight')
	info:SetPoint('TOPLEFT', BORDER_SIZE, 0)
	info:SetPoint('BOTTOMRIGHT', f, 'TOPRIGHT', -BORDER_SIZE, -(INFOBAR_HEIGHT))
	f.info = info

	local health = Sage.HealthBar:New(f, 'GameFontHighlightLarge')
	health:SetPoint('TOPLEFT', info, 'BOTTOMLEFT')
	health:SetPoint('BOTTOMRIGHT', info, 'BOTTOMRIGHT', 0, -HEALTHBAR_HEIGHT)
	f.health = health

	local power = Sage.PowerBar:New(f, 'GameFontHighlightSmall')
	power:SetPoint('TOPLEFT', health, 'BOTTOMLEFT', 0, -BORDER_SIZE)
	power:SetPoint('BOTTOMRIGHT', health, 'BOTTOMRIGHT', 0, -POWERBAR_HEIGHT)
	f.power = power

	if unit ~= 'player' then
		local cast = Sage.SpellBar:New(f)
		cast:SetAllPoints(health)
		f.cast = cast
	end

	local threat = Sage.ThreatDisplay:New(f)
	threat:SetPoint('TOPLEFT', health, -BORDER_SIZE, BORDER_SIZE)
	threat:SetPoint('BOTTOMRIGHT', power, BORDER_SIZE, -BORDER_SIZE)
	f.threat = threat

	local click = Sage.ClickFrame:New(f)
	click:SetPoint('TOPLEFT', info, 'BOTTOMLEFT')
	click:SetPoint('BOTTOMRIGHT', health, 'BOTTOMRIGHT', 0, -POWERBAR_HEIGHT)
	f.click = click

	return f
end

function MajorFrame:UpdateAll()
	self.info:UpdateAll()
	self.health:UpdateAll()
	self.power:UpdateAll()

	self.debuff:Update()
	self.buff:Update()

	if self.cast then
		self.cast:Update()
	end
end


--[[ Friendly Unit Frame ]]--

local FriendFrame = Sage:CreateClass('Frame', MajorFrame)

function FriendFrame:New(unit)
	local f = FriendFrame.super.New(self, unit)

	local buff = Sage.AuraContainer:New('Buffs', f, 'HELPFUL')
	buff:SetPoint('TOPLEFT', power, 'BOTTOMLEFT', 0, -2)
	buff:SetPoint('BOTTOMRIGHT', power, 'BOTTOMRIGHT', 0, -(17*2 + 2))
	f.buff = buff

	local debuff = Sage.AuraContainer:New('Debuffs', f, 'HARMFUL')
	debuff:SetPoint('TOPLEFT', health, 'TOPRIGHT', 1, 0)
	debuff:SetPoint('BOTTOMLEFT', power, 'BOTTOMRIGHT', 1, 0)
	debuff:SetWidth(30)
	f.debuff = debuff

	f:SetHeight(f:GetHeight() + 17*2 + 1)
	return f
end


--[[ Targeting Frame ]]--

local TargetFrame = Sage:CreateClass('Frame', MajorFrame)

function TargetFrame:New(unit)
	local f = TargetFrame.super.New(self, unit)

	if unit == 'target' then
		local combo = Sage.ComboFrame:New(f, 'GameFontHighlightSmall')
		combo:SetPoint('TOPRIGHT', f, 'TOPLEFT')
		f.combo = combo
	end

	local npc = Sage.NPCInfoBar:New(f, 'GameFontHighlightSmall')
	npc:SetPoint('TOPLEFT', power, 'BOTTOMLEFT', 0, -2)
	npc:SetPoint('TOPRIGHT', power, 'BOTTOMRIGHT', 0, -2)
	npc:SetHeight(12)
	f.npc = npc

	--shift the NPC frame up when the power frame is hidden
	local power = f.power
	local threat = f.threat
	local health = f.health

	power:HookScript('OnShow', function()
		npc:SetPoint('TOPLEFT', power, 'BOTTOMLEFT', 0, -2)
		npc:SetPoint('TOPRIGHT', power, 'BOTTOMRIGHT', 0, -2)
		threat:SetPoint('BOTTOMRIGHT', power, BORDER_SIZE, -BORDER_SIZE)
	end)

	power:SetScript('OnHide', function()
		npc:SetPoint('TOPLEFT', health, 'BOTTOMLEFT', 0, -2)
		npc:SetPoint('TOPRIGHT', health, 'BOTTOMRIGHT', 0, -2)
		threat:SetPoint('BOTTOMRIGHT', health, BORDER_SIZE, -BORDER_SIZE)
	end)

	local debuff = Sage.AuraContainer:New('Debuffs', f, 'HARMFUL|PLAYER', 'HELPFUL|PLAYER')
	debuff:SetPoint('TOPLEFT', npc, 'BOTTOMLEFT', 0, -2)
	debuff:SetPoint('BOTTOMRIGHT', npc, 'BOTTOMRIGHT', 0, -(17*2 + 2))
	f.debuff = debuff

	local buff = Sage.AuraContainer:New('Buffs', f, 'HELPFUL', 'HARMFUL')
	buff:SetPoint('TOPLEFT', health, 'TOPRIGHT', 1, 0)
	buff:SetPoint('BOTTOMLEFT', power, 'BOTTOMRIGHT', 1, 0)
	buff:SetWidth(18 * 4)
	f.buff = buff

	f:SetHeight(f:GetHeight() + 14 + 17*2 + 2)
	return f
end

function TargetFrame:UpdateAll()
	TargetFrame.super.UpdateAll(self)

	if self.npc then
		self.npc:Update()
	end

	if self.combo then
		self.combo:Update()
	end
end


--[[ Out of range fading ]]--

local RangeFader = CreateFrame('Frame')
RangeFader.nextUpdate = 0
RangeFader.delay = 0.05
RangeFader.frames = {}

function RangeFader:OnUpdate(elapsed)
	self.nextUpdate = self.nextUpdate - elapsed

	if self.nextUpdate < 0 then
		self.nextUpdate = self.delay

		for _,f in pairs(self.frames) do
			self:Fade(f)
		end
	end
end

function RangeFader:Fade(f)
	local unit = f:GetAttribute('unit')
	if (not UnitInRange(unit)) and (UnitIsUnit(unit, 'pet') or UnitInParty(unit) or UnitInRaid(unit)) then
		f:SetAlpha(0.6 * f:GetFrameAlpha())
	else
		f:SetAlpha(f:GetFrameAlpha())
	end
end

function RangeFader:Register(f)
	local found = false
	for _,frame in pairs(self.frames) do
		if f == frame then
			found = true
			break
		end
	end

	if not found then
		table.insert(self.frames, f)
		self:Show()
	end
end

function RangeFader:Unregister(f)
	local found = false

	for i,frame in pairs(self.frames) do
		if f == frame then
			found = true
			table.remove(self.frames, i)
			break
		end
	end

	if found and #self.frames == 0 then
		self:Hide()
	end
end

RangeFader:SetScript('OnUpdate', RangeFader.OnUpdate)
RangeFader:Hide()


--[[
	Module Code
--]]

local module = Sage:NewModule('BasicFrames')

local function PartyFrame_Create(id)
	local f = FriendFrame:New('party' .. id)
	f:SetVisibilityStates('[target=player,raid]hide;nil')
	f:RegisterEvent('PARTY_MEMBERS_CHANGED')
	f:RegisterEvent('RAID_ROSTER_UPDATE')
	f:SetScript('OnEvent', f.UpdateAll)

	RangeFader:Register(f)
end

function module:OnLoad()
	local player = MajorFrame:New('player')
	RegisterStateDriver(player, 'unit', '[target=vehicle,exists]vehicle;player')

	local pet = FriendFrame:New('pet')
	pet:SetScript('OnEvent', pet.UpdateAll)
	pet:RegisterEvent('UNIT_PET')
	RangeFader:Register(pet)

	local target = TargetFrame:New('target')
	target:SetScript('OnEvent', target.UpdateAll)
	target:RegisterEvent('PLAYER_TARGET_CHANGED')
	RangeFader:Register(target)

	local focus = TargetFrame:New('focus')
	focus:SetScript('OnEvent', focus.UpdateAll)
	focus:RegisterEvent('PLAYER_FOCUS_CHANGED')
	RangeFader:Register(focus)

	for id = 1, MAX_PARTY_MEMBERS do
		PartyFrame_Create(id)
	end
end

function module:OnUnload()
	Sage.Frame:Get('player'):Free()
	Sage.Frame:Get('target'):Free()
	Sage.Frame:Get('focus'):Free()
	Sage.Frame:Get('pet'):Free()

	for id = 1, MAX_PARTY_MEMBERS do
		Sage.Frame:Get('party' .. id):Free()
	end
end