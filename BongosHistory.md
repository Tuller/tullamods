1.10.1
  * Action Bar: Fixed a tooltip bug with Cowtip installed.
  * XP: Added Lifernal @ Steamwheedle Cartel's changes
  * XP: You can now switch between watching reputation and experience simply by clicking on the bar
  * XP: The experience bar now shows a percentage

1.10.0 (Beta)
  * Core: Frame positions are now saved relative to the nearest corner of the screen.
  * Core: Dragging a bar near the edge of the screen will automatically dock the bar to that edge
  * Core: Dragging a bar near the center of any edge will automatically dock and center that bar on that edge
  * Action Bar: Fixed an error when showing the right click menu for action bars in any non English locale

1.9.6
  * All: Updated Spanish translation (thanks Ferroginu)
  * Core: Recoded the minimap button
  * Action Bar: Fixed an updating issue with buff and debuff highlighting code
  * XP: Changed the texture
  * XP: Added an option to always show experience

1.9.5
  * All: Fixed issues with the French translation
  * Action Bar: Fixed the error when learning a new skill (for real this time)
  * Action Bar: Fixed some bugs with the buff and debuff highlighting code
  * Action Bar: Removed a source of taint from the unregistration code
  * Cast Bar: Fixed an issue causing the bar color to be red, even when not interrupted

1.9.4
  * Action Bar: Fixed the error when training a new skill
  * Action Bar: Made buff and debuff highlighting work on a few more things

1.9.3
  * Action Bar: Optimized buff and debuff highlighting
  * Action Bar: Fixed a tainting issue in the unregistration code

1.9.2
  * Action Bar: Fixed some showgrid bugs
  * Action Bar: Removed a debug message

1.9.1 (Beta)
  * Cast Bar: Fixed a bug causing coloring to not work
  * Action Bar: Fixed a bug causing highlighting to stick on empty buttons
  * Action Bar: Made debuff and buff highlighting optional

1.9.0 (Beta)
  * All: Updated for 2.3
  * All: Adjusted file structures  Delete all Bongos folders before installing
  * All: Added French translation (thanks SegFault)
  * Core: Profile copying now actually works
  * Cast Bar: Spell target coloring is now more accurate
  * Action Bar: The class bar will now update properly when you get a new form/aura/stance
  * Action Bar: Implemented FlexBar2 style buff and debuff highlighting
  * Action Bar: You can now bind macros directly using KeyBound
  * Action Bar: Reduced the CPU usage of showing and hiding empty buttons
  * XP: Added in the ability to configure the position of text (thanks SegFault)
  * Bags: Added in an option to hide the keyring
  * Bags: Modified the look of the keyring
  * Minimap: Added an offset setting for the clock

1.8.2
  * XP: Fixed a bug causing the bar to become too large after sizing it with the slider

1.8.1
  * Action Bar: Merged the key and bag bars
  * Action Bar: Fixed a bug causing the spacing slider for the pet bar display the correct value
  * Action Bar: Fixed an error when attempting to bind keys to the spell book
  * Action Bar: Altered the layout of stance sliders
  * Map Bar: Fixed a bug causing the interface panels to not be able to properly expand across the screen

1.8.0
  * All: Updated for 2.2.  This version is **not** compatible with 2.1
  * Action Bar: Implemented some event optimizations allowed by 2.2
  * Action Bar: Locking action buttons, and the key to hold down to move them now use the blizzard setting.
  * XP: Cleaned up the code a bit.
  * XP: Implemented tanerh's changes.  Text can now be configured to always show, and the player's current reputation level is displayed

1.7.5
  * All: Implemented chinese localization (thanks ondh (http://www.ondh.cn))
  * Core: Fixed an error when saving a profile
  * Core: Fixed a bug casuing profiles to be matched inaccurately
  * Core: Hopefully fixed a bug when upgrading Bongos

1.7.4
  * Cast Bar: Modified coloring. Implemented a better algorithm for target detection

1.7.3
  * Core: Implemented a theoretical fix for bad profile initialization
  * Options: Reimplemented the visibility panel
  * Action Bar: Implemented a fix for the range coloring issue

1.7.2
  * Core: Fixed a bug causing the fade slider to display incorrect values when a bar has a normal opacity of less than 100%
  * Core: Fixed a bug causing mouseover detection to be enabled when it shouldn't be
  * Stats: Fixed a bug causing setting options to not work
  * Stats: Implemented sorted displays for memory and CPU usage
  * XP: Fixed a error when setting the vertical option
  * Action Bar: Made the pet bar more easily bindable

1.7.1
  * Core: Reimplemented the minimap button
  * Core: Fixed a layering issue causing things to not be clickable
  * Action Bar: Fixed a bug causing action button slots to not properly update when switching actions
  * Map Bar: Reimplemented titan compatibility code


1.7.0
  * Core: Added in intuitive frame scaling (credit goes to AduinLothar)
  * Core: Added in mouseover fading
  * Core: Added in checkboxes to the right click menu for frame hiding/showing
  * Core: Removed the minimap button
  * Action Bar: Fixed a bug causing the spacing sliders to not display proper values
  * Action Bar: Altered range scaling to update even more frequently
  * Cast Bar: Resizing code should work properly :)
  * Cast Bar: Implemented basic target coloring

1.6.3
  * Core: Added shift right click to hide/show to the drag frame tooltips
  * Action Bar: Fixed a bug causing keys to not be able to be bound
  * Options: Disabled the key binding and actionbar panels if Bongos2\_ActionBar is not there

1.6.2
  * Core: Recoded all menus
  * Core: Tool tips are now hidden on drag frames when the mouse button is held down
  * Action Bar: Optimized idle CPU performance
  * Action Bar: Optimized ACTIONBAR\_SLOT\_CHANGED performance
  * Action Bar: Stance Sliders now list their values in bars
  * Action Bar: Increased the frequency of range checking updates
  * Minimap: Adjusted defaults
  * Minimap: Added a clock option
  * Stats: Removed memory and cpu usage for now

1.5
  * Fixed a bug causing Dongle addons to trigger Bongos profile messages
  * Fixed a bug causing the frame levels of frames to not persist after loading a profile
  * Recoded the pet bar to use blizzard functions, instead of my own

1.4c
  * Replaced the stance macro fix with a better one

1.4b
  * Fixed a bug causing left click to target the player in shadowform if right click selfcast was enabled
  * Probably fixed a bug causing the pet bar to not properly show up when summoning a pet with no target in combat

1.4
  * Fixed a bug causing the pet bar to not show up properly when in combat
  * Fixed a bug causing the pet bar to not show empty buttons in keybinding mode
  * Fixed a bug causing right click selfcast to renable itself after a /reloadui
  * Fixed a bug causing settings to not properly copy when saving a new profile

1.3
  * Fixed a bug causing the minimap button to not hide (seriously)
  * Fixed a bug causing right click selfcast to not work (seriously)
  * Fixed a bug causing duplicate frames to be created after loading a profile
  * Fixed a bug causing frames to not attach to their anchors after loading a profile
  * Modified the pet bar code to have empty button hiding work more consistently
  * Modified the menu bar code to remove a possible source of tainting
  * Modified the main actionbar hiding code to remove a possible source of tainting
  * Modified the right click menus to be able to be moved
  * Altered the state headers for action bars to be dynamically generated
  * Altered stance names for action bars to be dynamically generated
  * Added in settings for modifier (ctrl, alt, shift) paging
  * Reimplemented the Bongos experience bar
  * Reimplemented the Bongos map bar
  * Bindings are now converted from the default actionbars/Bongos1

1.2
  * Fixed a bug causing the minimap button to not hide
  * Fixed a bug causing right click selfcast to not work
  * Fixed a bug causing the user to be in the wrong state when logging in and already paged
  * Fixed a bug causing an error when attempting toggle range coloring
  * Fixed a bug causing hotkeys on the class bar and action bars to not properly be set when loading a profile
  * Fixed a bug causing macro text on the action bars to not be properly set when loading a profile
  * Fixed a bug causing the minimap button to go crazy when adjusting its location
  * Added options to save and copy profiles

1.1
  * Fixed a bug causing it not to be possible to bind mouse buttons 4 and 5
  * Fixed a bug causing macro text to not remain hidden on login if the option is set
  * Fixed a bug causing alt + binding to target mouseover :)
  * Fixed a bug causing the bars for paladins to not work properly when first loaded

1.0
  * Updated for 2.1