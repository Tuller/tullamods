--[[
	Sage Player's Config Menu

	Options:
		Minwidth,
		Scale,
		Opacity,
		Show Only Curable Debuffs
		Show Only Castable Buffs
		Show Combat Text
--]]

local function AddButtons(menu, unit)
	menu.unit = unit

	local name = menu:GetName()
	local frame = SageFrame.Get(unit)

	local curableDebuffs = CreateFrame("CheckButton", name .. "ShowCurable", menu, "GooeyCheckButton")
	curableDebuffs:SetText(SAGE_OPTIONS_SHOW_CURABLE)
	curableDebuffs:SetPoint("TOPLEFT", menu)
	curableDebuffs:SetScript("OnClick", function() Sage.ShowCurableDebuffs(frame, this:GetChecked()) end)

	local castableBuffs = CreateFrame("CheckButton", name .. "ShowCastable", menu, "GooeyCheckButton")
	castableBuffs:SetText(SAGE_OPTIONS_SHOW_CASTABLE)
	castableBuffs:SetPoint("TOPLEFT", curableDebuffs, "BOTTOMLEFT")
	castableBuffs:SetScript("OnClick", function() Sage.ShowCastableBuffs(frame, this:GetChecked()) end)

	local showCombatText = CreateFrame("CheckButton", name .. "ShowCombatText", menu, "GooeyCheckButton")
	showCombatText:SetText(SAGE_OPTIONS_SHOW_COMBAT_TEXT)
	showCombatText:SetPoint("TOPLEFT", castableBuffs, "BOTTOMLEFT")
	showCombatText:SetScript("OnClick", function() Sage.ShowCombatText(frame, this:GetChecked()) end)

	local alpha = CreateFrame("Slider", name .. "Opacity", menu, "SageOptionsOpacitySlider")
	alpha:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT", 4, 24)

	local scale = CreateFrame("Slider", name .. "Scale", menu, "SageOptionsScaleSlider")
	scale:SetPoint("BOTTOMLEFT", alpha, "BOTTOMLEFT", 0, 40)

	local minWidth = CreateFrame("Slider", name .. "MinWidth", menu, "SageOptionsWidthSlider")
	minWidth:SetPoint("BOTTOMLEFT", scale, "BOTTOMLEFT", 0, 40)

	this.notFinished = nil
end

Sage.AddOptionsPanel('Pet', 'Pet', function()
	if this.notFinished then
		AddButtons(this, 'pet')
	end

	this.onShow = 1

	local menuName = this:GetName()
	local unit = this.unit

	local sets = Sage.GetFrameSets(unit)
	getglobal(menuName .. "ShowCurable"):SetChecked(sets.showCurable)
	getglobal(menuName .. "ShowCastable"):SetChecked(sets.showCastable)
	getglobal(menuName .. "ShowCombatText"):SetChecked(sets.showCombatText)
	getglobal(menuName .. "MinWidth"):SetValue(sets.minWidth)

	local frame = SageFrame.Get(unit)
	getglobal(menuName .. "Scale"):SetValue(frame:GetScale() * 100)
	getglobal(menuName .. "Opacity"):SetValue(frame:GetAlpha() * 100)

	this.onShow = nil
end)