Ludwig is an item link database addon that was originally based on [GetLink](http://www.wowinterface.com/downloads/fileinfo.php?id=4360).  Ludwig is not dependent on saved variables, and Ludwig does not require the user to do anything special in order to collect data.

### Features ###
  * Search Window: You can filter via name, quality, level, type, subtype, and equip location.
  * Linkerator support: Typing an item name in `[[brackets]` will automatically convert the name into an item link if the item is known to Ludwig.
  * Command line searching: typing `/lw <name>` will bring up a list of the top 10 matches in the chat window.

### Slash Commands ###
  * `/lw or /ludwig` - Brings up the search frame
  * `/lw <name>` - Prints out a list in the chat window of the top 10 items matching `<name>`
  * `/lw --r` - Refreshes the database
  * `/lw --q <itemID>` - Queries the server for the given itemID

[Ludwig's source code is hosted on GitHub](http://github.com/Tuller/Ludwig)