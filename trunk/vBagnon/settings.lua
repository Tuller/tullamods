--[[
	vBagnon\settings.lua
		Loads saved settings and localization data
--]]

--[[ Variable Loading and Updating ]]--

local function LoadGlobalDefaults(current)
	BagnonSettings = {
		replaceBags = 1,
		replaceBank = 1,

		showTooltips = 1,
		showForeverTooltips = 1,

		showBagsAtBank = 1,
		showBagsAtAH = 1,
		showBankAtBank = 1,

		qualityBorders = 1,
		version = current,
	}
end

local function LoadDefaults(playerID)
	BagnonSettings[playerID]  = {
		['inventory'] = {
			bags = {0, 1, 2, 3, 4},
			bg = {r = 0, g = 0.2, b = 0, a = 0.5},
			cats = {{show = 1}},
		},

		['bank'] = {
			bags = {-1, 5, 6, 7, 8, 9, 10, 11},
			bg = {r = 0, g = 0, b = 0.2, a = 0.5},
			cats = {{show = 1}},
		},
	}
	BagnonMsg(BAGNON_INITIALIZED)
end

local function UpdateSettings(version)
	BagnonSettings.version = version

	BagnonMsg(format(BAGNON_UPDATED, version))
end

BVent:AddAction('PLAYER_LOGIN', function()
	local version = GetAddOnMetadata('vBagnon', 'Version')

	if not BagnonSettings then
		LoadGlobalDefaults(version)
	end

	if TLib.VToN(BagnonSettings.version) < TLib.VToN(version) then
		UpdateSettings(version)
	end

	if not BagnonLib.GetPlayerSets() then
		LoadDefaults(BagnonLib.GetPlayerID())
	end
end)


local INVENTORY_BAGS = {-2, 0, 1, 2, 3, 4}

function Bagnon_Create()
	BagnonFrame.Create("%s's Inventory", BagnonLib.GetPlayerSets().inventory, INVENTORY_BAGS)
end

function Bagnon_CreateC(player)
	local sets = BagnonLib.GetPlayerSets(player)
	local frame = BagnonFrame.CreateTempOfSaved("%s's Inventory", sets.inventory, INVENTORY_BAGS)
	frame:SetPlayer(player)
	BagnonMsg(frame:GetName())
end