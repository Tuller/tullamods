--[[
	profiles.lua
		A gui for managing bongos profiles
--]]

local listSize = 14
local selected

StaticPopupDialogs["BONGOS_OPTIONS_SAVE_PROFILE"] = {
	text = TEXT(BONGOS_OPTIONS_PROFILE_ENTER_NAME),
	button1 = TEXT(ACCEPT),
	button2 = TEXT(CANCEL),
	hasEditBox = 1,
	maxLetters = 24,
	OnAccept = function()
		local text = getglobal(this:GetParent():GetName().."EditBox"):GetText()
		if text ~= "" then
			Bongos:SaveProfile(text)
			BOptionsProfilesScrollBar_Update()
			BOptionsProfilesScrollBar_HighlightProfile(text)
		end
	end,
	EditBoxOnEnterPressed = function()
		local text = getglobal(this:GetParent():GetName().."EditBox"):GetText()
		if text ~= "" then
			Bongos:SaveProfile(text)
			BOptionsProfilesScrollBar_Update()
			BOptionsProfilesScrollBar_HighlightProfile(text)
		end
	end,
	OnShow = function()
		getglobal(this:GetName().."EditBox"):SetFocus()
		getglobal(this:GetName().."EditBox"):SetText(UnitClass("player"))
		getglobal(this:GetName().."EditBox"):HighlightText()
	end,
	OnHide = function()
		if ChatFrameEditBox:IsVisible() then
			ChatFrameEditBox:SetFocus()
		end
		getglobal(this:GetName().."EditBox"):SetText("")
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1
}

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
	BOptionsProfilesScrollBar_HighlightProfile(Bongos.db:GetCurrentProfile())
end

--[[ Profile Actions ]]--

function BOptionsProfiles_SaveProfile()
	StaticPopup_Show("BONGOS_OPTIONS_SAVE_PROFILE")
end

function BOptionsProfiles_SetProfile()
	if selected then
		Bongos:SetProfile(selected:GetText())
		BOptionsProfilesScrollBar_Update()
		BOptionsProfilesScrollBar_HighlightProfile(selected:GetText())
	end
end

function BOptionsProfiles_CopyProfile()
	if selected then
		Bongos:CopyProfile(selected:GetText())
	end
end

function BOptionsProfiles_DeleteProfile()
	if selected then
		Bongos:DeleteProfile(selected:GetText())
		BOptionsProfilesScrollBar_Update()
		BOptionsProfilesScrollBar_HighlightProfile(Bongos.db:GetCurrentProfile())
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
	BOptionsProfilesScrollBar_HighlightProfile(Bongos.db:GetCurrentProfile())
end

function BOptionsProfilesScrollBar_Update()
	--update list if there are changes
	local list = Bongos.db:GetProfiles()
	table.sort(list)

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

function BOptionsProfilesScrollBar_HighlightProfile(profile)
	for i = 1, listSize do
		local button = getglobal("BongosOptionsPanelProfiles".. i)
		if(button:GetText() == profile) then
			button:SetTextColor(0.2, 1, 0.2)
			button:SetHighlightTextColor(0.2, 1, 0.2)
		else
			button:SetTextColor(1, 0.82, 0)
			button:SetHighlightTextColor(1, 1, 1)
		end
	end
end