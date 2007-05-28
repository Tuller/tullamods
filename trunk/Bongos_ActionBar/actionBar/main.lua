--[[
	actionbar event code
--]]

BongosActionBar = Bongos:NewModule("Bongos-ActionBar")

local CLASS = BONGOS_CLASS
local hasStance = (CLASS == "DRUID" or CLASS == "ROGUE" or CLASS == "WARRIOR" or CLASS == "PRIEST")
local DEFAULT_NUM_ACTIONBARS = 10

--converts BActionButton and ActionButton bindings to their proper bongos bars, inspired from Bartender3
function BongosActionBar:ConvertBindings()
	--baction buttons
	for i = 1, 120 do
		local key = GetBindingKey(format("CLICK BActionButton%d:LeftButton", i))
		while key do
			SetBindingClick(key, format("BongosActionButton%d", i), "LeftButton")
			key = GetBindingKey(format("CLICK BActionButton%d:LeftButton", i))
		end
	end

	--action buttons
	for i = 1, 12 do
		local key = GetBindingKey(format("ActionButton%d", i))
		while key do
			SetBindingClick(key, format("BongosActionButton%d", i), "LeftButton")
			key = GetBindingKey(format("ActionButton%d", i))
		end
	end
	
	--left side multibars
	local k = 5
	for i = 1, 2 do
		for j = 1, 12 do
			local key = GetBindingKey(format("MULTIACTIONBAR%dBUTTON%d", i, j))
			while key do
				SetBindingClick(key, format("BongosActionButton%d", j+(k*12)), "LeftButton")
				key = GetBindingKey(format("ActionButton%d", i))
			end
		end
		k = k - 1
	end

	--right side bars
	for i = 4, 3, -1 do
		for j = 1, 12 do
			local key = GetBindingKey(format("MULTIACTIONBAR%dBUTTON%d", i, j))
			while key do
				SetBindingClick(key, format("BongosActionButton%d", j+(k*12)), "LeftButton")
				key = GetBindingKey(format("ActionButton%d", i))
			end
		end
		k = k - 1
	end
	SaveBindings(GetCurrentBindingSet())

	Bongos:Print("Converted keys from the blizzard actionbars and old bongos versions")
end

function BongosActionBar:Load()
	for i = 1, self:GetNumber() do BActionBar:Create(i) end

	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED", "UpdateVisibility")
	self:RegisterEvent("ACTIONBAR_SHOWGRID", "UpdateGrid")
	self:RegisterEvent("ACTIONBAR_HIDEGRID", "UpdateGrid")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateCombatStatus")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "UpdateCombatStatus")
	self:RegisterMessage("KEYBOUND_ENABLED", "UpdateVisibility")
	self:RegisterMessage("KEYBOUND_DISABLED", "UpdateVisibility")
	
	if(hasStance) then
		self.numForms = GetNumShapeshiftForms()
		self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS", "UpdateStanceNumbers")
	end
end

function BongosActionBar:Unload()
	for i = 1, self:GetNumber() do
		BActionBar:Get(i):Destroy()
	end

	self:UnregisterAllEvents()
	self:UnregisterAllMessages()
end

function BongosActionBar:UpdateCombatStatus(event)
	if(event == "PLAYER_REGEN_ENABLED") then
		self.inCombat = nil

		if(self.needToUpdate) then
			self.needToUpdate = nil
			self:UpdateVisibility()
		end
	elseif(event == "PLAYER_REGEN_DISABLED") then
		self.inCombat = true
	end
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
	if(not self.inCombat) then
		for i = 1, self:GetNumber() do
			local bar = BActionBar:Get(i)
			if bar:IsShown() then
				bar:UpdateVisibility()
			end
		end
	else
		self.needToUpdate = true
	end
end

function BongosActionBar:SetNumber(newSize)
	if(newSize ~= self:GetNumber()) then
		self:Unload()
		Bongos.profile.numActionBars = newSize
		self:Load()
	end
end

function BongosActionBar:GetNumber()
	return Bongos.profile.numActionBars or 10
end

function BongosActionBar:UpdateStanceNumbers()
	local prev = self.numForms
	self.numForms = GetNumShapeshiftForms()

	if(self.numForms ~= prev) then
		for i = 1, self:GetNumber() do
			local bar = BActionBar:Get(i)
			bar:UpdateStateHeader()
			bar:UpdateButtonStates()
		end
	end
end