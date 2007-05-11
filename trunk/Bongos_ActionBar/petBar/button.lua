--[[
	BPetButton
		A Pet Action Button
		Should work exactly like the normal pet action buttons, but with a modified appearance
--]]

BongosPetButton = CreateFrame('CheckButton')
local Button_mt = {__index = BongosPetButton}

--[[ Constructorish ]]--

local function PostClick(self, arg1) self:PostClick(arg1) end
local function OnDragStart(self) self:OnDragStart(arg1) end
local function OnReceiveDrag(self) self:OnReceiveDrag(arg1) end
local function OnEnter(self) self:OnEnter() end
local function OnLeave(self) self:OnLeave() end

function BongosPetButton:Set(id, parent)
	local button = setmetatable(self:Get(id), Button_mt)

	button:SetToplevel(false)
	button:SetAttribute('showstates', '1')
	button:SetScripts()
	button:Style()
	button:ShowHotkey(BongosActionMain:ShowingHotkeys())

	parent:Attach(button)
	parent:SetAttribute('addchild', button)

	return button
end

function BongosPetButton:Style()
	local name = self:GetName()

	local autoCast = getglobal(name .. "AutoCast")
	autoCast:SetPoint("TOPLEFT", self, "TOPLEFT", -0.5, -1)
	autoCast:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0.5, -1.5)

	getglobal(name .. 'Icon'):SetTexCoord(0.06, 0.94, 0.06, 0.94)
	getglobal(name .. 'NormalTexture2'):SetVertexColor(1, 1, 1, 0.5)
end

function BongosPetButton:SetScripts()
	self:RegisterForDrag('LeftButton', 'RightButton')
	self:RegisterForClicks('anyUp')

	self:SetScript('OnLoad', nil)
	self:SetScript('OnEvent', nil)
	self:SetScript('OnDragStart', OnDragStart)
	self:SetScript('OnReceiveDrag', OnReceiveDrag)
	self:SetScript('OnEnter', OnEnter)
end


--[[ OnX Functions ]]--

function BongosPetButton:OnDragStart()
	if not BongosActionMain:ButtonsLocked() or BongosActionMain:IsQuickMoveKeyDown() or self.showEmpty then
		self:SetChecked(false)
		PickupPetAction(self:GetID())
		self:UpdateVisibility()
	end
end

function BongosPetButton:OnReceiveDrag()
	if self.showEmpty or BongosActionMain:IsQuickMoveKeyDown() then
		self:SetChecked(false)
		PickupPetAction(self:GetID())
		self:UpdateVisibility()
	end
end

function BongosPetButton:OnEnter()
	if BongosActionMain:ShowingTooltips() then
		PetActionButton_OnEnter(self)
	end
	KeyBound:Set(self)
end


--[[ Update Functions ]]--

function BongosPetButton:Update()
	local name, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(self:GetID())
	local selfName = self:GetName()

	if name then
		self:Show()
	elseif not self:ShowingEmptyButtons() then
		self:Hide()
	end

	self.isToken = isToken
	self.tooltipSubtext = subtext
	self:SetChecked(isActive)

	local icon = getglobal(selfName .. 'Icon')
	SetDesaturation(icon, not GetPetActionsUsable())

	if texture then
		icon:Show()
		self:SetNormalTexture('Interface\\Buttons\\UI-Quickslot2')
	else
		icon:Hide()
		self:SetNormalTexture('Interface\\Buttons\\UI-Quickslot')
	end

	if not isToken then
		icon:SetTexture(texture)
		self.tooltipName = name
	else
		icon:SetTexture(getglobal(texture))
		self.tooltipName = getglobal(name)
	end

	local autoCastTexture = getglobal(selfName .. 'AutoCastable')
	if autoCastAllowed then
		autoCastTexture:Show()
	else
		autoCastTexture:Hide()
	end

	local autoCastModel = getglobal(selfName .. 'AutoCast')
	if autoCastEnabled then
		autoCastModel:Show()
	else
		autoCastModel:Hide()
	end
end

function BongosPetButton:UpdateCooldown()
	local start, duration, enable = GetPetActionCooldown(self:GetID())
	CooldownFrame_SetTimer(getglobal(self:GetName() .. 'Cooldown'), start, duration, enable)
end

function BongosPetButton:UpdateVisibility()
	if self:ShowingEmptyButtons() or GetPetActionInfo(self:GetID()) then
		self:Show()
	else
		self:Hide()
	end
end


--[[ Hotkey Functions ]]--

function BongosPetButton:ShowHotkey(show)
	if show then
		getglobal(self:GetName() .. 'HotKey'):Show()
		self:UpdateHotkey()
	else
		getglobal(self:GetName() .. 'HotKey'):Hide()
	end
end

function BongosPetButton:UpdateHotkey()
	getglobal(self:GetName() .. 'HotKey'):SetText(self:GetHotkey() or '')
end

function BongosPetButton:GetHotkey()
	local key = GetBindingKey(format('CLICK %s:LeftButton', self:GetName()))
	if not key then
		key = GetBindingText(GetBindingKey('BONUSACTIONBUTTON' .. self:GetID()), 'KEY_')
	end
	return KeyBound:ToShortKey(key)
end


--[[ Utility Functions ]]--

function BongosPetButton:ShowingEmptyButtons()
	return self.showEmpty or BongosActionMain:ShowingEmptyButtons()
end

function BongosPetButton:Get(id)
	return getglobal(format('PetActionButton%d', id))
end

function BongosPetButton:ForAll(action, ...)
	for i = 1, NUM_PET_ACTION_SLOTS do
		action(self:Get(i), ...)
	end
end