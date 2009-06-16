--[[
	frameSettings.lua
		A bagnon frame settings object
--]]

local FrameSettings = {}
local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
Bagnon.FrameSettings = FrameSettings


--[[---------------------------------------------------------------------------
	Constructorish
--]]---------------------------------------------------------------------------

FrameSettings.mt = {
	__index = FrameSettings
}

FrameSettings.objects = setmetatable({}, {__index = function(tbl, id)
	local obj = setmetatable({frameID = id, frameShown = 0}, FrameSettings.mt)
	tbl[id] = obj
	return obj
end})

function FrameSettings:Get(id)
	return self.objects[id]
end


--[[---------------------------------------------------------------------------
	Accessor Methods
--]]---------------------------------------------------------------------------


function FrameSettings:GetFrameID()
	return self.frameID
end

function FrameSettings:GetDB()
	return Bagnon.SavedFrameSettings:Get(self:GetFrameID())
--[[
	local db = self.db or Bagnon.SavedFrameSettings:Get(self:GetFrameID())
	self.db = db
	return db
--]]
end


--[[---------------------------------------------------------------------------
	Message Passing
--]]---------------------------------------------------------------------------

function FrameSettings:SendMessage(msg, ...)
	Bagnon.Callbacks:SendMessage(msg, self:GetFrameID(), ...)
end


--[[---------------------------------------------------------------------------
	Update Methods
--]]---------------------------------------------------------------------------


--[[ Frame Visibility ]]--

--the logic here is a little wacky, since we deal with auto open/close events
--if a frame was manually opened, then it should only be closable manually
function FrameSettings:ShowFrame()
	local wasShown = self:IsFrameShown()
	
	self.frameShown = (self.frameShown or 0) + 1

	if not wasShown then
		self:SendMessage('FRAME_SHOW')
	end
end

function FrameSettings:HideFrame(forceHide)
	self.frameShown = (self.frameShown or 1) - 1

	if forceHide or self.frameShown <= 0 then
		self.frameShown = 0
		self:SendMessage('FRAME_HIDE')
	end
end

function FrameSettings:ToggleFrame()
	if self:IsFrameShown() then
		self:HideFrame(true)
	else
		self:ShowFrame()
	end
end

function FrameSettings:IsFrameShown()
	return (self.frameShown or 0) > 0
end


--[[ Frame Position ]]--

--position
function FrameSettings:SetFramePosition(point, x, y)
	local oPoint, oX, oY = self:GetFramePosition()
	
	if not(point == oPoint and x == oX and y == oY) then
		self:GetDB():SetPosition(point, x, y)
		self:SendMessage('FRAME_POSITION_UPDATE', self:GetFramePosition())
	end
end

function FrameSettings:GetFramePosition()
	local point, x, y = self:GetDB():GetPosition()
	return point, x, y
end

function FrameSettings:IsMovable()
	return not Bagnon.Settings:AreFramePositionsLocked()
end


--[[ Frame Layout ]]--

--scale
function FrameSettings:SetFrameScale(scale)
	if self:GetFrameScale() ~= scale then
		self:GetDB():SetScale(scale)
		self:SendMessage('FRAME_SCALE_UPDATE', self:GetFrameScale())
	end
end

function FrameSettings:GetFrameScale()
	return self:GetDB():GetScale()
end

--opacity
function FrameSettings:SetFrameOpacity(opacity)
	if self:GetFrameOpacity() ~= opacity then
		self:GetDB():SetOpacity(opacity)
		self:SendMessage('FRAME_OPACITY_UPDATE', self:GetFrameOpacity())
	end
end

function FrameSettings:GetFrameOpacity()
	return self:GetDB():GetOpacity()
end

--frame color
function FrameSettings:SetFrameColor(r, g, b, a)
	local pR, pG, pB, pA = self:GetFrameColor()

	if not(pR == r and pG == g and pB == b and pA == a) then
		self:GetDB():SetColor(r, g, b, a)
		self:SendMessage('FRAME_COLOR_UPDATE', self:GetFrameColor())
	end
end

function FrameSettings:GetFrameColor()
	return self:GetDB():GetColor()
end

--border color
function FrameSettings:SetFrameBorderColor(r, g, b, a)
	local pR, pG, pB, pA = self:GetFrameBorderColor()

	if not(pR == r and pG == g and pB == b and pA == a) then
		self:GetDB():SetBorderColor(r, g, b, a)
		self:SendMessage('FRAME_BORDER_COLOR_UPDATE', self:GetFrameBorderColor())
	end
end

function FrameSettings:GetFrameBorderColor()
	return self:GetDB():GetBorderColor()
end


--[[ Frame Components ]]--

--returns true if the frame has a bag frame, and false otherwise
function FrameSettings:FrameHasBagFrame()
	return self:GetDB():HasBagFrame()
end

--returns true if the frame has a money frame, and false otherwise
function FrameSettings:FrameHasMoneyFrame()
	return self:GetDB():HasMoneyFrame()
end

--returns true if the frame has a databroker object frame, and false otherwise
function FrameSettings:FrameHasDBOFrame()
	return self:GetDB():HasDBOFrame()
end

function FrameSettings:HasSearchFrame()
	return self:GetFrameID() ~= 'keys'
end


--[[ Broker Display Object ]]--

function FrameSettings:SetBrokerDisplayObject(objectName)
	if self:GetBrokerDisplayObject() ~= objectName then
		self:GetDB():SetBrokerDisplayObject(objectName)
		self:SendMessage('DATABROKER_OBJECT_UPDATE', self:GetBrokerDisplayObject())
	end
end

function FrameSettings:GetBrokerDisplayObject()
	return self:GetDB():GetBrokerDisplayObject()
end

--[[ Bag Frame Visibility ]]--

function FrameSettings:ShowBagFrame()
	if not self:IsBagFrameShown() then
		self.showBagFrame = true
		self:SendMessage('BAG_FRAME_SHOW')
	end
end

function FrameSettings:HideBagFrame()
	if self:IsBagFrameShown() then
		self.showBagFrame = false
		self:SendMessage('BAG_FRAME_HIDE')
	end
end

function FrameSettings:ToggleBagFrame()
	if self:IsBagFrameShown() then
		self:HideBagFrame()
	else
		self:ShowBagFrame()
	end
end

function FrameSettings:IsBagFrameShown()
	return self.showBagFrame
end


--[[ Item Frame Layout ]]--

--spacing
function FrameSettings:SetItemFrameSpacing(spacing)
	if self:GetItemFrameSpacing() ~= spacing then
		self:GetDB():SetItemFrameSpacing(spacing)
		self:SendMessage('ITEM_FRAME_SPACING_UPDATE', self:GetItemFrameSpacing())
	end
end

function FrameSettings:GetItemFrameSpacing()
	return self:GetDB():GetItemFrameSpacing()
end

--columns
function FrameSettings:SetItemFrameColumns(columns)
	if self:GetItemFrameColumns() ~= columns then
		self:GetDB():SetItemFrameColumns(columns)
		self:SendMessage('ITEM_FRAME_COLUMNS_UPDATE', self:GetItemFrameColumns())
	end
end

function FrameSettings:GetItemFrameColumns()
	return self:GetDB():GetItemFrameColumns()
end


--[[ Bag Slot Availability ]]--

--returns true if the slot is available to this frame, and false otherwise
function FrameSettings:HasBagSlot(slot)
	for i, bagSlot in self:GetBagSlots() do
		if bagSlot == slot then
			return true
		end
	end
	return false
end

--returns an iterator for all bag slots available to this frame
function FrameSettings:GetBagSlots()
	return ipairs(self:GetDB():GetBags())
end


--[[ Bag Slot Visibility ]]--

function FrameSettings:ShowBagSlot(slotToShow)
	if not self:IsBagSlotShown(slotToShow) then
		self:GetDB():ShowBag(slotToShow)
		self:SendMessage('BAG_SLOT_SHOW', slotToShow)
	end
end

function FrameSettings:HideBagSlot(slotToHide)
	if self:IsBagSlotShown(slotToHide) then
		self:GetDB():HideBag(slotToHide)
		self:SendMessage('BAG_SLOT_HIDE', slotToHide)
	end
end

function FrameSettings:ToggleBagSlot(slot)
	if self:IsBagSlotShown(slot) then
		self:HideBagSlot(slot)
	else
		self:ShowBagSlot(slot)
	end
end

function FrameSettings:IsBagSlotShown(slot)
	for i, bagSlot in self:GetVisibleBagSlots() do
		if bagSlot == slot then
			return true
		end
	end
	return false
end

function FrameSettings:IsBagSlotHidden(slot)
	for i, bagSlot in self:GetHiddenBagSlots() do
		if bagSlot == slot then
			return true
		end
	end
	return false
end

--returns an iteratior for all bag slots marked as hidden for this frame
function FrameSettings:GetHiddenBagSlots()
	return ipairs(self:GetDB():GetHiddenBags())
end


--[[ Bag Slot Iterators ]]--

--returns an iterator for all bag slots that are available to this frame and marked as visible
local function reverseVisibleSlotIterator(obj, i)
	local bagSlots = obj:GetDB():GetBags()
	local nextSlot = i - 1

	for j = nextSlot, 1, -1 do
		local slot = bagSlots[j]
		if not obj:IsBagSlotHidden(slot) then
			return j, slot
		end
	end
end

local function visibleSlotIterator(obj, i)
	local bagSlots = obj:GetDB():GetBags()
	local nextSlot = i + 1

	for j = nextSlot, #bagSlots do
		local slot = bagSlots[j]
		if not obj:IsBagSlotHidden(slot) then
			return j, slot
		end
	end
end

function FrameSettings:GetVisibleBagSlots()
	if self:IsSlotOrderReversed() then
		local bagSlots = self:GetDB():GetBags()
		return reverseVisibleSlotIterator, self, #bagSlots + 1
	end
	return visibleSlotIterator, self, 0
end


function FrameSettings:IsSlotOrderReversed()
	return Bagnon.Settings:IsSlotOrderReversed()
end


--[[ Text Filtering ]]--

function FrameSettings:EnableTextSearch()
	if not self:IsTextSearchEnabled() then
		self.enableTextSearch = true
		self:SendMessage('TEXT_SEARCH_ENABLE')
	end
end

function FrameSettings:DisableTextSearch()
	if self:IsTextSearchEnabled() then
		self.enableTextSearch = false
		self:SendMessage('TEXT_SEARCH_DISABLE')
	end
end

function FrameSettings:ToggleTextSearch()
	if self:IsTextSearchEnabled() then
		self:DisableTextSearch()
	else
		self:EnableTextSearch()
	end
end

function FrameSettings:IsTextSearchEnabled()
	return self.enableTextSearch
end

function FrameSettings:SetTextSearch(search)
	if self:GetTextSearch() ~= search then
		self.textSearch = search or ''
		self:SendMessage('TEXT_SEARCH_UPDATE', self:GetTextSearch())
	end
end

function FrameSettings:GetTextSearch()
	return self.textSearch or ''
end


--[[ Bag Filtering ]]--

function FrameSettings:SetBagSearch(bagSlotID)
	if self:GetBagSearch() ~= bagSlotID then
		self.bagSearch = bagSlotID
		self:SendMessage('BAG_SEARCH_UPDATE', self:GetBagSearch())
	end
end

function FrameSettings:GetBagSearch()
	return self.bagSearch or false
end


--[[ Player Filtering ]]--

function FrameSettings:SetPlayerFilter(player)
	local currentFilter = self:GetPlayerFilter()
	if currentFilter ~= player then
		self.playerFilter = player
		self:SendMessage('PLAYER_UPDATE', self:GetPlayerFilter())
	end
end

function FrameSettings:GetPlayerFilter()
	return self.playerFilter or UnitName('player')
end