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
	
	self:RegisterMessage("KEYBOUND_ENABLED", function() BActionBar:UpdateVisibilityForAll(true) end)
	self:RegisterMessage("KEYBOUND_DISABLED", function() BActionBar:UpdateVisibilityForAll(nil) end)
	
	for i = 1, BActionBar:GetNumber() do 
		BActionBar:Create(i)
	end
end

-- local function OnEvent()
	-- if event == 'ACTIONBAR_SLOT_CHANGED' then
		-- BActionButton.ForID(arg1, BActionButton.UpdateSlot)
	-- elseif event == 'PLAYER_ENTERING_WORLD'then
		-- BActionButton.ForAll(BActionButton.Update)
	-- elseif event == 'ACTIONBAR_SHOWGRID' then
		-- bg_showGrid = true
		-- BActionBar.UpdateVisibilityForAll(bg_showGrid)
	-- elseif event == 'ACTIONBAR_HIDEGRID' then
		-- bg_showGrid = nil
		-- BActionBar.UpdateVisibilityForAll(bg_showGrid)
	-- elseif event == 'ACTIONBAR_PAGE_CHANGED' then
		-- BActionBar.ForAllWithPage(BActionButton.Update, true)
	-- elseif event == 'UPDATE_SHAPESHIFT_FORM' or event == 'UPDATE_STEALTH' then
		-- BActionBar.ForAllWithStance(BActionButton.Update, true)
	-- elseif event == 'UPDATE_BINDINGS' then
		-- BActionButton.ForAll(BActionButton.UpdateHotkey)
	-- elseif event == 'PLAYER_TARGET_CHANGED' then
		-- BActionButton.ForAllWithAction(BActionButton.UpdateUsable)
	-- elseif event == 'PLAYER_AURAS_CHANGED' then
		-- BActionButton.ForAllWithAction(BActionButton.UpdateUsable)
	-- elseif event == 'UNIT_INVENTORY_CHANGED' then
		-- if arg1 == 'player' then
			-- BActionButton.ForAllWithAction(BActionButton.Update)
		-- end
	-- elseif event == 'ACTIONBAR_UPDATE_USABLE' or event == 'UPDATE_INVENTORY_ALERTS' or event == 'ACTIONBAR_UPDATE_COOLDOWN' then
		-- BActionButton.ForAllWithAction(BActionButton.UpdateCooldown)
		-- BActionButton.ForAllWithAction(BActionButton.UpdateUsable)
	-- elseif event == 'ACTIONBAR_UPDATE_STATE' or event == 'CRAFT_SHOW' or event == 'CRAFT_CLOSE' or event == 'TRADE_SKILL_SHOW' or event == 'TRADE_SKILL_CLOSE' then
		-- BActionButton.ForAllWithAction(BActionButton.UpdateState)
	-- elseif event == 'PLAYER_ENTER_COMBAT' or event == 'PLAYER_LEAVE_COMBAT' or event == 'START_AUTOREPEAT_SPELL' or event == 'STOP_AUTOREPEAT_SPELL' then
		-- BActionButton.ForAllWithAction(BActionButton.UpdateFlash)
	-- end
-- end

function BongosActionBar:Unload()
	self:UnregisterAllEvents()
	self:UnregisterAllMessages()

	for i = 1, BActionBar:GetNumber() do 
		BActionBar:Get(i):Destroy()
	end
end

--event functions
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

function BongosActionBar:UpdatePages()
	BActionBar:ForAllWithPage(BongosActionButton.Update, true)
end

function BongosActionBar:UpdateStances()
	BActionBar:ForAllWithStance(BongosActionButton.Update, true)
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

-- local function RegisterEvents()
	-- BVent:AddAction('KEYBOUND_ENABLED', function() BActionBar.UpdateVisibilityForAll(true) end)
	-- BVent:AddAction('KEYBOUND_DISABLED', function() BActionBar.UpdateVisibilityForAll(nil) end)
-- end