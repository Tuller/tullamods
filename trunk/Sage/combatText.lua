--[[
		Combat Indicator Functions
			The combat indicator is a text popup on the unitframe when the unit takes damage/is healed
--]]

--create a combat indicator
local function CreateCombatFrame(parent, fontHeight)
	local frame = CreateFrame('Frame', nil, parent)
	frame:SetAllPoints(parent)
	frame:SetFrameLevel(parent:GetFrameLevel() + 2)

	frame.feedbackText = frame:CreateFontString(nil, "OVERLAY")
	frame.feedbackText:SetPoint("CENTER", parent.health, "CENTER", 0, 0)
	frame.feedbackText:Hide()
	frame.feedbackFontHeight = fontHeight
	frame.unit = parent.id
	
	parent.combatText = frame

	return frame
end

local function OnCombatEvent(event, flags, amount, type)
	local feedbackText = this.feedbackText
	local fontHeight = this.feedbackFontHeight
	local text = ""
	local r = 1.0
	local g = 1.0
	local b = 1.0

	if event == "IMMUNE" then
		fontHeight = fontHeight * 0.5
		text = CombatFeedbackText[event]
	elseif event == "WOUND" then
		if amount ~= 0 then
			if flags == "CRITICAL" or flags == "CRUSHING" then
				fontHeight = fontHeight * 1.5
			elseif flags == "GLANCING" then
				fontHeight = fontHeight * 0.75
			end
			if type > 0 then
				r = 1.0
				g = 1.0
				b = 0.0
			end
			text = amount
		elseif flags == "ABSORB" then
			fontHeight = fontHeight * 0.75
			text = CombatFeedbackText["ABSORB"]
		elseif flags == "BLOCK" then
			fontHeight = fontHeight * 0.75
			text = CombatFeedbackText["BLOCK"]
		elseif flags == "RESIST" then
			fontHeight = fontHeight * 0.75
			text = CombatFeedbackText["RESIST"]
		else
			text = CombatFeedbackText["MISS"]
		end
	elseif event == "BLOCK" then
		fontHeight = fontHeight * 0.75
		text = CombatFeedbackText[event]
	elseif event == "HEAL" then
		text = amount
		r = 0.0
		g = 1.0
		b = 0.0
		if flags == "CRITICAL" then
			fontHeight = fontHeight * 1.5
		end
	elseif event == "ENERGIZE" then
		text = amount
		r = 0.41
		g = 0.8
		b = 0.94
		if flags == "CRITICAL" then
			fontHeight = fontHeight * 1.5
		end
	else
		text = CombatFeedbackText[event]
	end

	this.feedbackStartTime = GetTime()

	feedbackText:SetFont(NumberFontNormal:GetFont(), fontHeight, "OUTLINE")
	feedbackText:SetText(text)
	feedbackText:SetTextColor(r, g, b)
	feedbackText:SetAlpha(0)
	feedbackText:Show()
end

local function OnEvent()
	if arg1 == this.unit and this:IsVisible() then
		OnCombatEvent(arg2, arg3, arg4, arg5)
	end
end

--[[ Usable Functions ]]--

SageCombatText = {}

function SageCombatText.Register(parent)
	local combatText = parent.combatText or CreateCombatFrame(parent, parent.sets.combatTextSize)

	if not combatText:GetScript("OnEvent") then
		combatText:RegisterEvent("UNIT_COMBAT")
		combatText:SetScript("OnEvent", OnEvent)
		combatText:SetScript("OnUpdate", CombatFeedback_OnUpdate)
		combatText:Show()
	end
end

function SageCombatText.Unregister(parent)
	local combatText = parent.combatText

	if combatText then
		combatText:UnregisterEvent("UNIT_COMBAT")
		combatText:SetScript("OnEvent", nil)
		combatText:SetScript("OnUpdate", nil)
		combatText:Hide()
	end
end