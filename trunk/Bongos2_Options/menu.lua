--[[
		menu.lua
			A GUI options menu for Bongos
--]]

local currentFrameName = BONGOS_PANEL_GENERAL

local function UpdateTabs(menu)
	local prev
	local numShown = 0

	for i = 1, select("#", menu:GetChildren()) do
		local frame = select(i, menu:GetChildren())
		if frame:IsShown() then
			numShown = numShown + 1
			frame:ClearAllPoints()
			if prev then
				frame:SetPoint("TOP", prev, "BOTTOM")
			else
				frame:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -8, -4)
			end
			prev = frame
		end
	end
	menu:SetHeight(12 + 26 * numShown)
end

function BOptions_OnShow(self)
	local name = self:GetName()
	UpdateTabs(getglobal(name .. "Menu"))

	currentFrame = getglobal(name .. "Panel" .. currentFrameName)
	if not currentFrame:IsShown() then
		currentFrame:Show()
		getglobal(name .. "Menu" .. currentFrameName):LockHighlight()
	end
end

function BOptions_SwitchTab(newFrameName)
	if newFrameName ~= currentFrameName then
		this:LockHighlight()
		getglobal("BongosOptionsMenu" .. currentFrameName):UnlockHighlight()
		getglobal("BongosOptionsPanel" .. currentFrameName):Hide()
		getglobal("BongosOptionsPanel" .. newFrameName):Show()
		currentFrameName = newFrameName
	end
end

local function AddTab(name, title)
	local tab = CreateFrame("Button", "BongosOptionsMenu" .. name, BongosOptionsMenu, "BongosOptionsTabButton")
	tab:SetScript("OnClick", function() BOptions_SwitchTab(name) end)
	tab:SetText(title)
end

function BOptions_OnLoad(self)
	if IsAddOnLoaded("Bongos2_ActionBar") then
		local name = self:GetName() .. "Panel"

		AddTab("ActionBar", BONGOS_PANEL_ACTIONBARS)
		CreateFrame("Frame", name .. "ActionBar", BongosOptionsPanel, "BongosOptionsActionBar")

		AddTab("Bindings", BONGOS_PANEL_BINDINGS)
		CreateFrame("Frame", name .. "Bindings", BongosOptionsPanel, "BongosOptionsBindings")
	end
end