--[[
	BagnonBag
		A bag button object
--]]

--local msg = function(msg) ChatFrame1:AddMessage(msg or "nil", 0.5, 0.5, 1) end

BagnonBag = CreateFrame("Button")
local Frame_mt = {__index = BagnonBag}
local L = BAGNON_LOCALS

local SIZE = 32
local NORMAL_TEXTURE_SIZE = 64 * (SIZE / 37)
local KEY_WIDTH = 18 * (SIZE / 37)
local util = BagnonUtil
local lastCreated = 0

--[[ Bag Constructor ]]--

local function OnEnter(self) self:OnEnter() end
local function OnLeave(self) self:OnLeave() end
local function OnShow(self)  self:OnShow()  end
local function OnClick(self) self:OnClick(arg1) end
local function OnDrag(self)  self:OnDrag()  end

local function LoadScripts(bag)
	bag:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	bag:RegisterForDrag("LeftButton")

	bag:SetScript("OnShow", OnShow)
	bag:SetScript("OnEnter", OnEnter)
	bag:SetScript("OnLeave", OnLeave)
	bag:SetScript("OnClick", OnClick)
	bag:SetScript("OnDragStart", OnDrag)
	bag:SetScript("OnReceiveDrag", OnClick)

	lastCreated = lastCreated + 1
end

local function Bag_Create(id)
	local name = format("BagnonBag%s", lastCreated)
	local bag = CreateFrame("Button", name)
	setmetatable(bag, Frame_mt)

	bag:SetWidth(SIZE)
	bag:SetHeight(SIZE)

	local icon = bag:CreateTexture(name .. "IconTexture", "BORDER")
	icon:SetAllPoints(bag)
	if id == 0 or id == -1 then
		icon:SetTexture("Interface\\Buttons\\Button-Backpack-Up")
	end

	local count = bag:CreateFontString(name .. "Count", "BORDER")
	count:SetFontObject("NumberFontNormal")
	count:SetJustifyH("RIGHT")
	count:SetPoint("BOTTOMRIGHT", bag, "BOTTOMRIGHT", -2, 2)

	local normalTexture = bag:CreateTexture(name .. "NormalTexture")
	normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot2")
	normalTexture:SetWidth(NORMAL_TEXTURE_SIZE)
	normalTexture:SetHeight(NORMAL_TEXTURE_SIZE)
	normalTexture:SetPoint("CENTER", bag, "CENTER", 0, -1)
	bag:SetNormalTexture(normalTexture)

	local pushedTexture = bag:CreateTexture()
	pushedTexture:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
	pushedTexture:SetAllPoints(bag)
	bag:SetPushedTexture(pushedTexture)

	local highlightTexture = bag:CreateTexture()
	highlightTexture:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
	highlightTexture:SetAllPoints(bag)
	bag:SetHighlightTexture(highlightTexture)

	LoadScripts(bag)

	return bag
end

local function Bag_CreateKey()
	local name = format("BagnonBag%s", lastCreated)
	local bag = CreateFrame("Button", name)
	setmetatable(bag, Frame_mt)

	bag:SetWidth(KEY_WIDTH)
	bag:SetHeight(SIZE)

	local normalTexture = bag:CreateTexture(name .. "NormalTexture")
	normalTexture:SetTexture("Interface\\Buttons\\UI-Button-KeyRing")
	normalTexture:SetAllPoints(bag)
	normalTexture:SetTexCoord(0, 0.5625, 0, 0.609375)
	bag:SetNormalTexture(normalTexture)

	local pushedTexture = bag:CreateTexture()
	pushedTexture:SetTexture("Interface\\Buttons\\UI-Button-KeyRing-Down")
	pushedTexture:SetAllPoints(bag)
	pushedTexture:SetTexCoord(0, 0.5625, 0, 0.609375)
	bag:SetPushedTexture(pushedTexture)

	local highlightTexture = bag:CreateTexture()
	highlightTexture:SetTexture("Interface\\Buttons\\UI-Button-KeyRing-Highlight")
	highlightTexture:SetAllPoints(bag)
	highlightTexture:SetTexCoord(0, 0.5625, 0, 0.609375)
	bag:SetHighlightTexture(highlightTexture)

	LoadScripts(bag)

	return bag
end


--[[ Constructor/Destructor  ]]--

function BagnonBag.New(parent, id)
	local bag
	if id == KEYRING_CONTAINER then
		bag = Bag_CreateKey()
	else
		bag = Bag_Create(id)
	end
	bag:SetID(id)

	util:Attach(bag, parent)
	bag:Update()

	return bag
end


--[[ Update ]]--

function BagnonBag:Update()
	self:UpdateTexture()
	self:UpdateLock()

	--update tooltip
	if GameTooltip:IsOwned(self) then
		if self.hasItem then
			self:OnEnter()
		else
			GameTooltip:Hide()
			ResetCursor()
		end
	end

	-- Update repair all button status
	if MerchantRepairAllIcon then
		local repairAllCost, canRepair = GetRepairAllCost()
		if canRepair then
			SetDesaturation(MerchantRepairAllIcon, nil)
			MerchantRepairAllButton:Enable()
		else
			SetDesaturation(MerchantRepairAllIcon, 1)
			MerchantRepairAllButton:Disable()
		end
	end
end

function BagnonBag:UpdateLock()
	local locked = IsInventoryItemLocked(util:GetInvSlot(self:GetID()))
	SetItemButtonDesaturated(self, locked)
end

function BagnonBag:UpdateCursor()
	local invID = util:GetInvSlot(self:GetID())
	if CursorCanGoInSlot(invID) then
		self:LockHighlight()
	else
		self:UnlockHighlight()
	end
end

--actually, update texture and count
function BagnonBag:UpdateTexture()
	local parent = self:GetParent():GetParent()
	local bagID = self:GetID()

	if bagID <= 0 or not parent then return end

	local player = parent:GetPlayer()

	if util:IsCachedBag(bagID, player) then
		if BagnonDB then
			local link, count = select(2, BagnonDB:GetBagData(self:GetID(), player))
			if link then
				local texture = select(10, GetItemInfo(link))
				SetItemButtonTexture(self, texture)

				if texture then
					self.hasItem = true
				end
			else
				SetItemButtonTexture(self, nil)
				self.hasItem = nil
			end

			if count then
				self:SetCount(count)
			end
		end
	else
		local texture = GetInventoryItemTexture("player", util:GetInvSlot(self:GetID()))
		if texture then
			SetItemButtonTexture(self, texture)
			self.hasItem = true
		else
			SetItemButtonTexture(self, nil)
			self.hasItem = nil
		end
		self:SetCount(GetInventoryItemCount("player", util:GetInvSlot(self:GetID())))
	end
end

function BagnonBag:SetCount(count)
	local text = getglobal(self:GetName() .. "Count")

	if self:GetID() <= 0 then
		text:Hide()
	else
		count = count or 0

		if count > 1 then
			if count > 9999 then
				text:SetFont(NumberFontNormal:GetFont(), 10, "OUTLINE")
			elseif count > 999 then
				text:SetFont(NumberFontNormal:GetFont(), 11, "OUTLINE")
			else
				text:SetFont(NumberFontNormal:GetFont(), 12, "OUTLINE")
			end

			text:SetText(count)
			text:Show()
		else
			text:Hide()
		end
	end
end


--[[ Frame Events ]]--

function BagnonBag:OnClick(button)
	local parent = self:GetParent():GetParent()
	local player = parent:GetPlayer()
	local bagID = self:GetID()

	if not(util:IsCachedBag(bagID, player)) and CursorHasItem() then
		if bagID == KEYRING_CONTAINER then
			PutKeyInKeyRing()
		elseif bagID == 0 then
			PutItemInBackpack()
		else
			PutItemInBag(ContainerIDToInventoryID(bagID))
		end
	else
		parent:ShowBag(bagID, not parent:ShowingBag(bagID))
	end
end

function BagnonBag:OnDrag()
	local parent = self:GetParent():GetParent()
	local player = parent:GetPlayer()
	local bagID = self:GetID()

	if not(util:IsCachedBag(bagID, player) or bagID <= 0) then
		PlaySound("BAGMENUBUTTONPRESS")
		PickupBagFromSlot(util:GetInvSlot(bagID))
	end
end

function BagnonBag:OnShow()
	if self:GetID() > 0 and self:GetParent() then
		self:UpdateTexture()
	end
end

--tooltip functions
function BagnonBag:OnEnter()
	local frame = self:GetParent():GetParent()
	local player = frame:GetPlayer()
	local bagID = self:GetID()

	util:AnchorTooltip(self)

	--mainmenubag specific code
	local cached = util:IsCachedBag(bagID, player)
	if bagID == 0 then
		GameTooltip:SetText(TEXT(BACKPACK_TOOLTIP), 1, 1, 1)
	elseif bagID == -1 then
		GameTooltip:SetText("Bank", 1, 1, 1)
	--keyring specific code...again
	elseif bagID == KEYRING_CONTAINER then
		GameTooltip:SetText(KEYRING, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	--cached bags
	elseif cached then
		local link = select(2, BagnonDB:GetBagData(bagID, frame:GetPlayer()))
		if link then
			GameTooltip:SetHyperlink(link)
		else
			GameTooltip:SetText(TEXT(EQUIP_CONTAINER), 1, 1, 1)
		end
	elseif not GameTooltip:SetInventoryItem("player", util:GetInvSlot(bagID)) then
		GameTooltip:SetText(TEXT(EQUIP_CONTAINER), 1, 1, 1)
	end

	if frame:ShowingBag(bagID) then
		GameTooltip:AddLine(L.TipHideBag)
	else
		GameTooltip:AddLine(L.TipShowBag)
	end
	GameTooltip:Show()
	BagnonSpot:SetBagSearch(bagID)
end

function BagnonBag:OnLeave()
	GameTooltip:Hide()
	BagnonSpot:SetBagSearch(nil)
end