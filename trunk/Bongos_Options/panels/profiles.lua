--[[
	profiles.lua
		A gui for managing bongos profiles
--]]

local listSize = 14
local selected

--[[ Profile Button ]]--

function BOptionsProfileButton_OnClick(self)
	for i = 1, listSize do
		local button = getglobal("BongosOptionsPanelProfiles".. i)
		if self == button then
			button:LockHighlight()
		else
			button:UnlockHighlight()
		end
	end
	selected = self
end

function BOptionsProfilesButton_OnMousewheel(scrollframe, direction)
	local scrollbar = getglobal(scrollframe:GetName() .. "ScrollBar")
	scrollbar:SetValue(scrollbar:GetValue() - direction * (scrollbar:GetHeight() / 2))
	BOptionsProfilesScrollBar_Update()
end

--[[ Profile Actions ]]--

function BOptionsProfiles_LoadProfile()
	if selected then
		Bongos:SetProfile(selected:GetText())
		BOptionsProfilesScrollBar_Update()
	end
end

--delete
function BOptionsProfiles_DeleteProfile()
	if selected then
		Bongos:DeleteProfile(selected:GetText())
		BOptionsProfilesScrollBar_Update()
	end
end

--[[ Scroll Bar Functions ]]--
function BOptionsProfiles_OnLoad(self)
	local name = self:GetName()
	local i = 1
	local size = 19

	local button = CreateFrame("Button", name .. i, self, "BongosOptionsProfileButton")
	button:SetPoint("TOPLEFT", self, "TOPLEFT", 4, -4)
	button:SetPoint("BOTTOMRIGHT", name .. "ScrollFrame", "TOPLEFT", -24, -20)
	button:SetID(i)

	for i = 2, listSize do
		button = CreateFrame("Button", name .. i, self, "BongosOptionsProfileButton")
		button:SetPoint("TOPLEFT", name .. i-1, "BOTTOMLEFT", 0, -1)
		button:SetPoint("BOTTOMRIGHT", name .. i-1, "BOTTOMRIGHT", 0, -size)
		button:SetID(i)
	end
end

function BOptionsProfiles_OnShow(self)
	BOptionsProfilesScrollBar_Update()
end

function BOptionsProfilesScrollBar_Update()
	--update list if there are changes
	local list = Bongos.db:GetProfiles()

	local size = #list
	local offset = BongosOptionsPanelProfilesScrollFrame.offset

	FauxScrollFrame_Update(BongosOptionsPanelProfilesScrollFrame, size, listSize, listSize)

	for i = 1, listSize do
		local index = i + offset
		local button = getglobal("BongosOptionsPanelProfiles".. i)

		if index <= size then
			button:SetText(list[index])
			button:Show()
		else
			button:Hide()
		end
	end
end