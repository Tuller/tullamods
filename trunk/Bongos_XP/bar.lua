--[[
	Bongos_XP\xpBar.lua
		Scripts for the Bongos XP bar
--]]

local DEFAULT_HEIGHT = 14
local DEFAULT_SIZE = 0.75
local REP_FORMAT = '%d / %d'
local XP_FORMAT = '%d tnl'

local xpBar, restBar, text, bg
local WatchRep, WatchXP


--[[ OnX Functions ]]--

local function OnRepEvent()
	if restBar:IsShown() then
		local name, reaction, min, max, value = GetWatchedFactionInfo()
		if name then
			max = max - min
			value = value - min

			local color = FACTION_BAR_COLORS[reaction]
			bg:SetVertexColor(color.r * 0.25, color.g * 0.25, color.b * 0.25, 0.5)
			xpBar:SetStatusBarColor(color.r, color.g, color.b)
			xpBar:SetMinMaxValues(0, max)
			xpBar:SetValue(value)

			text:SetText(format(REP_FORMAT, value, max))
		else
			WatchXP()
		end
	end
end

function WatchRep()
	restBar:SetValue(0)
	restBar:UnregisterAllEvents()
	restBar:SetScript("OnEvent", OnRepEvent)
	restBar:RegisterEvent("UPDATE_FACTION")
	restBar:SetStatusBarColor(0, 0, 0, 0)

	OnRepEvent()
end

local function OnXPEvent()
	if restBar:IsShown() then
		if GetWatchedFactionInfo() then
			WatchRep()
		else
			local value = UnitXP("player")
			local max = UnitXPMax("player")

			xpBar:SetMinMaxValues(0, max)
			xpBar:SetValue(value)

			restBar:SetMinMaxValues(0, max)
			if GetXPExhaustion() then
				restBar:SetValue(value + GetXPExhaustion())
			else
				restBar:SetValue(0)
			end
			text:SetText(format(XP_FORMAT, max - value))
		end
	end
end

function WatchXP()
	restBar:UnregisterAllEvents()
	restBar:SetScript("OnEvent", OnXPEvent)
	restBar:RegisterEvent("UPDATE_FACTION")
	restBar:RegisterEvent("PLAYER_LOGIN")
	restBar:RegisterEvent("PLAYER_LEVEL_UP")
	restBar:RegisterEvent("PLAYER_XP_UPDATE")
	restBar:RegisterEvent("UPDATE_EXHAUSTION")

	restBar:SetStatusBarColor(0.25, 0.25, 1)
	xpBar:SetStatusBarColor(0.6, 0, 0.6)
	bg:SetVertexColor(0.3, 0, 0.3, 0.6)

	OnXPEvent()
end

--[[ Configuration ]]--

local function SetSize(self, percent)
	if self.sets.vertical then
		self:SetHeight(GetScreenHeight() * (percent or DEFAULT_SIZE))
	else
		self:SetWidth(GetScreenWidth() * (percent or DEFAULT_SIZE))
	end
	self.sets.size = percent
end

--yes, a weird name
local function SetHeight(self, value)
	if self.sets.vertical then
		self:SetWidth(value or DEFAULT_HEIGHT)
	else
		self:SetHeight(value or DEFAULT_HEIGHT)
	end
	self.sets.height = value
end

--set how tall/wide the xp bar should be
local function SetVertical(self, vertical)
	if vertical then
		xpBar:SetOrientation("VERTICAL")
		xpBar:SetStatusBarTexture(BONGOS_XP_VERTICAL_TEXTURE)

		restBar:SetOrientation("VERTICAL")
		restBar:SetStatusBarTexture(BONGOS_XP_VERTICAL_TEXTURE)
		bg:SetTexture(BONGOS_XP_VERTICAL_TEXTURE)
		self.sets.vertical = 1
	else
		xpBar:SetOrientation("HORIZONTAL")
		xpBar:SetStatusBarTexture(BONGOS_XP_HORIZONTAL_TEXTURE)

		restBar:SetOrientation("HORIZONTAL")
		restBar:SetStatusBarTexture(BONGOS_XP_HORIZONTAL_TEXTURE)
		bg:SetTexture(BONGOS_XP_HORIZONTAL_TEXTURE)
		self.sets.vertical = nil
	end

	SetSize(self, self.sets.size)
	SetHeight(self, self.sets.height)
end


--[[ Menu Functions ]]--

local function CreateConfigMenu(name, frame)
	local menu = CreateFrame("Button", name, UIParent, "BongosRightClickMenu")
	menu.frame = frame
	menu:SetText('XP Bar')
	menu:SetWidth(220)
	menu:SetHeight(240)

	--checkbuttons
	local vertical = CreateFrame("CheckButton", name .. 'Vertical', menu, "GooeyCheckButton")
	vertical:SetScript("OnClick", function() 
		SetVertical(frame, this:GetChecked())

		if this:GetChecked() then
			getglobal(name .. "SizeText"):SetText(BONGOS_XP_HEIGHT)
			getglobal(name .. "HeightText"):SetText(BONGOS_XP_WIDTH)
		else
			getglobal(name .. "SizeText"):SetText(BONGOS_XP_WIDTH)
			getglobal(name .. "HeightText"):SetText(BONGOS_XP_HEIGHT)
		end
	end)
	vertical:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -28)
	vertical:SetText(BONGOS_XP_VERTICAL)

	--sliders
	local opacity = CreateFrame("Slider", name .. "Opacity", menu, "BongosOpacitySlider")
	opacity:SetPoint("BOTTOM", menu, "BOTTOM", 0, 24)

	local scale = CreateFrame("Slider", name .. "Scale", menu, "BongosScaleSlider")
	scale:SetPoint("BOTTOM", opacity, "TOP", 0, 24)

	local height = CreateFrame("Slider", name .. "Height", menu, "BongosSlider")
	height:SetPoint("BOTTOM", scale, "TOP", 0, 24)
	height:SetScript("OnValueChanged", function()
		if not menu.onShow then
			SetHeight(frame, this:GetValue())
		end
		getglobal(this:GetName() .. "ValText"):SetText(this:GetValue())
	end)
	height:SetValueStep(1)
	height:SetMinMaxValues(0, 128)
	getglobal(name .. "HeightLow"):SetText(0)
	getglobal(name .. "HeightHigh"):SetText(128)

	local size = CreateFrame("Slider", name .. "Size", menu, "BongosSlider")
	size:SetPoint("BOTTOM", height, "TOP", 0, 24)
	size:SetScript("OnValueChanged", function()
		if not menu.onShow then
			SetSize(frame, this:GetValue() / 100)
		end
		getglobal(this:GetName() .. "ValText"):SetText(this:GetValue())
	end)
	size:SetValueStep(1)
	size:SetMinMaxValues(0, 100)
	getglobal(name .. "SizeLow"):SetText("0%")
	getglobal(name .. "SizeHigh"):SetText("100%")
	
	return menu
end

--Called when the right click menu is shown, loads the correct values to the checkbuttons/sliders/text
local function ShowMenu(self)
	local name = 'BongosXPBarMenu'
	local menu = getglobal(name) or CreateConfigMenu(name, self)

	menu.onShow = 1

	getglobal(name .. 'Vertical'):SetChecked(self.sets.vertical)
	if self.sets.vertical then
		getglobal(name .. 'SizeText'):SetText(BONGOS_XP_HEIGHT)
		getglobal(name .. 'HeightText'):SetText(BONGOS_XP_WIDTH)
	else
		getglobal(name .. 'SizeText'):SetText(BONGOS_XP_WIDTH)
		getglobal(name .. 'HeightText'):SetText(BONGOS_XP_HEIGHT)
	end	
	
	getglobal(name .. 'Size'):SetValue((self.sets.size or DEFAULT_SIZE) * 100)
	getglobal(name .. 'Height'):SetValue(self.sets.height or DEFAULT_HEIGHT)
	
	self:DisplayMenu(menu)
	menu.onShow = nil
end


--[[ Startup Functions ]]--

local function OnCreate(self)
	self.ShowMenu = ShowMenu
	self:SetFrameStrata('BACKGROUND')
	self:SetFrameLevel(0)

	restBar = CreateFrame('StatusBar', nil, self)
	restBar:SetAllPoints(self)
	restBar:SetAlpha(self:GetAlpha())
	restBar:SetClampedToScreen(true)

	bg = restBar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(restBar)

	xpBar = CreateFrame('StatusBar', nil, restBar)
	xpBar:EnableMouse(true)
	xpBar:SetClampedToScreen(true)
	xpBar:SetAllPoints(restBar)
	xpBar:SetAlpha(restBar:GetAlpha())
	xpBar:SetScript('OnEnter', function() text:Show() end)
	xpBar:SetScript('OnLeave', function() text:Hide() end)

	text = xpBar:CreateFontString(nil, "OVERLAY")
	text:SetFontObject(GameFontHighlight)
	text:SetNonSpaceWrap(false)
	text:SetAllPoints(xpBar)
	text:SetJustifyH('CENTER')
	text:SetJustifyV('CENTER')
	text:Hide()
end

Bongos.AddStartup(function()
	local bar = BBar.Create('xp', OnCreate)
	if not bar:IsUserPlaced() then
		bar:SetPoint("TOP", UIParent, "TOP", 0, -32)
	end
	SetVertical(bar, bar.sets.vertical)

	if GetWatchedFactionInfo() then WatchRep() else WatchXP() end
end)