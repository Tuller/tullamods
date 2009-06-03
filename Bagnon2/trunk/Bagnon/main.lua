--[[
	main.lua
		The bagnon loader thingy
--]]

Bagnon = LibStub('AceAddon-3.0'):NewAddon('Bagnon', 'AceEvent-3.0', 'AceConsole-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')

--bindings
BINDING_HEADER_BAGNON = 'Bagnon'
BINDING_NAME_BAGNON_TOGGLE = L.ToggleBags
BINDING_NAME_BANKNON_TOGGLE = L.ToggleBank
BINDING_NAME_BAGNON_KEYS_TOGGLE = L.ToggleKeys

--[[ Startup ]]--

function Bagnon:OnEnable()
	self:CreateInventoryFrame()
	self:CreateBankFrame()
	self:CreateKeyRing()
end

function Bagnon:CreateInventoryFrame()
	self.Frame:New('inventory')
end

function Bagnon:CreateBankFrame()
	self.Frame:New('bank')
end

function Bagnon:CreateKeyRing()
	self.Frame:New('keys')
end

function Bagnon:SetPlayer(player)
	self.FrameSettings:Get('inventory'):SetPlayerFilter(player)
	self.FrameSettings:Get('bank'):SetPlayerFilter(player)
	self.FrameSettings:Get('keys'):SetPlayerFilter(player)
end