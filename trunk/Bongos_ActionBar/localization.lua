--[[
	Bongos_Actionbar Localization
--]]


--[[ States ]]--

--Names of stances, should be what people call them
BONGOS_STANCES = {
	['DRUID'] = {[0] = 'Caster', 'Bear', 'Aquatic', 'Cat', 'Travel', 'Moonkin|Tree of Life', 'Flight', 'Prowl'},
	['ROGUE'] = {[0] = 'Unstealth', 'Stealth'},
	['WARRIOR'] = {'Battle Stance', 'Defensive Stance', 'Berserker Stance'},
	['PRIEST'] = {[0] = 'Healer', 'Shadowform|Redemption'},
	['SHAMAN'] = {[0] = 'Caster', 'Ghostwolf'},
}
BONGOS_NORMAL = 'Normal'
BONGOS_PAGE = 'Page %s'


--[[ UI Component names ]]--

BONGOS_ROWS = "Rows"
BONGOS_COLUMNS = "Columns"
BONGOS_SIZE = "Size"
BONGOS_ONE_BAG = "One Bag"
BONGOS_VERTICAL = "Vertical"


--[[ KeyBound ]]--

BONGOS_BINDINGS_CLEAR_HELP = "Press " .. GetBindingText('ESCAPE','KEY_') .. " to clear all hotkeys"
BONGOS_BINDINGS_NO_KEYS_BOUND = 'No Current Hotkeys'
BONGOS_BINDINGS_UNBOUND_FROM_ACTION = 'Unbound %s from %s'
BONGOS_BINDINGS_CLEARED = 'Cleared all hotkeys from %s'
BONGOS_KEY_BOUND_TO_ACTION = "Set %s to %s"
BONGOS_CANNOT_BIND_IN_COMBAT = "Sorry, you can't change key bindings while in combat."
BONGOS_BINDINGS_COMBAT_ENABLED = 'Out of combat, keys can be bound again'
BONGOS_BINDINGS_COMBAT_DISABLED = 'Entering combat, preventing keys from being bound'


--[[ Tooltips ]]--

BONGOS_STATE_HIDE = '<Click> to hide in this state'
BONGOS_STATE_SHOW = '<Click> to show in this state'

BONGOS_STATE_INVERSE_SELECT = '<Control-Click> to select all other states'
BONGOS_STATE_SELECT_ONLY = '<Control-Click> to select only this state'

BONGOS_DOCK_HELP = 'Drag over another actionbar to dock'
BONGOS_UNDOCK_HELP = 'Drag away to undock this bar'

BONGOS_STATE_SHOWN_IN = 'Shown in %s'
BONGOS_STATE_SHOWN_ON_PAGE = 'Shown on Page %s'
BONGOS_STATE_UNUSED = 'Unused'


--[[ Keybindings ]]--

BINDING_HEADER_BGPAGE = "Bongos Paging"
BINDING_HEADER_BQUICKPAGE = "Quick Paging"
BINDING_HEADER_BBARS = "Bongos Bar Visibility"

BINDING_NAME_BMENUBAR_TOGGLE = "Toggle the MenuBar"
BINDING_NAME_BBAGBAR_TOGGLE = "Toggle the BagBar"