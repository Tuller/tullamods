--[[ 
	dragFrame.lua
		A bongos drag frame
--]]


--[[ Movement Functions ]]--

local function DragFrame_OnMouseDown()
	this.parent:StartMoving()
end

local function DragFrame_OnMouseUp()
	this.parent:StopMovingOrSizing()
	this.parent:Stick()
end

--[[ Constructor ]]--

function SDragFrame_Add(parent)
	local frame = CreateFrame('Button', nil, UIParent)
	frame.parent = parent
	
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata('DIALOG')
	frame:SetAllPoints(parent)
	
	local bg = frame:CreateTexture(nil, 'BACKGROUND')
	bg:SetTexture('Interface\\Tooltips\\UI-Tooltip-Background')
	bg:SetVertexColor(0, 0, 0, 0.5)
	bg:SetAllPoints(frame)
	frame:SetNormalTexture(bg)
	
	local highlight = frame:CreateTexture(nil, 'BACKGROUND')
	highlight:SetTexture(0.0, 0.6, 0.0, 0.5)
	highlight:SetAllPoints(frame)
	frame:SetHighlightTexture(highlight)
	
	--text
	frame:SetTextFontObject(GameFontNormalLarge)
	frame:SetHighlightTextColor(1, 1, 1)
	frame:SetText(parent.id)

	frame:RegisterForClicks('anyUp')
	frame:RegisterForDrag('LeftButton', 'RightButton')
	frame:SetScript('OnMouseDown', DragFrame_OnMouseDown)
	frame:SetScript('OnMouseUp', DragFrame_OnMouseUp)
	frame:Hide()
	
	parent.dragFrame = frame
end

--updates the drag button color of a given bar if its attached to another bar
function SDragFrame_UpdateSticky(frame)
	if frame.parent:GetAnchor() then
		frame:SetTextColor(0.5, 0.5, 1)
	else
		frame:SetTextColor(1, 0.82, 0)
	end
end