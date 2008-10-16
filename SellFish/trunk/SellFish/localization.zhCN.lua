--[[
	SellFish Localizion
		Chinese by wowui.cn
--]]

if GetLocale() == "zhCN" then
	local L = SELLFISH_LOCALS

	--system messages
	L.Loaded = "已加载 %s 物品价格"
	L.Updated = "更新到 v%s"
	L.SetStyle = "样式设置为 %s"

	--slash command help 
	L.CommandsHeader = "|cFF33FF99SellFish命令行|r: (/sf 或 /sellfish)"
	L.UnknownCommand = "'|cffffd700%s|r' 不是一个可用的命令"

	L.HelpDesc = "显示命令行"
	L.ResetDesc = "恢复为默认设置"
	L.StyleDesc = "改变物品价格显示方式"

	--tooltips
	L.SellsFor = "售价:"
	L.SellsForMany = "售价 (%s):"
end