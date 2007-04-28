--[[
	dragFrame.lua
--]]

local L = BONGOS_LOCALS

--[[ Tooltips ]]--

local function DragFrame_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")

	if tonumber(self:GetText()) then
		GameTooltip:SetText(format("action bar %s", self:GetText()), 1, 1, 1)
	else
		GameTooltip:SetText(format("bar %s", self:GetText()), 1, 1, 1)
	end

	if self.parent.ShowMenu then
		GameTooltip:AddLine(L.ShowConfig)
	end

	if self.parent:IsShown() then
		GameTooltip:AddLine(L.HideBar)
	else
		GameTooltip:AddLine(L.ShowBar)
	end
	GameTooltip:AddLine(format(L.SetAlpha, self.parent:GetAlpha()))

	GameTooltip:Show()
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

local function DragFrame_OnClick(self, arg1)
	if arg1 == 'RightButton' then
		if IsShiftKeyDown() then
			self.parent:ToggleFrame()
		elseif this.parent.ShowMenu then
			self.parent:ShowMenu()
		end
	elseif arg1 == 'MiddleButton' then
		self.parent:ToggleFrame()
	end
	DragFrame_OnEnter(self)
end

--updates the drag button color of a given bar if its attached to another bar
local function DragFrame_UpdateColor(self)
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

--[[ Constructor ]]--

function BDragFrame_New(parent)
	local frame = CreateFrame('Button', nil, UIParent)
	frame.parent = parent
	frame.UpdateColor = DragFrame_UpdateColor

	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata('DIALOG')
	frame:SetAllPoints(parent)

	local bg = frame:CreateTexture(nil, 'BACKGROUND')
	bg:SetTexture('Interface\\Tooltips\\UI-Tooltip-Background')

	local g = random(0, 1)
	local b = random(0, 2 - g)
	local r = random(0, 3 - (g+b))
	bg:SetVertexColor(r, g, b, 0.5)
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
	frame:SetScript('OnClick', DragFrame_OnClick)
	frame:SetScript('OnEnter', DragFrame_OnEnter)
	frame:SetScript('OnLeave', DragFrame_OnLeave)
	frame:Hide()

	return frame
end