--[[
	unreg.lua
		Gets rid of the main actionbar

	Frames Unregistered:
		MainMenuBar
		Experience Bar
		Action Bar
		Multibars
		Bonusbars
		Shapeshift
		Pet
--]]

--[[ Unregistering Functions ]]--

--Unregister action buttons
local function UnregisterActionButton(button)
	button:UnregisterAllEvents()
	button:Hide()
end

--Hide action bar
local function UnregisterActionBars()
	BonusActionBarFrame:Hide()

	--Action Buttons
	for i = 1, 12 do
		UnregisterActionButton(getglobal("ActionButton"..i))
		UnregisterActionButton(getglobal("MultiBarBottomLeftButton"..i))
		UnregisterActionButton(getglobal("MultiBarBottomRightButton"..i))
		UnregisterActionButton(getglobal("MultiBarLeftButton"..i))
		UnregisterActionButton(getglobal("MultiBarRightButton"..i))
		UnregisterActionButton(getglobal("BonusActionButton"..i))
	end
	BonusActionBarFrame:UnregisterAllEvents()
	ShapeshiftBarFrame:UnregisterAllEvents()
end

--Hide shapeshift bars
local function UnregisterShapeshiftBar()
	ShapeshiftBarFrame:UnregisterAllEvents()
end

--Hide pet bar
local function UnregisterPetBar()
	PetActionBarFrame:UnregisterAllEvents()
	PetActionBarFrame:Hide()

	for i = 1, NUM_PET_ACTION_SLOTS do
		getglobal("PetActionButton" .. i):UnregisterAllEvents()
	end
end

local noop = function() return end
do

	MainMenuBar:Hide()
	ExhaustionTick:UnregisterAllEvents()
	UnregisterActionBars()
	UnregisterShapeshiftBar()
	UnregisterPetBar()
	
	-- UIPARENT_MANAGED_FRAME_POSITIONS["MultiBarRight"] = nil
	-- UIPARENT_MANAGED_FRAME_POSITIONS["MultiBarLeft"] = nil
	-- UIPARENT_MANAGED_FRAME_POSITIONS["MultiBarBottomLeft"] = nil
	-- UIPARENT_MANAGED_FRAME_POSITIONS["MultiBarBottomRight"] = nil
	-- UIPARENT_MANAGED_FRAME_POSITIONS["MainMenuBar"] = nil

	ALWAYS_SHOW_MULTIBARS = nil
	SHOW_MULTI_ACTIONBAR_1 = nil
	SHOW_MULTI_ACTIONBAR_2 = nil
	SHOW_MULTI_ACTIONBAR_3 = nil
	SHOW_MULTI_ACTIONBAR_4 = nil
	
	MultiActionBar_ShowAllGrids = noop
	MultiActionBar_HideAllGrids = noop
	MultiActionBar_Update()
end