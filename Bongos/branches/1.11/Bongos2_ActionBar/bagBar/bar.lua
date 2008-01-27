--[[
	bar.lua
		Scripts used for the Bongos Bag bar
--]]

BongosBagBar = Bongos:NewModule('Bongos-BagBar')
local L = BONGOS_LOCALS
local DEFAULT_SPACING = 1
local BAG_SIZE = 37

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

local bags = {
	BongosKeyRingButton,
	MainMenuBarBackpackButton,
	CharacterBag0Slot,
	CharacterBag1Slot,
	CharacterBag2Slot,
	CharacterBag3Slot,
}


--[[ Bar Functions ]]--

local function Bar_SetSpacing(self, spacing)
	self:Layout(self.sets.vertical, spacing)
end

local function Bar_GetSpacing(self)
	return self.sets.spacing or DEFAULT_SPACING
end

local function Bar_Layout(self, vertical, spacing)
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

local function Bar_SetShowKeyring(self, enable)
	self.sets.showKeyring = enable or nil
	self:Layout(self.sets.vertical)
end

local function Bar_SetOneBag(self, enable)
	self.sets.oneBag = enable or nil
	self:Layout(self.sets.vertical)
end

local function Bar_SetVertical(self, enable)
	self:Layout(enable)
end

local function Bar_CreateMenu(frame)
	local menu,panel = BongosMenu:CreateMenu(frame.id)

	local oneBag = panel:AddCheckButton(L.OneBag)
	oneBag:SetScript('OnShow', function(self) self:SetChecked(frame.sets.oneBag) end)
	oneBag:SetScript('OnClick', function(self) frame:SetOneBag(self:GetChecked()) end)

	local showKeyRing = panel:AddCheckButton(L.ShowKeyring)
	showKeyRing:SetScript('OnShow', function(self) self:SetChecked(frame.sets.showKeyring) end)
	showKeyRing:SetScript('OnClick', function(self) frame:SetShowKeyring(self:GetChecked()) end)

	local vertical = panel:AddCheckButton(L.Vertical)
	vertical:SetScript('OnShow', function(self) self:SetChecked(frame.sets.vertical) end)
	vertical:SetScript('OnClick', function(self) frame:SetVertical(self:GetChecked()) end)

	panel:AddSpacingSlider()

	return menu
end

local function Bar_OnCreate(self)
	self.CreateMenu = Bar_CreateMenu
	self.Layout = Bar_Layout
	self.SetVertical = Bar_SetVertical
	self.SetOneBag = Bar_SetOneBag
	self.SetSpacing = Bar_SetSpacing
	self.GetSpacing = Bar_GetSpacing
	self.SetShowKeyring = Bar_SetShowKeyring

	for _,bag in pairs(bags) do
		self:Attach(bag)
	end

	--hack to prevent some random issue with the backpack
	MainMenuBarBackpackButton:Show()
end


--[[ Startup ]]--

function BongosBagBar:Load()
	local bar = BBar:Create('bags', Bar_OnCreate, nil, {showKeyring = true, x = 1241, y = 37})
	bar:Layout(bar.sets.vertical)

	self.bar = bar
end

function BongosBagBar:Unload()
	self.bar:Destroy()
end