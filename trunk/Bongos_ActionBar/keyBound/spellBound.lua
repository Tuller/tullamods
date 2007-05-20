local CastButton = {}

-- returns the keybind action of the given button
function CastButton:GetBindAction()
	local name, subName = GetSpellName(SpellBook_GetSpellID(self:GetID()), SpellBookFrame.bookType)
	if(subName and subName ~= "") then
		return format("SPELL %s(%s)", name, subName)
	end
	return format("SPELL %s", name)
end

-- binds the given key to the given button
function CastButton:SetKey(key)
	local name, subName = GetSpellName(SpellBook_GetSpellID(self:GetID()), SpellBookFrame.bookType)
	if(subName and subName ~= "") then
		name = format("%s(%s)", name, subName)
	end
	SetBindingSpell(key, name)
end

-- removes all keys bound to the given button
function CastButton:ClearBindings()
	local binding = self:GetBindAction()
	while GetBindingKey(binding) do
		SetBinding(GetBindingKey(binding), nil)
	end
end

-- returns a string listing all bindings of the given button
function CastButton:GetBindings()
	local keys
	local binding = self:GetBindAction()
	for i = 1, select("#", GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if keys then
			keys = keys .. ", " .. GetBindingText(hotKey, "KEY_")
		else
			keys = GetBindingText(hotKey, "KEY_")
		end
	end
	return keys
end

function CastButton:GetHotkey()
	return KeyBound:ToShortKey(GetBindingKey(self:GetBindAction()))
end

hooksecurefunc("SpellButton_OnEnter", function()
	local id = SpellBook_GetSpellID(this:GetID())
	local bookType = SpellBookFrame.bookType

	if not(bookType == BOOKTYPE_PET or IsPassiveSpell(id, bookType)) then
		KeyBound:Set(this)
	end
end)

for i = 1, 12 do
	local button = getglobal("SpellButton" .. i)
	button.GetBindAction = CastButton.GetBindAction
	button.SetKey = CastButton.SetKey
	button.GetHotkey = CastButton.GetHotkey
	button.ClearBindings = CastButton.ClearBindings
	button.GetBindings = CastButton.GetBindings
end