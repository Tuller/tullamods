--[[
	A profile selector panel
--]]

local L = BONGOS_LOCALS

--profile options
local listSize = 12
local rows, cols = 7, 3
local textWidth = 48
local defaultWidth, defaultHeight


--[[ Profile Button ]]--

local function VisButton_OnClick(self)
	if self:GetChecked() then
		BBar:ForBar(self:GetText(), "ShowFrame")
	else
		BBar:ForBar(self:GetText(), "HideFrame")
	end
end

local function VisButton_Create(name, parent)
	local button = CreateFrame("CheckButton", name, parent, "GooeyCheckButton")
	button:SetScript("OnClick", VisButton_OnClick)

	local text = getglobal(name .. "Text")
	text:SetWidth(textWidth)
	text:SetJustifyH("LEFT")

	return button
end


--[[ Panel Functions ]]--

local function Panel_UpdateButtons(self)
	for i = 1, (rows*cols) do
		local button = self.buttons[i]
		if button:IsShown() and button:GetText() then
			button:SetChecked(BBar:Get(button:GetText()):IsShown())
		end
	end
end

local list = {}
local function PanelSort(a, b)
	if type(a) == type(b) then
		return a < b
	elseif type(a) == "string" then
		return false
	end
	return true
end

local function Panel_UpdateList(self)
	for i in pairs(list) do list[i] = nil end

	for id in BBar:GetAll() do
		table.insert(list, id)
	end
	table.sort(list, PanelSort)

	local size = #list
	local scrollFrame = self.scrollFrame
	local offset = scrollFrame.offset
	FauxScrollFrame_Update(scrollFrame, size, rows*cols, cols)

	for i = 1, (rows*cols) do
		local index = i + offset
		local button = self.buttons[i]

		if index <= size then
			button:SetText(list[index])
			button:Show()
		else
			button:Hide()
		end
	end
	Panel_UpdateButtons(self)
end

local function Panel_LayoutButtons(self)
	local spacing = (self.scrollFrame:IsShown() and 0) or 20/(cols-1)
	local buttons = self.buttons
	local bWidth = buttons[1]:GetWidth() + textWidth + spacing
	local bHeight = buttons[1]:GetHeight()
	local offY = 40
	local offX = 8
	
	self.all:SetPoint("TOPLEFT", self, "TOPLEFT", offX, -8)
	if(self.actionBar) then
		self.actionBar:SetPoint("TOPLEFT", self.all, "TOPRIGHT", textWidth + spacing, 0)
	end

	for i = 1, (rows*cols) do
		local button = buttons[i]
		local row = mod(i - 1, cols)
		local col = ceil(i / cols) - 1
		button:SetPoint("TOPLEFT", self, "TOPLEFT", bWidth * row + offX, -(bHeight * col + offY))
	end
end

--[[ Make the Panel ]]--

function BongosOptions:AddVisibilityPanel()
	local panel = BongosOptions:AddPanel(L.Visibility)
	panel.UpdateList = Panel_UpdateList
	panel.Highlight = Panel_Highlight

	local name = panel:GetName()

	local OnShow = panel:GetScript("OnShow")
	panel:SetScript("OnShow", function(self)
		if(OnShow) then OnShow(self) end
		panel:UpdateList()
	end)

	local LayoutButtons = function() Panel_LayoutButtons(panel) end
	local scroll = CreateFrame("ScrollFrame", name .. "ScrollFrame", panel, "FauxScrollFrameTemplate")
	scroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(cols, function() panel:UpdateList() end) end)
	scroll:SetScript("OnShow", LayoutButtons)
	scroll:SetScript("OnHide", LayoutButtons)
	scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -6)
	scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 6)
	panel.scrollFrame = scroll

	--add list buttons
	local showAll = VisButton_Create(name .. "All", panel)
	showAll:SetText(ALL:lower())
	showAll:SetChecked(true)
	panel.all = showAll

	if(BongosActionBar) then
		local actionBars = CreateFrame("CheckButton", name .. "ActionBar", panel, "GooeyCheckButton")
		actionBars:SetText(L.ActionBars:lower())
		actionBars:SetChecked(true)
		actionBars:SetScript("OnClick", function(self)
			if self:GetChecked() then
				for i = 1, BongosActionBar:GetNumber() do
					BBar:Get(i):ShowFrame()
				end
			else
				for i = 1, BongosActionBar:GetNumber() do
					BBar:Get(i):HideFrame()
				end
			end
			Panel_UpdateButtons(panel)
		end)
		panel.actionBar = actionBars
	end

	panel.buttons = {}
	for i=1, (rows*cols) do
		panel.buttons[i] = VisButton_Create(name .. i, panel)
	end
	panel.buttons[1]:SetPoint("TOPLEFT", showAll, "BOTTOMLEFT", 0, 0)


	panel.height = panel.height + (rows * panel.buttons[1]:GetHeight()) + 34
	panel.width = max(panel.width, (panel.buttons[1]:GetWidth() + textWidth) * cols + 16)
	return panel
end

panel = BongosOptions:AddVisibilityPanel()