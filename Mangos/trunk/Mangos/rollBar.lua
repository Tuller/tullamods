--[[
	Mangos
		Because sometimes I feel bad about doing to much
--]]

local RollBar = Mangos:CreateClass('Frame', Mangos.Frame)
Mangos.RollBar  = RollBar

function RollBar:New()
	local f = self.super.New(self, 'roll')
	f:LoadButtons()
	f:Layout()

	return f
end

function RollBar:GetDefaults()
	return {
		point = 'LEFT',
		numButtons = NUM_GROUP_LOOT_FRAMES,
		columns = 1,
		spacing = 2
	}
end

function RollBar:AddButton(i)
	local b =  getglobal('GroupLootFrame' .. i)
	b:SetParent(self.header)
	self.buttons[i] = b
end

function RollBar:RemoveButton(i)
	local b = self.buttons[i]
	b:SetParent(nil)
	self.buttons[i] = nil
end