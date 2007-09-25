--[[
	Menu.lua
		Scripts for creating the main options menu for Bagnon
--]]
local L = BAGNON_LOCALS
L.General = "General"
L.ShowBorders = "Show Item Quality Borders"
L.ShowOwners = "Show Item Owners"
L.ReplaceBags = "Replace Bags"
L.ReplaceBank = "Replace Bank"
L.ReuseFrames = "Reuse Blizzard Frames"

local function Toggle_OnShow(self)
	local id = self:GetParent().id
	self:SetChecked(Bagnon[id][self.var])
end

local function Toggle_OnClick(self)
	local id = self:GetParent().id
	Bagnon[id][self.var] = self:GetChecked() and true or nil
	if(self.PostClick) then self:PostClick() end
end

local function Panel_AddToggle(panel, name, var, PostClick)
	local toggle = panel:AddCheckButton(name)
	toggle.var = var
	toggle.PostClick = PostClick
	toggle:SetScript("OnClick", Toggle_OnClick)
	toggle:SetScript("OnShow", Toggle_OnShow)
end

function BagnonOptions:AddGeneralPanel()
	local panel = self:AddPanel(L.General)

	local function ShowBorders_PostClick()
		local bags = Bagnon:GetInventory()
		if bags and bags:IsShown() then
			bags:Regenerate()
		end
		local bank = Bagnon:GetBank()
		if bank and bank:IsShown() then
			bank:Regenerate()
		end
	end
	Panel_AddToggle(panel, L.ShowBorders, "showBorders", ShowBorders_PostClick)

	if BagnonDB then
		Panel_AddToggle(panel, L.ShowOwners, "showOwners")
	end
	Panel_AddToggle(panel, L.ReplaceBags, "replaceBags")
	Panel_AddToggle(panel, L.ReplaceBank, "replaceBank")
	Panel_AddToggle(panel, L.ReuseFrames, "reuseFrames", function() ReloadUI() end)

	return panel
end
BagnonOptions:AddGeneralPanel()