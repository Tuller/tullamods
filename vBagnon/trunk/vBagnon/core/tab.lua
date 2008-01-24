--[[
	BagnonTab
		A category tab, which is a virtual bag?
--]]

BagnonTab = CreateFrame('CheckButton')
local Tab_mt = {__index = BagnonTab}

local UNKNOWN_ITEM = 'Interface\\Icons\\INV_Misc_QuestionMark'

--Creates a temporary inventory frame for the player of all items in the set defined by a tab
local function CreateFrameFromTab(tab)
	local frame = tab:GetParent():GetParent()		
	local cat = frame:GetCat(tab:GetID())	

	local newCat = TLib.TCopy(cat)
	newCat.hide = nil

	local bags = {}
	for i, bag in ipairs(frame:GetBags()) do
		bags[i] = bag
	end

	Bagnon_AnchorAtCursor(BagnonFrame.Create(newCat.name, bags, {newCat}))
end

--[[ Constructor ]]--

local function OnClick() this:OnClick(arg1) this:OnEnter() end
local function OnEnter() this:OnEnter() end
local function OnLeave() this:OnLeave() end

local function OnDragStart()
	this:OnLeave()
	this:StartMoving()
end

local function OnDragStop()
	this:OnDragStop()
	this:OnEnter()
end

local function Tab_Create(lastCreated)
	local name = 'BagnonTab' .. lastCreated
	local tab = CreateFrame('CheckButton', name, nil, 'ItemButtonTemplate')
	setmetatable(tab, Tab_mt)
	
	tab:SetWidth(24); tab:SetHeight(24)
	tab:SetMovable(true)
	
	local normalTexture = tab:GetNormalTexture()
	normalTexture:SetWidth(41); normalTexture:SetHeight(41)
	
	local checkedTexture = tab:CreateTexture(nil, 'ARTWORK')
	checkedTexture:SetTexture("Interface\\Buttons\\CheckButtonHilight")
	checkedTexture:SetBlendMode('ADD')
	checkedTexture:SetAllPoints(tab)
	tab:SetCheckedTexture(checkedTexture)
	
	tab:RegisterForDrag("LeftButton")
	tab:RegisterForClicks("anyUp")

	tab:SetScript('OnClick', OnClick)
	tab:SetScript('OnDragStart', OnDragStart)
	tab:SetScript('OnDragStop', OnDragStop)
	tab:SetScript('OnEnter', OnEnter)
	tab:SetScript('OnLeave', OnLeave)

	return tab
end

--[[ Methods ]]--

function BagnonTab.Get()
	return TPool.Get('BagnonTab', Tab_Create)	
end

function BagnonTab:Set(parent, catIndex)
	Bagnon_AttachToFrame(self, parent)

	self:SetID(catIndex)
	self:Update()
end

function BagnonTab:Release()
	return TPool.Release(self, 'BagnonTab')
end

function BagnonTab:Update()
	local frame = self:GetParent():GetParent()
	local cat = frame:GetCat(self:GetID())
	local rule = frame:GetCatRule(self:GetID())
	local player = frame:GetPlayer()	
	local icon

	if rule then
		for _, bag in ipairs(frame:GetBags()) do
			if Bagnon_IsCachedBag(player, bag) then
				for slot = 1, Bagnon_GetSize(bag, player) do
					local link, _, texture = BagnonDB.GetItemData(player, bag, slot)
					if rule(link, bag) then
						icon = texture
						if icon then break end
					end
				end
			else
				for slot = 1, Bagnon_GetSize(bag, player) do
					if rule(GetContainerItemLink(bag, slot), bag) then
						icon = (GetContainerItemInfo(bag, slot))
						if icon then break end
					end
				end
			end
		end
	end

	self:SetChecked(not cat.hide)
	getglobal(self:GetName() .. 'IconTexture'):SetTexture(icon or UNKNOWN_ITEM)
end

--[[ OnX ]]--

function BagnonTab:OnClick(mouseButton)
	local frame = self:GetParent():GetParent()
	if mouseButton == 'LeftButton' then
		frame:ToggleCat(self:GetID())
	elseif mouseButton == 'RightButton' then
		self:SetChecked(not self:GetChecked())
		BagnonCatMenu_Show(frame, self)
	end
end

function BagnonTab:OnEnter()
	local frame = self:GetParent():GetParent()
	local cat = frame:GetCat(self:GetID())
	local name = cat.name
	local items, empty = frame:GetCatSlotCount(self:GetID())
	local title
	
	Bagnon_AnchorTooltip(self)

	if items > 0 and empty > 0 then
		title = BAGNON_TAB_TITLE_MIXED:format(name, items, empty)
	elseif items == 0 and empty == 0 then
		title = name
	elseif empty > 0 then
		title = BAGNON_TAB_TITLE_EMPTY:format(name, empty)
	else
		title = BAGNON_TAB_TITLE:format(name, items)
	end
	GameTooltip:AddLine(title, 1, 1, 1)
	
	local sets = Bagnon_GetPlayerSets()
	if sets.showTooltips then
		GameTooltip:AddLine(BAGNON_TAB_TOGGLE)
		GameTooltip:AddLine(BAGNON_TAB_SWAP)
		GameTooltip:AddLine(BAGNON_TAB_NEW_WINDOW)
	end
	GameTooltip:Show()
	
	frame:HighlightRule(frame:GetCatRule(self:GetID()), true)
end

function BagnonTab:OnLeave()
	local frame = self:GetParent():GetParent()	

	GameTooltip:Hide()
	
	frame:HighlightRule(frame:GetCatRule(self:GetID()), nil)
end

function BagnonTab:OnDragStop()
	local parent = self:GetParent()
	local frame = parent:GetParent()
	
	if MouseIsOver(parent) then
		for _,tab in pairs(parent.tabs) do
			if MouseIsOver(tab) and tab ~= self then
				frame:SwapCats(self:GetID(), tab:GetID())			
				tab:Update()
				self:Update()
				break
			end
		end
	else
		CreateFrameFromTab(self)
	end
	
	self:StopMovingOrSizing()
	parent:Layout()
end