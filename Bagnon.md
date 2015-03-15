

## General ##
Bagnon is an addon that merges all of your bags into three frames: One for your inventory, one for your bank, and one for your keyring. Beyond the basic all-in-one inventory functionality, Bagnon also provides the following features:
  * Items can be colored based on quality
  * Quest items can be highlighted
  * Text searching
  * Offline viewing of inventory information from your other characters (via Bagnon\_Forever or Bagnon\_Armory)
  * [DataBroker](http://wiki.github.com/tekkub/libdatabroker-1-1) plugin support. Both the inventory and bank frames allow you to display a databroker plugin in the bottom left corner.



### Included Addons ###
  * Bagnon - Provides single window displays for your inventory, bank, and keyring
  * Bagnon\_Config - Provides a means of configuring said frames :P
  * Bagnon\_Forever - Enables the ability to view your character's bank, or items from any other character on the same server, from anywhere. (You need to log onto each character at least once for this to work).
  * Bagnon\_Tooltips - When hovering over an item, this tells you who has an item, and where.

---


## Frequently Asked Questions ##

### How do I display tokens? ###

Short answer: Install [Currency Tracker](http://www.wowinterface.com/downloads/info13001-CurrencyTracker.html)

Long answer, taken from a currency tracker comment:

> In Bagnon's options menu, you have to have the option "Enable databroker frame" ticked.    If that is enabled, you should see a frame looking sorta like this "< >" when you open Bagnon, on the lower end of the bag frame, next to the money display. Those < > are arrows and you can click them to cycle through your Broker plugins, like CurrencyTracker. When you have no other plugins, CurrencyTracker should show right up, otherwise you'll have to click a few times until you see either your tracked currencies or just the text "CurrencyTracker". If the latter shows up, just click the text and mark your currencies you want to watch.

### Items are disappearing when I put them in my Bank/Bags! ###

Odds are, they are not :)  Make sure that you have not accidentally hidden a bag from within Bagnon's frames.

![http://tullamods.googlecode.com/svn/images/bagnon_show_bags.png](http://tullamods.googlecode.com/svn/images/bagnon_show_bags.png)

### I deleted a character, but his or her items are still showing up in Bagnon's listing.  How do I get rid of him/her? ###

Bagnon does not really know when you remove a character, so you need to delete that character's information manually.  To do so, Open up a Bagnon frame, and click the player selector button (the icon in the top left of the frame that looks like your character a bit).  From there, you can select and delete information about any character that you're not currently logged onto.

![http://tullamods.googlecode.com/svn/images/bagnon_remove_character.png](http://tullamods.googlecode.com/svn/images/bagnon_remove_character.png)

### Is there guild bank support? ###

Currently, no.  I'm potentially working on it.

### Can you track items in my mailbox? ###

Bagnon\_Forever does not track mailbox items, and I have no plans on implementing support.  If you want that kind of information, you should probably check out an addon that stores more information about your characters, like the [Armory](http://www.wowinterface.com/downloads/info7952-Armory.html), or [Altoholic](http://www.wowinterface.com/downloads/info8533-Altoholic.html).

### Can you add in sorting? ###

I don't plan on implementing sorting in Bagnon, however, Bagnon works perfectly fine with things like [BankStack](http://www.wowinterface.com/downloads/info7761-BankStack.html).