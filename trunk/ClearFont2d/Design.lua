-- /////////////////////////////////////////////////////////////////////////////
-- =============================================================================
--  CLEARFONT2 BY KIRKBURN
--  Official website:  http://www.clearfont.co.uk/
-- -----------------------------------------------------------------------------
--  DESIGN.LUA - THE CLEARFONT DESIGN CODE
--	 A. SETTING UP THE ADDON
--	 B. WOW UI DESIGN
--	 C. DYNAMIC ADDON UPDATES
--	 D. AND FINALLY...
-- =============================================================================
-- /////////////////////////////////////////////////////////////////////////////


-- =============================================================================
--  A. SETTING UP THE ADDON
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Create function to check existence of certain fonts (useful for patch changes)
-- -----------------------------------------------------------------------------

local function CanSetFont(object)
	return (type(object)=="table"
		and object.SetFont and object.IsObjectType 
			and not object:IsObjectType("SimpleHTML")); 
end

	
-- -----------------------------------------------------------------------------
-- The function called by Core.lua, and locals
-- -----------------------------------------------------------------------------

local last_scale
function ApplyClearFontDesign(index)

	local scale					= ClearFont.db.profile.currentScale
	local scalechange 			= last_scale ~= scale
	last_scale 					= scale

	
-- -----------------------------------------------------------------------------
-- The different styles available in Core.lua
-- -----------------------------------------------------------------------------

	local NORMAL_TEXT_FONT		= ClearFont.fonts[index].normal
	local BOLD_TEXT_FONT		= ClearFont.fonts[index].bold
	local BOLDITALIC_TEXT_FONT	= ClearFont.fonts[index].bolditalic
	local ITALIC_TEXT_FONT		= ClearFont.fonts[index].italic
	local NUMBER_TEXT_FONT		= ClearFont.fonts[index].number



-- =============================================================================
--  B. WOW UI DESIGN
-- =============================================================================
--  This is the most important section to edit! I recommend using Notepad++ (http://notepad-plus.sourceforge.net)
--  Main font styles are listed first, the rest follows alphabetically
--  Lines listed are only where CF2 is altering the defaults - it does not always list every aspect of a font (such as shadow)
-- =============================================================================
--  The following can be used:
--  Font:SetFont(SOMETHING_TEXT_FONT, x * scale) ... no outline
--  Font:SetFont(SOMETHING_TEXT_FONT, x * scale, "OUTLINE") ... normal outline
--  Font:SetFont(SOMETHING_TEXT_FONT, x * scale, "THICKOUTLINE") ... thick outline
--  Font:SetTextColor(r, g, b) ... text colour
--  Font:SetShadowColor(r, g, b) ... shadow colour
--  Font:SetShadowOffset(x, y) ... shadow position
--  Font:SetAlpha(x) ... transparency
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Special game world '3D' fonts (Dark Imakuni)
-- Note that CF2 cannot define sizes or styles for these, just the fonts
-- Can taint on 2.1, so commented out
-- If you do not raid or set MT/MA, you can probably uncomment these lines without problem!
-- -----------------------------------------------------------------------------

-- Names above character's heads, free floating text (normally FRIZQT_.ttf)
-- UNIT_NAME_FONT = NORMAL_TEXT_FONT

-- Names above character's head, in nameplates (normally FRIZQT_.ttf)
-- NAMEPLATE_FONT = NORMAL_TEXT_FONT

-- Damage pop-up over targets , *not* SCT/SDT (normally FRIZQT_.ttf)
-- DAMAGE_TEXT_FONT = NORMAL_TEXT_FONT

-- Chat bubbles (normally FRIZQT_.ttf)
-- STANDARD_TEXT_FONT = NORMAL_TEXT_FONT


-- -----------------------------------------------------------------------------
-- Drop-down menu font size
-- Can taint on 2.1, so commented out
-- If you do not raid or set MT/MA, you can probably uncomment these lines without problem!
-- -----------------------------------------------------------------------------

-- UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT = 12 * scale


-- -----------------------------------------------------------------------------
-- System Font
-- The overall font, mostly used for inheritance purposes
-- -----------------------------------------------------------------------------

SystemFont:SetFont(NORMAL_TEXT_FONT, 17 * scale)


-- -----------------------------------------------------------------------------
-- Primary Game Fonts
-- Used as the main font used, e.g. window titles
-- Normally uses FRIZQT_.ttf, size 12, darker GameFontDisable
-- -----------------------------------------------------------------------------

GameFontNormal:SetFont(NORMAL_TEXT_FONT, 13 * scale)
GameFontHighlight:SetFont(NORMAL_TEXT_FONT, 13 * scale)

GameFontDisable:SetFont(NORMAL_TEXT_FONT, 13 * scale)
GameFontDisable:SetTextColor(0.6, 0.6, 0.6)

GameFontGreen:SetFont(NORMAL_TEXT_FONT, 13 * scale)
GameFontRed:SetFont(NORMAL_TEXT_FONT, 13 * scale)
GameFontBlack:SetFont(NORMAL_TEXT_FONT, 13 * scale)
GameFontWhite:SetFont(NORMAL_TEXT_FONT, 13 * scale)


-- -----------------------------------------------------------------------------
-- Small Game Fonts
-- Used as the main small font, e.g. character sheets, buff timers, macro titles
-- Normally uses FRIZQT_.ttf, size 10, darker GameFontDisableSmall and GameFontDarkGraySmall
-- -----------------------------------------------------------------------------

GameFontNormalSmall:SetFont(BOLD_TEXT_FONT, 11 * scale)

GameFontHighlightSmall:SetFont(BOLD_TEXT_FONT, 11 * scale)
GameFontHighlightSmallOutline:SetFont(BOLD_TEXT_FONT, 11 * scale, "OUTLINE")

GameFontDisableSmall:SetFont(BOLD_TEXT_FONT, 11 * scale)
GameFontDisableSmall:SetTextColor(0.6, 0.6, 0.6)

GameFontDarkGraySmall:SetFont(BOLD_TEXT_FONT, 11 * scale)
GameFontDarkGraySmall:SetTextColor(0.4, 0.4, 0.4)

GameFontGreenSmall:SetFont(BOLD_TEXT_FONT, 11 * scale)
GameFontRedSmall:SetFont(BOLD_TEXT_FONT, 11 * scale)


-- -----------------------------------------------------------------------------
-- Large Game Fonts
-- e.g. window titles
-- Normally uses FRIZQT_.ttf, size 16, darker GameFontDisableLarge
-- -----------------------------------------------------------------------------

GameFontNormalLarge:SetFont(BOLD_TEXT_FONT, 17 * scale)
GameFontHighlightLarge:SetFont(NORMAL_TEXT_FONT, 17 * scale)

GameFontDisableLarge:SetFont(NORMAL_TEXT_FONT, 17 * scale)
GameFontDisableLarge:SetTextColor(0.6, 0.6, 0.6)

GameFontGreenLarge:SetFont(NORMAL_TEXT_FONT, 17 * scale)
GameFontRedLarge:SetFont(NORMAL_TEXT_FONT, 17 * scale)


-- -----------------------------------------------------------------------------
-- Huge Game Fonts
-- Used for raid warnings
-- Normally uses FRIZQT_.ttf
-- -----------------------------------------------------------------------------

GameFontNormalHuge:SetFont(BOLD_TEXT_FONT, 20 * scale)


-- -----------------------------------------------------------------------------
-- Number Fonts
-- e.g. Auction House, money, icon keybinding & quantity overlays
-- Normally uses ARIALN.ttf, size 14/14/12/12/16/30
-- -----------------------------------------------------------------------------

NumberFontNormal:SetFont(NUMBER_TEXT_FONT, 15 * scale, "OUTLINE")
NumberFontNormalYellow:SetFont(NUMBER_TEXT_FONT, 15 * scale, "OUTLINE")
NumberFontNormalSmall:SetFont(NUMBER_TEXT_FONT, 13 * scale, "OUTLINE")
NumberFontNormalSmallGray:SetFont(NUMBER_TEXT_FONT, 13 * scale, "OUTLINE")
NumberFontNormalLarge:SetFont(NUMBER_TEXT_FONT, 17 * scale, "OUTLINE")

NumberFontNormalHuge:SetFont(NUMBER_TEXT_FONT, 30 * scale, "THICKOUTLINE")
NumberFontNormalHuge:SetAlpha(30)


-- -----------------------------------------------------------------------------
-- ChatFrame
-- Used for chat fonts and sizes
-- Normally uses ARIALN.ttf
-- -----------------------------------------------------------------------------

-- Chat and edit box font, edit box font size
ChatFontNormal:SetFont(NORMAL_TEXT_FONT, 14 * scale)

-- Added in 2.1 (thus check for existence by CanSetFont, otherwise errors in 2.0.x)
if (CanSetFont(ChatFontSmall)) then ChatFontSmall:SetFont(NORMAL_TEXT_FONT, 12 * scale); end

-- Extra chat font size options (add more if you wish!)
CHAT_FONT_HEIGHTS = {
	[1] = 7,
	[2] = 8,
	[3] = 9,
	[4] = 10,
	[5] = 11,
	[6] = 12,
	[7] = 13,
	[8] = 14,
	[9] = 15,
	[10] = 16,
	[11] = 17,
	[12] = 18,
	[13] = 19,
	[14] = 20,
	[15] = 21,
	[16] = 22,
	[17] = 23,
	[18] = 24
}

-- These would be used to set individual chat frames if they didn't just break everything :)
-- ChatFrame1:SetFont(NORMAL_TEXT_FONT, 14 * scale)
-- ChatFrame2:SetFont(NORMAL_TEXT_FONT, 14 * scale)
-- ChatFrame3:SetFont(NORMAL_TEXT_FONT, 14 * scale)
-- ChatFrame4:SetFont(NORMAL_TEXT_FONT, 14 * scale)
-- ChatFrame5:SetFont(NORMAL_TEXT_FONT, 14 * scale)
-- ChatFrame6:SetFont(NORMAL_TEXT_FONT, 14 * scale)
-- ChatFrame7:SetFont(NORMAL_TEXT_FONT, 14 * scale)


-- -----------------------------------------------------------------------------
-- CombatTextFont
-- In-built SCT-style info
-- Normally uses FRIZQT_.ttf, size 25
-- -----------------------------------------------------------------------------

CombatTextFont:SetFont(NORMAL_TEXT_FONT, 26 * scale)


-- -----------------------------------------------------------------------------
-- Quest Log
-- e.g. quest log, books
-- -----------------------------------------------------------------------------

-- Quest titles, normally MORPHEUS.ttf, size 18
QuestTitleFont:SetFont(BOLD_TEXT_FONT, 19 * scale)
QuestTitleFont:SetShadowColor(0.54, 0.4, 0.1)

-- Quest descriptions, normally FRIZQT_.ttf, size 13
QuestFont:SetFont(ITALIC_TEXT_FONT, 14 * scale)
QuestFont:SetTextColor(0.15, 0.09, 0.04)

-- Quest objectives, normally FRIZQT_.ttf, size 12
QuestFontNormalSmall:SetFont(BOLD_TEXT_FONT, 13 * scale)
QuestFontNormalSmall:SetShadowColor(0.54, 0.4, 0.1)

-- Normally FRIZQT_.ttf, size 14
QuestFontHighlight:SetFont(NORMAL_TEXT_FONT, 15 * scale)


-- -----------------------------------------------------------------------------
-- Dialog Buttons
-- e.g. "Accept" 
-- Normally uses FRIZQT_.ttf, size 16
-- -----------------------------------------------------------------------------

DialogButtonNormalText:SetFont(NORMAL_TEXT_FONT, 17 * scale)
DialogButtonHighlightText:SetFont(NORMAL_TEXT_FONT, 17 * scale)


-- -----------------------------------------------------------------------------
-- Error Log
-- e.g. "Another Action is in Progress" 
-- Normally uses FRIZQT_.ttf, no alpha
-- -----------------------------------------------------------------------------

ErrorFont:SetFont(ITALIC_TEXT_FONT, 16 * scale)
ErrorFont:SetAlpha(60)


-- -----------------------------------------------------------------------------
-- Invoice Text
-- Auction House sale invoices
-- Normally uses FRIZQT_.ttf, size 12/10
-- -----------------------------------------------------------------------------

InvoiceTextFontNormal:SetFont(ITALIC_TEXT_FONT, 13 * scale)
InvoiceTextFontNormal:SetTextColor(0.15, 0.09, 0.04)

InvoiceTextFontSmall:SetFont(ITALIC_TEXT_FONT, 11 * scale)
InvoiceTextFontSmall:SetTextColor(0.15, 0.09, 0.04)


-- -----------------------------------------------------------------------------
-- Item Info
-- Used for <Right click to read> item windows, such as [Lament of the Highborne]
-- Normally uses MORPHEUS.ttf, size 15
-- -----------------------------------------------------------------------------

ItemTextFontNormal:SetFont(NORMAL_TEXT_FONT, 16 * scale)


-- -----------------------------------------------------------------------------
-- Mail Text
-- In-game mails
-- Normally uses MORPHEUS.ttf, no shadow
-- -----------------------------------------------------------------------------

MailTextFontNormal:SetFont(ITALIC_TEXT_FONT, 15 * scale)
MailTextFontNormal:SetTextColor(0.15, 0.09, 0.04)
MailTextFontNormal:SetShadowColor(0.54, 0.4, 0.1)
MailTextFontNormal:SetShadowOffset(1, -1)


-- -----------------------------------------------------------------------------
-- PvPInfo
-- PvP objectives info
-- Normally uses FRIZQT_.ttf
-- -----------------------------------------------------------------------------

PVPInfoTextFont:SetFont(NORMAL_TEXT_FONT, 22 * scale, "THICKOUTLINE")


-- -----------------------------------------------------------------------------
-- Spell Book Subtitles
-- Spell and ability subtitles
-- Normally uses FRIZQT_.ttf, size 10
-- -----------------------------------------------------------------------------

SubSpellFont:SetFont(BOLD_TEXT_FONT, 11 * scale)


-- -----------------------------------------------------------------------------
-- Status Bars
-- Numbers on the unit frames, Damage Meters
-- Normally uses ARIALN.ttf, size 14/12
-- -----------------------------------------------------------------------------

TextStatusBarText:SetFont(NUMBER_TEXT_FONT, 13 * scale, "OUTLINE")
TextStatusBarTextSmall:SetFont(NORMAL_TEXT_FONT, 13 * scale)


-- -----------------------------------------------------------------------------
-- Tooltips
-- Text used in tooltips!
-- Normally uses FRIZQT_.ttf, size 12/10/14
-- -----------------------------------------------------------------------------

-- Main tooltip text
GameTooltipText:SetFont(NORMAL_TEXT_FONT, 13 * scale)
GameTooltipTextSmall:SetFont(BOLD_TEXT_FONT, 12 * scale)

-- Tooltip title
GameTooltipHeaderText:SetFont(BOLD_TEXT_FONT, 15 * scale, "OUTLINE")


-- -----------------------------------------------------------------------------
-- World Map
-- Map hover location titles
-- Normally uses FRIZQT_.ttf, size 102 (!), no alpha
-- -----------------------------------------------------------------------------

WorldMapTextFont:SetFont(BOLDITALIC_TEXT_FONT, 31 * scale, "THICKOUTLINE")
WorldMapTextFont:SetShadowColor(0, 0, 0)
WorldMapTextFont:SetShadowOffset(1, -1)
WorldMapTextFont:SetAlpha(40)


-- -----------------------------------------------------------------------------
-- Zone Text
-- On-screen notifications of zone changes
-- Normally uses FRIZQT_.ttf, size 102/26
-- -----------------------------------------------------------------------------

-- Zone changes (colour cannot be set)
ZoneTextFont:SetFont(BOLDITALIC_TEXT_FONT, 31 * scale, "THICKOUTLINE")
ZoneTextFont:SetShadowColor(0, 0, 0)
ZoneTextFont:SetShadowOffset(1, -1)

-- Subzone changes (colour cannot be set)
SubZoneTextFont:SetFont(BOLDITALIC_TEXT_FONT, 27 * scale, "THICKOUTLINE")


-- -----------------------------------------------------------------------------
-- CombatLogFont
-- Appears to be unused
-- Normally uses FRIZQT_.ttf, size 12
-- -----------------------------------------------------------------------------

CombatLogFont:SetFont(NORMAL_TEXT_FONT, 13 * scale)

-- =============================================================================
--  D. AND FINALLY...
-- =============================================================================

end
