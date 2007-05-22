--[[
	Bongos Bindings
--]]

local DEFAULT_BINDINGS = 0
local ACCOUNT_BINDINGS = 1
local CHARACTER_BINDINGS = 2


--[[ Per Character Bindings ]]--

local current
function BOptionsBinderPerCharacter_OnShow(self)
	if not current then
		current = GetCurrentBindingSet()
	end
	self:SetChecked(GetCurrentBindingSet() == CHARACTER_BINDINGS)
end

function BOptionsBinderPerCharacter_OnClick(self)
	if self:GetChecked() then
		current = CHARACTER_BINDINGS
	else
		current = ACCOUNT_BINDINGS
	end
	LoadBindings(current)
end