--[[
	THIS FILE IS ENCODED IN UTF-8

	Bagnon Localization file: Chinese 
		Credit goes to Diablohu
--]]


if GetLocale() ~= "zhCN" then return end

local L = BAGNON_LOCALS

--bindings
BINDING_HEADER_BAGNON = "Bagnon"
BINDING_NAME_BAGNON_TOGGLE = "开关Bagnon"
BINDING_NAME_BANKNON_TOGGLE = "开关Banknon"

--system messages
L.NewUser = "New user detected, default settings loaded"
L.Updated = "Updated to v%s"
L.UpdatedIncompatible = "Updating from an incompatible version, defaults loaded"

--errors
L.ErrorNoSavedBank = "Cannot open the bank, no saved information available"

--slash commands
L.Commands = "Commands:"
L.ShowMenuDesc = "Shows the options menu"
L.ShowBagsDesc = "Toggles the inventory frame"
L.ShowBankDesc = "Toggles the bank frame"

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
L.TipGoldOnRealm = "Total on %s"

--menu text
L.FrameSettings = "Frame Settings"
L.Lock = "锁定位置"
L.Toplevel = "Toplevel"
L.BackgroundColor = "背景颜色"
L.FrameLevel = "层"
L.Opacity = "透明度"
L.Scale = "缩放"
L.Spacing = "间距"
L.Cols = "列数"