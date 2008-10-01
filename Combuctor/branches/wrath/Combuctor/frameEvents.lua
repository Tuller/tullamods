--[[
	frameEvents.lua
		An event manager for combuctor frames
--]]

local FrameEvents = Combuctor:NewModule('InventoryFrameEvents', 'AceEvent-3.0')
local frames = {}

--a widget for performing delayed updates
local Updater = CreateFrame('Frame')
do
	Updater:SetScript('OnUpdate', function(self)
		FrameEvents:PerformUpdates()
		self:Hide()
	end)
	Updater:Hide()
end

function FrameEvents:Register(f)
	frames[f] = true
end


--[[ Events ]]--

function FrameEvents:OnEnable()
--	self:RegisterMessage('COMBUCTOR_BAG_TYPE_CHANGED')
end

function FrameEvents:COMBUCTOR_BAG_TYPE_CHANGED(msg, bag)
	for frame in pairs(frames) do
		for _,bagID in pairs(frame.sets.bags) do
			if bag == bagID then
				frame.needsBagUpdate = true
				break
			end
		end
	end
	Updater:Show()
end

function FrameEvents:PerformUpdates()
	for frame in pairs(frames) do
		if frame.needsBagUpdate then
			frame:GenerateBagSets()
			frame.needsBagUpdate = nil
		end
	end
end