--[[
	Bagnon Localization file

	TODO:
		Add some frame strings and other things
		I could probably Babelfish the translation, but most likely it would insult someone's
			mother or something.
--]]

--[[
	English - Default Language
		This version MUST always be loaded, as it has default values for all strings.
--]]


--[[ Keybindings ]]--

BINDING_HEADER_BAGNON = "Bagnon"
BINDING_NAME_BAGNON_TOGGLE = "Toggle Inventory"
BINDING_NAME_BANKNON_TOGGLE = "Toggle Bank"


--[[ Slash Commands ]]--

BAGNON_COMMAND_HELP = "help"
BAGNON_COMMAND_SHOWBAGS = "bags"
BAGNON_COMMAND_SHOWBANK = "bank"
BAGNON_COMMAND_LIST_RULES = "rules"


--[[ Messages from the slash commands ]]--

--/bgn help
BAGNON_HELP_TITLE = "Bagnon Commands:"
BAGNON_HELP_SHOWBAGS = "/bgn " .. BAGNON_COMMAND_SHOWBAGS .. " - Show/Hide Bagnon."
BAGNON_HELP_SHOWBANK = "/bgn " .. BAGNON_COMMAND_SHOWBANK .. " - Show/Hide Banknon."
BAGNON_HELP_HELP = "/bgn " .. BAGNON_COMMAND_HELP .. " - Display slash commands."
BAGNON_HELP_LIST_RULES = "/bgn " .. BAGNON_COMMAND_LIST_RULES .. " - Lists available rules for searching."

BAGNON_HELP_FIND = "/find <name> - Displays a window with all items matching <name>"
BAGNON_HELP_FINDR = "/findr <rule> - Displays a window with all items in the set defined by <rule>"


--[[ System Messages ]]--

BAGNON_INITIALIZED = "Bagnon initialized.  Type /bagnon or /bgn for commands"
BAGNON_UPDATED = "Bagnon Settings updated to v%s.  Type /bagnon or /bgn for commands"


--[[ UI Text ]]--

--These should probably read Inventory of <player> and Bank of <player> in other versions I guess
BAGNON_INVENTORY_TITLE = "%s's Inventory"
BAGNON_BANK_TITLE = "%s's Bank"

--Bag Button
BAGNON_SHOWBAGS = "Show Bags"
BAGNON_HIDEBAGS = "Hide Bags"

--General Options Menu
BAGNON_MAINOPTIONS_TITLE = "Bagnon Options"
BAGNON_MAINOPTIONS_SHOW = "Show"

--Right Click Menu
BAGNON_OPTIONS_TITLE = "Settings"
BAGNON_OPTIONS_LOCK = "Lock Position"
BAGNON_OPTIONS_BACKGROUND = "Background"
--BAGNON_OPTIONS_REVERSE = "Reverse Bag Ordering"
BAGNON_OPTIONS_COLUMNS = "Columns"
BAGNON_OPTIONS_SPACING = "Spacing"
BAGNON_OPTIONS_SCALE = "Scale"
BAGNON_OPTIONS_OPACITY = "Opacity"
BAGNON_OPTIONS_STRATA = "Layer"
BAGNON_OPTIONS_TOPLEVEL = 'Always On Top'

--Search Frames
BAGNON_SEARCH_NAME = "Named '%s'"
BAGNON_SEARCH_TAG = "Tagged '%s'"


--[[ Tooltips ]]--

BAGNON_SLOT_INFO = '(%d, %d)'

--Title tooltip
BAGNON_TITLE_SHOW_MENU = "<Right-Click> to open up the settings menu."

BAGNON_TAB_TITLE = '%s (%d items)'
BAGNON_TAB_TITLE_EMPTY = '%s (%d empty)'
BAGNON_TAB_TITLE_MIXED = '%s (%d items, %d empty)'
BAGNON_TAB_TOGGLE = "<Click> to toggle the display of this tab's contents"
BAGNON_TAB_SWAP = "Drag on another tab to swap positions"
BAGNON_TAB_NEW_WINDOW = "Drag onto an empty area to display this tab's contents in a window"

--Bag Tooltips
BAGNON_BAGS_HIDE = "<Click> to hide."
BAGNON_BAGS_SHOW = "<Click> to show."

--Search Tooltip
BAGNON_SPOT_TOOLTIP = "<Double-Click> to search."


--[[ Rules ]]--

BAGNON_RULE_ALL = 'All'
BAGNON_RULE_ITEMS = 'Item'
BAGNON_RULE_EMPTY = 'Empty'
BAGNON_RULE_BANK = 'Bank'
BAGNON_RULE_INVENTORY = 'Inventory'
BAGNON_RULE_AMMO_SLOTS = 'Ammo Slot'
BAGNON_RULE_PROFESSION_SLOTS = 'Profession Slot'
BAGNON_RULE_QUEST_ITEM = 'Quest Item'
BAGNON_RULE_BANDAGE = 'Bandage'
BAGNON_RULE_POISON = 'Poison'
BAGNON_RULE_TRASH = 'Trash'


--[[ Item types, the sixth return from GetItemInfo(id) ]]--

BAGNON_TYPE = {}
BAGNON_TYPE['Weapon'] = select(1, GetAuctionItemClasses())
BAGNON_TYPE['Armor'] = select(2, GetAuctionItemClasses())
BAGNON_TYPE['Container'] = select(3, GetAuctionItemClasses())
BAGNON_TYPE['Consumable'] = select(4, GetAuctionItemClasses())
BAGNON_TYPE['Trade Goods'] = select(5, GetAuctionItemClasses())
BAGNON_TYPE['Projectile'] = select(6, GetAuctionItemClasses())
BAGNON_TYPE['Quiver'] = select(7, GetAuctionItemClasses())
BAGNON_TYPE['Recipe'] = select(8, GetAuctionItemClasses())
BAGNON_TYPE['Reagent'] = select(9, GetAuctionItemClasses())
BAGNON_TYPE['Miscellaneous'] = select(10, GetAuctionItemClasses())

--types not listed in GetAuctionItemClasses
BAGNON_TYPE['Quest'] = 'Quest'
BAGNON_TYPE['Key'] = 'Key'


--[[ Subtypes, the seventh return from GetItemInfo(id) ]]--

BAGNON_SUBTYPE = {}

--weapon
BAGNON_SUBTYPE['One-Handed Axes'] = select(1, GetAuctionItemSubClasses(1))
BAGNON_SUBTYPE['Two-Handed Axes'] = select(2, GetAuctionItemSubClasses(1))
BAGNON_SUBTYPE['Bows'] = select(3, GetAuctionItemSubClasses(1))
BAGNON_SUBTYPE['Guns'] = select(4, GetAuctionItemSubClasses(1))
BAGNON_SUBTYPE['One-Handed Maces'] = select(5, GetAuctionItemSubClasses(1))
BAGNON_SUBTYPE['Two-Handed Maces'] = select(6, GetAuctionItemSubClasses(1))
BAGNON_SUBTYPE['Polearms'] = select(7, GetAuctionItemSubClasses(1))
BAGNON_SUBTYPE['One-Handed Swords'] = select(8, GetAuctionItemSubClasses(1))
BAGNON_SUBTYPE['Two-Handed Swords'] = select(9, GetAuctionItemSubClasses(1))
BAGNON_SUBTYPE['Staves'] = select(10, GetAuctionItemSubClasses(1))
BAGNON_SUBTYPE['Fist Weapons'] = select(11, GetAuctionItemSubClasses(1))
--BAGNON_SUBTYPE['Miscellaneous'] = select(12, GetAuctionItemSubClasses(1))
BAGNON_SUBTYPE['Daggers'] = select(13, GetAuctionItemSubClasses(1))
BAGNON_SUBTYPE['Thrown'] = select(14, GetAuctionItemSubClasses(1))
BAGNON_SUBTYPE['Crossbows'] = select(15, GetAuctionItemSubClasses(1))
BAGNON_SUBTYPE['Wands'] = select(16, GetAuctionItemSubClasses(1))
BAGNON_SUBTYPE['Fishing Pole'] = select(17, GetAuctionItemSubClasses(1))

--armor
--BAGNON_SUBTYPE['Miscellaneous'] = select(1, GetAuctionItemSubClasses(2))
BAGNON_SUBTYPE['Cloth'] = select(2, GetAuctionItemSubClasses(2))
BAGNON_SUBTYPE['Leather'] = select(3, GetAuctionItemSubClasses(2))
BAGNON_SUBTYPE['Mail'] = select(4, GetAuctionItemSubClasses(2))
BAGNON_SUBTYPE['Plate'] = select(5, GetAuctionItemSubClasses(2))
BAGNON_SUBTYPE['Shields'] = select(6, GetAuctionItemSubClasses(2))
BAGNON_SUBTYPE['Librams'] = select(7, GetAuctionItemSubClasses(2))
BAGNON_SUBTYPE['Idols'] = select(8, GetAuctionItemSubClasses(2))
BAGNON_SUBTYPE['Totems'] = select(9, GetAuctionItemSubClasses(2))

--bag
BAGNON_SUBTYPE['Bag'] = select(1, GetAuctionItemSubClasses(3))
BAGNON_SUBTYPE['Soul Bag'] = select(2, GetAuctionItemSubClasses(3))
BAGNON_SUBTYPE['Herb Bag'] = select(3, GetAuctionItemSubClasses(3))
BAGNON_SUBTYPE['Enchanting Bag'] = select(4, GetAuctionItemSubClasses(3))
BAGNON_SUBTYPE['Engineering Bag'] = select(5, GetAuctionItemSubClasses(3))
BAGNON_SUBTYPE['Gem Bag'] = select(6, GetAuctionItemSubClasses(3))
BAGNON_SUBTYPE['Mining Bag'] = select(7, GetAuctionItemSubClasses(3))

--projectile
BAGNON_SUBTYPE['Arrow'] = select(1, GetAuctionItemSubClasses(6))
BAGNON_SUBTYPE['Bullet'] = select(2, GetAuctionItemSubClasses(6))

--quiver
BAGNON_SUBTYPE['Quiver'] = select(1, GetAuctionItemSubClasses(7))
BAGNON_SUBTYPE['Ammo Pouch'] = select(2, GetAuctionItemSubClasses(7))

--recipe
BAGNON_SUBTYPE['Book'] = select(1, GetAuctionItemSubClasses(8))
BAGNON_SUBTYPE['Leatherworking'] = select(2, GetAuctionItemSubClasses(8))
BAGNON_SUBTYPE['Tailoring'] = select(3, GetAuctionItemSubClasses(8))
BAGNON_SUBTYPE['Engineering'] = select(4, GetAuctionItemSubClasses(8))
BAGNON_SUBTYPE['Blacksmithing'] = select(5, GetAuctionItemSubClasses(8))
BAGNON_SUBTYPE['Cooking'] = select(6, GetAuctionItemSubClasses(8))
BAGNON_SUBTYPE['Alchemy'] = select(7, GetAuctionItemSubClasses(8))
BAGNON_SUBTYPE['First Aid'] = select(8, GetAuctionItemSubClasses(8))
BAGNON_SUBTYPE['Enchanting'] = select(9, GetAuctionItemSubClasses(8))
BAGNON_SUBTYPE['Fishing'] = select(10, GetAuctionItemSubClasses(8))
BAGNON_SUBTYPE['Jewelcrafting'] = select(11, GetAuctionItemSubClasses(8))

--subtypes not listed in GetAuctionItemSubClasses
BAGNON_SUBTYPE['Devices'] = 'Devices'
BAGNON_SUBTYPE['Junk'] = 'Junk'
BAGNON_SUBTYPE['Key'] = 'Key'
BAGNON_SUBTYPE['Parts'] = 'Parts'
BAGNON_SUBTYPE['Explosives'] = 'Explosives'
BAGNON_SUBTYPE['Gems'] = 'Gems'


--[[ Strings ]]--

BAGNON_STRING_BANDAGE = 'bandage'
BAGNON_STRING_POISON = 'poison'