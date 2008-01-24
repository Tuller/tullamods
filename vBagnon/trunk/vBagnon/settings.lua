--[[
	vBagnon\settings.lua
		Loads saved settings and localization data
--]]

--[[ Variable Loading and Updating ]]--

local function LoadDefaults(playerID)
	BagnonSets[playerID]  = {
		replaceBags = 1,
		replaceBank = 1,

		showTooltips = 1,
		showForeverTooltips = 1,

		showBagsAtBank = 1,
		showBagsAtAH = 1,
		showBankAtBank = 1,

		qualityBorders = 1,

		['inventory'] = {
			bags = {0, 1, 2, 3, 4},

			bg = {r = 0, g = 0.2, b = 0, a = 0.5},

			cats = {
				{
					name = BAGNON_RULE_ALL,
					rule = Bagnon_ToRuleString(BAGNON_RULE_ALL),
				},
				{
					name = BAGNON_TYPE['Weapon'],
					rule = Bagnon_ToRuleString(BAGNON_TYPE['Weapon']),
					hide = 1,
				},
				{
					name = BAGNON_TYPE['Armor'],
					rule = Bagnon_ToRuleString(BAGNON_TYPE['Armor'], getglobal("INVTYPE_TRINKET")),
				},
				{
					name = getglobal("INVTYPE_TRINKET"),
					rule = Bagnon_ToRuleString(getglobal("INVTYPE_TRINKET")),
					hide = 1,
				},
				{
					name = BAGNON_TYPE['Quest'],
					rule = Bagnon_ToRuleString(BAGNON_TYPE['Quest']),
					hide = 1,
				},
				{
					name = BAGNON_TYPE['Trade Goods'],
					rule = Bagnon_ToRuleString(BAGNON_TYPE['Trade Goods']),
					hide = 1,
				},
				{
					name = BAGNON_RULE_TRASH,
					rule = Bagnon_ToRuleString(BAGNON_RULE_TRASH, nil, 'trash'),
					hide = 1,
				}
			},
		},

		['bank'] = {
			bags = {-1, 5, 6, 7, 8, 9, 10, 11},

			bg = {r = 0, g = 0, b = 0.2, a = 0.5},

			cats = {
				{
					name = BAGNON_RULE_ALL,
					rule = Bagnon_ToRuleString(BAGNON_RULE_ALL),
				},
				{
					name = BAGNON_TYPE['Weapon'],
					rule = Bagnon_ToRuleString(BAGNON_TYPE['Weapon']),
					hide = 1,
				},
				{
					name = BAGNON_TYPE['Armor'],
					rule = Bagnon_ToRuleString(BAGNON_TYPE['Armor'], getglobal("INVTYPE_TRINKET")),
				},
				{
					name = getglobal("INVTYPE_TRINKET"),
					rule = Bagnon_ToRuleString(getglobal("INVTYPE_TRINKET")),
					hide = 1,
				},
				{
					name = BAGNON_TYPE['Quest'],
					rule = Bagnon_ToRuleString(BAGNON_TYPE['Quest']),
					hide = 1,
				},
				{
					name = BAGNON_TYPE['Trade Goods'],
					rule = Bagnon_ToRuleString(BAGNON_TYPE['Trade Goods']),
					hide = 1,
				},
				{
					name = BAGNON_TYPE['Recipe'],
					rule = Bagnon_ToRuleString(BAGNON_TYPE['Recipe']),
					hide = 1,
				}
			},
		},
	}
	BagnonMsg(BAGNON_INITIALIZED)
end

local function UpdateSettings(version)
	BagnonSets = {['version'] = version}

	BagnonMsg(format(BAGNON_UPDATED, version))
end

local function LoadVariables()
	local version = GetAddOnMetadata('vBagnon', 'Version')

	if not BagnonSets then
		BagnonSets = {['version'] = version}
	end
	
	if TLib.VToN(BagnonSets.version) < TLib.VToN(version) then
		UpdateSettings(version)
	end
	
	if not BagnonSets[Bagnon_GetPlayerID()] then
		LoadDefaults(Bagnon_GetPlayerID())
	end
end

BEvent:AddAction('PLAYER_LOGIN', LoadVariables)