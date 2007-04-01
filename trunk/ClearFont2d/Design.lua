-- /////////////////////////////////////////////////////////////////////////////
-- =============================================================================
--  CLEARFONT2_DESIGN BY KIRKBURN
--  Official website:  http://www.clearfont.co.uk/
-- -----------------------------------------------------------------------------
--  DESIGN.LUA - THE CLEARFONT DESIGN CODE
--	A. SETTING UP THE ADDON
--	B. WOW UI DESIGN
-- =============================================================================
-- /////////////////////////////////////////////////////////////////////////////


-- =============================================================================
--  A. SETTING UP THE ADDON
-- =============================================================================


-- -----------------------------------------------------------------------------
-- The function to be called
-- -----------------------------------------------------------------------------

function ApplyClearFontDesign(index)

-- =============================================================================
--  B. WOW UI DESIGN
-- =============================================================================
--  This is the most important section to edit!
--  Main font styles are listed first, the rest follows alphabetically
-- =============================================================================

local scale 			= ClearFont.profile.currentScale
local NORMAL_TEXT_FONT		= ClearFont.fonts[index].normal
local BOLD_TEXT_FONT		= ClearFont.fonts[index].bold
local BOLDITALIC_TEXT_FONT	= ClearFont.fonts[index].bolditalic
local ITALIC_TEXT_FONT		= ClearFont.fonts[index].italic
local NUMBER_TEXT_FONT		= ClearFont.fonts[index].number
local scalechange = last_scale ~= scale
last_scale = scale

-- -----------------------------------------------------------------------------
-- In-World, '3D' Fonts, etc. (Dark Imakuni)
-- -----------------------------------------------------------------------------

-- Names above people's heads
UNIT_NAME_FONT = NORMAL_TEXT_FONT
NAMEPLATE_FONT = NORMAL_TEXT_FONT

-- The damage pop-up over your target's head (*not* SCT/SDT)
DAMAGE_TEXT_FONT = NUMBER_TEXT_FONT

-- Chat bubbles
STANDARD_TEXT_FONT = NORMAL_TEXT_FONT

-- Drop-down menu font
UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT = 12 * scale


-- -----------------------------------------------------------------------------
-- System Font
-- -----------------------------------------------------------------------------

SystemFont:SetFont(NORMAL_TEXT_FONT, 17 * scale)


-- -----------------------------------------------------------------------------
-- Primary Game Fonts: the main font used, window titles
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
-- Small Game Fonts: the main small font, used on character sheets, buff timers, Titan Panel
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
-- Large Game Fonts: titles
-- -----------------------------------------------------------------------------

GameFontNormalLarge:SetFont(BOLD_TEXT_FONT, 17 * scale)
GameFontHighlightLarge:SetFont(NORMAL_TEXT_FONT, 17 * scale)

GameFontDisableLarge:SetFont(NORMAL_TEXT_FONT, 17 * scale)
GameFontDisableLarge:SetTextColor(0.6, 0.6, 0.6)

GameFontGreenLarge:SetFont(NORMAL_TEXT_FONT, 17 * scale)
GameFontRedLarge:SetFont(NORMAL_TEXT_FONT, 17 * scale)


-- -----------------------------------------------------------------------------
-- Huge Game Fonts: raid warnings
-- -----------------------------------------------------------------------------

GameFontNormalHuge:SetFont(BOLD_TEXT_FONT, 20 * scale)


-- -----------------------------------------------------------------------------
-- CombatTextFont: in-built SCT-style info
-- -----------------------------------------------------------------------------

CombatTextFont:SetFont(NORMAL_TEXT_FONT, 26 * scale)


-- -----------------------------------------------------------------------------
-- Number Fonts: used in Auction House, money, keybinding, & quantity overlays
-- -----------------------------------------------------------------------------

NumberFontNormal:SetFont(NUMBER_TEXT_FONT, 15 * scale, "OUTLINE")
NumberFontNormalYellow:SetFont(NUMBER_TEXT_FONT, 15 * scale, "OUTLINE")
NumberFontNormalSmall:SetFont(NUMBER_TEXT_FONT, 13 * scale, "OUTLINE")
NumberFontNormalSmallGray:SetFont(NUMBER_TEXT_FONT, 13 * scale, "OUTLINE")
NumberFontNormalLarge:SetFont(NUMBER_TEXT_FONT, 17 * scale, "OUTLINE")

NumberFontNormalHuge:SetFont(NUMBER_TEXT_FONT, 30 * scale, "THICKOUTLINE")
NumberFontNormalHuge:SetAlpha(30)


-- -----------------------------------------------------------------------------
-- Chat window input font & increased size options available for the chat window font
-- -----------------------------------------------------------------------------

ChatFontNormal:SetFont(NORMAL_TEXT_FONT, 14 * scale)

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


-- -----------------------------------------------------------------------------
-- Quest Log: used in the quest log, books and more
-- -----------------------------------------------------------------------------

QuestTitleFont:SetFont(BOLD_TEXT_FONT, 19 * scale)
QuestTitleFont:SetShadowColor(0.54, 0.4, 0.1)

QuestFont:SetFont(ITALIC_TEXT_FONT, 14 * scale)
QuestFont:SetTextColor(0.15, 0.09, 0.04)

QuestFontNormalSmall:SetFont(BOLD_TEXT_FONT, 13 * scale)
QuestFontNormalSmall:SetShadowColor(0.54, 0.4, 0.1)

QuestFontHighlight:SetFont(NORMAL_TEXT_FONT, 15 * scale)


-- -----------------------------------------------------------------------------
-- Dialog Buttons: "Accept", etc.
-- -----------------------------------------------------------------------------

DialogButtonNormalText:SetFont(NORMAL_TEXT_FONT, 17 * scale)
DialogButtonHighlightText:SetFont(NORMAL_TEXT_FONT, 17 * scale)


-- -----------------------------------------------------------------------------
-- Error Log: "Another Action is in Progress", etc.
-- -----------------------------------------------------------------------------

ErrorFont:SetFont(ITALIC_TEXT_FONT, 16 * scale)
ErrorFont:SetAlpha(60)


-- -----------------------------------------------------------------------------
-- Item Info: general usage in frames
-- -----------------------------------------------------------------------------

ItemTextFontNormal:SetFont(NORMAL_TEXT_FONT, 16 * scale)


-- -----------------------------------------------------------------------------
-- Mail & Invoice Text: in-game mails & Auction House invoices
-- -----------------------------------------------------------------------------

MailTextFontNormal:SetFont(ITALIC_TEXT_FONT, 15 * scale)
MailTextFontNormal:SetTextColor(0.15, 0.09, 0.04)
MailTextFontNormal:SetShadowColor(0.54, 0.4, 0.1)
MailTextFontNormal:SetShadowOffset(1, -1)

InvoiceTextFontNormal:SetFont(ITALIC_TEXT_FONT, 13 * scale)
InvoiceTextFontNormal:SetTextColor(0.15, 0.09, 0.04)

InvoiceTextFontSmall:SetFont(ITALIC_TEXT_FONT, 11 * scale)
InvoiceTextFontSmall:SetTextColor(0.15, 0.09, 0.04)


-- -----------------------------------------------------------------------------
-- Spell Book: ability subtitles
-- -----------------------------------------------------------------------------

SubSpellFont:SetFont(BOLD_TEXT_FONT, 11 * scale)


-- -----------------------------------------------------------------------------
-- Status Bars: Numbers on the unit frames, Damage Meters
-- -----------------------------------------------------------------------------

TextStatusBarText:SetFont(NUMBER_TEXT_FONT, 12 * scale, "OUTLINE")
TextStatusBarTextSmall:SetFont(NORMAL_TEXT_FONT, 13 * scale)


-- -----------------------------------------------------------------------------
-- Tooltips
-- -----------------------------------------------------------------------------

GameTooltipText:SetFont(NORMAL_TEXT_FONT, 13 * scale)
GameTooltipTextSmall:SetFont(BOLD_TEXT_FONT, 12 * scale)
GameTooltipHeaderText:SetFont(BOLD_TEXT_FONT, 15 * scale, "OUTLINE")


-- -----------------------------------------------------------------------------
-- World Map: location titles
-- -----------------------------------------------------------------------------

WorldMapTextFont:SetFont(BOLDITALIC_TEXT_FONT, 31 * scale, "THICKOUTLINE")
WorldMapTextFont:SetShadowColor(0, 0, 0)
WorldMapTextFont:SetShadowOffset(1, -1)
WorldMapTextFont:SetAlpha(40)


-- -----------------------------------------------------------------------------
-- Zone Changes: on-screen notifications
-- -----------------------------------------------------------------------------

ZoneTextFont:SetFont(BOLDITALIC_TEXT_FONT, 31 * scale, "THICKOUTLINE")
ZoneTextFont:SetShadowColor(0, 0, 0)
ZoneTextFont:SetShadowOffset(1, -1)

SubZoneTextFont:SetFont(BOLDITALIC_TEXT_FONT, 27 * scale, "THICKOUTLINE")


-- -----------------------------------------------------------------------------
-- Appears to no longer be used?
-- -----------------------------------------------------------------------------

CombatLogFont:SetFont(NORMAL_TEXT_FONT, 13 * scale)


-- -----------------------------------------------------------------------------
-- PvP Objective Info
-- -----------------------------------------------------------------------------

PVPInfoTextFont:SetFont(NORMAL_TEXT_FONT, 22 * scale, "THICKOUTLINE")



-- =============================================================================
--  C. DYNAMIC ADDON UPDATES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- And finally ...
-- -----------------------------------------------------------------------------
end