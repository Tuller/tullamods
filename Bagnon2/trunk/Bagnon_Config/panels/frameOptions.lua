--[[
	Frame.lua
		General Bagnon settings
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon-Config')
local FrameOptions = Bagnon.OptionsPanel:New('BagnonOptions_Frame', 'Bagnon', 'Frame Settings', 'Configuration settings specific to a Bagnon frame')
FrameOptions:Hide()

Bagnon.FrameOptions = FrameOptions


--[[ 
	Startup
--]]

function FrameOptions:Load()
	self:SetFrameID('inventory')
	self:SetScript('OnShow', self.OnShow)
	self:SetScript('OnHide', self.OnHide)
	self:AddWidgets()
end

function FrameOptions:ShowFrame(frameID)
	self:SetFrameID(frameID)
	InterfaceOptionsFrame_OpenToCategory(self)
end

function FrameOptions:AddWidgets()
	--add frame selector
	local frameSelector = self:CreateFrameSelector()
	frameSelector:SetPoint('TOPLEFT', self, 'TOPLEFT', -4, -64)

	--[[ Colors ]]--
	
	--add color selector
	local frameColor = self:CreateColorSelector()
	frameColor:SetPoint('TOPLEFT', frameSelector, 'BOTTOMLEFT', 16, -8)
		
	--add border colors selector
	local frameBorderColor = self:CreateBorderColorSelector()
	frameBorderColor:SetPoint('TOPLEFT', frameColor, 'BOTTOMLEFT', 0, -4)

	--[[ checkboxes ]]--
	
	--lock position
	local lockPosition = self:CreateLockPositionCheckbox()
	lockPosition:SetPoint('TOPLEFT', frameBorderColor, 'BOTTOMLEFT', -4, -2)
	
	--toplevel
	
	--[[ Sliders ]]--
	
	--add frame strata slider?
	
	--add opacity slider
	local opacity = self:CreateOpacitySlider()
	opacity:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', 12, 16)
	opacity:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -48, 16)
	
	--add scale slider
	local scale = self:CreateScaleSlider()
	scale:SetPoint('BOTTOMLEFT', opacity, 'TOPLEFT', 0, 20)
	scale:SetPoint('BOTTOMRIGHT', opacity, 'TOPRIGHT', 0, 20)
	
	--add scale slider
	local spacing = self:CreateSpacingSlider()
	spacing:SetPoint('BOTTOMLEFT', scale, 'TOPLEFT', 0, 20)
	spacing:SetPoint('BOTTOMRIGHT', scale, 'TOPRIGHT', 0, 20)
	
	--add scale slider
	local cols = self:CreateColumnsSlider()
	cols:SetPoint('BOTTOMLEFT', spacing, 'TOPLEFT', 0, 20)
	cols:SetPoint('BOTTOMRIGHT', spacing, 'TOPRIGHT', 0, 20)
end


--[[
	Messages
--]]

function FrameOptions:FRAME_SCALE_UPDATE(msg, frameID, scale)
	if self:GetFrameID() == frameID then
		self:GetScaleSlider():SetValue(scale * 100)
	end
end

function FrameOptions:FRAME_OPACITY_UPDATE(msg, frameID, opacity)
	if self:GetFrameID() == frameID then
		self:GetOpacitySlider():SetValue(opacity * 100)
	end
end

function FrameOptions:FRAME_COLOR_UPDATE(msg, frameID, r, g, b, a)
	if self:GetFrameID() == frameID then
		self:GetColorSelector():SetColor(r, g, b, a)
	end
end

function FrameOptions:FRAME_BORDER_COLOR_UPDATE(msg, frameID, r, g, b, a)
	if self:GetFrameID() == frameID then
		self:GetBorderColorSelector():SetColor(r, g, b, a)
	end
end

function FrameOptions:ITEM_FRAME_SPACING_UPDATE(msg, frameID, spacing)
	if self:GetFrameID() == frameID then
		self:GetSpacingSlider():SetValue(spacing)
	end
end

function FrameOptions:ITEM_FRAME_COLUMNS_UPDATE(msg, frameID, columns)
	if self:GetFrameID() == frameID then
		self:GetColumnsSlider():SetValue(columns)
	end
end

function FrameOptions:FRAME_MOVABLE_UPDATE(msg, frameID, canMoveFrame)
	if self:GetFrameID() == frameID then
		self:GetLockPositionCheckBox():EnableSetting(not canMoveFrame)
	end
end


--[[
	Frame Events
--]]

function FrameOptions:OnShow()
	self:UpdateMessages()
--	self:UpdateWidgets()
end

function FrameOptions:OnHide()
	self:UpdateMessages()
end


--[[ 
	Components
--]]


--[[ Dropdowns ]]--

--frame selector
function FrameOptions:CreateFrameSelector()
	local dropdown = Bagnon.OptionsDropdown:New(L.Frame, self, 200)
	dropdown.titleText:Hide()

	dropdown.Initialize = function(self)
		self:AddItem(L.Inventory, 'inventory')
		self:AddItem(L.Bank, 'bank')
		self:AddItem(L.KeyRing, 'keys')
	end

	dropdown.SetSavedValue = function(self, value)
		self:GetParent():SetFrameID(value)
	end

	dropdown.GetSavedValue = function(self)
		return self:GetParent():GetFrameID()
	end

	self.frameSelector = dropdown
	return dropdown
end

function FrameOptions:GetFrameSelector()
	return self.frameSelector
end


--[[ Color Pickers ]]--

--frame color
function FrameOptions:CreateColorSelector()
	local selector = Bagnon.OptionsColorSelector:New(L.FrameColor, self, true)
	
	selector.OnSetColor = function(self, r, g, b, a)
		self:GetParent():GetSettings():SetFrameColor(r, g, b, a)
	end
	
	selector.GetColor = function(self)
		return self:GetParent():GetSettings():GetFrameColor()
	end
	
	self.colorSelector = selector
	return selector
end

function FrameOptions:GetColorSelector()
	return self.colorSelector
end

--background color
function FrameOptions:CreateBorderColorSelector()
	local selector = Bagnon.OptionsColorSelector:New(L.FrameBorderColor, self, true)
	
	selector.OnSetColor = function(self, r, g, b, a)
		self:GetParent():GetSettings():SetFrameBorderColor(r, g, b, a)
	end
	
	selector.GetColor = function(self)
		return self:GetParent():GetSettings():GetFrameBorderColor()
	end
	
	self.borderColorSelector = selector
	return selector
end

function FrameOptions:GetBorderColorSelector()
	return self.borderColorSelector
end


--[[ Sliders ]]--

--columns
function FrameOptions:CreateColumnsSlider()
	local slider = Bagnon.OptionsSlider:New(L.Columns, self, 4, 36, 1)

	slider.SetSavedValue = function(self, value)
		self:GetParent():GetSettings():SetItemFrameColumns(value)
	end

	slider.GetSavedValue = function(self)
		return self:GetParent():GetSettings():GetItemFrameColumns()
	end

	self.columnsSlider = slider
	return slider
end

function FrameOptions:GetColumnsSlider()
	return self.columnsSlider
end

--spacing
function FrameOptions:CreateSpacingSlider()
	local slider = Bagnon.OptionsSlider:New(L.Spacing, self, -16, 36, 2)

	slider.SetSavedValue = function(self, value)
		self:GetParent():GetSettings():SetItemFrameSpacing(value)
	end

	slider.GetSavedValue = function(self)
		return self:GetParent():GetSettings():GetItemFrameSpacing()
	end

	self.spacingSlider = slider
	return slider
end

function FrameOptions:GetSpacingSlider()
	return self.spacingSlider
end

--scale
function FrameOptions:CreateScaleSlider()
	local slider = Bagnon.OptionsSlider:New(L.Scale, self, 50, 200, 5)

	slider.SetSavedValue = function(self, value)
		self:GetParent():GetSettings():SetFrameScale(value / 100)
	end

	slider.GetSavedValue = function(self)
		return self:GetParent():GetSettings():GetFrameScale() * 100
	end

	slider.GetFormattedText = function(self, value)
		return value .. '%'
	end

	self.scaleSlider = slider
	return slider
end

function FrameOptions:GetScaleSlider()
	return self.scaleSlider
end

--opacity
function FrameOptions:CreateOpacitySlider()
	local slider = Bagnon.OptionsSlider:New(L.Opacity, self, 10, 100, 1)

	slider.SetSavedValue = function(self, value)
		self:GetParent():GetSettings():SetFrameOpacity(value / 100)
	end

	slider.GetSavedValue = function(self)
		return self:GetParent():GetSettings():GetFrameOpacity() * 100
	end

	slider.GetFormattedText = function(self, value)
		return value .. '%'
	end

	self.opacitySlider = slider
	return slider
end

function FrameOptions:GetOpacitySlider()
	return self.opacitySlider
end


--[[ Check Boxes ]]--

function FrameOptions:CreateLockPositionCheckbox()
	local button = Bagnon.OptionsCheckButton:New(L.LockFramePosition, self)
	
	button.OnEnableSetting = function(self, enable)
		self:GetParent():GetSettings():SetMovable(not enable)
	end
	
	button.IsSettingEnabled = function(self, enable)
		return not self:GetParent():GetSettings():IsMovable()
	end
	
	self.lockPositionCheckbox = button
	return button
end

function FrameOptions:GetLockPositionCheckBox()
	return self.lockPositionCheckbox
end


--[[ 
	Update Methods
--]]

function FrameOptions:UpdateMessages()
	if not self:IsVisible() then
		self:UnregisterAllMessages()
		return
	end

	self:RegisterMessage('FRAME_SCALE_UPDATE')
	self:RegisterMessage('FRAME_OPACITY_UPDATE')
	self:RegisterMessage('FRAME_COLOR_UPDATE')
	self:RegisterMessage('FRAME_BORDER_COLOR_UPDATE')
	self:RegisterMessage('ITEM_FRAME_SPACING_UPDATE')
	self:RegisterMessage('ITEM_FRAME_COLUMNS_UPDATE')
	self:RegisterMessage('FRAME_MOVABLE_UPDATE')
end

function FrameOptions:UpdateWidgets()
	if not self:IsVisible() then 
		return 
	end

	local settings = self:GetSettings()

	self:GetColorSelector():SetColor(settings:GetFrameColor())
	self:GetBorderColorSelector():SetColor(settings:GetFrameBorderColor())

	self:GetColumnsSlider():SetValue(settings:GetItemFrameColumns())
	self:GetSpacingSlider():SetValue(settings:GetItemFrameSpacing())

	self:GetScaleSlider():SetValue(settings:GetFrameScale() * 100)
	self:GetOpacitySlider():SetValue(settings:GetFrameOpacity() * 100)
	
	self:GetLockPositionCheckBox():EnableSetting(not settings:IsMovable())
end

function FrameOptions:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
		self:UpdateWidgets()
	end
end

function FrameOptions:GetFrameID()
	return self.frameID
end

function FrameOptions:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end


--[[ Load the thing ]]--

FrameOptions:Load()