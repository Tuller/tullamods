--[[
	SageBar.lua
		Shared statusbar functions
--]]

local StatusBar = Sage:CreateClass('StatusBar')
Sage.StatusBar = StatusBar

local bars = {}

function StatusBar:New(type, parent, font)
	local name =  parent:GetName() .. type

	local bar = self:Bind(CreateFrame('StatusBar', name, parent))
	bar:SetAttribute('unit', parent:GetAttribute('unit'))

	bar.bg = bar:CreateTexture(name .. 'bg', 'BACKGROUND')
	bar.bg:SetAllPoints(bar)

	bar:UpdateTexture()

	if font then
		local text = bar:CreateFontString(name .. 'text', 'OVERLAY')
		text:SetPoint('RIGHT', -2, 0)
		text:SetFontObject(font)
		bar.text = text
	end

	table.insert(bars, bar)
	return bar
end

function StatusBar:UpdateTexture(texture)
	local texture = texture or Sage:GetStatusBarTexture()
	self:SetStatusBarTexture(texture)
	self.bg:SetTexture(texture)
end


--[[
	RGB and HSL transformations were obviously not written by me
--]]

local RybWheel = {
	0,  26,  52,
	83, 120, 130,
	141, 151, 162,
	177, 190, 204,
	218, 232, 246,
	261, 275, 288,
	303, 317, 330,
	338, 345, 352,
	360
}

local RgbWheel = {
	0,   8,  17,
	26,  34,  41,
	48,  54,  60,
	81, 103, 123,
	138, 155, 171,
	187, 204, 219,
	234, 251, 267,
	282, 298, 329,
	360
}

local function RgbToRyb(hue)
	local d = hue % 15
	local i = tonumber(format('%d', hue / 15)) + 1
	local x0 = RybWheel[i] or 0
	local x1 = RybWheel[i + 1] or 360

	return x0 + (x1 - x0) * d / 15
end

local function RybToRgb(hue)
	local d = hue % 15
	local i = tonumber(format('%d', hue / 15)) + 1
	local x0 = RgbWheel[i]
	local x1 = RgbWheel[i + 1]

	return x0 + (x1 - x0) * d / 15
end

local function RGBToHSV(r, g, b)
	local v = max(r, g, b)
	local d = v - min(r, g, b)
	if d == 0 then
		return 0, 0, v
	end

	local s = d / v
	local dr = (v - r) / d
	local dg = (v - g) / d
	local db = (v - b) / d

	if r == v then
		h = db - dg
	elseif g == v then
		h = 2 + dr - db
	else
		h = 4 + dg - dr
	end

	h = (h * 60.0) % 360.0

	return h, s, v
end

local function HSVToRGB(h, s, v)
	if s == 0 then
		return v, v, v
	else
		h = h / 60.0
	    h = h % 6

		local i = tonumber(format('%d', h))
		local f = h - i
		if i % 2 == 0 then
			f = 1 - f
		end

		local m = v * (1 - s)
		local n = v * (1 - (s * f))

		if i == 0 then
			return v, n, m
		elseif i == 1 then
			return n, v, m
		elseif i == 2 then
			return m, v, n
		elseif i == 3 then
			return m, n, v
		elseif i == 4 then
			return n, m, v
		else
			return v, m, n
		end
	end
end

local function Complement(h, s, v)
	h = RgbToRyb(h)
	h = (h + 180) % 360
	h = RybToRgb(h)

	return h, s, v
end

local bgDarkness = 0.6
function StatusBar:SetColor(r, g, b)
	local h, s, v = RGBToHSV(r, g, b)
	local cR, cG, cB = HSVToRGB(Complement(h, s, v))

	self:SetStatusBarColor(r, g, b)
	self.bg:SetVertexColor(cR * bgDarkness, cG * bgDarkness, cB * bgDarkness, bgDarkness)
end

function StatusBar:ForAll(method, ...)
	for _,bar in pairs(bars) do
		bar[method](bar, ...)
	end
end