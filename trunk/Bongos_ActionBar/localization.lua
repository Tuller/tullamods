--[[
	Bongos_Actionbar Localization
		English (default)
--]]

local L = BONGOS_LOCALS
L.Columns = "Columns"
L.Size = "Size"
L.Vertical = "Vertical"
L.OneBag = "One Bag"
L.BagBar = "Bag Bar"
L.ActionBar = "Action Bar %s"
L.Paging = "Paging"
L.Stances = "Stances"
L.Page = "Page %s"
L.FriendlyTarget = "Friendly Target"

L.ClassBar = "Class Bar"
L.MenuBar = "Menu Bar"
L.PetBar = "Pet Bar"

--global constants, locale independent
BONGOS_CLASS = select(2, UnitClass("player"))
BONGOS_MAX_BUTTONS = 120
BONGOS_MAX_PAGES = 5

--names of stances, and what people call them
if(BONGOS_CLASS == "DRUID") then
	BONGOS_STANCES = {"Bear", "Aquatic", "Cat", "Travel", "Moonkin/Tree", "Flight", "Prowl"}
elseif(BONGOS_CLASS == "ROGUE") then
	BONGOS_STANCES = {"Stealth"}
elseif(BONGOS_CLASS == "WARRIOR") then
	BONGOS_STANCES = {"Battle", "Defensive", "Berserker"}
elseif(BONGOS_CLASS == "PRIEST") then
	BONGOS_STANCES = {"Shadowform/Redemption"}
end

--keybindings
BINDING_HEADER_BGPAGE = "Bongos Paging"
BINDING_HEADER_BQUICKPAGE = "Quick Paging"
BINDING_HEADER_BBARS = "Bongos Bar Visibility"

BINDING_NAME_BMENUBAR_TOGGLE = "Toggle the MenuBar"
BINDING_NAME_BBAGBAR_TOGGLE = "Toggle the BagBar"