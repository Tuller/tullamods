--[[
	SellFish Localizion
		ChineseTW by 巨龍之喉 曉漁
--]]

if GetLocale() == "zhTW" then
	local L = SELLFISH_LOCALS

	--system messages
	L.Loaded = "已加載 %s 物品售價"
	L.Updated = "更新到 v%s"
	L.SetStyle = "樣式設置為 %s"

	--slash command help 
	L.CommandsHeader = "|cFF33FF99SellFish命令行|r: (/sf 或 /sellfish)"
	L.UnknownCommand = "'|cffffd700%s|r' 不是一個可用的命令"

	L.HelpDesc = "顯示命令行"
	L.ResetDesc = "恢復為默認設置"
	L.StyleDesc = "改變物品價格顯示方式"

	--tooltips
	L.SellsFor = "售價:"
	L.SellsForMany = "數量(%s) 售價:"
end