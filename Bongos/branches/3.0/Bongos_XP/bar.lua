--[[
        Bongos_XP\xpBar.lua
                Scripts for the Bongos XP bar
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local XP = Bongos:NewModule('XP')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3-XP')

--constants
local HORIZONTAL_TEXTURE = 'Interface\\Addons\\Bongos_XP\\img\\Armory'
local VERTICAL_TEXTURE = 'Interface\\Addons\\Bongos_XP\\img\\ArmoryV'

local XP_FORMAT = '%s / %s (%s%%)'
local REST_FORMAT = '%s / %s (+%s) (%s%%)'
local REP_FORMAT = '%s:  %s / %s (%s)'

local DEFAULT_HEIGHT = 14
local DEFAULT_SIZE = 0.75
local DEFAULT_TEXT_POSITION = 0


--[[ Module Code ]]--

function XP:Load()
	local defaults = {
		point = 'TOP',
		x = 0,
		y = -32,
		alwaysShowText = true,
	}

	local bar, isNew = Bongos.Bar:Create('xp', defaults, false, 'BACKGROUND')
	if isNew then
		self:OnBarCreate(bar)
	end
	bar.xp:UpdateOrientation()
	bar.xp:Update()
	bar.xp:UpdateText()

	self.bar = bar
end

function XP:Unload()
	self.bar:Destroy()
end


--[[ Menu Creation ]]--

local function HeightSlider_Create(panel, bar)
	local function OnShow(self)
		self:SetValue(bar.sets.height or DEFAULT_HEIGHT)
		getglobal(self:GetName() ..'Text'):SetText(bar.sets.vertical and L.Width or L.Height)
	end

	local function UpdateValue(self, value)
		bar.sets.height = value
		bar.xp:UpdateSize()
	end

	return panel:CreateSlider('Height', 0, 128, 1, OnShow, UpdateValue)
end

local function SizeSlider_Create(panel, bar)
	local function OnShow(self)
		self:SetValue((bar.sets.size or DEFAULT_SIZE)*100)
		getglobal(self:GetName() .. 'Text'):SetText(bar.sets.vertical and L.Height or L.Width)
	end

	local function UpdateValue(self, value)
		bar.sets.size = value/100
		bar.xp:UpdateSize()
	end

	return panel:CreateSlider('Size', 0, 100, 1, OnShow, UpdateValue)
end

local function TextPosition_Create(panel, bar)
	local function OnShow(self, value)
		self:SetValue((bar.sets.textPosition or DEFAULT_TEXT_POSITION) * 100)
		bar.xp:UpdateTextPosition()
	end

	local function UpdateValue(self, value)
		bar.sets.textPosition = value/100
		bar.xp:UpdateTextPosition()
	end

	return panel:CreateSlider(L.TextPosition, -50, 50, 1, OnShow, UpdateValue)
end

local function AlwaysShowText_Create(panel, bar)
	--always show text checkbox
	local ast = panel:CreateCheckButton(L.AlwaysShowText)
	ast:SetScript('OnShow', function(self)
		self:SetChecked(bar.sets.alwaysShowText)
	end)

	ast:SetScript('OnClick', function(self)
		bar.sets.alwaysShowText = self:GetChecked() and 1 or nil
		bar.xp:UpdateText()
	end)

	return ast
end

local function AlwaysShowXP_Create(panel, bar)
	--always show experience
	local asXP = panel:CreateCheckButton(L.AlwaysShowXP)
	asXP:SetScript('OnShow', function(self)
		self:SetChecked(bar.sets.alwaysShowXP)
	end)

	asXP:SetScript('OnClick', function(self)
		bar.sets.alwaysShowXP = self:GetChecked() and 1 or nil
		bar.xp:Update()
	end)

	return asXP
end

local function Vertical_Create(panel, bar)
	local vertical = panel:CreateCheckButton(L.Vertical)
		vertical:SetScript('OnShow', function(self)
		self:SetChecked(bar.sets.vertical)
	end)

	vertical:SetScript('OnClick',  function(self)
		bar.sets.vertical = self:GetChecked() and 1 or nil
		bar.xp:UpdateOrientation()

		if self:GetChecked() then
			getglobal(panel:GetName() .. 'SizeText'):SetText(L.Height)
			getglobal(panel:GetName() .. 'HeightText'):SetText(L.Width)
		else
			getglobal(panel:GetName() .. 'SizeText'):SetText(L.Width)
			getglobal(panel:GetName() .. 'HeightText'):SetText(L.Height)
		end
	end)

	return vertical
end

--called when the bongos bar is physically created
function XP:OnBarCreate(bar)
	bar.CreateMenu = function(bar)
		local menu = Bongos.Menu:Create(bar.id)
		local panel = menu:AddLayoutPanel()

		--checkboxes
		local ast = AlwaysShowText_Create(panel, bar)	
		local alwaysShowXP = AlwaysShowXP_Create(panel, bar)
		local vertical = Vertical_Create(panel, bar)

		--sliders
		local height = HeightSlider_Create(panel, bar)
		local size = SizeSlider_Create(panel, bar)
		local textPosition = TextPosition_Create(panel, bar)

		return menu
	end

	bar.xp = self.Bar:Create(bar)
end


--[[ XP Bar Widget ]]--

local XPBar = Bongos:CreateWidgetClass('StatusBar')
XP.Bar = XPBar

function XPBar:Create(parent)
	local bar = self:New(CreateFrame('StatusBar', nil, parent))
	bar:EnableMouse(true)
	bar:SetClampedToScreen(true)
	bar:SetAllPoints(parent)
	bar.id = parent.id
	bar.sets = parent.sets

	local bg = bar:CreateTexture(nil, 'BACKGROUND')
	bg:SetAllPoints(bar)
	bar.bg = bg

	local overlay = CreateFrame('StatusBar', nil, bar)
	overlay:EnableMouse(true)
	overlay:SetAllPoints(bar)
	overlay.sets = parent.sets
	overlay.bar = bar
	bar.overlay = overlay

	local text = overlay:CreateFontString(nil, 'OVERLAY')
	text:SetFontObject('GameFontHighlight')
	bar.text = text

	bar:SetScript('OnShow', self.OnShow)
	bar:SetScript('OnHide', self.OnHide)

	overlay:SetScript('OnEnter', self.OnEnter)
	overlay:SetScript('OnLeave', self.OnLeave)
	overlay:SetScript('OnMouseDown', self.OnMouseDown)

	bar:Update()
	bar:UpdateText()
	bar:UpdateTextPosition()

	return bar
end

--frame events
function XPBar:OnShow()
	self:Update()
end

function XPBar:OnHide()
	self:UnregisterAllEvents()
end

function XPBar:OnEnter()
	self:GetParent().entered = true
	self:GetParent():UpdateText()
end

function XPBar:OnLeave()
	self:GetParent().entered = nil
	self:GetParent():UpdateText()
end

function XPBar:OnMouseDown()
	self:GetParent().sets.alwaysShowXP = not self:GetParent().sets.alwaysShowXP
	self:GetParent():Update()
end

--update functions
function XPBar:WatchExperience()
	self:UnregisterAllEvents()
	self:SetScript('OnEvent', self.UpdateExperience)
	self:RegisterEvent('UPDATE_FACTION')
	self:RegisterEvent('PLAYER_LOGIN')
	self:RegisterEvent('PLAYER_LEVEL_UP')
	self:RegisterEvent('PLAYER_XP_UPDATE')
	self:RegisterEvent('UPDATE_EXHAUSTION')

	self:SetStatusBarColor(0.25, 0.25, 1)
	self.overlay:SetStatusBarColor(0.6, 0, 0.6)
	self.bg:SetVertexColor(0.3, 0, 0.3, 0.6)

	self:UpdateExperience()
end

function XPBar:WatchReputation()
	self:UnregisterAllEvents()
	self:SetScript('OnEvent', self.UpdateReputation)
	self:RegisterEvent('UPDATE_FACTION')

	self.overlay:SetValue(0)
	self.overlay:SetStatusBarColor(0, 0, 0, 0)
	self.bg:SetVertexColor(0, 0.3, 0, 0.6)

	self:UpdateReputation()
end

function XPBar:UpdateExperience()
	if GetWatchedFactionInfo() and not self.sets.alwaysShowXP then
		self:WatchReputation()
	else
		local value = UnitXP('player')
		local max = UnitXPMax('player')
		-- do percentage to 3 sig digits (nn.n%)
		-- first get pct*10 (raw ratio * 1000)
		local pct10 = (value / max) * 1000
		-- now round by doing floor(n+0.5)
		pct10 = floor(pct10 + 0.5)
		-- now shift the decimal point back in
		local pct = pct10 / 10

		self:SetMinMaxValues(0, max)
		self.overlay:SetMinMaxValues(0, max)
		self.overlay:SetValue(value)

		local rest = GetXPExhaustion()
		if rest then
			self:SetValue(value + rest)
			self.text:SetFormattedText(REST_FORMAT, value, max, rest, pct)
		else
			self:SetValue(0)
			self.text:SetFormattedText(XP_FORMAT, value, max, pct)
		end
	end
end

function XPBar:UpdateReputation()
	local name, reaction, min, max, value = GetWatchedFactionInfo()
	if name then
		max = max - min
		value = value - min

		local color = FACTION_BAR_COLORS[reaction]
		self:SetStatusBarColor(color.r, color.g, color.b)
		self:SetMinMaxValues(0, max)
		self:SetValue(value)

		local repLevel = getglobal("FACTION_STANDING_LABEL" .. reaction)
		self.text:SetFormattedText(REP_FORMAT, name, value, max, repLevel)
	else
		self:WatchExperience()
	end
end

function XPBar:Update()
	if GetWatchedFactionInfo() and not self.sets.alwaysShowXP then
		self:WatchReputation()
	else
		self:WatchExperience()
	end
end

function XPBar:UpdateText()
	if self.entered or self.sets.alwaysShowText then
		self.text:Show()
	else
		self.text:Hide()
	end
end

function XPBar:UpdateTextPosition()
	self.text:ClearAllPoints()
	if self.sets.vertical then
		local yOff = self:GetParent():GetHeight() * (self.sets.textPosition or DEFAULT_TEXT_POSITION)
		self.text:SetPoint('LEFT', 0, yOff)
	else
		local xOff = self:GetParent():GetWidth() * (self.sets.textPosition or DEFAULT_TEXT_POSITION)
		self.text:SetPoint('CENTER', xOff, 0)
		xoff = self.sets.textPosition or DEFAULT_TEXT_POSITION
	end
end

function XPBar:UpdateOrientation()
	if self.sets.vertical then
		self:SetOrientation('VERTICAL')
		self:SetStatusBarTexture(VERTICAL_TEXTURE)

		self.overlay:SetOrientation('VERTICAL')
		self.overlay:SetStatusBarTexture(VERTICAL_TEXTURE)

		self.bg:SetTexture(VERTICAL_TEXTURE)
	else
		self:SetOrientation('HORIZONTAL')
		self:SetStatusBarTexture(HORIZONTAL_TEXTURE)

		self.overlay:SetOrientation('HORIZONTAL')
		self.overlay:SetStatusBarTexture(HORIZONTAL_TEXTURE)

		self.bg:SetTexture(HORIZONTAL_TEXTURE)
	end
	self:UpdateSize()
	self:UpdateTextPosition()
end

function XPBar:UpdateSize()
	local size = self.sets.size
	local height = self.sets.height

	if self.sets.vertical then
		self:GetParent():SetHeight(GetScreenHeight() * (size or DEFAULT_SIZE))
		self:GetParent():SetWidth(height or DEFAULT_HEIGHT)
	else
		self:GetParent():SetWidth(GetScreenWidth() * (size or DEFAULT_SIZE))
		self:GetParent():SetHeight(height or DEFAULT_HEIGHT)
	end
end