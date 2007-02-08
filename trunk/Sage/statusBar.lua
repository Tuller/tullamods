--[[
	SageStatusBar.lua
		Shared statusbar functions
--]]

SageStatusBar = {}

function SageStatusBar.SetText(text, value, max, mode)
	if text:IsShown() then
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
end

function SageStatusBar:UpdateTexture()
	SageStatusBar.SetTexture(self, Sage.GetBarTexture()) 
end

function SageStatusBar.SetTexture(bar, texture)
	bar:SetStatusBarTexture(texture)
	bar.bg:SetTexture(texture)
end

function SageStatusBar.UpdateAllTextures()
	SageHealth.ForAll(SageHealth.UpdateTexture)
	SageMana.ForAll(SageMana.UpdateTexture)
end

function SageStatusBar.UpdateAllText(enable)
	SageHealth.ForAll(SageHealth.ShowText, enable)
	SageMana.ForAll(SageMana.ShowText, enable)
end
