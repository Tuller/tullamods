--[[
	frame.lua
		A combuctor frame
--]]

CombuctorFrame = Combuctor:NewModule('Frame')

local L = LibStub('AceLocale-3.0'):GetLocale('Combuctor')

local BASE_WIDTH = 384
local ITEM_FRAME_WIDTH_OFFSET = 312 - BASE_WIDTH

local BASE_HEIGHT = 512
local ITEM_FRAME_HEIGHT_OFFSET = 346 - BASE_HEIGHT


function CombuctorFrame:OnEnable()
	self:RegisterMessage('COMBUCTOR_BAG_TYPE_CHANGED')
end

function CombuctorFrame:COMBUCTOR_BAG_TYPE_CHANGED(msg, bag)
	if self.frames then
		for frame in pairs(self.frames) do
			for _,bagID in pairs(frame.sets.bags) do
				if bag == bagID then
					frame.needsBagUpdate = true
					break
				end
			end
		end
		self.obj:Show()
	end
end

function CombuctorFrame:Create(...)
	local frame = self.obj:Create(...)

	if not self.frames then
		self.frames = {}
	end
	self.frames[frame] = true
	table.insert(UISpecialFrames, frame:GetName())

	return frame
end

function CombuctorFrame:UpdateBagSets()
	for frame in pairs(self.frames) do
		if frame.needsBagUpdate then
			frame.needsBagUpdate = nil
			frame:GenerateBagSets()
		end
	end
end

function CombuctorFrame:OnTitleEnter()
	GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	GameTooltip:SetText(self:GetText(), 1, 1, 1)
	GameTooltip:AddLine('<Alt-LeftDrag> To Move')
	GameTooltip:AddLine('<RightClick> To Reset Position')
	GameTooltip:Show()
end

function CombuctorFrame:OnBagToggleEnter()
	GameTooltip:SetOwner(self, 'ANCHOR_LEFT')

	GameTooltip:SetText('Bags', 1, 1, 1)
	GameTooltip:AddLine('<LeftClick> To Toggle Showing Bags')
	if self:GetParent().isBank then
		GameTooltip:AddLine('<RightClick> To Toggle the Inventory Frame')
	else
		GameTooltip:AddLine('<RightClick> To Toggle the Bank Frame')
	end
	GameTooltip:Show()
end

--[[
	Quality Filter Widget
		used for setting what quality of items to show
--]]

local QualityFilter = {}
do
	local SIZE = 20

	function QualityFilter:Create(parent)
		local f = CreateFrame('Frame', nil, parent)
		f.UpdateHighlight = self.UpdateHighlight

		local prev
		for i = -1, 5 do
			local button = CreateFrame('Button', nil, f, 'UIRadioButtonTemplate')
			button:SetWidth(SIZE); button:SetHeight(SIZE)
			button:SetScript('OnClick', self.OnButtonClick)
			button:SetScript('OnEnter', self.OnButtonEnter)
			button:SetScript('OnLeave', self.OnButtonLeave)

			if i > -1 then
				local bg = button:CreateTexture(nil, 'BACKGROUND')
				bg:SetWidth(SIZE/2); bg:SetHeight(SIZE/2)
				bg:SetPoint('CENTER')
				bg:SetTexture(GetItemQualityColor(i))
				button.bg = bg
				button.quality = i
			end

			if prev then
				button:SetPoint('LEFT', prev, 'RIGHT', 1, 0)
			else
				button:SetPoint('LEFT')
			end
			prev = button
		end

		f:SetWidth(SIZE * 5); f:SetHeight(SIZE)
		f:UpdateHighlight()

		return f
	end

	function QualityFilter:UpdateHighlight()
		local quality = self:GetParent().filter.quality

		for i = 1, select('#', self:GetChildren()) do
			local child = select(i, self:GetChildren())
			if child.quality == quality then
				if child.bg then
					child.bg:SetAlpha(1)
				end
				child:GetNormalTexture():SetVertexColor(1, 0.82, 0)
				child:LockHighlight()
			else
				if child.bg then
					child.bg:SetAlpha(0.5)
				end
				child:GetNormalTexture():SetVertexColor(1, 1, 1)
				child:UnlockHighlight()
			end
		end
	end

	function QualityFilter:OnButtonClick()
		self:GetParent():GetParent():SetFilter('quality', self.quality, true)
		self:GetParent():UpdateHighlight()
	end

	function QualityFilter:OnButtonEnter()
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')

		local quality = self.quality
		if quality then
			local r,g,b = GetItemQualityColor(quality)
			GameTooltip:SetText(getglobal(format('ITEM_QUALITY%d_DESC', quality)), r, g, b)
		else
			GameTooltip:SetText(ALL)
		end

		GameTooltip:Show()
	end

	function QualityFilter:OnButtonLeave()
		GameTooltip:Hide()
	end
end


--[[
	Type Filter Widget:
		Used for setting what types of items to show
--]]

local SideFilter = {}
do
	local nextID = 0
	function SideFilter:Create(parent)
		local f = CreateFrame('Frame', nil, parent)
		f.UpdateHighlight = self.UpdateHighlight

		local prev
		for i,category in ipairs(parent.cats) do
			local button = CreateFrame('CheckButton', format('CombuctorItemFilter%d', nextID), f, 'SpellBookSkillLineTabTemplate')
			button.category = category

			button:SetNormalTexture(category.icon)
			button:GetNormalTexture():SetTexCoord(0.06, 0.94, 0.06, 0.94)
			button:SetScript('OnClick', self.OnButtonClick)
			button:SetScript('OnEnter', self.OnButtonEnter)
			button:SetScript('OnLeave', self.OnButtonLeave)
			button:Show()

			if prev then
				button:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -17)
			else
				button:SetPoint('TOPLEFT', parent, 'TOPRIGHT', -32, -65)
				button:SetChecked(true)
			end
			prev = button
			nextID = nextID + 1
		end
		return f
	end

	function SideFilter:OnButtonClick()
		self:GetParent():GetParent():SetCategory(self.category)
	end

	function SideFilter:OnButtonEnter()
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		GameTooltip:SetText(self.category.name)
		GameTooltip:Show()
	end

	function SideFilter:OnButtonLeave()
		GameTooltip:Hide()
	end

	function SideFilter:UpdateHighlight()
		local category = self:GetParent().category

		for i = 1, select('#', self:GetChildren()) do
			local child = select(i, self:GetChildren())
			child:SetChecked(child.category == category)
		end
	end
end


--[[
	Inventory Frame Widget
--]]

--some crazy code, this is used for delayed updates when bag types change because of the possibility of updating in pairs
CombuctorFrame.obj = CombuctorUtil:CreateWidgetClass('Frame')
local InventoryFrame = CombuctorFrame.obj

--frame constructor
do
	local lastID = 1
	function InventoryFrame:Create(titleText, settings, isBank)
		local f = self:New(CreateFrame('Frame', format('CombuctorFrame%d', lastID), UIParent, 'CombuctorInventoryTemplate'))
		f:SetScript('OnShow', self.OnShow)
		f:SetScript('OnHide', self.OnHide)

		f.sets = settings
		f.isBank = isBank
		f.titleText = titleText

		f.bagButtons = {}
		f.tabs = {}
		f.filter = {}
		
		f:SetWidth(settings.w or BASE_WIDTH)
		f:SetHeight(settings.h or BASE_HEIGHT)

		f.title = getglobal(f:GetName() .. 'Title')

		--this must occur before we add the side buttons
		f:AddCategories()
		f.sideFilter = SideFilter:Create(f)

		f.nameFilter = getglobal(f:GetName() .. 'Search')

		f.qualityFilter = QualityFilter:Create(f)
		f.qualityFilter:SetPoint('BOTTOMLEFT', 24, 65)

		f.itemFrame = CombuctorItemFrame:Create(f)
		f.itemFrame:SetPoint('TOPLEFT', 24, -78)

		f.moneyFrame = CombuctorMoneyFrame:Create(f)
		f.moneyFrame:SetPoint('BOTTOMRIGHT', -40, 67)

		f:UpdateTitleText()
		f:UpdateBagFrame()
		f:LoadPosition()

		lastID = lastID + 1

		table.insert(UISpecialFrames, f:GetName())

		return f
	end
end

function InventoryFrame:OnSizeChanged()
	local w, h = self:GetWidth(), self:GetHeight()
	self.sets.w = w
	self.sets.h = h

	--topleft
	local t = getglobal(self:GetName() .. 'TLRight')
	t:SetWidth(128 + (w - BASE_WIDTH)/2)

	local t = getglobal(self:GetName() .. 'TLBottom')
	t:SetHeight(128 + (h - BASE_HEIGHT)/2)

	local t = getglobal(self:GetName() .. 'TLBottomRight')
	t:SetWidth(128 + (w - BASE_WIDTH)/2)
	t:SetHeight(128 + (h - BASE_HEIGHT)/2)


	--bottomleft
	local t = getglobal(self:GetName() .. 'BLRight')
	t:SetWidth(128 + (w - BASE_WIDTH)/2)

	local t = getglobal(self:GetName() .. 'BLTop')
	t:SetHeight(128 + (h - BASE_HEIGHT)/2)

	local t = getglobal(self:GetName() .. 'BLTopRight')
	t:SetWidth(128 + (w - BASE_WIDTH)/2)
	t:SetHeight(128 + (h - BASE_HEIGHT)/2)


	--topright
	local t = getglobal(self:GetName() .. 'TRLeft')
	t:SetWidth(64 + (w - BASE_WIDTH)/2)

	local t = getglobal(self:GetName() .. 'TRBottom')
	t:SetHeight(128 + (h - BASE_HEIGHT)/2)

	local t = getglobal(self:GetName() .. 'TRBottomLeft')
	t:SetWidth(64 + (w - BASE_WIDTH)/2)
	t:SetHeight(128 + (h - BASE_HEIGHT)/2)


	--bottomright
	local t = getglobal(self:GetName() .. 'BRLeft')
	t:SetWidth(64 + (w - BASE_WIDTH)/2)

	local t = getglobal(self:GetName() .. 'BRTop')
	t:SetHeight(128 + (h - BASE_HEIGHT)/2)

	local t = getglobal(self:GetName() .. 'BRTopLeft')
	t:SetWidth(64 + (w - BASE_WIDTH)/2)
	t:SetHeight(128 + (h - BASE_HEIGHT)/2)

	self:UpdateItemFrameSize()
end

function InventoryFrame:UpdateItemFrameSize()
	local prevW, prevH = self.itemFrame:GetWidth(), self.itemFrame:GetHeight()
	local newW = self:GetWidth() + ITEM_FRAME_WIDTH_OFFSET
	if next(self.bagButtons) then
		newW = newW - 36
	end

	local newH = self:GetHeight() + ITEM_FRAME_HEIGHT_OFFSET

	if not((prevW == newW) and (prevH == newH)) then
		self.itemFrame:SetWidth(newW)
		self.itemFrame:SetHeight(newH)
		self.itemFrame:Layout()
	end
end

function InventoryFrame:AddCategory(name, icon, rule)
	local category = {['name'] = name, ['icon'] = icon, ['rule'] = rule}
	self:AddSubCategory(category, L.All)

	if self.cats then
		table.insert(self.cats, category)
	else
		self.cats = {category}
	end
	return category
end

function InventoryFrame:AddSubCategory(category, name, rule)
	local subCategory = {['name'] = name, ['rule'] = rule}
	if category.subCats then
		table.insert(category.subCats, subCategory)
	else
		category.subCats = {subCategory}
	end
end

function InventoryFrame:AddCategories()
	local class = select(2, UnitClass('player'))

	--all items: this category is most like the old bagnon window, has tabs for bag types
	--we should default to the second tab of this rule whenever we open up the window (ie, clear on close)
	do
		local category = self:AddCategory(L.All, 'Interface/Icons/INV_Misc_EngGizmos_17')

		self:AddSubCategory(category, L.Normal, function(bag)
			return CombuctorUtil:IsNormalBag(bag, self:GetPlayer())
		end)

		self:AddSubCategory(category, L.Trade, function(bag)
			return CombuctorUtil:IsProfessionBag(bag, self:GetPlayer())
		end)

		--these filters are not relevant for the bank
		if not self.isBank then
			if class == 'WARLOCK' then
				self:AddSubCategory(category, L.Shards, function(bag)
					return CombuctorUtil:IsShardBag(bag, self:GetPlayer())
				end)
			elseif class == 'HUNTER' then
				self:AddSubCategory(category, L.Ammo, function(bag)
					return CombuctorUtil:IsAmmoBag(bag, self:GetPlayer())
				end)
			end

			self:AddSubCategory(category, L.Keys, function(bag)
				return bag == KEYRING_CONTAINER
			end)
		end
	end

	--equipment filters (armor, weapon, trinket)
	do
		local function IsEquipment(bag, link, type)
			return (type == L.Armor or type == L.Weapon)
		end

		local category = self:AddCategory(L.Equipment, 'Interface/Icons/INV_Chest_Chain_04', IsEquipment)

		self:AddSubCategory(category, L.Armor, function(bag, link, type, subType, equipLoc)
			return type == L.Armor and equipLoc ~= 'INVTYPE_TRINKET'
		end)

		self:AddSubCategory(category, L.Weapon, function(bag, link, type)
			return type == L.Weapon
		end)

		self:AddSubCategory(category, L.Trinket, function(bag, link, type, subType, equipLoc)
			return type == L.Armor and equipLoc == 'INVTYPE_TRINKET'
		end)
	end

	--usable items
	--TODO: Need to add in mounts + hearthstone as a special category
	do
		local function IsUsable(bag, link, type, subType)
			if type == L.Consumable then
				return true
			elseif type == L.TradeGood then
				if subType == L.Devices or subType == L.Explosives then
					return true
				end
			end
		end

		local category = self:AddCategory(L.Usable, 'Interface/Icons/INV_Potion_93', IsUsable)

		self:AddSubCategory(category, L.Consumable, function(bag, link, type)
			return type == L.Consumable
		end)

		self:AddSubCategory(category, L.Devices, function(bag, link, type)
			return type == L.TradeGood
		end)
	end

	--quest items
	--TODO: Probably should use PT for this
	do
		local function IsQuest(bag, link, type)
			return type == L.Quest
		end
		self:AddCategory(L.Quest, 'Interface/QuestFrame/UI-QuestLog-BookIcon', IsQuest)
	end

	--trade goods + gems
	--TODO: move item gems to consumables as a tab
	do
		local category = self:AddCategory(L.TradeGood, 'Interface/Icons/INV_Fabric_Silk_02', function(bag, link, type, subType)
			if type == L.TradeGood then
				return not(subType == L.Devices or subType == L.Explosives)
			end
			return type == L.Recipe or type == L.Gem
		end)

		self:AddSubCategory(category, L.TradeGood, function(bag, link, type)
			return type == L.TradeGood
		end)

		self:AddSubCategory(category, L.Gem, function(bag, link, type)
			return type == L.Gem
		end)

		self:AddSubCategory(category, L.Recipe, function(bag, link, type)
			return type == L.Recipe
		end)
	end

	--class specific filters (not relevant to the bank)
	if not self.isBank then
		--hunter: ammo button
		if class == 'HUNTER' then
			self:AddCategory(L.Projectile, 'Interface/Icons/INV_Misc_Ammo_Bullet_01', function(bag, link, type)
				return type == L.Projectile
			end)
		end

		--warlock: shard button
		if class == 'WARLOCK' then
			local name,_, _, _, _,_,_,_,_,icon = GetItemInfo(6265)
			if name then
				self:AddCategory(name, icon, function(bag, link)
					return link and GetItemInfo(link) == name
				end)
			else
				self:AddCategory(L.SoulShard, 'Interface/Icons/INV_Misc_Gem_Amethyst_02', function(bag, link)
					return link and (link:match('%d+') == '6265')
				end)
			end
		end
	end

	self:AddCategory(L.Misc, 'Interface/Icons/INV_Misc_Rune_01', function(bag, link, type)
		return type == L.Misc and (link:match('%d+') ~= '6265')
	end)
end

--title stuff
function InventoryFrame:UpdateTitleText()
	self.title:SetFormattedText(self.titleText, self:GetPlayer())
end

--player filtering
function InventoryFrame:SetPlayer(player)
	if self:GetPlayer() ~= player then
		self.player = player
		self:UpdateBagFrame()
		self:UpdateTitleText()

		self.itemFrame:SetPlayer(player)
		self.moneyFrame:Update()
	end
end

function InventoryFrame:GetPlayer()
	return self.player or UnitName('player')
end


--[[ Frame Events ]]--

function InventoryFrame:OnShow()
	self:SetCategory(self.cats[1])
	PlaySound('igMainMenuOpen')
end

function InventoryFrame:OnHide()
	PlaySound('igMainMenuClose')

	if self.isBank then
		CloseBankFrame()
	end
	self:SetPlayer(nil)
end


--[[ Bag Frame ]]--

function InventoryFrame:ToggleBagFrame()
	self.sets.showBags = not self.sets.showBags
	self:UpdateBagFrame()
end

function InventoryFrame:UpdateBagFrame()
	self:UpdateBagToggle()

	--remove all the current bags
	for i,bag in pairs(self.bagButtons) do
		self.bagButtons[i] = nil
		bag:Release()
	end

	if self.sets.showBags then
		for _,bagID in ipairs(self.sets.bags) do
			if bagID ~= KEYRING_CONTAINER then
				local bag = CombuctorBag:Get()
				bag:Set(self, bagID)
				table.insert(self.bagButtons, bag)
			end
		end

		for i,bag in ipairs(self.bagButtons) do
			bag:ClearAllPoints()
			if i > 1 then
				bag:SetPoint('TOP', self.bagButtons[i-1], 'BOTTOM', 0, -6)
			else
				bag:SetPoint('TOPRIGHT', -48, -82)
			end
			bag:Show()
		end
	end

	self:UpdateItemFrameSize()
end

function InventoryFrame:UpdateBagToggle()
	if self.sets.showBags then
		getglobal(self:GetName() .. 'BagToggle'):LockHighlight()
	else
		getglobal(self:GetName() .. 'BagToggle'):UnlockHighlight()
	end
end


--[[ Tabs ]]--

local function Tab_OnClick(self)
	local parent = self:GetParent()

	if parent.selectedTab ~= self:GetID() then
		PlaySound("igCharacterInfoTab")
	end

	PanelTemplates_SetTab(parent, self:GetID())
	parent:SetFilter('subRule', self.rule, true)
end

function InventoryFrame:CreateTab(id)
	local tab = CreateFrame('Button', format('%sTab%d', self:GetName(), id), self, 'CombuctorFrameTabButtonTemplate')
	tab:SetScript('OnClick', Tab_OnClick)
	tab:SetID(id)

	if(id > 1) then
		tab:SetPoint('LEFT', self.tabs[id-1], 'RIGHT', -16, 0)
	else
		tab:SetPoint('CENTER', self, 'BOTTOMLEFT', 60, 46)
	end

	self.tabs[id] = tab
	return tab
end

function InventoryFrame:SetTab(id, rule)
	local tab = self.tabs[id] or self:CreateTab(id)
	tab.rule = rule.rule
	tab:SetText(rule.name)
	tab:Show()

	PanelTemplates_TabResize(0, tab)
	getglobal(tab:GetName()..'HighlightTexture'):SetWidth(tab:GetTextWidth() + 30)
end

function InventoryFrame:UpdateTabs()
	local subCat = self.category.subCats
	if subCat and #subCat > 1 then
		for i,rule in ipairs(subCat) do
			self:SetTab(i, rule)
		end

		for i = #subCat + 1, #self.tabs do
			self.tabs[i]:Hide()
		end

		PanelTemplates_SetNumTabs(self, #self.tabs)
		PanelTemplates_SetTab(self, 1)
	else
		for _,tab in pairs(self.tabs) do
			tab:Hide()
		end
		PanelTemplates_SetNumTabs(self, 0)
	end
end


--[[ Filtering ]]--

function InventoryFrame:SetCategory(category)
	local changed = false
	self.category = category
	self.sideFilter:UpdateHighlight()
	self:UpdateTabs()

	if self:SetFilter('rule', category.rule) then
		changed = true
	end

	--nasty special case, the default tab for the all frame is the second, not the first
	if category.name == L.All then
		PanelTemplates_SetTab(self, 2)
		if self:SetFilter('subRule', category.subCats[2].rule) then
			changed = true
		end
	else
		if self:SetFilter('subRule', category.subCats[1].rule) then
			changed = true
		end
	end

	if changed then
		self.itemFrame:Regenerate()
	end
end

function InventoryFrame:SetFilter(key, value, update)
	if self.filter[key] ~= value then
		self.filter[key] = value

		if key == 'quality' then
			self.qualityFilter:UpdateHighlight()
		end

		if update then
			self.itemFrame:Regenerate()
		end
		return true
	end
end


--[[ Positioning ]]--

function InventoryFrame:SavePosition(point, parent, relPoint, x, y)
	if point then
		if self.sets.position then
			self.sets.position[1] = point
			self.sets.position[2] = parent
			self.sets.position[3] = relPoint
			self.sets.position[4] = x
			self.sets.position[5] = y
		else
			self.sets.position = {point, parent, relPoint, x, y}
		end
		self:SetUserPlaced(true)
	else
		self.sets.position = nil
		self:SetUserPlaced(false)
	end
	self:UpdateManagedPosition()
end

function InventoryFrame:LoadPosition()
	if self.sets.position then
		self:SetPoint(unpack(self.sets.position))
		self:SetUserPlaced(true)
	else
		self:SetUserPlaced(nil)
	end
	self:UpdateManagedPosition()
end

function InventoryFrame:UpdateManagedPosition()
	if self.sets.position then
		if self:GetAttribute('UIPanelLayout-enabled') then
			if self:IsShown() then
				HideUIPanel(self)
				self:SetAttribute('UIPanelLayout-enabled', nil)
				ShowUIPanel(self)
			else
				self:SetAttribute('UIPanelLayout-enabled', nil)
			end
		end
	else
		if not self:GetAttribute('UIPanelLayout-enabled') then
			if self:IsShown() then
				HideUIPanel(self)
				self:SetAttribute('UIPanelLayout-enabled', true)
				ShowUIPanel(self)
			else
				self:SetAttribute('UIPanelLayout-enabled', true)
			end
		end
	end
end


--[[ Display ]]--

function InventoryFrame:ToggleFrame(auto)
	if self:IsShown() then
		self:HideFrame(auto)
	else
		self:ShowFrame(auto)
	end
end

function InventoryFrame:ShowFrame(auto)
	if not self:IsShown() then
		ShowUIPanel(self)
		self.autoShown = auto or nil
	end
end

function InventoryFrame:HideFrame(auto)
	if self:IsShown() then
		if not auto or self.autoShown then
			HideUIPanel(self)
			self.autoShown = nil
		end
	end
end