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
	return Bagnon.SavedSettings:GetCurrentProfile()
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


--item slot ordering
function Settings:SetReverseSlotOrder(enable)
	if self:IsSlotOrderReversed() ~= enable then
		self:GetDB().reverseSlotOrder = enable
		self:SendMessage('SLOT_ORDER_UPDATE', enable)
	end
end

function Settings:IsSlotOrderReversed()
	return self:GetDB().reverseSlotOrder
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