--[[
	dragFrame.lua
--]]

local L = SAGE_LOCALS

--[[ Tooltips ]]--

local function DragFrame_OnEnter(self)
	if(not self.scaling) then
		GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMLEFT')
		GameTooltip:SetText(format('%s frame', self:GetText()), 1, 1, 1)
		GameTooltip:AddLine(format(L.SetAlpha, self.parent:GetAlpha()))
		GameTooltip:Show()
	end
end

local function DragFrame_OnLeave(self)
	GameTooltip:Hide()
end


--[[ Movement Functions ]]--

local function DragFrame_OnMouseDown(self, arg1)
	if arg1 == 'LeftButton' then
		self.isMoving = true
		self.parent:StartMoving()
	end
end

local function DragFrame_OnMouseUp(self, arg1)
	if self.isMoving then
		self.isMoving = nil
		self.parent:StopMovingOrSizing()
		self.parent:Stick()
	end
end

local function DragFrame_OnMouseWheel(self, arg1)
	local newAlpha = min(max(self.parent:GetAlpha() + (arg1 * 0.1), 0), 1)
	if newAlpha ~= self.parent:GetAlpha() then
		self.parent:SetFrameAlpha(newAlpha)
		DragFrame_OnEnter(self)
	end
end

--updates the drag button color of a given bar if its attached to another bar
local function DragFrame_UpdateColor(self)
	if self.parent:GetAnchor() then
		self:SetTextColor(0, 0.82*0.8, 1*0.8)
	else
		self:SetTextColor(1, 0.82, 0)
	end
	self.highlight:SetTexture(0, 0, 0.6, 0.5)
end

local function Scale_OnEnter(self)
	self:GetNormalTexture():SetVertexColor(1, 1, 1)
end

local function Scale_OnLeave(self)
	self:GetNormalTexture():SetVertexColor(1, 0.82, 0)
end

--credit goes to AnduinLothar for this code, I've only modified it to work with Bongos/Sage
local function Scale_OnUpdate(self, elapsed)
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

local function Scale_StartScaling(self)
	self:GetParent():LockHighlight()
	self:GetParent().scaling = true
	self:SetScript('OnUpdate', Scale_OnUpdate)
end

local function Scale_StopScaling(self)
	self:GetParent():UnlockHighlight()
	self:GetParent().scaling = nil
	self:SetScript('OnUpdate', nil)
end

--[[ Constructor ]]--

function SDragFrame_New(parent)
	local frame = CreateFrame('Button', nil, UIParent)
	frame.parent = parent
	frame.UpdateColor = DragFrame_UpdateColor

	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata(parent:GetFrameStrata())
	frame:SetAllPoints(parent)
	frame:SetFrameLevel(parent:GetFrameLevel() + 10)

	local bg = frame:CreateTexture(nil, 'BACKGROUND')
	bg:SetTexture('Interface\\Tooltips\\UI-Tooltip-Background')
	bg:SetTexture(0, 0.2, 0, 0.5)
	bg:SetAllPoints(frame)
	frame:SetNormalTexture(bg)

	local highlight = frame:CreateTexture(nil, 'BACKGROUND')
	highlight:SetTexture(0, 0, 0.6, 0.5)
	highlight:SetAllPoints(frame)
	frame:SetHighlightTexture(highlight)
	frame.highlight = highlight

	frame:SetTextFontObject(GameFontNormalLarge)
	frame:SetHighlightTextColor(1, 1, 1)
	frame:SetText(parent.id)

	frame:RegisterForClicks('AnyUp')
	frame:RegisterForDrag('LeftButton', 'RightButton')
	frame:EnableMouseWheel(true)
	frame:SetScript('OnMouseDown', DragFrame_OnMouseDown)
	frame:SetScript('OnMouseUp', DragFrame_OnMouseUp)
	frame:SetScript('OnMouseWheel', DragFrame_OnMouseWheel)
	frame:SetScript('OnEnter', DragFrame_OnEnter)
	frame:SetScript('OnLeave', DragFrame_OnLeave)
	frame:Hide()

	local scale = CreateFrame('Button', nil, frame)
	scale:SetPoint('BOTTOMRIGHT', frame)
	scale:SetHeight(16); scale:SetWidth(16)

	scale:SetNormalTexture('Interface\\AddOns\\Sage\\textures\\Rescale')
	scale:GetNormalTexture():SetVertexColor(1, 0.82, 0)

	scale:SetScript('OnEnter', Scale_OnEnter)
	scale:SetScript('OnLeave', Scale_OnLeave)
	scale:SetScript('OnMouseDown', Scale_StartScaling)
	scale:SetScript('OnMouseUp', Scale_StopScaling)
	scale.parent = frame.parent

	return frame
end