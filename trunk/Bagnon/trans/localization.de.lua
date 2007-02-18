--[[
	Bagnon Localization file
	
	TODO:
		Add some frame strings and other things
		I could probably Babelfish the translation, but most likely it would insult someone's 
			mother or something.
--]]

--[[
	German
		Credit goes to Sarkan on Curse and ArtureLeCoiffeur on ui.worldofwar.net
--]]


if (GetLocale() ~= "deDE") then return end

--[[ Keybindings ]]--

BINDING_HEADER_BAGNON = "Bagnon"
BINDING_NAME_BAGNON_TOGGLE = "Inventar umschalte"
BINDING_NAME_BANKNON_TOGGLE = "Bank umschalten"

--[[ Slash Commands ]]--

--[[
These may or may not work, so I've decided to disable non english versions of slash commands

BAGNON_COMMAND_HELP = "hilfe";
BAGNON_COMMAND_SHOWBAGS = "taschen";
BAGNON_COMMAND_SHOWBANK = "bank";
--]]

--[[ Messages from the slash commands ]]--

--/bgn help
BAGNON_HELP_TITLE = "Bagnon-Befehle:"
BAGNON_HELP_SHOWBAGS = "/bgn " .. BAGNON_COMMAND_SHOWBAGS .. " - Bagnon zeigen/verstecken."
BAGNON_HELP_SHOWBANK = "/bgn " .. BAGNON_COMMAND_SHOWBANK .. " - Banknon zeigen/verstecken."
BAGNON_HELP_HELP = "/bgn " .. BAGNON_COMMAND_HELP .. " - Schrägstrich-Befehle anzeigen."

BAGNON_HELP_FIND = "/find <name> - Zeigt ein Fenster mit allen Gegenständen, deren Name <name> enthält"
BAGNON_HELP_FINDR = "/findr <regel> - Zeigt ein Fenster mit allen Gegenständen, die durch die Regeln <regel> ausgewählt werden"

--[[ System Messages ]]--

BAGNON_INITIALIZED = "Bagnon initialisiert.  /bagnon und /bgn aktiviert"
BAGNON_UPDATED = "Bagnon-Einstellungen auf v%s aktualisiert.  /bagnon und /bgn aktiviert"

--[[ UI Text ]]--

--Titles

--These should probably read Inventory of <player> and Bank of <player> in other versions I guess
BAGNON_INVENTORY_TITLE = "Inventar von %s"
BAGNON_BANK_TITLE = "Bankfach von %s"

--Bag Button
BAGNON_SHOWBAGS = "+ Taschen";
BAGNON_HIDEBAGS = "- Taschen";

--Right Click Menu
BAGNON_OPTIONS_TITLE = "Einstellungen"
BAGNON_OPTIONS_LOCK = "Position verriegeln"
BAGNON_OPTIONS_BACKGROUND = "Hintergrund"
--BAGNON_OPTIONS_REVERSE = "umgekehrte Taschenanordnung"
BAGNON_OPTIONS_COLUMNS = "Spalten"
BAGNON_OPTIONS_SPACING = "Abstand"
BAGNON_OPTIONS_SCALE = "Skalierung"
BAGNON_OPTIONS_OPACITY = "Abdeckung"
BAGNON_OPTIONS_STRATA = "Layer"
BAGNON_OPTIONS_TOPLEVEL = 'Immer oben'

--Search Frames
BAGNON_SEARCH_NAME = "Name '%s'"
BAGNON_SEARCH_TAG = "Markierung '%s'"

--[[ Tooltips ]]--

--Title tooltip
BAGNON_TITLE_SHOW_MENU = "<Rechts-Klick> Um Einstellungs Men\195\188 zu zeigen";

--Bag Tooltips
BAGNON_BAGS_HIDE = "<Klick> zum verstecken.";
BAGNON_BAGS_SHOW = "<Klick> zum zeigen.";

--Search Tooltip
BAGNON_SPOT_TOOLTIP = "<Doppelklick> zum Suchen."

--[[ Rules ]]--

--[[

BAGNON_RULE_ALL = 'Alles'
BAGNON_RULE_ITEMS = 'Gegenstände'
BAGNON_RULE_EMPTY = 'Leer'
BAGNON_RULE_BANK = 'Bank'
BAGNON_RULE_INVENTORY = 'Inventory'
BAGNON_RULE_AMMO_SLOTS = 'Munitionsbeutel'
BAGNON_RULE_PROFESSION_SLOTS = 'Profession Slot'
BAGNON_RULE_QUEST_ITEM = "Quest-Gegenstände"
BAGNON_RULE_BANDAGE = 'Verbände'
BAGNON_RULE_POISON = 'Gifte'
BAGNON_RULE_TRASH = "Müll"

--types not listed in GetAuctionItemClasses
BAGNON_TYPE['Quest'] = "Quest"
BAGNON_TYPE['Key'] = 'Key'

--subtypes not listed in GetAuctionItemSubClasses
BAGNON_SUBTYPE['Devices'] = 'Devices'
BAGNON_SUBTYPE['Junk'] = 'Junk'
BAGNON_SUBTYPE['Key'] = 'Key'
BAGNON_SUBTYPE['Parts'] = 'Parts'
BAGNON_SUBTYPE['Explosives'] = 'Explosives'
BAGNON_SUBTYPE['Gems'] = 'Gems'

BAGNON_STRING_BANDAGE = 'verband'
BAGNON_STRING_POISON = 'gift'

]]--