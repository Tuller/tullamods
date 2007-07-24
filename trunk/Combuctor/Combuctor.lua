--[[
	Combuctor.lua
		The combuctor frame
--]]

Combuctor = DongleStub("Dongle-1.0"):New("Combuctor")

--local constants
local L = COMBUCTOR_LOCALS
local FRAME_WIDTH = 312
local FRAME_HEIGHT = 326
local ITEM_SIZE = 37
local SPACING = 2

--local bindings
local _G = getfenv(0)
local GetContainerItemLink = GetContainerItemLink
local GetItemInfo = GetItemInfo
local BagnonUtil, BagnonItem = BagnonUtil, BagnonItem
local floor, mod, ceil = floor, mod, ceil
local currentPlayer = UnitName("player")

--utility functions
local function ToIndex(bag, slot)
	return (bag<0 and bag*100 - slot) or (bag*100 + slot)
end

local function ToBag(index)
	return (index > 0 and floor(index/100)) or ceil(index/100)
end


--[[ Main Frame Functions ]]--

function Combuctor:Enable()
	local name = "CombuctorFrame"

	--frame stuff
	self.frame = _G[name]
	self.frame.player = currentPlayer

	--set the frame title
	self.title = _G[name .. "Text"]
	self.title:SetText(format(L.FrameTitle, self:GetPlayer()))

	--add a background to the item area of the frame
	local texture = self.frame:CreateTexture(nil, "OVERLAY")
	texture:SetWidth(FRAME_WIDTH); texture:SetHeight(FRAME_HEIGHT)
	texture:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 26, -78)
	texture:SetTexture(0.1, 0.1, 0.1)

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
	--character select dropdown
	self.charList = (BagnonDB and self:AddCharSelect()) or nil

	--add panels to the frame
	self:AddPanels()

	--add in events and messages that are always watch
	self:RegisterMessage("BAGNON_BANK_OPENED")
	self:RegisterMessage("BAGNON_BANK_CLOSED")

	--hook into the bag clicking interface
	self:HookBagClicks()
end

function Combuctor:OnShow()
	self:Regenerate()
	self:UpdateEvents()
end

function Combuctor:OnHide()
	self:SetPlayer(currentPlayer)
	self:UpdateEvents()

	if(BagnonUtil:AtBank()) then
		CloseBankFrame()
	end
end

--watch events only if we're showing the frame and looking at the current player
function Combuctor:UpdateEvents()
	if(self.frame:IsShown() and self:GetPlayer() == currentPlayer) then
		if(not self.watchingEvents) then
			self.watchingEvents = true
			self:RegisterMessage("BAGNON_SLOT_ADD", "OnSlotChanged")
			self:RegisterMessage("BAGNON_SLOT_UPDATE", "OnSlotChanged")
			self:RegisterMessage("BAGNON_SLOT_UPDATE_LOCK")
			self:RegisterMessage("BAGNON_SLOT_UPDATE_COOLDOWN")
			self:RegisterMessage("BAGNON_SLOT_REMOVE")

			self:RegisterMessage("BAGNON_ITEM_GAINED")
			self:RegisterMessage("BAGNON_ITEM_LOST")
			self:RegisterMessage("BAGNON_ITEM_SWAPPED")
		end
	else
		if(self.watchingEvents) then
			self.watchingEvents = nil
			self:UnregisterMessage("BAGNON_SLOT_ADD")
			self:UnregisterMessage("BAGNON_SLOT_UPDATE")
			self:UnregisterMessage("BAGNON_SLOT_UPDATE_LOCK")
			self:UnregisterMessage("BAGNON_SLOT_UPDATE_COOLDOWN")
			self:UnregisterMessage("BAGNON_SLOT_REMOVE")

			self:UnregisterMessage("BAGNON_ITEM_GAINED")
			self:UnregisterMessage("BAGNON_ITEM_LOST")
			self:UnregisterMessage("BAGNON_ITEM_SWAPPED")
		end
	end
end


--[[ Messages ]]--

function Combuctor:BAGNON_BANK_OPENED()
	BagnonUtil:SetAtBank(true)

	if(self.frame:IsShown()) then
		if(self:GetPlayer() == currentPlayer) then
			self:Regenerate()
		end
	else
		ShowUIPanel(self.frame)
	end
end

function Combuctor:BAGNON_BANK_CLOSED()
	BagnonUtil:SetAtBank(false)

	if(not BagnonDB) then
		if(self:RemoveBankItems() and self.frame:IsShown()) then
			self:Layout()
		end
	end
end

function Combuctor:OnSlotChanged(msg, bag, slot, link)
	if self:UpdateSlot(bag, slot, link) then
		self:Layout()
	end
end

function Combuctor:BAGNON_ITEM_GAINED(msg, bag, slot)
	self:UpdateSlotNew(bag, slot, true)
end

function Combuctor:BAGNON_ITEM_LOST(msg, bag, slot)
	self:UpdateSlotNew(bag, slot, false)
end

function Combuctor:BAGNON_ITEM_SWAPPED(msg, bag, slot)
	self:UpdateSlotNew(bag, slot, false)
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


--[[ Panels ]]--

--frame tabs and their respective bags
local PANELS = {NEW, L.Inventory, L.Bank, L.Keys, ALL}
local PANEL_BAGS = {
	{0, 1, 2, 3, 4},
	{0, 1, 2, 3, 4},
	{-1, 5, 6, 7, 8, 9, 10, 11},
	{-2},
	{0, 1, 2, 3, 4, -1, 5, 6, 7, 8, 9, 10, 11},
}
local DEFAULT_PANEL = L.Inventory

--takes a panel name, and returns its ID
local function NameToPanelID(name)
	for id,panelName in pairs(PANELS) do
		if(panelName == name) then
			return id
		end
	end
end

--add in all panels
function Combuctor:AddPanels()
	local name = format("%sTab", self.frame:GetName())

	local prev
	for i,panelName in ipairs(PANELS) do
		local tab = CreateFrame("Button", name .. i, self.frame, "CombuctorFrameTabButtonTemplate")
		tab:SetID(i)
		tab:SetText(panelName)

		if(prev) then
			tab:SetPoint("LEFT", prev, "RIGHT", -16, 0)
		else
			tab:SetPoint("CENTER", self.frame, "BOTTOMLEFT", 60, 62)
		end
		prev = tab
	end
	PanelTemplates_SetNumTabs(self.frame, #PANELS)

	self:ShowPanel(DEFAULT_PANEL)
end

--shows the given panel
function Combuctor:ShowPanel(name)
	if(self.panel ~= name) then
		self.panel = name

		--highlight the matching panel tab
		local panelID = NameToPanelID(name)
		PanelTemplates_SetTab(self.frame, panelID)

		--remove any bags that are not in the new set, then
		self:SetBags(PANEL_BAGS[panelID])
		self:SetShowNewItems(name == NEW)
	end
end


--[[ Item Updating ]]--

--returns true if the item matches the given filter, false othewise
function Combuctor:HasItem(bag, slot, link)
	if self:ShowingNewItems() and not BagnonItem:IsNewSlot(bag, slot) then
		return false
	end

	local f = self.filter
	if(next(f)) then
		local link = link or BagnonUtil:GetItemLink(bag, slot, self:GetPlayer())
		if(not link) then return false end

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

function Combuctor:AddItem(bag, slot, isNew)
	local index = ToIndex(bag, slot)
	local item = self.items[index]

	if item then
		item:Update(isNew)
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
	if(self:HasItem(bag, slot, link)) then
		return self:AddItem(bag, slot)
	end
	return self:RemoveItem(bag, slot)
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

function Combuctor:UpdateSlotNew(bag, slot, isNew)
	BagnonItem:SetNew(bag, slot, isNew)

	if(self:ShowingNewItems()) then
		if self:UpdateSlot(bag, slot) then
			self:Layout()
		end
	end
end


--[[ Mass Item Changes ]]--

--update all items and layout the frame
function Combuctor:Regenerate()
	local changed = false
	local player = self:GetPlayer()
	for _,bag in ipairs(self.bags) do
		for slot = 1, BagnonUtil:GetBagSize(bag, player) do
			local altered = self:UpdateSlot(bag, slot)
			changed = changed or altered
		end
	end
	if(changed) then self:Layout() end
end

--set the display to use the given bag set, and remove any bags that are not in the new set
function Combuctor:SetBags(newBags)
	local bags = self.bags
	if(bags ~= newBags) then
		self.bags = newBags

		--remove any items from bags that are not in the new set
		local changed
		if(bags) then
			for _,i in pairs(bags) do
				local found = false
				for _,j in pairs(newBags) do
					if(i == j) then
						found = true
						break
					end
				end
				if(not found) then
					local altered = self:RemoveBag(i)
					changed = changed or altered
				end
			end
		end

		--add in any items from bags that were not in the old set
		if(self.frame:IsShown()) then
			if(not bags) then
				self:Regenerate()
			else
				for _,i in pairs(newBags) do
					local found = false
					for _,j in pairs(bags) do
						if(i == j) then
							found = true
							break
						end
					end
					if(not found) then
						local altered = self:AddBag(i)
						changed = changed or altered
					end
				end
				if(changed) then self:Layout() end
			end
		end
	end
end

--add all items in the givem bag
function Combuctor:AddBag(bag, layout)
	local player = self:GetPlayer()
	local changed = false

	for slot = 1, BagnonUtil:GetBagSize(bag, player) do
		local added = self:UpdateSlot(bag, slot)
		changed = changed or added
	end

	if(layout and changed) then self:Layout() end
	return changed
end

--remove all items in the given bag
function Combuctor:RemoveBag(bag, layout)
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

	if(layout and changed) then self:Layout() end
	return changed
end

--remove bank items from the frame
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

--remove all items from the frame
function Combuctor:RemoveAllItems()
	local items = self.items
	local changed = true

	for i,item in pairs(items) do
		changed = true
		item:Release()
		items[i] = nil
	end
	self.count = 0

	return changed
end

--completely regenerate the frame
function Combuctor:ReloadAllItems()
	if(self:RemoveAllItems() and self.frame:IsShown()) then
		self:Regenerate()
	end
end


--[[ Item Layout ]]--

--layout all the item buttons, scaling ot fit inside the fram
--todo: dividers for bags v bank
function Combuctor:Layout()
	--figure out the layout
	local count = self.count
	local size = ITEM_SIZE+SPACING
	local cols = 1
	local scale = FRAME_WIDTH / (size*cols)
	local rows = floor(FRAME_HEIGHT / (size*scale))
	while(cols*rows < count) do
		cols = cols + 1
		scale = FRAME_WIDTH / (size*cols)
		rows = floor(FRAME_HEIGHT / (size * scale))
	end

	--layout the items
	local offX, offY = (26 + SPACING/2)/scale, (78 + SPACING/2)/scale
	local player = self:GetPlayer()
	local items = self.items
	local frame = self.frame

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
				item:Show()
			end
		end
	end
end


--[[
	Filtering
--]]


--[[ Reset ]]--

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

--[[ New Items ]]--

--show only new items
function Combuctor:SetShowNewItems(enable)
	self.showingNewItems = enable or nil
	self:Regenerate()
end

function Combuctor:ShowingNewItems()
	return self.showingNewItems and self:GetPlayer() == currentPlayer
end


--[[ Player ]]--

function Combuctor:SetPlayer(player)
	if(player ~= self:GetPlayer()) then
		self.player = player
		self.frame.player = player

		self:UpdateEvents()
		self:ReloadAllItems()
		self.title:SetText(format(L.FrameTitle, self:GetPlayer()))
	end
end

function Combuctor:GetPlayer()
	return self.player or currentPlayer
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


--[[
	Dropdowns
--]]

local info = {}

--adds a checkable item
local function AddCheckItem(text, value, func, selected, hasArrow, level, arg1, arg2)
	info.text = text
	info.func = func
	info.value = value
	info.hasArrow = (hasArrow and true) or nil
	info.notCheckable = false
	info.checked = value == selected
	info.arg1 = arg1
	info.arg2 = arg2
	UIDropDownMenu_AddButton(info, level)
end

--adds an uncheckable item
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

local function Type_OnClick(type, subType)
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


--[[ Player ]]--

local chars
local function Char_GetList()
	local list = {}

	for player in BagnonDB:GetPlayers() do
		table.insert(list, player)
	end

	--sort by currentPlayer first, then alphabetically
	local function SexySort(a, b)
		if(a == currentPlayer) then
			return true
		end
		if(b == currentPlayer) then
			return false
		end
		return a < b
	end
	table.sort(list, SexySort)

	return list
end

local function Char_OnClick(player, delete)
	local playerToShow
	if(delete) then
		--remove the selected player
		BagnonDB:RemovePlayer(player)

		--remove them from the dropdown's sorted list
		for i,character in pairs(chars) do
			if(character == player) then
				table.remove(chars, i)
				break
			end
		end

		--select the current player
		playerToShow = currentPlayer
	else
		--select the clicked player
		playerToShow = player
	end

	--show the given player, and check the selected one
	Combuctor:SetPlayer(playerToShow)
	UIDropDownMenu_SetSelectedName(Combuctor.charList, playerToShow)

	--hide the previous dropdown menus (hack)
	for i = 1, UIDROPDOWNMENU_MENU_LEVEL-1 do
		_G["DropDownList"..i]:Hide()
	end
end

--populate the list, add a delete button to all characters that aren't the current player
local function Char_Initialize(level)
	if(not chars) then
		chars = Char_GetList()
	end

	local level = level or 1
	if(level == 1) then
		local selected = Combuctor:GetPlayer()
		for i,player in ipairs(chars) do
			AddCheckItem(player, i, Char_OnClick, selected, player ~= currentPlayer, level, player)
		end
	elseif(level == 2) then
		AddItem(REMOVE, nil, Char_OnClick, false, level, chars[UIDROPDOWNMENU_MENU_VALUE], true)
	end
end

--toggle the character select dropdown at the given frame
function Combuctor:ToggleCharacterSelect(anchorFrame)
	if self.charList then
		ToggleDropDownMenu(1, nil, self.charList, anchorFrame, 20, 32)
	end
end

--add the character select dropdown
function Combuctor:AddCharSelect()
	local parent = self.frame
	local frame = CreateFrame("Frame", parent:GetName() .. "CharSelect", parent, "UIDropDownMenuTemplate")
	frame:SetID(1)

	UIDropDownMenu_Initialize(frame, Char_Initialize, "MENU")

	return frame
end