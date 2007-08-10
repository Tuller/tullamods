--[[
	BagnonDBUI
		Functions for the dropdown menu for showing cached data
		No alterations if this code should be needed to make it work with other databases

	Essentially the dropdown is used to switch between the inventory of other characters
	Why not use a normal dropdown?  It takes a lot of memory
--]]

local charList
local chars
local currentPlayer = UnitName("player")
local selectedPlayer = currentPlayer
local currentFrame
local dropdown

local info = {}

--adds a checkable item to a dropdown menu
local function AddCheckItem(text, value, func, selected, hasArrow, level, arg1, arg2)
	info.text = text
	info.func = func
	info.value = value
	info.hasArrow = (hasArrow and true) or nil
	info.notCheckable = false
	info.checked = value == selected
	info.arg1 = arg1
	info.arg2 = arg2
	UIDropDownMenu_AddButton(info, level)
end

--adds an uncheckable item to a dropdown menu
local function AddItem(text, value, func, hasArrow, level, arg1, arg2)
	info.text = text
	info.func = func
	info.value = value
	info.hasArrow = (hasArrow and true) or nil
	info.notCheckable = true
	info.checked = false
	info.arg1 = arg1
	info.arg2 = arg2
	UIDropDownMenu_AddButton(info, level)
end

local function CharSelect_OnClick(player, delete)
	local playerToShow
	if(delete) then
		--remove the selected player
		BagnonDB:RemovePlayer(player)

		--select the current player
		playerToShow = currentFrame:GetPlayer()
	else
		--select the clicked player
		playerToShow = player
	end

	--show the given player, and check the selected one
	currentFrame:SetPlayer(playerToShow)
	UIDropDownMenu_SetSelectedName(dropdown, playerToShow)

	--hide the previous dropdown menus (hack)
	for i = 1, UIDROPDOWNMENU_MENU_LEVEL-1 do
		getglobal("DropDownList"..i):Hide()
	end
end

--populate the list, add a delete button to all characters that aren't the current player
local function CharSelect_Initialize(level)
	local playerList = BagnonDB:GetPlayerList()

	local level = level or 1
	if(level == 1) then
		local selected = currentFrame:GetPlayer()
		for i,player in ipairs(playerList) do
			AddCheckItem(player, i, CharSelect_OnClick, selected, player ~= currentPlayer, level, player)
		end
	elseif(level == 2) then
		AddItem(REMOVE, nil, CharSelect_OnClick, false, level, playerList[UIDROPDOWNMENU_MENU_VALUE], true)
	end
end

local function CharSelect_Create()
	local dropdown = CreateFrame("Frame", "BagnonDBCharSelect", UIParent, "UIDropDownMenuTemplate")
	dropdown:SetID(1)
	UIDropDownMenu_Initialize(dropdown, CharSelect_Initialize, "MENU")

	return dropdown
end

local function CharSelect_Get()
	dropdown = dropdown or CharSelect_Create()
	return dropdown
end


--[[ Usable Functions ]]--

--set which frame to "parent" the dropdown to
function BagnonDB:SetDropdownFrame(frame)
	currentFrame = frame
end

--show the character select list at the given location
function BagnonDB:ToggleDropdown(anchor, offX, offY)
	ToggleDropDownMenu(1, nil, CharSelect_Get(), anchor, offX, offY)
end