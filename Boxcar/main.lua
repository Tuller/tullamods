local f = CreateFrame('Frame', nil, UIParent)
f.bg = f:CreateTexture()
f.bg:SetTexture(0, 0, 0.1, 0.1)
f.bg:SetAllPoints(f)

f:SetFrameLevel(1)
f:EnableMouse(true)
f:RegisterForDrag('LeftButton')
f:SetAllPoints(UIParent)

local function OnUpdate(self, elapsed)
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

	self.rows = floor(self.frame:GetWidth() / 37 + 0.5)
	self.cols = floor(self.frame:GetHeight() / 37 + 0.5)
	self.frame.text:SetFormattedText('%d x %d', self.rows, self.cols)
end


f:SetScript('OnDragStart', function(self)
	self.frame = CreateFrame('Frame', nil, self)
	self.frame.bg = self.frame:CreateTexture()
	self.frame.bg:SetTexture(random(), random(), random(), 0.4)
	self.frame.bg:SetAllPoints(self.frame)

	local text = self.frame:CreateFontString()
	text:SetPoint('CENTER')
	text:SetFontObject('GameFontNormal')
	self.frame.text = text

	local x, y = GetCursorPosition()
	local s = UIParent:GetScale()
	x = x/s
	y = y/s

	if x > GetScreenWidth() / 2 then
		self.startX = 'RIGHT'
	else
		self.startX = 'LEFT'
	end

	if y > GetScreenHeight() / 2 then
		self.startY = 'TOP'
	else
		self.startY = 'BOTTOM'
	end

	self.x = x
	self.y = y

	self.frame:ClearAllPoints()
	self.frame:SetPoint(self.startY .. self.startX, UIParent, 'BOTTOMLEFT', self.x, self.y)

	self:SetScript('OnUpdate', OnUpdate)
end)


f:SetScript('OnDragStop', function(self)
	Bongos:Print('create bar: self.frame

	self:SetScript('OnUpdate', nil)
end)