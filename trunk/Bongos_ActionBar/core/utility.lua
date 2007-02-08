--[[
	Utility Functions for Bongos_ActionBar
--]]

BActionUtil = {}

function BActionUtil.ShowGrid(enable)
	bg_showGrid = enable
	
	if enable then
		BActionButton.ForAll(BActionButton.ShowGrid)
	else
		BActionButton.ForAll(BActionButton.HideGrid)
	end
end

function BActionUtil.ShowPetGrid(enable)
	bg_showPetGrid = enable

	if PetHasActionBar() then
		if enable then
			BPetButton.ForAll(BPetButton.ShowGrid)
		else
			BPetButton.ForAll(BPetButton.HideGrid)
		end
	end
end

function BActionUtil.ToShortKey(key)
	if key then
		key = key:upper()
		key = key:gsub(' ', '')
		key = key:gsub('ALT%-', 'A')
		key = key:gsub('CTRL%-', 'C')
		key = key:gsub('SHIFT%-', 'S')

		key = key:gsub('NUMPAD', 'N')

		key = key:gsub('BACKSPACE', 'BS')
		key = key:gsub('PLUS', '%+')
		key = key:gsub('MINUS', '%-')
		key = key:gsub('MULTIPLY', '%*')
		key = key:gsub('DIVIDE', '%/')
		key = key:gsub('HOME', 'HN')
		key = key:gsub('INSERT', 'Ins')
		key = key:gsub('DELETE', 'Del')
		key = key:gsub('BUTTON3', 'M3')
		key = key:gsub('BUTTON4', 'M4')
		key = key:gsub('BUTTON5', 'M5')
		key = key:gsub('MOUSEWHEELDOWN', 'WD')
		key = key:gsub('MOUSEWHEELUP', 'WU')
		key = key:gsub('PAGEDOWN', 'PD')
		key = key:gsub('PAGEUP', 'PU')

		return key
	end
end