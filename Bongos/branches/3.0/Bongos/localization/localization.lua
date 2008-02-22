--[[
	Localization.lua
		Translations for Bongos

	English: Default language
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('Bongos3', 'enUS', true)

--system messages
L.NewPlayer = 'Created new profile for %s'
L.Updated = 'Updated to v%s'
L.UpdatedIncompatible = 'Updating from an incompatible version. Default settings loaded'

--profiles
L.ProfileCreated = 'Created new profile "%s"'
L.ProfileLoaded = 'Set profile to "%s"'
L.ProfileDeleted = 'Deleted profile "%s"'
L.ProfileCopied = 'Copied settings from "%s"'
L.ProfileReset = 'Reset profile "%s"'
L.CantDeleteCurrentProfile = 'Cannot delete the current profile'
L.InvalidProfile = 'Invalid Profile "%s"'

--slash command help
L.ShowOptionsDesc = 'Shows the options menu'
L.LockBarsDesc = 'Toggles locking bar positions'
L.StickyBarsDesc = 'Toggles auto anchoring bars'

L.SetScaleDesc = 'Sets the scale of <barList>'
L.SetAlphaDesc = 'Sets the opacity of <barList>'
L.SetFadeDesc = 'Sets the faded opacity of <barList>'

L.ShowBarsDesc = 'Shows the given <barList>'
L.HideBarsDesc = 'Hides the given <barList>'
L.ToggleBarsDesc = 'Toggles the given <barList>'

--slash commands for profiles
L.SetDesc = 'Switches settings to <profile>'
L.SaveDesc = 'Saves current settings and switches to <profile>'
L.CopyDesc = 'Copies settings from <profile>'
L.DeleteDesc = 'Deletes <profile>'
L.ResetDesc = 'Returns to default settings'
L.ListDesc = 'Lists all profiles'
L.AvailableProfiles = 'Available Profiles'
L.PrintVersionDesc = 'Prints the current Bongos version'

--dragFrame tooltips
L.ShowConfig = '<Right Click> to configure'
L.HideBar = '<Middle Click or Shift Right Click> to hide'
L.ShowBar = '<Middle Click or Shift Right Click> to show'
L.DeleteBar = '<Ctrl Right Click> to delete'
L.SetAlpha = '<Mousewheel> to set opacity (|cffffffff%d|r)'

--Menu Stuff
L.Scale = 'Scale'
L.Opacity = 'Opacity'
L.FadedOpacity = 'AutoFade Opacity'
L.Visibility = 'Visibility'
L.Spacing = 'Spacing'
L.Layout = 'Layout'

--minimap button stuff
L.ShowMenuTip = '<Right Click> to show the options menu'
L.HideMenuTip = '<Right Click> to hide the options menu'
L.LockBarsTip = '<Left Click> to lock bar positions'
L.UnlockBarsTip = '<Left Click> to unlock bar positions'
L.LockButtonsTip = '<Shift Left Click> to lock button positions'
L.UnlockButtonsTip = '<Shift Left Click> to unlock button positions'