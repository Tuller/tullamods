--[[
	Bongos Bindings
--]]

local DEFAULT_BINDINGS = 0
local ACCOUNT_BINDINGS = 1
local CHARACTER_BINDINGS = 2
local enabled
local current
local wasUnlocked


--[[ Options Frame Functions ]]--

function BOptionsBinder_OnShow()
	wasUnlocked = not Bongos.IsLocked()
	if wasUnlocked then
		Bongos.SetLock(true)
	end
	
	if InCombatLockdown() then
		SeeQ:Do(KeyBound_Enable)
	else
		KeyBound_Enable()
	end
end

function BOptionsBinder_OnHide()
	if wasUnlocked then
		Bongos.SetLock(nil)
	end
	
	KeyBound_Disable()

	if InCombatLockdown() then
		SeeQ:Do(function() SaveBindings(current) end)
	else
		SaveBindings(current)
	end
end


--[[ Per Character Bindings ]]--

function BOptionsBinderPerCharacter_OnShow()
	if not current then
		current = GetCurrentBindingSet()
	end
	this:SetChecked(GetCurrentBindingSet() == CHARACTER_BINDINGS)
end

function BOptionsBinderPerCharacter_OnClick(checkButton)
	if checkButton:GetChecked() then
		current = CHARACTER_BINDINGS
	else
		current = ACCOUNT_BINDINGS
	end
	LoadBindings(current)
end