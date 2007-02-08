Sage is a minimalistic, lightweight unit frame replacement. If you're looking for a set of frames with giant portraits, or 3D models of everything, then Sage is not for you.

General Features

    * Low Memory Usage - Sage frames should not be a heavy hit on resources.
    * Modular Design - You can pick and choose what frames you want.
    * Adjustable bar textures - Sage features 15 different bar textures to choose from, with the ability to add more.
    * Highly Visible Debuffs - For friendly unit, debuffs are displayed to the side and are very large. By default, a friendly unit's health will change color if debuffed.
    * Multiple styles for displaying health or mana text.
    * Optional health percentage display for all frames.
    * Buff filtering - You can choose to show only buffs you are able to cast, or only debuffs you are able to cure, on a per unit basis.
    * Support for Telos' MobHealth, MobInfo2, and MobHealth3 

Components

    * Sage - A single dependency for all Sage frames, it provides all the building blocks for creating a
    * Sage_Player
    * Sage_Pet
    * Sage_Target -
    * Sage_TargetOfTarget - Displays whatever your current target is targeting.
    * Sage_Focus
    * Sage_Party
    * Sage_Options - A load on demand options menu, triggered by /sage
    * Sage_Comm - Standalone, sends combat information about party members 

Using Sage

Configuration

    * To bring up the options menu. Type /sage.
    * You can disable a specific frame by logging out, selecting the addons menu, and unchecking whichever frame you do not want to load. 

The Player Frame

    * The player frame displays your name, level, health, mana, pvp status, master loot status, group leader status, raid target icon, and optionally your experience or reputation.
    * In a raid, your level display changes to show what raid group you are in.
    * Your name's color changes based on your combat and resting status. Blue means you are resting, red means you are in combat.
    * To toggle between watching reputation or experience, open the character menu (c by default) go to your reputation tab. To watch reputation, click on a faction and check the option to watch reputation. Uncheck it to go back to watching your experience. 

The Target Frame

    * The target frame displays your target's name, level, health, mana, and raid target icon.
    * If you're targeting a unit controlled by a player, the target frame will display that unit's class, else the frame will display that unit's classification (humanoid, beast, etc), and elite status.
    * The color of the name of your target is based on a large amount of conditions, and is similar to the colors of the blizzard target frame.
    * Combo points are displayed to the left of the frame. By default, combo points are displayed in a style similar to Tony Hawk games: Spelling out combo means you have a max amount of combo points.
    * For friendly units, buffs are displayed at the bottom of the frame, with debuffs on the side. For enemy units, the arrangement is reversed. 

The Target of Target Frame

    * The target of target frame displays the same amount of information as your target frame, minus buffs, debuffs, and mana, though if you have healthbar debuff coloring on, you'll still be able to see if your target of target is debuffed.
    * You can turn the target of target frame off by logging out, selecting the addons menu, and unchecking Sage_TargetOfTarget 

The Focus Frame

    * The focus unit was added by Blizzard in 2.0.1. Its basically a secondary target you manually set and unset. It should be useful for mages who want to watch a unit to sheep, or a main tank.
    * Sage's Focus frame displays the same amount of information as the Target frame.
    * To set a unit as your focus, type /focus, and to clear it, type /clearfocus.
    * You can setup keybindings for setting and clearing your focus in the keybindings menu. 

The Pet Frame

    * The pet frame displays about the same amount of information as the player frame, except for experience.
    * Buffs are displayed at the bottom of the frame, debuffs to the right.
    * For hunters, a happiness indicator is displayed to the right of the frame. It functions exactly like the blizzard provided one.
    * Your pet's combat status is displayed by the color of your pet's name. Red means its in combat, white that its not. 

The Party Frames

    * Party frames show the standard amount of information as the other frames.
    * Buffs are displayed below the frame, debuffs to the right.
    * The color of the name of a member of your party signifies what class it is. The colors are the same as the ones used by the raid frames.
    * If both you and a party member have Sage_Comm installed, then that party member's name color will turn red if that unit is in combat.
    * If one of your party members has a pet, a click able health bar for that pet will show up under the member's mana bar.
    * You can set whether to show the party frame in a raid or not via the options menu. 

Slash Commands

    * /sg or /sage - Displays the options menu, if available.
    * /sg help - Displays list of commands
    * /sg lock - Locks the position all frames
    * /sg unlock - Unlocks the positions all frames
    * /sg scale <unit> <scale> - Sets the scale of the given frame. 100 is normal size.
    * /sg setalpha <unit> <opacity> - Sets the opacity of the given frame. 0 is translucent, 1 is opaque.
    * /sg setwidth <unit> <width> - Sets the width, in pixels, of the name portion of the given unit's frame. 100 is the default for the target frame.
    * /sg stickyframes <on | off> - Enable/disable frames sticking when placed near each other.
    * /sg text <on | off> - Enable/disable always showing text.
    * /sg percents <on | off> - Enable/disable showing health percentages. 