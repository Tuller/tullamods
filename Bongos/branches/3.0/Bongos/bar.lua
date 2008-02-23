--[[
	BBar.lua - A movable, scalable, container frame
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
Bongos.Bar = Bongos:CreateWidgetClass('Frame')

local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3')


--[[ Auto Fade Manager ]]--

do
	local f = CreateFrame('Frame')
	f.nextUpdate = 0.1
	f.bars = {}

	f:SetScript('OnUpdate', function(self, elapsed)
		if self.nextUpdate < 0 then
			self.nextUpdate = 0.1

			for bar in pairs(self.bars) do
				if MouseIsOver(bar, 1, -1, -1, 1) then
					if abs(bar:GetAlpha() - bar:GetFadedAlpha()) < 0.01 then --the checking logic is a little weird because floating point values tend to not be exact
						UIFrameFadeIn(bar, 0.1, bar:GetAlpha(), bar:GetFrameAlpha())
					end
				else
					if abs(bar:GetAlpha() - bar:GetFrameAlpha()) < 0.01 then
						UIFrameFadeOut(bar, 0.1, bar:GetAlpha(), bar:GetFadedAlpha())
					end
				end
			end
		else
			self.nextUpdate = self.nextUpdate - elapsed
		end
	end)
	f:Hide()

	function f:Add(bar)
		self.bars[bar] = true
		if not self:IsShown() then
			self:Show()
		end
	end

	function f:Remove(bar)
		self.bars[bar] = nil
		if not next(self.bars) then
			self:Hide()
		end
	end

	Bongos.Bar.Fader = f
end


--[[ Constructor/Destructor ]]--

local BBar = Bongos.Bar
BBar.stickyTolerance = 16
BBar.paddingX = 2
BBar.paddingY = 2

local active = {}
local unused = {}

function BBar:Create(id, defaults, secure, strata)
	local id = tonumber(id) or id
	assert(id, 'id expected')
	assert(not active[id], format('BBar \'%s\' is already in use', id))

	local isNew = false
	local bar = self:Restore(id)
	if not bar then
		bar = self:CreateNew(id, secure, strata)
		isNew = true
	end
	bar:LoadSettings(defaults)

	active[id] = bar

	return bar, isNew
end

function BBar:CreateNew(id, secure, strata)
	local bar
	if secure then
		bar = self:New(CreateFrame('Frame', nil, UIParent, 'SecureStateHeaderTemplate'))
	else
		bar = self:New(CreateFrame('Frame', nil, UIParent))
	end
	bar.id = id
	bar.dragFrame = Bongos.Drag:Create(bar)

	if strata then
		bar:SetFrameStrata(strata)
	end

	bar:SetWidth(32); bar:SetHeight(32)
	bar:SetClampedToScreen(true)
	bar:SetMovable(true)

	return bar
end

function BBar:Restore(id)
	local bar = unused[id]
	if bar then
		unused[id] = nil
		return bar
	end
end

function BBar:Destroy(deleteSettings)
	active[self.id] = nil

	if self.OnDelete then
		self:OnDelete()
	end

	self.sets = nil
	self.dragFrame:Hide()
	self:ClearAllPoints()
	self:SetUserPlaced(false)
	self:Hide()

	self.Fader:Remove(self)

	if deleteSettings then
		Bongos:SetBarSets(self.id, nil)
	end

	unused[self.id] = self
end

function BBar:LoadSettings(defaults)
	self.sets = Bongos:GetBarSets(self.id) or Bongos:SetBarSets(self.id, defaults or {point = 'CENTER'})
	self:Reposition()

	if self.sets.hidden then
		self:HideFrame()
	else
		self:ShowFrame()
	end

	if Bongos:IsLocked() then
		self:Lock()
	else
		self:Unlock()
	end

	self:UpdateAlpha()
	self:UpdateFader()
end


--[[ Lock/Unlock ]]--

function BBar:Lock()
	self.dragFrame:Hide()
end

function BBar:Unlock()
	self.dragFrame:Show()
end


--[[ Sticky Bars ]]--

function BBar:StickToEdge()
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

function BBar:Stick()
	local stuck = false

	if Bongos:IsSticky() then
		self.sets.anchor = nil

		--try to stick to a screen edge, then try to stick to a bar
		for _, frame in self:GetAll() do
			if frame ~= self then
				local point = FlyPaper.Stick(self, frame, self.stickyTolerance, self.paddingX, self.paddingY)
				if point then
					self.sets.anchor = frame.id .. point
					break
				end
			end
		end

		if not self.sets.anchor then
			self:StickToEdge()
		end
	end

	self:SavePosition()
	self.dragFrame:UpdateColor()
end

--try to reanchor the frame
function BBar:Reanchor()
	local frame, point = self:GetAnchor()

	if not(frame and Bongos:IsSticky() and FlyPaper.StickToPoint(self, frame, point, self.paddingX, self.paddingY)) then
		self.sets.anchor = nil

		if not self:Reposition() then
			self:ClearAllPoints()
			self:SetPoint('CENTER')
		end
	end
	self.dragFrame:UpdateColor()
end

function BBar:GetAnchor()
	local anchorString = self.sets.anchor
	if anchorString then
		local pointStart = #anchorString - 1
		return self:Get(anchorString:sub(1, pointStart - 1)), anchorString:sub(pointStart)
	end
end


--[[ Positioning ]]--

function BBar:GetRelPosition()
	local parent = self:GetParent()
	local w, h = parent:GetWidth(), parent:GetHeight()
	local x, y = self:GetCenter()
	local s = self:GetScale()
	w = w/s; h = h/s

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

function BBar:SavePosition()
	local point, x, y = self:GetRelPosition()
	local sets = self.sets

	sets.point = point
	sets.x = x
	sets.y = y
end

--place the frame at it's saved position
--returns true if we've placed the frame
function BBar:Reposition()
	self:Rescale()

	local sets = self.sets

	--the new hotness positioning code
	local point, x, y = sets.point, sets.x, sets.y
	if point then
		self:ClearAllPoints()
		self:SetPoint(point, x, y)
		self:SetUserPlaced(true)
		return true
	end
end

function BBar:SetFramePoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
	self:SavePosition()
end


--[[ Scaling ]]--

function BBar:GetScaledCoords(scale)
	local ratio = self:GetScale() / scale
	return (self:GetLeft() or 0) * ratio, (self:GetTop() or 0) * ratio
end

function BBar:SetFrameScale(scale, scaleAnchored)
	local x, y =  self:GetScaledCoords(scale)

	self.sets.scale = scale
	self:SetScale(scale or 1)
	self.dragFrame:SetScale(scale or 1)

	if not self.sets.anchor then
		self:ClearAllPoints()
		self:SetPoint('TOPLEFT', self:GetParent(), 'BOTTOMLEFT', x, y)
		self:SavePosition()
	end

	if scaleAnchored and Bongos:IsSticky() then
		for _,frame in self:GetAll() do
			if frame:GetAnchor() == self then
				frame:SetFrameScale(scale, true)
			end
		end
	end
end

function BBar:Rescale()
	self:SetScale(self.sets.scale or 1)
	self.dragFrame:SetScale(self.sets.scale or 1)
end


--[[ Opacity ]]--

function BBar:UpdateAlpha()
	local alpha
	if MouseIsOver(self, 1, -1, -1, 1) then
		alpha = self:GetFrameAlpha()
	else
		alpha = self:GetFadedAlpha()
	end
	self:SetAlpha(alpha)
end

function BBar:SetFrameAlpha(alpha)
	if alpha == 1 then
		self.sets.alpha = nil
	else
		self.sets.alpha = alpha
	end
	self:UpdateAlpha()
end

function BBar:GetFrameAlpha()
	return self.sets.alpha or 1
end

--faded opacity (mouse not over the frame)
function BBar:SetFadeAlpha(alpha)
	local alpha = alpha or 1
	if alpha == 1 then
		self.sets.fadeAlpha = nil
	else
		self.sets.fadeAlpha = alpha
	end

	self:UpdateAlpha()
	self:UpdateFader()
end

--returns fadedOpacity, fadePercentage
--fadedOpacity is what opacity the bar will be at when faded
--fadedPercentage is what modifier we use on normal opacity
function BBar:GetFadedAlpha(alpha)
	local fadeAlpha = self.sets.fadeAlpha or 1
	return fadeAlpha * self:GetFrameAlpha(), fadeAlpha
end


--[[ Visibility ]]--

function BBar:ShowFrame()
	self.sets.hidden = nil
	self:Show()
	self:UpdateFader()
	self.dragFrame:UpdateColor()
end

function BBar:HideFrame()
	self.sets.hidden = true
	self:Hide()
	self:UpdateFader()
	self.dragFrame:UpdateColor()
end

function BBar:ToggleFrame()
	if self:FrameIsShown() then
		self:HideFrame()
	else
		self:ShowFrame()
	end
end

function BBar:FrameIsShown()
	return not self.sets.hidden
end


--[[ Menus ]]--

function BBar:ShowMenu()
	if not self.menu then
		local menu
		if self.CreateMenu then
			menu = self:CreateMenu()
		else
			menu = Bongos.Menu:Create(self.id)
			menu:AddLayoutPanel()
		end
		self.menu = menu
	end

	self.menu:SetFrameID(self.id)
	self:AnchorMenu(self.menu)
	self.menu:ShowPanel(L.Layout)
end

function BBar:AnchorMenu(menu)
	local drag = self.dragFrame
	local ratio = UIParent:GetScale() / drag:GetEffectiveScale()
	local x = drag:GetLeft() / ratio
	local y = drag:GetTop() / ratio

	menu:Hide()
	menu:ClearAllPoints()
	menu:SetPoint('TOPRIGHT', UIParent, 'BOTTOMLEFT', x, y)
	menu:Show()
end


--[[ Utility ]]--

function BBar:Attach(frame)
	frame:SetFrameStrata(self:GetFrameStrata())
	frame:SetParent(self)
	frame:SetFrameLevel(0)
end

--run the fade onupdate checker if only if there are mouseover frames to check
function BBar:UpdateFader()
	if self.sets.hidden then
		self.Fader:Remove(self)
	else
		if(select(2, self:GetFadedAlpha()) == 1) then
			self.Fader:Remove(self)
		else
			self.Fader:Add(self)
		end
	end
end


--[[ Metafunctions ]]--

function BBar:Get(id)
	return active[tonumber(id) or id]
end

function BBar:GetAll()
	return pairs(active)
end

function BBar:ForAll(method, ...)
	for _, bar in self:GetAll() do
		local action = bar[method]
		if action then
			action(bar, ...)
		end
	end
end

--takes a barID, and performs the specified action on that bar
--this adds two special IDs, 'all' for all bars and number-number for a range of IDs
function BBar:ForBar(id, method, ...)
	assert(id and id ~= '', 'Invalid barID')

	if id == 'all' then
		self:ForAll(method, ...)
	else
		local startID, endID = tostring(id):match('(%d+)-(%d+)')
		startID = tonumber(startID)
		endID = tonumber(endID)

		if startID and endID then
			if startID > endID then
				local t = startID
				startID = endID
				endID = t
			end

			for i = startID, endID do
				local bar = self:Get(i)
				if bar then
					local action = bar[method]
					if action then
						action(bar, ...)
					end
				end
			end
		else
			local bar = self:Get(tonumber(id) or id)
			if bar then
				local action = bar[method]
				if action then
					action(bar, ...)
				end
			end
		end
	end
end