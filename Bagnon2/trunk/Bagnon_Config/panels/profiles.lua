--[[
	Profiles.lua
		profile configuration settings
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon-Config')
local ProfileOptions = Bagnon.OptionsPanel:New('BagnonOptions_Profile', 'Bagnon', 'Profiles')
Bagnon.ProfileOptions = ProfileOptions

function ProfileOptions:Load()
end

ProfileOptions:Load()