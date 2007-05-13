BongosActionBar = BongosActionMain:NewModule("Bongos-ActionBar")

function BongosActionBar:Load()	
	self:RegisterEvent("ACTIONBAR_PAGE_CHANGED", "UpdatePages")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "UpdateStances")
	self:RegisterEvent("UPDATE_STEALTH", "UpdateStances")

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAllButtons")
	self:RegisterEvent("ACTIONBAR_SHOWGRID", "UpdateGrid")
	self:RegisterEvent("ACTIONBAR_HIDEGRID", "UpdateGrid")	
	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED", "UpdateSlot")
	self:RegisterEvent("UPDATE_BINDINGS", "UpdateHotkeys")
	self:RegisterEvent("PLAYER_AURAS_CHANGED", "UpdateUsuable")
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
	
	for i = 1, self:GetNumber() do 
		BActionBar:Create(i)
	end
end

function BongosActionBar:Unload()
	self:UnregisterAllEvents()

	for i = 1, self:GetNumber() do 
		self:Get(i):Destroy()
	end
end

--event functions
function BongosActionBar:UpdateSlot(event, slot)
	BongosActionButton:ForID(slot, BongosActionButton.UpdateSlot)
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
	BongosActionButton:ForAll(BongosActionButton.Update)
end

function BongosActionBar:UpdatePages()
	BActionBar:ForAllWithPage(BongosActionButton.Update, true)
end

function BongosActionBar:UpdateStances()
	BActionBar:ForAllWithStance(BongosActionButton.Update, true)
end

function BongosActionBar:UpdateHotkeys()
	BongosActionButton:ForAll(BongosActionButton.UpdateHotkey)
end

function BongosActionBar:UpdateUsuable()
	BongosActionButton:ForAllWithAction(BongosActionButton.UpdateUsable)
end

function BongosActionBar:UpdateInventory(event, unit)
	if unit == "player" then
		BongosActionButton:ForAllWithAction(BongosActionButton.Update)
	end
end

function BongosActionBar:UpdateCooldownAndUsable()
	BongosActionButton:ForAllWithAction(BongosActionButton.UpdateCooldown)
	BongosActionButton:ForAllWithAction(BongosActionButton.UpdateUsable)
end

function BongosActionBar:UpdateState()
	BongosActionButton:ForAllWithAction(BongosActionButton.UpdateState)
end

function BongosActionBar:UpdateFlash()
	BongosActionButton:ForAllWithAction(BongosActionButton.UpdateFlash)
end

-- local function RegisterEvents()
	-- BVent:AddAction('KEYBOUND_ENABLED', function() BActionBar.UpdateVisibilityForAll(true) end)
	-- BVent:AddAction('KEYBOUND_DISABLED', function() BActionBar.UpdateVisibilityForAll(nil) end)
-- end