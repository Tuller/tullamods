--[[
	actionbar/events.lua
		handles all actionbar and button events
--]]

bg_showGrid = false

--[[ Event Handler ]]--

local function OnEvent()
	if event == 'ACTIONBAR_SLOT_CHANGED' then
		BActionButton.ForID(arg1, BActionButton.UpdateSlot)
	elseif event == 'PLAYER_ENTERING_WORLD'then
		BActionButton.ForAll(BActionButton.Update)
	elseif event == 'ACTIONBAR_SHOWGRID' then
		bg_showGrid = true
		BActionBar.UpdateVisibilityForAll(bg_showGrid)
	elseif event == 'ACTIONBAR_HIDEGRID' then
		bg_showGrid = nil
		BActionBar.UpdateVisibilityForAll(bg_showGrid)
	elseif event == 'ACTIONBAR_PAGE_CHANGED' then
		BActionBar.ForAllWithPage(BActionButton.Update, true)
	elseif event == 'UPDATE_SHAPESHIFT_FORM' or event == 'UPDATE_STEALTH' then
		BActionBar.ForAllWithStance(BActionButton.Update, true)
	elseif event == 'UPDATE_BINDINGS' then
		BActionButton.ForAll(BActionButton.UpdateHotkey)
	elseif event == 'PLAYER_TARGET_CHANGED' then
		BActionButton.ForAllWithAction(BActionButton.UpdateUsable)
	elseif event == 'PLAYER_AURAS_CHANGED' then
		BActionButton.ForAllWithAction(BActionButton.UpdateUsable)
	elseif event == 'UNIT_INVENTORY_CHANGED' then
		if arg1 == 'player' then
			BActionButton.ForAllWithAction(BActionButton.Update)
		end
	elseif event == 'ACTIONBAR_UPDATE_USABLE' or event == 'UPDATE_INVENTORY_ALERTS' or event == 'ACTIONBAR_UPDATE_COOLDOWN' then
		BActionButton.ForAllWithAction(BActionButton.UpdateCooldown)
		BActionButton.ForAllWithAction(BActionButton.UpdateUsable)
	elseif event == 'ACTIONBAR_UPDATE_STATE' or event == 'CRAFT_SHOW' or event == 'CRAFT_CLOSE' or event == 'TRADE_SKILL_SHOW' or event == 'TRADE_SKILL_CLOSE' then
		BActionButton.ForAllWithAction(BActionButton.UpdateState)
	elseif event == 'PLAYER_ENTER_COMBAT' or event == 'PLAYER_LEAVE_COMBAT' or event == 'START_AUTOREPEAT_SPELL' or event == 'STOP_AUTOREPEAT_SPELL' then
		BActionButton.ForAllWithAction(BActionButton.UpdateFlash)
	end
end

local function RegisterEvents()
	local frame = CreateFrame("Frame")
	frame:SetScript('OnEvent', OnEvent)
	
	frame:RegisterEvent('ACTIONBAR_PAGE_CHANGED')
	frame:RegisterEvent('UPDATE_SHAPESHIFT_FORM')
	frame:RegisterEvent('UPDATE_STEALTH')

	frame:RegisterEvent('PLAYER_ENTERING_WORLD')
	frame:RegisterEvent('ACTIONBAR_SHOWGRID')
	frame:RegisterEvent('ACTIONBAR_HIDEGRID')	
	frame:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
	frame:RegisterEvent('UPDATE_BINDINGS')

	frame:RegisterEvent('ACTIONBAR_UPDATE_STATE')
	frame:RegisterEvent('ACTIONBAR_UPDATE_USABLE')
	frame:RegisterEvent('ACTIONBAR_UPDATE_COOLDOWN')
	frame:RegisterEvent('UPDATE_INVENTORY_ALERTS')
	frame:RegisterEvent('PLAYER_AURAS_CHANGED')
	frame:RegisterEvent('UNIT_INVENTORY_CHANGED')
	frame:RegisterEvent('CRAFT_SHOW')
	frame:RegisterEvent('CRAFT_CLOSE')
	frame:RegisterEvent('TRADE_SKILL_SHOW')
	frame:RegisterEvent('TRADE_SKILL_CLOSE')
	frame:RegisterEvent('PLAYER_ENTER_COMBAT')
	frame:RegisterEvent('PLAYER_LEAVE_COMBAT')
	frame:RegisterEvent('START_AUTOREPEAT_SPELL')
	frame:RegisterEvent('STOP_AUTOREPEAT_SPELL')

	BVent:AddAction('KEYBOUND_ENABLED', function() BActionBar.UpdateVisibilityForAll(true) end)
	BVent:AddAction('KEYBOUND_DISABLED', function() BActionBar.UpdateVisibilityForAll(nil) end)
end


--[[ Startup ]]--

local eventsLoaded
Bongos.AddStartup(function()
	if not eventsLoaded then 
		RegisterEvents()
		eventsLoaded = true 
	end
end)