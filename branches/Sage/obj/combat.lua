--[[
		Combat Indicator Functions
			The combat indicator is a text popup on the unitframe when the unit takes damage/is healed
--]]

--create a combat indicator
local function CombatFrame_Create(parent, fontHeight)
	local frame = CreateFrame("Frame", nil, parent)
	frame.id = parent.id
	frame.feedbackFontHeight = fontHeight

	frame:SetAllPoints(parent)
	frame:SetFrameLevel(parent:GetFrameLevel() + 2)

	frame.feedbackText = frame:CreateFontString(nil, "OVERLAY")
	frame.feedbackText:SetPoint("CENTER", parent.health)
	frame.feedbackText:Hide()

	return frame
end

local function CombatFrame_OnCombatEvent(self, event, flags, amount, type)
	local feedbackText = self.feedbackText
	local fontHeight = self.feedbackFontHeight
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

	self.feedbackStartTime = GetTime()

	feedbackText:SetFont(NumberFontNormal:GetFont(), fontHeight, "OUTLINE")
	feedbackText:SetText(text)
	feedbackText:SetTextColor(r, g, b)
	feedbackText:SetAlpha(0)
	feedbackText:Show()
end

local function CombatFrame_OnEvent(self, event, unit, ...)
	if unit == self.id and self:IsVisible() then
		CombatFrame_OnCombatEvent(self, ...)
	end
end


--[[ Usable Functions ]]--

SageCombat = {}

function SageCombat:Register(parent)
	local frame = parent.combatFrame
	if(not frame) then
		frame = CombatFrame_Create(parent, parent.sets.combatTextSize)
		parent.combatFrame = frame
	end

	if not frame:GetScript("OnEvent") then
		frame:RegisterEvent("UNIT_COMBAT")
		frame:SetScript("OnEvent", CombatFrame_OnEvent)
		frame:SetScript("OnUpdate", CombatFeedback_OnUpdate)
		frame:Show()
	end
end

function SageCombat:Unregister(parent)
	local frame = parent.combatFrame
	if frame then
		frame:Hide()
		frame:UnregisterAllEvents()
		frame:SetScript("OnEvent", nil)
		frame:SetScript("OnUpdate", nil)
	end
end