--[[
	frame.lua
		A combuctor frame
--]]

local ITEM_FRAME_WIDTH = 312
local ITEM_FRAME_HEIGHT = 346


--[[
	Quality Filter Widget
		used for setting what quality of items to show
--]]

local QualityFilter = {}

function QualityFilter:Create(parent)
	local f = CreateFrame('Frame', nil, parent)
	local size = 20

	local prev
	for i = -1, 5 do
		local button = CreateFrame('Button', nil, f, 'UIRadioButtonTemplate')
		if i > -1 then
			local bg = button:CreateTexture(nil, 'BACKGROUND')
			bg:SetWidth(size/2)
			bg:SetHeight(size/2)
			bg:SetPoint('CENTER')

			local r,g,b = GetItemQualityColor(i)
			bg:SetTexture(r,g,b)
			button.bg = bg
		end

		button:SetScript('OnClick', self.OnClick)
		button:SetScript('OnEnter', self.OnEnter)
		button:SetScript('OnLeave', self.OnLeave)
		button:SetWidth(size); button:SetHeight(size)
		button:SetID(i)

		if prev then
			button:SetPoint('LEFT', prev, 'RIGHT', 1, 0)
			if button.bg then
				button.bg:SetAlpha(0.5)
			end
		else
			button:SetPoint('LEFT')
			button:GetNormalTexture():SetVertexColor(1, 1, 0)
			button:LockHighlight()
		end
		prev = button
	end

	f:SetWidth(size * 5)
	f:SetHeight(size)

	return f
end

function QualityFilter:OnClick()
	local id = self:GetID()
	local quality = (id >= 0 and id) or nil

	self:GetParent():GetParent().itemFrame:SetFilter('quality', quality)

	for i = 1, select('#', self:GetParent():GetChildren()) do
		local child = select(i, self:GetParent():GetChildren())
		if child == self then
			child:GetNormalTexture():SetVertexColor(1, 0.82, 0)
			child:LockHighlight()
			if child.bg then
				child.bg:SetAlpha(1)
			end
		else
			child:GetNormalTexture():SetVertexColor(1, 1, 1)
			child:UnlockHighlight()
			if child.bg then
				child.bg:SetAlpha(0.5)
			end
		end
	end
end

function QualityFilter:OnEnter()
	GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')

	local quality = self:GetID()
	if quality > -1 then
		local r,g,b = GetItemQualityColor(quality)
		GameTooltip:SetText(getglobal(format('ITEM_QUALITY%d_DESC', quality)), r, g, b)
	else
		GameTooltip:SetText(ALL)
	end

	GameTooltip:Show()
end

function QualityFilter:OnLeave()
	GameTooltip:Hide()
end


--[[
	Type Filter Widget:
		Used for setting what types of items to show
--]]

local TypeFilter = {}
do
	local types = {'All', 'Weapon', 'Armor', 'Quest', 'Consumable', 'Trade Goods', 'Miscellaneous'}

	local typeIcons = {
		'Interface/Icons/INV_Misc_EngGizmos_17',
		'Interface/Icons/INV_Sword_23',
		'Interface/Icons/INV_Chest_Chain_04',
		'Interface/QuestFrame/UI-QuestLog-BookIcon',
		'Interface/Icons/INV_Potion_93',
		'Interface/Icons/INV_Fabric_Silk_02',
		'Interface/Icons/INV_Misc_Rune_01',
	}

	local nextID = 0
	function TypeFilter:Create(parent)
		local f = CreateFrame('Frame', nil, parent)

		local prev
		for i,type in ipairs(types) do
			local button = CreateFrame('CheckButton', format('CombuctorItemFilter', nextID), f, 'CombuctorFrameSideButtonTemplate')
			button:SetNormalTexture(typeIcons[i])
			button:GetNormalTexture():SetTexCoord(0.06, 0.94, 0.06, 0.94)
			button:SetScript('OnClick', self.OnClick)
			button:SetScript('OnEnter', self.OnEnter)
			button:SetScript('OnLeave', self.OnLeave)
			button:Show()

			if type ~= 'All' then
				button.type = (type ~= 'All' and type) or nil
			end

			if prev then
				button:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -17)
			else
				button:SetPoint('TOPLEFT', parent, 'TOPRIGHT', -32, -65)
				button:SetChecked(true)
			end
			prev = button
		end

		return f
	end

	function TypeFilter:OnClick()
		self:GetParent():GetParent().itemFrame:SetFilter('type', self.type)

		for i = 1, select('#', self:GetParent():GetChildren()) do
			local child = select(i, self:GetParent():GetChildren())
			child:SetChecked(child == self)
		end
	end

	function TypeFilter:OnEnter()
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		GameTooltip:SetText(self.type or ALL)
		GameTooltip:Show()
	end

	function TypeFilter:OnLeave()
		GameTooltip:Hide()
	end
end


--[[
	Inventory Frame Widget
--]]

CombuctorFrame = CombuctorUtil:CreateWidgetClass('Frame')

--frame constructor
local lastID = 0
function CombuctorFrame:Create(titleText, settings, isBank)
	local f = self:New(CreateFrame('Frame', format('CombuctorFrame%d', lastID), UIParent, 'CombuctorFrameTemplate'))
	f:SetScript('OnShow', self.OnShow)
	f:SetScript('OnHide', self.OnHide)

	f.sets = settings
	f.isBank = isBank
	f.titleText = titleText

	f.panelBags = {}
	f.bagButtons = {}

	f.title = getglobal(f:GetName() .. 'Title')

	f.typeFilter = TypeFilter:Create(f)

	f.qualityFilter = QualityFilter:Create(f)
	f.qualityFilter:SetPoint('BOTTOMLEFT', 24, 65)

	f.itemFrame = CombuctorItemFrame:Create(f)
	f.itemFrame:SetPoint('TOPLEFT', 24, -78)
	f.itemFrame:SetWidth(312)
	f.itemFrame:SetHeight(346)

	f.moneyFrame = CombuctorMoneyFrame:Create(f)
	f.moneyFrame:SetPoint('BOTTOMRIGHT', -40, 67)

	f:UpdateTitleText()
	f:UpdateTabs()

	lastID = lastID + 1

	return f
end


--title stuff
function CombuctorFrame:UpdateTitleText()
	self.title:SetText(self.titleText:format(self:GetPlayer()))
end

--player filtering
function CombuctorFrame:SetPlayer(player)
	if self:GetPlayer() ~= player then
		self.player = player
		self:UpdateTitleText()
		self:UpdateTabs()
		self.moneyFrame:Update()
		self.itemFrame:SetPlayer(player)
	end
end

function CombuctorFrame:GetPlayer()
	return self.player or UnitName('player')
end


--frame events
function CombuctorFrame:OnShow()
	PlaySound('igMainMenuOpen')
end

function CombuctorFrame:OnHide()
	self:SetPlayer(UnitName('player'))

	if self.isBank then
		CloseBankFrame()
	end
	PlaySound('igMainMenuClose')
end


--frame tabs and their respective bags
--add in all panels
function CombuctorFrame:SetTab(id, text)
	self.tabs = self.tabs or {}

	local tab = self.tabs[id]
	if not tab then
		tab = CreateFrame('Button', self:GetName() .. format('Tab%d', id), self, 'CombuctorFrameTabButtonTemplate')
		tab:SetID(id)

		if(id > 1) then
			tab:SetPoint('LEFT', self.tabs[id-1], 'RIGHT', -16, 0)
		else
			tab:SetPoint('CENTER', self, 'BOTTOMLEFT', 60, 46)
		end

		self.tabs[id] = tab
	end

	tab:Show()
	tab:SetText(text)
	PanelTemplates_TabResize(0, tab)
	getglobal(tab:GetName()..'HighlightTexture'):SetWidth(tab:GetTextWidth() + 30)
end

--update visible tabs based on what bags we have. should be run whenever bags change, basically
function CombuctorFrame:UpdateTabs()
	local tradeBags, normalBags, ammoBags, shardBags, keyBags
	local player = self:GetPlayer()

	for _,bag in ipairs(self.sets.bags) do
		if bag == KEYRING_CONTAINER then
			if not keyBags then
				keyBags = {}
			end
			table.insert(keyBags, bag)
		elseif CombuctorUtil:IsAmmoBag(bag, player) then
			if not ammoBags then
				ammoBags = {}
			end
			table.insert(ammoBags, bag)
		elseif CombuctorUtil:IsShardBag(bag, player) then
			if not shardBags then
				shardBags = {}
			end
			table.insert(shardBags, bag)
		elseif CombuctorUtil:IsProfessionBag(bag, player) then
			if not tradeBags then
				tradeBags = {}
			end
			table.insert(tradeBags, bag)
		else
			if not normalBags then
				normalBags = {}
			end
			table.insert(normalBags, bag)
		end
	end

	self.panelBags = {}
	local panelBags = self.panelBags
	for i in pairs(panelBags) do
		panelBags[i] = nil
	end

	if normalBags and next(normalBags) then
		table.insert(panelBags, normalBags)
		self:SetTab(#panelBags, 'Normal')
	end

	if tradeBags and next(tradeBags) then
		table.insert(panelBags, tradeBags)
		self:SetTab(#panelBags, 'Trade')
	end

	if ammoBags and next(ammoBags) then
		table.insert(panelBags, ammoBags)
		self:SetTab(#panelBags, 'Ammo')
	end

	if shardBags and next(shardBags) then
		table.insert(panelBags, shardBags)
		self:SetTab(#panelBags, 'Shards')
	end

	if keyBags and next(keyBags) then
		table.insert(panelBags, keyBags)
		self:SetTab(#panelBags, 'Keys')
	end

	--hide all tabs if there's only one category to display
	if #panelBags == 1 then
		for _,tab in ipairs(self.tabs) do
			tab:Hide()
		end
	else
		for i = #panelBags + 1, #self.tabs do
			self.tabs[i]:Hide()
		end
	end

	PanelTemplates_SetNumTabs(self, #panelBags)
	self:SetPanel(1, true)
end


--[[ Panel Functions ]]--

--sets the given frame to show only the given tab's bags
function CombuctorFrame:SetPanel(id, forceUpdate)
	if(self.selectedTab ~= id or forceUpdate) then
		PanelTemplates_SetTab(self, id)

		self.currentBags = self.panelBags[id]
		self.itemFrame:SetBags(self.currentBags)
		if self:IsShown() then
			self:UpdateBagFrame()
		end
	end
end

function CombuctorFrame:ShowPanel(id)
	self:SetPanel(id)
	if not self:IsShown() then
		ShowUIPanel(self)
	end
end

function CombuctorFrame:HidePanel(id)
	HideUIPanel(self)
	self:SetPanel(1)
end

function CombuctorFrame:TogglePanel(id)
	if self:IsShown() then
		if self.selectedTab == id then
			self:HidePanel(id)
		else
			self:ShowPanel(id)
		end
	else
		self:ShowPanel(id)
	end
end


--[[ Bag Frame Functions ]]--

function CombuctorFrame:ToggleBagFrame()
	self.sets.showBags = not self.sets.showBags
	self:UpdateBagToggleHighlight()
	self:UpdateBagFrame()
end

function CombuctorFrame:UpdateBagToggleHighlight()
	if self.sets.showBags then
		getglobal(self:GetName() .. 'BagToggle'):LockHighlight()
	else
		getglobal(self:GetName() .. 'BagToggle'):UnlockHighlight()
	end
end

function CombuctorFrame:UpdateBagFrame()
	--remove all the current bags
	for i,bag in pairs(self.bagButtons) do
		self.bagButtons[i] = nil
		bag:Release()
	end

	if self.sets.showBags then
		for _,bagID in ipairs(self.currentBags) do
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
				bag:SetPoint('TOPLEFT', 340 - 36, -82)
			end
			bag:Show()
		end
	end

	local prevWidth = self.itemFrame:GetWidth()
	if next(self.bagButtons) then
		self.itemFrame:SetWidth(ITEM_FRAME_WIDTH - 36)
	else
		self.itemFrame:SetWidth(ITEM_FRAME_WIDTH)
	end

	if prevWidth ~= self.itemFrame:GetWidth() then
		self.itemFrame:Layout()
	end
end


--[[ Visibility Functions ]]--

--set which panel to show, based on the given bag
function CombuctorFrame:ShowBag(bag, auto)
	for tab,bags in pairs(self.panelBags) do
		for _,id in pairs(bags) do
			if id == bag then
				self:ShowPanel(tab, auto)
				break
			end
		end
	end
end

function CombuctorFrame:HideBag(bag, auto)
	for tab,bags in pairs(self.panelBags) do
		for _,id in pairs(bags) do
			if id == bag then
				self:HidePanel(tab, auto)
				break
			end
		end
	end
end

function CombuctorFrame:ToggleBag(bag, auto)
	for tab,bags in pairs(self.panelBags) do
		for _,id in pairs(bags) do
			if id == bag then
				self:TogglePanel(tab, auto)
				break
			end
		end
	end
end