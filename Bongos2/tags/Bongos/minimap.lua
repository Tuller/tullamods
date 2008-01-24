--[[
	Bongos' minimap button
--]]

BongosMinimap = {}

function BongosMinimap.OnEnter(self)
	GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
	GameTooltip:SetText('Bongos!', 1, 1, 1)
	
	if not(BongosOptions and BongosOptions:IsShown()) then
		GameTooltip:AddLine('<Left Click> to show the options menu')
	else
		GameTooltip:AddLine('<Left Click> to hide the options menu')
	end
	
	if Bongos.IsLocked() then
		GameTooltip:AddLine(BONGOS_UNLOCK_BARS)
	else
		GameTooltip:AddLine(BONGOS_LOCK_BARS)
	end
	
	if IsAddOnLoaded('Bongos_ActionBar') then
		if BActionConfig.ButtonsLocked() then
			GameTooltip:AddLine(BONGOS_UNLOCK_BUTTONS)
		else
			GameTooltip:AddLine(BONGOS_LOCK_BUTTONS)
		end
	end

	GameTooltip:Show()
end

--taken from trinity, since I'm terrible at math
function BongosMinimap.OnUpdate(self)
	local pos;
	local xpos,ypos = GetCursorPosition();
	local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom();

	xpos = xmin-xpos/Minimap:GetEffectiveScale()+70;
	ypos = ypos/Minimap:GetEffectiveScale()-ymin-70;

	pos = math.deg(math.atan2(ypos,xpos));	

	xpos = 80*cos(pos);
	ypos = 80*sin(pos);	

	self:SetPoint('TOPLEFT', 'Minimap', 'TOPLEFT', 52-xpos, ypos-55)

	local sets = Bongos.GetSettings()		
	sets.mapx = 52 - xpos
	sets.mapy = ypos - 55
end

function BongosMinimap.OnClick(mouseButton)
	if mouseButton == 'RightButton' then
		if IsAddOnLoaded('Bongos_ActionBar') and IsShiftKeyDown() then
			BActionConfig.SetButtonsLocked(not BActionConfig.ButtonsLocked())
		else
			Bongos.ToggleLock()
		end
	elseif mouseButton == 'LeftButton' then
		if BongosOptions then
			if BongosOptions:IsVisible() then
				BongosOptions:Hide()
			else
				BongosOptions:Show()
			end
		else
			LoadAddOn('Bongos_Options')
		end
	end
end

Bongos.AddStartup(function() 
	local sets = Bongos.GetSettings()		
	BongosMinimapFrame:ClearAllPoints()
	BongosMinimapFrame:SetPoint('TOPLEFT', 'Minimap', 'TOPLEFT', sets.mapx, sets.mapy)
	
	if not Bongos.ShowMinimap() then
		BongosMinimapFrame:Hide()
	end
end)