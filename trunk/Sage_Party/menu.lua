--[[
	Sage Target's Config Menu
--]]

local function ShowInRaid(enable)
	if enable then
		SageDB.alwaysShowParty = 1
	else
		SageDB.alwaysShowParty = nil
	end
	SParty_UpdateMembers()
end

local function AddButtons(menu, unit)
	local name = menu:GetName()
	menu.unit = unit

	local showInRaid = CreateFrame("CheckButton", name .. "ShowInRaid", menu, "GooeyCheckButton")
	showInRaid:SetText(SAGE_PARTY_SHOW_IN_RAID)
	showInRaid:SetPoint("TOPLEFT", menu)
	showInRaid:SetScript("OnClick", function() ShowInRaid(this:GetChecked()) end)

	local curableDebuffs = CreateFrame("CheckButton", name .. "ShowCurable", menu, "GooeyCheckButton")
	curableDebuffs:SetText(SAGE_OPTIONS_SHOW_CURABLE)
	curableDebuffs:SetPoint("TOPLEFT", showInRaid, "BOTTOMLEFT")
	curableDebuffs:SetScript("OnClick", function() Sage.ForFrame(unit, Sage.ShowCurableDebuffs, this:GetChecked()) end)

	local castableBuffs = CreateFrame("CheckButton", name .. "ShowCastable", menu, "GooeyCheckButton")
	castableBuffs:SetText(SAGE_OPTIONS_SHOW_CASTABLE)
	castableBuffs:SetPoint("TOPLEFT", curableDebuffs, "BOTTOMLEFT")
	castableBuffs:SetScript("OnClick", function() Sage.ForFrame(unit, Sage.ShowCastableBuffs, this:GetChecked()) end)

	local showCombatText = CreateFrame("CheckButton", name .. "ShowCombatText", menu, "GooeyCheckButton")
	showCombatText:SetText(SAGE_OPTIONS_SHOW_COMBAT_TEXT)
	showCombatText:SetPoint("TOPLEFT", castableBuffs, "BOTTOMLEFT")
	showCombatText:SetScript("OnClick", function() Sage.ForFrame(unit, Sage.ShowCombatText, this:GetChecked()) end)

	local alpha = CreateFrame("Slider", name .. "Opacity", menu, "SageOptionsOpacitySlider")
	alpha:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT", 4, 24)

	local scale = CreateFrame("Slider", name .. "Scale", menu, "SageOptionsScaleSlider")
	scale:SetPoint("BOTTOMLEFT", alpha, "BOTTOMLEFT", 0, 40)

	local minWidth = CreateFrame("Slider", name .. "MinWidth", menu, "SageOptionsWidthSlider")
	minWidth:SetPoint("BOTTOMLEFT", scale, "BOTTOMLEFT", 0, 40)

	menu.notFinished = nil
end

Sage.AddOptionsPanel('Party', 'Party', function()
	if this.notFinished then
		AddButtons(this, 'party')
	end

	local menuName = this:GetName()

	this.onShow = 1

	local sets = Sage.GetFrameSets("party1")
	getglobal(menuName .. "ShowInRaid"):SetChecked(SageDB.alwaysShowParty)
	getglobal(menuName .. "ShowCurable"):SetChecked(sets.showCurable)
	getglobal(menuName .. "ShowCastable"):SetChecked(sets.showCastable)
	getglobal(menuName .. "ShowCombatText"):SetChecked(sets.showCombatText)
	getglobal(menuName .. "MinWidth"):SetValue(sets.minWidth)

	local frame = SageFrame.Get("party1")
	getglobal(menuName .. "Scale"):SetValue(frame:GetScale() * 100)
	getglobal(menuName .. "Opacity"):SetValue(frame:GetAlpha() * 100)

	this.onShow = nil
end)