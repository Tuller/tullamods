--[[
	Bongos CastBar Localization file
--]]

local locale = GetLocale()

if locale == 'frFR' then
	MANGOS_SHOW_TIME = 'Montrer le temps'
elseif locale == 'zhCN' then
	MANGOS_SHOW_TIME = '显示时间'
elseif locale == 'esES' then
	MANGOS_SHOW_TIME = 'Mostrar tiempo'
else
	MANGOS_SHOW_TIME = 'Show Time'
end