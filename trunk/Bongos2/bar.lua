--[[
	BBar.lua - A movable, scalable, container frame
--]]

BBar = CreateFrame("Frame")
local Bar_MT = {__index = BBar}

local STICKY_TOLERANCE = 16 --how close one frame must be to another to trigger auto anchoring
local PADDING = 2
local active = {}
local unused = {}
local ceil = math.ceil

--fade and unfade mouseover frames
local fadeChecker = CreateFrame("Frame")
fadeChecker.bars = {}
fadeChecker.nextUpdate = 0.1
fadeChecker:Hide()
fadeChecker:SetScript("OnUpdate", function(self, elapsed)
	if(self.nextUpdate < 0) then
		self.nextUpdate = 0.1
		for bar in pairs(self.bars) do
			if MouseIsOver(bar, 1, 1, 1, 1) then
				if(ceil(bar:GetAlpha()*100) == ceil(bar:GetFadeAlpha()*100)) then
					UIFrameFadeIn(bar, 0.1, bar:GetAlpha(), bar:GetFrameAlpha())
				end
			else
				if(ceil(bar:GetAlpha()*100) == ceil(bar:GetFrameAlpha()*100)) then
					UIFrameFadeOut(bar, 0.1, bar:GetAlpha(), bar:GetFadeAlpha())
				end
			end
		end
	else
		self.nextUpdate = self.nextUpdate - elapsed
	end
end)


--[[ Local Functions ]]--

--returns the adjusted x and y coordinates for a frame at the given scale
local function GetRelativeCoords(frame, scale)
	local ratio = frame:GetScale() / scale
	return (frame:GetLeft() or 0) * ratio, (frame:GetTop() or 0) * ratio
end

local function Bar_New(id, secure, strata)
	local bar
	if(secure) then
		bar = setmetatable(CreateFrame("Frame", nil, UIParent, "SecureStateHeaderTemplate"), Bar_MT)
	else
		bar = setmetatable(CreateFrame("Frame", nil, UIParent), Bar_MT)
	end
	if(strata) then
		bar:SetFrameStrata(strata)
	end

	bar.id = id
	bar.dragFrame = BDragFrame_New(bar)

	bar:SetClampedToScreen(true)
	bar:SetMovable(true)
	bar:SetSize(32)
	bar.isNew = true

	return bar
end

local function Bar_Restore(id)
	local bar = unused[id]
	if bar then
		unused[id] = nil
		return bar
	end
end


--[[ Usable Functions ]]--

function BBar:Create(id, OnCreate, OnDelete, defaults, strata, secure)
	local id = tonumber(id) or id
	assert(id, "id expected")
	assert(not active[id], format("BBar \"%s\" is already in use", id))

	local bar = Bar_Restore(id) or Bar_New(id, secure, strata)
	bar.OnDelete = OnDelete

	bar:LoadSettings(defaults)
	if(bar.isNew) then
		if(OnCreate) then
			OnCreate(bar)
		end
		bar.isNew = nil
	end

	active[id] = bar

	return bar
end

function BBar:CreateHeader(id, OnCreate, OnDelete, defaults, strata)
	return self:Create(id, OnCreate, OnDelete, defaults, strata, true)
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

	if(deleteSettings) then
		Bongos:SetBarSets(self.id, nil)
	end

	fadeChecker.bars[self] = nil
	if not next(fadeChecker.bars) then
		fadeChecker:Hide()
	end

	unused[self.id] = self
end


--[[ Settings Loading ]]--

function BBar:LoadSettings(defaults)
	self.sets = Bongos:GetBarSets(self.id) or Bongos:SetBarSets(self.id, defaults or {})
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
	self:UpdateFadeChecker()
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

--scale
function BBar:SetFrameScale(scale, scaleAnchored)
	local x, y = GetRelativeCoords(self, scale)

	self:SetScale(scale)
	self.dragFrame:SetScale(scale)
	self:ClearAllPoints()
	self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
	self:Reanchor()
	self:SavePosition()

	if(scaleAnchored and Bongos:IsSticky()) then
		for _,frame in self:GetAll() do
			if frame:GetAnchor() == self then
				frame:SetFrameScale(scale, true)
			end
		end
	end
end

--opacity
function BBar:UpdateAlpha()
	self:SetAlpha((MouseIsOver(self) and self:GetFrameAlpha()) or self:GetFadeAlpha())
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
	if(alpha == 1) then
		self.sets.fadeAlpha = nil
	else
		self.sets.fadeAlpha = alpha
	end

	self:UpdateFadeChecker()
	self:UpdateAlpha()
end

--returns fadedOpacity, fadePercentage
--fadedOpacity is what opacity the bar will be at when faded
--fadedPercentage is what modifier we use on normal opacity
function BBar:GetFadeAlpha(alpha)
	local fadeAlpha = self.sets.fadeAlpha or 1
	return fadeAlpha * self:GetFrameAlpha(), fadeAlpha
end


--[[ Attach an object to the frame ]]--

function BBar:Attach(frame)
	frame:SetFrameStrata(self:GetFrameStrata())
	frame:SetParent(self)
	frame:SetFrameLevel(0)
end


--[[ Visibility ]]--

function BBar:ShowFrame()
	self.sets.hidden = nil
	self:Show()
	self:UpdateFadeChecker()
	self.dragFrame:UpdateColor()
end

function BBar:HideFrame()
	self.sets.hidden = true
	self:Hide()
	self:UpdateFadeChecker()
	self.dragFrame:UpdateColor()
end

function BBar:FrameIsShown()
	return not self.sets.hidden
end

function BBar:ToggleFrame()
	if self:FrameIsShown() then
		self:HideFrame()
	else
		self:ShowFrame()
	end
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

--place the frame at it"s saved position
function BBar:Reposition()
	local x, y = self.sets.x, self.sets.y
	self:Rescale()

	if x and y then
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
		self:SetUserPlaced(true)
	end
end

function BBar:Rescale()
	self:SetScale(self.sets.scale or 1)
	self.dragFrame:SetScale(self.sets.scale or 1)
end

--try to reanchor the frame
function BBar:Reanchor()
	local frame, point = self:GetAnchor()

	if not(frame and Bongos:IsSticky() and FlyPaper.StickToPoint(self, frame, point, PADDING, PADDING)) then
		self.sets.anchor = nil

		local x, y = GetRelativeCoords(self, self:GetScale())
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
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
		local menu
		if self.CreateMenu then
			menu = self:CreateMenu()
		else
			menu = BongosMenu:CreateMenu(self.id)
		end
		self.menu = menu
	end

	local menu = self.menu
	menu:SetFrameID(self.id)
	self:PlaceMenu(menu)
end

function BBar:PlaceMenu(menu)
	local dragFrame = self.dragFrame
	local ratio = UIParent:GetScale() / dragFrame:GetEffectiveScale()
	local x = dragFrame:GetLeft() / ratio
	local y = dragFrame:GetTop() / ratio

	menu:Hide()
	menu:ClearAllPoints()
	menu:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", x, y)
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
	assert(id and id ~= "", "Invalid barID")

	if id == "all" then
		self:ForAll(method, ...)
	else
		local startID, endID = id:match("(%d+)-(%d+)")
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

--run the fade onupdate checker if only if there are mouseover frames to check
function BBar:UpdateFadeChecker()
	if(self.sets.hidden) then
		fadeChecker.bars[self] = nil
	else
		if(select(2, self:GetFadeAlpha()) == 1) then
			fadeChecker.bars[self] = nil
		else
			fadeChecker.bars[self] = true
		end
	end

	if next(fadeChecker.bars) then
		fadeChecker:Show()
	else
		fadeChecker:Hide()
	end
end