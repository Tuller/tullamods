--[[
	General.lua
		General Bagnon settings
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon-Config')

--a hack panel, this is designed to force open to the general options panel when clicked
local BagnonOptions = Bagnon.OptionsPanel:New('Bagnon', nil, 'Bagnon')
BagnonOptions:SetScript('OnShow', function(self)
	InterfaceOptionsFrame_OpenToCategory(Bagnon.GeneralOptions)
	self:Hide()
end)

local GeneralOptions = Bagnon.OptionsPanel:New('BagnonOptions_General', 'Bagnon', L.GeneralSettings, L.GeneralSettingsTitle)
Bagnon.GeneralOptions = GeneralOptions

local SPACING = 4


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

	self:RegisterMessage('SHOW_EMPTY_ITEM_SLOT_TEXTURE_UPDATE')
	self:RegisterMessage('ITEM_HIGHLIGHT_QUALITY_UPDATE')
	self:RegisterMessage('ITEM_HIGHLIGHT_QUEST_UPDATE')
	self:RegisterMessage('LOCK_FRAME_POSITIONS_UPDATE')
	self:RegisterMessage('ITEM_SLOT_COLOR_ENABLED_UPDATE')
	self:RegisterMessage('ENABLE_FRAME_UPDATE')
	self:RegisterMessage('BLIZZARD_BAG_PASSTHROUGH_UPDATE')
end

function GeneralOptions:ITEM_HIGHLIGHT_QUALITY_UPDATE(msg, enable)
	self:GetHighlightItemsByQualityCheckbox():UpdateChecked()
end

function GeneralOptions:ITEM_HIGHLIGHT_QUEST_UPDATE(msg, enable)
	self:GetHighlightQuestItemsCheckbox():UpdateChecked()
end

function GeneralOptions:SHOW_EMPTY_ITEM_SLOT_TEXTURE_UPDATE(msg, enable)
	self:GetEmptyItemSlotTextureCheckbox():UpdateChecked()
end

function GeneralOptions:LOCK_FRAME_POSITIONS_UPDATE(msg, enable)
	self:GetLockFramePositionsCheckbox():UpdateChecked()
end

function GeneralOptions:ITEM_SLOT_COLOR_ENABLED_UPDATE(msg, enable)
	self:GetColorItemSlotsCheckbox():UpdateChecked()
end

function GeneralOptions:ENABLE_FRAME_UPDATE(msg, frameID, enable)
	self:GetEnableFrameCheckbox(frameID):UpdateChecked()
end

function GeneralOptions:BLIZZARD_BAG_PASSTHROUGH_UPDATE(msg, enable)
	self:GetBlizzardBagPassThroughCheckbox():UpdateChecked()
end



--[[
	Widgets
--]]

function GeneralOptions:AddWidgets()
	local enableInventory = self:CreateEnableFrameCheckbox('inventory')
	enableInventory:SetPoint('TOPLEFT', self, 'TOPLEFT', 14, -72)
	
	local enableBank = self:CreateEnableFrameCheckbox('bank')
	enableBank:SetPoint('TOPLEFT', enableInventory, 'BOTTOMLEFT', 0, -SPACING)
	
	local enableKeyring = self:CreateEnableFrameCheckbox('keys')
	enableKeyring:SetPoint('TOPLEFT', enableBank, 'BOTTOMLEFT', 0, -SPACING)
	
	local lockFramePositions = self:CreateLockFramePositionsCheckbox()
	lockFramePositions:SetPoint('TOPLEFT', enableKeyring, 'BOTTOMLEFT', 0, -SPACING)
	
	local showEmptyItemSlotTextures = self:CreateEmptyItemSlotTextureCheckbox()
	showEmptyItemSlotTextures:SetPoint('TOPLEFT', lockFramePositions, 'BOTTOMLEFT', 0, -SPACING)
	
	local colorItemSlots = self:CreateColorItemSlotsCheckbox()
	colorItemSlots:SetPoint('TOPLEFT', showEmptyItemSlotTextures, 'BOTTOMLEFT', 0, -SPACING)

	local highlightItemsByQuality = self:CreateHighlightItemsByQualityCheckbox()
	highlightItemsByQuality:SetPoint('TOPLEFT', colorItemSlots, 'BOTTOMLEFT', 0, -SPACING)

	local highightQuestItems = self:CreateHighlightQuestItemsCheckbox()
	highightQuestItems:SetPoint('TOPLEFT', highlightItemsByQuality, 'BOTTOMLEFT', 0, -SPACING)
	
	local enableBlizzardBagPassThrough = self:CreateBlizzardBagPassThroughCheckbox()
	enableBlizzardBagPassThrough:SetPoint('TOPLEFT', highightQuestItems, 'BOTTOMLEFT', 0, -SPACING)
end

function GeneralOptions:UpdateWidgets()
	if not self:IsVisible() then
		return
	end

	self:GetEnableFrameCheckbox('inventory'):UpdateChecked()
	self:GetEnableFrameCheckbox('bank'):UpdateChecked()
	self:GetEnableFrameCheckbox('keyring'):UpdateChecked()

	self:GetEmptyItemSlotTextureCheckbox():UpdateChecked()
	self:GetHighlightItemsByQualityCheckbox():UpdateChecked()
	self:GetHighlightQuestItemsCheckbox():UpdateChecked()
	self:GetColorItemSlotsCheckbox():UpdateChecked()
	self:GetBlizzardBagPassThroughCheckbox():UpdateChecked()
end


--[[ Checkboxes ]]--

function GeneralOptions:CreateEnableFrameCheckbox(frameID)
	local button = Bagnon.OptionsCheckButton:New(L['EnableFrame_' .. frameID], self)
	button.frameID = frameID

	button.OnEnableSetting = function(self, enable)
		Bagnon.Settings:SetEnableFrame(self.frameID, enable)
		GeneralOptions:DisplayRequiresRestartPopup()
	end

	button.IsSettingEnabled = function(self)
		return Bagnon.Settings:WillFrameBeEnabled(self.frameID)
	end

	self['enableFrame_' .. frameID .. '_Checkbox'] = button
	return button
end

function GeneralOptions:GetEnableFrameCheckbox(frameID)
	return self['enableFrame_' .. frameID .. '_Checkbox']
end

function GeneralOptions:DisplayRequiresRestartPopup()
	self:CreateRequiresRestartDialog()
	StaticPopup_Show('BAGNON_CONFIRM_REQUIRES_RESTART')
end

function GeneralOptions:CreateRequiresRestartDialog()
	if not StaticPopupDialogs['BAGNON_CONFIRM_REQUIRES_RESTART'] then
		StaticPopupDialogs['BAGNON_CONFIRM_REQUIRES_RESTART'] = {
			text = L.SettingRequiresRestart,
			button1 = OKAY,
			timeout = 0, exclusive = 1, hideOnEscape = 1
		}
	end
end

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


--lock frame positions
function GeneralOptions:CreateLockFramePositionsCheckbox()
	local button = Bagnon.OptionsCheckButton:New(L.LockFramePositions, self)

	button.OnEnableSetting = function(self, enable)
		Bagnon.Settings:SetLockFramePositions(enable)
	end

	button.IsSettingEnabled = function(self)
		return Bagnon.Settings:AreFramePositionsLocked()
	end

	self.lockFramePositionsCheckbox = button
	return button
end

function GeneralOptions:GetLockFramePositionsCheckbox()
	return self.lockFramePositionsCheckbox
end


--color item slots
function GeneralOptions:CreateColorItemSlotsCheckbox()
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

function GeneralOptions:GetColorItemSlotsCheckbox()
	return self.colorItemSlotsCheckbox
end


--blizzard bag passthrough
function GeneralOptions:CreateBlizzardBagPassThroughCheckbox()
	local button = Bagnon.OptionsCheckButton:New(L.EnableBlizzardBagPassThrough, self)

	button.OnEnableSetting = function(self, enable)
		Bagnon.Settings:SetEnableBlizzardBagPassThrough(enable)
		GeneralOptions:DisplayRequiresRestartPopup()
	end

	button.IsSettingEnabled = function(self)
		return Bagnon.Settings:WillBlizzardBagPassThroughBeEnabled()
	end

	self.blizzardBagPassThroughCheckbox = button
	return button
end

function GeneralOptions:GetBlizzardBagPassThroughCheckbox()
	return self.blizzardBagPassThroughCheckbox
end 


--[[ Load the thing ]]--

GeneralOptions:Load()