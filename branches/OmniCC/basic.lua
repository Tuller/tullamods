--[[
	basic.lua
		A featureless version of OmniCC,

	To use it, change the file listings in OmniCC.toc to only the name of this file.
	You can also remove the saved variables line.
--]]

local ICON_SCALE = 37
local FONT_SIZE = 18
local TEXT_FONT = STANDARD_TEXT_FONT

local function GetFormattedTime(s)
	if s >= 86400 then
		return floor(s / 86400 + 0.5) .. "d", mod(s, 86400)
	elseif s >= 3600 then
		return floor(s / 3600 + 0.5) .. "h", mod(s, 3600)
	elseif s >= 60 then
		return floor(s / 60 + 0.5) .. "m", mod(s, 60)
	end
	return floor(s + 0.5), s - floor(s)
end

local function Timer_OnUpdate(self, elapsed)
	if self.text:IsShown() then
		if self.nextUpdate <= 0 then
			local remain = self.duration - (GetTime() - self.start)
			if floor(remain + 0.5) > 0 then
				local time, toNextUpdate = GetFormattedTime(remain)
				self.text:SetText(time)
				self.toNextUpdate = toNextUpdate
			else
				self.text:Hide()
			end
		else
			self.nextUpdate = self.nextUpdate - elapsed
		end
	end
end

local function Timer_Create(self)
	local scale = min(self:GetParent():GetWidth() / ICON_SCALE, 1)

	local text
	if (FONT_SIZE * scale) > 8 then
		text = self:CreateFontString(nil, "OVERLAY")
		text:SetPoint("CENTER", self, "CENTER", 0, 1)
		text:SetFont(TEXT_FONT, FONT_SIZE * scale, "OUTLINE")
		text:SetTextColor(1, 0.9, 0)

		self.text = text
		self:SetScript("OnUpdate", Timer_OnUpdate)
	end
	return text
end

local function Timer_Start(self, start, duration)
	self.start = start
	self.duration = duration
	self.nextUpdate = 0

	local text = self.text or Timer_Create(self)
	if text then
		text:Show()
	end
end

hooksecurefunc("CooldownFrame_SetTimer", function(self, start, duration, enable)
	if start > 0 and duration > 3 and enable == 1 then
		Timer_Start(self, start, duration)
	else
		local text = self.text
		if text then
			text:Hide()
		end
	end
end)