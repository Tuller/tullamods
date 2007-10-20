--[[
	Combuctor.lua
		The combuctor frame
--]]

--creates a new class of objects that inherits from objects of <type>, ex 'Frame', 'Button', 'StatusBar'
--does not chain inheritance
local function CreateWidgetClass(type)
	local class = CreateFrame(type)
	local mt = {__index = class}

	function class:New(o)
		if o then
			local type, cType = o:GetFrameType(), self:GetFrameType()
			assert(type == cType, format('\'%s\' expected, got \'%s\'', cType, type))
		end
		return setmetatable(o or CreateFrame(type), mt)
	end

	return class
end


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
			bg:SetWidth(size/2); bg:SetHeight(size/2)
			bg:SetPoint('CENTER')

			local r,g,b = GetItemQualityColor(i)
			bg:SetTexture(r,g,b, 0.5)
		end

		button:SetScript('OnClick', self.OnClick)
		button:SetWidth(size); button:SetHeight(size)
		button:SetID(i)

		if prev then
			button:SetPoint('LEFT', prev, 'RIGHT', 1, 0)
		else
			button:SetPoint('LEFT')
			button:GetNormalTexture():SetVertexColor(1, 0.82, 0)
			button:LockHighlight()
		end
		prev = button
	end

	f:SetWidth(size * 5); f:SetHeight(size)

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
		else
			child:GetNormalTexture():SetVertexColor(1, 1, 1)
			child:UnlockHighlight()
		end
	end
end


--[[
	Type Filter Widget:
		Used for setting what types of items to show
--]]

local TypeFilter = {}
do
	local types = {'All', 'Weapon', 'Armor', 'Quest', 'Consumable', 'Trade Goods', 'Miscellaneous'}

	local typeIcons = {
		'INV_Misc_Bag_08',
		'INV_Sword_23',
		'INV_Chest_Chain_04',
		'INV_Torch_Lit',
		'INV_Potion_91',
		'INV_Fabric_Silk_02',
		'Ability_Mount_RidingHorse',
	}

	local nextID = 0
	function TypeFilter:Create(parent)
		local f = CreateFrame('Frame', nil, parent)

		local prev
		for i,type in ipairs(types) do
			local button = CreateFrame('CheckButton', format('CombuctorItemFilter', nextID), f, 'CombuctorFrameSideButtonTemplate')
			button:SetNormalTexture('Interface/Icons/' .. typeIcons[i])
			button:GetNormalTexture():SetTexCoord(0.06, 0.94, 0.06, 0.94)
			button:SetScript('OnClick', self.OnClick)
			button:SetScript('OnEnter', nil)
			button:SetScript('OnLeave', nil)
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
end

--[[
	Inventory Frame Widget
		is container object!
--]]

CombuctorFrame = CreateWidgetClass('Frame')


--frame constructor
local lastID = 0
function CombuctorFrame:Create(titleText, settings, isBank)
	local f = self:New(CreateFrame('Frame', format('CombuctorFrame%d', lastID), UIParent, 'CombuctorFrameTemplate'))
	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnHide', f.OnHide)

	f.sets = settings
	f.titleText = titleText

	f.title = getglobal(f:GetName() .. 'Title')

	TypeFilter:Create(f)

	f.qualityFilter = QualityFilter:Create(f)
	f.qualityFilter:SetPoint('BOTTOMLEFT', 24, 65)

	f.itemFrame = CombuctorItemFrame:Create(f)
	f.itemFrame:SetPoint('TOPLEFT', f, 'TOPLEFT', 24, -78)
	f.itemFrame:SetWidth(312)
	f.itemFrame:SetHeight(346)

	--[[
		TODO:
		- clear filters button
		- bagFrame + bagFrame toggle
	--]]

	f:UpdateTitleText()
	f:UpdateTabs()
	f.isBank = isBank

	lastID = lastID + 1

	return f
end


--title stuff
function CombuctorFrame:UpdateTitleText()
	self.title:SetText(self.titleText:format(self:GetPlayer()))
end


--position stuff
function CombuctorFrame:SavePosition()
	if self:GetPoint() then
		self.sets.position = {self:GetPoint()}
	else
		self.sets.position = nil
	end
end

function CombuctorFrame:LoadPosition()
	self:ClearAllPoints()

	local pushable = self.sets.pushable
	if pushable then
		self:SetUserPlaced(false)
		self:SetAttribute('UIPanelLayout-pushable', pushable)
	else
		local position = self.sets.position
		if position then
			self:SetPoint(unpack(position))
		else
			self:SetPoint('CENTER')
		end
	end
end


--player filtering
function CombuctorFrame:SetPlayer(player)
	if self:GetPlayer() ~= player then
		self.player = player
		self:UpdateTitleText()
		self:UpdateTabs()
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
	self:SetPlayer(nil)

	PlaySound('igMainMenuClose')
	if self.isBank then
		CloseBankFrame()
	end
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
	local tradeBags, normalBags, ammoBags, keyBags

	for _,bag in ipairs(self.sets.bags) do
		if bag == KEYRING_CONTAINER then
			if not keyBags then
				keyBags = {}
			end
			table.insert(keyBags, bag)
		elseif CombuctorUtil:IsAmmoBag(bag, self:GetPlayer()) then
			if not ammoBags then
				ammoBags = {}
			end
			table.insert(ammoBags, bag)
		elseif CombuctorUtil:IsProfessionBag(bag, self:GetPlayer()) then
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
		local text = (select(2, UnitClass('player')) == 'WARLOCK' and 'Shards') or 'Ammo'
		self:SetTab(#panelBags, text)
	end

	if keyBags and next(keyBags) then
		table.insert(panelBags, keyBags)
		self:SetTab(#panelBags, 'Keys')
	end

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
		self.itemFrame:SetBags(self.panelBags[id])
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