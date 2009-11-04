--[[
	Frame.lua
		General Bagnon settings
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon-Config')
local ColorOptions = Bagnon.OptionsPanel:New('BagnonOptions_Colors', 'Bagnon', L.ColorSettings, L.ColorSettingsTitle)
ColorOptions:Hide()

Bagnon.ColorOptions = ColorOptions

local SPACING = 4


--[[
	Startup
--]]

function ColorOptions:Load()
	self:SetScript('OnShow', self.OnShow)
	self:SetScript('OnHide', self.OnHide)
	self:AddWidgets()
end

function ColorOptions:ShowFrame(frameID)
	self:SetFrameID(frameID)
	InterfaceOptionsFrame_OpenToCategory(self)
end


--[[
	Messages
--]]

function ColorOptions:UpdateMessages()
	if not self:IsVisible() then
		self:UnregisterAllMessages()
		return
	end
	
	self:RegisterMessage('ITEM_HIGHLIGHT_QUALITY_UPDATE')
	self:RegisterMessage('ITEM_HIGHLIGHT_QUEST_UPDATE')
	self:RegisterMessage('ITEM_SLOT_COLOR_ENABLED_UPDATE')
	self:RegisterMessage('ITEM_SLOT_COLOR_UPDATE')
end

function ColorOptions:ITEM_HIGHLIGHT_QUALITY_UPDATE(msg, enable)
	self:GetHighlightItemsByQualityCheckbox():UpdateChecked()
end

function ColorOptions:ITEM_HIGHLIGHT_QUEST_UPDATE(msg, enable)
	self:GetHighlightQuestItemsCheckbox():UpdateChecked()
end

function ColorOptions:ITEM_SLOT_COLOR_ENABLED_UPDATE(msg, enable)
	self:GetColorItemSlotsCheckbox():UpdateChecked()
end

function ColorOptions:ITEM_SLOT_COLOR_UPDATE(msg, type, r, g, b)
	--update colorpicker
end



--[[
	Frame Events
--]]

function ColorOptions:OnShow()
	self:UpdateMessages()
end

function ColorOptions:OnHide()
	self:UpdateMessages()
end


--[[
	Components
--]]

function ColorOptions:AddWidgets()
	local colorItemSlots = self:CreateColorItemSlotsCheckbox()
	colorItemSlots:SetPoint('TOPLEFT', self, 'TOPLEFT', 14, -72)

	local highlightItemsByQuality = self:CreateHighlightItemsByQualityCheckbox()
	highlightItemsByQuality:SetPoint('TOPLEFT', colorItemSlots, 'BOTTOMLEFT', 0, -SPACING)

	local highightQuestItems = self:CreateHighlightQuestItemsCheckbox()
	highightQuestItems:SetPoint('TOPLEFT', highlightItemsByQuality, 'BOTTOMLEFT', 0, -SPACING)
end

function ColorOptions:UpdateWidgets()
	if not self:IsVisible() then
		return
	end

	self:GetHighlightItemsByQualityCheckbox():UpdateChecked()
	self:GetHighlightQuestItemsCheckbox():UpdateChecked()
	self:GetColorItemSlotsCheckbox():UpdateChecked()
end


--[[ Check Boxes ]]--


--highlight items by quality
function ColorOptions:CreateHighlightItemsByQualityCheckbox()
	local button = Bagnon.OptionsCheckButton:New(L.HighlightItemsByQuality, self)

	button.OnEnableSetting = function(self, enable)
		Bagnon.Settings:SetHighlightItemsByQuality(enable)
	end

	button.IsSettingEnabled = function(self)
		return Bagnon.Settings:HighlightingItemsByQuality()
	end

	self.highlightItemsByQualityCheckbox = button
	return button
end

function ColorOptions:GetHighlightItemsByQualityCheckbox()
	return self.highlightItemsByQualityCheckbox
end


--highlight quest items
function ColorOptions:CreateHighlightQuestItemsCheckbox()
	local button = Bagnon.OptionsCheckButton:New(L.HighlightQuestItems, self)

	button.OnEnableSetting = function(self, enable)
		Bagnon.Settings:SetHighlightQuestItems(enable)
	end

	button.IsSettingEnabled = function(self)
		return Bagnon.Settings:HighlightingQuestItems()
	end

	self.highlightQuestItemsCheckbox = button
	return button
end

function ColorOptions:GetHighlightQuestItemsCheckbox()
	return self.highlightQuestItemsCheckbox
end


--color item slots
function ColorOptions:CreateColorItemSlotsCheckbox()
	local button = Bagnon.OptionsCheckButton:New(L.ColorItemSlotsByBagType, self)

	button.OnEnableSetting = function(self, enable)
		Bagnon.Settings:SetColorBagSlots(enable)
	end

	button.IsSettingEnabled = function(self)
		return Bagnon.Settings:ColoringBagSlots()
	end

	self.colorItemSlotsCheckbox = button
	return button
end

function ColorOptions:GetColorItemSlotsCheckbox()
	return self.colorItemSlotsCheckbox
end


--[[
	Update Methods
--]]

function ColorOptions:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
		self:UpdateWidgets()
	end
end

function ColorOptions:GetFrameID()
	return self.frameID
end


--[[ Load the thing ]]--

ColorOptions:Load()