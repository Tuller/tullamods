--[[
	Bongos Minimap Button
		Based on the fubar and item rack minimap buttons
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3')

Bongos.Minimap = CreateFrame('Button', 'Bongos3MinimapButton', Minimap)
local MinimapButton = Bongos.Minimap

function MinimapButton:Load()
	self:SetFrameStrata('MEDIUM')
	self:SetWidth(31); self:SetHeight(31)
	self:SetFrameLevel(8)
	self:RegisterForClicks('anyUp')
	self:RegisterForDrag('LeftButton')
	self:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')

	local overlay = self:CreateTexture(nil, 'OVERLAY')
	overlay:SetWidth(53); overlay:SetHeight(53)
	overlay:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')
	overlay:SetPoint('TOPLEFT')

	local icon = self:CreateTexture(nil, 'BACKGROUND')
	icon:SetWidth(20); icon:SetHeight(20)
	icon:SetTexture('Interface\\Icons\\INV_Misc_Drum_04')
	icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	icon:SetPoint('TOPLEFT', 7, -5)
	self.icon = icon

	self:SetScript('OnEnter', self.OnEnter)
	self:SetScript('OnLeave', self.OnLeave)
	self:SetScript('OnClick', self.OnClick)
	self:SetScript('OnDragStart', self.OnDragStart)
	self:SetScript('OnDragStop', self.OnDragStop)
	self:SetScript('OnMouseDown', self.OnMouseDown)
	self:SetScript('OnMouseUp', self.OnMouseUp)
end

function MinimapButton:OnClick(button)
	if button == 'LeftButton' then		
		if KeyBound and IsShiftKeyDown() then
			Bongos:SetLock(true)
			KeyBound:Toggle()
		else
			if KeyBound then
				KeyBound:Deactivate()
			end
			Bongos:SetLock(not Bongos:IsLocked())
		end
	elseif button == 'RightButton' then
		LoadAddOn('Bongos_Options')
		InterfaceOptionsFrame_OpenToFrame('Bongos')
	end
	self:OnEnter()
end

function MinimapButton:OnMouseDown()
	self.icon:SetTexCoord(0, 1, 0, 1)
end

function MinimapButton:OnMouseUp()
	self.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
end

function MinimapButton:OnEnter()
	if not self.dragging then
		GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
		GameTooltip:SetText('Bongos3', 1, 1, 1)

		if Bongos:IsLocked() then
			GameTooltip:AddLine(L.UnlockBarsTip)
		else
			GameTooltip:AddLine(L.LockBarsTip)
		end
		
		if KeyBound then
			if KeyBound:IsShown() then
				GameTooltip:AddLine('<Right Click> to exit keybinding mode')
			else
				GameTooltip:AddLine('<Right Click> to enter keybinding mode')
			end
		end
		GameTooltip:Show()
	end
end

function MinimapButton:OnLeave()
	GameTooltip:Hide()
end

function MinimapButton:OnDragStart()
	self.dragging = true
	self:LockHighlight()
	self.icon:SetTexCoord(0, 1, 0, 1)
	self:SetScript('OnUpdate', self.OnUpdate)
	GameTooltip:Hide()
end

function MinimapButton:OnDragStop()
	self.dragging = nil
	self:SetScript('OnUpdate', nil)
	self.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	self:UnlockHighlight()
end

function MinimapButton:OnUpdate()
	local mx, my = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()

	px, py = px / scale, py / scale

	Bongos:SetMinimapButtonPosition(math.deg(math.atan2(py - my, px - mx)) % 360)
	self:UpdatePosition()
end

--magic fubar code for updating the minimap button's position
--I suck at trig, so I'm not going to bother figuring it out
function MinimapButton:UpdatePosition()
	local angle = math.rad(Bongos:GetMinimapButtonPosition() or random(0, 360))
	local cos = math.cos(angle)
	local sin = math.sin(angle)
	local minimapShape = GetMinimapShape and GetMinimapShape() or 'ROUND'

	local round = false
	if minimapShape == 'ROUND' then
		round = true
	elseif minimapShape == 'SQUARE' then
		round = false
	elseif minimapShape == 'CORNER-TOPRIGHT' then
		round = not(cos < 0 or sin < 0)
	elseif minimapShape == 'CORNER-TOPLEFT' then
		round = not(cos > 0 or sin < 0)
	elseif minimapShape == 'CORNER-BOTTOMRIGHT' then
		round = not(cos < 0 or sin > 0)
	elseif minimapShape == 'CORNER-BOTTOMLEFT' then
		round = not(cos > 0 or sin > 0)
	elseif minimapShape == 'SIDE-LEFT' then
		round = cos <= 0
	elseif minimapShape == 'SIDE-RIGHT' then
		round = cos >= 0
	elseif minimapShape == 'SIDE-TOP' then
		round = sin <= 0
	elseif minimapShape == 'SIDE-BOTTOM' then
		round = sin >= 0
	elseif minimapShape == 'TRICORNER-TOPRIGHT' then
		round = not(cos < 0 and sin > 0)
	elseif minimapShape == 'TRICORNER-TOPLEFT' then
		round = not(cos > 0 and sin > 0)
	elseif minimapShape == 'TRICORNER-BOTTOMRIGHT' then
		round = not(cos < 0 and sin < 0)
	elseif minimapShape == 'TRICORNER-BOTTOMLEFT' then
		round = not(cos > 0 and sin < 0)
	end

	local x, y
	if round then
		x = cos*80
		y = sin*80
	else
		x = math.max(-82, math.min(110*cos, 84))
		y = math.max(-86, math.min(110*sin, 82))
	end

	self:SetPoint('CENTER', x, y)
end

MinimapButton:Load()