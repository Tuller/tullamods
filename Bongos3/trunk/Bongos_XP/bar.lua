--[[
        Bongos_XP\xpBar.lua
                Scripts for the Bongos XP bar
--]]

local Ace = LibStub('AceAddon-3.0')
local Bongos = Ace:GetAddon('Bongos3')
local XP = Bongos:NewModule('XP')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3-XP')

local HORIZONTAL_TEXTURE = 'Interface\\Addons\\Bongos_XP\\img\\Armory'
local VERTICAL_TEXTURE = 'Interface\\Addons\\Bongos_XP\\img\\ArmoryV'

local XP_FORMAT = '%s / %s (%s%%)'
local REST_FORMAT = '%s / %s (+%s) (%s%%)'
local REP_FORMAT = '%s:  %s / %s (%s)'


--[[ Module Code ]]--

function XP:Load()
	local defaults = {
		alwaysShowText = true,
		textX = 0,
		textY = 0,
		point = 'TOP',
		width = 0.75,
		height = 14,
		y = -32,
		x = 0,
	}

	local bar, isNew = Bongos.Bar:Create('xp', defaults, 'MEDIUM')
	if isNew then
		self.LoadBar(bar)
	end
	
	------ temporary -------------------------------------------------
	bar.sets.width = bar.sets.width or bar.sets.size or defaults.width
	bar.sets.height = bar.sets.height or defaults.height
	bar.sets.textX = bar.sets.textX or defaults.textX
	bar.sets.textY = bar.sets.textY or defaults.textY
	-------------------------------------------------
	
	bar.xp:ToggleText(bar.sets.alwaysShowText)
	bar.xp:UpdateOrientation()
	bar.xp:UpdateWatch()

	self.bar = bar
end

function XP:LoadBar()
	for k,v in pairs(XP) do self[k] = v end
	self.xp = self.Bar:Create(self)
end

function XP:Unload()
	self.bar:Destroy()
end


--[[ Status Bar Widget ]]--

local XPBar = Bongos:CreateWidgetClass('StatusBar')
XP.Bar = XPBar

function XPBar:Create(parent)
	local bar = self:New(CreateFrame('StatusBar', nil, parent))
	bar:SetClampedToScreen(true)
	bar:SetAllPoints(parent)
	bar:EnableMouse(true)
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
	bar.text = text

	bar:SetScript('OnShow', self.OnShow)
	bar:SetScript('OnHide', self.OnHide)
	bar:SetScript('OnMouseUp', self.OnClick) --we don't need a button frame to include this feature

	Ace:EmbedLibrary(bar, "AceEvent-3.0")
	return bar
end

function XPBar:OnClick()
	self.sets.alwaysShowXP = not self.sets.alwaysShowXP
	self:UpdateWatch()
end

function XPBar:OnShow()
	self:UpdateWatch()
end

function XPBar:OnHide()
	self:UnregisterAllEvents()
end

function XPBar:UpdateWatch()
	if not self.sets.alwaysShowXP and GetWatchedFactionInfo() then
		self:WatchReputation()
	else
		self:WatchExperience()
	end
end


--[[ Experience ]]--

function XPBar:WatchExperience()
	self:UnregisterAllEvents()
	self:RegisterEvent('UPDATE_FACTION', 'UpdateWatch')
	
	local func = 'UpdateExperience'
	self:RegisterEvent('UPDATE_EXHAUSTION', func)
	self:RegisterEvent('PLAYER_XP_UPDATE', func)
	self:RegisterEvent('PLAYER_LEVEL_UP', func)
	self:RegisterEvent('PLAYER_LOGIN', func)

	self:SetStatusBarColor(0.25, 0.25, 1)
	self.overlay:SetStatusBarColor(0.6, 0, 0.6)
	self.bg:SetVertexColor(0.3, 0, 0.3, 0.6)

	self:UpdateExperience()
end

function XPBar:UpdateExperience()
	local value = UnitXP('player')
	local max = UnitXPMax('player')
	local percent = floor(value / max * 1000 + 0.5) / 10

	self:SetMinMaxValues(0, max)
	self.overlay:SetMinMaxValues(0, max)
	self.overlay:SetValue(value)
	
	local rest = GetXPExhaustion()
	if rest then
		self:SetValue(value + rest)
		self.text:SetFormattedText(REST_FORMAT, value, max, rest, percent)
	else
		self:SetValue(0)
		self.text:SetFormattedText(XP_FORMAT, value, max, percent)
	end
	self:UpdateTextPosition()
end


--[[ Reputation ]]--

function XPBar:WatchReputation()
	self:UnregisterAllEvents()
	self:RegisterEvent('UPDATE_FACTION', 'UpdateWatch')

	self.overlay:SetValue(0)
	self.overlay:SetStatusBarColor(0, 0, 0, 0)

	self:UpdateReputation()
end

function XPBar:UpdateReputation()
	local name, reaction, min, max, value = GetWatchedFactionInfo()
	max = max - min
	value = value - min

	local color = FACTION_BAR_COLORS[reaction]
	self:SetStatusBarColor(color.r, color.g, color.b)
	self.bg:SetVertexColor(color.r - 0.3, color.g - 0.3, color.b - 0.3, 0.6)
	
	self:SetMinMaxValues(0, max)
	self:SetValue(value)

	local repLevel = getglobal("FACTION_STANDING_LABEL" .. reaction)
	self.text:SetFormattedText(REP_FORMAT, name, value, max, repLevel)
	self:UpdateTextPosition()
end


--[[ Layout Updates ]]--

function XPBar:UpdateOrientation()
	local texture, orientation
	if self.sets.vertical then
		texture, orientation = VERTICAL_TEXTURE, 'VERTICAL'
	else
		texture, orientation = HORIZONTAL_TEXTURE, 'HORIZONTAL'
	end
	
	self:SetOrientation(orientation)
	self:SetStatusBarTexture(texture)
	self.overlay:SetOrientation(orientation)
	self.overlay:SetStatusBarTexture(texture)
	self.bg:SetTexture(texture)
	
	self:UpdateSize()
end

function XPBar:UpdateSize()
	local width = self.sets.width
	local height = self.sets.height

	if self.sets.vertical then
		self:GetParent():SetHeight(GetScreenHeight() * width)
		self:GetParent():SetWidth(height)
	else
		self:GetParent():SetWidth(GetScreenWidth() * width)
		self:GetParent():SetHeight(height)
	end
	self:UpdateTextPosition()
end


--[[ Bar Text ]]--

function XPBar:OnEnter()
	UIFrameFadeIn(self.text, 0.2)
end

function XPBar:OnLeave()
	UIFrameFadeOut(self.text, 0.3)
end

function XPBar:ToggleText(enable)
	self.sets.alwaysShowText = enable
	if enable then
		self:SetScript('OnEnter', nil)
		self:SetScript('OnLeave', nil)
		self:OnEnter()
	else
		self:SetScript('OnEnter', self.OnEnter)
		self:SetScript('OnLeave', self.OnLeave)
		self:OnLeave()
	end
end

function XPBar:UpdateTextPosition()
	self.text:ClearAllPoints()
	local parent = self:GetParent()
	
	local xOff = ( self.text:GetWidth() + parent:GetWidth() ) * self.sets.textX
	local yOff = ( self.text:GetHeight() + parent:GetHeight() ) * self.sets.textY
	
	self.text:SetPoint('CENTER', xOff, yOff)
end


--[[ Menu Creation ]]--

function XP:CreateMenu()
	local menu = Bongos.Menu:Create(self.id)
	local panel = menu:AddLayoutPanel()

	self:CreateVerticalButton(panel)
	self:CreateAlwaysXPButton(panel)

	self:CreateHeightSlider(panel)
	self:CreateWidthSlider(panel)
	
	local panel = menu:AddPanel(L.Text)
	
	self:CreateAlwaysShowTextButton(panel)
	self:CreateTextPositionSlider(panel, L.HorizontalPosition, 'textX')
	self:CreateTextPositionSlider(panel, L.VerticalPosition, 'textY')

	return menu
end


--[[ Layout Panel ]]--

function XP:CreateVerticalButton(panel)
	local button = panel:CreateCheckButton(L.Vertical)
	button:SetScript('OnShow', function()
		button:SetChecked(self.sets.vertical)
	end)

	button:SetScript('OnClick',  function()
		local checked = button:GetChecked()
		self.sets.vertical = checked and 1 or nil
		self.xp:UpdateOrientation()
		
		local width, height = getglobal(panel:GetName() .. 'Width'), getglobal(panel:GetName() .. 'Height')
		width:Hide() width:Show() --still needs a better solution
		height:Hide() height:Show()
	end)

	return button
end

function XP:CreateAlwaysXPButton(panel)
	local button = panel:CreateCheckButton(L.AlwaysShowXP)
	button:SetScript('OnShow', function()
		button:SetChecked(self.sets.alwaysShowXP)
	end)

	button:SetScript('OnClick', function()
		self.xp:OnClick() --still needs a better solution
		button:Hide() button:Show()
	end)

	return button
end

function XP:CreateHeightSlider(panel)
	local function OnShow(slider)
		slider:SetValue(self.sets.height)
		getglobal(slider:GetName() ..'Text'):SetText(self.sets.vertical and L.Width or L.Height)
	end

	local function UpdateValue(slider, value)
		self.sets.height = value
		self.xp:UpdateSize()
	end

	return panel:CreateSlider('Height', 1, 128, 1, OnShow, UpdateValue)
end

function XP:CreateWidthSlider(panel)
	local function OnShow(slider)
		slider:SetValue(self.sets.width * 100)
		getglobal(slider:GetName() .. 'Text'):SetText(self.sets.vertical and L.Height or L.Width)
	end

	local function UpdateValue(slider, value)
		self.sets.width = value/100
		self.xp:UpdateSize()
	end

	return panel:CreateSlider('Width', 1, 100, 1, OnShow, UpdateValue)
end


--[[ Text Panel ]]--

function XP:CreateTextPositionSlider(panel, name, arg)
	local function OnShow(slider, value)
		slider:SetValue(self.sets[arg] * 100)
		self.xp:UpdateTextPosition()
	end

	local function UpdateValue(slider, value)
		self.sets[arg] = value/100
		self.xp:UpdateTextPosition()
	end

	return panel:CreateSlider(name, -50, 50, 1, OnShow, UpdateValue)
end


function XP:CreateAlwaysShowTextButton(panel)
	local button = panel:CreateCheckButton(L.AlwaysShow)
	button:SetScript('OnShow', function()
		button:SetChecked(self.sets.alwaysShowText)
	end)

	button:SetScript('OnClick', function()
		self.xp:ToggleText(button:GetChecked())
	end)

	return button
end