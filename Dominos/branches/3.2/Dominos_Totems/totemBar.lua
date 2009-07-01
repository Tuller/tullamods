--[[
	totemBar
		A dominos totem bar
--]]

local class, enClass = UnitClass('player')
if enClass ~= 'SHAMAN' then
	DisableAddOn('Dominos_Totems')
	return
end

local DTB = Dominos:NewModule('totems')
local TotemBar
local SpellButton

--hurray for constants
local NUM_TOTEM_BARS = 3 --fire, water, air
local NUM_TOTEM_BAR_BUTTONS = 4 --fire, earth, water, air
local TOTEM_CALLS = {66842, 66843, 66844} --fire, water, air spellIDs
local CALL_OF_EARTH = 36936
local TOTEM_BAR_START_ID = 132 --actionID start of the totembar


--[[ Module Stuff ]]--

function DTB:Load()
	for id = 1, NUM_TOTEM_BARS do
		TotemBar:New(id)
	end
end

function DTB:Unload()
	for id = 1, NUM_TOTEM_BARS do
		local f = Dominos.Frame:Get('totem' .. id)
		if f then
			f:Free()
		end
	end
end


--[[ Totem Bar Object ]]--

TotemBar = Dominos:CreateClass('Frame', Dominos.Frame)

function TotemBar:New(id)
	local f = self.super.New(self, 'totem' .. id)
	f.totemBarID = id
	f:LoadButtons()
	f:Layout()

	return f
end

function TotemBar:GetDefaults()
	return {
		point = 'CENTER',
		spacing = 2
	}
end

function TotemBar:NumButtons()
	return NUM_TOTEM_BAR_BUTTONS + 2
end

function TotemBar:GetBaseID()
	return TOTEM_BAR_START_ID + (NUM_TOTEM_BAR_BUTTONS * (self.totemBarID - 1))
end


--[[ button stuff]]--

function TotemBar:LoadButtons()
	self.buttons[1] = self:CreateSpellButton(TOTEM_CALLS[self.totemBarID])
	
	for i = 1, NUM_TOTEM_BAR_BUTTONS do
		local b = Dominos.ActionButton:New(self:GetBaseID() + i)
		if b then
			b:SetParent(self.header)
			self.buttons[i + 1] = b
		else
			break
		end
	end
	
	self.buttons[self:NumButtons()] = self:CreateSpellButton(CALL_OF_EARTH)
		
	self.header:Execute([[ control:ChildUpdate('action', nil) ]])
end

function TotemBar:AddButton(i)
	local b
	if i == 1 then
		b = self:CreateSpellButton(TOTEM_CALLS[self.totemBarID])
	elseif i == self:NumButtons() then
		b = self:CreateSpellButton(CALL_OF_EARTH)
	else
		b = self:CreateActionButton(self:GetBaseID() + 1)
	end
	self.buttons[i] = b
end

function TotemBar:RemoveButton(i)
	local b = self.buttons[i]
	self.buttons[i] = nil
	b:Free()
end

function TotemBar:CreateSpellButton(spellID)
	local b = Dominos.SpellButton:New(spellID)
	b:SetParent(self.header)
	
	return b
end

function TotemBar:CreateActionButton(actionID)
	local b = Dominos.ActionButton:New(actionID)
	b:SetParent(self.header)
	b:LoadAction()
	
	return b
end
