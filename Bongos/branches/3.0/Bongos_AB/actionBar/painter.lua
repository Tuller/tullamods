--[[
	Painter.lua
		ActionBar creation via click and drag
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local Action = Bongos:GetModule('ActionBar')

local Painter = CreateFrame('Frame')
Action.Painter = Painter

function Painter:Load()
	self:SetParent(Bongos.lockBG)
	self:SetFrameStrata('BACKGROUND')
	self:SetFrameLevel(0)
	self:SetAllPoints(self:GetParent())
	self:RegisterForDrag('LeftButton')

	self:SetScript('OnMouseDown', self.SetStartPoint)
	self:SetScript('OnDragStart', self.ShowDragBox)
	self:SetScript('OnDragStop', self.CreateBar)
	self:SetScript('OnUpdate', self.OnUpdate)
	self.nextUpdate = 0

	self.loaded = true
end

function Painter:OnUpdate(elapsed)
	if self.nextUpdate < 0 then
		self.nextUpdate = 0.05
		self:EnableMouse(IsAltKeyDown())
	else
		self.nextUpdate = self.nextUpdate - elapsed
	end
end

--set our starting point to the cursor
function Painter:SetStartPoint()
	local x, y = GetCursorPosition()
	local s = UIParent:GetScale()
	x = x/s; y = y/s

	self.startX = (x > GetScreenWidth()/2) and 'RIGHT' or 'LEFT'
	self.startY = (y > GetScreenHeight()/2) and 'TOP' or 'BOTTOM'
	self.x = x; self.y = y
end

function Painter:ShowDragBox()
	--create the selection box, if we've not already
	if not self.box then
		self.box = CreateFrame('Frame', nil, self)
		self.box.bg = self.box:CreateTexture()
		self.box.bg:SetAllPoints(self.box)

		local text = self.box:CreateFontString()
		text:SetPoint('CENTER')
		text:SetFontObject('GameFontNormal')
		self.box.text = text
	end

	--place the box at the starting point
	self.box:ClearAllPoints()
	self.box:SetPoint(self.startY .. self.startX, UIParent, 'BOTTOMLEFT', self.x, self.y)
	self.box:Show()

	self:SetScript('OnUpdate', self.UpdateDragBox)
end

function Painter:UpdateDragBox()
	local x, y = GetCursorPosition()
	local s = UIParent:GetScale()
	x = x/s; y = y/s

	if (x >= self.x and self.startX == 'RIGHT') then
		self.startX = 'LEFT'
	end
	if (x < self.x and self.startX == 'LEFT') then
		self.startX = 'RIGHT'
	end

	if (y >= self.y and self.startY == 'TOP') then
		self.startY = 'BOTTOM'
	end
	if (y < self.y and self.startY == 'BOTTOM') then
		self.startY = 'TOP'
	end

	local endX = (self.startX == 'LEFT' and 'RIGHT') or 'LEFT'
	local endY = (self.startY == 'TOP' and 'BOTTOM') or 'TOP'

	--make the bars an exact size
	local x = x + (self.x - x) % 37
	local y = y + (self.y - y) % 37

	if endY == 'BOTTOM' then
		y = min(y, self.y - 37)
	else
		y = max(y, self.y + 37)
	end

	if endX == 'LEFT' then
		x = min(x, self.x - 37)
	else
		x = max(x, self.x + 37)
	end

	--update the box position
	self.box:ClearAllPoints()
	self.box:SetPoint(self.startY .. self.startX, UIParent, 'BOTTOMLEFT', self.x, self.y)
	self.box:SetPoint(endY .. endX, UIParent, 'BOTTOMLEFT', x, y)

	--update the box text and our row and colum count
	self.rows = floor(self.box:GetHeight() / 37 + 0.5)
	self.cols = floor(self.box:GetWidth() / 37 + 0.5)
	
	if self.rows * self.cols > Action.Bar:NumFreeIDs() then
		self.box.bg:SetTexture(1, 0, 0, 0.4)
	else
		self.box.bg:SetTexture(0, 0.5, 0, 0.4)
	end
	self.box.text:SetFormattedText('%dx%d', self.rows, self.cols)
end

--try and create the bar
function Painter:CreateBar()
	if self.box and self.box:IsShown() then
		Action.Bar:Create(self.rows, self.cols, self.startY .. self.startX, self.x, self.y)
		self.box:Hide()
		self:SetScript('OnUpdate', self.OnUpdate)
	end
end