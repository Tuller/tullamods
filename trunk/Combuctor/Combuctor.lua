--[[
	Combuctor.lua
		The combuctor frame
--]]

Combuctor = DongleStub("Dongle-1.0"):New("Combuctor")

local L = COMBUCTOR_LOCALS
local FRAME_WIDTH = 320-8
local FRAME_HEIGHT = 324
local ITEM_SIZE = 37
local SPACING = 2

--local bindings
local _G = getfenv(0)
local GetContainerItemLink = GetContainerItemLink
local GetItemInfo = GetItemInfo
local BagnonUtil = BagnonUtil
local BagnonItem = BagnonItem
local floor, mod, ceil = floor, mod, ceil
local currentPlayer = UnitName("player")


--[[ Utility Functions ]]--

local function ToIndex(bag, slot)
	if(tonumber(bag) and tonumber(slot)) then
		return (bag<0 and bag*100 - slot) or (bag*100 + slot)
	end
end

local function ToBag(index)
	return (index > 0 and floor(index/100)) or ceil(index/100)
end


--[[ Main Frame Functions ]]--

local tabs = {ALL, "Inventory", "Bank", "Keys"}
local bags = {
	{0, 1, 2, 3, 4, -1, 5, 6, 7, 8, 9, 10, 11},
	{0, 1, 2, 3, 4},
	{-1, 5, 6, 7, 8, 9, 10, 11},
	{-2},
}

function Combuctor:Enable()
	local name = "CombuctorFrame"

	--frame stuff
	self.frame = _G[name]
	self.frame.player = UnitName("player")

	self.title = _G[name .. "Text"]
	self.title:SetText(format("%s's Stuff", self.frame.player))

	--item stuff
	self.items = {}
	self.count = 0

	--filtering stuff
	self.filter = {}
	self.quality = _G[name .. "Quality"]
	self.type = _G[name .. "Type"]
	self.search = _G[name .. "Search"]
	self.maxLevel = _G[name .. "MaxLevel"]
	self.minLevel = _G[name .. "MinLevel"]

	self:RegisterMessage("BAGNON_BANK_OPENED")
	self:RegisterMessage("BAGNON_BANK_CLOSED")
	self:HookBagClicks()

	local prev
	for i,title in ipairs(tabs) do
		local tab = CreateFrame("Button", name .. "Tab" .. i, self.frame, "CombuctorFrameTabButtonTemplate")
		tab:SetID(i); tab:SetText(title)

		if(prev) then
			tab:SetPoint("LEFT", prev, "RIGHT", -16, 0)
		else
			tab:SetPoint("CENTER", self.frame, "BOTTOMLEFT", 60, 62)
		end
		prev = tab
	end
	PanelTemplates_SetNumTabs(self.frame, #tabs)

	self:SetTab(2)
end

function Combuctor:OnShow()
	self:Regenerate()

	self:RegisterMessage("BAGNON_SLOT_ADD", "OnSlotChanged")
	self:RegisterMessage("BAGNON_SLOT_UPDATE", "OnSlotChanged")
	self:RegisterMessage("BAGNON_SLOT_UPDATE_LOCK")
	self:RegisterMessage("BAGNON_SLOT_UPDATE_COOLDOWN")
	self:RegisterMessage("BAGNON_SLOT_REMOVE")
end

function Combuctor:OnHide()
	self:RemoveAllItems()

	self:UnregisterMessage("BAGNON_SLOT_ADD")
	self:UnregisterMessage("BAGNON_SLOT_UPDATE")
	self:UnregisterMessage("BAGNON_SLOT_UPDATE_LOCK")
	self:UnregisterMessage("BAGNON_SLOT_UPDATE_COOLDOWN")
	self:UnregisterMessage("BAGNON_SLOT_REMOVE")
end

function Combuctor:SetTab(index)
	if(self.index ~= index) then
		self.index = index
		PanelTemplates_SetTab(self.frame, index)

		local newBags = bags[index]
		local changed = false
		if(self.bags) then
			for _,i in pairs(self.bags) do
				local found = false
				for _,j in pairs(newBags) do
					if(i == j) then
						found = true
					end
				end

				if(not found) then
					local removedItems = self:RemoveBag(i)
					changed = changed or removedItems
				end
			end
		end
		self.bags = newBags

		if(changed and self.frame:IsShown()) then
			self:Regenerate()
		end
	end
end

--[[ Messages ]]--

function Combuctor:BAGNON_BANK_OPENED()
	BagnonUtil:SetAtBank(true)

	if(self.frame:IsShown()) then
		self:Regenerate()
	else
		ShowUIPanel(self.frame)
	end
end

function Combuctor:BAGNON_BANK_CLOSED()
	BagnonUtil:SetAtBank(false)

	if(not BagnonDB) then
		local changed = self:RemoveBankItems()
		if(changed and self.frame:IsShown()) then
			self:Layout()
		end
	end
end

function Combuctor:OnSlotChanged(msg, ...)
	self:UpdateSlot(...)
end

function Combuctor:BAGNON_SLOT_UPDATE_LOCK(msg, ...)
	self:UpdateSlotLock(...)
end

function Combuctor:BAGNON_SLOT_UPDATE_COOLDOWN(msg, ...)
	self:UpdateSlotCooldown(...)
end

function Combuctor:BAGNON_SLOT_REMOVE(msg, ...)
	if self:RemoveItem(...) then
		self:Layout()
	end
end


--[[ Item Updating ]]--

function Combuctor:HasItem(link)
	local f = self.filter
	if(next(f)) then
		if(not link) then return true end

		local name, _, quality, _, level, type, subType, _, equipLoc = GetItemInfo(link)

		if f.quality and quality ~= f.quality then
			return false
		elseif f.minLevel and level < f.minLevel then
			return false
		elseif f.maxLevel and level > f.maxLevel then
			return false
		elseif f.type and type ~= f.type then
			return false
		elseif f.subType and subType ~= f.subType then
			return false
		elseif f.equipLoc and equipLoc ~= f.equipLoc then
			return false
		elseif f.name then
			local name = name:lower()
			if not(f.name == name or name:find(f.name)) then
				return false
			end
		end
	end
	return true
end

function Combuctor:AddItem(bag, slot)
	local index = ToIndex(bag, slot)
	local item = self.items[index]

	if item then
		item:Update()
	else
		self.items[index] = BagnonItem:Set(self.frame, bag, slot)
		self.count = self.count + 1
		return true
	end
end

function Combuctor:RemoveItem(bag, slot)
	local index = ToIndex(bag, slot)
	local item = self.items[index]

	if item then
		item:Release()
		self.items[index] = nil
		self.count = self.count - 1
		return true
	end
end

function Combuctor:UpdateSlot(bag, slot, link)
	if(self:HasItem(link or BagnonUtil:GetItemLink(bag, slot, self:GetPlayer()))) then
		self:AddItem(bag, slot)
	else
		self:RemoveItem(bag, slot)
	end
end

function Combuctor:UpdateSlotLock(bag, slot)
	local item = self.items[ToIndex(bag, slot)]
	if item then
		item:UpdateLock()
	end
end

function Combuctor:UpdateSlotCooldown(bag, slot)
	local item = self.items[ToIndex(bag, slot)]
	if item then
		item:UpdateCooldown()
	end
end

--layout all items
function Combuctor:Regenerate()
	local player = self:GetPlayer()
	for _,bag in ipairs(self.bags) do
		for slot = 1, BagnonUtil:GetBagSize(bag, player) do
			self:UpdateSlot(bag, slot)
		end
	end
	self:Layout()
end

function Combuctor:Layout()
	local count = self.count
	local size = ITEM_SIZE+2

	local cols = 1
	local scale = FRAME_WIDTH / (size*cols)
	local rows = floor(FRAME_HEIGHT / (size*scale))
	while(cols*rows < count) do
		cols = cols + 1
		scale = FRAME_WIDTH / (size*cols)
		rows = floor(FRAME_HEIGHT / (size * scale))
	end

	local items = self.items
	local frame = self.frame

	local offX, offY = 28/scale, 78/scale
	local player = self:GetPlayer()
	local i = 0
	for _,bag in ipairs(self.bags) do
		for slot = 1, BagnonUtil:GetBagSize(bag, player) do
			local item = items[ToIndex(bag, slot)]
			if(item) then
				i = i + 1
				local row = mod(i-1,cols)
				local col = ceil(i/cols)-1
				item:ClearAllPoints()
				item:SetScale(scale)
				item:SetPoint("TOPLEFT", frame, "TOPLEFT", size*row + offX, -(size*col + offY))
			end
		end
	end
end

--remove bank items
function Combuctor:RemoveBankItems()
	local items = self.items
	local changed = false

	for index,item in pairs(items) do
		if BagnonUtil:IsBankBag(ToBag(index)) then
			item:Release()
			items[index] = nil
			self.count = self.count - 1
			changed = true
		end
	end
	return changed
end

function Combuctor:RemoveBag(bag)
	local items = self.items
	local changed = false

	for index,item in pairs(items) do
		if bag == ToBag(index) then
			item:Release()
			items[index] = nil
			self.count = self.count - 1
			changed = true
		end
	end

	return changed
end

function Combuctor:RemoveAllItems()
	local items = self.items

	for index,item in pairs(items) do
		item:Release()
		items[index] = nil
	end
	self.count = 0
end

function Combuctor:ReloadAllItems()
	self:RemoveAllItems()

	if(self.frame:IsShown()) then
		self:Regenerate()
	end
end


--[[
	Filtering
--]]

function Combuctor:GetPlayer()
	return self.player or currentPlayer
end

function Combuctor:SetPlayer(player)
	if(player ~= self:GetPlayer()) then
		self.player = player
		self.frame.player = player
		self:ReloadAllItems()
		self.title:SetText(format("%s's Stuff", player))
	end
end

--reset all filters
function Combuctor:Reset()
	local f = self.filter
	local changed
	for i in pairs(f) do
		if(f[i] ~= nil) then
			changed = true
			f[i] = nil
		end
	end

	--reset search text
	local search = self.search
	search:SetText(search:HasFocus() and "" or SEARCH)

	self.minLevel:SetText("")
	self.maxLevel:SetText("")

	self:UpdateTypeText()
	self:UpdateQualityText()

	if(changed) then
		self:Regenerate()
	end
end


--[[ Text ]]--

--name
function Combuctor:OnSearchChanged(frame, text)
	if(frame:HasFocus()) then
		if text == "" then text = nil end
		if(text) then
			text = text:lower()
		end

		local f = self.filter
		if(f.name ~= text) then
			f.name = text
			self:Regenerate()
		end
	end
end

--minLevel
function Combuctor:OnMinLevelChanged(frame, text)
	if(frame:HasFocus()) then
		if text == "" then text = nil end

		local f = self.filter
		if(f.minLevel ~= tonumber(text)) then
			f.minLevel = tonumber(text)
			self:Regenerate()
		end
	end
end

--maxLevel
function Combuctor:OnMaxLevelChanged(frame, text)
	if(frame:HasFocus()) then
		if text == "" then text = nil end

		local f = self.filter
		if(f.maxLevel ~= tonumber(text)) then
			f.maxLevel = tonumber(text)
			self:Regenerate()
		end
	end
end


--[[ Dropdowns ]]--

local info = {}
local function AddItem(text, value, func, hasArrow, level, arg1, arg2)
	info.text = text
	info.func = func
	info.value = value
	info.hasArrow = (hasArrow and true) or nil
	info.notCheckable = true
	info.checked = false
	info.arg1 = arg1
	info.arg2 = arg2
	UIDropDownMenu_AddButton(info, level)
end


--[[ Quality ]]--

local function Quality_GetText(index)
	if tonumber(index) then
		local hex = select(4, GetItemQualityColor(index))
		return format("%s%s|r", hex, _G[format("ITEM_QUALITY%d_DESC",index)])
	end
	return ALL
end

local function Quality_OnClick()
	local value = (this.value ~= ALL and this.value) or nil
	local f = Combuctor.filter

	if(f.quality ~= value) then
		f.quality = value
		Combuctor:Regenerate()
	end
	Combuctor:UpdateQualityText()
end

--add all buttons to the dropdown menu
local function Quality_Initialize()
	AddItem(ALL, ALL, Quality_OnClick)
	for i = 6, 0, -1 do
		AddItem(Quality_GetText(i), i, Quality_OnClick)
	end
end

function Combuctor:UpdateQualityText()
	_G[self.quality:GetName() .. "Text"]:SetText(Quality_GetText(self.filter.quality))
end

function Combuctor:OnQualityShow(frame)
	UIDropDownMenu_Initialize(frame, Quality_Initialize)
	UIDropDownMenu_SetWidth(90, frame)
	self:UpdateQualityText()
end


--[[ Type ]]--

local function Types_Generate()
	local types = {GetAuctionItemClasses()}
	table.insert(types, L.Quest)
	table.insert(types, L.Key)

	local subTypes = {}
	for i in ipairs(types) do
		if GetAuctionItemSubClasses(i) then
			subTypes[i] = {GetAuctionItemSubClasses(i)}
		end
	end

	local tradeGoods = subTypes[5] or {}
	table.insert(tradeGoods, L.TradeGoods)
	table.insert(tradeGoods, L.Devices)
	table.insert(tradeGoods, L.Explosives)
	table.insert(tradeGoods, L.Parts)
	subTypes[5] = tradeGoods

	local misc = subTypes[11] or {}
	table.insert(misc, L.Junk)
	subTypes[11] = misc

	return types, subTypes
end
local types, subTypes = Types_Generate()
local type, subType

local function Type_UpdateText()
	local text
	if(filter.type) then
		if(filter.subType) then
			text = format("%s - %s", filter.type, filter.subType)
			if(filter.equipLoc) then
				text = format("%s - %s", filter.subType, getglobal(filter.equipLoc))
			end
		else
			text = filter.type
		end
	else
		text = ALL
	end
	getglobal(uiFrame.type:GetName() .. "Text"):SetText(text)
end

local function Type_OnClick(arg1, arg2)
	local type, subType = this.arg1, this.arg2
	local text
	local f = Combuctor.filter

	f.type = nil
	f.subType = nil
	f.equipLoc = nil

	if(type) then
		f.type = types[type]
		if(subType) then
			f.subType = subTypes[type][subType]
			f.equipLoc = select(this.value, GetAuctionInvTypes(type, subType))
		else
			f.subType = subTypes[type][this.value]
		end
	else
		f.type = types[this.value]
	end
	Combuctor:UpdateTypeText()
	Combuctor:Regenerate()

	--hack to hide the previous dropdown menu levels
	for i = 1, UIDROPDOWNMENU_MENU_LEVEL-1 do
		_G["DropDownList"..i]:Hide()
	end
end

local function AddTypes(level)
	AddItem(ALL, ALL, Type_OnClick)
	for i,text in pairs(types) do
		AddItem(text, i, Type_OnClick, subTypes[i], level)
	end
end

local function AddSubTypes(level)
	type = UIDROPDOWNMENU_MENU_VALUE

	if subTypes[type] then
		for i,text in ipairs(subTypes[type]) do
			AddItem(text, i, Type_OnClick, GetAuctionInvTypes(type, i), level, type)
		end
	end
end

local function AddEquipLocations(level)
	subType = UIDROPDOWNMENU_MENU_VALUE

	for i = 1, select("#", GetAuctionInvTypes(type, subType)) do
		local equipLoc = getglobal(select(i, GetAuctionInvTypes(type, subType)))
		AddItem(equipLoc, i, Type_OnClick, false, level, type, subType)
	end
end

local function Type_Initialize(level)
	local level = level or 1

	if(level == 1) then
		AddTypes(level)
	elseif(level == 2) then
		AddSubTypes(level)
	elseif(level == 3) then
		AddEquipLocations(level)
	end
end

function Combuctor:UpdateTypeText()
	local f = self.filter

	local text
	if(f.type) then
		if(f.subType) then
			text = format("%s - %s", f.type, f.subType)
			if(f.equipLoc) then
				text = format("%s - %s", f.subType, _G[f.equipLoc])
			end
		else
			text = f.type
		end
	else
		text = ALL
	end

	_G[self.type:GetName() .. "Text"]:SetText(text)
end

function Combuctor:OnTypeShow(frame)
	UIDropDownMenu_Initialize(frame, Type_Initialize)
	UIDropDownMenu_SetWidth(200, frame)
	self:UpdateTypeText()
end


--[[ Bag Clicks ]]--

function Combuctor:Toggle()
	if(self.frame:IsShown()) then
		HideUIPanel(self.frame)
	else
		ShowUIPanel(self.frame)
	end
end

function Combuctor:HookBagClicks()
	BankFrame:UnregisterEvent("BANKFRAME_OPENED")

	local hide = function() HideUIPanel(self.frame) end
	local show = function() ShowUIPanel(self.frame) end
	local toggle = function() self:Toggle() end
	local noop = function() return end

	OpenBackpack = show
	CloseBackpack = hide
	ToggleBackpack = toggle

	OpenAllBags = function(force) if(force) then show() else toggle() end end
	CloseAllBags = hide

	ToggleBag = toggle
end