1.2e
  * Fixed a petbar error

1.2d
  * Updated keybound

1.2c
  * Corrected zip file structure

1.2b
  * Removed an erroneous debug print

1.2
  * Switched to using LibKeyBound instead of KeyBound
  * Added jailborc's XP bar modifications
  * Fixed errors with the class bar under the case of a class with no classbar skills.

1.1
  * Fixed a bug causing my upgrade code not to run. If you're upgrading from 1.0 to 1.1, please make sure you've set a bar as the possess bar
  * Fixed typo

1.0
  * The possess bar will now default to the pet bar if no action bar has been set to act as it
  * You can now only have one possess bar at a time
  * Bongos now fires two Ace3 messages: BONGOS\_LOCK\_ENABLE and BONGOS\_LOCK\_DISABLE

Gamma.1
  * Fixed some grammar issues

Beta.12
  * Fixed a bug causing disabling sticky bars causing bars to move out of place
  * Fixed a bug causing bindings to clear on a new version update
  * Fixed a bug causing bindings to not disable properly when removing a button or loading a profile
  * Fixed a bug causing the stats display to not show correct information after a profile load
  * Added an option to show tooltips only in combat
  * Slightly tweaked the interface options menu

Beta.11
  * Added an option to make the pet bar act as the possess bar
  * Made the binding and config mode dialogs movable
  * Fixed a bug for new users

Beta 10:
  * Added a Page slider to each stance menu, tried to make the bar creation help more informative/noticeable.

Beta 9:
  * Replaced the term Action Set with paging, and altered all of the stance sliders to say Page X instead of simply X
  * Differentiated Page 1 from the default state of do nothing, called Disabled.
  * Changed the format used for creating the right click menu for action bars to be table driven. Take a look at Bongos\_AB/actionBarConfig.lua if you wanna edit it.