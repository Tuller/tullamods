--[[
	The Drag Frame
--]]

local Drag = Sage:CreateClass('Button')
Sage.DragFrame = Drag

local L = LibStub('AceLocale-3.0'):GetLocale('Sage')
local frames = {}


function Drag:New(owner)
	local f = self:Bind(CreateFrame('Button', nil, UIParent))
	f.owner = owner

	f:EnableMouseWheel(true)
	f:SetClampedToScreen(true)
	f:SetFrameStrata(owner:GetFrameStrata())
	f:SetAllPoints(owner)
	f:SetFrameLevel(owner:GetFrameLevel() + 5)

	local bg = f:CreateTexture(nil, 'BACKGROUND')
	bg:SetTexture(1, 1, 1, 0.4)
	bg:SetAllPoints(f)
	f:SetNormalTexture(bg)

	local t = f:CreateTexture(nil, 'BACKGROUND')
	t:SetTexture(0.2, 0.3, 0.4, 0.5)
	t:SetAllPoints(f)
	f:SetHighlightTexture(t)

	f:SetNormalFontObject('GameFontNormalLarge')
	f:SetText(owner.id)

	f:RegisterForClicks('AnyUp')
	f:RegisterForDrag('LeftButton')
	f:SetScript('OnMouseDown', self.StartMoving)
	f:SetScript('OnMouseUp', self.StopMoving)
	f:SetScript('OnMouseWheel', self.OnMouseWheel)
	f:SetScript('OnEnter', self.OnEnter)
	f:SetScript('OnLeave', self.OnLeave)
	f:UpdateVisibility()

	table.insert(frames, f)
	return f
end


function Drag:OnEnter()
	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMLEFT')
	GameTooltip:SetText(format('%s Frame', self:GetText():gsub('^%l', string.upper)), 1, 1, 1)
	GameTooltip:AddLine(format(L.SetAlpha, ceil(self.owner:GetFrameAlpha()*100)))
	GameTooltip:Show()
end

function Drag:OnLeave()
	GameTooltip:Hide()
end

function Drag:StartMoving(button)
	if button == 'LeftButton' then
		self.isMoving = true
		self.owner:StartMoving()

		if GameTooltip:IsOwned(self) then
			GameTooltip:Hide()
		end
	end
end

function Drag:StopMoving()
	if self.isMoving then
		self.isMoving = nil
		self.owner:StopMovingOrSizing()
		self.owner:Stick()
		self:OnEnter()
	end
end

function Drag:OnMouseWheel(arg1)
	local newAlpha = min(max(self.owner:GetAlpha() + (arg1 * 0.1), 0), 1)
	self.owner.sets.alpha = newAlpha	
end

--updates the drag button color of a given bar if its attached to another bar
function Drag:UpdateColor()
	if self.owner:GetAnchor() then
		self:GetNormalTexture():SetTexture(0, 0.2, 0.3, 0.4)
	else
		self:GetNormalTexture():SetTexture(0, 0.8, 0.4, 0.4)
	end
end

function Drag:UpdateVisibility()
	if Sage:Locked() then
		self:Hide()
	else
		self:Show()
	end
end

function Drag:ForAll(method, ...)
	for _,f in pairs(frames) do
		f[method](f, ...)
	end
end

function Drag:anchor_Change(newAnchor)
	self:UpdateColor()
end

function Drag:scale_Change(newScale)
	self:SetScale(newScale)
end

function Drag:alpha_Change(newAlpha)
	if GameTooltip:IsOwned(self) then
		self:OnEnter()
	end
end