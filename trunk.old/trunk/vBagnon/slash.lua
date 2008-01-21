--[[
	Slash
		This is the slash command handler for Bagnon
--]]

local function DisplayRules()
	local categories = {}
	for name in pairs(BagnonRule) do
		table.insert(categories, name)
	end
	table.sort(categories)

	for _, name in ipairs(categories) do
		BagnonMsg(name)
	end
end

local function DisplayHelp()
	BagnonMsg(BAGNON_HELP_TITLE)
	BagnonMsg(BAGNON_HELP_HELP)
	BagnonMsg(BAGNON_HELP_SHOWBAGS)
	BagnonMsg(BAGNON_HELP_SHOWBANK)
	BagnonMsg(BAGNON_HELP_FIND)
	BagnonMsg(BAGNON_HELP_FINDR)
	BagnonMsg(BAGNON_HELP_LIST_RULES)
end

local function ShowOptionsMenu()
	local enabled = select(4, GetAddOnInfo("vBagnon_Options"))
	if enabled then
		if not IsAddOnLoaded("vBagnon_Options") then
			LoadAddOn("vBagnon_Options")
		end
		BagnonOptions:Show()
	else
		DisplayHelp()
	end	
end

SlashCmdList["BagnonCOMMAND"] = function(msg)
	if not msg or msg == "" then
		ShowOptionsMenu()
	else
		local args = strsplit(' ', msg)
		local cmd = select(1, args):lower()
		
		if cmd == BAGNON_COMMAND_HELP then
			DisplayHelp()
		elseif cmd == BAGNON_COMMAND_SHOWBANK then
			Bagnon_ToggleBank()
		elseif cmd == BAGNON_COMMAND_SHOWBAGS then
			Bagnon_ToggleInventory()
		elseif cmd == BAGNON_COMMAND_LIST_RULES then
			DisplayRules()
		end
	end
end

SLASH_BagnonCOMMAND1 = "/bagnon"
SLASH_BagnonCOMMAND2 = "/bgn"