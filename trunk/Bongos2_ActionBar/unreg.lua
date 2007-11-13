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

-- local noop = function() return end

--[[ Unregistering Functions ]]--

local function noop() end

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

MainMenuBar:Hide()
ExhaustionTick:UnregisterAllEvents()
UnregisterActionBars()
UnregisterShapeshiftBar()
UnregisterPetBar()

MultiActionBar_UpdateGridVisibility = noop
MultiActionBar_Update = noop
for i in pairs(VIEWABLE_ACTION_BAR_PAGES) do
	VIEWABLE_ACTION_BAR_PAGES[i] = 1
end