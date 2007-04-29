--[[
	BBar.lua - A movable, scalable, container frame
--]]

BBar = CreateFrame('Frame')
local Bar_MT = {__index = BBar}

local STICKY_TOLERANCE = 16 --how close one frame must be to another to trigger auto anchoring
local PADDING = 2
local active = {}
local unused = {}


--[[ Local Functions ]]--

--returns the adjusted x and y coordinates for a frame at the given scale
local function GetRelativeCoords(frame, scale)
	local ratio = frame:GetScale() / scale
	return frame:GetLeft() * ratio, frame:GetTop() * ratio
end

-- local function Bar_OnShow(self)
	-- Bongos:Print(format('Showing %s', self.id))
-- end

-- local function Bar_OnHide(self)
	-- Bongos:Print(format('Hiding %s', self.id))
-- end

local function Bar_OnAttributeChanged(self, arg1, arg2)
	local fadeMode = self.sets.fadeMode

	if arg1 == "incombat" and fadeMode then
		local maxAlpha, minAlpha = self:GetFrameAlpha()
		if arg2 == "true" then
			if fadeMode == 1 then
				UIFrameFadeOut(self, 0.4, maxAlpha, minAlpha)
			elseif fadeMode == 2 then
				UIFrameFadeIn(self, 0.15, self:GetAlpha(), maxAlpha)
			end
		else
			if fadeMode == 1 then
				UIFrameFadeIn(self, 0.15, self:GetAlpha(), maxAlpha)
			elseif fadeMode == 2 then
				UIFrameFadeOut(self, 0.4, maxAlpha, minAlpha)
			end
		end
	end
end

local function Bar_OnEvent(self, event, ...)
	if event == "PLAYER_REGEN_DISABLED" then
		self:SetAttribute("incombat", "true")
	elseif event == "PLAYER_REGEN_ENABLED" then
		self:SetAttribute("incombat", "nil")
	end		
end

local function Bar_New(id)
	local bar = setmetatable(CreateFrame('Frame', nil, UIParent), Bar_MT)
	
	bar.id = id
	bar.dragFrame = BDragFrame_New(bar)

	bar:SetClampedToScreen(true)
	bar:SetMovable(true)
	bar:SetSize(32)

	bar:SetScript('OnEvent', Bar_OnEvent)
	bar:SetScript('OnAttributeChanged', Bar_OnAttributeChanged)

	return bar
end

local function Bar_Restore(id)
	local bar = unused[id]
	if bar then
		unused[id] = nil
		bar:SetParent(UIParent)
		return bar
	end
end


--[[ Usable Functions ]]--

function BBar:Create(id, OnCreate, OnDelete)
	local id = tonumber(id) or id
	assert(id, "id expected")
	assert(not active[id], format("BBar '%s' is already in use", id))

	local bar = Bar_Restore(id) or Bar_New(id)
	bar.OnDelete = OnDelete

	bar:LoadSettings()
	if OnCreate then OnCreate(bar) end

	bar:RegisterEvent("PLAYER_REGEN_DISABLED")
	bar:RegisterEvent("PLAYER_REGEN_ENABLED")
	
	active[id] = bar

	return bar
end

function BBar:Destroy(removeSettings)
	active[self.id] = nil

	if self.OnDelete then
		self:OnDelete()
	end

	if removeSettings then
		Bongos:SetBarSets(self.id, nil)
	end
	self.sets = nil
	self.dragFrame:Hide()
	self:SetParent(nil)
	self:ClearAllPoints()
	self:SetUserPlaced(false)
	self:Hide()

	self:ForAll('Reanchor')
	self:UnregisterAllEvents()

	unused[self.id] = self
end


--[[ Settings Loading ]]--

function BBar:LoadSettings()
	self.sets = Bongos:GetBarSets(self.id) or Bongos:SetBarSets(self.id, {})
	self:SetFrameAlpha(self.sets.alpha)
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
end

--[[ Lock/Unlock ]]--

function BBar:Lock()
	self.dragFrame:Hide()
end

function BBar:Unlock()
	self.dragFrame:Show()
end


--[[ Frame Attributes ]]--

--laziness function on my part
function BBar:SetSize(x, y)
	self:SetWidth(x)
	self:SetHeight(y or x)
end

function BBar:SetFrameScale(scale)
	local x, y = GetRelativeCoords(self, scale)

	self:SetScale(scale)
	self:ClearAllPoints()
	self:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x, y)
	self:Reanchor()
	self:SavePosition()
end

function BBar:SetFrameAlpha(alpha)
	if alpha == 1 then
		self.sets.alpha = nil
	else
		self.sets.alpha = alpha
	end

	local mode = self.sets.fadeMode
	if mode then
		if mode == 2 and self:GetAttribute('incombat') then
			self:SetAlpha(alpha or 1)
		elseif mode == 1 and not self:GetAttribute('incombat')  then
			self:SetAlpha(alpha or 1)
		end
	else
		self:SetAlpha(alpha or 1)
	end
end

function BBar:Attach(frame)
	frame:SetParent(self)
	frame:SetAlpha(self:GetAlpha())
	frame:SetFrameLevel(0)
end


--[[ Visibility ]]--

function BBar:ShowFrame()
	self.sets.hidden = nil
	self:Show()
	self.dragFrame:UpdateColor()
end

function BBar:HideFrame()
	self.sets.hidden = true
	self:Hide()
	self.dragFrame:UpdateColor()
end

function BBar:ToggleFrame()
	if self.sets.hidden then
		self:ShowFrame()
	else
		self:HideFrame()
	end
end

--combat fading
function BBar:SetFadeMode(mode)
	if mode == 0 then
		self.sets.fadeMode = nil
	elseif not mode or (mode >= 0 and mode <= 3) then
		self.sets.fadeMode = mode
	end
		
	if not mode or mode == 0 then
		self:SetAlpha(self.sets.alpha or 1)
	else
		Bar_OnAttributeChanged(self, 'incombat', self:GetAttribute('incombat'))
	end
end

function BBar:SetFadeALpha(alpha)
	if alpha == 0 then
		self.sets.fadeAlpha = nil
	else
		self.sets.fadeAlpha = alpha
	end

	local mode = self.sets.fadeMode
	if mode then
		if mode == 1 and self:GetAttribute('incombat') then
			self:SetAlpha(alpha or 0)
		elseif mode == 2 and not self:GetAttribute('incombat')  then
			self:SetAlpha(alpha or 0)
		end
	end
end

function BBar:GetFrameAlpha()
	return self.sets.alpha or 1, self.sets.fadeAlpha or 0
end


--[[ Positioning ]]--

function BBar:Stick()
	if Bongos:IsSticky() then
		self.sets.anchor = nil

		for _, frame in self:GetAll() do
			if frame ~= self then
				local point = FlyPaper.Stick(self, frame, STICKY_TOLERANCE, PADDING, PADDING)
				if point then
					self.sets.anchor = frame.id .. point
					break
				end
			end
		end
	end

	self:SavePosition()
	self.dragFrame:UpdateColor()
end

function BBar:SavePosition()
	self.sets.x = self:GetLeft()
	self.sets.y = self:GetTop()

	local scale = self:GetScale()
	if scale == 1 then
		self.sets.scale = nil
	else
		self.sets.scale = scale
	end
end

--place the frame at it's saved position
function BBar:Reposition()
	local x, y = self.sets.x, self.sets.y
	self:Rescale()

	if x and y then
		self:ClearAllPoints()
		self:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x, y)
		self:SetUserPlaced(true)
	else
		self:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', random(0, GetScreenWidth()), random(0, GetScreenHeight()))
	end
end

function BBar:Rescale()
	self:SetScale(self.sets.scale or 1)
end

--try to reanchor the frame
function BBar:Reanchor()
	local frame, point = self:GetAnchor()

	if not(frame and Bongos:IsSticky() and FlyPaper.StickToPoint(self, frame, point, PADDING, PADDING)) then
		self.sets.anchor = nil

		local x, y = GetRelativeCoords(self, self:GetScale())
		self:ClearAllPoints()
		self:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x, y)
		self:SetUserPlaced(true)
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


--[[ Menus ]]--

function BBar:ShowMenu()
	if not self.menu then
		local menu = BongosMenu:Create(format('BongosMenu%s', self.id))
		menu.text:SetText(format("%s bar", self.id))
		menu.frame = self
		self.menu = menu
	end

	local menu = self.menu
	menu.onShow = 1
	self:PlaceMenu(menu)
	menu.onShow = nil
end

function BBar:PlaceMenu(menu)
	local dragFrame = self.dragFrame
	local ratio = UIParent:GetScale() / dragFrame:GetEffectiveScale()
	local x = dragFrame:GetLeft()
	local y = dragFrame:GetTop()

	menu:ClearAllPoints()
	menu:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", x  / ratio, y / ratio)
	menu:Show()
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
--this adds two special IDs, "all" for all bars and number-number for a range of IDs
function BBar:ForBar(id, method, ...)
	assert(id and id ~= '', 'Invalid barID')

	if id == 'all' then
		self:ForAll(method, ...)
	else
		local startID, endID = id:match('(%d+)-(%d+)')
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