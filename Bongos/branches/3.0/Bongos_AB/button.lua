--[[
	ActionButton - A Bongos ActionButton
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local Action = Bongos:GetModule('ActionBar')

local ActionButton = Bongos:CreateWidgetClass('CheckButton')
Action.Button = ActionButton

local unused = {}

do
	local id = 1
	function ActionButton:Create(parent)
		local b = self:New(CreateFrame('CheckButton', format('Bongos3ActionButton%d', id), parent, 'SecureActionButtonTemplate, ActionButtonTemplate'))
		id = id + 1
		return b
	end
end

function ActionButton:Get(parent)
	return self:GetUnused(parent) or self:Create(parent)
end

function ActionButton:GetUnused(parent)
	local button = next(unused)
	if button then
		unused[button] = nil
		button:SetParent(parent)
		return button
	end
end

function ActionButton:Release()
	self:Hide()
	self:SetParent(nil)
	unused[self] = true
end