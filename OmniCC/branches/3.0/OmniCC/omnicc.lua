--[[
	OmniCC
		A featureless, 'pure' version of OmniCC.
		This version should work on absolutely everything, but I've removed pretty much all of the options
--]]

--[[ constants & local bindings ]]--

local ICON_SIZE = 36 --the normal size for an icon (don't change this)
local TEXT_FONT = STANDARD_TEXT_FONT --what font to use
local FONT_SIZE = 18 --the base font size to use at a scale of 1
local MIN_SCALE = 0.5 --the minimum scale we want to show cooldown counts at, anything below this will be hidden
local MIN_DURATION = 3 --the minimum duration to show cooldown text for
local DAY, HOUR, MINUTE = 86400, 3600, 60
local UPDATE_DELAY = 0.05 --minimum time between timer updates

--omg speed
local format = string.format
local floor = math.floor
local min = math.min

--[[
	Timer Code
--]]

local function formatTime(s)
	if s >= DAY then
		return format('%dd', floor(s/DAY + 0.5))
	elseif s >= HOUR then
		return format('%dh', floor(s/HOUR + 0.5))
	elseif s >= MINUTE then
		return format('%dm', floor(s/MINUTE + 0.5))
	end
	return floor(s + 0.5)
end

local Timer = CreateFrame('Frame'); Timer:Hide()
local timer_MT = {__index = Timer}

function Timer:New(parent)
	local t = setmetatable(CreateFrame('Frame', nil, parent), timer_MT)
	t:Hide()
	t:SetAllPoints(parent)
	t:SetScript('OnShow', t.OnShow)
	t:SetScript('OnHide', t.OnHide)

	local text = t:CreateFontString(nil, 'OVERLAY')
	text:SetPoint('CENTER', 0, 1)
	text:SetFont(TEXT_FONT, FONT_SIZE, 'OUTLINE')
	text:SetTextColor(1, 0.9, 0)
	t.text = text

	return t
end

function Timer:OnShow()
	if self:GetRemainingTime() > 0 then
		OmniCC:Add(self)
	else
		self:Stop()
	end
end

function Timer:OnHide()
	OmniCC:Remove(self)
end

function Timer:Start(cooldown, start, duration)
	local timer = cooldown.timer
	if not timer then
		timer = Timer:New(cooldown)
		cooldown.timer = timer
	end

	timer.start = start
	timer.duration = duration
	timer:Show()
end

function Timer:Update()
	if self:GetRemainingTime() > 0 then
		self:UpdateDisplay()
	else
		self:Stop()
	end
end

function Timer:Stop()
	self.start = 0
	self.duration = 0
	self:Hide()
end

function Timer:UpdateDisplay()
	self.text:SetText(formatTime(self:GetRemainingTime()))
end

function Timer:GetRemainingTime()
	return self.duration - (GetTime() - self.start)
end

--[[
	global updater
--]]

local OmniCC = CreateFrame('Frame', 'OmniCC', UIParent); OmniCC:Hide()
OmniCC.timers = {}
OmniCC.nextUpdate = 0

OmniCC:SetScript('OnHide', function(self, elapsed)
	self.nextUpdate = 0
end)

OmniCC:SetScript('OnUpdate', function(self, elapsed)
	if not next(self.timers) then
		self:Hide()
		return
	end

	if self.nextUpdate > 0 then
		self.nextUpdate = self.nextUpdate - elapsed
	else
		self.nextUpdate = UPDATE_DELAY
		for timer in pairs(self.timers) do
			timer:Update()
		end
	end
end)

function OmniCC:Add(timer)
	self.timers[timer] = true
	self:UpdateShown()
end

function OmniCC:Remove(timer)
	if next(self.timers) then
		self.timers[timer] = nil
		self:UpdateShown()
	end
end

function OmniCC:UpdateShown()
	if next(self.timers) then
		self:Show()
	else
		self:Hide()
	end
end

--[[
	the hook
--]]

--ActionButton1Cooldown here, is something we think will always exist
local methods = getmetatable(_G['ActionButton1Cooldown']).__index
hooksecurefunc(methods, 'SetCooldown', function(self, start, duration)
	if start > 0 and duration > MIN_DURATION then
		Timer:Start(self, start, duration)
	elseif self.timer then
		self.timer:Stop()
	end
end)