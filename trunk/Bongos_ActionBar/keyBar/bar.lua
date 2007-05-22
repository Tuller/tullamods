--[[
	BKeyBar
		Makes the keyring button movable
--]]

BongosKeyBar = BongosActionMain:NewModule("Bongos-KeyBar")

local function Bar_OnCreate(self)
	local key = KeyRingButton
	key:ClearAllPoints()
	key:SetPoint("TOPLEFT", self)
	key:Show()

	self:Attach(key)
	self:SetSize(key:GetWidth(), key:GetHeight())
end

function BongosKeyBar:Load()
	self.bar = BBar:Create("key", Bar_OnCreate, nil, {["y"] = 39, ["x"] = 1241.857})
end

function BongosKeyBar:Unload()
	self.bar:Destroy()
end