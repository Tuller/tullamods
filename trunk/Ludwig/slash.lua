--[[ 
	slash.lua
		Slash command handler for Ludwig
		
	Commands:
		/lw or /ludwig
			start of a command, shows the UI if its enabled
		/lw refresh
			resets the database
		/lw minquality <value>
			sets the minimum quality of items to be viewable
		/lw <name>
			prints a list of items matching <name>
--]]

local L = LUDWIG_LOCALS

local function LMsg(msg)
	ChatFrame1:AddMessage(format('|cFF00EE00Ludwig|r: %s', msg or 'nil'))
end

local function PrintMsg(msg)
	ChatFrame1:AddMessage(msg or 'nil')
end

local function PrintList(name, list, startTime)
	LMsg(format(L["There are %d items matching '%s':"], #list, name))
	for i, link in ipairs(list) do 
		PrintMsg(Ludwig_GetHyperLink(link))
		if i > 9 then break end
	end
	PrintMsg(format(L['Generated in %.3f seconds'], GetTime() - startTime))
end

local function ListItemsOfName(name)
	local startTime = GetTime()
	local list = Ludwig_GetItems(name)
	
	if list then
		PrintList(name, list, startTime)
	else
		LMsg(format(L["There are %d items matching '%s':"], name))
	end
end

--[[ Initialize Slash Command Handler ]]--
SlashCmdList["LudwigSlashCOMMAND"] = function(msg)
	if not msg or msg == "" and LudwigUIParent then
		LudwigUIParent:Show()
	else
		local cmd, arg1 = string.match(msg:lower(), "%-(%w+)%s?(%d*)")
		if cmd then
			if cmd == 'refresh' then
				Ludwig_Reload()
				LMsg(L['Database refreshed'])
			elseif cmd == 'minquality' then
				if tonumber(arg1) then 
					Ludwig_SetMinQuality(tonumber(arg1))
					LMsg(format(L['Quality threshold set to %d'], arg1))
				end
			else
				LMsg(format(L["'%s' is an unknown command"] , cmd))
			end
		else
			ListItemsOfName(msg)
		end
	end
end
SLASH_LudwigSlashCOMMAND1 = '/lw'
SLASH_LudwigSlashCOMMAND2 = '/ludwig'