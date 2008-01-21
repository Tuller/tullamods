--[[
	vBagnon\item.lua
		An item button
--]]

BagnonItem = CreateFrame('Button')
BagnonItem.SIZE = 37

local Item_mt = {__index = BagnonItem}
local UPDATE_DELAY = 0.3

--[[ Dummy Bag ]]--

local function DummyBag_Get(parent, bag)
	local bagFrame = getglobal(parent:GetName() .. bag)
	if not bagFrame then
		bagFrame = CreateFrame('Frame', parent:GetName() .. bag, parent)
		bagFrame:SetID(bag)
		Bagnon_AttachToFrame(bagFrame, parent)
	end

	return bagFrame
end

--[[ Constructor ]]--

local function OnUpdate()
	if not this.isLink and GameTooltip:IsOwned(this) then
		if not this.elapsed or this.elapsed < 0 then
			local enable = select(3, GetContainerItemCooldown(this:GetBag(), this:GetID()))
			if enable == 1 then
				this:OnEnter()
			end
			this.elapsed = UPDATE_DELAY
		else
			this.elapsed = this.elapsed - arg1
		end
	end
end

local function OnEnter() 
	this.elapsed = nil
	this:OnEnter() 
end

local function OnLeave() 
	this.elapsed = nil 
	this:OnLeave() 
end

local function OnHide()
	this:OnHide() 
end

local function PostClick()
	this:PostClick(arg1)
end

local function Item_Create(lastCreated)
	local name = "BagnonItem" .. lastCreated
	local item = CreateFrame('Button', name, nil, 'ContainerFrameItemButtonTemplate')
	setmetatable(item, Item_mt)
	item:ClearAllPoints()

	local border = item:CreateTexture(name .. "Border", "OVERLAY")
	border:SetWidth(67)
	border:SetHeight(67)
	border:SetPoint("CENTER", item)
	border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	border:SetBlendMode("ADD")
	border:Hide()
	
	item:UnregisterAllEvents()
	item:SetScript('OnEvent', nil)
	item:SetScript("OnEnter", OnEnter)
	item:SetScript("OnLeave", OnLeave)
	item:SetScript("OnUpdate", OnUpdate)	
	item:SetScript("OnHide", OnHide)
	item:SetScript("PostClick", PostClick)

	return item
end

--[[ Object Methods ]]--

function BagnonItem.Get()
	return TPool.Get('BagnonItem', Item_Create)
end

function BagnonItem:Set(parent, bag, slot)
	Bagnon_AttachToFrame(self, DummyBag_Get(parent, bag))
	self:SetID(slot)
end

function BagnonItem:Release()
	self:SetID(-99)
	self.hasItem = nil
	self.isLink = nil
	TPool.Release(self, 'BagnonItem')
end

--[[ Update Functions ]]--

-- Update the texture, lock status, and other information about an item
function BagnonItem:Update()
	local _, texture, count, locked, readable, quality
	local slot = self:GetID()
	local bag = self:GetBag()
	local player = self:GetPlayer()
		
	if Bagnon_IsCachedBag(player, bag) then
		self.isLink = 1	
		count, texture, quality = select(2, BagnonDB.GetItemData(player, bag, slot))
	else
		self.isLink = nil
		self.readable = readable
		texture, count, locked, _, readable = GetContainerItemInfo(bag, slot)
	end

	if texture then
		self.hasItem = 1
	else
		self.hasItem = nil
	end

	SetItemButtonDesaturated(self, locked)
	SetItemButtonTexture(self, texture)
	SetItemButtonCount(self, count)
	
	self:UpdateSlotBorder()
	self:UpdateCooldown()
	
	if self.isLink then
		self:UpdateLinkBorder(quality)
	else
		self:UpdateBorder()
	end

	self:UpdateSearch()
end

--spot highlighting
function BagnonItem:UpdateSearch()
	if BagnonSpot then
		local pattern = BagnonSpot.search
		local link = Bagnon_GetItemLink(self:GetPlayer(), self:GetBag(), self:GetID())
		
		if pattern and link then
			local name = GetItemInfo(link):lower()
			if name:match(pattern) then
				self:Unfade(true)
			else
				self:Fade()
			end
		else
			self:Unfade()
		end
	end
end

function BagnonItem:UpdateBorder()
	local border = getglobal(self:GetName() .. 'Border')
	local link = GetContainerItemLink(self:GetBag() , self:GetID())

	if Bagnon_GetPlayerSets().qualityBorders and link then
		local hexString = link:match('|cff([%l%d]+)|H')
		local r = tonumber(strsub(hexString, 1, 2), 16)/256
		local g = tonumber(strsub(hexString, 3, 4), 16)/256
		local b = tonumber(strsub(hexString, 5, 6), 16)/256
			
		if not(r == g and r == b) then
			border:SetVertexColor(r, g, b, 0.5)
			border:Show()
		else
			border:Hide()
		end
	else
		border:Hide()
	end
end

function BagnonItem:UpdateLinkBorder(quality)
	local slot = self:GetID()
	local bag = self:GetBag()
	local player = self:GetPlayer()
	local border = getglobal(self:GetName() .. 'Border')

	if Bagnon_GetPlayerSets().qualityBorders and self.hasItem then
		if not quality then
			quality = select(3, GetItemInfo((BagnonDB.GetItemData(player, bag, slot))))
		end

		if quality > 1 then
			local r, g, b = GetItemQualityColor(quality)
			border:SetVertexColor(r, g, b, 0.5)
			border:Show()
		else
			border:Hide()
		end
	else
		border:Hide()
	end
end

function BagnonItem:UpdateSlotBorder()
	local bag = self:GetBag()
	local player = self:GetPlayer()
	local normalTexture = getglobal(self:GetName() .. 'NormalTexture')
	
	if bag == KEYRING_CONTAINER then
		normalTexture:SetVertexColor(1, 0.7, 0)
	elseif Bagnon_IsAmmoBag(bag, player) then
		normalTexture:SetVertexColor(1, 1, 0)
	elseif Bagnon_IsProfessionBag(bag , player) then
		normalTexture:SetVertexColor(0, 1, 0)
	else
		normalTexture:SetVertexColor(1, 1, 1)
	end
end

function BagnonItem:UpdateLock(locked)
	SetItemButtonDesaturated(self, locked)
end

function BagnonItem:UpdateCooldown()
	local cooldown = getglobal(self:GetName().."Cooldown")
	
	if (not self.isLink) and self.hasItem then
		local start, duration, enable = GetContainerItemCooldown(self:GetBag(), self:GetID())
		CooldownFrame_SetTimer(cooldown, start, duration, enable)
	else
		CooldownFrame_SetTimer(cooldown, 0, 0, 0)
	end
end

--[[ OnX Functions ]]--

function BagnonItem:PostClick(mouseButton)
	if IsModifierKeyDown() then
		if this.isLink then
			if this.hasItem then
				if mouseButton == "LeftButton" then
					if IsControlKeyDown() then
						DressUpItemLink((BagnonDB.GetItemData(self:GetPlayer(), self:GetBag(), self:GetID())))
					elseif IsShiftKeyDown() then
						ChatFrameEditBox:Insert(BagnonDB.GetItemHyperlink(self:GetPlayer(), self:GetBag(), self:GetID()))
					end
				end
			end
		else
			ContainerFrameItemButton_OnModifiedClick(mouseButton)
		end
	end
end

function BagnonItem:OnEnter()
	if not self:GetParent() then return end

	local bag = self:GetBag()
	local slot = self:GetID()

	if self.isLink then
		if self.hasItem then
			local player = self:GetPlayer()
			local link, count = BagnonDB.GetItemData(player, bag, slot)
			
			Bagnon_AnchorTooltip(self)
			GameTooltip:SetHyperlink(link, count)
		end
	else
		if self:GetParent():GetID() == -1 then
			Bagnon_AnchorTooltip(self)
			GameTooltip:SetInventoryItem('player', BankButtonIDToInvSlotID(self:GetID()))
		else
			ContainerFrameItemButton_OnEnter(self)
		end
	end

	if not self.hasItem then
		GameTooltip:AddLine(BAGNON_SLOT_INFO:format(bag, slot))
		GameTooltip:Show()
	end
end

function BagnonItem:OnLeave()
	self.updateTooltip = nil
	GameTooltip:Hide()
	ResetCursor()
end

function BagnonItem:OnHide()
	self:Unfade()
	if self.hasStackSplit and self.hasStackSplit == 1 then
		StackSplitFrame:Hide()
	end
end

function BagnonItem:Fade()
	local parent = self:GetParent()
	if parent then
		self:SetAlpha(parent:GetAlpha() / 3)
	end
	self:UnlockHighlight()
end

function BagnonItem:Unfade(highlight)
	local parent = self:GetParent()
	if parent then
		self:SetAlpha(parent:GetAlpha())
	else
		self:SetAlpha(1)
	end

	if highlight and not GetContainerItemInfo(self:GetBag(), self:GetID()) then
		self:LockHighlight()		
	else
		self:UnlockHighlight()
	end
end

function BagnonItem:GetPlayer()
	return self:GetParent():GetParent():GetParent():GetPlayer()
end

function BagnonItem:GetBag()
	return self:GetParent():GetID()
end

function BagnonItem:GetSearchPattern()
	return BagnonSpot.search
end