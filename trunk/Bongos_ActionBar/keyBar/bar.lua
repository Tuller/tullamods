--[[
	BKeyBar
		Makes the keyring button movable
--]]

BongosKeyBar = BongosActionMain:NewModule("Bongos-KeyBar")
BongosKeyBar.defaults = {x = 1241.857, y = 39, vis = 1}

local function Bar_OnCreate(self)
	local key = KeyRingButton
	key:ClearAllPoints()
	key:SetPoint('TOPLEFT', self)
	key:Show()

	self:Attach(key)
	self:SetSize(key:GetWidth(), key:GetHeight())
end

function BongosKeyBar:Load()
	self.bar = BBar:Create('key', Bar_OnCreate, nil, self.defaults)
end

function BongosKeyBar:Unload()
	self.bar:Destroy()
end