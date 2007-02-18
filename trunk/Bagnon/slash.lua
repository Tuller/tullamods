--[[
	Slash
		This is the slash command handler for Bagnon
--]]

local function DisplayHelp()
	BagnonMsg(BAGNON_HELP_TITLE)
	BagnonMsg(BAGNON_HELP_HELP)
	BagnonMsg(BAGNON_HELP_SHOWBAGS)
	BagnonMsg(BAGNON_HELP_SHOWBANK)
end

local function ShowOptionsMenu()
	local enabled = select(4, GetAddOnInfo('Bagnon_Options'))
	if enabled then
		if not IsAddOnLoaded('Bagnon_Options') then
			LoadAddOn('Bagnon_Options')
		end
		BagnonOptions:Show()
	else
		DisplayHelp()
	end	
end

SlashCmdList['BagnonCOMMAND'] = function(msg)
	if not msg or msg == '' then
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
		end
	end
end

SLASH_BagnonCOMMAND1 = '/bagnon'
SLASH_BagnonCOMMAND2 = '/bgn'