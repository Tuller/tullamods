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
		bar.text = bar:CreateFontString(name .. "text", "OVERLAY")
		bar.text:SetPoint("CENTER", bar)
		bar.text:SetFontObject(font)

		if(alwaysShow or Sage:ShowingText()) then bar.text:Show() else bar.text:Hide() end
	end
	self:Register(bar)
	lastCreated = lastCreated + 1

	return bar
end

function SageBar:Register(bar)
	if(not self.bars) then self.bars = {} end
	self.bars[bar] = true
end

function SageBar:ShowText(enable)
	if(self.text) then
		if(enable) then
			self.text:Show()
			self:UpdateText()
		else
			self.text:Hide()
		end
	end
end

function SageBar:SetText(value, max, mode)
	local text = self.text
	--current / max
	if not mode or mode == 1 then
		text:SetText(format("%d / %d", value, max))
	--current
	elseif mode == 2 then
		text:SetText(value)
	--deficit / max
	elseif mode == 3 then
		text:SetText(format("-%d / %d", max - value, max))
	--deficit / current
	elseif mode == 4 then
		text:SetText(format("-%d / %d", max - value, value))
	--deficit
	elseif mode == 5 then
		text:SetText(format("-%d", max - value))
	end
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

function SageBar:UpdateAllText(unit, show)
	if(self.bars) then
		for bar in pairs(self.bars) do
			if(not unit or bar.id == unit) then
				if(bar.ShowText) then
					bar:ShowText(show)
				end
			end
		end
	end
end