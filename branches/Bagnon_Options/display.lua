--[[
	Menu.lua
		Scripts for creating the main options menu for Bagnon
--]]

local L = BAGNON_LOCALS
L.Display = "Display"
L.AtBank = "Show At Bank"
L.AtVendor = "Show At Vendor"
L.AtAH = "Show At The Auction House"
L.AtMail = "Show At Mailbox"
L.AtTrade = "Show When Trading"
L.AtCraft = "Show When Crafting"

--[[
	A toggle is simply a checkbox that sets a saved variable,
	it may perform an action after being checked
--]]

local function Toggle_OnShow(self)
	local id = self:GetParent().id
	self:SetChecked(Bagnon.sets[id][self.var])
end

local function Toggle_OnClick(self)
	Bagnon.sets[id][self.var] = self:GetChecked() and true or nil
end

local function Panel_AddToggle(panel, name, var)
	local toggle = panel:AddCheckButton(name)
	toggle.var = var
	toggle:SetScript("OnClick", Toggle_OnClick)
	toggle:SetScript("OnShow", Toggle_OnShow)
end

function BagnonOptions:AddDisplayPanel()
	local panel = self:AddPanel(L.Display)

	Panel_AddToggle(panel, L.AtBank, "showAtBank")
	Panel_AddToggle(panel, L.AtVendor, "showAtVendor")
	Panel_AddToggle(panel, L.AtAH, "showAtAH")
	Panel_AddToggle(panel, L.AtMail, "showAtMail")
	Panel_AddToggle(panel, L.AtTrade, "showAtTrade")
	Panel_AddToggle(panel, L.AtCraft, "showAtCraft")

	return panel
end
BagnonOptions:AddDisplayPanel()