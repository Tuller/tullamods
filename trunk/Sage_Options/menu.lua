--[[
		menu.lua
			A GUI options menu for Sage
--]]

local currentFrameName = SAGE_PANEL_GENERAL

local function UpdateTabs()
	local prevShown
	local numShown = 0

	for i = 1, select('#', SageOptionsMenu:GetChildren()) do
		local frame = select(i, SageOptionsMenu:GetChildren())
		if frame:IsShown() then
			numShown = numShown + 1
			frame:ClearAllPoints()
			if prevShown then
				frame:SetPoint("TOP", prevShown, "BOTTOM")
			else
				frame:SetPoint("TOPRIGHT", SageOptionsMenu, "TOPRIGHT", -8, -4)
			end
			prevShown = frame
		end
	end
	SageOptionsMenu:SetHeight(12 + 26 * numShown)
end

function SOptions_OnShow()
	UpdateTabs()

	currentFrame = getglobal("SageOptionsPanel" .. currentFrameName)
	if not currentFrame:IsShown() then
		currentFrame:Show()
		getglobal("SageOptionsMenu" .. currentFrameName):LockHighlight()
	end
end

function SOptions_SwitchTab(newFrameName)
	if newFrameName ~= currentFrameName then
		this:LockHighlight()
		getglobal("SageOptionsMenu" .. currentFrameName):UnlockHighlight()
		getglobal("SageOptionsPanel" .. currentFrameName):Hide()
		getglobal("SageOptionsPanel" .. newFrameName):Show()
		currentFrameName = newFrameName
	end
end

function SOptions_CreatePanel(name, title, OnShow)
	assert(not getglobal("SageOptionsPanel" .. name), "SageOptionsPanel" .. name .. " already exists")

	local tab = CreateFrame("Button", "SageOptionsMenu" .. name, SageOptionsMenu, "SageOptionsTabButton")
	tab:SetScript("OnClick", function() SOptions_SwitchTab(name) end)
	tab:SetText(title)

	local menu = CreateFrame("Frame", "SageOptionsPanel" .. name, SageOptionsPanel, "SageOptionsPanel")
	menu:SetScript("OnShow", OnShow)
	menu.notFinished = 1

	UpdateTabs()

	return menu
end