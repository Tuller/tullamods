--[[
	KeyBound
		An intuitive keybindings sytem
		Based off of ClickBinder by Gello and TrinityBinder by Maul

		Functions needed to implement
			button:GetHotkey() - returns the current hotkey assigned to the given button

		Functions to implemnt if using a custom keybindings system:
			button:SetKey(key) - binds the given key to the given button
			button:FreeKey(key) - unbinds the given key from all other buttons
			button:ClearBindings() - removes all keys bound to the given button
			button:GetBindings() - returns a string listing all bindings of the given button
			button:GetActionName() - what we're binding to, used for printing
--]]

KeyBound = DongleStub("Dongle-1.0"):New("KeyBound")
local L = KEYBOUND_LOCALS

--[[ Bindframe functions ]]--

local function Binder_ToBinding(button)
	return format("CLICK %s:LeftButton", button:GetName())
end

local function Binder_FreeKey(button, key)
	local msg
	if button.FreeKey then
		local action = button:FreeKey(key)
		if button:FreeKey(key) then
			msg = format(L.UnboundKey, GetBindingText(key, "KEY_"), action)
		end
	else
		local action = GetBindingAction(key)
		if action and action ~= "" and action ~= Binder_ToBinding(button) then
			msg = format(L.UnboundKey, GetBindingText(key, "KEY_"), action)
		end
	end

	if msg then
		UIErrorsFrame:AddMessage(msg, 1, 1, 0, 1, UIERRORS_HOLD_TIME)
	end
end

local function Binder_SetKey(button, key)
	if not InCombatLockdown() then
		Binder_FreeKey(button, key)

		local msg
		if button.SetKey then
			button:SetKey(key)
			msg = format(L.BoundKey, GetBindingText(key, "KEY_"), button:GetActionName())
		else
			SetBindingClick(key, button:GetName(), "LeftButton")
			msg = format(L.BoundKey, GetBindingText(key, "KEY_"), button:GetName())
		end
		SaveBindings(GetCurrentBindingSet())
		UIErrorsFrame:AddMessage(msg, 1, 1, 1, 1, UIERRORS_HOLD_TIME)
	else
		UIErrorsFrame:AddMessage(L.CannotBindInCombat, 1, 0, 0, 1, UIERRORS_HOLD_TIME)
	end
end

local function Binder_ClearBindings(button)
	if not InCombatLockdown() then
		local msg
		if button.ClearBindings then
			button:ClearBindings()
			msg = format(L.ClearedBindings, button:GetActionName())
		else
			local binding = Binder_ToBinding(button)
			while GetBindingKey(binding) do
				SetBinding(GetBindingKey(binding), nil)
			end
			msg = format(L.ClearedBindings, button:GetName())
		end
		SaveBindings(GetCurrentBindingSet())
		UIErrorsFrame:AddMessage(msg, 1, 1, 1, 1, UIERRORS_HOLD_TIME)
	else
		UIErrorsFrame:AddMessage(L.CannotBindInCombat, 1, 0, 0, 1, UIERRORS_HOLD_TIME)
	end
end

local function Binder_GetBindings(button)
	if button.GetBindings then
		return button:GetBindings()
	end

	local keys
	local binding = Binder_ToBinding(button)
	for i = 1, select("#", GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if keys then
			keys = keys .. ", " .. GetBindingText(hotKey,"KEY_")
		else
			keys = GetBindingText(hotKey,"KEY_")
		end
	end

	return keys
end

local function Binder_OnKeyDown(self, key)
	local button = self.button
	if not button then return end

	if key == "UNKNOWN" or key == "SHIFT" or key == "CTRL"	or key == "ALT" then return end

	local screenshotKey = GetBindingKey("SCREENSHOT")
	if screenshotKey and key == screenshotKey then
		Screenshot()
		return
	end

	local openChatKey = GetBindingKey("OPENCHAT")
	if openChatKey and key == openChatKey then
		ChatFrameEditBox:Show()
		return
	end

	if key == "LeftButton" or key == "RightButton" then
		return
	elseif key == "MiddleButton" then
		key = "BUTTON3"
	elseif key == "Button4" then
		key = "BUTTON4"
	elseif key == "Button5" then
		key = "BUTTON5"
	end

	if key == "ESCAPE" then
		Binder_ClearBindings(button)
		KeyBound:Set(button)
		return
	end

	if IsShiftKeyDown() then
		key = "SHIFT-" .. key
	end
	if IsControlKeyDown() then
		key = "CTRL-" .. key
	end
	if IsAltKeyDown() then
		key = "ALT-" .. key
	end

	Binder_SetKey(button, key)
	KeyBound:Set(button)
end

local function Binder_OnEnter(self)
	local button = self.button
	if button and not InCombatLockdown() then
		if self:GetRight() >= (GetScreenWidth() / 2) then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		else
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		end
		if(button.GetActionName) then
			GameTooltip:SetText(button:GetActionName(), 1, 1, 1)
		else
			GameTooltip:SetText(button:GetName(), 1, 1, 1)
		end

		local bindings = Binder_GetBindings(button)
		if bindings then
			GameTooltip:AddLine(bindings, 0, 1, 0)
			GameTooltip:AddLine(L.ClearTip)
		else
			GameTooltip:AddLine(L.NoKeysBoundTip, 0, 1, 0)
		end
		GameTooltip:Show()
	else
		GameTooltip:Hide()
	end
end

local function Binder_OnLeave(self)
	KeyBound:Set(nil)
	GameTooltip:Hide()
end

local function Binder_OnMouseWheel(self, arg1)
	if arg1 > 0 then
		Binder_OnKeyDown(self, "MOUSEWHEELUP")
	else
		Binder_OnKeyDown(self, "MOUSEWHEELDOWN")
	end
end

local function Binder_Create()
	local binder = CreateFrame("Button")
	binder:RegisterForClicks("anyUp")
	binder:SetFrameStrata("DIALOG")
	binder:EnableKeyboard(true)
	binder:EnableMouseWheel(true)

	local bg = binder:CreateTexture()
	bg:SetTexture(0, 0, 0, 0.5)
	bg:SetAllPoints(binder)

	local text = binder:CreateFontString("OVERLAY")
	text:SetFontObject("GameFontNormalLarge")
	text:SetTextColor(0, 1, 0)
	text:SetAllPoints(binder)
	binder.text = text

	binder:SetScript("OnClick", Binder_OnKeyDown)
	binder:SetScript("OnKeyDown", Binder_OnKeyDown)
	binder:SetScript("OnMouseWheel", Binder_OnMouseWheel)
	binder:SetScript("OnEnter", Binder_OnEnter)
	binder:SetScript("OnLeave", Binder_OnLeave)
	binder:SetScript("OnHide", function() KeyBound:Set(nil) end)
	binder:Hide()

	return binder
end


--[[ KeyBound ]]--

--events
function KeyBound:Enable()
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterMessage("KEYBOUND_ENABLED")
	self:RegisterMessage("KEYBOUND_DISABLED")
end

function KeyBound:PLAYER_REGEN_ENABLED()
	if self.enabled then
		UIErrorsFrame:AddMessage(L.CombatBindingsEnabled, 1, 0, 0, 1, UIERRORS_HOLD_TIME)
	end
end

function KeyBound:PLAYER_REGEN_DISABLED()
	if self.enabled then
		self:Set(nil)
		UIErrorsFrame:AddMessage(L.CombatBindingsDisabled, 1, 0, 0, 1, UIERRORS_HOLD_TIME)
	end
end

function KeyBound:Toggle()
	if self:IsShown() then
		self:Deactivate()
	else
		self:Activate()
	end
end

function KeyBound:Activate()
	if(not self:IsShown()) then
		if(InCombatLockdown()) then
			UIErrorsFrame:AddMessage(L.CannotBindInCombat, 1, 0, 0, 1, UIERRORS_HOLD_TIME)
		else
			self.enabled = true
			if not self.frame then
				self.frame = Binder_Create()
			end
			self:Set(nil)
			self:TriggerMessage("KEYBOUND_ENABLED")
			UIErrorsFrame:AddMessage(L.Enabled, 1, 1, 0, 1, UIERRORS_HOLD_TIME)
		end
	end
end

function KeyBound:Deactivate()
	if(self:IsShown()) then
		self.enabled = nil
		self:Set(nil)
		self:TriggerMessage("KEYBOUND_DISABLED")
		UIErrorsFrame:AddMessage(L.Disabled, 1, 1, 0, 1, UIERRORS_HOLD_TIME)
	end
end

function KeyBound:IsShown()
	return self.enabled
end

function KeyBound:Set(button)
	local bindFrame = self.frame

	if button and self:IsShown() and not InCombatLockdown() then
		bindFrame.button = button
		bindFrame:SetAllPoints(button)

		bindFrame.text:SetFontObject("GameFontNormalLarge")
		bindFrame.text:SetText(button:GetHotkey())
		if bindFrame.text:GetStringWidth() > bindFrame:GetWidth() then
			bindFrame.text:SetFontObject("GameFontNormal")
		end
		bindFrame:Show()
		Binder_OnEnter(bindFrame)
	elseif bindFrame then
		bindFrame.button = nil
		bindFrame:ClearAllPoints()
		bindFrame:Hide()
	end
end

function KeyBound:ToShortKey(key)
	if key then
		key = key:upper()
		key = key:gsub(" ", "")
		key = key:gsub("ALT%-", "A")
		key = key:gsub("CTRL%-", "C")
		key = key:gsub("SHIFT%-", "S")

		key = key:gsub("NUMPAD", "N")

		key = key:gsub("BACKSPACE", "BS")
		key = key:gsub("PLUS", "%+")
		key = key:gsub("MINUS", "%-")
		key = key:gsub("MULTIPLY", "%*")
		key = key:gsub("DIVIDE", "%/")
		key = key:gsub("HOME", "HN")
		key = key:gsub("INSERT", "Ins")
		key = key:gsub("DELETE", "Del")
		key = key:gsub("BUTTON3", "M3")
		key = key:gsub("BUTTON4", "M4")
		key = key:gsub("BUTTON5", "M5")
		key = key:gsub("MOUSEWHEELDOWN", "WD")
		key = key:gsub("MOUSEWHEELUP", "WU")
		key = key:gsub("PAGEDOWN", "PD")
		key = key:gsub("PAGEUP", "PU")

		return key
	end
end

SlashCmdList["KeyBoundSlashCOMMAND"] = function() KeyBound:Toggle() end
SLASH_KeyBoundSlashCOMMAND1 = "/keybound"
SLASH_KeyBoundSlashCOMMAND1 = "/kb"