--[[
	dragFrame.lua
--]]

local L = SAGE_LOCALS

--[[ Tooltips ]]--

local function DragFrame_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
	GameTooltip:SetText(format("%s frame", self:GetText()), 1, 1, 1)
	GameTooltip:AddLine(format(L.SetAlpha, self.parent:GetAlpha()))
	GameTooltip:Show()
end

local function DragFrame_OnLeave(self)
	GameTooltip:Hide()
end


--[[ Movement Functions ]]--

local function DragFrame_OnMouseDown(self, arg1)
	if arg1 == "LeftButton" then
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
		self:SetTextColor(0.1, 0.5, 0.1)
	else
		self:SetTextColor(0.2, 1, 0.2)
	end
	self.highlight:SetTexture(0, 0, 0.6, 0.5)
end


--[[ Constructor ]]--

function SDragFrame_New(parent)
	local frame = CreateFrame("Button", nil, UIParent)
	frame.parent = parent
	frame.UpdateColor = DragFrame_UpdateColor

	frame:SetClampedToScreen(true)
	frame:SetFrameStrata(parent:GetFrameStrata())
	frame:SetAllPoints(parent)
	frame:SetFrameLevel(6)

	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")

	bg:SetVertexColor(0, 0.2, 0, 0.5)
	bg:SetAllPoints(frame)
	frame:SetNormalTexture(bg)

	local highlight = frame:CreateTexture(nil, "BACKGROUND")
	highlight:SetTexture(0, 0, 0.6, 0.5)
	highlight:SetAllPoints(frame)
	frame:SetHighlightTexture(highlight)
	frame.highlight = highlight

	frame:SetTextFontObject(GameFontNormalLarge)
	frame:SetHighlightTextColor(1, 1, 1)
	frame:SetText(parent.id)

	frame:RegisterForClicks("AnyUp")
	frame:RegisterForDrag("LeftButton", "RightButton")
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseDown", DragFrame_OnMouseDown)
	frame:SetScript("OnMouseUp", DragFrame_OnMouseUp)
	frame:SetScript("OnMouseWheel", DragFrame_OnMouseWheel)
	frame:SetScript("OnEnter", DragFrame_OnEnter)
	frame:SetScript("OnLeave", DragFrame_OnLeave)
	frame:Hide()

	return frame
end