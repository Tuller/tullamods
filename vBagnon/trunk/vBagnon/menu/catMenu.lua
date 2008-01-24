--[[
	Menu.lua
		Functions for the Bagnon right click options menu
--]]

--[[ Show the Menu ]]--

local MENU_NAME = 'BagnonCatMenu'
local menu
local selectedButton
local listSize = 16

--[[ Scroll Bar ]]--

function BagnonCatMenu_UpdateList()
	local scrollFrame = getglobal(MENU_NAME .. 'ScrollFrame')
	local offset = scrollFrame.offset
	local startIndex = offset
	local i = 0	
	local sets = menu.frame.sets
	
	for id, cat in pairs(sets.cats) do
		i = i + 1
		if i > offset and (i + offset) <= listSize then
			local button = getglobal(MENU_NAME .. i - offset)
			button:SetText(cat.name or 'No Name')
			button.catID = id
			button:Show()
		elseif i + offset > listSize then
			break
		end
	end

	for j = i + 1, listSize do
		getglobal(MENU_NAME .. j):Hide()
	end

	FauxScrollFrame_Update(scrollFrame, i, listSize, listSize)
end

function BagnonCatMenu_OnMouseWheel(scrollframe, direction)
	local scrollbar = getglobal(scrollframe:GetName() .. "ScrollBar")
	scrollbar:SetValue(scrollbar:GetValue() - direction * (scrollbar:GetHeight() / 2))
	BagnonCatMenu_UpdateList()
end

--[[ List Buttons ]]--

function BagnonCatMenuListButton_OnClick(button)
	for i = 1, listSize do
		getglobal(MENU_NAME .. i):UnlockHighlight()
	end
	button:LockHighlight()
	selectedButton = button
end

function BagnonCatMenuListButton_OnMouseWheel()
	BagnonCatMenu_OnMouseWheel(getglobal(MENU_NAME .. 'ScrollFrame'), arg1)
end

function BagnonCatMenu_AddListButtons(menu)
	local size = 19

	local button = CreateFrame("Button", MENU_NAME .. 1, menu, "BagnonListButton")
	button:SetID(1)
	button:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -32)
	button:SetPoint("BOTTOMRIGHT", menu, "TOPRIGHT", -24, -(size + 32))

	for i = 2, listSize do
		button = CreateFrame("Button", MENU_NAME .. i, menu, "BagnonListButton")
		button:SetID(i)
		
		button:SetPoint("TOPLEFT", MENU_NAME .. i-1, "BOTTOMLEFT", 0, -1)
		button:SetPoint("BOTTOMRIGHT", MENU_NAME .. i-1, "BOTTOMRIGHT", 0, -size)
	end
end

--[[ Delete Button ]]--

local function DeleteCat(frame, catID)
	local cats = frame.sets.cats
	if cats[catID] then
		cats[catID] = nil
		frame:RemoveCat(catID)
		
		BagnonCatMenu_UpdateList()
	end
end

function BagnonCatMenuDelete_OnClick(button)
	if selectedButton then
		DeleteCat(menu.frame, selectedButton.catID)
	end
end

function BagnonCatMenuAdd_OnClick(button)
	BagnonCatAdder_Show(menu.frame, menu)
end

--[[ Show Menu ]]--

function BagnonCatMenu_Show(frame, parent)
	if not menu then
		menu = CreateFrame('Button', MENU_NAME, UIParent, 'BagnonCatMenuFrame')
		menu:RegisterForClicks("RightButtonUp")
		BagnonCatMenu_AddListButtons(menu)
	end
	menu.frame = frame
	
	BagnonCatMenu_UpdateList()
	menu:SetPoint("TOPLEFT", parent)
	
	if BagnonMenu then
		BagnonMenu:Hide()
	end
	menu:Show()
end