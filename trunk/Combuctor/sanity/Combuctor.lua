--[[
	Combuctor.lua
		The combuctor frame
--]]

Combuctor = DongleStub("Dongle-1.0"):New("Combuctor")
Combuctor.numShown = 15
Combuctor.step = 15

--local constants
local L = COMBUCTOR_LOCALS
local ITEM_WIDTH = 300

--local bindings
local _G = getfenv(0)
local floor, mod, ceil, format = floor, mod, ceil, format
local GetContainerItemLink = GetContainerItemLink
local GetItemInfo = GetItemInfo
local BagnonUtil = BagnonUtil
local currentPlayer = UnitName("player")

--utility functions
local function ToIndex(bag, slot)
	return (bag<0 and bag*100 - slot) or (bag*100 + slot)
end

local function ToBag(index)
	return (index > 0 and floor(index/100)) or ceil(index/100)
end

local function ToSlot(index)
	local bag = ToBag(index)
	return bag, index - bag*100
end

--returns the full item link
local function ToShortLink(link)
	if link then
		local a,b,c,d,e,f,g = link:match("(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):%-?%d+")
		if(b == c and c == d and d == e and e == f and f == g) then
			return a
		end
		return format("item:%s:%s:%s:%s:%s:%s:%s:0", a, b, c, d, e, f, g)
	end
end


--[[ Main Frame Functions ]]--

local function DummyItem_Create(name, parent)
	local dummy = CreateFrame("Button", name, parent, "ContainerFrameItemButtonTemplate")
	dummy:SetScript("OnLeave", function(self) GameTooltip:Hide() self:Hide() end)
	dummy:SetNormalTexture(nil)
	dummy:SetPushedTexture(nil)
	dummy:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
	dummy:SetToplevel(true)
	dummy:Hide()

	return dummy
end

function Combuctor:Enable()
	local name = "CombuctorFrame"

	--frame stuff
	local frame = _G[name]
	frame.player = currentPlayer
	frame.GetPlayer = function(self) return Combuctor:GetPlayer() end
	frame.SetPlayer = function(self, player) Combuctor:SetPlayer(player) end
	self.frame = frame

	self.dummyItem = DummyItem_Create(name .. "DummyItem", frame)


	--set the frame title
	self.title = _G[name .. "Text"]
	self.title:SetText(format(L.FrameTitle, self:GetPlayer()))

	--add item buttons
	self.buttons = {}
	local buttons = self.buttons

	local button = CreateFrame("Button", name .. 1, frame, "CombuctorItemButtonTemplate")
	button:SetPoint("TOPLEFT", frame, "TOPLEFT", 19, -75)
	button:RegisterForClicks("anyUp")
	button.icon = _G[button:GetName() .. "Icon"]
	button.count = _G[button:GetName() .. "Count"]
	buttons[1] = button

	for i = 2, self.numShown do
		local name = name .. i
		button = CreateFrame("Button", name, frame, "CombuctorItemButtonTemplate")
		button:RegisterForClicks("anyUp")
		button.icon = _G[name .. "Icon"]
		button.count = _G[name .. "Count"]
		button:SetPoint("TOPLEFT", buttons[i-1], "BOTTOMLEFT")
		button:SetPoint("TOPRIGHT", buttons[i-1], "BOTTOMRIGHT")
		buttons[i] = button
	end

	--item stuff
	self.links = {}
	self.newItems = {}
	self.display = {}
	self.filter = {}

	--filtering stuff
	self.quality = _G[name .. "Quality"]
	self.type = _G[name .. "Type"]
	self.search = _G[name .. "Search"]
	self.maxLevel = _G[name .. "MaxLevel"]
	self.minLevel = _G[name .. "MinLevel"]
	self.scrollFrame = 	_G[name.. "Scroll"]

	--add panels to the frame
	self:AddPanels()

	--add in events and messages that are always watch
	self:RegisterMessage("BAGNON_BANK_OPENED")
	self:RegisterMessage("BAGNON_BANK_CLOSED")

	self:RegisterMessage("BAGNON_ITEM_GAINED")
	self:RegisterMessage("BAGNON_ITEM_LOST")
	self:RegisterMessage("BAGNON_ITEM_SWAPPED")

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
			self:RegisterMessage("BAGNON_ITEM_GAINED")
			self:RegisterMessage("BAGNON_ITEM_LOST")
			self:RegisterMessage("BAGNON_ITEM_SWAPPED")
			self:RegisterMessage("BAGNON_ITEM_COUNT_CHANGED")
			-- self:RegisterMessage("BAGNON_SLOT_ADD", "OnSlotChanged")
			-- self:RegisterMessage("BAGNON_SLOT_UPDATE", "OnSlotChanged")
			-- self:RegisterMessage("BAGNON_SLOT_UPDATE_LOCK")
			-- self:RegisterMessage("BAGNON_SLOT_UPDATE_COOLDOWN")
			self:RegisterMessage("BAGNON_SLOT_REMOVE")
		end
	else
		if(self.watchingEvents) then
			self.watchingEvents = nil
			self:UnregisterMessage("BAGNON_ITEM_GAINED")
			self:UnregisterMessage("BAGNON_ITEM_LOST")
			self:UnregisterMessage("BAGNON_ITEM_SWAPPED")
			self:UnregisterMessage("BAGNON_ITEM_COUNT_CHANGED")
			-- self:UnregisterMessage("BAGNON_SLOT_ADD")
			-- self:UnregisterMessage("BAGNON_SLOT_UPDATE")
			-- self:UnregisterMessage("BAGNON_SLOT_UPDATE_LOCK")
			-- self:UnregisterMessage("BAGNON_SLOT_UPDATE_COOLDOWN")
			self:UnregisterMessage("BAGNON_SLOT_REMOVE")
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
			self:Layout(true)
		end
	end
end

-- function Combuctor:OnSlotChanged(msg, bag, slot, link)
	-- if self:UpdateSlot(bag, slot, link) then
		-- self:Layout(true)
	-- end
-- end

function Combuctor:BAGNON_SLOT_REMOVE(msg, ...)
	if self:RemoveItem(...) then
		self:Layout(true)
	end
end

function Combuctor:BAGNON_ITEM_GAINED(msg, bag, slot, link)
	if self:UpdateSlot(bag, slot, link) then
		self:Layout(true)
	end
end

function Combuctor:BAGNON_ITEM_LOST(msg, bag, slot, newLink, oldLink)
	if self:RemoveItem(bag, slot, oldLink) then
		self:Layout(true)
	end
end

function Combuctor:BAGNON_ITEM_SWAPPED(msg, bag, slot, newLink, oldLink)
	local removed = self:RemoveItem(bag, slot, oldLink)
	if(self:UpdateSlot(bag, slot, link) or removed) then
		self:Layout(true)
	end
end

function Combuctor:BAGNON_ITEM_COUNT_CHANGED(msg, bag, slot, link)
	self:UpdateSlot(bag, slot, link)
end

-- function Combuctor:BAGNON_SLOT_UPDATE_LOCK(msg, ...)
	-- self:UpdateSlotLock(...)
-- end

-- function Combuctor:BAGNON_SLOT_UPDATE_COOLDOWN(msg, ...)
	-- self:UpdateSlotCooldown(...)
-- end


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
local PANELS = {L.Inventory, L.Bank, L.Keys, L.All}
local PANEL_BAGS = {
	{0, 1, 2, 3, 4},
	{-1, 5, 6, 7, 8, 9, 10, 11},
	{-2},
	{0, 1, 2, 3, 4, -1, 5, 6, 7, 8, 9, 10, 11},
}
local DEFAULT_PANEL = L.Inventory

--takes a panel name, and returns its ID
local function NameToPanelID(name)
	for id,panelName in pairs(PANELS) do
		if(panelName == name) then return id end
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
		if(self:SetBags(PANEL_BAGS[panelID]) and self.frame:IsShown()) then
			self:Layout(true)
		end
		-- self:SetShowNewItems(name == L.New)
	end
end


--[[ Scroll Frame Events ]]--

function Combuctor:OnScrollShow()
	self.buttons[1]:SetWidth(ITEM_WIDTH)
end

function Combuctor:OnScrollHide()
	self.buttons[1]:SetWidth(ITEM_WIDTH + 20)
end


--[[ Item Button ]]--

function Combuctor:OnItemEnter(item)
	local bag, slot = ToSlot(next(self.links[item.link]))
	self.frame:SetID(bag)
	self.dummyItem:SetID(slot)
	self.dummyItem:SetAllPoints(item)
	self.dummyItem:Show()
end


--[[ Item Updating ]]--

--returns true if the item matches the given filter, false othewise
function Combuctor:HasItem(bag, slot, link)
	-- if self:ShowingNewItems() and not(self:GetPlayer() == currentPlayer and self.newItems[ToIndex(bag, slot)]) then
		-- return false
	-- end

	local f = self.filter
	if(next(f)) then
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

function Combuctor:AddItem(bag, slot, link)
	if(link) then
		local index = ToIndex(bag, slot)
		local link = ToShortLink(link)
		local count = BagnonUtil:GetItemCount(bag, slot, self:GetPlayer())

		local items = self.links[link]
		if items then
			items[index] = count
			self:UpdateLink(link)
		else
			self.links[link] = {[index] = count}
			self:AddLink(link)
			return true
		end
	end
end

function Combuctor:RemoveItem(bag, slot, prevLink)
	if prevLink then
		local index = ToIndex(bag, slot)
		local link = ToShortLink(prevLink)
		local count = BagnonUtil:GetItemCount(bag, slot, self:GetPlayer())

		local items = self.links[link]
		if items then
			items[index] = nil
			if(next(items)) then
				self:UpdateLink(link)
			else
				self.links[link] = nil
				self:RemoveLink(link)
				return true
			end
		end
	end
end

function Combuctor:UpdateSlot(bag, slot, link)
	local link = link or BagnonUtil:GetItemLink(bag, slot, self:GetPlayer())

	if self:HasItem(bag, slot, link) then
		return self:AddItem(bag, slot, link)
	end
	return self:RemoveItem(bag, slot, link)
end

-- function Combuctor:UpdateSlotLock(bag, slot)
	-- local item = self.items[ToIndex(bag, slot)]
	-- if item then
		-- item:UpdateLock()
	-- end
-- end

-- function Combuctor:UpdateSlotCooldown(bag, slot)
	-- local item = self.items[ToIndex(bag, slot)]
	-- if item then
		-- item:UpdateCooldown()
	-- end
-- end

-- function Combuctor:UpdateSlotNew(bag, slot, link, isNew)
	-- BagnonItem:SetNew(bag, slot, isNew)

	-- if(self.frame:IsShown() and self:ShowingNewItems()) then
		-- if self:UpdateSlot(bag, slot) then
			-- self:Layout()
		-- end
	-- end
-- end


--[[ Link Updating ]]--

local tinsert, tremove = tinsert, tremove

function Combuctor:AddLink(link)
	--self:Print("add", (select(2, GetItemInfo(link))))
	tinsert(self.display, link)
end

function Combuctor:RemoveLink(link)
	for i,v in pairs(self.display) do
		if v == link then
			--self:Print("remove", (select(2, GetItemInfo(tremove(self.display, i)))))
			-- tremove(self.display, i)
			break
		end
	end
end

function Combuctor:UpdateLink(link)
	if(self.frame:IsShown()) then
		for _,button in ipairs(self.buttons) do
			if(button.link == link) then
				button.count:SetText(self:GetLinkCount(link))
				break
			end
		end
	end
end

function Combuctor:GetLinkCount(link)
	local total = 0
	local items = self.links[link]
	if(items) then
		for _,count in pairs(items) do
			total = total + count
		end
	end
	return total == 1 and "" or total
end

--[[ Item Layout ]]--

--sorts a list by rarity, either closeness to the searchString if there's been a search, then level, then name
local function Ludwig_Sort(id1, id2)
	local name1, _, quality1 = GetItemInfo(id1)
	local name2, _, quality2 = GetItemInfo(id2)

	if quality1 ~= quality2 then
		return quality1 > quality2
	end

	return name1 < name2
end

function Combuctor.UpdateList()
	Combuctor:Layout()
end

function Combuctor:Layout(shouldSort)
	local display = self.display
	if(shouldSort) then table.sort(display, Ludwig_Sort) end

	local size = #display
	FauxScrollFrame_Update(self.scrollFrame, size, self.numShown, self.step)

	local offset = self.scrollFrame.offset
	self.offset = offset

	for i,button in ipairs(self.buttons) do
		local index = i + offset
		if index > size then
			button:Hide()
		else
			local link = display[index]
			local name,_,quality,_,_,_,_,_,_,icon = GetItemInfo(link)
			local r,g,b = GetItemQualityColor(quality)
			button:SetText(name)
			button:SetTextColor(r, g, b)
			button.icon:SetTexture(icon)
			button.count:SetText(self:GetLinkCount(link))
			button.link = link
			button:Show()
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
	if(changed) then self:Layout(true) end
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
				if(changed) then self:Layout(true) end
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

	if(layout and changed) then self:Layout(true) end
	return changed
end

--remove all items in the given bag
function Combuctor:RemoveBag(bag, layout)
	local changed = false

	local links = self.links
	for link in pairs(links) do
		local items = self.links[link]
		for index in pairs(items) do
			if(bag == ToBag(index)) then
				items[index] = nil
				changed = true
			end
		end
		if(not next(items)) then
			self:RemoveLink(link)
		end
	end

	if(layout and changed) then self:Layout(true) end
	return changed
end

--remove bank items from the frame
function Combuctor:RemoveBankItems(layout)
	local changed = false

	local links = self.links
	for link in pairs(links) do
		local items = self.links[link]
		for index in pairs(items) do
			if BagnonUtil:IsBankBag(ToBag(index)) then
				items[index] = nil
				changed = true
			end
		end
		if(not next(items)) then
			self:RemoveLink(link)
		end
	end

	if(layout and changed) then self:Layout(true) end
	return changed
end

--remove all items from the frame
function Combuctor:RemoveAllItems()
	if next(self.links) then
		self.links = {}
		self.display = {}
		return true
	end
end

--completely regenerate the frame
function Combuctor:ReloadAllItems()
	if(self:RemoveAllItems() and self.frame:IsShown()) then
		self:Regenerate()
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
	return self.showingNewItems
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


--[[ Dropdowns ]]--

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