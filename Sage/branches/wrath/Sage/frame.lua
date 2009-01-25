--[[
	Sage Frame
		A unitframe container. This object defines the following properties:
			The frame's unit (can change based on state)
			The frame's region/size/opacity/scale
			The frame's visibility settings
			The frame's faded opacity

		The object also provides methods to do nifty things, like add other objects to the frame
--]]

local Frame = Sage:CreateClass('Frame')
Sage.Frame = Frame

local active = {}
local unused = {}

--constructor
function Frame:New(unit)
	local f = self:Restore(unit) or self:Create(unit)
	f:SetUnit(unit)
	f:LoadSettings()
	
	if f.created then
		f.created = nil
		f:OnCreate()
	end
	
	if UnitExists(f:GetAttribute('unit')) then
		f:Show()
	end

	active[unit] = f
	return f
end

function Frame:Create(unit)
	local f = self:Bind(CreateFrame('Frame', format('Sage%sFrame', unit), UIParent, 'SecureHandlerStateTemplate'))
	f:LoadUnitController()
	f:LoadVisibilityController()
	f:SetAttribute('unit', unit)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnHide', f.OnHide)

	f.id = unit

	--get rid of the blizzard unit for this frame
	Sage:UnregisterUnit(unit)

	f.created = true
	return f
end

function Frame:OnCreate()
	--should be overridden, called when a frame is first created
end

function Frame:OnShow()
	self:UpdateOORAlpha()
end

function Frame:OnHide()
	self:UpdateOORAlpha()
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

	self:UnregisterAllEvents()
	self:ClearAllPoints()
	self:SetUserPlaced(nil)

	if self.drag then
		self.drag:Hide()
	end

	self:Hide()

	unused[self.id] = self
end

function Frame:Delete()
	self:Free()
	Sage:SetFrameSets(self.id, nil)
end

function Frame:LoadSettings(defaults)
	self.sets = Sage:GetFrameSets(self.id) or Sage:SetFrameSets(self.id, self:GetDefaults())
	self:UpdateWidth()
	self:UpdateHeight()
	self:Reposition()
	self:UpdateAlpha()
	self:UpdateOORAlpha()
	self:UpdateUnitStates()
	self:UpdateVisibilityStates()
end

--should be overridden, called when first initializing a frame's settings
function Frame:GetDefaults()
	return {
		point = 'CENTER',
		width = 200,
		height = 200
	}
end


--[[ Width ]]--

function Frame:SetFrameWidth(width)
	self.sets.width = width
	self:UpdateWidth()
end

function Frame:UpdateWidth()
	self:SetWidth(self.sets.width)
end


--[[ Height ]]--

function Frame:SetFrameHeight(height)
	self.sets.height = height
	self:UpdateHeight()
end

function Frame:UpdateHeight()
	self:SetHeight(self.sets.height)
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

	if self.drag then
		self.drag:SetScale(self:GetScale())
	end
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


--[[ Out of range opacity ]]

function Frame:UpdateOORAlpha()
	if self:IsVisible() and floor(self:GetFrameAlpha() * 100) == floor(self:GetOORAlpha() * 100) then
		Sage.RangeFader:Unregister(self)
	else
		Sage.RangeFader:Register(self)
	end
end

function Frame:SetOORAlpha(alpha)
	self.sets.oorAlpha = alpha
end

function Frame:GetOORAlpha()
	return self.sets.oorAlpha or self:GetFrameAlpha()
end


--[[ Unit ]]--

function Frame:UpdateUnitStates()
	if self.sets.unitStates then
		RegisterStateDriver(self, 'unit', self.sets.unitStates)
	else
		UnregisterStateDriver(self, 'unit')
		self:SetAttribute('unit', self.id)
	end
end

function Frame:SetUnitStates(states)
	self.sets.unitStates = unitStates
	self:UpdateUnitStates()
end

function Frame:SetUnit(unit)
	self:SetAttribute('unit', unit)

	if not UnitWatchRegistered(self) then
		RegisterUnitWatch(self, true)
	end
end

function Frame:LoadUnitController()
	self:SetAttribute('_onstate-unit', [[
		self:SetAttribute('unit', newstate)
		control:ChildUpdate(stateid, newstate)
		control:CallMethod('ForChildren', 'UpdateUnit', newstate)
	]])

	self:SetAttribute('_onstate-unitexists', [[
		self:SetAttribute('unitexists', newstate)
		control:RunAttribute('updatevisibility')
	]])
end


--[[ Visibility ]]--

function Frame:LoadVisibilityController()
	self:SetAttribute('_onstate-forcevisibility', [[
		if newstate == 'nil' then
			self:SetAttribute('forcevisibility', nil)
		else
			self:SetAttribute('forcevisibility', newstate)
		end
		control:RunAttribute('updatevisibility')
	]])

	self:SetAttribute('updatevisibility', [[
		local forcehide = self:GetAttribute('forcevisibility') == 'hide'

		if self:GetAttribute('unitexists') and not forcehide then
			self:Show()
		else
			self:Hide()
		end
	]])
end

function Frame:UpdateVisibilityStates()
	if self.sets.visibilityStates then
		RegisterStateDriver(self, 'forcevisibility', self.sets.visibilityStates)
	else
		UnregisterStateDriver(self, 'forcevisibility')
		if UnitExists(self:GetAttribute('unit')) then
			self:Show()
		end
	end
end

function Frame:SetVisibilityStates(states)
	self.sets.visibilityStates = states
	self:UpdateVisibilityStates()
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

	if self.drag then
		self.drag:UpdateColor()
	end
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

	if self.drag then
		self.drag:UpdateColor()
	end
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

function Frame:ForChildren(method, ...)
	for i = 1, select('#', self:GetChildren()) do
		local f = select(i, self:GetChildren())
		local action = f[method]
		if action then
			action(f, ...)
		end
	end
end

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

function Frame:ForAllVisibile(method, ...)
	for _,f in self:GetAll() do
		if f:IsVisible() then
			local action = f[method]
			if action then
				action(f, ...)
			end
		end
	end
end

--takes a frameID, and performs the specified action on that frame
--this adds two special IDs, 'all' for all frames, and 'party' for all party frames
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