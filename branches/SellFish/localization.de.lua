--[[
	SellFish English Localization File
		This file must be loaded, as it fills in the gaps for partial translations
--]]

if GetLocale() == "deDE" then
	local L = SELLFISH_LOCALS

	--system messages
	L.Loaded = "%s Gegenstandswerte geladen"
	L.Updated = "Auf v%s aktualisiert"
	L.SetStyle = "Style auf %s eingestellt"

	--slash command help
	L.CommandsHeader = "|cFF33FF99SellFish-Befehle|r: (/sf or /sellfish)"
	L.UnknownCommand = "'|cffffd700%s|r' ist ein unbekannter Befehl"

	L.HelpDesc = "Zeigt die Befehle an"
	L.ResetDesc = "Setzt die Verkaufswert-Datenbank zur\195\188ck"
	L.StyleDesc = "Style der Verkaufspreisanzeige umschalten"
	L.CompressDesc = "Komprimiert die Verkaufspreis-Datenbank"

	--tooltips
	L.SellsFor = "Verkauf f\195\188r:"
	L.SellsForMany = "Verkauf f\195\188r (%s):"
end