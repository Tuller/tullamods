--[[
	Menu.lua
		Functions for the Bagnon right click options menu
--]]

--[[ Show the Menu ]]--

local MENU_NAME = 'BagnonCatAdd'
local menu
local listSize = 9
local includeList = {}
local excludeList = {}
local categories = {}

local function LoadCategories()
	if BagnonRule then	
		for name in pairs(BagnonRule) do
			table.insert(categories, name)
		end
		table.sort(categories)
	end
end

function BagnonCatAdder_AddCategory(frame, catName)
	local include, exclude

	for name in pairs(includeList) do
		if not include then
			include = name
		else
			include = include .. ';' .. name
		end
	end

	for name in pairs(excludeList) do
		if not exclude then
			exclude = name
		else
			exclude = exclude .. ';' .. name
		end
	end

	frame:AddCat(catName, Bagnon_ToRuleString(include, exclude))
	
	--clear the current list
	getglobal(MENU_NAME .. 'Name'):SetText('')
	
	for i in pairs(excludeList) do
		excludeList[i] = nil
	end
	for i in pairs(includeList) do
		includeList[i] = nil
	end

	BagnonCatAdderList_Update()
end

--[[ Scroll Bar ]]--

function BagnonCatAdder_OnMouseWheel(scrollframe, direction)
	local scrollbar = getglobal(scrollframe:GetName() .. "ScrollBar")
	scrollbar:SetValue(scrollbar:GetValue() - direction * listSize)
	BagnonCatAdderList_Update()
end

function BagnonCatAdderList_Update()
	local scrollFrame = getglobal(MENU_NAME .. 'ListScrollFrame')
	local offset = scrollFrame.offset
	
	for i = 1, listSize do
		local name = categories[i + offset]
		local button = getglobal(MENU_NAME .. 'List' .. i)
		if name then
			getglobal(button:GetName() .. 'Title'):SetText(name)
			getglobal(button:GetName() .. 'Exclude'):SetChecked(excludeList[name])
			getglobal(button:GetName() .. 'Include'):SetChecked(includeList[name])
			button:Show()
		else
			button:Hide()
		end
	end

	FauxScrollFrame_Update(scrollFrame, #categories, listSize, listSize)
end

--[[ List Buttons ]]--

function BagnonCatAdderExclude_OnClick(button)
	local name = getglobal(button:GetParent():GetName() .. 'Title'):GetText()	
	if button:GetChecked() then
		excludeList[name] = button:GetChecked()
	else
		excludeList[name] = nil
	end
	
	local nameBox = getglobal(MENU_NAME .. 'Name')
	if not(nameBox:GetText() and nameBox:GetText() ~= '') then
		nameBox:SetText('Not ' .. name)
	end
end

function BagnonCatAdderInclude_OnClick(button)
	local name = getglobal(button:GetParent():GetName() .. 'Title'):GetText()
	if button:GetChecked() then
		includeList[name] = button:GetChecked()
	else
		includeList[name] = nil
	end

	local nameBox = getglobal(MENU_NAME .. 'Name')
	if not(nameBox:GetText() and nameBox:GetText() ~= '') then
		nameBox:SetText(name)
	end
end

function BagnonCatAdder_AddListButtons(frame)
	local frameName = frame:GetName()

	local button = CreateFrame("CheckButton", frameName .. 1, frame, "BagnonFilterListButton")
	button:SetID(1)
	button:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -22)

	for i = 2, listSize do
		button = CreateFrame("CheckButton", frameName .. i, frame, "BagnonFilterListButton")
		button:SetID(i)
		button:SetPoint("TOPLEFT", frameName .. i - 1, "BOTTOMLEFT", 0, 4)
	end
end

--[[ Show Menu ]]--

function BagnonCatAdder_Show(frame, parent)
	if not menu then
		LoadCategories()		
		menu = CreateFrame('Frame', MENU_NAME, UIParent, 'BagnonCatAdderFrame')
	end
	menu.frame = frame
	
	BagnonCatAdderList_Update()

	if BagnonCatMenu then
		BagnonCatMenu:Hide()
	end
	
	menu:SetPoint("TOPLEFT", parent)
	menu:Show()
end