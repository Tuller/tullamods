--[[
	main.lua
		The bagnon loader thingy
--]]

Bagnon = LibStub('AceAddon-3.0'):NewAddon('Bagnon', 'AceEvent-3.0', 'AceConsole-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')

--bindings
BINDING_HEADER_BAGNON = 'Bagnon'
BINDING_NAME_BAGNON_TOGGLE = L.BagnonToggle
BINDING_NAME_BANKNON_TOGGLE = L.BanknonToggle

--[[ Startup ]]--

function Bagnon:OnEnable()
	self:CreateInventoryFrame()
	self:CreateBankFrame()
	self:CreateKeyRing()
end

function Bagnon:CreateInventoryFrame()
	local sets = self.FrameSettings:Get('inventory')
	sets:SetBagSlots(BACKPACK_CONTAINER, 1, 2, 3, 4)

	self.Frame:New('inventory')
	sets:ShowFrame()
end

function Bagnon:CreateBankFrame()
	local sets = self.FrameSettings:Get('bank')
	sets:SetBagSlots(BANK_CONTAINER, 5, 6, 7, 8, 9, 10, 11)
	
	self.Frame:New('bank')
	sets:ShowFrame()
end

function Bagnon:CreateKeyRing()
	local sets = self.FrameSettings:Get('keys')
	sets:SetBagSlots(KEYRING_CONTAINER)

	self.Frame:New('keys')
	sets:ShowFrame()
end

function Bagnon:SetPlayer(player)
	self.FrameSettings:Get('inventory'):SetPlayerFilter(player)
	self.FrameSettings:Get('bank'):SetPlayerFilter(player)
	self.FrameSettings:Get('keys'):SetPlayerFilter(player)
end