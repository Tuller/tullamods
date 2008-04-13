--[[
	BPetButton
		A Pet Action Button
		Should work exactly like the normal pet action buttons, but with a modified appearance
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local PetBar = Bongos:GetModule('PetBar')
local PetButton = Bongos:CreateWidgetClass('CheckButton')
local Config = Bongos:GetModule('ActionBar-Config')
PetBar.Button = PetButton

local petBar = PetActionBarFrame


--[[ Constructorish ]]--

function PetButton:Set(id, parent)
	local button = self:New(self:Get(id))
	button:SetToplevel(nil)
	button:SetScripts()
	button:Skin()
	button:ShowHotkey(Config:ShowingHotkeys())
	button:SetParent(parent)

	return button
end

function PetButton:Skin()
	local name = self:GetName()

	local autoCast = getglobal(name .. 'AutoCast')
	autoCast:SetPoint('TOPLEFT', -0.5, -1)
	autoCast:SetPoint('BOTTOMRIGHT', 0.5, -1.5)

	getglobal(name .. 'Icon'):SetTexCoord(0.06, 0.94, 0.06, 0.94)
	getglobal(name .. 'NormalTexture2'):SetVertexColor(1, 1, 1, 0.5)
end

function PetButton:SetScripts()
	self:RegisterForDrag('LeftButton', 'RightButton')
	self:RegisterForClicks('anyUp')

	self:SetScript('OnDragStart', self.OnDragStart)
	self:SetScript('OnReceiveDrag', self.OnReceiveDrag)
	self:SetScript('OnEnter', self.OnEnter)
	self:SetScript('OnEvent', self.UpdateHotkey)
	self:RegisterEvent('UPDATE_BINDINGS')
end


--[[ OnX Functions ]]--

function PetButton:OnDragStart()
	if petBar.showgrid > 0 or LOCK_ACTIONBAR ~= '1' or IsModifiedClick('PICKUPACTION') then
		self:SetChecked(0)
		PickupPetAction(self:GetID())
		PetActionBar_Update()
	end
end

function PetButton:OnReceiveDrag()
	if petBar.showgrid > 0 or LOCK_ACTIONBAR ~= '1' or IsModifiedClick('PICKUPACTION') then
		self:SetChecked(0)
		PickupPetAction(self:GetID())
		PetActionBar_Update()
	end
end

function PetButton:OnEnter()
	if Config:ShouldShowTooltips() then
		PetActionButton_OnEnter(self)
	end
	KeyBound:Set(self)
end


--[[ Hotkey Functions ]]--

function PetButton:ShowHotkey(show)
	if show then
		getglobal(self:GetName() .. 'HotKey'):Show()
		self:UpdateHotkey()
	else
		getglobal(self:GetName() .. 'HotKey'):Hide()
	end
end

function PetButton:UpdateHotkey()
	getglobal(self:GetName() .. 'HotKey'):SetText(self:GetHotkey() or '')
end

function PetButton:GetHotkey()
	local key = GetBindingKey(format('CLICK %s:LeftButton', self:GetName()))
	return KeyBound:ToShortKey(key)
end


--[[ Utility Functions ]]--

function PetButton:Get(id)
	return getglobal(format('PetActionButton%d', id))
end

function PetButton:ForAll(method, ...)
	for i = 1, NUM_PET_ACTION_SLOTS do
		local button = self:Get(i)
		button[method](button, ...)
	end
end