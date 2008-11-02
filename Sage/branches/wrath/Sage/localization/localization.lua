--[[
	Localization.lua
		Translations for Sage

	English: Default language
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('Sage', 'enUS', true)

--system messages
L.NewPlayer = 'Created new profile for %s'
L.Updated = 'Updated to v%s'

--profiles
L.ProfileCreated = 'Created new profile "%s"'
L.ProfileLoaded = 'Set profile to "%s"'
L.ProfileDeleted = 'Deleted profile "%s"'
L.ProfileCopied = 'Copied settings from "%s"'
L.ProfileReset = 'Reset profile "%s"'
L.CantDeleteCurrentProfile = 'Cannot delete the current profile'
L.InvalidProfile = 'Invalid profile "%s"'

--slash command help
L.ShowOptionsDesc = 'Shows the options menu'
L.ConfigDesc = 'Toggles configuration mode'

L.SetScaleDesc = 'Sets the scale of <frameList>'
L.SetAlphaDesc = 'Sets the opacity of <frameList>'

--slash commands for profiles
L.SetDesc = 'Switches settings to <profile>'
L.SaveDesc = 'Saves current settings and switches to <profile>'
L.CopyDesc = 'Copies settings from <profile>'
L.DeleteDesc = 'Deletes <profile>'
L.ResetDesc = 'Returns to default settings'
L.ListDesc = 'Lists all profiles'
L.AvailableProfiles = 'Available Profiles'
L.PrintVersionDesc = 'Prints the current version'

--dragFrame tooltips
L.SetAlpha = '<Mousewheel> to set opacity (|cffffffff%d|r)'

--minimap button stuff
L.ConfigEnterTip = '<Left Click> to enter configuration mode'
L.ConfigExitTip = '<Left Click> to exit configuration mode'
L.ShowOptionsTip = '<Right Click> to show the options menu'

--helper dialog stuff
L.ConfigMode = 'Configuration Mode'
L.ConfigModeExit = 'Exit Config Mode'
L.ConfigModeHelp = '<Drag> any bar to move it.  <Right Click> to configure.'