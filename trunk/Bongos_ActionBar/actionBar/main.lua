--[[
	actionbar event code
--]]

BongosActionBar = BongosActionMain:NewModule("Bongos-ActionBar")

local DEFAULT_NUM_ACTIONBARS = 10

function BongosActionBar:Load()
	for i = 1, self:GetNumber() do
		BActionBar:Create(i)
	end

	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED", "UpdateVisibility")
	self:RegisterEvent("ACTIONBAR_SHOWGRID", "UpdateGrid")
	self:RegisterEvent("ACTIONBAR_HIDEGRID", "UpdateGrid")
	self:RegisterMessage("KEYBOUND_ENABLED", "UpdateVisibility")
	self:RegisterMessage("KEYBOUND_DISABLED", "UpdateVisibility")
end

function BongosActionBar:Unload()
	for i = 1, self:GetNumber() do
		BActionBar:Get(i):Destroy()
	end

	self:UnregisterAllEvents()
	self:UnregisterAllMessages()
end

function BongosActionBar:UpdateGrid(event)
	if(event == "ACTIONBAR_SHOWGRID") then
		BongosActionButton.showEmpty = true
	elseif(event == "ACTIONBAR_HIDEGRID") then
		BongosActionButton.showEmpty = nil
	end
	self:UpdateVisibility()
end

--updates the showstates of every button on every bar
function BongosActionBar:UpdateVisibility()
	for i = 1, self:GetNumber() do
		local bar = BActionBar:Get(i)
		if bar:IsShown() then
			bar:UpdateVisibility()
		end
	end
end

function BongosActionBar:SetNumber(newSize)
	if(newSize ~= self:GetNumber()) then
		self:Unload()
		BongosActionMain.profile.numActionBars = newSize
		self:Load()
	end
end

function BongosActionBar:GetNumber()
	return BongosActionMain.profile.numActionBars or 10
end
