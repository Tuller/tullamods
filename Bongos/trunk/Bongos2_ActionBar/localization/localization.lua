--[[
	Bongos_Actionbar Localization
		English (default)
--]]

local L = BONGOS_LOCALS
L.Columns = "Columns"
L.Size = "Size"
L.Vertical = "Vertical"
L.OneBag = "One Bag"
L.ShowKeyring = "Show Keyring"
L.BagBar = "Bag Bar"
L.ActionBar = "Action Bar %s"
L.Paging = "Paging"
L.Stances = "Stances"
L.Page = "Page %s"
L.FriendlyStance = "Friendly Target"
L.Modifier = "Modifier"
L.Prowl = "Prowl"
L.ShadowForm = "Shadowform/Redemption"

L.ClassBar = "Class Bar"
L.MenuBar = "Menu Bar"
L.PetBar = "Pet Bar"

--global constants, locale independent
BONGOS_CLASS = select(2, UnitClass("player"))
BONGOS_MAX_BUTTONS = 120
BONGOS_MAX_PAGES = 5

--keybindings
BINDING_HEADER_BBARS = "Bongos Bar Visibility"
BINDING_NAME_BMENUBAR_TOGGLE = "Toggle the MenuBar"
BINDING_NAME_BBAGBAR_TOGGLE = "Toggle the BagBar"