--[[
	TPool
		Functions for pooling frames
--]]

assert(TLib, 'TLib not loaded')

local VERSION = '6.11.11'
if TLib.OlderIsBetter(TPool, VERSION) then return end

if not TPool then
	TPool = {
		unused = {},
		count = {}
	}
end
TPool.verison = VERSION

function TPool.Get(type, createFunc)
	local unusedOfType = TPool.unused[type]
	local frame
	if unusedOfType and next(unusedOfType) then
		local id = next(unusedOfType)
		if id then
			frame = unusedOfType[id]
			unusedOfType[id] = nil
		end
	else
		local count = TPool.count
		if not count[type] then
			count[type] = 1
		else
			count[type] = count[type] + 1
		end

		frame = createFunc(count[type])
		frame.id = count[type]
	end
	frame:Show()
	return frame
end

function TPool.Release(frame, type)
	local unused = TPool.unused

	if not unused[type] then
		unused[type] = {}
	end
	unused[type][frame.id] = frame
	
	frame:ClearAllPoints()
	if frame:IsMovable() then
		frame:SetUserPlaced(false)
	end
	frame:SetParent(nil)
	frame:Hide()
end