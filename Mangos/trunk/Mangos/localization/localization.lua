--[[
	Localization.lua
		Translations for Bongos

	English: Default language
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('Mangos', 'enUS', true)

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
L.SetFadeDesc = 'Sets the faded opacity of <frameList>'

L.SetColsDesc = 'Sets the number of columns for <frameList>'
L.SetPadDesc = 'Sets the padding level for <frameList>'
L.SetSpaceDesc = 'Sets the spacing level for <frameList>'

L.ShowGridDesc = 'Toggles showing empty buttons on actionbars'

L.ShowFramesDesc = 'Shows the given <frameList>'
L.HideFramesDesc = 'Hides the given <frameList>'
L.ToggleFramesDesc = 'Toggles the given <frameList>'

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
L.ShowConfig = '<Right Click> to configure'
L.HideBar = '<Middle Click or Shift-Right Click> to hide'
L.ShowBar = '<Middle Click or Shift-Right Click> to show'
L.DeleteBar = '<Alt-Right Click> to delete'
L.SetAlpha = '<Mousewheel> to set opacity (|cffffffff%d|r)'

--Menu Stuff
L.Scale = 'Scale'
L.Opacity = 'Opacity'
L.FadedOpacity = 'Faded Opacity'
L.Visibility = 'Visibility'
L.Spacing = 'Spacing'
L.Layout = 'Layout'
L.Columns = 'Columns'
L.Size = 'Size'
L.Modifiers = 'Modifiers'
L.QuickPaging = 'Quick Paging'
L.Help = 'Help'
L.Harm = 'Harm'
L.Targeting = 'Targeting'
L.ShowStates = 'Show States'
L.Set = 'Set'
L.Bar = 'Bar %d'