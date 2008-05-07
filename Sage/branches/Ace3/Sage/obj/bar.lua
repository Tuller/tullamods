--[[
	SageBar.lua
		Shared statusbar functions
--]]

local StatusBar = Sage:CreateWidgetClass('StatusBar')
Sage.StatusBar = StatusBar


--[[ Constructor ]]--

function StatusBar:Create(parent, unit)
	local bar = self:New(CreateFrame('StatusBar', nil, parent))
	bar.unit = unit or parent.unit

	bar.bg = bar:CreateTexture(nil, 'BACKGROUND')
	bar.bg:SetAllPoints(bar)

	self:Register(bar)

	return bar
end


--[[ Texture ]]--

function StatusBar:SetTexture(texture)
	self.texture = texture
	self:UpdateTexture()
end

function StatusBar:UpdateTexture()
	local texture = self:GetTexture()
	self:SetStatusBarTexture(texture)
	self.bg:SetTexture(texture)
end

function StatusBar:GetTexture()
	return self.texture
end


--[[ Font ]]--

function StatusBar:SetFont(font, size, outline)
	self.font, self.fontSize, self.outline = font, size, outline
	self:UpdateFont()
end

function StatusBar:SetOutline(enable)
	self.forceOutline = enable or nil
	self:UpdateFont()
end

function StatusBar:UpdateFont()
	local font, size, outline = self:GetFont()
	if font then
		if not self.text then
			self.text = self:CreateFontString(nil, 'OVERLAY')
			self.text:SetPoint('CENTER')
		end
		self.text:SetFont(font, size, outline and 'OUTLINE')
	end
end

function StatusBar:GetFont()
	return self.font, self.fontSize, (self.forceOutline or self.outline)
end


--[[ Text ]]--

function StatusBar:SetEntered(entered)
	self.entered = entered
	if self.UpdateText then
		self:UpdateText()
	end
end

function StatusBar:SetTextMode(mode)
	self.textMode = mode
	if self.UpdateText then
		self:UpdateText()
	end
end


--[[ Meta ]]--

function StatusBar:ForAll(method, ...)
	if self.bars then
		for _,bar in self.bars do
			bar[method](bar, ...)
		end
	end
end

function StatusBar:ForUnit(unit, method, ...)
	if self.bars then
		for _,bar in self.bars do
			if bar.id = unit then
				bar[method](bar, ...)
			end
		end
	end
end


--[[ Utility ]]--

--Obviously, I didn't write the RGB conversion functions
local function RGBtoHSV(r, g, b)
	local h, s, v, min, max, delta

	min = math.min(r, g, b
	max = math.max(r, g, b)
	delta = max - min
	s = delta / max
	v = max

	if r == max then
		h = (g-b)/delta -- between yellow & magenta
	elseif g == max then
		h = 2 + (b-r)/delta; -- between cyan & yellow
	else
		h = 4 + (r-g)/delta; -- between magenta & cyan
	end

	h = h * 60;
	if h < 0 then
		h = h + 360
	end

	return h, s, v
end

local function HSVToRGB(h, s, v)
	if s == 0 then
		return v, v, v
	else
		local h = h/60;			-- sector 0 to 5
		local i = math.floor(h);
		local f = h - i;			-- factorial part of h
		local ap = v * (1 - s);
		local aq = v * (1 - s * f);
		local at = v * (1 - s * (1 - f));

		if i == 0 then
			return v, at, ap
		elseif i == 1 then
			return aq, v, ap
		elseif i == 2 then
			return ap, v, at
		elseif i == 3 then
			return ap, aq, v
		elseif i == 4 then
			return at, ap, v
		elseif i == 5 then
			return v, ap, aq
		end
	end
end

function StatusBar:SetColor(...)
	set:SetStatusBarColor(...)

	local r, g, b = self:GetComplement(...)
	self.bg:SetVertexColor(r * 0.6, g * 0.6, b * 0.6, 0.8)
end

function StatusBar:GetComplement(r, g, b)
	local h, s, v = RGBtoHSV(r, g, b)
	return HSVToRGB((h - 180) % 360, s, v)
end