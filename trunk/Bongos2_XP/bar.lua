--[[
	BongosXP
		A movable experience bar
--]]

BongosXP = Bongos:NewModule("Bongos-XP")

local function Bar_OnCreate(self)
	local xpBar = MainMenuExpBar
	self:SetSize(xpBar:GetWidth(), xpBar:GetHeight())
	xpBar:ClearAllPoints()
	xpBar:SetPoint("TOPLEFT", self)
	self:Attach(xpBar)
end

function BongosXP:Load()
	self.bar = BBar:Create("xp", Bar_OnCreate)
	if(not self.bar:IsUserPlaced()) then
		self.bar:SetPoint("CENTER", UIParent)
	end
end

function BongosXP:Unload()
	self.bar:Destroy()
end