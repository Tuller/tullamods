--[[
	BVent
		An small event handler.
--]]

assert(TLib, "TLib not loaded")

--[[ Version Checking ]]--

local VERSION = '7.1.2'
if TLib.IsCurrent(BVent, VERSION) then return end


--[[ locals ]]--

--these events only fire once
local fireOnce = {'PLAYER_LOGIN', 'VARIABLES_LOADED'}

local function RemoveEvent(event)
	BVent.events[event] = nil
	BVent:UnregisterEvent(event)
end

if not BVent then
	BVent = CreateFrame('Frame')
	BVent:SetScript('OnEvent', function()
		BVent:Call(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
		if fireOnce[event] then RemoveEvent(event) end
	end)
	BVent.events = {}
end
BVent.version = VERSION


--[[ Usable Functions ]]--

--adds an action to the given event
function BVent:AddAction(event, action)
	if action then
		local events = self.events
		if events[event] then
			table.insert(events[event], action)
		else
			events[event] = {action}
			self:RegisterEvent(event)
		end
	end
end

--removes the given action from the given event
function BVent:RemoveAction(event, action)
	if action then
		local actions = self.events[event]
		if actions then
			local index	
			for i, act in pairs(actions) do
				if act == action then
					actions[i] = nil
					break
				end
			end

			if not next(actions) then
				RemoveEvent(event)
			end
		end
	end
end

--Calls an event with the given arguments
function BVent:Call(event, ...)
	local actions = self.events[event]
	if actions then
		for _,action in pairs(actions) do
			action(action, event, ...)
		end
	end
end