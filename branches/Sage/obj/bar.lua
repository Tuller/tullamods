--[[
	SageBar.lua
		Shared statusbar functions
--]]

SageBar = {}

local lastCreated = 0
function SageBar:Create(parent, id, font, alwaysShow)
	local name = format("SageBar%s", tonumber(lastCreated, 36))
	local bar = CreateFrame("StatusBar", name, parent)
	bar.id = id or parent.id

	bar.bg = bar:CreateTexture(name .. "bg", "BACKGROUND")
	bar.bg:SetAllPoints(bar)

	if(font) then
		bar.mode = Sage:GetTextMode(bar.id)
		bar.text = bar:CreateFontString(name .. "text", "OVERLAY")
		bar.text:SetPoint("CENTER", bar)
		bar.text:SetFontObject(font)
	end
	self:Register(bar)
	lastCreated = lastCreated + 1

	return bar
end

function SageBar:Register(bar)
	if(not self.bars) then self.bars = {} end
	self.bars[bar] = true
end

function SageBar:UpdateTexture()
	local texture = Sage:GetBarTexture()
	self:SetStatusBarTexture(texture)
	self.bg:SetTexture(texture)
end

function SageBar:UpdateAllTextures()
	if(self.bars) then
		for bar in pairs(self.bars) do
			bar:UpdateTexture()
		end
	end
end

function SageBar:SetTextMode(unit, mode)
	if(self.bars) then
		for bar in pairs(self.bars) do
			if(not unit or bar.id == unit) then
				if(bar.UpdateText) then
					bar.mode = mode
					bar:UpdateText()
				end
			end
		end
	end
end

function SageBar:UpdateText(unit, entered)
	if(self.bars) then
		for bar in pairs(self.bars) do
			if(not unit or bar.id == unit) then
				if(bar.UpdateText) then
					bar.entered = entered
					bar:UpdateText()
				end
			end
		end
	end
end

function SageBar:UpdateAll()
	if(self.bars) then
		for bar in pairs(self.bars) do
			if(bar.UpdateText) then
				bar:UpdateText()
			end
		end
	end
end