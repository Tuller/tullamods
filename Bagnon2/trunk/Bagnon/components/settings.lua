--[[
	profileSettings.lua
		Handles non specific frame settings
--]]

local Settings = {}
local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
Bagnon.Settings = Settings


--[[---------------------------------------------------------------------------
	Accessor Methods
--]]---------------------------------------------------------------------------


function Settings:GetDB()
	return Bagnon.SavedSettings:GetDB()
end


--[[---------------------------------------------------------------------------
	Message Passing
--]]---------------------------------------------------------------------------

function Settings:SendMessage(msg, ...)
	Bagnon.Callbacks:SendMessage(msg, ...)
end


--[[---------------------------------------------------------------------------
	Settings...Setting
--]]---------------------------------------------------------------------------

--highlight items by quality
function Settings:SetHighlightItemsByQuality(enable)
	if self:HighlightingItemsByQuality() ~= enable then
		self:GetDB().highlightItemsByQuality = enable
		self:SendMessage('ITEM_HIGHLIGHT_QUALITY_UPDATE', enable)
	end
end

function Settings:HighlightingItemsByQuality()
	return self:GetDB().highlightItemsByQuality
end

--highlight quest items
function Settings:SetHighlightQuestItems(enable)
	if self:HighlightingQuestItems() ~= enable then
		self:GetDB().highlightQuestItems = enable
		self:SendMessage('ITEM_HIGHLIGHT_QUEST_UPDATE', enable)
	end
end

function Settings:HighlightingQuestItems()
	return self:GetDB().highlightQuestItems
end


--show empty item slots
function Settings:SetShowEmptyItemSlotTexture(enable)
	if self:ShowingEmptyItemSlotTextures() ~= enable then
		self:GetDB().showEmptyItemSlotTexture = enable
		self:SendMessage('SHOW_EMPTY_ITEM_SLOT_TEXTURE_UPDATE', enable)
	end
end

function Settings:ShowingEmptyItemSlotTextures()
	return self:GetDB().showEmptyItemSlotTexture
end


--lock frame positions
function Settings:SetLockFramePositions(enable)
	if self:AreFramePositionsLocked() ~= enable then
		self:GetDB().lockFramePositions = enable
		self:SendMessage('LOCK_FRAME_POSITIONS_UPDATE', enable)
	end
end

function Settings:AreFramePositionsLocked()
	return self:GetDB().lockFramePositions
end


--item slot coloring
function Settings:SetColorBagSlots(enable)
	if self:ColoringBagSlots() ~= enable then
		self:GetDB().colorBagSlots = enable
		self:SendMessage('ITEM_SLOT_COLOR_UPDATE', enable)
	end
end

function Settings:ColoringBagSlots()
	return self:GetDB().colorBagSlots
end

--enable frames
function Settings:SetEnableFrame(frameID, enable)
	local enable = enable and true or false
	if self:WillFrameBeEnabled(frameID) ~= enable then
		self.framesToEnable = self.framesToEnable or setmetatable({}, {__index = self:GetDB().enabledFrames})
		self.framesToEnable[frameID] = enable and true or false

		self:SendMessage('ENABLE_FRAME_UPDATE', frameID, self:WillFrameBeEnabled(frameID))
	end
end

function Settings:IsFrameEnabled(frameID)
	return self:GetDB().enabledFrames[frameID] and true or false
end

function Settings:WillFrameBeEnabled(frameID)
	self.framesToEnable = self.framesToEnable or setmetatable({}, {__index = self:GetDB().enabledFrames})
	return self.framesToEnable[frameID]
end

function Settings:AreAllFramesEnabled()
	for frameID, isEnabled in pairs(self:GetDB().enabledFrames) do
		if not isEnabled then
			return false
		end
	end
	return true
end


--automatic frame display
function Settings:SetShowFrameAtEvent(frameID, event, enable)
	local enable = enable and true or false
	if self:IsFrameShownAtEvent(frameID, event) ~= enable then
		Bagnon.SavedSettings:SetShowFrameAtEvent(frameID, event, enable)
		self:SendMessage('FRAME_DISPLAY_EVENT_UPDATE', frameID, self:IsFrameShownAtEvent(frameID, event))
	end
end

function Settings:IsFrameShownAtEvent(frameID, event)
	return Bagnon.SavedSettings:IsFrameShownAtEvent(frameID, event)
end