--[[
	slash.lua
		Sage's slash command handler
		I intend that most commands should be set by an options menu, and not here.
		I really think only lock/unlock, scale, and setalpha are ones that should always be present, as they are commands I use frequently.
--]]

local function GetRestofMessage(args)
	if args[2] then
		local name = args[2]
		for i = 3, #args do
			name = name .. ' ' .. args[i]
		end
		return name
	end
end

local function printMsg(msg)
	ChatFrame1:AddMessage(msg or 'nil')
end

--Display commands
local function ShowCommands()
	SMsg(SAGE_COMMANDS)

	printMsg(SAGE_UNIT_DEFINITION)
	printMsg(SAGE_COMMAND_HELP)
	printMsg(SAGE_COMMAND_LOCK)
	printMsg(SAGE_COMMAND_UNLOCK)
	printMsg(SAGE_COMMAND_SCALE)
	printMsg(SAGE_COMMAND_SETALPHA)
	printMsg(SAGE_COMMAND_STICKY)
	printMsg(SAGE_COMMAND_TEXT)
	printMsg(SAGE_COMMAND_PERCENTS)
	printMsg(SAGE_COMMAND_SETWIDTH)
	printMsg(SAGE_COMMAND_RESET)
end

local function ShowMenuOrHelp()
	if SageOptions then
		SageOptions:Show()
	else
		if SageOptions then
			SageOptions:Show()
		else
			local enabled = select(4, GetAddOnInfo("Sage_Options"))
			if enabled then
				LoadAddOn("Sage_Options")
			else
				ShowCommands()
			end
		end	
	end
end

--Slash handler
SlashCmdList["SageCOMMAND"] = function(msg)
	if not msg or msg == "" then
		ShowMenuOrHelp()
	else
		local args = {strsplit(' ', msg)}
		local cmd = args[1]:lower()

		if cmd == "help" or cmd == '?' then
			ShowCommands()
		elseif cmd == "lock" then
			Sage.SetLock(true)
		elseif cmd == "unlock" then
			Sage.SetLock(nil)
		elseif cmd == "scale" then
			local size = #args
			for i = 2, size-1 do
				Sage.ForFrame(args[i]:lower(), SageFrame.SetFrameScale, tonumber(args[size]) or 1, true)
			end
		elseif cmd == "setalpha" then
			local size = #args
			for i = 2, size-1 do
				Sage.ForFrame(args[i]:lower(), SageFrame.SetFrameOpacity, tonumber(args[size]) or 1, true)
			end
		elseif cmd == "stickyframes" then
			Sage.SetSticky(args[2]:lower() == 'on')
		elseif cmd == "text" then
			Sage.ShowText(args[2]:lower() == 'on')
		elseif cmd == "percents" then
			Sage.ShowPercents(args[2]:lower() == 'on')
		elseif cmd == "setwidth" then
			local size = #args
			for i = 2, size-1 do
				Sage.ForFrame(args[i]:lower(), SageFrame.SetFrameWidth, tonumber(args[size]))
			end
		elseif cmd == "reset" then
			SProfile.Reset()
		else
			SMsg(format(SAGE_UNKNOWN_COMMAND, cmd))
		end
	end
end
SLASH_SageCOMMAND1 = "/sage"
SLASH_SageCOMMAND2 = "/sg"