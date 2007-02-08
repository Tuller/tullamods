--[[
	stance.lua
		This panel does things for enablin
--]]

local frameName, selectedButton
local listSize = 14


--[[ Buttons ]]--

function BOptionsStanceButton_OnClick(clickedButton)
	for i = 1, listSize do
		getglobal(frameName .. i):UnlockHighlight()
	end
	clickedButton:LockHighlight()
	selectedButton = clickedButton
end

function BOptionsStance_Save()
	local stance = tonumber(UIDropDownMenu_GetSelectedValue(getglobal(frameName .. "StanceAddStance")))
	local fromBar = tonumber(getglobal(frameName .. 'StanceAddBarsMin'):GetText())
	local toBar = tonumber(getglobal(frameName .. 'StanceAddBarsMax'):GetText())

	if stance and fromBar and toBar then
		local bar = BActionBar.Get(fromBar)
		if bar then
			if fromBar == toBar then
				bar:SetStanceBar(stance, nil)
			else
				bar:SetStanceBar(stance, toBar)
			end
		end
	end

	BOptionsStance_UpdateScrollBar()
	getglobal(frameName..'StanceAdd'):Hide()
end

function BOptionsStance_Delete()
	if selectedButton then
		BActionBar.Get(selectedButton.bar):SetStanceBar(selectedButton.stanceID, nil)
		BOptionsStance_UpdateScrollBar()
	end
end

function BOptionsStance_AddNew()
	getglobal(frameName..'StanceAdd'):Show()
end


--[[ Stance Adder Dialog ]]--

--event listing
local function AddDropdownButton(text, value, selectedValue, action)
	local info = {}
	info.text = text
	info.func = action
	info.value = value
	if value == selectedValue then
		info.checked = 1
	end
	UIDropDownMenu_AddButton(info)
end

local function StanceStance_OnClick()
	UIDropDownMenu_SetSelectedValue(getglobal(frameName .. "StanceAddStance"), this.value)
end

local function StanceStance_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(getglobal(frameName .. "StanceAddStance"))
	
	local s,e = BState.GetStanceRange()
	for i = s, e do
		if not selectedValue then
			selectedValue = 1
		end
		AddDropdownButton(BState.GetStanceName(i), i, i, StanceStance_OnClick)
	end

	UIDropDownMenu_SetSelectedValue(getglobal(frameName .. "StanceAddStance"), selectedValue)
end

function BOptionsStanceStance_OnShow()
	UIDropDownMenu_Initialize(this, StanceStance_Initialize)
	UIDropDownMenu_SetWidth(108, this)
end


--[[ Panel ]]--

function BOptionsStance_UpdateScrollBar()
	local scrollFrame = getglobal(frameName .. 'ScrollFrame')
	local offset = scrollFrame.offset
	local startIndex = offset
	local i = 0
	local s, e = BState.GetStanceRange()

	for barID = 1, BActionBar.GetNumber() do
		local bar = BActionBar.Get(barID)
		for stance = s, e do
			local amount = bar.sets['s' .. stance] or 0
			if amount > 0 then
				i = i + 1
				if i > offset and (i + offset) <= listSize then
					local button = getglobal(frameName .. i - offset)
					button:SetText(format(BONGOS_STANCE_TEXT, BState.GetStanceName(stance), barID, amount))
					button.bar = barID
					button.stanceID = stance
					button:Show()
				end
			end
		end
	end

	for j = i+1, listSize do
		getglobal(frameName .. j):Hide()
	end

	FauxScrollFrame_Update(scrollFrame, i, listSize, listSize)
end

function BOptionsStance_OnLoad()
	frameName = this:GetName()
	local size = 19

	local button = CreateFrame("Button", frameName .. 1, this, "BongosOptionsStanceButton")
	button:SetPoint("TOPLEFT", this, "TOPLEFT", 4, -4)
	button:SetPoint("BOTTOMRIGHT", this, "TOPRIGHT", -24, -size)
	button:SetID(1)

	for i = 2, listSize do
		button = CreateFrame("Button", frameName .. i, this, "BongosOptionsStanceButton")
		button:SetPoint("TOPLEFT", frameName .. i-1, "BOTTOMLEFT", 0, -1)
		button:SetPoint("BOTTOMRIGHT", frameName .. i-1, "BOTTOMRIGHT", 0, -size)
		button:SetID(i)
	end
end

function BOptionsStance_OnShow()
	BOptionsStance_UpdateScrollBar()
end

function BOptionsStance_OnMousewheel(scrollframe, direction)
	local scrollbar = getglobal(scrollframe:GetName() .. "ScrollBar")
	scrollbar:SetValue(scrollbar:GetValue() - direction * (scrollbar:GetHeight() / 2))

	BOptionsStance_UpdateScrollBar()
end