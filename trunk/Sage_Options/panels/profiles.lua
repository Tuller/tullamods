StaticPopupDialogs["SAGE_OPTIONS_SAVE_PROFILE"] = {
	text = TEXT(SAGE_OPTIONS_PROFILE_ENTER_NAME),
	button1 = TEXT(ACCEPT),
	button2 = TEXT(CANCEL),
	hasEditBox = 1,
	maxLetters = 24,
	OnAccept = function()
		local text = getglobal(this:GetParent():GetName().."EditBox"):GetText()
		if text ~= "" then
			SProfile.Save(text)
			SOptionsProfilesScrollBar_Update()
		end
	end,
	EditBoxOnEnterPressed = function()
		local text = getglobal(this:GetParent():GetName().."EditBox"):GetText()
		if text ~= "" then
			SProfile.Save(text)
			SOptionsProfilesScrollBar_Update()
		end
	end,
	OnShow = function()
		getglobal(this:GetName().."EditBox"):SetFocus()
		getglobal(this:GetName().."EditBox"):SetText(UnitName("player"))
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


local listSize = 14
local selectedButton

--[[ Profile Button ]]--

function SOptionsProfileButton_OnClick(clickedButton)
	for i = 1, listSize do
		local button = getglobal(format("SageOptionsPanelProfiles%d", i))
		if clickedButton ~= button then
			button:UnlockHighlight()
		else
			button:LockHighlight()
		end
	end
	selectedButton = clickedButton
end

function SOptionsProfilesButton_OnMousewheel(scrollframe, direction)
	local scrollbar = getglobal(scrollframe:GetName() .. "ScrollBar")
	scrollbar:SetValue(scrollbar:GetValue() - direction * (scrollbar:GetHeight() / 2))
	SOptionsProfilesScrollBar_Update()
end

--[[ Profile Actions ]]--
function SOptionsProfiles_SaveProfile()
	StaticPopup_Show("SAGE_OPTIONS_SAVE_PROFILE")
end

function SOptionsProfiles_LoadProfile()
	if selectedButton then
		SProfile.Load(selectedButton:GetText())
		SOptionsProfilesScrollBar_Update()
	end
end

--delete
function SOptionsProfiles_DeleteProfile()
	if selectedButton then
		SProfile.Delete(selectedButton:GetText())
		SOptionsProfilesScrollBar_Update()
	end
end

--[[ Scroll Bar Functions ]]--
function SOptionsProfiles_OnLoad()
	local thisName = this:GetName()
	local i = 1
	local size = 19

	local button = CreateFrame("Button", thisName .. i, this, "SageOptionsProfileButton")
	button:SetPoint("TOPLEFT", this, "TOPLEFT", 4, -4)
	button:SetPoint("BOTTOMRIGHT", thisName .. "ScrollFrame", "TOPLEFT", -24, -20)
	button:SetID(i)

	for i = 2, listSize do
		button = CreateFrame("Button", thisName .. i, this, "SageOptionsProfileButton")
		button:SetPoint("TOPLEFT", thisName .. i-1, "BOTTOMLEFT", 0, -1)
		button:SetPoint("BOTTOMRIGHT", thisName .. i-1, "BOTTOMRIGHT", 0, -size)
		button:SetID(i)
	end
end

function SOptionsProfiles_OnShow()
	SOptionsProfilesScrollBar_Update()
end

function SOptionsProfilesScrollBar_Update(parentName)
	--update list if there are changes
	local list = {}
	for name in pairs(SageProfiles) do
		table.insert(list, name)
	end
	table.sort(list)

	local size = #list
	local offset = SageOptionsPanelProfilesScrollFrame.offset

	FauxScrollFrame_Update(SageOptionsPanelProfilesScrollFrame, size, listSize, listSize)

	for index = 1, listSize do
		local rIndex = index + offset
		local button = getglobal(format("SageOptionsPanelProfiles%d", index))

		if rIndex <= size then
			button:SetText(list[rIndex])
			--button:SetTextColor(1, 0.82, 0)
			button:Show()
		else
			button:Hide()
		end
	end
end