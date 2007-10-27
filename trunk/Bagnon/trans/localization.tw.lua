--[[
	Bagnon Localization Information: English Language
		This file must be present to have partial translations
--]]

if GetLocale() ~= "zhTW" then return end

local L = BAGNON_LOCALS

--bindings
BINDING_HEADER_BAGNON = "Bagnon"
BINDING_NAME_BAGNON_TOGGLE = "切換背包整合開關"
BINDING_NAME_BANKNON_TOGGLE = "切換銀行整合開關"

--system messages
L.NewUser = "偵測到新的使用者，預設值已載入"
L.Updated = "已更新到v%s"
L.UpdatedIncompatible = "由不相容版本升級，預設值已載入"

--errors
L.ErrorNoSavedBank = "無法開啟銀行，沒有儲存資訊"
L.vBagnonLoaded = format("vBagnon 和 Bagnon 不相容。點擊 %s 將 vBagnon 停用並重載你的 UI", TEXT(ACCEPT))

--slash commands
L.Commands = "指令:"
L.ShowMenuDesc = "顯示設定選單"
L.ShowBagsDesc = "顯示背包"
L.ShowBankDesc = "顯示銀行"

--frame text
L.TitleBank = "%s的銀行"
L.TitleBags = "%s的背包"
L.ShowBags = "顯示背包"
L.HideBags = "隱藏背包"

--tooltips
L.TipShowMenu = "<右鍵>設定"
L.TipShowSearch = "<雙擊>搜尋"
L.TipShowBag = "<點擊>顯示"
L.TipHideBag = "<點擊>隱藏"
L.TipGoldOnRealm = "總計%s"

--menu text
L.FrameSettings = "視窗設定"
L.Lock = "鎖定位置"
L.Toplevel = "最上層顯示"
L.BackgroundColor = "背景"
L.FrameLevel = "視窗層級"
L.Opacity = "透明度"
L.Scale = "縮放"
L.Spacing = "間隔"
L.Cols = "欄數"
L.ReverseSort = "反向"

--item count tooltips
L.NumInBags = " %d 在背包"
L.NumInBank = " %d 在銀行"
L.NumEquipped = " 裝備中"
