--[[
	Mangos
		Because sometimes I feel bad about doing to much
--]]

--libs and omgspeed
local _G = getfenv(0)
local format = string.format

local KeyBound = LibStub('LibKeyBound-1.0')
local LBF = LibStub('LibButtonFacade', true)


--[[ Pet Button ]]--

local PetButton = Mangos:CreateClass('CheckButton')

function PetButton:New(id)
	return PetButton:Restore(id) or PetButton:Create(id)
end

function PetButton:Create(id)
	local b = self:Bind(_G['PetActionButton' .. id])
	b:SetScript('OnEnter', self.OnEnter)

	if LBF then
		LBF:Group('Mangos', 'Pet Bar'):AddButton(b)
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
	self:RCall(PetActionButton_OnEnter)
	KeyBound:Set(self)
end

function PetButton:UpdateHotkey()
	local hotkey = _G[self:GetName() .. 'HotKey']
	local text = KeyBound:ToShortKey(GetBindingKey('BONUSACTIONBUTTON'..self:GetID()) or GetBindingKey(format('CLICK %s:LeftButton', self:GetName()))) 
	hotkey:SetText(text)

	if text == '' then
		hotkey:Hide()
	else
		hotkey:Show()
	end
end

function PetButton:GetHotkey()
	return KeyBound:ToShortKey(GetBindingKey(format('CLICK %s:LeftButton', self:GetName())))
end

--you can hopefully guess what the 'R' stands for
function PetButton:RCall(f, ...)
	local pThis = this
	this = self
	f(...)
	this = pThis
end

PetActionButton_SetHotkeys = function() PetButton.UpdateHotkey(this) end


--[[ Pet Bar ]]--

local PetBar = Mangos:CreateClass('Frame', Mangos.Frame)
Mangos.PetBar  = PetBar

function PetBar:New()
	local f = self.super.New(self, 'pet')
	f:LoadButtons()
	f:Layout()
	f:UpdatePossess()

	return f
end

function PetBar:UpdatePossess()
	if Mangos:GetPossessBar() == self then
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
	self:UpdatePossess()

	local petBarShown = PetHasActionBar()
	for _,button in pairs(self.buttons) do
		if petBarShown and GetPetActionInfo(button:GetID()) then
			button:Show()
		else
			button:Hide()
		end
	end
end