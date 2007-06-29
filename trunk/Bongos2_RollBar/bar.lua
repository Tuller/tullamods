--[[
	BRollBar
		A movable frame for rolling on items
--]]

BongosRollBar = Bongos:NewModule("Bongos-RollBar")

--[[ Startup ]]--

local function Bar_OnCreate(self)
	local frame = getglobal("GroupLootFrame"..1)
	frame:ClearAllPoints()
	frame:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 4, 2)
	self:Attach(frame)

	for i=2, NUM_GROUP_LOOT_FRAMES do
		local frame = getglobal("GroupLootFrame"..i)
		frame:ClearAllPoints()
		frame:SetPoint("BOTTOM", "GroupLootFrame" .. (i-1), "TOP", 0, 3)
		self:Attach(frame)
	end

	self:SetWidth(GroupLootFrame1:GetWidth() + 4)
	self:SetHeight((GroupLootFrame1:GetHeight() + 3) * NUM_GROUP_LOOT_FRAMES)
end

function BongosRollBar:Load()
	local bar = BBar:Create("roll", Bar_OnCreate, nil, nil, "DIALOG")
	if not bar:IsUserPlaced() then
		bar:SetPoint("LEFT", UIParent)
	end
end

function BongosRollBar:Unload()
	BBar:Get("roll"):Destroy()
end