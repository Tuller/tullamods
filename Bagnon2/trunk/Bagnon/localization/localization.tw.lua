--[[
    Bagnon Localization Information: Traditional Chinese Language
        20071117 by matini< yiting.jheng <at> gmail <dot> com
        20081201 by yleaf@cwdg(yaroot@gmail.com)
        20090423 by youngway@水晶之刺
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('Bagnon', 'zhTW')
if not L then return end

L.BagnonToggle  = "切換背包整合開關"
L.BanknonToggle  = "切換銀行整合開關"

--system messages
L.NewUser = "偵測到新的使用者，預設值已載入"
L.Updated = "已更新到v%s"
L.UpdatedIncompatible = "由不相容版本升級，預設值已載入"

--errors
L.ErrorNoSavedBank = "無法開啟銀行，沒有儲存資訊"
L.vBagnonLoaded = format("vBagnon 和 Bagnon 不相容。點擊 %s 將 vBagnon 停用並重載你的 UI", TEXT(ACCEPT))

--slash commands
L.Commands = "指令:"
L.ShowBagsDesc = "顯示背包"
L.ShowBankDesc = "顯示銀行"
L.ShowVersionDesc = '顯示目前版本'

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

L.ConfirmReloadUI = '這個設置將在下次登陸時生效'