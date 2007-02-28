--[[
	vBagnon\settings.lua
		Loads saved settings and localization data
--]]

--[[ Variable Loading and Updating ]]--

local function LoadDefaults(current)
	BagnonSets = {
		['inventory'] = {
			bags = {0, 1, 2, 3, 4},
			bg = {r = 0, g = 0.2, b = 0, a = 0.5},
		},

		['bank'] = {
			bags = {-1, 5, 6, 7, 8, 9, 10, 11},
			bg = {r = 0, g = 0, b = 0.2, a = 0.5},
		},

		replaceBags = 1,

		showTooltips = 1,
		showForeverTooltips = 1,

		showBagsAtMail = 1,
		showBagsAtVendor = 1,
		showBagsAtBank = 1,
		showBagsAtAH = 1,
		showBankAtBank = 1,

		qualityBorders = 1,

		version = current,
	}
	BagnonMsg(BAGNON_INITIALIZED)
end

local function UpdateSettings(version)
	BagnonSets.version = version
	BagnonSets.showBagsAtMail = 1
	BagnonSets.showBagsAtVendor = 1
	BagnonSets.replaceBank = nil

	BagnonMsg(format(BAGNON_UPDATED, version))
end

BVent:AddAction('PLAYER_LOGIN', function()
	local version = GetAddOnMetadata('Bagnon', 'Version')

	if not(BagnonSets and BagnonSets.inventory and BagnonSets.bank) then
		LoadDefaults(version)
	end

	if TLib.VToN(BagnonSets.version) < TLib.VToN(version) then
		UpdateSettings(version)
	end
end)