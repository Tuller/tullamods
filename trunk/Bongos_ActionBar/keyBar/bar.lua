--[[
	BKeyBar
		Makes the keyring button movable
--]]

BongosKeyBar = BongosActionMain:NewModule("Bongos-KeyBar")

local function Bar_OnCreate(self)
	local key = KeyRingButton
	key:ClearAllPoints()
	key:SetPoint("TOPLEFT", self)

	self:Attach(key)
	self:SetSize(key:GetWidth(), key:GetHeight())
	key:Show()
end

function BongosKeyBar:Load()
	self.bar = BBar:Create("key", Bar_OnCreate, nil, {["y"] = 39, ["x"] = 1214})
end

function BongosKeyBar:Unload()
	self.bar:Destroy()
end