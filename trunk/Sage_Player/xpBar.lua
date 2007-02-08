--[[
	SPlayerXP
		Scripts for the Sage Player Experience bar
--]]

local BAR_HEIGHT = 12
local xpBar, restBar, text, bg
local WatchRep, WatchXP

local function PrettyPrint(x)
	if x >= 10000 then
		if mod(x, 10000) == 0 then
			return x / 1000
		end
		return format("%.1fk", x / 1000);
	else
		return format("%d", x);
	end
end

local function OnRepEvent()
	if restBar:IsShown() then
		local name, reaction, min, max, value = GetWatchedFactionInfo()
		if name then
			max = max - min
			value = value - min

			local color = FACTION_BAR_COLORS[reaction]
			restBar:SetStatusBarColor(color.r, color.g, color.b)
			restBar:SetMinMaxValues(0, max)
			restBar:SetValue(value)

			text:SetText(format('%d / %d', value, max))
		else
			WatchXP()
		end
	end
end

function WatchRep()
	xpBar:SetValue(0)

	restBar:UnregisterAllEvents()
	restBar:SetScript("OnEvent", OnRepEvent)
	restBar:RegisterEvent("UPDATE_FACTION")

	bg:SetVertexColor(0, 0.3, 0, 0.6)
	xpBar:SetStatusBarColor(0, 0, 0, 0)

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
			
			local restXP = GetXPExhaustion()
			if restXP then
				restBar:SetValue(value + restXP)
				text:SetText(format('%s tnl (+%s)', PrettyPrint(max - value), PrettyPrint(restXP)));
  			else
  				restBar:SetValue(0)
				text:SetText(format('%s tnl', PrettyPrint(max - value)));
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

local function CreateXPBar(parent)
	restBar = CreateFrame('StatusBar', nil, parent)
	restBar:SetAlpha(parent:GetAlpha())

	bg = restBar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(restBar)

	xpBar = CreateFrame('StatusBar', nil, restBar)
	xpBar:SetAllPoints(restBar)
	xpBar:SetAlpha(restBar:GetAlpha())

	text = xpBar:CreateFontString(nil, "OVERLAY")
	text:SetFontObject(SageBarFontSmall)
	text:SetPoint('CENTER', xpBar)
	if not Sage.ShowingText() then 
		text:Hide() 
	end

	--Function hooks
	local parent_OnEnter = parent.click:GetScript("OnEnter")
	parent.click:SetScript("OnEnter", function()
		parent_OnEnter()
		text:Show()
	end)

	local parent_OnLeave = parent.click:GetScript("OnLeave")
	parent.click:SetScript("OnLeave", function()
		parent_OnLeave()
		if not Sage.ShowingText() then 
			text:Hide() 
		end
	end)

	local function SetTexture(texture)
		xpBar:SetStatusBarTexture(texture)
		restBar:SetStatusBarTexture(texture)
		bg:SetTexture(texture)
	end
	SetTexture(Sage.GetBarTexture())

	local oStatusBar_UpdateAllTextures = SageStatusBar.UpdateAllTextures
	SageStatusBar.UpdateAllTextures = function()
		oStatusBar_UpdateAllTextures()
		SetTexture(Sage.GetBarTexture())
	end

	local function ShowText(enable)
		if enable then
			text:Show()
		else
			text:Hide()
		end
	end

	local oStatusBar_UpdateAllText = SageStatusBar.UpdateAllText
	SageStatusBar.UpdateAllText = function(enable)
		oStatusBar_UpdateAllText(enable)
		ShowText(enable)
	end

	local druidBar = parent.druid
	if druidBar then
		restBar:SetPoint("TOPLEFT", druidBar, "BOTTOMLEFT")
		restBar:SetPoint("BOTTOMRIGHT", druidBar, "BOTTOMRIGHT", 0, -BAR_HEIGHT)
	else
		restBar:SetPoint("TOPLEFT", parent.mana, "BOTTOMLEFT")
		restBar:SetPoint("BOTTOMRIGHT", parent.mana, "BOTTOMRIGHT", 0, -BAR_HEIGHT)
	end

	parent.click:SetPoint('BOTTOMRIGHT', restBar)
	parent:SetHeight(parent:GetHeight() + BAR_HEIGHT)
end

function SagePlayerXP_Set(enable)
	local frame = SageFrame.Get('player')

	if enable then
		if restBar then
			if not restBar:IsShown() then
				frame:SetHeight(frame:GetHeight() + BAR_HEIGHT)
				restBar:Show()
			end
		else
			CreateXPBar(frame)
		end
		if GetWatchedFactionInfo() then
			WatchRep()
		else
			WatchXP()
		end
	else
		if restBar and restBar:IsShown() then
			frame:SetHeight(frame:GetHeight() - BAR_HEIGHT)
			restBar:Hide()
		end
	end
end