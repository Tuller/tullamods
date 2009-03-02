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
	
	if f.created then
		f.created = nil
		f:OnCreate()
	end
	
	if UnitExists(f:GetAttribute('unit')) then
		f:Show()
	end
	
	f:LoadSettings()
	f:SetUnit(unit)

	active[unit] = f
	return f
end

function Frame:Create(unit)
	local f = self:Bind(CreateFrame('Frame', format('Sage%sFrame', unit), UIParent, 'SecureHandlerStateTemplate'))
	f.id = unit
	f.sets = setmetatable({}, {
		__index = function(t, k)
			return f._sets[k]
		end,
		
		__newindex = function(t, k, v)
			f:SetSetting(k, v)
		end
	})
	
	f:LoadUnitController()
	f:LoadVisibilityController()
	f:SetAttribute('unit', unit)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnHide', f.OnHide)

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
	self._sets = Sage:GetFrameSets(self.id) or Sage:SetFrameSets(self.id, self:GetDefaults())
	
	for k, v in self:GetSettings() do
		self:OnSettingChanged(k, v)
	end
	self:Reposition()
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

function Frame:width_Change(newWidth)
	self:UpdateWidth()
end

function Frame:GetFrameWidth()
	return max(0, self._sets.width or 0)
end

function Frame:extraWidth_Change(newWidth)
	self:UpdateWidth()
end

function Frame:GetExtraWidth()
	return math.max(self._sets.extraWidth or 0, 0)
end

function Frame:UpdateWidth()
	self:SetWidth(self:GetFrameWidth() + self:GetExtraWidth())
end


--[[ Height ]]--

function Frame:height_Change(newHeight)
	self:UpdateHeight()
end

function Frame:UpdateHeight()
	self:SetHeight(self:GetFrameHeight())
end

function Frame:GetFrameHeight()
	return math.max(self._sets.height or 0, 0)
end


--[[ Scaling ]]--

function Frame:scale_Change(newScale)
	if newScale == 1 and self._sets.scale ~= nil then
		self._sets.scale = nil
	end
	self:UpdateScale()
end

function Frame:UpdateScale()
	self:SetScale(self:GetScale())
end

function Frame:GetScale()
	return self._sets.scale or 1
end


--should be used over a direct call to frame.sets.scale = scale to do proper reanchoring
function Frame:SetFrameScale(scale, scaleAnchored)
	local scale = max(0, scale or 1)
	local x, y =  self:GetScaledCoords(scale)
	self.sets.scale = scale --implicit call to scale_Change
	
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

function Frame:GetScaledCoords(scale)
	local ratio = self:GetScale() / scale
	return (self:GetLeft() or 0) * ratio, (self:GetTop() or 0) * ratio
end


--[[ Opacity ]]--

function Frame:alpha_Change(newAlpha)
	if newAlpha == 1 and self._sets.alpha ~= nil then
		self._sets.alpha = nil
	end
	self:UpdateAlpha()
end
	
function Frame:UpdateAlpha()
	self:SetAlpha(self:GetFrameAlpha())
end

function Frame:GetFrameAlpha()
	return max(0, self._sets.alpha or 1)
end


--[[ Out of range opacity ]]

function Frame:oorAlpha_Change(newAlpha)
	self:UpdateOORAlpha()
end

function Frame:UpdateOORAlpha()
	local diff = floor(abs(self:GetFrameAlpha() - self:GetOORAlpha() * 100))
	if self:IsVisible() and diff == 0 then
		Sage.RangeFader:Unregister(self)
	else
		Sage.RangeFader:Register(self)
	end
end

function Frame:GetOORAlpha()
	return self._sets.oorAlpha or self:GetFrameAlpha()
end


--[[ Unit State Controller ]]--

function Frame:unitStates_Change(newStates)
	self:UpdateUnitStates()
end

function Frame:UpdateUnitStates()
	if self._sets.unitStates then
		RegisterStateDriver(self, 'unit', self._sets.unitStates)
	else
		UnregisterStateDriver(self, 'unit')
		self:SetAttribute('unit', self.id)
	end
end


--[[ Unit Attribute ]]--

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

function Frame:visibilityStates_Change(newStates)
	self:UpdateVisibilityStates()
end

function Frame:UpdateVisibilityStates()
	if self._sets.visibilityStates then
		RegisterStateDriver(self, 'forcevisibility', self._sets.visibilityStates)
		self:SetAttribute('state-forcevisibility', 'dummyValueToForceAnUpdate') --does exactly what you think it does
	else
		UnregisterStateDriver(self, 'forcevisibility')
		self:SetAttribute('state-forcevisibility', 'show')
	end
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
end

function Frame:GetAnchor()
	local anchorString = self._sets.anchor
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
	self:UpdateScale()

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


--[[
	Settings...setting
		The intent of this functionality is to allow components to listen for when a setting changes and react to it
--]]

function Frame:SetSetting(key, value)
	assert(self._sets, format('Missing settings for frame "%s"', self.id or 'nil'))
	if self._sets[key] ~= value then
		self._sets[key] = value
		self:OnSettingChanged(key, value)
	end
end

function Frame:GetSettings()
	return pairs(self._sets)
end

function Frame:GetSetting(id, key)
	local f
	if id == 'all' then
		f = self:Get('player')
	elseif id == 'party' then
		f = self:Get('party1')
	else
		f = self:Get(id)
	end
	return f and f.sets[key]
end

function Frame:OnSettingChanged(key, value)
	local method = key .. '_Change'
	
	if self[method] then
		self[method](self, value)
	end
	
	--hack, since the drag frame is technically not a child frame
	if self.drag and self.drag[method] then
		self.drag[method](self.drag, value)
	end
	
	self:ForChildren(method, value)
end
