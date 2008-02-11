--[[
	dragFrame.lua
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3')


--[[
	The Scale Gripper
--]]

local Scaler = Bongos:CreateWidgetClass('Button')

function Scaler:Create(parent)
	local f = self:New(CreateFrame('Button', nil, parent))
	f:SetFrameLevel(parent:GetFrameLevel() + 1)
	f:SetPoint('BOTTOMRIGHT', parent)
	f:SetHeight(16)
	f:SetWidth(16)

	f:SetNormalTexture('Interface\\AddOns\\Bongos\\textures\\Rescale')
	f:GetNormalTexture():SetVertexColor(1, 0.82, 0)

	f:SetScript('OnEnter', self.OnEnter)
	f:SetScript('OnLeave', self.OnLeave)
	f:SetScript('OnMouseDown', self.StartScaling)
	f:SetScript('OnMouseUp', self.StopScaling)
	f.parent = parent.parent

	return f
end

--credit goes to AnduinLothar for this code, I've only modified it to work with Bongos/Sage
function Scaler:OnUpdate(elapsed)
	local frame = self.parent
	local x, y = GetCursorPosition()
	local currScale = frame:GetEffectiveScale()
	x = x / currScale
	y = y / currScale

	local left, top = frame:GetLeft(), frame:GetTop()
	local wScale = (x-left)/frame:GetWidth()
	local hScale = (top-y)/frame:GetHeight()

	local scale = max(min(max(wScale, hScale), 1.2), 0.8)
	local newScale = min(max(frame:GetScale() * scale, 0.5), 1.5)
	frame:SetFrameScale(newScale, IsShiftKeyDown())
end

function Scaler:StartScaling()
	self.isScaling = true
	self:GetParent():LockHighlight()
	self:SetScript('OnUpdate', self.OnUpdate)
end

function Scaler:StopScaling()
	self.isScaling = nil
	self:GetParent():UnlockHighlight()
	self:SetScript('OnUpdate', nil)
end

function Scaler:OnEnter()
	self:GetNormalTexture():SetVertexColor(1, 1, 1)
end

function Scaler:OnLeave()
	self:GetNormalTexture():SetVertexColor(1, 0.82, 0)
end


--[[
	The Drag Frame
--]]

Bongos.Drag = Bongos:CreateWidgetClass('Button')
local Drag = Bongos.Drag

function Drag:Create(parent)
	local f = self:New(CreateFrame('Button', nil, UIParent))
	f.parent = parent

	f:SetClampedToScreen(true)
	f:SetFrameStrata(parent:GetFrameStrata())
	f:SetAllPoints(parent)
	f:SetFrameLevel(6)

	local bg = f:CreateTexture(nil, 'BACKGROUND')
	bg:SetTexture('Interface/Tooltips/UI-Tooltip-Background')
	bg:SetVertexColor(1, 1, 1, 0.4)
	bg:SetAllPoints(f)
	f:SetNormalTexture(bg)

	local highlight = f:CreateTexture(nil, 'BACKGROUND')
	highlight:SetTexture(0, 0, 0.6, 0.5)
	highlight:SetAllPoints(f)
	f:SetHighlightTexture(highlight)
	f.highlight = highlight

	f:SetTextFontObject(GameFontNormalLarge)
	f:SetHighlightTextColor(1, 1, 1)
	f:SetText(parent.id)

	f:RegisterForClicks('AnyUp')
	f:EnableMouseWheel(true)
	f:SetScript('OnMouseDown', self.OnMouseDown)
	f:SetScript('OnMouseUp', self.OnMouseUp)
	f:SetScript('OnMouseWheel', self.OnMouseWheel)
	f:SetScript('OnClick', self.OnClick)
	f:SetScript('OnEnter', self.OnEnter)
	f:SetScript('OnLeave', self.OnLeave)
	f:Hide()

	f.scaler = Scaler:Create(f, parent)

	return f
end

function Drag:OnEnter()
	if not self.scaler.isScaling then
		GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMLEFT')

		if tonumber(self:GetText()) then
			GameTooltip:SetText(format('ActionBar %s', self:GetText()), 1, 1, 1)
		else
			GameTooltip:SetText(format('%s Bar', self.parent.id:gsub('^%l', string.upper)), 1, 1, 1)
		end

		if self.parent.ShowMenu then
			GameTooltip:AddLine(L.ShowConfig)
		end

		if self.parent:IsShown() then
			GameTooltip:AddLine(L.HideBar)
		else
			GameTooltip:AddLine(L.ShowBar)
		end
		GameTooltip:AddLine(format(L.SetAlpha, ceil(self.parent:GetFrameAlpha()*100)))

		GameTooltip:Show()
	end
end

function Drag:OnLeave()
	GameTooltip:Hide()
end

function Drag:OnMouseDown(button)
	if arg1 == 'LeftButton' then
		self.isMoving = true
		self.parent:StartMoving()

		if GameTooltip:IsOwned(self) then
			GameTooltip:Hide()
		end
	end
end

function Drag:OnMouseUp(button)
	if self.isMoving then
		self.isMoving = nil
		self.parent:StopMovingOrSizing()
		self.parent:Stick()
		self:OnEnter()
	end
end

function Drag:OnMouseWheel(arg1)
	local newAlpha = min(max(self.parent:GetAlpha() + (arg1 * 0.1), 0), 1)
	if newAlpha ~= self.parent:GetAlpha() then
		self.parent:SetFrameAlpha(newAlpha)
		self:OnEnter()
	end
end

function Drag:OnClick(button)
	if button == 'RightButton' then
		if IsShiftKeyDown() then
			self.parent:ToggleFrame()
		elseif IsAltKeyDown() then
			self.parent:Destroy(true)
			return
		elseif self.parent.ShowMenu then
			self.parent:ShowMenu()
		end
	elseif button == 'MiddleButton' then
		self.parent:ToggleFrame()
	end
	self:OnEnter()
end

--updates the drag button color of a given bar if its attached to another bar
function Drag:UpdateColor()
	if not self.parent:IsShown() then
		if self.parent:GetAnchor() then
			self:SetTextColor(0.4, 0.4, 0.4)
		else
			self:SetTextColor(0.8, 0.8, 0.8)
		end
		self.highlight:SetTexture(0.2, 0.3, 0.4, 0.5)
	else
		if self.parent:GetAnchor() then
			self:SetTextColor(0.1, 0.5, 0.1)
		else
			self:SetTextColor(0.2, 1, 0.2)
		end
		self.highlight:SetTexture(0, 0, 0.6, 0.5)
	end
end