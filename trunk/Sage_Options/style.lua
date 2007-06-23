--[[
	The Style Panel
--]]

local L = SAGE_LOCALS

function SageOptions:AddStylePanel()
	local panel = self:AddPanel(L.Style)
	panel.unit = "all"

	local function Percents_OnShow(self) self:SetChecked(Sage:ShowingPercents()) end
	local function Percents_OnClick(self) Sage:SetShowPercents(self:GetChecked()) end
	panel:AddCheckButton(L.ShowHealthPercents, Percents_OnClick, Percents_OnShow)

	local function CastBars_OnShow(self) self:SetChecked(Sage:ShowingCastBars()) end
	local function CastBars_OnClick(self) Sage:SetShowCastBars(self:GetChecked()) end
	panel:AddCheckButton(L.ShowCastBars, CastBars_OnClick, CastBars_OnShow)

	local function DebuffColoring_OnShow(self) self:SetChecked(Sage:DebuffColoring()) end
	local function DebuffColoring_OnClick(self) Sage:SetDebuffColoring(self:GetChecked()) end
	panel:AddCheckButton(L.HealthBarDebuffColoring, DebuffColoring_OnClick, DebuffColoring_OnShow)

	local function OutlineBar_OnShow(self) self:SetChecked(Sage:OutlineBarFonts()) end
	local function OutlineBar_OnClick(self) Sage:SetOutlineBarFonts(self:GetChecked()) end
	panel:AddCheckButton(L.OutlineBarText, OutlineBar_OnClick, OutlineBar_OnShow)

	local function OutlineOut_OnShow(self) self:SetChecked(Sage:OutlineOutsideFonts()) end
	local function OutlineOut_OnClick(self) Sage:SetOutlineOutsideFonts(self:GetChecked()) end
	panel:AddCheckButton(L.OutlineOutside, OutlineOut_OnClick, OutlineOut_OnShow)
	
	local selector = panel:AddTextDisplaySelector()
	selector.text:SetText(selector.vals[1]) 
	selector:SetScript("OnShow", nil)
	
	return panel
end
SageOptions:AddStylePanel()