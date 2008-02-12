--[[
	bar.lua
		Scripts used for the Bongos Bag bar
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local Bags = Bongos:NewModule('Bar')
local L = LibStub('AceLocale-3.0'):GetLocale('Bongos3-AB')

--create the keyring button
do
	local button = CreateFrame('CheckButton', 'BongosKeyRingButton', UIParent, 'ItemButtonTemplate')
	button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	button:Hide()

	button:SetScript('OnClick', function()
		if CursorHasItem() then
			PutKeyInKeyRing()
		else
			ToggleKeyRing()
		end
	end)

	button:SetScript('OnReceiveDrag', function()
		if CursorHasItem() then
			PutKeyInKeyRing()
		end
	end)

	button:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')

		local color = HIGHLIGHT_FONT_COLOR
		GameTooltip:SetText(KEYRING, color.r, color.g, color.b)
		GameTooltip:AddLine()
	end)

	button:SetScript('OnLeave', function()
		GameTooltip:Hide()
	end)

	getglobal(button:GetName() .. 'IconTexture'):SetTexture('Interface/Icons/INV_Misc_Bag_16')
end


--[[ Bar Methods ]]--

local DEFAULT_SPACING = 1
local BAG_SIZE = 37

local bags = {
	BongosKeyRingButton,
	MainMenuBarBackpackButton,
	CharacterBag0Slot,
	CharacterBag1Slot,
	CharacterBag2Slot,
	CharacterBag3Slot,
}

local Bar = {}

function Bar:CreateMenu()
	local menu = Bongos.Menu:Create(self.id)
	local panel = menu:AddLayoutPanel()

	local oneBag = panel:CreateCheckButton(L.OneBag)
	oneBag:SetScript('OnShow', function(b) b:SetChecked(self.sets.oneBag) end)
	oneBag:SetScript('OnClick', function(b) self:SetOneBag(b:GetChecked()) end)

	local showKeyRing = panel:CreateCheckButton(L.ShowKeyring)
	showKeyRing:SetScript('OnShow', function(b) b:SetChecked(self.sets.showKeyring) end)
	showKeyRing:SetScript('OnClick', function(b) self:SetShowKeyring(b:GetChecked()) end)

	local vertical = panel:CreateCheckButton(L.Vertical)
	vertical:SetScript('OnShow', function(b) b:SetChecked(self.sets.vertical) end)
	vertical:SetScript('OnClick', function(b) self:SetVertical(b:GetChecked()) end)

	panel:CreateSpacingSlider()

	return menu
end

function Bar:Layout(vertical, spacing)
	self.sets.vertical = vertical or nil

	spacing = (spacing or self.sets.spacing or DEFAULT_SPACING)
	self.sets.spacing = (spacing ~= DEFAULT_SPACING and spacing) or nil

	for _,bag in pairs(bags) do
		bag:ClearAllPoints()
	end

	--hide bags as necessary
	if self.sets.oneBag then
		for i = NUM_BAG_SLOTS, 1, -1 do
			getglobal(format('CharacterBag%dSlot', i-1)):Hide()
		end
	end
	if not self.sets.showKeyring then
		BongosKeyRingButton:Hide()
	end

	--vertical layout
	local numBags = 1
	if vertical then
		MainMenuBarBackpackButton:SetPoint('BOTTOMRIGHT', self)

		local prev = MainMenuBarBackpackButton
		if not self.sets.oneBag then
			for i = 1, NUM_BAG_SLOTS do
				local bag = getglobal(format('CharacterBag%dSlot', i-1))
				bag:SetPoint('BOTTOM', prev, 'TOP', 0, spacing)
				bag:Show()
				prev = bag
			end
			numBags = numBags + NUM_BAG_SLOTS
		end

		if self.sets.showKeyring then
			BongosKeyRingButton:SetPoint('BOTTOM', prev, 'TOP', 0, spacing)
			BongosKeyRingButton:Show()
			numBags = numBags + 1
		end

		self:SetWidth(BAG_SIZE)
		self:SetHeight((BAG_SIZE + spacing) * numBags - spacing)
	--horizontal layout
	else
		MainMenuBarBackpackButton:SetPoint('TOPRIGHT', self)

		local prev = MainMenuBarBackpackButton
		if not self.sets.oneBag then
			for i = 1, NUM_BAG_SLOTS do
				local bag = getglobal(format('CharacterBag%dSlot', i - 1))
				bag:SetPoint('RIGHT', prev, 'LEFT', -spacing, 0)
				bag:Show()
				prev = bag
			end
			numBags = numBags + NUM_BAG_SLOTS
		end

		if self.sets.showKeyring then
			BongosKeyRingButton:SetPoint('RIGHT', prev, 'LEFT', -spacing, 0)
			BongosKeyRingButton:Show()
			numBags = numBags + 1
		end

		self:SetWidth((BAG_SIZE + spacing) * numBags - spacing)
		self:SetHeight(BAG_SIZE)
	end
end

function Bar:SetSpacing(spacing)
	self:Layout(self.sets.vertical, spacing)
end

function Bar:GetSpacing()
	return self.sets.spacing or DEFAULT_SPACING
end

function Bar:SetShowKeyring(enable)
	self.sets.showKeyring = enable or nil
	self:Layout(self.sets.vertical)
end

function Bar:SetOneBag(enable)
	self.sets.oneBag = enable or nil
	self:Layout(self.sets.vertical)
end

function Bar:SetVertical(enable)
	self:Layout(enable)
end


--[[ Startup ]]--

function Bags:Load()
	local bar, isNew = Bongos.Bar:Create('bags', {showKeyring = true, point = 'BOTTOMRIGHT'})
	if isNew then
		self:OnBarCreate(bar)
	end
	bar:Layout(bar.sets.vertical)

	self.bar = bar
end

function Bags:OnBarCreate(bar)
	for k,v in pairs(Bar) do
		bar[k] = v
	end

	for _,bag in pairs(bags) do
		bar:Attach(bag)
	end

	--hack to prevent some random issue with the backpack
	MainMenuBarBackpackButton:Show()
end

function Bags:Unload()
	self.bar:Destroy()
end