local CastButton = {}

function CastButton:Load()
	local function SpellButton_OnEnter(self)
		local id = SpellBook_GetSpellID(self:GetID())
		local bookType = SpellBookFrame.bookType

		if not(bookType == BOOKTYPE_PET or IsPassiveSpell(id, bookType)) then
			KeyBound:Set(self)
		end
	end

	local i = 1
	local button
	repeat
		button = getglobal('SpellButton' .. i)
		if button then
			button:HookScript('OnEnter', SpellButton_OnEnter)

			button.GetBindAction = CastButton.GetBindAction
			button.GetActionName = CastButton.GetActionName
			button.SetKey = CastButton.SetKey
			button.GetHotkey = CastButton.GetHotkey
			button.ClearBindings = CastButton.ClearBindings
			button.GetBindings = CastButton.GetBindings
			i = i + 1
		end
	until not button
end

function CastButton:GetActionName()
	local name, subName = GetSpellName(SpellBook_GetSpellID(self:GetID()), SpellBookFrame.bookType)
	if(subName and subName ~= '') then
		return format('%s(%s)', name, subName)
	end
	return name
end

-- returns the keybind action of the given button
function CastButton:GetBindAction()
	return format('SPELL %s', self:GetActionName())
end

-- binds the given key to the given button
function CastButton:SetKey(key)
	SetBindingSpell(key, self:GetActionName())
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
	for i = 1, select('#', GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if keys then
			keys = keys .. ', ' .. GetBindingText(hotKey, 'KEY_')
		else
			keys = GetBindingText(hotKey, 'KEY_')
		end
	end
	return keys
end

function CastButton:GetHotkey()
	return KeyBound:ToShortKey(GetBindingKey(self:GetBindAction()))
end

CastButton:Load()