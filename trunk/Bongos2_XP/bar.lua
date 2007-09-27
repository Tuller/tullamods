--[[
	Bongos_XP\xpBar.lua
		Scripts for the Bongos XP bar
--]]

BongosXP = Bongos:NewModule('Bongos-XP')

local L = BONGOS_LOCALS
local HORIZONTAL_TEXTURE = 'Interface\\Addons\\Bongos2_XP\\img\\Smooth'
local VERTICAL_TEXTURE = 'Interface\\Addons\\Bongos2_XP\\img\\SmoothV'
local REP_FORMAT = '%s:  %s / %s (%s)'
local REST_FORMAT = '%s / %s (+%s)'
local XP_FORMAT = '%s / %s'
local DEFAULT_HEIGHT = 14
local DEFAULT_SIZE = 0.75


--[[ XPBar, a statusbar that displays reputation or experience ]]--

local XPBar = {}

function XPBar:New(parent)
	local bar = CreateFrame('StatusBar', nil, parent)
	bar:EnableMouse(true)
	bar:SetClampedToScreen(true)
	bar:SetAllPoints(parent)

	--copy over all the XPBar functions
	for k,v in pairs(self) do bar[k] = v end

	bar.id = parent.id
	bar.sets = parent.sets

	local bg = bar:CreateTexture(nil, 'BACKGROUND')
	bg:SetAllPoints(bar)
	bar.bg = bg

	local overlay = CreateFrame('StatusBar', nil, bar)
	overlay:EnableMouse(false)
	overlay:SetAllPoints(bar)
	bar.overlay = overlay

	local text = overlay:CreateFontString(nil, 'OVERLAY')
	text:SetFontObject('GameFontHighlight')
	text:SetPoint('CENTER', bar)
	bar.text = text

	bar:SetScript('OnShow', bar.OnShow)
	bar:SetScript('OnHide', bar.OnHide)
	bar:SetScript('OnEnter', bar.OnEnter)
	bar:SetScript('OnLeave', bar.OnLeave)

	bar:Update()
	bar:UpdateText()

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
	self.entered = true
	self:UpdateText()
end

function XPBar:OnLeave()
	self.entered = nil
	self:UpdateText()
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
	if GetWatchedFactionInfo() then
		self:WatchReputation()
	else
		local value = UnitXP('player')
		local max = UnitXPMax('player')

		self:SetMinMaxValues(0, max)
		self.overlay:SetMinMaxValues(0, max)
		self.overlay:SetValue(value)

		local rest = GetXPExhaustion()
		if rest then
			self:SetValue(value + rest)
			self.text:SetText(REST_FORMAT:format(value, max, rest))
		else
			self:SetValue(0)
			self.text:SetText(XP_FORMAT:format(value, max))
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

		self.text:SetText(REP_FORMAT:format(name, value, max, repLevel))
	else
		self:WatchExperience()
	end
end

function XPBar:Update()
	if GetWatchedFactionInfo() then
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


--[[ Bongos Bar Stuff ]]--

--menu creation
local function Bar_CreateMenu(frame)
	local menu, panel = BongosMenu:CreateMenu(frame.id)
	local size, height

	--always show text checkbox
	local alwaysShowText = panel:AddCheckButton(L.AlwaysShowText)
	alwaysShowText:SetScript('OnShow', function(self)
		self:SetChecked(frame.sets.alwaysShowText)
	end)

	alwaysShowText:SetScript('OnClick', function(self)
		frame.sets.alwaysShowText = self:GetChecked() and 1 or nil
		frame.xp:UpdateText()
	end)

	--vertical orientation slider
	local vertical = panel:AddCheckButton(L.Vertical)
	vertical:SetScript('OnShow', function(self)
		self:SetChecked(frame.sets.vertical)
	end)

	vertical:SetScript('OnClick',  function(self)
		frame.sets.vertical = self:GetChecked() and 1 or nil
		frame.xp:UpdateOrientation()

		if self:GetChecked() then
			getglobal(size:GetName() .. 'Text'):SetText(L.Height)
			getglobal(height:GetName() .. 'Text'):SetText(L.Width)
		else
			getglobal(size:GetName() .. 'Text'):SetText(L.Width)
			getglobal(height:GetName() .. 'Text'):SetText(L.Height)
		end
	end)

	height = panel:AddSlider('Height', 0, 128, 1)
	height:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(frame.sets.height or DEFAULT_HEIGHT)
		getglobal(self:GetName() .. 'Text'):SetText(frame.sets.vertical and L.Width or L.Height)
		self.onShow = nil
	end)

	height:SetScript('OnValueChanged', function(self, value)
		if not self.onShow then
			frame.sets.height = value
			frame.xp:UpdateSize()
		end
		getglobal(self:GetName() .. 'ValText'):SetText(value)
	end)

	--size slider
	size = panel:AddSlider('Size', 0, 100, 1)
	size:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue((frame.sets.size or DEFAULT_SIZE) * 100)
		getglobal(self:GetName() .. 'Text'):SetText(frame.sets.vertical and L.Height or L.Width)
		self.onShow = nil
	end)

	size:SetScript('OnValueChanged', function(self, value)
		if not self.onShow then
			frame.sets.size = value / 100
			frame.xp:UpdateSize()
		end
		getglobal(self:GetName() .. 'ValText'):SetText(value)
	end)

	return menu
end

--add stuff to the bar after it has been first created
local function Bar_OnCreate(self)
	self.CreateMenu = Bar_CreateMenu
	self.xp = XPBar:New(self)
end

--module loading
function BongosXP:Load()
	local bar = BBar:Create('xp', Bar_OnCreate, nil, nil, 'BACKGROUND')
	if not bar:IsUserPlaced() then
		bar:SetPoint('TOP', UIParent, 'TOP', 0, -32)
	end

	bar.xp:UpdateOrientation()
	bar.xp:Update()
	bar.xp:UpdateText()

	self.bar = bar
end

--module unloading
function BongosXP:Unload()
	self.bar:Destroy()
end