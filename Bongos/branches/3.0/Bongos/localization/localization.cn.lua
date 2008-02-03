--[[
	Bongos' Localization File
		Chinese Simplified by ondh
		http://www.ondh.cn
		
	UTF-8!
--]]

local L = LibStub("AceLocale-3.0"):NewLocale("Bongos3", "zhCN")

--system messages
L.NewPlayer = "建立新配置 %s"
L.Updated = "升级到 v%s"
L.UpdatedIncompatible = "无法从不兼容的版本升级. 加载默认配置"

--profiles
L.ProfileCreated = "建立新配置 \"%s\""
L.ProfileLoaded = "配置设置为 \"%s\""
L.ProfileDeleted = "删除配置 \"%s\""
L.ProfileCopied = "从 \"%s\" 复制配置到 \"%s\""
L.ProfileReset = "重置配置 \"%s\""
L.CantDeleteCurrentProfile = "不能删除当前配置"

--slash command help
L.ShowOptionsDesc = "显示设置菜单"
L.LockBarsDesc = "动作条位置锁定开关"
L.StickyBarsDesc = "动作条自动定位开关"

L.SetScaleDesc = "设置缩放 <barList>"
L.SetAlphaDesc = "设置透明度 <barList>"

L.ShowBarsDesc = "显示设置 <barList>"
L.HideBarsDesc = "隐藏设置 <barList>"
L.ToggleBarsDesc = "设置开关 <barList>"

--slash commands for profiles
L.SetDesc = "配置切换为 <profile>"
L.SaveDesc = "保存当前配置为 <profile>"
L.CopyDesc = "从 <profile> 复制配置"
L.DeleteDesc = "删除 <profile>"
L.ResetDesc = "返回默认配置"
L.ListDesc = "列出所有配置"
L.AvailableProfiles = "可用设置"
L.PrintVersionDesc = "显示当前 Bongos 版本"

--dragFrame tooltips
L.ShowConfig = "<右键> 设置"
L.HideBar = "<中键或者Shift+右键> 隐藏"
L.ShowBar = "<中键或者Shift+右键> 显示"
L.SetAlpha = "<滚轮> 设置透明度 (|cffffffff%d|r)"

--Menu Stuff
L.Scale = "缩放"
L.Opacity = "透明度"
L.FadedOpacity = "渐隐透明度"
L.Visibility = "可见性"
L.Spacing = "间距"
L.Layout = "布局"

--minimap button stuff
L.ShowMenuTip = "<右键> 显示设置菜单"
L.HideMenuTip = "<右键> 隐藏设置菜单"
L.LockBarsTip = "<左键> 锁定动作条位置"
L.UnlockBarsTip = "<左键> 解锁动作条位置"
L.LockButtonsTip = "<Shift+左键> 锁定动作条按钮"
L.UnlockButtonsTip = "<Shift+左键> 解锁动作条按钮"