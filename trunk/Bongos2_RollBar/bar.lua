--[[
	BRollBar
		A movable frame for rolling on items
--]]

BongosRollBar = Bongos:NewModule('Bongos-RollBar')

--[[ Startup ]]--

local function Bar_OnCreate(self)
	for i = 1, NUM_GROUP_LOOT_FRAMES do	
		local frame = getglobal('GroupLootFrame' .. i)
		frame:ClearAllPoints()

		if i > 1 then
			frame:SetPoint('BOTTOM', 'GroupLootFrame' .. (i-1), 'TOP', 0, 3)
		else
			frame:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', 4, 2)
		end
		self:Attach(frame)
	end

	self:SetWidth(GroupLootFrame1:GetWidth() + 4)
	self:SetHeight((GroupLootFrame1:GetHeight() + 3) * NUM_GROUP_LOOT_FRAMES)
end

function BongosRollBar:Load()
	local defaults = {
		point = 'LEFT',
		xOff = 0,
		yOff = 0,
	}

	BBar:Create('roll', Bar_OnCreate, nil, defaults, 'DIALOG')
end

function BongosRollBar:Unload()
	BBar:Get('roll'):Destroy()
end