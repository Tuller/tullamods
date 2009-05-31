--[[
	THIS FILE IS ENCODED IN UTF-8

	Bagnon Localization file: Chinese Simplified
		Credit: Diablohu, yleaf, 狂飙
	
	Last Update: Apr 25, 2009
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('Bagnon', 'zhCN')
if not L then return end

--bindings
L.BagnonToggle = "开关 背包"
L.BanknonToggle = "开关 银行"

--system messages
L.NewUser = "这是该角色第一次使用 Bagnon，已载入默认设置。"
L.Updated = "已更新到 v%s"
L.UpdatedIncompatible = "从一个错误的版本更新，已载入默认设置。"

--errors
L.ErrorNoSavedBank = "无法打开银行：无可用的存储信息。"
L.vBagnonLoaded = format("vBagnon 和 Bagnon 不能同时开启。点击 %s 禁用 vBagnon 并重载界面", TEXT(ACCEPT))

--slash commands
L.Commands = "命令:"
L.ShowBagsDesc = "开关背包界面"
L.ShowBankDesc = "开关银行界面"
L.ShowVersionDesc = '显示当前版本'

--frame text
L.TitleBank = "%s的银行"
L.TitleBags = "%s的背包"
L.ShowBags = "显示包裹"
L.HideBags = "隐藏包裹"

--tooltips
L.TipShowMenu = "<右键点击>打开设置菜单"
L.TipShowSearch = "<双击>进行搜索"
L.TipShowBag = "<单击>显示"
L.TipHideBag = "<单击>隐藏"
L.TipGoldOnRealm = "%s上的总资产"

L.ConfirmReloadUI = '这个设置将在你下次登录时生效'
