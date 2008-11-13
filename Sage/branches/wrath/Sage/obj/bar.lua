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

local bgDarkness = 0.5
function StatusBar:SetColor(r, g, b)
	self:SetStatusBarColor(r, g, b)
	self.bg:SetVertexColor(r * bgDarkness, g * bgDarkness, b * bgDarkness, bgDarkness)
end

function StatusBar:ForAll(method, ...)
	for _,bar in pairs(bars) do
		bar[method](bar, ...)
	end
end