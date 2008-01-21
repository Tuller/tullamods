--[[
	BongosStats
		A movable memory, latency and fps display for Bongos
--]]

Pockets = Bongos:NewModule("Bongos-Pockets")
local L = POCKETS_LOCALS
local UNKNOWN_ITEM = "Interface\\Icons\\INV_Misc_QuestionMark"

local function DockButton_OnEnter(self)
	local frame = self:GetParent().frame
	frame:SetRule(self.rule)
	frame:SetPoint("BOTTOMLEFT", self, "TOPLEFT")
	UIFrameFadeIn(self, 0.2)
	UIFrameFadeIn(frame, 0.2)
end

local function DockButton_OnLeave(self)
	UIFrameFadeOut(self, 0.2, 1, 0.3)
end

local function DockButton_OnReceiveDrag(self)
	if CursorHasItem() then
		local texture = select(10, GetItemInfo(select(2, GetCursorInfo())))
		getglobal(self:GetName() .. "IconTexture"):SetTexture(texture)
	end
	ClearCursor()
end

local last = 1
local function DockButton_New(parent)
	local button = CreateFrame("Button", format("PocketTab%d", last), parent, "ItemButtonTemplate")
	button:SetAlpha(0.3)
	button:SetScript("OnEnter", DockButton_OnEnter)
	button:SetScript("OnLeave", DockButton_OnLeave)
	button:SetScript("OnReceiveDrag", DockButton_OnReceiveDrag)
	getglobal(button:GetName() .. "IconTexture"):SetTexture(UNKNOWN_ITEM)
	button:RegisterForDrag("LeftButton")
	last = last + 1

	return button
end

local function DockButton_Set(self, rule)
	self.rule = rule
end

local function Bar_Layout(self)
	if(not self.items) then self.items = {} end

	local cats = self.sets.cats
	for i, rule in ipairs(cats) do
		local item = self.items[i]
		if(not item) then
			item = DockButton_New(self)
			self.items[i] = item
		end
		DockButton_Set(item, rule)

		if(i == 1) then
			item:SetPoint("TOPLEFT", self)
		else
			item:SetPoint("TOPLEFT", self.items[i-1], "TOPRIGHT", 1, 0)
		end
	end

	for i = #cats+1, #self.items do
		self.items[i]:Hide()
		item:Hide()
	end

	self:SetSize(#cats * 37, 37)
end

local function Bar_OnCreate(self)
	self.Layout = Bar_Layout
end

--[[ Startup ]]--

function Pockets:Load()
	local bar = BBar:Create("pockets", Bar_OnCreate, nil, {cats = {"quest", "Consumable.Potion", "Consumable.Bandage", "Misc.Mount"}})
	if not bar:IsUserPlaced() then bar:SetPoint("CENTER", UIParent) end
	self.bar = bar
	bar.frame = PocketFrame:New()
	self.frame = bar.frame
	bar:Layout()

	self:RegisterMessage("BAGNON_SLOT_ADD", "UpdateSlot")
	self:RegisterMessage("BAGNON_SLOT_UPDATE", "UpdateSlot")
	self:RegisterMessage("BAGNON_SLOT_UPDATE_LOCK")
	self:RegisterMessage("BAGNON_SLOT_UPDATE_COOLDOWN")
	self:RegisterMessage("BAGNON_SLOT_REMOVE")
end

function Pockets:Unload()
	self.bar:Destroy()
	self:UnregisterAllMessages()
end

function Pockets:UpdateSlot(msg, bag, slot)
	local frame = self.frame
	if frame:IsShown() then
		frame:UpdateSlot(bag, slot, link)
	end
end

function Pockets:BAGNON_SLOT_UPDATE_LOCK(msg, bag, slot)
	local frame = self.frame
	if frame:IsShown() then
		frame:UpdateSlotLock(bag, slot)
	end
end

function Pockets:BAGNON_SLOT_UPDATE_COOLDOWN(msg, bag, slot)
	local frame = self.frame
	if frame:IsShown() then
		frame:UpdateSlotCooldown(bag, slot)
	end
end

function Pockets:BAGNON_SLOT_REMOVE(msg, bag, slot)
	local frame = self.frame
	if frame:IsShown() then
		frame:RemoveItem(bag, slot)
	end
end