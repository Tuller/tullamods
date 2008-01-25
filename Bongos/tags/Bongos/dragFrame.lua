--[[ 
	dragFrame.lua
--]]

--[[ Tooltips ]]--

local function DragFrame_OnEnter()
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")

	if tonumber(this:GetText()) then
		GameTooltip:SetText("action bar " .. this:GetText(), 1, 1, 1)
	else
		GameTooltip:SetText(this:GetText() .. " bar", 1, 1, 1)
	end

	if this.parent.ShowMenu then
		GameTooltip:AddLine(BONGOS_SHOW_CONFIG)
	end

	if this.parent:IsShown() then
		GameTooltip:AddLine(BONGOS_HIDE_BAR)
	else
		GameTooltip:AddLine(BONGOS_SHOW_BAR)
	end

	GameTooltip:Show()
end

local function DragFrame_OnLeave()
	GameTooltip:Hide()
end


--[[ Movement Functions ]]--

local function DragFrame_OnMouseDown()
	if arg1 == 'LeftButton' then
		this.isMoving = true
		this.parent:StartMoving()
	end
end

local function DragFrame_OnMouseUp()
	if this.isMoving then
		this.isMoving = nil
		this.parent:StopMovingOrSizing()
		this.parent:Stick()
	end
end

local function DragFrame_OnClick()
	if arg1 == 'RightButton' then
		if IsShiftKeyDown() then
			this.parent:ToggleFrame()
		elseif this.parent.ShowMenu then
			this.parent:ShowMenu()
		end
	elseif arg1 == 'MiddleButton' then
		this.parent:ToggleFrame()
	end
	DragFrame_OnEnter()
end


--updates the drag button color of a given bar if its attached to another bar
local function UpdateColor(self)
	if not self.parent:IsShown() then
		if self.parent:GetAnchor() then
			self:SetTextColor(0.4, 0.4, 0.4)
		else
			self:SetTextColor(0.8, 0.8, 0.8)
		end
	else
		if self.parent:GetAnchor() then
			self:SetTextColor(0.1, 0.5, 0.1)
		else
			self:SetTextColor(0.2, 1, 0.2)
		end
	end
end

--[[ Constructor ]]--

function BDragFrame_Add(parent)
	local frame = CreateFrame('Button', nil, UIParent)
	frame.parent = parent
	frame.UpdateColor = UpdateColor
	
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata('DIALOG')
	frame:SetAllPoints(parent)
	
	local bg = frame:CreateTexture(nil, 'BACKGROUND')
	bg:SetTexture('Interface\\Tooltips\\UI-Tooltip-Background')
	bg:SetVertexColor(0, 0, 0, 0.5)
	bg:SetAllPoints(frame)
	frame:SetNormalTexture(bg)
	
	local highlight = frame:CreateTexture(nil, 'BACKGROUND')
	highlight:SetTexture(0, 0, 0.6, 0.5)
	highlight:SetAllPoints(frame)
	frame:SetHighlightTexture(highlight)

	frame:SetTextFontObject(GameFontNormalLarge)
	frame:SetHighlightTextColor(1, 1, 1)
	frame:SetText(parent.id)

	frame:RegisterForClicks('anyUp')
	frame:RegisterForDrag('LeftButton', 'RightButton')
	frame:SetScript('OnMouseDown', DragFrame_OnMouseDown)
	frame:SetScript('OnMouseUp', DragFrame_OnMouseUp)
	frame:SetScript('OnClick', DragFrame_OnClick)
	frame:SetScript('OnEnter', DragFrame_OnEnter)
	frame:SetScript('OnLeave', DragFrame_OnLeave)
	frame:Hide()
	
	return frame
end