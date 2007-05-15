--[[
	actionbar event code
--]]

BongosActionBar = BongosActionMain:NewModule("Bongos-ActionBar")

local class = select(2, UnitClass("player"))

function BongosActionBar:Load()
	-- self:RegisterEvent("ACTIONBAR_PAGE_CHANGED", "UpdateStances")
	-- self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "UpdateStances")
	-- self:RegisterEvent("UPDATE_STEALTH", "UpdateStances")
	-- self:RegisterEvent("PLAYER_TARGET_CHANGED", "UpdateStances")

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAllButtons")
	self:RegisterEvent("ACTIONBAR_SHOWGRID", "UpdateGrid")
	self:RegisterEvent("ACTIONBAR_HIDEGRID", "UpdateGrid")
	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED", "UpdateSlot")
	self:RegisterEvent("UPDATE_BINDINGS", "UpdateHotkeys")
	self:RegisterEvent("PLAYER_AURAS_CHANGED", "UpdateUsuable")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "UpdateUsable")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED", "UpdateInventory")

	self:RegisterEvent("ACTIONBAR_UPDATE_USABLE", "UpdateCooldownAndUsable")
	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN", "UpdateCooldownAndUsable")
	self:RegisterEvent("UPDATE_INVENTORY_ALERTS", "UpdateCooldownAndUsable")

	self:RegisterEvent("ACTIONBAR_UPDATE_STATE", "UpdateState")
	self:RegisterEvent("CRAFT_SHOW", "UpdateState")
	self:RegisterEvent("CRAFT_CLOSE", "UpdateState")
	self:RegisterEvent("TRADE_SKILL_SHOW", "UpdateState")
	self:RegisterEvent("TRADE_SKILL_CLOSE", "UpdateState")

	self:RegisterEvent("PLAYER_ENTER_COMBAT", "UpdateFlash")
	self:RegisterEvent("PLAYER_LEAVE_COMBAT", "UpdateFlash")
	self:RegisterEvent("START_AUTOREPEAT_SPELL", "UpdateFlash")
	self:RegisterEvent("STOP_AUTOREPEAT_SPELL", "UpdateFlash")

	self:RegisterMessage("KEYBOUND_ENABLED", function() BActionBar:UpdateVisibilityForAll(true) end)
	self:RegisterMessage("KEYBOUND_DISABLED", function() BActionBar:UpdateVisibilityForAll(nil) end)
	
	for i = 1, BActionBar:GetNumber() do
		BActionBar:Create(i)
	end
end

function BongosActionBar:Unload()
	self:UnregisterAllEvents()
	self:UnregisterAllMessages()

	for i = 1, BActionBar:GetNumber() do
		BActionBar:Get(i):Destroy()
	end
end


--[[ Event Functions ]]--

function BongosActionBar:UpdateSlot(event, slot)
	BongosActionButton:ForID(slot, "UpdateSlot")
end

function BongosActionBar:UpdateGrid(event)
	if(event == "ACTIONBAR_SHOWGRID") then
		self.showEmpty = true
	elseif(event == "ACTIONBAR_HIDEGRID") then
		self.showEmpty = nil
	end
	BActionBar:UpdateVisibilityForAll(self.showEmpty)
end

function BongosActionBar:UpdateAllButtons()
	BongosActionButton:ForAll("Update")
end

function BongosActionBar:UpdateStances()
	BongosActionButton:ForAll("Update", true)
end

function BongosActionBar:UpdateHotkeys()
	BongosActionButton:ForAll("UpdateHotkey")
end

function BongosActionBar:UpdateUsuable()
	BongosActionButton:ForAllWithAction("UpdateUsable")
end

function BongosActionBar:UpdateInventory(event, unit)
	if unit == "player" then
		BongosActionButton:ForAllWithAction("Update")
	end
end

function BongosActionBar:UpdateCooldownAndUsable()
	BongosActionButton:ForAllWithAction("UpdateCooldown")
	BongosActionButton:ForAllWithAction("UpdateUsable")
end

function BongosActionBar:UpdateState()
	BongosActionButton:ForAllWithAction("UpdateState")
end

function BongosActionBar:UpdateFlash()
	BongosActionButton:ForAllWithAction("UpdateFlash")
end