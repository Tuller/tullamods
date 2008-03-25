--[[
	A profile selector panel
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3')
local Options = Bongos.Options

--profile options
local NUM_ITEMS = 8
local width, height, offset = 146, 18, 2


--[[ Profile Button ]]--

local function ProfileButton_OnClick(self)
	local parent = self:GetParent()
	if parent.selected then
		parent.selected:UnlockHighlight()
	end
	self:LockHighlight()
	parent.selected = self
end

local function ProfileButton_OnMouseWheel(self, direction)
	local scrollBar = getglobal(self:GetParent().scrollFrame:GetName() .. 'ScrollBar')

	scrollBar:SetValue(scrollBar:GetValue() - direction * (scrollBar:GetHeight()/2))
	parent:UpdateList()
	parent:Highlight()
end

local function ProfileButton_Create(name, parent)
	local button = CreateFrame('Button', name, parent)
	button:SetWidth(width) button:SetHeight(height)
	button:SetScript('OnClick', ProfileButton_OnClick)
	button:SetScript('OnMouseWheel', ProfileButton_OnMouseWheel)

	local text = button:CreateFontString()
	text:SetFontObject('GameFontNormal'); text:SetJustifyH('LEFT')
	text:SetAllPoints(button)
	button:SetFontString(text)

	local highlight = button:CreateTexture()
	highlight:SetAllPoints(button)
	highlight:SetTexture('Interface/QuestFrame/UI-QuestTitleHighlight')
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
	FauxScrollFrame_Update(scrollFrame, size, NUM_ITEMS, height + offset)

	for i = 1, NUM_ITEMS do
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
	local profile = profile or Bongos.db:GetCurrentProfile()

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

local function Panel_CreatePopupDialog(panel)
	return {
		text = TEXT(L.EnterName),
		button1 = TEXT(ACCEPT),
		button2 = TEXT(CANCEL),
		hasEditBox = 1,
		maxLetters = 24,
		OnAccept = function()
			local text = getglobal(this:GetParent():GetName()..'EditBox'):GetText()
			if text ~= '' then
				Bongos:SaveProfile(text)
				panel:UpdateList()
				panel:Highlight(text)
			end
		end,
		EditBoxOnEnterPressed = function()
			local text = getglobal(this:GetParent():GetName()..'EditBox'):GetText()
			if text ~= '' then
				Bongos:SaveProfile(text)
				panel:UpdateList()
				panel:Highlight(text)
			end
		end,
		OnShow = function()
			getglobal(this:GetName()..'EditBox'):SetFocus()
			getglobal(this:GetName()..'EditBox'):SetText(UnitName('player'))
			getglobal(this:GetName()..'EditBox'):HighlightText()
		end,
		OnHide = function()
			if ChatFrameEditBox:IsVisible() then
				ChatFrameEditBox:SetFocus()
			end
			getglobal(this:GetName()..'EditBox'):SetText('')
		end,
		timeout = 0, exclusive = 1, hideOnEscape = 1
	}
end

function Options:AddProfilePanel()
	local panel = self:CreatePanel(L.Profiles)
	panel:SetWidth(180); panel:SetHeight(200)
	panel:SetPoint('TOPRIGHT', -10, -24)

	panel.UpdateList = Panel_UpdateList
	panel.Highlight = Panel_Highlight

	local name = panel:GetName()

	panel:SetScript('OnShow', function(self)
		self:UpdateList()
		self:Highlight()
	end)

	local scroll = CreateFrame('ScrollFrame', name .. 'ScrollFrame', panel, 'FauxScrollFrameTemplate')
	scroll:SetScript('OnVerticalScroll', function() FauxScrollFrame_OnVerticalScroll(height + offset, function() panel:UpdateList() panel:Highlight() end) end)
	scroll:SetScript('OnShow', function(self) panel.buttons[1]:SetWidth(width) end)
	scroll:SetScript('OnHide', function() panel.buttons[1]:SetWidth(width + 20) end)
	scroll:SetPoint('TOPLEFT', 6, -6)
	scroll:SetPoint('BOTTOMRIGHT', -28, 34)
	panel.scrollFrame = scroll

	local set = self:CreateButton(L.Set, panel, 38, 24)
	set:SetScript('OnClick', function()
		local selected = panel.selected
		if selected then
			Bongos:SetProfile(selected:GetText())
			panel:UpdateList()
			panel:Highlight(selected:GetText())
		end
	end)
	set:SetPoint('BOTTOMLEFT', 5, 6)

	local save = self:CreateButton(L.Save, panel, 42, 24)
	save:SetScript('OnClick', function() StaticPopup_Show('BONGOS_OPTIONS_SAVE_PROFILE') end)
	save:SetPoint('LEFT', set, 'RIGHT')

	local copy = self:CreateButton(L.Copy, panel, 42, 24)
	copy:SetScript('OnClick', function()
		local selected = panel.selected
		if selected then
			Bongos:CopyProfile(selected:GetText())
		end
	end)
	copy:SetPoint('LEFT', save, 'RIGHT')

	local delete = self:CreateButton(L.Delete, panel, 48, 24)
	delete:SetScript('OnClick', function()
		local selected = panel.selected
		if selected then
			Bongos:DeleteProfile(selected:GetText())
			panel:UpdateList()
			panel:Highlight()
		end
	end)
	delete:SetPoint('LEFT', copy, 'RIGHT')

	--add list buttons
	panel.buttons = {}
	for i = 1, NUM_ITEMS do
		local button = ProfileButton_Create(name .. i, panel)
		if i == 1 then
			button:SetPoint('TOPLEFT', 8, -8)
		else
			button:SetPoint('TOPLEFT', name .. i-1, 'BOTTOMLEFT', 0, -offset)
			button:SetPoint('TOPRIGHT', name .. i-1, 'BOTTOMRIGHT', 0, -offset)
		end
		panel.buttons[i] = button
	end
	
	StaticPopupDialogs['BONGOS_OPTIONS_SAVE_PROFILE'] = Panel_CreatePopupDialog(panel)

	return panel
end
Options:AddProfilePanel()