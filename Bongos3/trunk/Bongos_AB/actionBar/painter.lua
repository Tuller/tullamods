--[[
	Painter.lua
		ActionBar creation via click and drag
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local Action = Bongos:GetModule('ActionBar')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3-AB')

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
	self:SetScript('OnShow', self.ShowHelp)
	self:SetScript('OnHide', self.HideHelp)
	self.nextUpdate = 0

	self.loaded = true
end

function Painter:CreateHelp()
	local f = CreateFrame('Frame', 'BongosABHelpDialog', UIParent)
	f:SetFrameStrata('DIALOG')
	f:SetToplevel(true); f:EnableMouse(true)
	f:SetWidth(320); f:SetHeight(96)
	f:SetBackdrop{
		bgFile='Interface\\DialogFrame\\UI-DialogBox-Background' ,
		edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',
		tile = true,
		insets = {left = 11, right = 12, top = 12, bottom = 11},
		tileSize = 32,
		edgeSize = 32,
	}
	f:SetPoint('TOP', 0, -24)
	f:Hide()
	
	f.title = f:CreateFontString('ARTWORK')
	f.title:SetPoint('TOP', 0, -16)
	f.title:SetFontObject('GameFontNormalLarge')
	
	f.text = f:CreateFontString('ARTWORK')
	f.text:SetFontObject('GameFontHighlight')
	f.text:SetPoint('TOP', 0, -40)
	f.text:SetWidth(300); f.text:SetHeight(0)
	f.text:SetText(L.CreateBarHelp)
	
	f:SetHeight(24 + 8 + 24 + f.text:GetStringHeight())
	
	local tr = f:CreateTitleRegion()
	tr:SetAllPoints(f)
	f:SetClampedToScreen(true)
	
	local close = CreateFrame('Button', f:GetName() .. 'Close', f, 'UIPanelCloseButton')
	close:SetPoint('TOPRIGHT', -3, -3)

	self.dialog = f
	return f
end

function Painter:ShowHelp()
	local dialog = self.dialog or self:CreateHelp()
	dialog:Show()
	self:UpdateDialogTitle()
end

function Painter:HideHelp()
	if self.dialog then
		self.dialog:Hide()
	end
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

function Painter:UpdateDialogTitle()
	if self.dialog then
		self.dialog.title:SetFormattedText(L.NumActionButtons, Action.Bar:NumFreeIDs())
	end
end