--[[
	OmniCC Basic
		A featureless, 'pure' version of OmniCC.
		This version should work on absolutely everything, but I've removed pretty much all of the options

	To use it, replace OmniCC.toc with OmniCC.basic.toc located in the tocs folder
	To stop using it, replace OmniCC.toc with OmniCC.full.toc located in the tocs folder
--]]

local ICON_SIZE = 37 --the normal size for an icon (don't change this)
local FONT_SIZE = 18 --the base font size to use at a scale of 1
local MIN_SCALE = 0.5 --the minimum scale we want to show cooldown counts at, anything below this will be hidden
local MIN_DURATION = 3 --the minimum duration to show cooldown text for
local TEXT_FONT = STANDARD_TEXT_FONT --what font to use
local DAY, HOUR, MINUTE = 86400, 3600, 60

--local bindings for omg speed
local format, floor = string.format, math.floor
local GetTime = GetTime

local function GetFormattedTime(s)
	if s >= DAY then
		return format('%dd', floor(s/DAY + 0.5)), s % DAY
	elseif s >= HOUR then
		return format('%dh', floor(s/HOUR + 0.5)), s % HOUR
	elseif s >= MINUTE then
		return format('%dm', floor(s/MINUTE + 0.5)), s % MINUTE
	end
	return floor(s + 0.5), s - floor(s)
end

local function Timer_OnUpdate(self, elapsed)
	if self.text:IsShown() then
		if self.nextUpdate <= 0 then
			if self:GetEffectiveScale()/UIParent:GetEffectiveScale() < MIN_SCALE then
				self.text:SetText('')
				self.toNextUpdate = 1
			else
				local remain = self.duration - (GetTime() - self.start)
				if floor(remain + 0.5) > 0 then
					local time, toNextUpdate = GetFormattedTime(remain)
					self.text:SetText(time)
					self.toNextUpdate = toNextUpdate
				else
					self.text:Hide()
				end
			end
		else
			self.nextUpdate = self.nextUpdate - elapsed
		end
	end
end

local function Timer_Create(self)
	local fontScale = min(self:GetParent():GetWidth() / ICON_SIZE, 1)

	if fontScale >= MIN_SCALE then
		local text = self:CreateFontString(nil, 'OVERLAY')
		text:SetPoint('CENTER', 0, 1)
		text:SetFont(TEXT_FONT, FONT_SIZE * fontScale, 'OUTLINE')
		text:SetTextColor(1, 0.9, 0)

		self.text = text
		self:SetScript('OnUpdate', Timer_OnUpdate)
		return text
	else
		self.noOCC = true
	end
end

local function Timer_Start(self, start, duration)
	self.start = start
	self.duration = duration
	self.nextUpdate = 0

	local text = self.text or (not self.noOCC and Timer_Create(self))
	if text then
		text:Show()
	end
end

local methods = getmetatable(CreateFrame('Cooldown')).__index
hooksecurefunc(methods, 'SetCooldown', function(self, start, duration)
	if start > 0 and duration > MIN_DURATION then
		Timer_Start(self, start, duration)
	else
		local text = self.text
		if text then
			text:Hide()
		end
	end
end)