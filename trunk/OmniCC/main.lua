--[[
	OmniCC
		A universal cooldown count, based on an idea by Gello
--]]

local ICON_SCALE = 37

local function msg(message, showAddon)
	if showAddon then
		ChatFrame1:AddMessage(format("|cFF33FF99OmniCC|r: %s", tostring(message)))
	else
		ChatFrame1:AddMessage(tostring(message))
	end
end

local active = {}
local activePulses = {}

OmniCC = CreateFrame("Frame")
OmniCC:Hide()

OmniCC:SetScript("OnEvent", function()
	if arg1 == "OmniCC" then
		this:UnregisterEvent(event)
		this:Init()
	end
end)
OmniCC:RegisterEvent("ADDON_LOADED")

OmniCC:SetScript("OnUpdate", function()
	if next(activePulses) then
		for pulse in pairs(activePulses) do
			this:UpdatePulse(pulse)
		end
	else
		this:Hide()
	end
end)


--[[ Settings Loading ]]--

function OmniCC:Init()
	self:LoadSettings()
	self:LoadFont()
end

function OmniCC:LoadSettings()
	local current = GetAddOnMetadata("OmniCC", "Version")

	if not(OmniCC2DB and OmniCC2DB.version) then
		self:LoadDefaults(current)
		msg("Initialized", true)
	else
		local cMajor, cMinor = current:match('(%d+)%.(%d+)')
		local major, minor = OmniCC2DB.version:match('(%d+)%.(%d+)')

		if major ~= cMajor then
			self:LoadDefaults(current)
			msg("Upgrading from an incompatible version. Default settings loaded", true)
		elseif minor ~= cMinor then
			self:UpdateSettings(current)
		end
	end
	self.sets = OmniCC2DB
end

function OmniCC:LoadDefaults(current)
	OmniCC2DB = {
		version = current,								--minimum duration to show text
		vlong = {r = 0.8, g = 0.8, b = 0.9, s = 0.6}, 	--settings for cooldowns greater than an hour
		long = {r = 0.8, g = 0.8, b = 0.9, s = 0.8}, 	--settings for cooldowns greater than one minute
		med = {r = 1, g = 1, b = 0.4, s = 1}, 			--settings for cooldowns under a minute
		short = {r = 1, g = 0, b = 0, s = 1.3}, 		--settings for cooldowns less than five seconds
		pulse = 1,
	}
end

function OmniCC:UpdateSettings(current)
	OmniCC2DB.version = current
	msg(format("Updated to v%s", OmniCC2DB.version), true)
end


--[[ Config Functions ]]--

function OmniCC:UpdateActiveTimers()
	for timer in pairs(active) do
		self:UpdateTimer(timer)
	end
end

function OmniCC:Reset()
	self:LoadDefaults(GetAddOnMetadata("OmniCC", "Version"))
	self:UpdateActiveTimers()
end


--font
function OmniCC:LoadFont()
	if not self.font then
		self.font = CreateFont("OmniCCFont")
	end

	local font, size = self:GetFont()

	if not self.font:SetFont(font, size) then
		self.sets.font = nil
		if not self.font:SetFont(STANDARD_TEXT_FONT, size) then
			self.font:SetFont("Fonts\\FRIZQT__.TTF", size)
		end
	end
end

function OmniCC:SetFont(font)
	self.sets.font = font
	self:LoadFont()
	self:UpdateActiveTimers()
end

function OmniCC:SetFontSize(size)
	self.sets.fontSize = size
	self:UpdateActiveTimers()
end

function OmniCC:SetFontFormat(index, r, g, b, s)
	local sets = self.sets[index]
	if sets then
		sets.r = r or sets.r
		sets.g = g or sets.g
		sets.b = b or sets.b
		sets.s = s or sets.s
	end
	self:UpdateActiveTimers()
end

function OmniCC:GetFont()
	return self.sets.font or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", self.sets.fontSize or 20
end


--model
function OmniCC:ToggleModel()
	if self.sets.hideModel then
		self.sets.hideModel = nil
	else
		self.sets.hideModel = 1
	end
end

function OmniCC:ShowingModel()
	return not self.sets.hideModel
end


--time format
function OmniCC:ToggleMMSS()
	if self.sets.mmSS then
		self.sets.mmSS = nil
	else
		self.sets.mmSS = 1
	end
	self:UpdateActiveTimers()
end

function OmniCC:InMMSSFormat()
	return self.sets.mmSS
end


--minimum duration
function OmniCC:SetMinimumDuration(duration)
	self.sets.minDur = duration
end

function OmniCC:GetMinimumDuration()
	return self.sets.minDur or 3
end


--pulse
function OmniCC:TogglePulse()
	if self.sets.pulse then
		self.sets.pulse = nil
	else
		self.sets.pulse = 1
	end
end

function OmniCC:ShowingPulse()
	return self.sets.pulse
end


--[[ Cooldown Timer Code ]]--

local function GetFormattedTime(s)
	local mmSSFormat = OmniCC:InMMSSFormat()

	if s >= 86400 then
		return format('%dd', floor(s/86400 + 0.5)), mod(s, 86400)
	elseif s >= 3600 then
		return format('%dh', floor(s/3600 + 0.5)), mod(s, 3600)
	elseif s >= 180 or (not mmSSFormat and s >= 60.5) then
		return format('%dm', floor(s/60 + 0.5)), mod(s, 60)
	elseif mmSSFormat and s >= 60.5 then
		return format('%d:%02d', floor(s/60), mod(s, 60)), s - floor(s)
	end
	return floor(s + 0.5), s - floor(s)
end

local function GetFormattedFont(s)
	local index
	if s >= 3600 then
		index = 'vlong'
	elseif s >= 60.5 then
		index = 'long'
	elseif s >= 5.5 then
		index = 'med'
	end
	local sets = OmniCC.sets[index or 'short']
	local font, size = OmniCC:GetFont()

	return font, size * (sets.s or 1), (sets.r or 1), (sets.g or 1), (sets.b or 1)
end

local function Timer_OnUpdate()
	if this.toNextUpdate <= 0 or not this.icon:IsVisible() then
		local remain = this.duration - (GetTime() - this.start)

		if floor(remain + 0.5) > 0 and this.icon:IsVisible() then
			local time, toNextUpdate = GetFormattedTime(remain)
			local font, size, r, g, b = GetFormattedFont(remain)
			local scale = this:GetWidth() / ICON_SCALE
			
			this.text:SetFont(font, size * scale, "OUTLINE")
			this.text:SetText(time)

			this.text:SetTextColor(r, g, b)
			this.toNextUpdate = toNextUpdate
		else
			OmniCC:StopTimer(this)
			if OmniCC:ShowingPulse() then
				OmniCC:StartPulse(this)
			end
		end
	else
		this.toNextUpdate = this.toNextUpdate - arg1
	end
end

local function Timer_Create(parent, cooldown, icon)
	local timer = CreateFrame("Frame", nil, parent)
	timer:SetFrameLevel(parent:GetFrameLevel() + 3)
	timer:SetToplevel(true)
	timer:Hide()

	timer:SetAllPoints(parent)
	timer:SetAlpha(parent:GetAlpha())
	timer:SetScript("OnUpdate", Timer_OnUpdate)

	timer.icon = icon
	timer.text = timer:CreateFontString(nil, "OVERLAY")
	timer.text:SetPoint("CENTER", timer, "CENTER", 0, 1)

	parent.timer = timer

	return timer
end

function OmniCC:StartTimer(cooldown, start, duration)
	local parent = cooldown:GetParent()
	if parent then
		if parent.object and parent.object.icon then
			msg(parent.icon:GetTexture())
		end

		local icon =
			--standard action button icon, $parentIcon
			getglobal(parent:GetName() .. "Icon") or
			--standard item button icon,  $parentIconTexture
			getglobal(parent:GetName() .. "IconTexture")

		if icon then
			local timer = parent.timer or Timer_Create(parent, cooldown, icon)

			timer.start = start
			timer.duration = duration
			timer.toNextUpdate = 0
			active[timer] = true
			timer:Show()
		end
	end
end

function OmniCC:StopTimer(timer)
	if timer then
		active[timer] = nil
		timer:Hide()
	end
end

function OmniCC:UpdateTimer(timer)
	timer.toNextUpdate = 0
end

hooksecurefunc("CooldownFrame_SetTimer", function(frame, start, duration, enable)
	if not OmniCC:ShowingModel() then
		frame:Hide()
	end

	if start > 0 and duration > OmniCC:GetMinimumDuration() and enable == 1 then
		OmniCC:StartTimer(frame, start, duration)
	else
		local timer = frame:GetParent().timer
		if timer then
			OmniCC:StopTimer(timer)
		end
	end
end)


--[[  Pulse Code ]]--

local function Pulse_Create(parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetToplevel(true)
	frame:SetAlpha(parent:GetAlpha())
	frame:SetAllPoints(parent)

	local icon = frame:CreateTexture(nil, "OVERLAY")
	icon:SetPoint("CENTER", frame, "CENTER")
	icon:SetBlendMode("ADD")
	icon:SetHeight(frame:GetHeight())
	icon:SetWidth(frame:GetWidth())
	frame.icon = icon

	parent.pulse = frame

	return frame
end

function OmniCC:StartPulse(cooldown)
	local parent = cooldown:GetParent()

	if parent and parent:IsVisible() then
		local pulse = parent.pulse or Pulse_Create(parent)
		pulse.scale = 1
		pulse.icon:SetTexture(cooldown.icon:GetTexture())
		pulse:Show()
		activePulses[pulse] = true
		
		self:Show()
	end
end

function OmniCC:UpdatePulse(pulse)
	if pulse.scale >= 2 then
		pulse.dec = 1
	end

	if pulse.dec then
		pulse.scale = pulse.scale - pulse.scale * 0.09
	else
		pulse.scale = pulse.scale + pulse.scale * 0.09
	end

	if pulse.scale <= 1 then
		activePulses[pulse] = nil

		pulse:Hide()
		pulse.dec = nil
	else
		pulse.icon:SetHeight(pulse:GetHeight() * pulse.scale)
		pulse.icon:SetWidth(pulse:GetWidth() * pulse.scale)
	end
end


--[[ Slash Commands ]]--

local function PrintCommands()
	msg("Commands (/omnicc)", true)
	msg("- size <size>: Set font size. 20 is default");
	msg("- font <font>: Set the font to use. " .. STANDARD_TEXT_FONT .. " is default")
	msg("- color <dur> <r> <g> <b>: Set the color to use for cooldowns of <dur>. <dur> can be vlong, long, med or short")
	msg("- scale <dur> <scale>: Set the scale to use for cooldowns of <dur>. <dur> can be vlong, long, med or short")
	msg("- min <time>: Set the minimum duration (secs) a cooldown should be to show text. Default value of 3")
	msg("- model: Toggles the cooldown model")
	msg("- pulse: Toggles a pulse when cooldowns are finished")
	msg("- mmss: Toggles MM:SS format")
	msg("- reset: Returns to default settings")
end

SlashCmdList["OmniCCCOMMAND"] = function(message)
	if not message or message == "" or message:lower() == "help" or message == "?" then
		PrintCommands();
	else
		local args = {strsplit(' ', message:lower())}
		local cmd = args[1]

		if cmd == "font" then
			OmniCC:SetFont(args[2])
			msg(format("Set font to %s", (OmniCC:GetFont())), true)
		elseif cmd == "size" then
			OmniCC:SetFontSize(tonumber(args[2]))
			msg(format("Set font size to %s", select(2, OmniCC:GetFont())), true)
		elseif cmd == "min" then
			OmniCC:SetMinimumDuration(tonumber(args[2]))
			msg(format("Set minimum duration to %s", OmniCC:GetMinimumDuration(), true))
		elseif cmd == "model" then
			OmniCC:ToggleModel()
			if OmniCC:ShowingModel() then
				msg("Cooldown models enabled", true)
			else
				msg("Cooldown models disabled", true)
			end
		elseif cmd == "pulse" then
			OmniCC:TogglePulse()
			if OmniCC:ShowingPulse() then
				msg("Pulse enabled", true)
			else
				msg("Pulse disabled", true)
			end
		elseif cmd == "mmss" then
			OmniCC:ToggleMMSS()
			if OmniCC:InMMSSFormat() then
				msg("MM:SS format enabled", true)
			else
				msg("MM:SS format disabled", true)
			end
		elseif cmd == "color" then
			OmniCC:SetFontFormat(args[2], tonumber(args[3]), tonumber(args[4]), tonumber(args[5]))
		elseif cmd == "scale" then
			OmniCC:SetFontFormat(args[2], nil, nil, nil, tonumber(args[3]))
		elseif cmd == "reset" then
			OmniCC:Reset()
			msg("Loaded default settings", true)
		else
			msg(format("'%s' is an invalid command", cmd), true)
		end
	end
end
SLASH_OmniCCCOMMAND1 = "/omnicc"