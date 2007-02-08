--[[
	Sage_Player\druidBar.lua
		A druidbar for Sage
--]]

local BAR_HEIGHT = 12

--So, I'm also using this an example of lua's scoping rules
function SDruidBar_Create(parent)
	local name = parent:GetName() .. "DruidBar"

	--build the bar
	local druidBar = CreateFrame("StatusBar", name, parent)
	druidBar:SetAlpha(parent:GetAlpha())
	druidBar:EnableMouse(false)
	druidBar:Hide()

	local bg = druidBar:CreateTexture(name .. "Background", "BACKGROUND")
	bg:SetAllPoints(druidBar)

	local function SetTexture(texture)
		bg:SetTexture(texture)
		druidBar:SetStatusBarTexture(texture)
	end
	SetTexture(Sage.GetBarTexture())

	local color = ManaBarColor[0]
	druidBar:SetStatusBarColor(color.r, color.g, color.b)
	bg:SetVertexColor(color.r * 0.5, color.g * 0.5, color.b * 0.5, 0.6)

	local text = druidBar:CreateFontString(name .. "Text" ,"OVERLAY")
	text:SetFontObject(SageBarFontSmall)
	text:SetPoint("CENTER", druidBar, "CENTER", 0, 1)
	if not Sage.ShowingText() then
		text:Hide()
	end

	--OnX Functions
	druidBar.toNextUpdate = 0.3
	druidBar:SetScript("OnUpdate", function()
		if this.toNextUpdate <= 0 then
			druidBar:SetMinMaxValues(0, DruidBarKey.maxmana)
			druidBar:SetValue(DruidBarKey.keepthemana)
			druidBar.toNextUpdate = 0.3
			SageStatusBar.SetText(text, floor(DruidBarKey.keepthemana + 0.5), DruidBarKey.maxmana, Sage.GetManaTextMode())
		else
			druidBar.toNextUpdate = druidBar.toNextUpdate - arg1
		end
	end)

	--Events
	local manaBar = parent:GetName() .. "Mana"
	druidBar:SetPoint("TOPLEFT", manaBar, "BOTTOMLEFT", 0, 0)
	druidBar:SetPoint("BOTTOMRIGHT", manaBar)
	druidBar:Hide()

	druidBar:SetScript("OnEvent", function()
		if UnitPowerType("player") == 0 then
			if druidBar:IsShown() then
				druidBar:Hide()
				druidBar:SetPoint("TOPLEFT", manaBar, "BOTTOMLEFT", 0, 0)
				druidBar:SetPoint("BOTTOMRIGHT", manaBar)

				parent:SetHeight(parent:GetHeight() - BAR_HEIGHT)
			end
		else
			if not druidBar:IsShown() then
				druidBar.toNextUpdate = 0
				druidBar:Show()
				druidBar:SetPoint("TOPLEFT", manaBar, "BOTTOMLEFT", 0, 0)
				druidBar:SetPoint("BOTTOMRIGHT", manaBar, "BOTTOMRIGHT", 0, -BAR_HEIGHT)

				parent:SetHeight(parent:GetHeight() + BAR_HEIGHT)
			end
		end
	end)
	druidBar:RegisterEvent("UPDATE_BONUS_ACTIONBAR")

	--Function hooks
	local parent_OnEnter = parent:GetScript("OnEnter")
	parent:SetScript("OnEnter", function()
		parent_OnEnter()
		SageStatusBar.SetText(text, floor(DruidBarKey.keepthemana + 0.5), DruidBarKey.maxmana, Sage.GetManaTextMode())
		text:Show()
	end)

	local parent_OnLeave = parent:GetScript("OnLeave")
	parent:SetScript("OnLeave", function()
		parent_OnLeave()
		if not Sage.ShowingText() then 
			text:Hide() 
		end
	end)

	local oStatusBar_SetAllTextures = SageStatusBar.SetAllTextures
	SageStatusBar.SetAllTextures = function(texture)
		oStatusBar_SetAllTextures(texture)
		SetTexture(texture)
	end

	local oStatusBar_UpdateAllText = SageStatusBar.UpdateAllText
	SageStatusBar.UpdateAllText = function(enable)
		oStatusBar_UpdateAllText(enable)
		if enable then
			text:Show()
		else
			text:Hide()
		end
	end
end