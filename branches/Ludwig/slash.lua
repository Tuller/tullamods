--[[
	slash.lua
		Slash command handler for Ludwig

	Commands:
		/lw or /ludwig
			start of a command, shows the UI if its enabled
		/lw -refresh
			resets the database
		/lw <name>
			prints a list of items matching <name>
--]]

local L = LUDWIG_LOCALS
local MAX_DISPLAY = 9

local function LMsg(msg)
	ChatFrame1:AddMessage(format("|cFF00EE00Ludwig|r: %s", tostring(msg)))
end

local function PrintMsg(msg)
	ChatFrame1:AddMessage(tostring(msg))
end

local function PrintList(name, list, startTime)
	LMsg(format(L.NumMatching, #list, name))
	for i = 1, min(#list, MAX_DISPLAY) do
		PrintMsg(Ludwig:GetItemLink(list[i]))
	end
	PrintMsg(format(L.GenTime, GetTime() - startTime))
end

local function ListItemsOfName(name)
	local startTime = GetTime()
	local list = Ludwig:GetItems(name)
	if list then
		PrintList(name, list, startTime)
	else
		LMsg(format(L.NoMatchingItems, name))
	end
end

SlashCmdList["LudwigSlashCOMMAND"] = function(msg)
	if not msg or msg == "" then
		if(LudwigFrame and LudwigFrame:IsShown()) then
			HideUIPanel(LudwigFrame)
		elseif(LudwigFrame) then
			ShowUIPanel(LudwigFrame)
		end
	else
		local cmd = msg:lower():match("%-%-(%w+)")
		if cmd then
			if cmd == "refresh" then
				Ludwig:ReloadDB()
				LMsg(L.DBRefreshed)
			elseif tonumber(cmd) then
				SetItemRef(format("item:%d", tonumber(cmd)))
			else
				LMsg(format(L.UnknownCommand, cmd))
			end
		else
			ListItemsOfName(msg)
		end
	end
end
SLASH_LudwigSlashCOMMAND1 = "/lw"
SLASH_LudwigSlashCOMMAND2 = "/ludwig"