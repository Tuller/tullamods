--[[
	Localization.lua
		Translations for Combuctor

	English: Default language
--]]

local L = LibStub("AceLocale-3.0"):NewLocale("Combuctor", "enUS", true)

--these are automatically localized (aka, don't translate them :)
do
	L.All = ALL

	L.Weapon, L.Armor, L.Container, L.Consumable, L.TradeGood, 
	L.Projectile, L.Quiver, L.Recipe, L.Gem, L.Misc, L.Quest = GetAuctionItemClasses()

	L.Trinket = getglobal('INVTYPE_TRINKET')

	L.Devices, L.Explosives = select(10, GetAuctionItemSubClasses(5))

	L.SimpleGem = select(8, GetAuctionItemSubClasses(9))
end

--binding actions
L.ToggleInventory = "Toggle Inventory"
L.ToggleBank = "Toggle Bank"

--frame titles
L.InventoryTitle = "%s's Inventory"
L.BankTitle = "%s's Bank"

--panel names
L.Normal = 'Normal'
L.Equipment = 'Equipment'
L.Keys = 'Keys'
L.Trade = 'Trade'
L.Ammo = 'Ammo'
L.Shards = 'Shards'
L.Usable = 'Usable'
L.SoulShard = 'Soul Shard' --this is a fallback translation,for cases where a person has never seen a soul shard

--tooltips
L.Bank = 'Bank'
L.TotalOnRealm = 'Total on %s'
L.ClickToPurchase = '<Click> to Purchase'