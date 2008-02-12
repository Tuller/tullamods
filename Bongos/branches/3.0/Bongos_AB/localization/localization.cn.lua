--[[
	Bongos_Actionbar Localization
		Chinese Simplified by ondh
		http://www.ondh.cn
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('Bongos3-AB', 'zhCN')
if not L then return end

L.Columns = '列'
L.Size = 'Size'
L.Vertical = '纵向'
L.OneBag = '单个包'
L.BagBar = '背包栏'
L.ActionBar = '动作条 %s'
L.Paging = '翻页'
L.Stances = '姿态'
L.Page = '页 %s'
L.FriendlyStance = '友好目标'
L.Modifier = '调整键'
L.Prowl = '潜行'
L.ShadowForm = '暗影形态'

L.ClassBar = '职业姿态栏'
L.MenuBar = '系统栏动作条'
L.PetBar = '宠物动作条'

--keybindings
BINDING_HEADER_BGPAGE = 'Bongos 翻页'
BINDING_HEADER_BQUICKPAGE = '快速翻页'
BINDING_HEADER_BBARS = 'Bongos 动作条可见性'

BINDING_NAME_BMENUBAR_TOGGLE = '显示系统栏'
BINDING_NAME_BBAGBAR_TOGGLE = '显示背包栏'