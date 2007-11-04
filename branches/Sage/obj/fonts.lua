--[[
	Sage Fonts
		Functions for getting and updating the fonts used by Sage
--]]

local function Font_Update(self, size, outline)
	local base = GameFontHighlight:GetFont()

	if outline then
		self:SetFont(base, size, "OUTLINE")
		self:SetShadowOffset(0, 0)
	else
		self:SetFont(base, size)
		self:SetShadowOffset(1, -1)
		self:SetShadowColor(0, 0, 0)
	end
end

SageFont = {}

--updating
function SageFont:Update()
	self:UpdateBarFonts()
	self:UpdateOutsideFonts()
end

function SageFont:UpdateBarFonts()
	local fontSize = Sage:GetFontSize()
	local outline = Sage:OutlineBarFonts()

	Font_Update(self:GetBarFont(), fontSize, outline)
	Font_Update(self:GetSmallBarFont(), fontSize * 0.9, outline)
end

function SageFont:UpdateOutsideFonts()
	local fontSize = Sage:GetFontSize()
	local outline = Sage:OutlineOutsideFonts()

	Font_Update(self:GetOutsideFont(), fontSize, outline)
	Font_Update(self:GetSmallOutsideFont(), fontSize * 0.84, outline)
	Font_Update(self:GetLevelFont(), fontSize * 0.84, true)
end

--access
function SageFont:GetBarFont()
	if not self.font then
		self.font = CreateFont("SageBarFont")
	end
	return self.font
end

function SageFont:GetSmallBarFont()
	if not self.fontSmall then
		self.fontSmall = CreateFont("SageBarFontSmall")
	end
	return self.fontSmall
end

function SageFont:GetOutsideFont()
	if not self.oFont then
		self.oFont = CreateFont("SageOutsideFont")
	end
	return self.oFont
end

function SageFont:GetSmallOutsideFont()
	if not self.oFontSmall then
		self.oFontSmall = CreateFont("SageOutsideFontSmall")
	end
	return self.oFontSmall
end

function SageFont:GetLevelFont()
	if not self.levelFont then
		self.levelFont = CreateFont("SageLevelFont")
	end
	return self.levelFont
end