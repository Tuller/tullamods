--[[
	RollBar
		A movable frame for rolling on items
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local Roll = Bongos:NewModule('Roll')

function Roll:Load()
	self.bar, isNew = Bongos.Bar:Create('roll', {point = 'LEFT'}, 'DIALOG')
	if isNew then
		self:OnBarCreate(self.bar)
	end
end

function Roll:Unload()
	self.bar:Destroy()
end

function Roll:OnBarCreate(bar)
	for i = 1, NUM_GROUP_LOOT_FRAMES do	
		local f = getglobal('GroupLootFrame' .. i)
		bar:Attach(f)

		f:ClearAllPoints()
		if i > 1 then
			f:SetPoint('BOTTOM', 'GroupLootFrame' .. (i-1), 'TOP', 0, 3)
		else
			f:SetPoint('BOTTOMLEFT', 4, 2)
		end
	end

	bar:SetWidth(GroupLootFrame1:GetWidth() + 4)
	bar:SetHeight((GroupLootFrame1:GetHeight() + 3) * NUM_GROUP_LOOT_FRAMES)
end