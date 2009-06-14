--[[
	General.lua
		General Bagnon settings
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon-Config')
local name, desc = select(2, GetAddOnInfo('Bagnon'))
local GeneralOptions = Bagnon.OptionsPanel:New('BagnonOptions_General', nil, name, desc, [[Interface\Icons\INV_Misc_Bag_07]])
Bagnon.GeneralOptions = GeneralOptions


--[[
	Startup
--]]

function GeneralOptions:Load()
	self:AddWidgets()
	self:UpdateMessages()
end

--[[
	Frame Events
--]]

function GeneralOptions:OnShow()
	self:UpdateMessages()
end

function GeneralOptions:OnHide()
	self:UpdateMessages()
end


--[[
	Messages
--]]

function GeneralOptions:UpdateMessages()
	if not self:IsVisible() then
		self:UnregisterAllMessages()
		return
	end

	self:RegisterMessage('EMPTY_ITEM_SLOT_TEXTURE_UPDATE')
	self:RegisterMessage('ITEM_HIGHLIGHT_QUALITY_UPDATE')
	self:RegisterMessage('ITEM_HIGHLIGHT_QUEST_UPDATE')
end

function GeneralOptions:ITEM_HIGHLIGHT_QUALITY_UPDATE(msg, enable)
	self:GetHighlightItemsByQualityCheckbox():UpdateChecked()
end

function GeneralOptions:ITEM_HIGHLIGHT_QUEST_UPDATE(msg, enable)
	self:GetHighlightQuestItemsCheckbox():UpdateChecked()
end

function GeneralOptions:EMPTY_ITEM_SLOT_TEXTURE_UPDATE(msg, enable)
	self:GetEmptyItemSlotTextureCheckbox():UpdateChecked()
end


--[[
	Widgets
--]]

function GeneralOptions:AddWidgets()
	local showEmptyItemSlotTextures = self:CreateEmptyItemSlotTextureCheckbox()
	showEmptyItemSlotTextures:SetPoint('TOPLEFT', self, 'TOPLEFT', 14, -72)

	local highlightItemsByQuality = self:CreateHighlightItemsByQualityCheckbox()
	highlightItemsByQuality:SetPoint('TOPLEFT', showEmptyItemSlotTextures, 'BOTTOMLEFT', 0, 0)

	local highightQuestItems = self:CreateHighlightQuestItemsCheckbox()
	highightQuestItems:SetPoint('TOPLEFT', highlightItemsByQuality, 'BOTTOMLEFT', 0, 0)
end

function GeneralOptions:UpdateWidgets()
	if not self:IsVisible() then
		return
	end

	self:GetEmptyItemSlotTextureCheckbox():UpdateChecked()
	self:GetHighlightItemsByQualityCheckbox():UpdateChecked()
	self:GetHighlightQuestItemsCheckbox():UpdateChecked()
end


--[[ Checkboxes ]]--

--show empty item slot textures
function GeneralOptions:CreateEmptyItemSlotTextureCheckbox()
	local button = Bagnon.OptionsCheckButton:New(L.ShowEmptyItemSlotBackground, self)

	button.OnEnableSetting = function(self, enable)
		Bagnon.Settings:SetShowEmptyItemSlotTexture(enable)
	end

	button.IsSettingEnabled = function(self)
		return Bagnon.Settings:ShowingEmptyItemSlotTextures()
	end

	self.showEmptyItemsTextureCheckbox = button
	return button
end

function GeneralOptions:GetEmptyItemSlotTextureCheckbox()
	return self.showEmptyItemsTextureCheckbox
end


--highlight items by quality
function GeneralOptions:CreateHighlightItemsByQualityCheckbox()
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

function GeneralOptions:GetHighlightItemsByQualityCheckbox()
	return self.highlightItemsByQualityCheckbox
end


--highlight quest items
function GeneralOptions:CreateHighlightQuestItemsCheckbox()
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

function GeneralOptions:GetHighlightQuestItemsCheckbox()
	return self.highlightQuestItemsCheckbox
end


--[[ Load the thing ]]--

GeneralOptions:Load()