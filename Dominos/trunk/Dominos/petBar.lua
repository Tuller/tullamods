--[[
	Dominos
		Because sometimes I feel bad about doing to much
--]]

--libs and omgspeed
local _G = getfenv(0)
local format = string.format

local KeyBound = LibStub('LibKeyBound-1.0')
local unused


--[[ Pet Button ]]--

local PetButton = Dominos:CreateClass('CheckButton')

function PetButton:New(id)
	local b = self:Restore(id) or self:Create(id)
	b:UpdateHotkey()

	return b
end

function PetButton:Create(id)
	local b = self:Bind(_G['PetActionButton' .. id])
	b:SetScript('OnEnter', self.OnEnter)
	b:Skin()

	return b
end

--if we have button facade support, then skin the button that way
--otherwise, apply the dominos style to the button to make it pretty
function PetButton:Skin()
	local LBF = LibStub('LibButtonFacade', true)
	if LBF then
		LBF:Group('Dominos', 'Pet Bar'):AddButton(self)
	else
		_G[self:GetName() .. 'Icon']:SetTexCoord(0.06, 0.94, 0.06, 0.94)
		self:GetNormalTexture():SetVertexColor(1, 1, 1, 0.5)
	end
end

function PetButton:Restore(id)
	local b = unused and unused[id]
	if b then
		unused[id] = nil
		b:Show()

		return b
	end
end

--saving them thar memories
function PetButton:Free()
	if not unused then unused = {} end
	unused[self:GetID()] = self

	self:SetParent(nil)
	self:Hide()
end

--keybound support
function PetButton:OnEnter()
	if Dominos:ShowTooltips() then
		PetActionButton_OnEnter(self)
	end
	KeyBound:Set(self)
end

function PetButton:UpdateHotkey()
	--this syntax is necessary since I override PetActionButton_SetHotkeys
	--which may be called before I have a chance to make every blizzard pet button a dominos pet button object
	local key = PetButton.GetHotkey(self)
	local hotkey = _G[self:GetName() .. 'HotKey']

	if key ~= ''  and Dominos:ShowBindingText() then
		hotkey:SetText(key)
		hotkey:Show()
	else
		hotkey:Hide()
	end
end
PetActionButton_SetHotkeys = PetButton.UpdateHotkey

function PetButton:GetHotkey()
	local key = GetBindingKey('BONUSACTIONBUTTON'..self:GetID()) or GetBindingKey(format('CLICK %s:LeftButton', self:GetName()))
	return KeyBound:ToShortKey(key)
end

local function getKeyStrings(...)
	local keys
	for i = 1, select('#', ...) do
		local key = select(i, ...)
		if keys then
			keys = keys .. ", " .. GetBindingText(key, "KEY_")
		else
			keys = GetBindingText(key, "KEY_")
		end
	end
	return keys
end

function PetButton:GetBindings()
	local blizzKeys = getKeyStrings(GetBindingKey('BONUSACTIONBUTTON'..self:GetID()))
	local clickKeys = getKeyStrings(GetBindingKey(format('CLICK %s:LeftButton', self:GetName())))

	if blizzKeys then
		if clickKeys then
			return blizzKeys .. ', ' .. clickKeys
		end
		return blizzKeys
	else
		return clickKeys
	end
end


--[[ Pet Bar ]]--

local PetBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.PetBar  = PetBar

function PetBar:New()
	local f = self.super.New(self, 'pet')
	f:LoadButtons()
	f:Layout()
	f:UpdateStateDriver()

	return f
end

function PetBar:UpdateStateDriver()
	self:SetShowStates('[target=pet,exists,nobonusbar:5]')
end

function PetBar:GetDefaults()
	return {
		point = 'CENTER',
		x = 0,
		y = -32,
		spacing = 6
	}
end

--dominos frame method overrides
function PetBar:NumButtons()
	return NUM_PET_ACTION_SLOTS
end

function PetBar:AddButton(i)
	local b = PetButton:New(i)
	b:SetParent(self.header)
	self.buttons[i] = b
end

function PetBar:RemoveButton(i)
	local b = self.buttons[i]
	self.buttons[i] = nil
	b:Free()
end


--[[ keybound  support ]]--

function PetBar:KEYBOUND_ENABLED()
	self:SetShowStates(nil)

	for _,button in pairs(self.buttons) do
		button:Show()
	end
end

function PetBar:KEYBOUND_DISABLED()
	self:UpdateStateDriver()

	local petBarShown = PetHasActionBar()
	for _,button in pairs(self.buttons) do
		if petBarShown and GetPetActionInfo(button:GetID()) then
			button:Show()
		else
			button:Hide()
		end
	end
end