--[[
	Sage Frame
		A unitframe container object
--]]

local Frame = Sage:CreateClass('Frame')
Sage.Frame = Frame

local Config = Sage:GetModule('Config')

local active = {}
local unused = {}

--constructor
function Frame:New(id)
	local id = tonumber(id) or id
	local f = self:Restore(id) or self:Create(id)
	f:LoadSettings()

	active[id] = f
	return f
end

function Frame:Create(id)
	local f = self:Bind(CreateFrame('Frame', nil, UIParent))
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f.id = id

	f.header = CreateFrame('Frame', nil, f, 'SecureHandlerAttributeTemplate')
	f.header:SetAllPoints(f)

	f.drag = Sage.DragFrame:New(f)

	return f
end

function Frame:Restore(id)
	local f = unused[id]
	if f then
		unused[id] = nil
		return f
	end
end

--destructor
function Frame:Free()
	active[self.id] = nil

	UnregisterStateDriver(self.header, 'state', 0)
	UnregisterStateDriver(self.header, 'visibility', 'show')

	for i in pairs(self.buttons) do
		self:RemoveButton(i)
	end
	self.buttons = nil

	self:ClearAllPoints()
	self:SetUserPlaced(nil)
	self.drag:Hide()
	self:Hide()

	unused[self.id] = self
end

function Frame:Delete()
	self:Free()
	Sage:SetFrameSets(self.id, nil)
end

function Frame:LoadSettings(defaults)
	self.sets = Sage:GetFrameSets(self.id) or Sage:SetFrameSets(self.id, self:GetDefaults()) --get defaults must be provided by anything implementing the Frame type
	self:Reposition()

	if Sage:Locked() then
		self:Lock()
	else
		self:Unlock()
	end

	self:UpdateShowStates()
	self:UpdateAlpha()
end


--[[ Scaling ]]--

function Frame:GetScaledCoords(scale)
	local ratio = self:GetScale() / scale
	return (self:GetLeft() or 0) * ratio, (self:GetTop() or 0) * ratio
end

function Frame:SetFrameScale(scale, scaleAnchored)
	local x, y =  self:GetScaledCoords(scale)

	self.sets.scale = scale
	self:Rescale()

	if not self.sets.anchor then
		self:ClearAllPoints()
		self:SetPoint('TOPLEFT', self:GetParent(), 'BOTTOMLEFT', x, y)
		self:SavePosition()
	end

	if scaleAnchored then
		for _,f in self:GetAll() do
			if f:GetAnchor() == self then
				f:SetFrameScale(scale, true)
			end
		end
	end
end

function Frame:Rescale()
	self:SetScale(self:GetScale())
	self.drag:SetScale(self:GetScale())
end

function Frame:GetScale()
	return self.sets.scale or 1
end


--[[ Opacity ]]--

function Frame:UpdateAlpha()
	self:SetAlpha(self:GetFrameAlpha())
end

function Frame:SetFrameAlpha(alpha)
	if alpha == 1 then
		self.sets.alpha = nil
	else
		self.sets.alpha = alpha
	end
	self:UpdateAlpha()
end

function Frame:GetFrameAlpha()
	return self.sets.alpha or 1
end

--[[ ShowStates ]]--

function Frame:SetShowStates(states)
	self.sets.showstates = states
	self:UpdateShowStates()
end

function Frame:GetShowStates()
	return self.sets.showstates
end

function Frame:UpdateShowStates()
	UnregisterStateDriver(self.header, 'visibility', 'show')
	self.header:Show()

	local showstates = self:GetShowStates()
	if showstates then
		RegisterStateDriver(self.header, 'visibility', showstates .. 'show;hide')
	end
end


--[[ Lock/Unlock ]]--

function Frame:Lock()
	self.drag:Hide()
end

function Frame:Unlock()
	self.drag:Show()
end


--[[ Sticky Bars ]]--

Frame.stickyTolerance = 16

function Frame:StickToEdge()
	local point, x, y = self:GetRelPosition()
	local s = self:GetScale()
	local w = self:GetParent():GetWidth()/s
	local h = self:GetParent():GetHeight()/s
	local rTolerance = self.stickyTolerance/s
	local changed = false

	--sticky edges
	if abs(x) <= rTolerance then
		x = 0
		changed = true
	end

	if abs(y) <= rTolerance then
		y = 0
		changed = true
	end

	-- auto centering
	local cX, cY = self:GetCenter()
	if y == 0 then
		if abs(cX - w/2) <= rTolerance*2 then
			if point == 'TOPLEFT' or point == 'TOPRIGHT' then
				point = 'TOP'
			else
				point = 'BOTTOM'
			end

			x = 0
			changed = true
		end
	elseif x == 0 then
		if abs(cY - h/2) <= rTolerance*2 then
			if point == 'TOPLEFT' or point == 'BOTTOMLEFT' then
				point = 'LEFT'
			else
				point = 'RIGHT'
			end

			y = 0
			changed = true
		end
	end

	--save this junk if we've done something
	if changed then
		self.sets.point = point
		self.sets.x = x
		self.sets.y = y

		self:ClearAllPoints()
		self:SetPoint(point, x, y)
	end
end

function Frame:Stick()
	self.sets.anchor = nil

	--only do sticky code if the alt key is not currently down
	if Sage:Sticky() and not IsAltKeyDown() then
		--try to stick to a bar, then try to stick to a screen edge
		for _, f in self:GetAll() do
			if f ~= self then
				local point = FlyPaper.Stick(self, f, self.stickyTolerance)
				if point then
					self.sets.anchor = f.id .. point
					break
				end
			end
		end

		if not self.sets.anchor then
			self:StickToEdge()
		end
	end

	self:SavePosition()
	self.drag:UpdateColor()
end

function Frame:Reanchor()
	local f, point = self:GetAnchor()

	if not(f and FlyPaper.StickToPoint(self, f, point)) then
		self.sets.anchor = nil

		if not self:Reposition() then
			self:ClearAllPoints()
			self:SetPoint('CENTER')
		end
	end
	self.drag:UpdateColor()
end

function Frame:GetAnchor()
	local anchorString = self.sets.anchor
	if anchorString then
		local pointStart = #anchorString - 1
		return self:Get(anchorString:sub(1, pointStart - 1)), anchorString:sub(pointStart)
	end
end


--[[ Positioning ]]--

function Frame:GetRelPosition()
	local parent = self:GetParent()
	local w, h = parent:GetWidth(), parent:GetHeight()
	local x, y = self:GetCenter()
	local s = self:GetScale()
	w = w/s h = h/s

	local dx, dy
	local hHalf = (x > w/2) and 'RIGHT' or 'LEFT'
	if hHalf == 'RIGHT' then
		dx = self:GetRight() - w
	else
		dx = self:GetLeft()
	end

	local vHalf = (y > h/2) and 'TOP' or 'BOTTOM'
	if vHalf == 'TOP' then
		dy = self:GetTop() - h
	else
		dy = self:GetBottom()
	end

	return vHalf..hHalf, dx, dy
end

function Frame:SavePosition()
	local point, x, y = self:GetRelPosition()
	local sets = self.sets

	sets.point = point
	sets.x = x
	sets.y = y
end

--place the frame at it's saved position
function Frame:Reposition()
	self:Rescale()

	local sets = self.sets
	local point, x, y = sets.point, sets.x, sets.y

	if point then
		self:ClearAllPoints()
		self:SetPoint(point, x, y)
		self:SetUserPlaced(true)
		return true
	end
end

function Frame:SetFramePoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
	self:SavePosition()
end


--[[ Metafunctions ]]--

function Frame:Get(id)
	return active[tonumber(id) or id]
end

function Frame:GetAll()
	return pairs(active)
end

function Frame:ForAll(method, ...)
	for _,f in self:GetAll() do
		local action = f[method]
		if action then
			action(f, ...)
		end
	end
end

--takes a frameID, and performs the specified action on that frame
--this adds two special IDs, 'all' for all frames, and 'party for all party frames
function Frame:ForFrame(id, method, ...)
	if id == 'all' then
		self:ForAll(method, ...)
	elseif id == 'party' then
		for i = 1, MAX_PARTY_MEMBERS do
			local f = self:Get('party' .. i)
			if f then
				local action = f[method]
				if action then
					action(f, ...)
				end
			end
		end
	else
		local f = self:Get(id)
		if f then
			local action = f[method]
			if action then
				action(f, ...)
			end
		end
	end
end