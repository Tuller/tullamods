--[[
	A general options panel
--]]

local L = SAGE_LOCALS

function SageOptions:AddGeneralPanel()
	local panel = self:AddPanel(L.General)
	panel.unit = "all"

	local function Lock_OnShow(self) self:SetChecked(Sage:IsLocked()) end
	local function Lock_OnClick(self) Sage:SetLock(self:GetChecked()) end
	panel:AddCheckButton(L.SetLock, Lock_OnClick, Lock_OnShow)

	local function Sticky_OnShow(self) self:SetChecked(Sage:IsSticky()) end
	local function Sticky_OnClick(self) Sage:SetSticky(self:GetChecked()) end
	panel:AddCheckButton(L.SetSticky, Sticky_OnClick, Sticky_OnShow)
	
	local slider = panel:AddWidthSlider(); slider:SetScript("OnShow", nil)
	slider.onShow = true; slider:SetValue(120); slider.onShow = nil
	local slider = panel:AddAlphaSlider(); slider:SetScript("OnShow", nil)
	slider.onShow = true; slider:SetValue(100); slider.onShow = nil
	local slider = panel:AddScaleSlider(); slider:SetScript("OnShow", nil)
	slider.onShow = true; slider:SetValue(100); slider.onShow = nil
	
	return panel
end
SageOptions:AddGeneralPanel()