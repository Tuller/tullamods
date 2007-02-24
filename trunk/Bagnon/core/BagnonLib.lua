--[[
	BagnonLib
		A library of functions for accessing and updating bag data

	Based on SpecialEvents-Bags by Tekkub Stoutwrithe (tekkub@gmail.com)

	BAGNON_SLOT_ADDED
	args:		bag, slot, link, count
		called when a new slot becomes available to the player

	BAGNON_SLOT_UPDATE
	args:		bag, slot, link, count
		called when an item slot is updated

	BAGNON_SLOT_UPDATE_LOCK
	args:		bag, slot, locked
		called when an item slot is locked or unlocked

	BAGNON_SLOT_UPDATE_COOLDOWN
	args:		bag, slot, enable
		called when an item's cooldown starts/ends

	BAGNON_SLOT_REMOVED
	args:		bag, slot
		called when an item slot is removed from being in use
--]]

local slots = {}
local size = {}
local atBank = nil

--[[ Update Functions ]]--

--item slots
local function AddItem(bag, slot)
	if not slots[bag][slot] then slots[bag][slot] = {} end

	local data = slots[bag][slot]
	local link = GetContainerItemLink(bag, slot)
	local count, locked = select(2, GetContainerItemInfo(bag, slot))

	data[1] = link
	data[2] = count
	data[3] = locked
	
	local start, duration, enable = GetContainerItemCooldown(bag, slot)
	if (start > 0 and duration > 0 and enable == 1) then
		data[4] = 1
	else
		data[4] = nil
	end

	BVent:Call('BAGNON_SLOT_ADDED', bag, slot, link, count)
end

local function RemoveItem(bag, slot)
	if not slots[bag] then return end

	local data = slots[bag][slot]
	if not data then return end

	for i in pairs(data) do data[i] = nil end

	BVent:Call('BAGNON_SLOT_REMOVED', bag, slot)
end

local function UpdateItem(bag, slot)
	if not slots[bag][slot] then slots[bag][slot] = {} end

	local data = slots[bag][slot]
	local oldLink = data[1]
	local oldCount = data[2]
	local link = GetContainerItemLink(bag, slot)
	local count, locked = select(2, GetContainerItemInfo(bag, slot))
	
	local start, duration, enable = GetContainerItemCooldown(bag, slot)
	local onCooldown
	if (start > 0 and duration > 0 and enable == 1) then
		onCooldown = 1
	else
		onCooldown = nil
	end

	if not(oldLink == link and oldCount == count) then
		data[1] = link; data[2] = count; data[3] = locked; data[4] = onCooldown
		BVent:Call('BAGNON_SLOT_UPDATE', bag, slot, link, count)
	end
end

local function UpdateItems(bag)
	if not slots[bag] then slots[bag] = {} end

	for slot = 1, BagnonLib.GetBagSize(bag) do
		UpdateItem(bag, slot)
	end
end

--lock
local function UpdateLock(bag)
	if slots[bag] then
		for slot, data in pairs(slots[bag]) do
			local oldLocked = data[3]
			local locked = select(3, GetContainerItemInfo(bag, slot))

			if oldLocked ~= locked then
				data[3] = locked
				BVent:Call('BAGNON_SLOT_UPDATE_LOCK', bag, slot, locked)
			end
		end
	end
end

--cooldowns
local function UpdateCooldown(bag, slot)
	if not slots[bag] then
		slots[bag] = {}
	end

	if not slots[bag][slot] then
		slots[bag][slot] = {}
	end

	local data = slots[bag][slot]
	local start, duration, enable = GetContainerItemCooldown(bag, slot)
	
	local onCooldown
	if (start > 0 and duration > 0 and enable == 1) then
		onCooldown = 1
	else
		onCooldown = nil
	end

	if data[4] ~= onCooldown then
		data[4] = onCooldown
		BVent:Call('BAGNON_SLOT_UPDATE_COOLDOWN', bag, slot, onCooldown)
	end
end

local function UpdateCooldowns()
	for bag = 0, 4 do
		for slot = 1, BagnonLib.GetBagSize(bag) do
			UpdateCooldown(bag, slot)
		end
	end
end

--bag sizes
local function UpdateBagSize(bag)
	local prevSize = size[bag] or 0
	size[bag] = BagnonLib.GetBagSize(bag) or 0

	if prevSize > size[bag] then
		if not slots[bag] then return end

		for slot = size[bag] + 1, prevSize do
			RemoveItem(bag, slot)
		end
	elseif prevSize < size[bag] then
		if not slots[bag] then slots[bag] = {} end

		for slot = prevSize + 1, size[bag] do
			AddItem(bag, slot)
		end
	end
end

local function UpdateBagSizes()
	for bag = -2, GetNumBankSlots() + 4 do
		UpdateBagSize(bag)
	end
end

--bank
local function UpdateBank()
	UpdateBagSizes()

	UpdateItems(-1)
	for bag = 5, GetNumBankSlots() + 4 do
		UpdateItems(bag)
	end
end


--[[ Events ]]--

BVent:AddAction('PLAYER_LOGIN', function()
	UpdateBagSize(KEYRING_CONTAINER)
	UpdateBagSize(0)
end)

BVent:AddAction('BAG_UPDATE', function()
	UpdateBagSizes()
	UpdateItems(arg1)
end)

BVent:AddAction('PLAYERBANKSLOTS_CHANGED', UpdateBank)

BVent:AddAction('BANKFRAME_OPENED', function()
	atBank = true
	UpdateBank()
end)

BVent:AddAction('BANKFRAME_CLOSED', function()
	atBank = nil
end)

BVent:AddAction('PLAYER_LEVEL_UP', function()
	UpdateBagSize(KEYRING_CONTAINER)
end)

BVent:AddAction('ITEM_LOCK_CHANGED', function()
	if atBank then
		for bag = -1, GetNumBankSlots() + 4 do
			UpdateLock(bag)
		end
	else
		for bag = 0, 4 do
			UpdateLock(bag)
		end
	end
	UpdateLock(KEYRING_CONTAINER)
end)

BVent:AddAction('BAG_UPDATE_COOLDOWN', UpdateCooldowns)


--[[ Usable Functions ]]--

local currentPlayer = UnitName('player')

BagnonLib = {}

--returns true if the current player is at the bank, nil otherwise
function BagnonLib.AtBank()
	return atBank
end


--[[ Wrapper functions for retrieving live/cached data easily ]]--

function BagnonLib.GetInvSlot(bag)
	if bag > 0 then
		return ContainerIDToInventoryID(bag)
	end
end

function BagnonLib.GetBagSize(bag, player)
	if (player or currentPlayer) ~= currentPlayer then
		if BagnonDB then
			return BagnonDB.GetBagData(player, bag) or 0
		end
		return 0
	end

	if BagnonLib.IsBankBag(bag) and not BagnonLib.AtBank() then
		if BagnonDB then
			return BagnonDB.GetBagData(player, bag) or 0
		end
		return 0
	elseif bag == KEYRING_CONTAINER then
		return GetKeyRingSize()
	end
	return GetContainerNumSlots(bag)
end

function BagnonLib.GetBagLink(bag, player)
	if player and player ~= currentPlayer then
		if BagnonDB then
			return select(2, BagnonDB.GetBagData(player, bag))
		end
	else
		return GetInventoryItemLink('player', BagnonLib.GetInvSlot(bag))
	end
end

function BagnonLib.GetItemLink(bag, slot, player)
	if BagnonLib.IsCachedBag(bag, player) then
		return (BagnonDB.GetItemData(player, bag, slot))
	else
		return GetContainerItemLink(bag, slot)
	end
end

function BagnonLib.GetItemCount(bag, slot, player)
	if BagnonLib.IsCachedBag(bag, player) then
		local link, count = BagnonDB.GetItemData(player, bag, slot)
		if link then
			return count or 1
		end
		return 0
	else
		return select(2, GetContainerItemInfo(bag, slot)) or 0
	end
end


--[[ Bag ]]--

--returns true if the given bag is cached AND we have a way of reading data for it
function BagnonLib.IsCachedBag(bag, player)
	if BagnonDB then
		return currentPlayer ~= (player or currentPlayer) or (not atBank and BagnonLib.IsBankBag(bag))
	end
end

function BagnonLib.IsInventoryBag(bag)
	return bag == KEYRING_CONTAINER or (bag > -1 and bag < 5)
end

function BagnonLib.IsBankBag(bag)
	return (bag == -1 or bag > 4)
end

--returns if the given bag is an ammo bag/soul bag
function BagnonLib.IsAmmoBag(bag, player)
	--bankslots, the main bag, and the keyring cannot be ammo slots
	if bag <= 0 then return end

	local link = BagnonLib.GetBagLink(bag, player)
	if link then
		local type, subType = select(6, GetItemInfo(link))
		return (type == BAGNON_TYPE['Quiver'] or subType == BAGNON_SUBTYPE['Soul Bag'])
	end
end

--returns if the given bag is a profession bag (herb bag, engineering bag, etc)
function BagnonLib.IsProfessionBag(bag, player)
	--bankslots, the main bag, and the keyring cannot be profession bags
	if bag <= 0 then return end

	local link = BagnonLib.GetBagLink(bag, player)
	if link then
		local type, subType = select(6, GetItemInfo(link))
		return type == BAGNON_TYPE['Container'] and not (subType == BAGNON_SUBTYPE['Bag'] or subType == BAGNON_SUBTYPE['Soul Bag'])
	end
end


--[[ Utility Functions ]]--

function BagnonLib.AnchorTooltip(frame)
	if frame:GetRight() >= (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(frame, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(frame, 'ANCHOR_RIGHT')
	end
end

function BagnonLib.AnchorAtCursor(frame)
	local x,y = GetCursorPosition()
	local scale = UIParent:GetScale()

	frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x/scale - 32, y/scale + 32)
end

--attaches the given frame to the given parent
function BagnonLib.Attach(frame, parent)
	frame:SetParent(parent)
	frame:SetAlpha(parent:GetAlpha())
	frame:SetFrameLevel(1)
end

--returns the player's settings
function BagnonLib.GetSets(player, realm)
	return BagnonSets
end

--send a message to the player
function BagnonMsg(msg)
	ChatFrame1:AddMessage(format('|cFFFFFF44Bagnon|r: %s', msg or 'nil'))
end