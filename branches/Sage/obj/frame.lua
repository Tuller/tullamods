--[[
	SageFrame.lua - A movable, scalable, container frame
--]]

SageFrame = CreateFrame("Frame")
local Frame_MT = {__index = SageFrame}

local STICKY_TOLERANCE = 16 --how close one frame must be to another to trigger auto anchoring
local PADDING = 2
local active = {}
local unused = {}


--[[ Local Functions ]]--

--returns the adjusted x and y coordinates for a frame at the given scale
local function GetRelativeCoords(frame, scale)
	local ratio = frame:GetScale() / scale
	return (frame:GetLeft() or 0) * ratio, (frame:GetTop() or 0) * ratio
end

local function Frame_New(id)
	local frame = setmetatable(CreateFrame("Frame", nil, UIParent, "SecureStateHeaderTemplate"), Frame_MT)
	frame:SetFrameStrata("LOW")
	frame.id = id
	frame.dragFrame = SDragFrame_New(frame)
	frame.click = SageClick:Create(frame)

	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:SetSize(32)
	frame.isNew = true

	return frame
end

local function Frame_Restore(id)
	local frame = unused[id]
	if frame then
		unused[id] = nil
		return frame
	end
end


--[[ Usable Functions ]]--

function SageFrame:Create(id, OnCreate, defaults, hasHeader)
	local id = tonumber(id) or id
	assert(id, "id expected")
	assert(not active[id], format("SageFrame \"%s\" is already in use", id))

	local frame = Frame_Restore(id) or Frame_New(id)

	frame:LoadSettings(defaults)
	if(frame.isNew) then
		if(OnCreate) then
			OnCreate(frame)
		end
		frame.isNew = nil
	end
	frame:SetAttribute("unit", id)

	frame.hasHeader = hasHeader
	RegisterUnitWatch(frame)
	if(UnitExists(id)) then
		frame:Show()
	end

	active[id] = frame

	return frame
end

function SageFrame:Destroy()
	active[self.id] = nil

	self.sets = nil
	self.dragFrame:Hide()
	self:ClearAllPoints()
	self:SetUserPlaced(false)
	self:Hide()

	UnregisterUnitWatch(self)

	unused[self.id] = self
end


--[[ Settings Loading ]]--

function SageFrame:LoadSettings(defaults)
	self.sets = Sage:GetFrameSets(self.id) or Sage:SetFrameSets(self.id, defaults or {})
	self:SetFrameAlpha(self.sets.alpha)
	self:Reposition()

	if Sage:IsLocked() then
		self:Lock()
	else
		self:Unlock()
	end
end


--[[ Lock/Unlock ]]--

function SageFrame:Lock()
	self.click:EnableMouse(true)
	self.dragFrame:Hide()
end

function SageFrame:Unlock()
	self.click:EnableMouse(false)
	self.dragFrame:Show()
end


--[[ Frame Attributes ]]--

--laziness function on my part
function SageFrame:SetSize(x, y)
	self:SetWidth(x)
	self:SetHeight(y or x)
end

function SageFrame:SetFrameScale(scale, scaleAnchored)
	local x, y = GetRelativeCoords(self, scale)

	self:SetScale(scale)
	self:ClearAllPoints()
	self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
	self:Reanchor()
	self:SavePosition()

	if(scaleAnchored and Sage:IsSticky()) then
		for _,frame in self:GetAll() do
			if frame:GetAnchor() == self then
				frame:SetFrameScale(scale, true)
			end
		end
	end
end

function SageFrame:SetFrameAlpha(alpha)
	if alpha == 1 then
		self.sets.alpha = nil
	else
		self.sets.alpha = alpha
	end
	self:SetAlpha(alpha or 1)
end

function SageFrame:GetFrameAlpha()
	return self.sets.alpha or 1
end

function SageFrame:Attach(frame)
	frame:SetFrameStrata(self:GetFrameStrata())
	frame:SetParent(self)
	frame:SetAlpha(1)
	frame:SetFrameLevel(0)
end

function SageFrame:SetFrameWidth(width)
	self.sets.width = width

	local info = SageInfo:Get(self.id)
	if info then
		info:UpdateWidth()
	end
end

function SageFrame:GetFrameWidth()
	return self.sets.width or 0
end


--[[ Positioning ]]--

function SageFrame:Stick()
	if Sage:IsSticky() then
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

function SageFrame:SavePosition()
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
function SageFrame:Reposition()
	local x, y = self.sets.x, self.sets.y
	self:Rescale()

	if x and y then
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
		self:SetUserPlaced(true)
	end
end

function SageFrame:Rescale()
	self:SetScale(self.sets.scale or 1)
end

--try to reanchor the frame
function SageFrame:Reanchor()
	local frame, point = self:GetAnchor()

	if not(frame and Sage:IsSticky() and FlyPaper.StickToPoint(self, frame, point, PADDING, PADDING)) then
		self.sets.anchor = nil

		local x, y = GetRelativeCoords(self, self:GetScale())
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
		self:SetUserPlaced(true)
	end
	self.dragFrame:UpdateColor()
end

function SageFrame:GetAnchor()
	local anchorString = self.sets.anchor
	if anchorString then
		local pointStart = #anchorString - 1
		return self:Get(anchorString:sub(1, pointStart - 1)), anchorString:sub(pointStart)
	end
end


--[[ Metafunctions ]]--

function SageFrame:Get(id)
	return active[tonumber(id) or id]
end

function SageFrame:GetAll()
	return pairs(active)
end

function SageFrame:ForAll(method, ...)
	for _, frame in self:GetAll() do
		local action = frame[method]
		if action then
			action(frame, ...)
		end
	end
end

--takes a frameID, and performs the specified action on that frame
--this adds two special IDs, "all" for all frames and number-number for a range of IDs
function SageFrame:ForFrame(id, method, ...)
	assert(id and id ~= "", "Invalid frameID")

	if id == "all" then
		self:ForAll(method, ...)
	elseif(id == "party") then
		for i = 1, 4 do
			local frame = self:Get("party"..i)
			if(frame) then
				local action = frame[method]
				if(action) then
					action(frame, ...)
				end
			end
		end
	else
		local s, e = id:match("(%d+)-(%d+)")
		s = tonumber(s)
		e = tonumber(e)

		if s and e then
			for i = min(s, e), max(s, e) do
				local frame = self:Get(i)
				if frame then
					local action = frame[method]
					if action then
						action(frame, ...)
					end
				end
			end
		else
			local frame = self:Get(tonumber(id) or id)
			if frame then
				local action = frame[method]
				if action then
					action(frame, ...)
				end
			end
		end
	end
end

--[[ Config Functions ]]--

function SageFrame:SetShowCurable(enable)
	self.sets.showCurable = enable or nil
	
	local debuffs = SageBuff:Get(self.id, true)
	if(debuffs) then debuffs:Update() end
	
	local health = SageHealth:Get(self.id)
	if(health) then health:UpdateAll() end
end

function SageFrame:SetShowCastable(enable)
	self.sets.showCastable = enable or nil
	
	local buffs = SageBuff:Get(self.id)
	if(buffs) then buffs:Update() end
end

function SageFrame:SetShowCombatText(enable)
	self.sets.showCombatText = enable or nil

	if enable then
		SageCombat:Register(self)
	else
		SageCombat:Unregister(self)
	end
end

function SageFrame:SetTextMode(mode)
	self.sets.textMode = mode
	SageBar:SetTextMode(self.id, mode)
end