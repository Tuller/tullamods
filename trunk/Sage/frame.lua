--[[
	SageFrame
		A unitframe container
--]]

SageFrame = CreateFrame('Frame')
local Frame_mt = {__index = SageFrame}


--[[ Locals ]]--

local STICKY_TOLERANCE = 16 --how close one frame must be to another to trigger auto anchoring
local PADDING = 2
local frames = {} 			--any frames currently in use
local deleted = {} 			--any frames that have been deleted

local function Frame_GetDeleted(id)
	local frame = deleted[id]
	if frame then
		deleted[id] = nil
		frame.id = id
		frame:SetParent(UIParent)
	end
	return frame
end

local function Frame_Create(id)
	local frame = CreateFrame('Frame', nil, UIParent, 'SecureFrameTemplate')
	setmetatable(frame, Frame_mt)

	frame.id = id
	frame.created = true
	frame.click = SageClick.Create(frame)

	frame:SetAttribute('unit', id)
	frame:SetFrameStrata('LOW')
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)

	RegisterUnitWatch(frame)
	SDragFrame_Add(frame)

	return frame
end

--returns the adjusted x and y coordinates for a frame at the given scale
local function GetRelativeCoords(frame, scale)
	local ratio = frame:GetScale() / scale
	return frame:GetLeft() * ratio, frame:GetTop() * ratio
end


--[[ Constructor/Destructor ]]--

function SageFrame.Create(id, OnCreate, OnDelete)
	assert(id, 'No unit given')
	
	local frame = Frame_GetDeleted(id) or Frame_Create(id)
	frame.OnDelete = OnDelete
	frame:LoadSettings()
	frames[id] = frame
	
	if frame.created then
		if OnCreate then
			OnCreate(frame)
		end
		frame.created = nil
	end

	RegisterUnitWatch(frame)
	return frame
end

function SageFrame:Delete()
	if self.OnDelete then
		self:OnDelete()
	end

	Sage.SetFrameSets(self.id, nil)
	self.sets = nil

	frames[self.id] = nil
	deleted[self.id] = self

	self:SetParent(nil)
	self:ClearAllPoints()
	self:SetUserPlaced(false)
	self.dragFrame:Hide()

	UnregisterUnitWatch(self)
	self:Hide()

	SageFrame.ForAll('Reanchor')
end

function SageFrame:LoadSettings()
	self.sets = Sage.GetFrameSets(self.id)
	self:SetFrameOpacity(self.sets.alpha)
	self:Reposition()

	if Sage.IsLocked() then
		self:Lock()
	else
		self:Unlock()
	end
end


--[[ Movement ]]--

function SageFrame:Lock()
	self.dragFrame:Hide()
end

function SageFrame:Unlock()
	self.dragFrame:Show()
end


--[[ Scale and Opacity ]]--

--Sets <frame>'s scale <scale>, and repositions the frame if its out of the viewable screen area
function SageFrame:SetFrameScale(scale)
	local x, y = GetRelativeCoords(self, scale)

	self:SetScale(scale)
	self:ClearAllPoints()
	self:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x, y)
	self:Reanchor()
	self:SavePosition()
end

function SageFrame:SetFrameOpacity(alpha)
	self:SetAlpha(alpha or 1)
	if alpha == 1 then
		self.sets.alpha = nil
	else
		self.sets.alpha = alpha
	end
end

function SageFrame:SetFrameWidth(width)
	self.sets.minWidth = width
	if self.info then
		self.info:UpdateWidth()
	end
end


--[[ Positioning ]]--

function SageFrame:Stick()
	if Sage.IsSticky() then
		self.sets.anchor = nil
		for _, frame in pairs(frames) do
			local point = FlyPaper.Stick(self, frame, STICKY_TOLERANCE, PADDING, PADDING)
			if point then
				self.sets.anchor = frame.id .. point
				break
			end
		end
	end

	self:SavePosition()
	SDragFrame_UpdateSticky(self.dragFrame)
end

--place the frame at it's saved position
function SageFrame:Reposition()
	local x = self.sets.x
	local y = self.sets.y

	self:SetScale(self.sets.scale or 1)
	if x and y then
		self:ClearAllPoints()
		self:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x, y)
		self:SetUserPlaced(true)
	end
end

function SageFrame:Rescale()
	self:SetScale(self.sets.scale or 1)
end

--try to reanchor the frame
function SageFrame:Reanchor()
	local frame, point = self:GetAnchor()

	if not(Sage.IsSticky() and frame and FlyPaper.StickToPoint(self, frame, point, PADDING, PADDING)) then
		self.sets.anchor = nil
	end
	SDragFrame_UpdateSticky(self.dragFrame)
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


--[[ Text ]]--

function SageFrame:ShowText(enable)
	if self.health then
		self.health:ShowText(enable)
	end
	if self.mana then
		self.mana:ShowText(enable)
	end
end

function SageFrame:ShowPercent(enable)
	if self.info then
		self.info:ShowPercent(enable)
	end
end


--[[ Utility Functions ]]--

function SageFrame:GetSets()
	return self.sets
end

function SageFrame:GetAnchor()
	local anchorString = self.sets.anchor
	if anchorString then
		local pointStart = anchorString:len() - 1
		return SageFrame.Get(anchorString:sub(1, pointStart - 1)), anchorString:sub(pointStart)
	end
end


--[[ Utility, non frame specific ]]--

function SageFrame.Get(id)
	return frames[id]
end

function SageFrame.GetSettings(id)
	local frame = SageFrame.Get(id)
	if frame then
		return frame.sets
	end
end

function SageFrame.GetAll()
	return pairs(frames)
end

function SageFrame.ForAll(action, ...)
	if type(action) == 'string' then
		for _,frame in SageFrame.GetAll() do
			frame[action](frame, ...)
		end
	else
		for _,frame in SageFrame.GetAll() do
			action(frame, ...)
		end
	end
end

--[[ Repositioning ]]--

BVent:AddAction('PLAYER_ENTERING_WORLD', function(action, event)
	BVent:RemoveAction(event, action)
	SageFrame.ForAll('Rescale') SageFrame.ForAll('Reanchor')
end)