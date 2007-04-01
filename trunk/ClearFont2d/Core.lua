-- /////////////////////////////////////////////////////////////////////////////
-- =============================================================================
--  CLEARFONT2 BY KIRKBURN
--  Official website:  http://www.clearfont.co.uk/
-- -----------------------------------------------------------------------------
--  CORE.LUA - STANDARD WOW UI FONTS
--	A. FONT LOCALS
--	B. SETTING UP THE ADDON
--	C. APPLY THE FONT CHOICES
-- =============================================================================
-- /////////////////////////////////////////////////////////////////////////////


-- -----------------------------------------------------------------------------
-- Create instance of the Ace2 addon
-- -----------------------------------------------------------------------------

ClearFont = DongleStub("Dongle-Beta1"):New("ClearFont2d")

-- =============================================================================
--  A. FONT LOCALS
-- =============================================================================

local fontLoc = "Interface\\AddOns\\ClearFont2d\\Fonts\\"
ClearFont.fonts = {
	{["name"]="Default",
		["normal"]		=fontLoc.."Calibri_v1\\Calibri.ttf",
		["bold"]		=fontLoc.."Calibri_v1\\CalibriBold.ttf",
		["italic"]		=fontLoc.."Calibri_v1\\CalibriItalic.ttf",
		["bolditalic"]	=fontLoc.."Calibri_v1\\CalibriBoldItalic.ttf",
		["number"]		=fontLoc.."Calibri_v1\\CalibriBold.ttf"},

	{["name"]="Baar Philos",
		["normal"]		=fontLoc.."BaarPhilos\\BaarPhilos.ttf",
		["bold"]		=fontLoc.."BaarPhilos\\BaarPhilosBold.ttf",
		["italic"]		=fontLoc.."BaarPhilos\\BaarPhilosItalic.ttf",
		["bolditalic"]	=fontLoc.."BaarPhilos\\BaarPhilosBoldItalic.ttf",
		["number"]		=fontLoc.."BaarPhilos\\BaarPhilosBold.ttf"},

	{["name"]="Baar Sophia",
		["normal"]		=fontLoc.."BaarSophia\\BaarSophia.ttf",
		["bold"]		=fontLoc.."BaarSophia\\BaarSophiaBold.ttf",
		["italic"]		=fontLoc.."BaarSophia\\BaarSophiaItalic.ttf",
		["bolditalic"]	=fontLoc.."BaarSophia\\BaarSophiaBoldItalic.ttf",
		["number"]		=fontLoc.."BaarSophia\\BaarSophiaBold.ttf"},

	{["name"]="Classic",
		["normal"]		=fontLoc.."Calibri_v0.9\\Calibri.ttf",
		["bold"]		=fontLoc.."Calibri_v0.9\\CalibriBold.ttf",
		["italic"]		=fontLoc.."Calibri_v0.9\\CalibriItalic.ttf",
		["bolditalic"]	=fontLoc.."Calibri_v0.9\\CalibriBoldItalic.ttf",
		["number"]		=fontLoc.."Calibri_v0.9\\CalibriBold.ttf"},

	{["name"]="Francophil Sans",
		["normal"]		=fontLoc.."Franc\\Franc.ttf",
		["bold"]		=fontLoc.."Franc\\FrancBold.ttf",
		["italic"]		=fontLoc.."Franc\\Franc.ttf",
		["bolditalic"]	=fontLoc.."Franc\\FrancBold.ttf",
		["number"]		=fontLoc.."Franc\\FrancBold.ttf"},

	{["name"]="Lucida Grande",
		["normal"]		=fontLoc.."LucidaGrande\\LucidaGrande.ttf",
		["bold"]		=fontLoc.."LucidaGrande\\LucidaGrande.ttf",
		["italic"]		=fontLoc.."LucidaGrande\\LucidaGrande.ttf",
		["bolditalic"]	=fontLoc.."LucidaGrande\\LucidaGrande.ttf",
		["number"]		=fontLoc.."LucidaGrande\\LucidaGrande.ttf"},

	{["name"]="Lucida Sans Demibold",
		["normal"]		=fontLoc.."LucidaSD\\LucidaSD.ttf",
		["bold"]		=fontLoc.."LucidaSD\\LucidaSD.ttf",
		["italic"]		=fontLoc.."LucidaSD\\LucidaSDItalic.ttf",
		["bolditalic"]	=fontLoc.."LucidaSD\\LucidaSDItalic.ttf",
		["number"]		=fontLoc.."LucidaSD\\LucidaSD.ttf"},

	{["name"]="Perspective Sans",
		["normal"]		=fontLoc.."PerspectiveSans\\PerspectiveSans.ttf",
		["bold"]		=fontLoc.."PerspectiveSans\\PerspectiveSansBold.ttf",
		["italic"]		=fontLoc.."PerspectiveSans\\PerspectiveSansItalic.ttf",
		["bolditalic"]	=fontLoc.."PerspectiveSans\\PerspectiveSansBoldItalic.ttf",
		["number"]		=fontLoc.."PerspectiveSans\\PerspectiveSansBold.ttf"},

	{["name"]="Tin Birdhouse",
		["normal"]		=fontLoc.."TinBirdhouse\\TinBirdhouse.ttf",
		["bold"]		=fontLoc.."TinBirdhouse\\TinBirdhouse.ttf",
		["italic"]		=fontLoc.."TinBirdhouse\\TinBirdhouse.ttf",
		["bolditalic"]	=fontLoc.."TinBirdhouse\\TinBirdhouse.ttf",
		["number"]		=fontLoc.."TinBirdhouse\\TinBirdhouse.ttf"},
}

-- =============================================================================
--  B. SETTING UP THE ADDON
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Startup call when addon is loaded
-- -----------------------------------------------------------------------------

function ClearFont:Initialize()
	self.db = self:InitializeDB("ClearFont2dDB", {profile = {
		currentFont = "Default",
		currentScale = 1.0,
		applyAll = true,
	}})
	self.profile = self.db.profile

	self:RegisterSlashCommands()
	self:RegisterEvent("ADDON_LOADED", "ApplyFont")
end

function ClearFont:RegisterSlashCommands()
	local slash = self:InitializeSlashCommand("commands", "CLEARFONT2D", "clearfont2d", "cf2d")
	slash:RegisterSlashHandler(format("font <font>: %s", "changes font face"), "font ([%w%s%p]+)", "SetFont")
	slash:RegisterSlashHandler(format("scale <scale>: %s", "changes font scale"), "scale ([%d%.]+)", "SetScale")
	slash:RegisterSlashHandler(format("apply: %s", "toggle applying font settings to addons"), "apply", "ToggleApplyToAddons")
	slash:RegisterSlashHandler(format("fonts: %s", "lists loaded fonts"), "fonts", "ListFonts")

	self.slash = slash
end

-- =============================================================================
--  C. APPLY THE FONT CHOICES
-- =============================================================================

function ClearFont:ApplyFont()
	local currentFont
	if self.profile.currentFont then
		currentFont = self.profile.currentFont:lower()
	end

	local index = 1
	for i,f in pairs(self.fonts) do
		if f.name:lower() == currentFont then
			index = i
			break
		end
	end

	if not self.fonts[index].normal then return end

	if type(ApplyClearFontDesign) == "function" then
		ApplyClearFontDesign(index)
	end

	if type(ApplyCustomClearFontDesign) == "function" then
		ApplyCustomClearFontDesign()
	end
end

function ClearFont:SetFont(font)
	self.profile.currentFont = font or "default"
	self:ApplyFont()
	self:Print(format("Set font to %s", font or "default"))
end

function ClearFont:SetScale(scale)
	scale = tonumber(scale)
	if scale then
		self.profile.currentScale = tonumber(scale)
		self:ApplyFont()
		self:Print(format("Set scale to %s", scale))
	end
end

function ClearFont:ToggleApplyToAddons()
	if self.profile.applyAll then
		self:Print("Disabled applying fonts to addons")
		self.profile.applyAll = nil
	else
		self:Print("Enabled applying fonts to addons")
		self.profile.applyAll = true
	end
	self:ApplyFont()
end

function ClearFont:ListFonts()
	self:Print("Loaded Fonts")

	for i, font in ipairs(self.fonts) do
		ChatFrame1:AddMessage(format("- %s", font.name))
	end
end
