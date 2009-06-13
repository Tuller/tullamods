--[[
	General.lua
		General Bagnon settings
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon-Config')
local name, desc = select(2, GetAddOnInfo('Bagnon'))
local GeneralOptions = Bagnon.OptionsPanel:New('BagnonOptions_General', nil, name, desc, [[Interface\Icons\INV_Misc_Bag_07]])
Bagnon.GeneralOptions = GeneralOptions


function GeneralOptions:Load()
end

GeneralOptions:Load()