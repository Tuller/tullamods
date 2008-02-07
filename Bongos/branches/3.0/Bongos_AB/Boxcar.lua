local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local ActionBar = Bongos:GetModule('ActionBar')

local f = CreateFrame('Frame', nil, UIParent)
f:SetFrameStrata('BACKGROUND')
f:SetFrameLevel(0)
f:Hide()

f.bg = f:CreateTexture()
f.bg:SetTexture(0, 0, 0.1, 0.3)
f.bg:SetAllPoints(f)

f:SetFrameLevel(1)
f:EnableMouse(true)
f:RegisterForDrag('LeftButton')
f:SetAllPoints(UIParent)

f.text = f:CreateFontString()
f.text:SetFontObject('GameFontNormalHuge')
f.text:SetPoint('TOP', 0, -64)

function f:OnUpdate(elapsed)
	local x, y = GetCursorPosition()
	local s = UIParent:GetScale()
	x = x/s; y = y/s

	if (x > self.x and self.startX == 'RIGHT') then
		self.startX = 'LEFT'
	end
	if (x < self.x and self.startX == 'LEFT') then
		self.startX = 'RIGHT'
	end

	if (y > self.y and self.startY == 'TOP') then
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

	self.frame:ClearAllPoints()
	self.frame:SetPoint(self.startY .. self.startX, UIParent, 'BOTTOMLEFT', self.x, self.y)
	self.frame:SetPoint(endY .. endX, UIParent, 'BOTTOMLEFT', x, y)

	self.rows = floor(self.frame:GetHeight() / 37 + 0.5)
	self.cols = floor(self.frame:GetWidth() / 37 + 0.5)
	self.frame.text:SetFormattedText('%d x %d', self.rows, self.cols)
end

function f:UpdateText()
	self.text:SetText('Available Buttons: ' .. ActionBar.Bar:NumFreeIDs())
end

f:SetScript('OnMouseDown', function(self)
	local x, y = GetCursorPosition()
	local s = UIParent:GetScale()
	x = x/s; y = y/s

	if x > GetScreenWidth() / 2 then
		self.startX = 'RIGHT'
--		x = x + 16/s
	else
		self.startX = 'LEFT'
--		x = x - 16/s
	end

	if y > GetScreenHeight() / 2 then
		self.startY = 'TOP'
--		y = y + 16/s
	else
		self.startY = 'BOTTOM'
--		y = y - 16/s
	end

	self.x = x
	self.y = y
end)

f:SetScript('OnDragStart', function(self)
	if not self.frame then
		self.frame = CreateFrame('Frame', nil, self)
		self.frame.bg = self.frame:CreateTexture()
		self.frame.bg:SetTexture(random(), random(), random(), 0.4)
		self.frame.bg:SetAllPoints(self.frame)

		local text = self.frame:CreateFontString()
		text:SetPoint('CENTER')
		text:SetFontObject('GameFontNormal')
		self.frame.text = text
	end
--[[
	local x, y = GetCursorPosition()
	local s = UIParent:GetScale()
	x = x/s; y = y/s

	if x > GetScreenWidth() / 2 then
		self.startX = 'RIGHT'
		x = x + 16/s
	else
		self.startX = 'LEFT'
		x = x - 16/s
	end

	if y > GetScreenHeight() / 2 then
		self.startY = 'TOP'
		y = y + 16/s
	else
		self.startY = 'BOTTOM'
		y = y - 16/s
	end

	self.x = x
	self.y = y
--]]
	self.frame:ClearAllPoints()
	self.frame:SetPoint(self.startY .. self.startX, UIParent, 'BOTTOMLEFT', self.x, self.y)
	self.frame:Show()

	self:SetScript('OnUpdate', self.OnUpdate)
end)

do
	local id = 1
	f:SetScript('OnDragStop', function(self)
		ActionBar.Bar:Create(id, self.rows, self.cols, self.startY .. self.startX, self.x, self.y)
		id = id + 1
		self.frame:Hide()

		self:SetScript('OnUpdate', nil)
	end)
	
	f:SetScript('OnShow', f.UpdateText)
end

ActionBar.Painter = f