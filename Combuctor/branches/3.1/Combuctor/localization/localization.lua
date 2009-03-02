﻿--[[
	Localization.lua
		Translations for Combuctor

	English: Default language
--]]

local L = LibStub("AceLocale-3.0"):NewLocale("Combuctor", "enUS", true)

L.Updated = 'Updated to v%s'

--binding actions
L.ToggleInventory = "Toggle Inventory"
L.ToggleBank = "Toggle Bank"

--frame titles
L.InventoryTitle = "%s's Inventory"
L.BankTitle = "%s's Bank"

--tooltips
L.Inventory = 'Inventory'
L.Bank = 'Bank'
L.TotalOnRealm = 'Total on %s'
L.ClickToPurchase = '<Click> to Purchase'
L.Bags = 'Bags'
L.BagToggle = '<LeftClick> To Toggle Showing Bags'
L.InventoryToggle = '<RightClick> To Toggle the Inventory Frame'
L.BankToggle = '<RightClick> To Toggle the Bank Frame'
L.MoveTip = '<Alt-LeftDrag> To Move'
L.ResetPositionTip = '<RightClick> To Reset Position'

--default sets (need to be here because of a flaw in how I save things
--these are automatically localized (aka, don't translate them :)
do
	L.All = ALL

	L.Weapon, L.Armor, L.Container, L.Consumable, L.Glyph, L.TradeGood, 
 	L.Projectile, L.Quiver, L.Recipe, L.Gem, L.Misc, L.Quest = GetAuctionItemClasses()

	L.Trinket = getglobal('INVTYPE_TRINKET')

	L.Devices, L.Explosives = select(10, GetAuctionItemSubClasses(6))

	L.SimpleGem = select(8, GetAuctionItemSubClasses(7))
end

L.Normal = 'Normal'
L.Equipment = 'Equipment'
L.Keys = 'Keys'
L.Trade = 'Trade'
L.Ammo = 'Ammo'
L.Shards = 'Shards'
L.SoulShard = 'Soul Shard'
L.Usable = 'Usable'