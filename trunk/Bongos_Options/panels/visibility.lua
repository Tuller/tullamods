--[[
	visibility.lua
		Scripts for the Visibility panel of the Bongos Options menu
--]]

local ROWS = 9
local COLS = 3

local frameName
local list = {}

local function sortList(bar1, bar2)
	if tonumber(bar1.id) and tonumber(bar2.id) then
		return bar1.id < bar2.id
	elseif not(tonumber(bar1.id) or tonumber(bar2.id)) then
		return bar1.id < bar2.id
	elseif tonumber(bar1.id) then
		return false
	end
	return true
end

function BOptionsVisibility_OnMousewheel(scrollframe, direction)
	local scrollbar = getglobal(scrollframe:GetName() .. "ScrollBar")
	scrollbar:SetValue(scrollbar:GetValue() - direction * (scrollbar:GetHeight() / 2))
	BOptionsVisibilityScrollBar_Update()
end

function BOptionsVisibility_OnLoad(self)
	frameName = self:GetName()

	local allButton = CreateFrame("CheckButton", frameName .. "All", self, "BOptionsShowButton")
	allButton:SetPoint("TOPLEFT", this, "TOPLEFT", 4, 4)
	allButton:SetText(BONGOS_OPTIONS_ALL)
	allButton:SetScript("OnClick", function(self)
		if self:GetChecked() then
			BBar:ForAll("ShowFrame")
		else
			BBar:ForAll("HideFrame")
		end
		BOptionsVisibilityScrollBar_Update()
	end)
	allButton:SetChecked(true)

	if IsAddOnLoaded("Bongos2_ActionBar") then
		local allActionBars = CreateFrame("CheckButton", frameName .. "AllActionBars", self, "BOptionsShowButton")
		allActionBars:SetPoint("LEFT", allButton, "RIGHT", 34, 0)
		allActionBars:SetText(BONGOS_OPTIONS_ACTIONBARS)
		allActionBars:SetScript("OnClick", function(self)
			if self:GetChecked() then
				for i = 1, BActionBar:GetNumber() do
					BActionBar:Get(i):ShowFrame()
				end
			else
				for i = 1, BActionBar:GetNumber() do
					BActionBar:Get(i):HideFrame()
				end
			end
			BOptionsVisibilityScrollBar_Update()
		end)
		allActionBars:SetChecked(true)
	end

	local firstOfRow
	for i = 1, ROWS do
		local button = CreateFrame("CheckButton", frameName .. (i-1)*COLS + 1, self, "BOptionsShowButton")
		if not firstOfRow then
			button:SetPoint("TOPLEFT", allButton, "BOTTOMLEFT")
		else
			button:SetPoint("TOPLEFT", firstOfRow, "BOTTOMLEFT")
		end
		firstOfRow = button
		for j = 2, COLS do
			local button = CreateFrame("CheckButton", frameName .. (i-1)*COLS + j, self, "BOptionsShowButton")
			button:SetPoint("LEFT", frameName .. (i-1)*COLS + j-1, "RIGHT", 34, 0)
		end
	end
end

function BOptionsVisibility_OnShow(self)
	for i in pairs(list) do
		list[i] = nil
	end

	for _, bar in BBar:GetAll() do
		table.insert(list, bar)
	end
	table.sort(list, sortList)

	BOptionsVisibilityScrollBar_Update()
end

function BOptionsVisibilityScrollBar_Update()
	local numButtons = ROWS*COLS
	local size = #list
	local offset = getglobal(frameName .. "ScrollFrame").offset
	FauxScrollFrame_Update(getglobal(frameName .. "ScrollFrame"), size, ROWS*COLS, COLS)

	for index = 1, numButtons do
		local rIndex = index + offset
		local button = getglobal(frameName.. index)

		if rIndex <= size then
			button:SetText(list[rIndex].id)
			button:SetChecked(not list[rIndex].sets.hidden)
			button:Show()
		else
			button:Hide()
		end
	end
end