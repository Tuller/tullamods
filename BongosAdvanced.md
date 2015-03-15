So, you've figured out what right click menus are, you can move and scale things like a champ, and you know how to get to the options window.  Here's some more info to help you get the most out of Bongos:



## Making The Most Out Of Your Bindings (Paging) ##

Paging is a feature that allows any one of your action bars to duplicate the buttons of another one of your action bars when in a given state (bear form, battle stance, stealth, etc), but keep the same hot keys.  You can see this in the normal interface whenever you switch stances or manually page (more on that later).  On a druid, for example, pressing 1 could cast Starfire when in caster form, but use Maul when in bear.  Its a really useful way to reduce the number of bindings you need to remember.

You can configure what bar to switch in when in a given state through that bar's right click menu (for information about how to get here, check out [Bongos2 For Dummies](http://code.google.com/p/tullamods/wiki/Bongos2)).  In the menu that will pop up, there will be options for stances, paging, and modifier.

The stances tab contains sliders for class specific states: Druid forms, Warrior Stances, Rogue Stealth, Shadow Form on Priests, etc.  Simply adjust the slider for a form

The paging tab is for manual paging, a feature available in the standard interface, but not known about by most players.  Manual paging allows you to assign bars to switch to when you press a certain hot key (shift+1 for page 1, shift+2 for page2, shift+3 for page3, etc up to 6, as well as shift + mouse wheel up or down).  You can switch back to the standard bar by pressing shift + 1.  Bindings for each page are configurable in the Blizzard bindings menu, under Action Page or Quick Page.

The modifier tab is for paging whenever you hold down a modifier key (shift, alt, or ctrl on Windows).  So, you can setup a bar1 to switch to bar 2 whenever you hold down alt.


**A Note About Paging:**

When you first install Bongos, your bindings will still reference the Blizzard action buttons.  While it may seem as if your bindings are working properly when in your normal state (caster form, battle stance, etc), once you switch states your bindings will not update.  To resolve this, bind your keys using KeyBound (for information about how to get here, check out [Bongos2 For Dummies](http://code.google.com/p/tullamods/wiki/Bongos2)).



## Configuring things Faster (Slash Commands) ##

The slash command handler in Bongos is there to do two things:  Configure things fast, and Configure things precisely.  Need the bags to be faded to exactly 30.5%?  `/bob setalpha bags 0.305`  Need to hide bars 7 to 120?  `/bob hide 7-120`  Also need to hide the bags?  `/bob hide 7-120 bags` will do it.

All bar specific slash commands take a barList.  A bar list is an individual bar id (ex, bags), all for all bars, a range (1-120 for bars 1-120), or any combination of those separated by a space (ex, menu bags 1-10 for the menu and bag bars, as well as actionbars 1-10).  If you understand that syntax, you can configure things **very** quickly.

Now, for the commands:
| **Command Syntax** | **Description** |
|:-------------------|:----------------|
| /bongos | Shows the options menu, if present, else displays slash commands |
| /bongos lock | Toggles locking bars positions |
| /bongos show 

&lt;barList&gt;

 | Shows 

&lt;barList&gt;

 |
| /bongos hide 

&lt;barList&gt;

 | Hides 

&lt;barList&gt;

 |
| /bongos toggle 

&lt;barList&gt;

 | Toggles 

&lt;barList&gt;

 |
| /bongos scale 

&lt;barList&gt;

 

&lt;scale&gt;

 | Sets the scale of 

&lt;barList&gt;

 to 

&lt;scale&gt;

.  1 is normal  size, 2 is double, etc |
| /bongos setalpha 

&lt;barList&gt;

 

&lt;opacity&gt;

 | Sets the opacity of 

&lt;barList&gt;

 to 

&lt;opacity&gt;

. 0 is completely invisible, 1 is completely opaque |
| /bongos set 

&lt;profile&gt;

 | Sets the current character to use 

&lt;profile&gt;

 |
| /bongos save 

&lt;profile&gt;

 | Saves current settings as and switches to 

&lt;profile&gt;

 |
| /bongos copy 

&lt;profile&gt;

 | Copies all settings from 

&lt;profile&gt;

 |
| /bongos delete 

&lt;profile&gt;

 | Deletes 

&lt;profile&gt;

 |
| /bongos reset | Loads default settings |
| /bongos version | Prints version information |
| /keybound or /kb | Toggles keybinding mode |