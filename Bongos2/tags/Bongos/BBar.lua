--[[
	BBar
		A movable container for things
--]]

BBar = CreateFrame('Frame')
local Frame_mt = {__index = BBar}


--[[ Locals ]]--

local STICKY_TOLERANCE = 16 --how close one frame must be to another to trigger auto anchoring
local PADDING = 2
local frames = {} 			--any frames currently in use
local deleted = {} 			--any frames that have been deleted


local function Frame_GetDeleted(id)
	local frame = deleted[id]
	if frame then
		deleted[id] = nil
		frame:SetParent(UIParent)
		frame.id = id
	end
	return frame
end

local function Frame_Create(id, template)
	local frame = CreateFrame('Frame', nil, UIParent, template)
	setmetatable(frame, Frame_mt)

	frame.id = id
	frame.created = true
	frame.dragFrame = BDragFrame_Add(frame)

	frame:SetClampedToScreen(true)
	frame:SetMovable(true)

	return frame
end

--returns the adjusted x and y coordinates for a frame at the given scale
local function GetRelativeCoords(frame, scale)
	local ratio = frame:GetScale() / scale
	return frame:GetLeft() * ratio, frame:GetTop() * ratio
end


--[[ Constructor/Destructor ]]--

function BBar.Create(id, OnCreate, OnDelete, template)
	assert(id, 'No unit given')

	local frame = Frame_GetDeleted(id) or Frame_Create(id, template)
	frame.OnDelete = OnDelete
	frame:LoadSettings()
	frames[id] = frame

	if frame.created then
		if OnCreate then
			OnCreate(frame)
		end
		frame.created = nil
	end
	return frame
end

function BBar:Delete()
	if self.OnDelete then
		self:OnDelete()
	end

	Bongos.SetBarSets(self.id, nil)
	self.sets = nil

	frames[self.id] = nil
	deleted[self.id] = self

	self:SetParent(nil)
	self:ClearAllPoints()
	self:SetUserPlaced(false)
	self.dragFrame:Hide()
	SeeQ:HideFrame(self)

	BBar.ForAll(BBar.Reanchor)
end

function BBar:LoadSettings()
	self.sets = Bongos.GetBarSets(self.id) or Bongos.SetBarSets(self.id, {vis = 1})
	self:SetFrameOpacity(self.sets.alpha)
	self:Reposition()

	if self.sets.vis then
		self:ShowFrame()
	else
		self:HideFrame()
	end

	if Bongos.IsLocked() then
		self:Lock()
	else
		self:Unlock()
	end
end

function BBar:Attach(frame)
	frame:SetParent(self)
	frame:SetAlpha(self:GetAlpha())
	frame:SetFrameLevel(0)
end


--[[ Movement ]]--

function BBar:Lock()
	self.dragFrame:Hide()
end

function BBar:Unlock()
	self.dragFrame:Show()
end


--[[ Visibility ]]--

function BBar:ShowFrame()
	self.sets.vis = 1
	self:Show()
	self.dragFrame:UpdateColor()
end

function BBar:HideFrame()
	self.sets.vis = nil
	self:Hide()
	self.dragFrame:UpdateColor()
end

function BBar:ToggleFrame()
	if self:IsShown() then
		self:HideFrame()
	else
		self:ShowFrame()
	end
end


--[[ Scale and Opacity ]]--

--Sets <frame>'s scale <scale>, and repositions the frame if its out of the viewable screen area
function BBar:SetFrameScale(scale)
	local x, y = GetRelativeCoords(self, scale)

	self:SetScale(scale)
	self:ClearAllPoints()
	self:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x, y)
	self:Reanchor()
	self:SavePosition()
end

function BBar:SetFrameOpacity(alpha)
	if alpha == 1 then
		self.sets.alpha = nil
	else
		self.sets.alpha = alpha
	end
	self:SetAlpha(alpha or 1)
end


--[[ Positioning ]]--

function BBar:Stick()
	if Bongos:IsSticky() then
		self.sets.anchor = nil

		for _, frame in BBar.GetAll() do
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

--place the frame at it's saved position
function BBar:Reposition()
	local x = self.sets.x
	local y = self.sets.y
	self:Rescale()

	if x and y then
		self:ClearAllPoints()
		self:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x, y)
		self:SetUserPlaced(true)
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
	end
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


--[[ Utility Functions ]]--

function BBar:DisplayMenu(menu)
	local dragFrame = self.dragFrame
	local ratio = UIParent:GetScale() / dragFrame:GetEffectiveScale()
	local x = dragFrame:GetLeft()
	local y = dragFrame:GetTop()

	menu:ClearAllPoints()
	menu:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", x  / ratio, y / ratio)
	menu:Show()
end

function BBar:GetSets()
	return self.sets
end

function BBar:GetAnchor()
	local anchorString = self.sets.anchor
	if anchorString then
		local pointStart = anchorString:len() - 1
		return BBar.Get(anchorString:sub(1, pointStart - 1)), anchorString:sub(pointStart)
	end
end

--returns true if <frame>, or one of the frames that <frame> is dependent on, is anchored to <otherFrame>.  Returns nil otherwise.
function BBar:IsDependent(frame)
	if self == frame then
		return true
	else
		for i = 1, self:GetNumPoints() do
			local parent = select(2, self:GetPoint(i))
			if parent and BBar.IsDependent(parent, frame) then
				return true
			end
		end
	end
	return false
end


--[[ Utility, non frame specific ]]--

function BBar.Get(id)
	return frames[tonumber(id) or id]
end

function BBar.GetSettings(id)
	local frame = BBar.Get(id)
	if frame then
		return frame.sets
	end
end

function BBar.GetAll()
	return pairs(frames)
end

function BBar.ForAll(action, ...)
	if type(action) == 'string' then
		for _,frame in BBar.GetAll() do
			frame[action](frame, ...)
		end
	else
		for _,frame in BBar.GetAll() do
			action(frame, ...)
		end
	end
end


--[[ Repositioning ]]--

BVent:AddAction('PLAYER_ENTERING_WORLD', function(action, event)
	BVent:RemoveAction(event, action)
	BBar.ForAll('Rescale') BBar.ForAll('Reanchor')
end)