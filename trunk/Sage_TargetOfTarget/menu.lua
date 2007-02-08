--[[
	Sage Target's Config Menu
--]]

local function AddButtons(menu, unit)
	menu.unit = unit
	
	local name = menu:GetName()
	local frame = SageFrame.Get(unit)
	
	local curableDebuffs = CreateFrame("CheckButton", name .. "ShowCurable", menu, "GooeyCheckButton")
	curableDebuffs:SetText(SAGE_OPTIONS_SHOW_CURABLE)
	curableDebuffs:SetPoint("TOPLEFT", menu)
	curableDebuffs:SetScript("OnClick", function() Sage.ShowCurableDebuffs(frame, this:GetChecked()) end)
	
	local alpha = CreateFrame("Slider", name .. "Opacity", menu, "SageOptionsOpacitySlider")
	alpha:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT", 4, 24)
	
	local scale = CreateFrame("Slider", name .. "Scale", menu, "SageOptionsScaleSlider")
	scale:SetPoint("BOTTOMLEFT", alpha, "BOTTOMLEFT", 0, 40)
	
	local minWidth = CreateFrame("Slider", name .. "MinWidth", menu, "SageOptionsWidthSlider")
	minWidth:SetPoint("BOTTOMLEFT", scale, "BOTTOMLEFT", 0, 40)

	local updateInterval = CreateFrame("Slider", name .. "UpdateInterval", menu, "SageOptionsSlider")
	updateInterval:SetPoint("BOTTOMLEFT", minWidth, "BOTTOMLEFT", 0, 40)
	updateInterval:SetMinMaxValues(0.1, 2)
	updateInterval:SetValueStep(0.1)
	
	getglobal(updateInterval:GetName() .. "Text"):SetText(SAGE_TARGET_TARGET_UPDATE_INTERVAL)
	getglobal(updateInterval:GetName() .. "High"):SetText(2)
	getglobal(updateInterval:GetName() .. "Low"):SetText(0.1)
	
	updateInterval:SetScript("OnValueChanged", function()
		if not this:GetParent().onShow then
			frame.sets.updateInterval = this:GetValue()
		end
		getglobal(this:GetName() .. "ValText"):SetText(format("%.1f", this:GetValue()))
	end)

	this.notFinished = nil
end

Sage.AddOptionsPanel("TargetTarget", "Target of Target", function()
	if this.notFinished then
		AddButtons(this, "targettarget")
	end
	
	this.onShow = 1

	local menuName = this:GetName()
	
	local unit = this.unit
	local sets = SageFrame.GetSettings(unit)
	getglobal(menuName .. "UpdateInterval"):SetValue(sets.updateInterval)
	getglobal(menuName .. "MinWidth"):SetValue(sets.minWidth)
	
	local frame = SageFrame.Get(unit)
	getglobal(menuName .. "Scale"):SetValue(frame:GetScale() * 100)
	getglobal(menuName .. "Opacity"):SetValue(frame:GetAlpha() * 100)
	
	this.onShow = nil
end)