--[[
	A profile selector panel
--]]

local L = BONGOS_LOCALS
L.Profiles = "Profiles"
L.Set = "Set"
L.Save = "Save"
L.Copy = "Copy"
L.Delete = "Delete"
L.EnterName = "Enter Profile Name"

--profile options
local listSize = 12
local size = 19


--[[ Profile Button ]]--

local function ProfileButton_OnClick(self)
	local parent = self:GetParent()
	if(parent.selected) then
		parent.selected:UnlockHighlight()
	end
	self:LockHighlight()
	parent.selected = self
end

local function ProfileButton_OnMouseWheel(self, direction)
	local scrollBar = getglobal(self:GetParent().scrollFrame:GetName() .. "ScrollBar")

	scrollBar:SetValue(scrollBar:GetValue() - direction * (scrollBar:GetHeight()/2))
	parent:UpdateList()
	parent:Highlight()
end

local function ProfileButton_Create(name, parent)
	local button = CreateFrame("Button", name, parent)
	button:SetScript("OnClick", ProfileButton_OnClick)
	button:SetScript("OnMouseWheel", ProfileButton_OnMouseWheel)

	local text = button:CreateFontString()
	text:SetFontObject("GameFontNormal"); text:SetJustifyH("LEFT")
	text:SetAllPoints(button)
	button:SetFontString(text)

	local highlight = button:CreateTexture()
	highlight:SetAllPoints(button)
	highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	button:SetHighlightTexture(highlight)

	return button
end


--[[ Panel Functions ]]--

local function Panel_UpdateList(self)
	local list = Bongos.db:GetProfiles()
	local size = #list
	table.sort(list)

	local scrollFrame = self.scrollFrame
	local offset = scrollFrame.offset
	FauxScrollFrame_Update(scrollFrame, size, listSize, listSize)

	for i = 1, listSize do
		local index = i + offset
		local button = self.buttons[i]

		if index <= size then
			button:SetText(list[index])
			button:Show()
		else
			button:Hide()
		end
	end
end

local function Panel_Highlight(self, profile)
	profile = profile or Bongos.db:GetCurrentProfile()

	for _,button in pairs(self.buttons) do
		if(button:GetText() == profile) then
			button:SetTextColor(0.2, 1, 0.2)
			button:SetHighlightTextColor(0.2, 1, 0.2)
		else
			button:SetTextColor(1, 0.82, 0)
			button:SetHighlightTextColor(1, 1, 1)
		end
	end
end

--[[ Make the Panel ]]--

StaticPopupDialogs["BONGOS_OPTIONS_SAVE_PROFILE"] = {
	text = TEXT(L.EnterName),
	button1 = TEXT(ACCEPT),
	button2 = TEXT(CANCEL),
	hasEditBox = 1,
	maxLetters = 24,
	OnAccept = function()
		local text = getglobal(this:GetParent():GetName().."EditBox"):GetText()
		if text ~= "" then
			Bongos:SaveProfile(text)
			panel:UpdateList()
			panel:Highlight(text)
		end
	end,
	EditBoxOnEnterPressed = function()
		local text = getglobal(this:GetParent():GetName().."EditBox"):GetText()
		if text ~= "" then
			Bongos:SaveProfile(text)
			panel:UpdateList()
			panel:Highlight(text)
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
	timeout = 0, exclusive = 1, hideOnEscape = 1
}

function BongosOptions:AddProfilePanel()
	local panel = BongosOptions:AddPanel(L.Profiles)
	panel.UpdateList = Panel_UpdateList
	panel.Highlight = Panel_Highlight

	local name = panel:GetName()

	local OnShow = panel:GetScript("OnShow")
	panel:SetScript("OnShow", function(self) 
		if(OnShow) then OnShow(self) end
		panel:UpdateList()
		panel:Highlight() 
	end)

	local scroll = CreateFrame("ScrollFrame", name .. "ScrollFrame", panel, "FauxScrollFrameTemplate")
	scroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(10, ScrollBar_Update) end)
	scroll:SetScript("OnShow", function(self)
		panel.buttons[1]:SetPoint("BOTTOMRIGHT", scroll, "TOPLEFT", -24, -20)
	end)
	scroll:SetScript("OnHide", function()
		panel.buttons[1]:SetPoint("BOTTOMRIGHT", scroll, "TOPLEFT", -2, -20)
	end)
	scroll:SetPoint("TOPLEFT", panel, "TOPRIGHT", -4, -2)
	scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -26, 42)
	panel.scrollFrame = scroll

	local set = panel:CreateButton(L.Set, 48, 24)
	set:SetScript("OnClick", function()
		local selected = panel.selected
		if selected then
			Bongos:SetProfile(selected:GetText())
			panel:UpdateList()
			panel:Highlight(selected:GetText())
		end
	end)
	set:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 7, 6)

	local save = panel:CreateButton(L.Save, 48, 24)
	save:SetScript("OnClick", function() StaticPopup_Show("BONGOS_OPTIONS_SAVE_PROFILE") end)
	save:SetPoint("LEFT", set, "RIGHT", 5, 0)

	local copy = panel:CreateButton(L.Copy, 48, 24)
	copy:SetScript("OnClick", function()
		local selected = panel.selected
		if selected then
			Bongos:CopyProfile(selected:GetText())
		end
	end)
	copy:SetPoint("LEFT", save, "RIGHT", 5, 0)

	local delete = panel:CreateButton(L.Delete, 48, 24)
	delete:SetScript("OnClick", function()
		local selected = panel.selected
		if selected then
			Bongos:DeleteProfile(selected:GetText())
			panel:UpdateList()
			panel:Highlight()
		end
	end)
	delete:SetPoint("LEFT", copy, "RIGHT", 5, 0)

	--add list buttons
	panel.buttons = {}
	for i = 1, listSize do
		local button = ProfileButton_Create(name .. i, panel)
		if(i == 1) then
			button:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -4)
			button:SetPoint("BOTTOMRIGHT", scroll, "TOPLEFT", -2, -20)
		else
			button:SetPoint("TOPLEFT", name .. i-1, "BOTTOMLEFT", 0, -1)
			button:SetPoint("BOTTOMRIGHT", name .. i-1, "BOTTOMRIGHT", 0, -size)
		end
		panel.buttons[i] = button
	end

	panel.height = panel.height + 24 + size * listSize
	return panel
end

panel = BongosOptions:AddProfilePanel()