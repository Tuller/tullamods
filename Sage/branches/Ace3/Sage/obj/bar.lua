--[[
	SageBar.lua
		Shared statusbar functions
--]]

local StatusBar = Sage:CreateWidgetClass('StatusBar')
Sage.StatusBar = StatusBar


--[[ Constructor ]]--

function StatusBar:Create(parent, id, font, size, outline)
	local bar = self:New(CreateFrame('StatusBar', nil, parent))
	bar.id = id or parent.id
	
	bar.bg = bar:CreateTexture(nil, 'BACKGROUND')
	bar.bg:SetAllPoints(bar)
	
	if font then
		bar.text = bar:CreateFontString(nil, 'OVERLAY')
		bar.text:SetPoint('CENTER')
		bar.text:SetFont(font, size, outline)
	end
	
	self:Register(bar)
	
	return bar
end


--[[ Texture ]]--

function StatusBar:SetTexture(texture)
	self.texture = texture
	self:ForAll('UpdateTexture', texture)
end

function StatusBar:UpdateTexture(texture)
	local texture = texture or self.texture
	self:SetStatusBarTexture(texture)
	self.bg:SetTexture(texture)
end

function StatusBar:GetTexture()
	return self.texture
end


--[[ Font ]]--

function StatusBar:SetFont(...)
	self.font, self.fontSize, self.outline = ...
	self:ForAll('UpdateFont', ...)
end

function StatusBar:UpdateFont()
	if self.text then
		self.text:SetFont(self:GetFont())
	end
end

function StatusBar:GetFont()
	return self.font, self.fontSize, self.outline
end


--[[ Callbacks ]]--

function StatusBar:SetTextMode(mode)
	self.textMode = mode
end

function StatusBar:UpdateText(...)
	if self.OnTextUpdate then
		self:OnTextUpdate(...)
	end
end

function StatusBar:GetTextMode()
	return self.textMode
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

function StatusBar:GetComplement(r, g, b)
	local h, s, v = RGBtoHSV(r, g, b)
	return HSVToRGB((h - 180) % 360, s, v)
end