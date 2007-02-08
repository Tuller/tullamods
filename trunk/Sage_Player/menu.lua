--[[
	Sage Player's Config Menu

	Options:
		Minwidth,
		Scale,
		Opacity,
		Show XP,
		Show Only Curable Debuffs
--]]

local function ShowXP(self, enable)
	if enable then
		self.sets.showXp = 1
	else
		self.sets.showXp = nil
	end
	SagePlayerXP_Set(enable)
end

local function AddMenuButtons(menu, unit)
	menu.unit = unit
	local frame = SageFrame.Get(unit)

	local name = menu:GetName()

	local curableDebuffs = CreateFrame("CheckButton", name .. "ShowCurable", menu, "GooeyCheckButton")
	curableDebuffs:SetText(SAGE_OPTIONS_SHOW_CURABLE)
	curableDebuffs:SetPoint("TOPLEFT", menu)
	curableDebuffs:SetScript("OnClick", function() Sage.ShowCurableDebuffs(frame, this:GetChecked()) end)

	local showCombatText = CreateFrame("CheckButton", name .. "ShowCombatText", menu, "GooeyCheckButton")
	showCombatText:SetText(SAGE_OPTIONS_SHOW_COMBAT_TEXT)
	showCombatText:SetPoint("TOPLEFT", curableDebuffs, "BOTTOMLEFT")
	showCombatText:SetScript("OnClick", function() Sage.ShowCombatText(frame, this:GetChecked()) end)

	local showXP = CreateFrame("CheckButton", name .. "ShowXP", menu, "GooeyCheckButton")
	showXP:SetText(SAGE_PLAYER_SHOW_EXPERIENCE)
	showXP:SetPoint("TOPLEFT", showCombatText, "BOTTOMLEFT")
	showXP:SetScript("OnClick", function() ShowXP(frame, this:GetChecked()) end)

	local alpha = CreateFrame("Slider", name .. "Opacity", menu, "SageOptionsOpacitySlider")
	alpha:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT", 4, 24)

	local scale = CreateFrame("Slider", name .. "Scale", menu, "SageOptionsScaleSlider")
	scale:SetPoint("BOTTOMLEFT", alpha, "BOTTOMLEFT", 0, 40)

	local minWidth = CreateFrame("Slider", name .. "MinWidth", menu, "SageOptionsWidthSlider")
	minWidth:SetPoint("BOTTOMLEFT", scale, "BOTTOMLEFT", 0, 40)

	this.notFinished = nil
end

Sage.AddOptionsPanel("Player", "Player", function()
	if this.notFinished then
		AddMenuButtons(this, "player")
	end

	this.onShow = 1

	local menuName = this:GetName()
	local unit = this.unit
	local sets = SageFrame.GetSettings(unit)

	getglobal(menuName .. "ShowCurable"):SetChecked(sets.showCurable)
	getglobal(menuName .. "ShowCombatText"):SetChecked(sets.showCombatText)
	getglobal(menuName .. "ShowXP"):SetChecked(sets.showXp)
	getglobal(menuName .. "MinWidth"):SetValue(sets.minWidth)

	local frame = SageFrame.Get(unit)
	getglobal(menuName .. "Scale"):SetValue(frame:GetScale() * 100)
	getglobal(menuName .. "Opacity"):SetValue(frame:GetAlpha() * 100)

	this.onShow = nil
end)