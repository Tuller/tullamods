local MajorFrame = Sage:CreateClass('Frame', Sage.Frame)
local HEALTHBAR_HEIGHT = 20
local POWERBAR_HEIGHT = 12
local INFOBAR_HEIGHT = 18
local BORDER_SIZE = 2

local function IsFriendlyUnit(unit)
	return unit == 'player' or unit == 'pet' or unit:match('party%d')
end

function MajorFrame:New(unit)
	local f = self.super.New(self, unit)
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

	local power = Sage.PowerBar:NewFrequent(f, 'GameFontHighlightSmall')
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

	if IsFriendlyUnit(unit) then
		if unit ~= 'player' then
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
		end
	else
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
	end

	return f
end

function MajorFrame:UpdateAll()
	self.info:UpdateAll()
	self.health:UpdateAll()
	self.power:Update()
	self.debuff:Update()
	self.buff:Update()
	self.cast:Update()

	if self.npc then
		self.npc:Update()
	end

	if self.combo then
		self.combo:Update()
	end
end


--[[
	Module Code
--]]

local module = Sage:NewModule('BasicFrames')

function module:OnEnable()
	local function Fade(f)
		if f then
			if UnitInRange(f:GetAttribute('unit')) then
				f:SetAlpha(f:GetFrameAlpha())
			else
				f:SetAlpha(0.6 * f:GetFrameAlpha())
			end
		end
	end

	CreateFrame('Frame'):SetScript('OnUpdate', function(self, elapsed)
		self.nextUpdate = (self.nextUpdate or 0) - elapsed
		if self.nextUpdate < 0 then
			self.nextUpdate = 1

			Fade(Sage.Frame:Get('pet'))
			for i = 1, MAX_PARTY_MEMBERS do
				Fade(Sage.Frame:Get('party' .. i))
			end
		end
	end)
end

function module:OnLoad()
	local player = MajorFrame:New('player')
	RegisterStateDriver(player, 'unit', '[target=vehicle,exists]vehicle;player')

	local target = MajorFrame:New('target')
	target:SetScript('OnEvent', target.UpdateAll)
	target:RegisterEvent('PLAYER_TARGET_CHANGED')

	local focus = MajorFrame:New('focus')
	focus:SetScript('OnEvent', focus.UpdateAll)
	focus:RegisterEvent('PLAYER_FOCUS_CHANGED')

	local pet = MajorFrame:New('pet')
	RegisterStateDriver(pet, 'unit', '[target=vehicle,exists]player;pet')
	pet:SetScript('OnEvent', pet.UpdateAll)
	pet:RegisterEvent('UNIT_PET')

	for i = 1, MAX_PARTY_MEMBERS do
		local f = MajorFrame:New('party' .. i)
		f:RegisterEvent('PARTY_MEMBERS_CHANGED')
		f:RegisterEvent('RAID_ROSTER_UPDATE')
		f:SetScript('OnEvent', f.UpdateAll)
	end
end

function module:OnUnload()
	Sage.Frame:Get('player'):Free()
	Sage.Frame:Get('target'):Free()
	Sage.Frame:Get('focus'):Free()
	Sage.Frame:Get('pet'):Free()

	for i = 1, MAX_PARTY_MEMBERS do
		Sage.Frame:Get('party' .. i):Free()
	end
end