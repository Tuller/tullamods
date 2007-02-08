--[[
	Sage Fonts
		Functions for loading and updating the fonts used by Sage UnitFrames

	SageFont
		Used for unit names

	SageFontSmall
		Used for level numbers, health percentages, and target info

	SageFontSmallOutline
		Used for the level number when the unit is flagged, or a raid target.

	SageBarFont
		Used for healthbars

	SageBarFontSmall
		Used for manabars
--]]

local DEFAULT_SIZE = 14

SFont = {}

function SFont.LoadAll()
	SFont.LoadBar()
	SFont.LoadOutside()
end

function SFont.LoadBar()
	local fontSize = SFont.GetSize()

	if not SageBarFont then 
		CreateFont("SageBarFont") 
	end

	if SageDB.outlineBarFonts then
		SageBarFont:SetFont(GameFontHighlight:GetFont(), fontSize, "OUTLINE")
		SageBarFont:SetShadowOffset(0, 0)
		SageBarFont:SetShadowColor(0, 0, 0, 0)
	else
		SageBarFont:SetFont(GameFontHighlight:GetFont(), fontSize)
		SageBarFont:SetShadowOffset(1, -1)
		SageBarFont:SetShadowColor(0, 0, 0, 1)
	end

	if not SageBarFontSmall then 
		CreateFont("SageBarFontSmall") 
	end

	if SageDB.outlineBarFonts then
		SageBarFontSmall:SetFont(GameFontHighlight:GetFont(), fontSize * 0.9, "OUTLINE")
		SageBarFontSmall:SetShadowOffset(0, 0)
		SageBarFontSmall:SetShadowColor(0, 0, 0, 0)
	else
		SageBarFontSmall:SetFont(GameFontHighlight:GetFont(), fontSize * 0.9)
		SageBarFontSmall:SetShadowOffset(1, -1)
		SageBarFontSmall:SetShadowColor(0, 0, 0, 1)
	end
end

function SFont.LoadOutside()
	local fontSize = SFont.GetSize()

	if not SageFont then 
		CreateFont("SageFont")
	end

	if SageDB.outlineOutsideFonts then
		SageFont:SetFont(GameFontHighlight:GetFont(), fontSize, "OUTLINE")
		SageFont:SetShadowOffset(0, 0)
		SageFont:SetShadowColor(0, 0, 0, 0)
	else
		SageFont:SetFont(GameFontHighlight:GetFont(), fontSize)
		SageFont:SetShadowOffset(1, -1)
		SageFont:SetShadowColor(0, 0, 0, 1)
	end

	if not SageFontSmall then 
		CreateFont("SageFontSmall") 
	end

	if SageDB.outlineOutsideFonts then
		SageFontSmall:SetFont(GameFontHighlight:GetFont(), fontSize * 0.84, "OUTLINE")
		SageFontSmall:SetShadowOffset(0, 0)
		SageFontSmall:SetShadowColor(0, 0, 0, 0)
	else
		SageFontSmall:SetFont(GameFontHighlight:GetFont(), fontSize * 0.84)
		SageFontSmall:SetShadowOffset(1, -1)
		SageFontSmall:SetShadowColor(0, 0, 0, 1)
	end

	if not SageFontSmallOutline then 
		CreateFont("SageFontSmallOutline") 
	end

	SageFontSmallOutline:SetFont(GameFontHighlight:GetFont(), fontSize * 0.84, "OUTLINE")
end

--sets whether to outline outsize fonts (name and target info)
function SFont.OutlineOutside(enable)
	if enable then
		SageDB.outlineOutsideFonts = 1
	else
		SageDB.outlineOutsideFonts = nil
	end

	SFont.LoadOutside()
	SageInfo.ForAll(SageInfo.UpdateWidth)
end

--sets whether to outline bar fonts (healthbar, and manabar text)
function SFont.OutlineBar(enable)
	if enable then
		SageDB.outlineBarFonts = 1
	else
		SageDB.outlineBarFonts = nil
	end

	SFont.LoadBar()
	SageInfo.ForAll(SageInfo.UpdateWidth)
end

--Sets the general size to use for the fonts.  All font sizes are based on some ratio of this size
function SFont.SetSize(size)
	SageDB.fontSize = size or DEFAULT_SIZE
	SFont.LoadAll()
end

function SFont.GetSize() 
	return SageDB.fontSize or DEFAULT_SIZE 
end