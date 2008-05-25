--[[
	Bongos' Localization File
		Chinese Simplified by Jokey http://www.biggamer.com
	UTF-8!
--]]

local L = LibStub("AceLocale-3.0"):NewLocale("Bongos3", "zhCN")
if not L then return end

--system messages
L.NewPlayer = "建立新配置 %s"
L.Updated = "升级到 v%s"

--profiles
L.ProfileCreated = "建立新配置 \"%s\""
L.ProfileLoaded = "配置设置为 \"%s\""
L.ProfileDeleted = "删除配置 \"%s\""
L.ProfileCopied = "从 \"%s\" 复制配置到 \"%s\""
L.ProfileReset = "重置配置 \"%s\""
L.CantDeleteCurrentProfile = "不能删除当前配置"
L.InvalidProfile = '无效的配置文件 "%s"'

--slash command help
L.ShowOptionsDesc = "显示设置菜单"
L.LockBarsDesc = "动作条位置锁定开关"
L.StickyBarsDesc = "动作条自动定位开关"

L.SetScaleDesc = "设置缩放 <barList>"
L.SetAlphaDesc = "设置透明度 <barList>"
L.SetFadeDesc = '设置淡出透明度 <barList>'

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
L.DeleteBar = '<Alt+右键> 删除'
L.SetAlpha = "<滚轮> 设置透明度 (|cffffffff%d|r)"

--Menu Stuff
L.Scale = "缩放"
L.Opacity = "透明度"
L.FadedOpacity = "渐隐透明度"
L.Visibility = "可见性"
L.Spacing = "间距"
L.Layout = "布局"

--minimap button stuff
L.ConfigEnterTip = '<左键> 进入设置菜单'
L.ConfigExitTip = '<左键> 退出设置菜单'
L.BindingEnterTip = '<Shift+左键> 进入按键绑定菜单'
L.BindingExitTip = '<Shift+左键> 退出按键绑定菜单'
L.ShowOptionsTip = '<右键> 显示设置菜单'

--Options Menu
L.EnableStickyBars = '动作条吸附'
L.ShowMinimapButton = '显示迷你地图按钮'
L.General = '综合'
L.Profiles = '配置文件'
L.Visibility = '可见'
L.Copy = '拷贝'
L.Set = '设置'
L.Save = '保存'
L.Delete = '删除'
L.EnterName = '输入配置文件名'