--[[
	Bongos_Actionbar Localization
		English (default)
--]]

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
BONGOS_FRIENDLY_STANCE = "Friendly Target"

--keybindings
BINDING_HEADER_BGPAGE = "Bongos Paging"
BINDING_HEADER_BQUICKPAGE = "Quick Paging"
BINDING_HEADER_BBARS = "Bongos Bar Visibility"

BINDING_NAME_BMENUBAR_TOGGLE = "Toggle the MenuBar"
BINDING_NAME_BBAGBAR_TOGGLE = "Toggle the BagBar"