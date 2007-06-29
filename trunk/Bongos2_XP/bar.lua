--[[
	Bongos_XP\xpBar.lua
		Scripts for the Bongos XP bar
--]]

BongosXP = Bongos:NewModule("Bongos-XP")

local DEFAULT_HEIGHT = 14
local DEFAULT_SIZE = 0.75
local REP_FORMAT = "%s:  %s / %s"
local REST_FORMAT = "%s / %s (+%s)"
local XP_FORMAT = "%s / %s"

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

			text:SetText(format(REP_FORMAT, name, value, max))
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
			local rest = GetXPExhaustion()
			if rest then
				restBar:SetValue(value + rest)
				if(rest > 10000) then
					text:SetText(format(REST_FORMAT, value, max, format("%.1fk", rest / 1000)))
				else
					text:SetText(format(REST_FORMAT, value, max, rest))
				end
			else
				restBar:SetValue(0)
				text:SetText(format(XP_FORMAT, value, max))
			end
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

local function Bar_SetSize(self, percent)
	if self.sets.vertical then
		self:SetHeight(GetScreenHeight() * (percent or DEFAULT_SIZE))
	else
		self:SetWidth(GetScreenWidth() * (percent or DEFAULT_SIZE))
	end
	self.sets.size = percent
end

--yes, a weird name
local function Bar_SetHeight(self, value)
	if self.sets.vertical then
		self:SetWidth(value or DEFAULT_HEIGHT)
	else
		self:SetHeight(value or DEFAULT_HEIGHT)
	end
	self.sets.height = value
end

--set how tall/wide the xp bar should be
local function Bar_SetVertical(self, vertical)
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

	Bar_SetSize(self, self.sets.size)
	Bar_SetHeight(self, self.sets.height)
end


--[[ Menu Functions ]]--

local function Bar_CreateMenu(frame)
	local menu, panel = BongosMenu:CreateMenu(frame.id)

	--checkbuttons
	local vertical = panel:AddCheckButton("Vertical")
	vertical:SetScript("OnShow", function(self) self:SetChecked(frame.sets.vertical) end)
	vertical:SetScript("OnClick",  function(self)
		Bar_SetVertical(frame, self:GetChecked())

		if self:GetChecked() then
			getglobal(name .. "SizeText"):SetText("Height")
			getglobal(name .. "HeightText"):SetText("Width")
		else
			getglobal(name .. "SizeText"):SetText("Width")
			getglobal(name .. "HeightText"):SetText("Height")
		end
	end)

	--height slider
	local height = panel:AddSlider("Height", 0, 128, 1)
	height:SetScript("OnShow", function(self)
		self.onShow = true
		if(frame.sets.vertical) then
			getglobal(self:GetName() .. "Text"):SetText("Width")
		else
			getglobal(self:GetName() .. "Text"):SetText("Height")
		end
		self:SetValue(frame.sets.height or DEFAULT_HEIGHT)
		self.onShow = nil
	end)
	height:SetScript("OnValueChanged", function(self, value)
		if not self.onShow then
			Bar_SetHeight(frame, value)
		end
		getglobal(self:GetName() .. "ValText"):SetText(value)
	end)

	--size slider
	local size = panel:AddSlider("Size", 0, 100, 1)
	size:SetScript("OnShow", function(self)
		self.onShow = true
		if(frame.sets.vertical) then
			getglobal(self:GetName() .. "Text"):SetText("Height")
		else
			getglobal(self:GetName() .. "Text"):SetText("Width")
		end
		self:SetValue((frame.sets.size or DEFAULT_SIZE) * 100)
		self.onShow = nil
	end)
	size:SetScript("OnValueChanged", function(self, value)
		if not self.onShow then
			Bar_SetSize(frame, value/100)
		end
		getglobal(this:GetName() .. "ValText"):SetText(value)
	end)

	return menu
end


--[[ Startup Functions ]]--

local function Bar_OnCreate(self)
	self.CreateMenu = Bar_CreateMenu

	restBar = CreateFrame("StatusBar", nil, self)
	restBar:SetAllPoints(self)
	restBar:SetClampedToScreen(true)

	bg = restBar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(restBar)

	xpBar = CreateFrame("StatusBar", nil, restBar)
	xpBar:EnableMouse(true)
	xpBar:SetClampedToScreen(true)
	xpBar:SetAllPoints(restBar)
	xpBar:SetScript("OnEnter", function() text:Show() end)
	xpBar:SetScript("OnLeave", function() text:Hide() end)

	text = xpBar:CreateFontString(nil, "OVERLAY")
	text:SetFontObject(GameFontHighlight)
	text:SetNonSpaceWrap(false)
	text:SetAllPoints(xpBar)
	text:SetJustifyH("CENTER")
	text:SetJustifyV("CENTER")
	text:Hide()
end

function BongosXP:Load()
	local bar = BBar:Create("xp", Bar_OnCreate, nil, nil, "BACKGROUND")
	if not bar:IsUserPlaced() then
		bar:SetPoint("TOP", UIParent, "TOP", 0, -32)
	end

	Bar_SetVertical(bar, bar.sets.vertical)

	if GetWatchedFactionInfo() then
		WatchRep()
	else
		WatchXP()
	end

	self.bar = bar
end

function BongosXP:Unload()
	self.bar:Destroy()
end