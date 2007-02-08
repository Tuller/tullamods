--[[
	Sage_PartyCom
		Functions for sending and recieving party information

	Events Thrown:
		SAGE_COMBAT_UPDATE
			Called when a party member's combat status is updated
			arg1 - unitID
--]]

--[[ Local Globals ]]--

local combatStatus = {}

--[[ Local Functions ]]--

local function SendCombatStatus(inCombat)
	if InCombatLockdown() or inCombat then
		SendAddonMessage('sg', 'combat1', 'PARTY')
	else
		SendAddonMessage('sg', 'combat0', 'PARTY')
	end
end

local function RequestCombatStatus()
	SendAddonMessage('sg', 'combatreq', 'PARTY')
end

local function ParseMessage(msg, sender)
	--combat enter
	if msg == 'combat1' then
		for i = 1, 4 do
			local partyID = 'party' .. i
			if UnitName(partyID) == sender then
				combatStatus[partyID] = true
				BVent:Call('SAGE_COMBAT_UPDATE', partyID)
				return
			end
		end
	--combat leave
	elseif msg == 'combat0' then
		for i = 1, 4 do
			local partyID = 'party' .. i
			if UnitName(partyID) == sender then
				combatStatus[partyID] = nil
				BVent:Call('SAGE_COMBAT_UPDATE', partyID)
				return
			end
		end
	--request combat info
	elseif msg == 'combatreq' then
		SendCombatStatus()
	end
end

--[[ Events ]]--

BVent:AddAction('CHAT_MSG_ADDON', function(_, _, prefix, message, type, sender)
	if prefix == 'sg' and sender ~= UnitName('player') then
		ParseMessage(message, sender)
	end
end)
BVent:AddAction('PLAYER_REGEN_DISABLED', function() SendCombatStatus(true) end)
BVent:AddAction('PLAYER_REGEN_ENABLED',  function() SendCombatStatus(nil) end)
BVent:AddAction('PLAYER_ENTERING_WORLD', function() SendCombatStatus(nil) end)
BVent:AddAction('PARTY_MEMBERS_CHANGED', function() SendCombatStatus(nil) end)
BVent:AddAction('PLAYER_LOGIN', RequestCombatStatus)

--[[ Usable Functions ]]--

SComm = {}

function SComm.InCombat(unit)
	return UnitAffectingCombat(unit) or combatStatus[unit]
end