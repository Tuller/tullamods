--[[
	frame.lua
		A combuctor frame object
--]]

local InventoryFrame  = Combuctor:NewClass('Frame')
Combuctor.Frame = InventoryFrame

--local references
local _G = getfenv(0)
local L = LibStub('AceLocale-3.0'):GetLocale('Combuctor')

--constants
local BASE_WIDTH = 384
local ITEM_FRAME_WIDTH_OFFSET = 312 - BASE_WIDTH
local BASE_HEIGHT = 512
local ITEM_FRAME_HEIGHT_OFFSET = 346 - BASE_HEIGHT


--frame constructor
local lastID = 1
function InventoryFrame:New(titleText, settings, isBank)
	local f = self:Bind(CreateFrame('Frame', format('CombuctorFrame%d', lastID), UIParent, 'CombuctorInventoryTemplate'))
	f:SetScript('OnShow', self.OnShow)
	f:SetScript('OnHide', self.OnHide)

	f.sets = settings
	f.isBank = isBank
	f.titleText = titleText

	f.bagButtons = {}
	f.filter = {}

	f:SetWidth(settings.w or BASE_WIDTH)
	f:SetHeight(settings.h or BASE_HEIGHT)

	f.title = _G[f:GetName() .. 'Title']

	f.sideFilter = Combuctor.SideFilter:New(f)
	f.bottomFilter = Combuctor.BottomFilter:New(f)

	f.nameFilter = _G[f:GetName() .. 'Search']

	f.qualityFilter = Combuctor.QualityFilter:New(f)
	f.qualityFilter:SetPoint('BOTTOMLEFT', 24, 65)

	f.itemFrame = Combuctor.ItemFrame:New(f)
	f.itemFrame:SetPoint('TOPLEFT', 24, -78)

	f.moneyFrame = Combuctor.MoneyFrame:New(f)
	f.moneyFrame:SetPoint('BOTTOMRIGHT', -40, 67)

	f:UpdateTitleText()
	f:UpdateBagFrame()
	f:LoadPosition()

	lastID = lastID + 1

	table.insert(UISpecialFrames, f:GetName())
	Combuctor:GetModule('InventoryFrameEvents'):Register(f)
	
	return f
end


--[[
	Title Frame
--]]

function InventoryFrame:UpdateTitleText()
	self.title:SetFormattedText(self.titleText, self:GetPlayer())
end

function InventoryFrame:OnTitleEnter(title)
	GameTooltip:SetOwner(title, 'ANCHOR_LEFT')
	GameTooltip:SetText(title:GetText(), 1, 1, 1)
	GameTooltip:AddLine(L.MoveTip)
	GameTooltip:AddLine(L.ResetPositionTip)
	GameTooltip:Show()
end


--[[
	Bag Toggle
--]]

function InventoryFrame:OnBagToggleClick(toggle, button)
	if button == 'LeftButton' then
		_G[toggle:GetName() .. "Icon"]:SetTexCoord(0.075, 0.925, 0.075, 0.925)
		self:ToggleBagFrame()
	else
		if self.isBank then
			Combuctor:Toggle(BACKPACK_CONTAINER)
		else
			Combuctor:Toggle(BANK_CONTAINER)
		end
	end
end

function InventoryFrame:OnBagToggleEnter(toggle)
	GameTooltip:SetOwner(toggle, 'ANCHOR_LEFT')

	GameTooltip:SetText(L.Bags, 1, 1, 1)
	GameTooltip:AddLine(L.Bags)
	if self.isBank then
		GameTooltip:AddLine(L.InventoryToggle)
	else
		GameTooltip:AddLine(L.BankToggle)
	end
	GameTooltip:Show()
end


--[[
	Bag Frame
--]]

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
				local bag = Combuctor.Bag:Get()
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
		_G[self:GetName() .. 'BagToggle']:LockHighlight()
	else
		_G[self:GetName() .. 'BagToggle']:UnlockHighlight()
	end
end


--[[
	Filtering
--]]

--player
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

function InventoryFrame:HasSet(setName)
	for i,set in self:GetSets() do
		if set.name == setName then
			return i
		end
	end
	return false
end

function InventoryFrame:HasSubSet(setName, parentSetName)
	for _,set in self:GetSets() do
		--parent set found...
		if set.name == parentSetName then
			--see if the  child set is excluded or not, if so then blow up
			if set.exclude then
				for _,childSetName in pairs(set.exclude) do
					if childSetName == setName then
						return false
					end
				end
			end
			return true
		end
	end
	return false
end

function InventoryFrame:GetSets()
	return ipairs(self.sets.sets)
end


--general
function InventoryFrame:SetCategory(set)
	if self:SetFilter('rule', set.rule) then
		self.category = set.name
		self.sideFilter:UpdateHighlight()

		self.bottomFilter:UpdateFilters()
		self:SetSubCategory(self.bottomFilter.buttons[1].set)
	end
end

function InventoryFrame:GetCategory()
	return self.category or L.All
end

function InventoryFrame:SetSubCategory(set)
	if self:SetFilter('subRule', set.rule) then
		self.subCategory = set.name
		self.bottomFilter:UpdateHighlight()
	end
end

function InventoryFrame:GetSubCategory()
	return self.subCategory or L.All
end


function InventoryFrame:SetQuality(quality)
	if self:SetFilter('quality', quality) then
		self.qualityFilter:UpdateHighlight()
	end
end

function InventoryFrame:GetQuality()
	return self:GetFilter('quality') or -1
end


--update our filter stuff,  make a request for the item frame to regenerate itself
function InventoryFrame:SetFilter(key, value)
	if self.filter[key] ~= value then
		self.filter[key] = value

		self.itemFrame:Regenerate()
		return true
	end
end

function InventoryFrame:GetFilter(key)
	return self.filter[key]
end


--[[
	Sizing
--]]

function InventoryFrame:OnSizeChanged()
	local w, h = self:GetWidth(), self:GetHeight()
	self.sets.w = w
	self.sets.h = h

	self:SizeTLTextures(w, h)
	self:SizeBLTextures(w, h)
	self:SizeTRTextures(w, h)
	self:SizeBRTextures(w, h)
	self:UpdateItemFrameSize()
end

function InventoryFrame:SizeTLTextures(w, h)
	local t = _G[self:GetName() .. 'TLRight']
	t:SetWidth(128 + (w - BASE_WIDTH)/2)

	local t = _G[self:GetName() .. 'TLBottom']
	t:SetHeight(128 + (h - BASE_HEIGHT)/2)

	local t = _G[self:GetName() .. 'TLBottomRight']
	t:SetWidth(128 + (w - BASE_WIDTH)/2)
	t:SetHeight(128 + (h - BASE_HEIGHT)/2)
end

function InventoryFrame:SizeBLTextures(w, h)
	local t = _G[self:GetName() .. 'BLRight']
	t:SetWidth(128 + (w - BASE_WIDTH)/2)

	local t = _G[self:GetName() .. 'BLTop']
	t:SetHeight(128 + (h - BASE_HEIGHT)/2)

	local t = _G[self:GetName() .. 'BLTopRight']
	t:SetWidth(128 + (w - BASE_WIDTH)/2)
	t:SetHeight(128 + (h - BASE_HEIGHT)/2)
end

function InventoryFrame:SizeTRTextures(w, h)
	local t = _G[self:GetName() .. 'TRLeft']
	t:SetWidth(64 + (w - BASE_WIDTH)/2)

	local t = _G[self:GetName() .. 'TRBottom']
	t:SetHeight(128 + (h - BASE_HEIGHT)/2)

	local t = _G[self:GetName() .. 'TRBottomLeft']
	t:SetWidth(64 + (w - BASE_WIDTH)/2)
	t:SetHeight(128 + (h - BASE_HEIGHT)/2)
end

function InventoryFrame:SizeBRTextures(w, h)
	local t = _G[self:GetName() .. 'BRLeft']
	t:SetWidth(64 + (w - BASE_WIDTH)/2)

	local t = _G[self:GetName() .. 'BRTop']
	t:SetHeight(128 + (h - BASE_HEIGHT)/2)

	local t = _G[self:GetName() .. 'BRTopLeft']
	t:SetWidth(64 + (w - BASE_WIDTH)/2)
	t:SetHeight(128 + (h - BASE_HEIGHT)/2)
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


--[[
	Positioning
--]]

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


--[[
	Display
--]]

function InventoryFrame:OnShow()
	self:SetCategory(self:GetCategory())
	PlaySound('igMainMenuOpen')
end

function InventoryFrame:OnHide()
	PlaySound('igMainMenuClose')

	if self.isBank then
		CloseBankFrame()
	end
	self:SetPlayer(nil)
end

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