--[[
	PocketFrame
		A container frame for categories, tabs, bags, money, and purchasing bags

	Each frame contains its own list of slots, index by what bag and what slot it is in
	The index, bag slot 0 is used to store size information about each bag.
--]]

PocketFrame = CreateFrame("Frame")
local Frame_MT = {__index = PocketFrame}
local util = PocketUtil
local ITEM_SIZE = PocketItem.SIZE

local bg = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 16,
	tile = true, tileSize = 16,
	insets = {left = 4, right = 4, top = 4, bottom = 4}
}

local function ToIndex(bag, slot)
	return (bag<0 and bag*100 - slot) or (bag*100 + slot)
end


--frame constructor
local function Frame_Create()
	local frame = setmetatable(CreateFrame("Frame", nil, UIParent), Frame_MT)
	frame.items = {}
	frame.count = 0
	frame.borderSize = 4
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	-- frame:SetScript("OnEnter", function(self, ...)
		-- Bongos:Print("enter", ...)
	-- end)
	-- frame:SetScript("OnLeave", function(self, ...)
		-- Bongos:Print("leave", ...)
	-- end)

	return frame
end


--[[ usable functions ]]--

function PocketFrame:New()
	local frame = Frame_Create()
	frame:SetScript("OnShow", function(self) self:OnShow() end)
	frame:Hide()

	return frame
end


--[[ frame events ]]--

function PocketFrame:SetRule(rule)
	self.rule = rule
	self:Regenerate()
end

function PocketFrame:OnShow()
	self:Regenerate()
end


--[[ Item Updating ]]--

function PocketFrame:AddItem(bag, slot)
	local index = ToIndex(bag, slot)
	local item = self.items[index]

	if item then
		item:Update()
	else
		self.items[index] = PocketItem:Get(self, bag, slot)
		self.count = self.count + 1
	end
end

function PocketFrame:RemoveItem(bag, slot, update)
	local index = ToIndex(bag, slot)
	local item = self.items[index]

	if item then
		item:Release()
		self.items[index] = nil
		self.count = self.count - 1
		if(update) then
			self:Layout()
		end
	end
end

function PocketFrame:UpdateSlot(bag, slot)
	if(self:HasItem(GetContainerItemLink(bag, slot))) then
		self:AddItem(bag, slot)
	else
		self:RemoveItem(bag, slot)
	end
end

function PocketFrame:UpdateSlotLock(bag, slot)
	local item = self.items[ToIndex(bag, slot)]
	if item then
		item:UpdateLock()
	end
end

function PocketFrame:UpdateSlotCooldown(bag, slot)
	local item = self.items[ToIndex(bag, slot)]
	if item then
		item:UpdateCooldown()
	end
end

function PocketFrame:Regenerate()
	for bag = 0, 4 do
		for slot = 1, util:GetBagSize(bag) do
			self:UpdateSlot(bag, slot)
		end
	end
	self:Layout()
end


--[[ layout ]]--

function PocketFrame:Layout()
	local borderSize = self.borderSize or 0
	local width, height = self:LayoutItems(ceil(self.count/4), 1, borderSize/2, borderSize/2)
	
	self:SetWidth(width+borderSize)
	self:SetHeight(height+borderSize)
end

function PocketFrame:LayoutItems(cols, space, offX, offY)
	if not next(self.items) then return 0, 0 end

	local itemSize = ITEM_SIZE + space
	local items = self.items
	local i = 0

	for bag = 0, 4 do
		for slot = 1, util:GetBagSize(bag) do
			local item = items[ToIndex(bag, slot)]
			if item then
				i = i + 1
				local row = mod(i-1, cols)
				local col = ceil(i/cols) - 1
				item:SetPoint("TOPLEFT", self, "TOPLEFT", itemSize*row + offX, -(itemSize*col + offY))
			end
		end
	end

	return itemSize*min(cols, i) - space, itemSize*ceil(i/cols) - space
end

local pt
function PocketFrame:HasItem(link)
	local rule = self.rule

	if(rule) then
		if(link) then
			pt = pt or (AceLibrary and AceLibrary:HasInstance("PeriodicTable-3.0") and AceLibrary("PeriodicTable-3.0"))
			if(pt and pt:ItemInSet(link, rule)) then
				return true
			end

			local name, _, quality, itemLevel, minLevel, type, subType, _, equipLoc = GetItemInfo(link)
			if rule and rule ~= type:lower() then
				if not(subType and subType:lower():find(rule)) then
					local equipLoc = getglobal(equipLoc)
					if not(equipLoc) or rule ~= equipLoc:lower() then
						if not name:lower():find(rule) then
							return false
						end
					end
				end
			end
			return true
		else
			return rule == "empty"
		end
	else
		return true
	end
end