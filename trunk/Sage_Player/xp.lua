--[[
	Sage Player XP
		SagePlayer's experience/reputation bar
--]]

local BAR_HEIGHT = 12

local function PrettyPrint(val)
	if val >= 10000 then
		if mod(val, 10000) == 0 then
			return val / 1000
		end
		return format("%.1fk", val / 1000)
	else
		return format("%d", val)
	end
end

local function XPBar_OnXPEvent(self)
	if self:IsShown() then
		if GetWatchedFactionInfo() then
			self:WatchReputation()
		else
			local value = UnitXP("player")
			local max = UnitXPMax("player")

			self:SetMinMaxValues(0, max)
			self.overlay:SetMinMaxValues(0, max)
			self.overlay:SetValue(value)

			local rest = GetXPExhaustion()
			if rest then
				self:SetValue(value + rest)
				self.text:SetText(format("%s tnl (+%s)", PrettyPrint(max - value), PrettyPrint(rest)))
  			else
  				self:SetValue(0)
				self.text:SetText(format("%s tnl", PrettyPrint(max - value)))
  			end
		end
	end
end

local function XPBar_OnRepEvent(self)
	if self:IsShown() then
		local name, reaction, min, max, value = GetWatchedFactionInfo()
		if name then
			max = max - min
			value = value - min

			local color = FACTION_BAR_COLORS[reaction]
			self:SetStatusBarColor(color.r, color.g, color.b)
			self:SetMinMaxValues(0, max)
			self:SetValue(value)

			self.text:SetText(format("%d / %d", value, max))
		else
			self:WatchExperience()
		end
	end
end

local function XPBar_WatchExperience(self)
	self:UnregisterAllEvents()
	self:SetScript("OnEvent", XPBar_OnXPEvent)
	self:RegisterEvent("UPDATE_FACTION")
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("PLAYER_XP_UPDATE")
	self:RegisterEvent("UPDATE_EXHAUSTION")

	self:SetStatusBarColor(0.25, 0.25, 1)
	self.overlay:SetStatusBarColor(0.6, 0, 0.6)
	self.bg:SetVertexColor(0.3, 0, 0.3, 0.6)

	XPBar_OnXPEvent(self)
end

local function XPBar_WatchReputation(self)
	self:UnregisterAllEvents()
	self:SetScript("OnEvent", XPBar_OnRepEvent)
	self:RegisterEvent("UPDATE_FACTION")

	self.overlay:SetValue(0)
	self.overlay:SetStatusBarColor(0, 0, 0, 0)
	self.bg:SetVertexColor(0, 0.3, 0, 0.6)

	XPBar_OnRepEvent(self)
end

local function XPBar_UpdateTexture(self)
	local texture = Sage:GetBarTexture()
	self:SetStatusBarTexture(texture)
	self.overlay:SetStatusBarTexture(texture)
	self.bg:SetTexture(texture)
end

local function XPBar_ShowText(self, show)
	if show then
		self.text:Show()
	else
		self.text:Hide()
	end
end

local function XPBar_Create(parent)
	local bar = CreateFrame("StatusBar", nil, parent)
	bar.WatchReputation = XPBar_WatchReputation
	bar.WatchExperience = XPBar_WatchExperience
	bar.UpdateTexture = XPBar_UpdateTexture
	bar.ShowText = XPBar_ShowText
	bar.id = parent.id

	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(bar)
	bar.bg = bg

	local overlay = CreateFrame("StatusBar", nil, bar)
	overlay:SetAllPoints(bar)
	bar.overlay = overlay

	local text = overlay:CreateFontString(nil, "OVERLAY")
	text:SetFontObject(SageFont:GetSmallBarFont())
	text:SetPoint("CENTER", bar)
	bar.text = text

	local druidBar = parent.druid
	if druidBar then
		bar:SetPoint("TOPLEFT", druidBar, "BOTTOMLEFT")
		bar:SetPoint("BOTTOMRIGHT", druidBar, "BOTTOMRIGHT", 0, -BAR_HEIGHT)
	else
		bar:SetPoint("TOPLEFT", parent.mana, "BOTTOMLEFT")
		bar:SetPoint("BOTTOMRIGHT", parent.mana, "BOTTOMRIGHT", 0, -BAR_HEIGHT)
	end

	parent.click:SetPoint("BOTTOMRIGHT", bar)
	parent:SetHeight(parent:GetHeight() + BAR_HEIGHT)

	bar:UpdateTexture()
	bar:ShowText(Sage:ShowingText())

	SageBar:Register(bar)

	return bar
end


--[[ Usable Functions ]]--

function SagePlayer:SetShowXP(enable)
	local frame = self.frame
	local bar = frame.xp
	frame.sets.showXP = (enable and true) or nil

	if enable then
		if bar then
			if not bar:IsShown() then
				frame:SetHeight(frame:GetHeight() + BAR_HEIGHT)
				bar:Show()
			end
		else
			frame.xp = XPBar_Create(frame)
		end

		if GetWatchedFactionInfo() then
			frame.xp:WatchReputation()
		else
			frame.xp:WatchExperience()
		end
	else
		if bar and bar:IsShown() then
			frame:SetHeight(frame:GetHeight() - BAR_HEIGHT)
			bar:Hide()
		end
	end
end

function SagePlayer:ShowingXP()
	return self.frame.sets.showXP
end