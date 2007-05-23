--[[
	Bongos" minimap button
--]]

local L = BONGOS_LOCALS

BongosMinimap = {}

function BongosMinimap:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
	GameTooltip:SetText("Bongos2", 1, 1, 1)
	
	if not(BongosOptions and BongosOptions:IsShown()) then
		GameTooltip:AddLine(L.ShowMenuTip)
	else
		GameTooltip:AddLine(L.HideMenuTip)
	end
	
	if Bongos:IsLocked() then
		GameTooltip:AddLine(L.UnlockBarsTip)
	else
		GameTooltip:AddLine(L.LockBarsTip)
	end
	
	if IsAddOnLoaded("Bongos2_ActionBar") then
		if BongosActionConfig:ButtonsLocked() then
			GameTooltip:AddLine(L.UnlockButtonsTip)
		else
			GameTooltip:AddLine(L.LockButtonsTip)
		end
	end

	GameTooltip:Show()
end

--taken from trinity, since I"m terrible at math
function BongosMinimap:OnUpdate(elapsed)
	local pos;
	local xpos,ypos = GetCursorPosition()
	local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom()

	xpos = xmin - xpos / Minimap:GetEffectiveScale() + 70
	ypos = ypos / Minimap:GetEffectiveScale() - ymin - 70

	pos = deg(atan2(ypos, xpos))

	xpos = 80 * cos(pos)
	ypos = 80 * sin(pos);

	self:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 52 - xpos, ypos - 55)

	Bongos:SetMapCoords(52 - xpos, ypos - 55)
end

function BongosMinimap:OnClick(button)
	if button == "LeftButton" then
		if IsAddOnLoaded("Bongos2_ActionBar") and IsShiftKeyDown() then
			BongosActionConfig:LockButtons(not BongosActionConfig:ButtonsLocked())
		else
			Bongos:SetLock(not Bongos:IsLocked())
		end
	elseif button == "RightButton" then
		if BongosOptions then
			if BongosOptions:IsShown() then
				BongosOptions:Hide()
			else
				BongosOptions:Show()
			end
		else
			LoadAddOn("Bongos2_Options")
		end
	end
end