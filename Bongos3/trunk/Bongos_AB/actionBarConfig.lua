--[[
	stanceConfig.lua
		Stance configuration settings for Bongos
--]]

local Config = Bongos3:GetModule('ActionBar-Config', true)	--get the actionbar configuration panel
if not Config then return end 								--no actionbar config? no bongos_actionbar, so quit
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3-AB') 	--get localized string information.  When you see L.Var in my code, it represents a localized string

--[[
	this table determines what macro conditions bongos recognizes, and also at what priority they're in
	in this case, modifiers are checked before action pages, which are checked before forms, which are checked before targeting

	The stuff inside brackets are macro condtions.  You can read more about these at:
		http://www.wowwiki.com/HOWTO:_Make_a_Macro#Part_II:_Macro_Options
--]]

function Config:LoadStateHeader()
	return {
		'[mod:ctrl]', --modifier down
		'[mod:alt]',
		'[mod:shift]',
		'[bar:2]', --action page 2-6 (shift + number)
		'[bar:3]',
		'[bar:4]',
		'[bar:5]',
		'[bar:6]',
		'[bonusbar:1,stealth]', --prowl
		'[bonusbar:1]', --stances, forms, stealth, etc
		'[bonusbar:2]',
		'[bonusbar:3]',
		'[bonusbar:4]',
		'[help]',
		'[harm]'
	}
end


--[[
	This table determines what stance sliders you see on the right click menu.  The format is:
		layout = {
			{"panelName", conditionTable}
		}
	
	with condition table having the format of
		conditionTable = {
			{"condition1", "macroOption1"},
			{"condition2", "macroOption2"},
		}
		
		such as
		conditionTable = {
			{"Alt and Control Down", "[mod:alt,mod:ctrl]"},
			{"Stealth", "[stealth]"},
		}

	If you list a macro option here, but not in the GetStateHeader table, then whatever setting you have for a bar on that condition will be ignored
--]]

function Config:LoadStanceLayout()
	local layout = {}
	
	--[[
		class specific panels, adds sliders for druid forms, priest shadowform, warrior stances, and rogue stealth

		GetSpellinfo is used to get localized names for spells based on spellIDs
			You can get spellIDs by looking at the number at the end of a wowhead link for a spell
			For example, prowl's wowhead spell url is: http://www.wowhead.com/?spell=5215, so its spellID is 5215
	--]]
	local class, enClass = UnitClass('player') --the first return is the localized class name, the second return is the name of the class in uppercased english
	if enClass == 'DRUID' then
		local classConditions = {
			{GetSpellInfo(5487), '[bonusbar:3]'}, 		--bear
			{GetSpellInfo(768), '[bonusbar:1]'}, 		--cat
			{GetSpellInfo(5215), '[bonusbar:1,stealth]'},	--prowl
			{GetSpellInfo(24858), '[bonusbar:4]'},		--moonkin
			{GetSpellInfo(33891), '[bonusbar:2]'}, 		--tree
		}
		table.insert(layout, {class, classConditions})
	elseif enClass == 'PRIEST' then
		table.insert(layout, {class, {{GetSpellInfo(15473), '[bonusbar:1]'}}}) --shadowform
	elseif enClass == 'WARRIOR' then
		local classConditions = {
			{GetSpellInfo(2457), '[bonusbar:1]'},	--battle
			{GetSpellInfo(71), '[bonusbar:2]'},	--defensive
			{GetSpellInfo(2458), '[bonusbar:3]'}	--berserker
		}
		table.insert(layout, {class, classConditions})
	elseif enClass == 'ROGUE' then
		table.insert(layout, {class, {{GetSpellInfo(1784), '[bonusbar:1]'}}}) --stealth
	end
	
	--paging panel
	--adds sliders for shift + number paging
	--i'm using some shortcuts here, but its the same stuff as for the other stuff
	local pageConditions = {}
	for i = 2, 6 do
		table.insert(pageConditions, {getglobal('BINDING_NAME_ACTIONPAGE' .. i), format('[bar:%d]', i)})
	end
	table.insert(layout, {L.Paging, pageConditions})
	
	--modifier panel
	--for things like holding down alt, control, or shift
	local modifierConditions = {
		{CTRL_KEY, '[mod:ctrl]'},
		{ALT_KEY, '[mod:alt]'},
		{SHIFT_KEY, '[mod:shift]'},
	}
	table.insert(layout, {L.Modifier, modifierConditions})
	
	
	--targeting panel
	--for things like when targeting a friendly or enemy unit
	local targetConditions = {
		{L.FriendlyTarget, '[help]'},
		{L.EnemyTarget, '[harm]'},
	}
	table.insert(layout, {L.Targeting, targetConditions})
	return layout
end