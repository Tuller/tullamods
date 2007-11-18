--[[
	frame.lua
		A combuctor frame
--]]

local L = LibStub('AceLocale-3.0'):GetLocale('Combuctor')
local ITEM_FRAME_WIDTH = 312
local BANK_FRAME_WIDTH = 568
local ITEM_FRAME_HEIGHT = 346

CombuctorFrame = Combuctor:NewModule('Combuctor-Frame')

--some crazy code, this is used for delayed updates when bag types change because of the possibility of updating in pairs
CombuctorFrame.obj = CombuctorUtil:CreateWidgetClass('Frame')
CombuctorFrame.obj:Hide()
CombuctorFrame.obj:SetScript('OnUpdate', function(self) CombuctorFrame:UpdateBagSets(); self:Hide() end)


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


--[[
	Quality Filter Widget
		used for setting what quality of items to show
--]]

local QualityFilter = {}
do
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
end


--[[
	Type Filter Widget:
		Used for setting what types of items to show
--]]

local TypeFilter = {}
do
	local types
	if GetBuildInfo() == '2.2.3' then
		local weapon, armor, _, consumable, trade, _, _, _, _, _, misc = GetAuctionItemClasses()
		types = {ALL, weapon, armor, L.Quest, consumable, trade, misc}
	else
		local weapon, armor, _, consumable, trade, _, _, _, _, misc, quest = GetAuctionItemClasses()
		types = {ALL, weapon, armor, quest, consumable, trade, misc}
	end

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
			local button = CreateFrame('CheckButton', format('CombuctorItemFilter', nextID), f, 'SpellBookSkillLineTabTemplate')
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

local InventoryFrame = CombuctorFrame.obj

--frame constructor
local lastID = 0
function InventoryFrame:Create(titleText, settings, isBank)
	local template = isBank and 'CombuctorBankTemplate' or 'CombuctorInventoryTemplate'
	local f = self:New(CreateFrame('Frame', format('CombuctorFrame%d', lastID), UIParent, template))
	f:SetScript('OnShow', self.OnShow)
	f:SetScript('OnHide', self.OnHide)
	f:SetAttribute('UIPanelLayout-pushable', settings.pushable)

	f.sets = settings
	f.isBank = isBank
	f.titleText = titleText

	f.bagButtons = {}
	f.bagSets = {}
	f.tabs = {}

	f.title = getglobal(f:GetName() .. 'Title')

	f.typeFilter = TypeFilter:Create(f)

	f.qualityFilter = QualityFilter:Create(f)
	f.qualityFilter:SetPoint('BOTTOMLEFT', 24, 65)

	f.itemFrame = CombuctorItemFrame:Create(f)
	f.itemFrame:SetPoint('TOPLEFT', 24, -78)
	f.itemFrame:SetHeight(ITEM_FRAME_HEIGHT)

	f.moneyFrame = CombuctorMoneyFrame:Create(f)
	f.moneyFrame:SetPoint('BOTTOMRIGHT', -40, 67)

	f:UpdateTitleText()
	f:GenerateBagSets()
	f:UpdateBagFrame()
	f:LoadPosition()

	lastID = lastID + 1

	return f
end


--title stuff
function InventoryFrame:UpdateTitleText()
	self.title:SetFormattedText(self.titleText, self:GetPlayer())
end

--player filtering
function InventoryFrame:SetPlayer(player)
	if self:GetPlayer() ~= player then
		self.player = player
		self:GenerateBagSets()
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
	PlaySound('igMainMenuOpen')
end

function InventoryFrame:OnHide()
	PlaySound('igMainMenuClose')

	if self.isBank then
		CloseBankFrame()
	end
	self:SetPlayer(nil)
end


--[[ Bag Frame Code ]]--

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
		for _,bagID in ipairs(self:GetCurrentBagSet()) do
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

	local prevWidth = self.itemFrame:GetWidth()
	local width = self.isBank and BANK_FRAME_WIDTH or ITEM_FRAME_WIDTH
	if next(self.bagButtons) then
		self.itemFrame:SetWidth(width - 36)
	else
		self.itemFrame:SetWidth(width)
	end

	if prevWidth ~= self.itemFrame:GetWidth() then
		self.itemFrame:Layout()
	end
end

function InventoryFrame:UpdateBagToggle()
	if self.sets.showBags then
		getglobal(self:GetName() .. 'BagToggle'):LockHighlight()
	else
		getglobal(self:GetName() .. 'BagToggle'):UnlockHighlight()
	end
end


--[[ Bag Set Code ]]--

local BAG_SETS = {
	L.Normal,
	L.Trade,
	L.Ammo,
	L.Shards,
	L.Keys,
}

function InventoryFrame:GenerateBagSets()
	--clear out all of the old bag sets
	for _,bags in pairs(self.bagSets) do
		for i in pairs(bags) do bags[i] = nil end
	end

	--iterate through all bags, adding each to the appropiate bag set
	local player = self:GetPlayer()
	for _,bag in ipairs(self.sets.bags) do
		if bag == KEYRING_CONTAINER then
			self:AddBagToSet(bag, L.Keys)
		elseif CombuctorUtil:IsShardBag(bag, player) then
			self:AddBagToSet(bag, L.Shards)
		elseif CombuctorUtil:IsAmmoBag(bag, player) then
			self:AddBagToSet(bag, L.Ammo)
		elseif CombuctorUtil:IsProfessionBag(bag, player) then
			self:AddBagToSet(bag, L.Trade)
		else
			self:AddBagToSet(bag, L.Normal)
		end
	end

	--update tabs
	local numTabs = 0
	for _,setName in ipairs(BAG_SETS) do
		local bags = self.bagSets[setName]
		if bags and next(bags) then
			numTabs = numTabs + 1
			self:SetTab(numTabs, setName, bags)
		end
	end

	--hide all tabs if there's only one category to display
	if numTabs == 1 then
		for _,tab in ipairs(self.tabs) do
			tab:Hide()
		end
		self:SetClampRectInsets(0, 0, 0, 64)
	else
		for i = numTabs + 1, #self.tabs do
			self.tabs[i]:Hide()
			self.tabs[i].unused = true
		end
		self:SetClampRectInsets(0, 0, 0, 37)
	end

	PanelTemplates_SetNumTabs(self, numTabs)
	self:SetPanel(1, true)
end

--update visible tabs based on what bags we have. should be run whenever bags change, basically
function InventoryFrame:AddBagToSet(bag, set)
	if self.bagSets[set] then
		table.insert(self.bagSets[set], bag)
	else
		self.bagSets[set] = {bag}
	end
end

function InventoryFrame:GetCurrentBagSet()
	return self.tabs[self:GetSelectedTab()].bags
end
InventoryFrame.GetSelectedTab = PanelTemplates_GetSelectedTab


--[[ Tab Code ]]--

function InventoryFrame:CreateTab(id)
	local tab = CreateFrame('Button', format('%sTab%d', self:GetName(), id), self, 'CombuctorFrameTabButtonTemplate')
	tab:SetID(id)

	if(id > 1) then
		tab:SetPoint('LEFT', self.tabs[id-1], 'RIGHT', -16, 0)
	else
		tab:SetPoint('CENTER', self, 'BOTTOMLEFT', 60, 46)
	end

	self.tabs[id] = tab
	return tab
end

function InventoryFrame:SetTab(id, text, bags)
	local tab = self.tabs[id] or self:CreateTab(id)
	tab.bags = bags
	tab:SetText(text)
	tab:Show()

	PanelTemplates_TabResize(0, tab)
	getglobal(tab:GetName()..'HighlightTexture'):SetWidth(tab:GetTextWidth() + 30)
end


--[[ Panel Code ]]--

--sets the given frame to show only the given tab's bags
function InventoryFrame:SetPanel(id, forceUpdate)
	if self:GetSelectedTab() ~= id or forceUpdate then
		PanelTemplates_SetTab(self, id)

		self:UpdateBagFrame()
		self.itemFrame:SetBags(self:GetCurrentBagSet())
	end
end

--show if not shown, switch tabs if we've already been automatically shown, or if we're switching tabs manually
function InventoryFrame:ShowPanel(id, auto)
	if not self:IsShown() then
		self.auto = auto
		self:SetPanel(id)
		ShowUIPanel(self)
	elseif self.auto or not auto then
		self:SetPanel(id)
	end
end

--hide if automatically shown, or if manually told to hide
function InventoryFrame:HidePanel(id, auto)
	if self.auto or not auto then
		self.auto = nil
		HideUIPanel(self)
		self:SetPanel(1)
	end
end

--if shown, and on the selected tab, then hide, else show the frame and switch to the appropiate tab
function InventoryFrame:TogglePanel(id, auto)
	if self:IsShown() then
		if self.selectedTab == id then
			self:HidePanel(id, auto)
		else
			self:ShowPanel(id, auto)
		end
	else
		self:ShowPanel(id, auto)
	end
end


--[[ Show/Hide/Toggle Frame Functions ]]--

--set which panel to show, based on the given bag
function InventoryFrame:ShowBag(bag, auto)
	for id,tab in pairs(self.tabs) do
		if id > self.numTabs then
			return
		else
			for _,bagID in pairs(tab.bags) do
				if bagID == bag then
					self:ShowPanel(id, auto)
					break
				end
			end
		end
	end
end

function InventoryFrame:HideBag(bag, auto)
	for id,tab in pairs(self.tabs) do
		if id > self.numTabs then
			return
		else
			for _,bagID in pairs(tab.bags) do
				if bagID == bag then
					self:HidePanel(id, auto)
					break
				end
			end
		end
	end
end

function InventoryFrame:ToggleBag(bag, auto)
	for id,tab in pairs(self.tabs) do
		if id > self.numTabs then
			return
		else
			for _,bagID in pairs(tab.bags) do
				if bagID == bag then
					self:TogglePanel(id, auto)
					break
				end
			end
		end
	end
end


--[[ Settings Loading ]]--

function InventoryFrame:SavePosition(...)
	if self:IsUserPlaced() then
		if self.sets.position then
			local numPoints = select('#', ...)
			for i = 1, numPoints do
				self.sets.position[i] = select(i, ...)
			end
			for i = numPoints + 1, #self.sets.position do
				self.sets.position[i] = nil
			end
		else
			self.sets.position = {...}
		end
	else
		self.sets.position = nil
	end
end

function InventoryFrame:LoadPosition()
	if self.sets.position then
		self:SetPoint(unpack(self.sets.position))
		self:SetUserPlaced(true)
		self:SetAttribute('UIPanelLayout-enabled', nil)
	else
		self:SetUserPlaced(false)
		self:SetAttribute('UIPanelLayout-enabled', true)
	end
	if self:IsShown() then
		HideUIPanel(self)
		ShowUIPanel(self)
	end
end