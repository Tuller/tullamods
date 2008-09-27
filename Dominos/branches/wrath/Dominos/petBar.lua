--[[
	Dominos
		Because sometimes I feel bad about doing to much
--]]

--libs and omgspeed
local _G = getfenv(0)
local format = string.format

local KeyBound = LibStub('LibKeyBound-1.0')
local LBF = LibStub('LibButtonFacade', true)


--[[ Pet Button ]]--

local PetButton = Dominos:CreateClass('CheckButton')

function PetButton:New(id)
	local b = PetButton:Restore(id) or PetButton:Create(id)
	b:UpdateHotkey()
	
	return b
end

function PetButton:Create(id)
	local b = self:Bind(_G['PetActionButton' .. id])
	b:SetScript('OnEnter', self.OnEnter)

	if LBF then
		LBF:Group('Dominos', 'Pet Bar'):AddButton(b)
	else
		_G[b:GetName() .. 'Icon']:SetTexCoord(0.06, 0.94, 0.06, 0.94)
		b:GetNormalTexture():SetVertexColor(1, 1, 1, 0.5)
	end
	return b
end

function PetButton:Restore(id)
	local unused = self.unused
	if unused then
		b = unused[id]
		if b then
			unused[id] = nil
			b:Show()
			return b
		end
	end
end

function PetButton:Free()
	local unused = PetButton.unused or {}
	unused[self:GetID()] = self
	PetButton.unused = unused

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
	local key = PetButton.GetHotkey(self)
	local hotkey = _G[self:GetName() .. 'HotKey']

	if key ~= ''  and Dominos:ShowBindingText() then
		hotkey:SetText(key)
		hotkey:Show()
	else
		hotkey:Hide()
	end
end

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

PetActionButton_SetHotkeys = function(self) PetButton.UpdateHotkey(self) end


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
	if self == Dominos:GetPossessBar() then
		self:SetShowStates('[target=pet,nodead,exists]')
	else
		self:SetShowStates('[target=pet,nodead,exists,nobonusbar:5]')
	end
end

function PetBar:GetDefaults()
	return {
		point = 'CENTER',
		x = 0,
		y = -32,
		numButtons = 10,
		spacing = 6
	}
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