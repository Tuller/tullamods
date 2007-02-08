local CastButton = {}

local function ToBindAction(button)
	local name, subName = GetSpellName(button:GetID(), SpellBookFrame.bookType)
	if subName then
		name = name .. '(' .. subName  .. ')'
	end
	return 'SPELL ' .. name
end

-- binds the given key to the given button
function CastButton:SetKey(key)
	local name, subName = GetSpellName(self:GetID(), SpellBookFrame.bookType)
	if subName then
		name = name .. '(' .. subName  .. ')'
	end
	SetBindingSpell(key, name)
end

-- removes all keys bound to the given button
function CastButton:ClearBindings()
	local binding = ToBindAction(self)
	while GetBindingKey(binding) do
		SetBinding(GetBindingKey(binding), nil)
	end
	SaveBindings(GetCurrentBindingSet())
end

-- returns a string listing all bindings of the given button
function CastButton:GetBindings()
	local keys
	local binding = ToBindAction(self)
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

function CastButton:GetHotkey()
	return BActionUtil.ToShortKey(GetBindingKey(ToBindAction(self)))
end

hooksecurefunc('SpellButton_OnEnter', function()
	local id = SpellBook_GetSpellID(this:GetID())
	local bookType = SpellBookFrame.bookType

	if not(bookType == BOOKTYPE_PET or IsPassiveSpell(id, bookType)) then
		KeyBound_Set(this)
	end
end)

for i = 1, 12 do
	local button = getglobal('SpellButton' .. i)
	button.SetKey = CastButton.SetKey
	button.GetHotkey = CastButton.GetHotkey
	button.ClearBindings = CastButton.ClearBindings
	button.GetBindings = CastButton.GetBindings
end