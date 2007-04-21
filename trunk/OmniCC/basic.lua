--[[
	basic.lua
		A featureless version of OmniCC,

	To use it, change the file listings in OmniCC.toc to only the name of this file.
	You can also remove the saved variables line.
--]]

local ICON_SCALE = 37

local function GetFormattedTime(secs)
	if secs >= 86400 then
		return floor(secs / 86400 + 0.5) .. "d", mod(secs, 86400)
	elseif secs >= 3600 then
		return floor(secs / 3600 + 0.5) .. "h", mod(secs, 3600)
	elseif secs >= 60 then
		return floor(secs / 60 + 0.5) .. "m", mod(secs, 60)
	end
	return floor(secs + 0.5), secs - floor(secs)
end

local function Timer_OnUpdate()
	if this.toNextUpdate <= 0 or not this.icon:IsVisible() then
		local remain = this.duration - (GetTime() - this.start)

		if floor(remain + 0.5) > 0 and this.icon:IsVisible() then
			local time, toNextUpdate = GetFormattedTime(remain)
			this.text:SetText(time)
			this.toNextUpdate = toNextUpdate
		else
			this:Hide()
		end
	else
		this.toNextUpdate = this.toNextUpdate - arg1
	end
end

local function Timer_Create(parent, cooldown, icon)
	local timer = CreateFrame("Frame", nil, parent)
	timer:SetToplevel(true)
	timer:SetAllPoints(parent)
	timer:SetAlpha(parent:GetAlpha())
	timer:Hide()
	timer:SetScript("OnUpdate", Timer_OnUpdate)

	timer.icon = icon
	
	local scale = timer:GetWidth() / ICON_SCALE
	timer.text = timer:CreateFontString(nil, "OVERLAY")
	timer.text:SetPoint("CENTER", timer, "CENTER", 0, 1)
	timer.text:SetFont(STANDARD_TEXT_FONT, 20 * scale, "OUTLINE")
	timer.text:SetTextColor(1, 1, 0.4)
	parent.timer = timer

	return timer
end

local function Timer_Start(cooldown, start, duration)
	local parent = cooldown:GetParent()
	if parent then
		local icon = parent.icon or
			getglobal(parent:GetName() .. "Icon") or
			getglobal(parent:GetName() .. "IconTexture")

		if icon then
			local timer = parent.timer or Timer_Create(parent, cooldown, icon)
			timer.start = start
			timer.duration = duration
			timer.toNextUpdate = 0
			timer:Show()
		end
	end
end

hooksecurefunc("CooldownFrame_SetTimer", function(frame, start, duration, enable)
	if start > 0 and duration > 3 and enable == 1 then
		Timer_Start(frame, start, duration)
	else
		local timer = frame:GetParent().timer
		if timer then
			timer:Hide()
		end
	end
end)