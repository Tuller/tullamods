--[[
	slash
		Slash command handler for Bongos
		All commands start with /bob or /bongos
--]]

local function msg(message)
	ChatFrame1:AddMessage(message or 'nil', 0,1,0.4)
end

--Display commands
local function ShowCommands()
	msg(BONGOS_COMMANDS)
	msg(BONGOS_SHOW_OPTIONS)
	msg(BONGOS_SHOW_HELP)
	
	--bar commands
	msg(BONGOS_LOCK)
	msg(BONGOS_UNLOCK)
	msg(BONGOS_SHOW)
	msg(BONGOS_HIDE)
	msg(BONGOS_TOGGLE)
	msg(BONGOS_SET_SCALE)
	msg(BONGOS_SET_OPACITY)
	msg(BONGOS_SET_STICKY)

	--Profile commands
	msg(BONGOS_RESET)
end

local function ShowOptionsMenu()
	if BongosOptions then
		BongosOptions:Show()
	else
		local enabled = select(4, GetAddOnInfo('Bongos_Options'))
		if enabled then
			LoadAddOn('Bongos_Options')
		else
			ShowCommands()
		end
	end
end

--Slash handler
SlashCmdList["BongosCOMMAND"] = function(msg)
	if msg == '' then
		ShowOptionsMenu()	
	else
		local args = {strsplit(' ', msg)}
		local cmd = args[1]:lower()

		if cmd == "help" or cmd == "?" then
			ShowCommands()
		elseif cmd == "lock" then
			Bongos.SetLock(true)
		elseif cmd == "unlock" then
			Bongos.SetLock(nil)
		elseif cmd == "stickybars" then
			Bongos.SetSticky(args[2]:lower() == "on")
		elseif cmd == "show" then
			for i = 2, #args do
				Bongos.ForBar(args[i]:lower(), BBar.ShowFrame)
			end
		elseif cmd == "hide" then
			for i = 2, #args do
				Bongos.ForBar(args[i]:lower(), BBar.HideFrame)
			end
		elseif cmd == "toggle" then
			for i = 2, #args do
				Bongos.ForBar(args[i]:lower(), BBar.ToggleFrame)
			end
		elseif cmd == "scale" then
			local scale = tonumber(args[#args])
			for i = 2, #args - 1 do
				Bongos.ForBar(args[i]:lower(), BBar.SetFrameScale, scale)
			end
		elseif cmd == "setalpha" then
			local alpha = tonumber(args[#args])
			for i = 2, #args - 1 do
				Bongos.ForBar(args[i]:lower(), BBar.SetFrameAlpha, alpha)
			end
		elseif cmd == "reset" then
			BProfile.Reset()
		else
			BMsg(format(BONGOS_UNKNOWN_COMMAND, cmd or 'nil'))
		end
	end
end
SLASH_BongosCOMMAND1 = "/bongos"
SLASH_BongosCOMMAND2 = "/bob"