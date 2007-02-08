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
--]]

--local key, button
local KeyBound, enabled


--[[ Conversions ]]--

local function Binder_ToBinding(button)
	return 'CLICK ' .. button:GetName() .. ':LeftButton'
end


--[[ Binding Functions ]]--

local function Binder_FreeKey(button, key)
	if button.FreeKey then
		local action = button:FreeKey(key)
		if button:FreeKey(key) then
			BMsg(format(BONGOS_BINDINGS_UNBOUND_FROM_ACTION, GetBindingText(key, 'KEY_'), action))
		end
	else
		local action = GetBindingAction(key)
		if action and action ~= '' and action ~= Binder_ToBinding(button) then
			BMsg(format(BONGOS_BINDINGS_UNBOUND_FROM_ACTION, GetBindingText(key, 'KEY_'), action))
		end
	end
end

local function Binder_SetKey(button, key)
	if not InCombatLockdown() then
		Binder_FreeKey(button, key)

		if button.SetKey then
			button:SetKey(key)
		else
			SetBindingClick(key, button:GetName(), 'LeftButton')
			SaveBindings(GetCurrentBindingSet())
		end
		BMsg(format(BONGOS_KEY_BOUND_TO_ACTION, GetBindingText(key, 'KEY_'), button:GetName()))
	else
		BMsg(BONGOS_CANNOT_BIND_IN_COMBAT)
	end
end

local function Binder_ClearBindings(button)
	if not InCombatLockdown() then
		if button.ClearBindings then
			button:ClearBindings()
		else
			local binding = Binder_ToBinding(button)
			while GetBindingKey(binding) do
				SetBinding(GetBindingKey(binding), nil)
			end
			SaveBindings(GetCurrentBindingSet())
		end
		BMsg(format(BONGOS_BINDINGS_CLEARED, button:GetName()))
	else
		BMsg(BONGOS_CANNOT_BIND_IN_COMBAT)
	end
end

local function Binder_GetBindings(button)
	if button.GetBindings then
		return button:GetBindings()
	end

	local keys
	local binding = Binder_ToBinding(button)
	for i = 1, select('#', GetBindingKey(binding)) do	
		local hotKey = select(i, GetBindingKey(binding))
		if keys then
			keys = keys .. ', ' .. GetBindingText(hotKey,'KEY_')
		else
			keys = GetBindingText(hotKey,'KEY_')
		end
	end
	
	return keys
end


--[[ OnX Functions ]]--

function Binder_OnKeyDown(binder, newKey)
	local button = binder.button
	if not button then return end
	
	if newKey == 'UNKNOWN' or newKey == 'SHIFT' or newKey == 'CTRL' or newKey == 'ALT' then return end

	local screenshotKey = GetBindingKey('SCREENSHOT')
	if screenshotKey and newKey == screenshotKey then
		Screenshot()
		return
	end

	local openChatKey = GetBindingKey('OPENCHAT')
	if openChatKey and newKey == openChatKey then
		ChatFrameEditBox:Show()
		return
	end

	if newKey == "LeftButton" or newKey == "RightButton" then
		return
	elseif newKey == "MiddleButton" then
		newKey = "BUTTON3"
	elseif newKey == "Button4" then
		newKey = "BUTTON4"
	elseif newKey == "Button5" then
		newKey = "BUTTON5"
	end

	if newKey == 'ESCAPE' then
		Binder_ClearBindings(button)
		KeyBound_Set(button)
		return
	end

	local key = newKey
	if IsShiftKeyDown() then
		key = 'SHIFT-' .. key
	end
	if IsControlKeyDown() then
		key = 'CTRL-' .. key
	end
	if IsAltKeyDown() then
		key = 'ALT-' .. key
	end

	Binder_SetKey(button, key)
	KeyBound_Set(button)
end

local function Binder_OnEnter(self)
	local button = self.button
	if button and not InCombatLockdown() then
		if self:GetRight() >= (GetScreenWidth() / 2) then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		else
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		end
		GameTooltip:SetText(button:GetName(), 1, 1, 1)
	
		local bindings = Binder_GetBindings(button)
		if bindings then
			GameTooltip:AddLine(bindings, 0, 1, 0)
			GameTooltip:AddLine(BONGOS_BINDINGS_CLEAR_HELP)
		else
			GameTooltip:AddLine(BONGOS_BINDINGS_NO_KEYS_BOUND, 0, 1, 0)
		end
		GameTooltip:Show()
	else
		GameTooltip:Hide()
	end
end

local function Binder_OnLeave(self)
	KeyBound_Set(nil)
	GameTooltip:Hide()
end


--[[ Constructor ]]--

local function Binder_Create()
	local binder = CreateFrame('Button')
	binder:RegisterForClicks('anyUp')
	binder:SetFrameStrata('DIALOG')
	binder:EnableKeyboard(true)
	binder:EnableMouseWheel(true)

	local bg = binder:CreateTexture()
	bg:SetTexture(0, 0, 0, 0.5)
	bg:SetAllPoints(binder)

	local text = binder:CreateFontString('OVERLAY')
	text:SetFontObject('GameFontNormalLarge')
	text:SetTextColor(0, 1, 0)
	text:SetAllPoints(binder)
	binder.text = text

	binder:SetScript('OnClick', function() Binder_OnKeyDown(this, arg1) end)
	binder:SetScript('OnKeyDown', function() Binder_OnKeyDown(this, arg1) end)
	binder:SetScript('OnMouseWheel', function()
		if arg1 > 0 then
			Binder_OnKeyDown(this, 'MOUSEWHEELUP')
		else
			Binder_OnKeyDown(this, 'MOUSEWHEELDOWN')
		end
	end)
	binder:SetScript('OnEnter', function() Binder_OnEnter(this) end)
	binder:SetScript('OnLeave', function() Binder_OnLeave(this) end)
	binder:SetScript('OnHide', function() KeyBound_Set(nil) end)
	binder:Hide()
	
	return binder
end


--[[ Usable Functions ]]--

function KeyBound_Set(button)
	if enabled and button then
		KeyBound.button = button
		KeyBound:SetAllPoints(button)
		
		KeyBound.text:SetFontObject('GameFontNormalLarge')
		KeyBound.text:SetText(button:GetHotkey())
		if KeyBound.text:GetStringWidth() > KeyBound:GetWidth() then
			KeyBound.text:SetFontObject('GameFontNormal')
		end
		KeyBound:Show()
		Binder_OnEnter(KeyBound)
	elseif KeyBound then
		KeyBound.button = nil
		KeyBound:ClearAllPoints()
		KeyBound:Hide()
	end
end

function KeyBound_Enable()
	enabled = true
	if not KeyBound then
		KeyBound = Binder_Create()
	end
	KeyBound_Set(nil)
	BVent:Call('KEYBOUND_ENABLED')
end

function KeyBound_Disable()
	enabled = nil
	KeyBound_Set(nil)
	BVent:Call('KEYBOUND_DISABLED')
end

--[[ Events ]]--

local wasEnabled
BVent:AddAction('PLAYER_REGEN_ENABLED', function()
	if wasEnabled or enabled then
		KeyBound_Enable()
		UIErrorsFrame:AddMessage(BONGOS_BINDINGS_COMBAT_ENABLED, 1, 1, 1, 1, UIERRORS_HOLD_TIME)
	end
	wasEnabled = nil
end)


BVent:AddAction('PLAYER_REGEN_DISABLED', function()
	wasEnabled = enabled
	if wasEnabled then
		KeyBound_Disable()
		UIErrorsFrame:AddMessage(BONGOS_BINDINGS_COMBAT_DISABLED, 1, 1, 1, 1, UIERRORS_HOLD_TIME)
	end
end)