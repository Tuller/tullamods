--[[
	frameSettings.lua
		A bagnon frame settings object
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local FrameSettings = {}
Bagnon.FrameSettings = FrameSettings


--[[---------------------------------------------------------------------------
	Constructorish
--]]---------------------------------------------------------------------------

FrameSettings.mt = {
	__index = FrameSettings
}

FrameSettings.objects = {}


local function frameSettings_Create(self, id)
	local obj = {
		frameID = id,
		bagSlots = {},
		hiddenBagSlots = {},
	}

	obj = setmetatable(obj, self.mt)
	obj:RegisterMessages()
	return obj
end

function FrameSettings:Get(id)
	local obj = self.objects[id]
	if not obj then
		obj = frameSettings_Create(self, id)
		self.objects[id] = obj
	end

	return obj
end


--[[---------------------------------------------------------------------------
	Message Passing
--]]---------------------------------------------------------------------------

FrameSettings.messages = {
	'PLAYER_UPDATE',
	'BAGS_UPDATE',
	'FRAME_SHOW',
	'FRAME_HIDE',
	'BAG_FRAME_SHOW',
	'BAG_FRAME_HIDE',
	'BAG_SLOT_SHOW',
	'BAG_SLOT_HIDE',
	'TEXT_SEARCH_ENABLE',
	'TEXT_SEARCH_DISABLE',
	'TEXT_SEARCH_UPDATE'
}

function FrameSettings:SendMessage(msg, ...)
	Bagnon.Callbacks:SendMessage(msg, self:GetFrameID(), ...)
end

function FrameSettings:HandleMessage(msg, frameID, ...)
	if self:GetFrameID() == frameID then
		local method = self[msg]
		method(self, ...)
	end
end

function FrameSettings:RegisterMessages()
	for i, message in pairs(self.messages) do
		Bagnon.Callbacks:Listen(self, message, 'HandleMessage')
	end
end


--[[---------------------------------------------------------------------------
	Events/Messages
--]]---------------------------------------------------------------------------

--frame display
function FrameSettings:FRAME_SHOW()
	self:ShowFrame()
end

function FrameSettings:FRAME_HIDE()
	self:HideFrame()
end

--bag frame display
function FrameSettings:BAG_FRAME_SHOW()
	self:ShowBagFrame()
end

function FrameSettings:BAG_FRAME_HIDE()
	self:HideBagFrame()
end

--individual bag display
function FrameSettings:BAG_SLOT_SHOW(slot)
	if self:HasBagSlot(slot) then
		self:ShowBagSlot(slot)
	end
end

function FrameSettings:BAG_SLOT_HIDE(slot)
	if self:HasBagSlot(slot) then
		self:HideBagSlot(slot)
	end
end

--searching
function FrameSettings:TEXT_SEARCH_ENABLE()
	self:EnableTextSearch()
end

function FrameSettings:TEXT_SEARCH_DISABLE()
	self:DisableTextSearch()
end

function FrameSettings:TEXT_SEARCH_UPDATE(search)
	if self:IsTextSearchEnabled() then
		self:SetTextSearch(search)
	end
end

--player filtering
function FrameSettings:PLAYER_UPDATE(player)
	self:SetPlayerFilter(player)
end

--bag filtering
--[[
function FrameSettings:BAGS_UPDATE(...)
	self:SetBagSlots(...)
end
--]]


--[[---------------------------------------------------------------------------
	Update Methods
--]]---------------------------------------------------------------------------


--[[ Frame Visibility ]]--

function FrameSettings:ShowFrame()
	if not self:IsFrameShown() then
		self.showFrame = true
		self:SendMessage('FRAME_SHOW')
	end
end

function FrameSettings:HideFrame()
	if self:IsFrameShown() then
		self.showFrame = false
		self:SendMessage('FRAME_HIDE')
	end
end

function FrameSettings:ToggleFrame()
	if self:IsFrameShown() then
		self:HideFrame()
	else
		self:ShowFrame()
	end
end

function FrameSettings:IsFrameShown()
	return self.showFrame or false
end


--[[ Frame Layout ]]--

--scale
function FrameSettings:SetFrameScale(scale)
	if self:GetScale() ~= scale then
		Bagnon.SavedSettings:SetFrameScale(self:GetFrameID(), scale)
		self:SendMessage('FRAME_SCALE_UPDATE', scale)
	end
end

function FrameSettings:GetFrameScale()
	return Bagnon.SavedSettings:GetFrameScale(self:GetFrameID())
end

--opacity
function FrameSettings:SetFrameOpacity(opacity)
	if self:GetOpacity() ~= opacity then
		Bagnon.SavedSettings:SetFrameOpacity(self:GetFrameID(), opacity)
		self:SendMessage('FRAME_OPACITY_UPDATE', opacity)
	end
end

function FrameSettings:GetFrameOpacity()
	return Bagnon.SavedSettings:GetFrameOpacity(self:GetFrameID())
end

--position
function FrameSettings:SetFramePosition(point, x, y)
	local oPoint, oX, oY = self:GetFramePosition()
	if not(point == oPoint and x == oX and y == oY) then
		Bagnon.SavedSettings:SetFramePosition(self:GetFrameID(), point, x, y)
		self:SendMessage('FRAME_POSITION_UPDATE', point, x, y)
	end
end

function FrameSettings:GetFramePosition()
	return Bagnon.SavedSettings:GetFramePosition(self:GetFrameID())
end

--frame color
function FrameSettings:SetFrameColor(r, g, b, a)
	local pR, pG, pB, pA = self:GetFrameColor()

	if not(pR == r and pG == g and pB == b and pA == a) then
		Bagnon.SavedSettings:SetFrameColor(self:GetFrameID(), r, g, b, a)
		self:SendMessage('FRAME_COLOR_UPDATE', r, g, b, a)
	end
end

function FrameSettings:GetFrameColor()
	return Bagnon.SavedSettings:GetFrameColor(self:GetFrameID())
end

--border color
function FrameSettings:SetFrameBorderColor(r, g, b, a)
	local pR, pG, pB, pA = self:GetFrameBorderColor()

	if not(pR == r and pG == g and pB == b and pA == a) then
		Bagnon.SavedSettings:SetFrameBorderColor(self:GetFrameID(), r, g, b, a)
		self:SendMessage('FRAME_BORDER_COLOR_UPDATE', r, g, b, a)
	end
end

function FrameSettings:GetFrameBorderColor()
	return Bagnon.SavedSettings:GetFrameBorderColor(self:GetFrameID())
end


--[[ Frame Components ]]--

--returns true if the frame has a bag frame, and false otherwise
function FrameSettings:FrameHasBagFrame()
	return Bagnon.SavedSettings:DoesFrameHaveBagFrame(self:GetFrameID())
end

--returns true if the frame has a money frame, and false otherwise
function FrameSettings:FrameHasMoneyFrame()
	return Bagnon.SavedSettings:DoesFrameHaveMoneyFrame(self:GetFrameID())
end

--returns true if the frame has a databroker object frame, and false otherwise
function FrameSettings:FrameHasDBOFrame()
	return Bagnon.SavedSettings:DoesFrameHaveDBOFrame(self:GetFrameID())
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


--[[ Bag Frame Layout ]]--

--spacing
function FrameSettings:SetBagFrameSpacing(spacing)
	if self:GetBagFrameSpacing() ~= spacing then
		self.bagFrameSpacing = spacing
		self:SendMessage('BAG_FRAME_SPACING_UPDATE', spacing)
	end
end

function FrameSettings:GetBagFrameSpacing()
	return self.bagFrameSpacing or 4
end

--padding
function FrameSettings:SetBagFramePadding(padding)
	if self:GetBagFramePadding() ~= padding then
		self.bagFramepadding = padding
		self:SendMessage('BAG_FRAME_PADDING_UPDATE', self:GetBagFramePadding())
	end
end

function FrameSettings:GetBagFramePadding()
	return self.bagFramePadding or 0
end


--[[ Item Frame Layout ]]--

function FrameSettings:SetItemFrameSpacing(spacing)
	if self:GetItemFrameSpacing() ~= spacing then
		Bagnon.SavedSettings:SetItemFrameSpacing(self:GetFrameID(), spacing)
		self:SendMessage('ITEM_FRAME_SPACING_UPDATE', self:GetItemFrameSpacing())
	end
end

function FrameSettings:GetItemFrameSpacing()
	return Bagnon.SavedSettings:GetItemFrameSpacing(self:GetFrameID())
end

function FrameSettings:SetItemFrameColumns(columns)
	if self:GetItemFrameColumns() ~= columns then
		Bagnon.SavedSettings:SetItemFrameColumns(self:GetFrameID(), columns)
		self:SendMessage('ITEM_FRAME_COLUMNS_UPDATE', self:GetItemFrameColumns())
	end
end

function FrameSettings:GetItemFrameColumns()
	return Bagnon.SavedSettings:GetItemFrameColumns(self:GetFrameID())
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
	return ipairs(Bagnon.SavedSettings:GetFrameBags(self:GetFrameID()))
end


--[[ Bag Slot Visibility ]]--

function FrameSettings:ShowBagSlot(slotToShow)
	if not self:IsBagSlotShown(slotToShow) then
		Bagnon.SavedSettings:ShowFrameBag(self:GetFrameID(), slotToShow)
		self:SendMessage('BAG_SLOT_SHOW', slotToShow)
	end
end

function FrameSettings:HideBagSlot(slotToHide)
	if self:IsBagSlotShown(slotToHide) then
		Bagnon.SavedSettings:HideFrameBag(self:GetFrameID(), slotToHide)
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

--returns an iteratior for all bag slots marked as hidden for this frame
function FrameSettings:GetHiddenBagSlots()
	return ipairs(Bagnon.SavedSettings:GetHiddenBags(self:GetFrameID()))
end

--returns an iterator for all bag slots that are available to this frame and marked as visible
local function visibleSlotIterator(obj, i)
	local bagSlots = Bagnon.SavedSettings:GetFrameBags(obj:GetFrameID())
	for j = i + 1, #bagSlots do
		local slot = bagSlots[j]
		local found = false

		for _, hiddenSlot in obj:GetHiddenBags() do
			if hiddenSlot == slot then
				found = true
				break
			end
		end

		if slot and not found then
			return j, slot
		end
	end
end

function FrameSettings:GetVisibleBagSlots()
	return visibleSlotIterator, self, 0
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


--[[ Accessor Methods ]]--

function FrameSettings:GetFrameID()
	return self.frameID
end