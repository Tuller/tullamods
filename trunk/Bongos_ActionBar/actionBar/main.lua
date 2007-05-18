--[[
	actionbar event code
--]]

BongosActionBar = BongosActionMain:NewModule("Bongos-ActionBar")

function BongosActionBar:Load()
	for i = 1, BActionBar:GetNumber() do
		BActionBar:Create(i)
	end

	self:RegisterEvent("ACTIONBAR_SHOWGRID", "UpdateGrid")
	self:RegisterEvent("ACTIONBAR_HIDEGRID", "UpdateGrid")
	self:RegisterMessage("KEYBOUND_ENABLED", "UpdateBindingMode")
	self:RegisterMessage("KEYBOUND_DISABLED", "UpdateBindingMode")
end

function BongosActionBar:Unload()
	for i = 1, BActionBar:GetNumber() do
		BActionBar:Get(i):Destroy()
	end
	
	self:UnregisterAllEvents()
	self:UnregisterAllMessages()
end


function BongosActionBar:UpdateGrid(event)
	if(event == "ACTIONBAR_SHOWGRID") then
		self.showEmpty = true
	elseif(event == "ACTIONBAR_HIDEGRID") then
		self.showEmpty = nil
	end
	BActionBar:UpdateVisibilityForAll(self.showEmpty)
end

function BongosActionBar:UpdateBindingMode(event)
	if(event == "KEYBOUND_ENABLED") then
		BActionBar:UpdateVisibilityForAll(true) 
	elseif(event == "KEYBOUND_DISABLED") then
		BActionBar:UpdateVisibilityForAll(nil)
	end
end