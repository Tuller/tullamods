--[[
	BPetButton
		A Pet Action Button
		Should work exactly like the normal pet action buttons, but with a modified appearance
--]]

BPetButton = CreateFrame('CheckButton')
local Button_mt = {__index = BPetButton}


--[[ Button Events ]]--

local function PostClick() this:PostClick() end
local function OnDragStart() this:OnDragStart() end
local function OnReceiveDrag() this:OnReceiveDrag() end
local function OnEnter() this:OnEnter() end
local function OnLeave() this:OnLeave() end


--[[ Constructorish ]]--

function BPetButton.Set(id, parent)
	local button = BPetButton.Get(id)
	setmetatable(button, Button_mt)

	button:SetAttribute('showstates', '1')
	button:SetScripts()
	button:Style()
	button:ShowHotkey(BActionConfig.HotkeysShown())
	
	parent:Attach(button)
	parent:SetAttribute('addchild', button)

	return button
end

function BPetButton:Style()
	local name = self:GetName()

	local autoCast = getglobal(name .. "AutoCast")
	autoCast:SetPoint("TOPLEFT", self, "TOPLEFT", -0.5, -1)
	autoCast:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0.5, -1.5)

	getglobal(name .. 'Icon'):SetTexCoord(0.06, 0.94, 0.06, 0.94)
	getglobal(name .. 'NormalTexture2'):SetVertexColor(1, 1, 1, 0.5)
end

function BPetButton:SetScripts()
	self:RegisterForDrag('LeftButton', 'RightButton')
	self:RegisterForClicks('anyUp')

	self:SetScript('OnLoad', nil)
	self:SetScript('OnEvent', nil)
	self:SetScript('OnDragStart', OnDragStart)
	self:SetScript('OnReceiveDrag', OnReceiveDrag)
	self:SetScript('OnEnter', OnEnter)
	self:SetScript('OnLeave', OnLeave)
end


--[[ OnX Functions ]]--

function BPetButton:OnDragStart()
	if not BActionConfig.ButtonsLocked() or BActionConfig.IsQuickMoveKeyDown() or bg_showPetGrid then
		self:SetChecked(false)
		PickupPetAction(self:GetID())
		self:UpdateVisibility()
	end
end

function BPetButton:OnReceiveDrag()
	if BActionConfig.IsQuickMoveKeyDown() or bg_showPetGrid then
		self:SetChecked(false)
		PickupPetAction(self:GetID())
		self:UpdateVisibility()
	end
end

function BPetButton:OnEnter()
	if BActionConfig.TooltipsShown() then
		PetActionButton_OnEnter()
	end
	KeyBound_Set(self)
end

function BPetButton:OnLeave()
	PetActionButton_OnLeave(this)
end


--[[ Update Functions ]]--

function BPetButton:Update()
	local name, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(self:GetID())
	local selfName = self:GetName()

	if name then
		SeeQ:Show(self)
	elseif not BPetButton.ShowGrid() then
		SeeQ:Hide(self)
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

--Update the cooldown timer
function BPetButton:UpdateCooldown()
	local start, duration, enable = GetPetActionCooldown(self:GetID())
	CooldownFrame_SetTimer(getglobal(self:GetName() .. 'Cooldown'), start, duration, enable)
end

function BPetButton:UpdateVisibility()
	if BPetButton.ShowGrid() or GetPetActionInfo(self:GetID()) then
		SeeQ:Show(self)
	else
		SeeQ:Hide(self)
	end
end


--[[ Hotkey Functions ]]--

function BPetButton:ShowHotkey(show)
	if show then
		getglobal(self:GetName() .. 'HotKey'):Show()
		self:UpdateHotkey()
	else
		getglobal(self:GetName() .. 'HotKey'):Hide()
	end
end

function BPetButton:UpdateHotkey()
	getglobal(self:GetName() .. 'HotKey'):SetText(self:GetHotkey() or '')
end

function BPetButton:GetHotkey()
	local key = GetBindingKey(format('CLICK %s:LeftButton', self:GetName()))
	if not key then
		key = GetBindingText(GetBindingKey('BONUSACTIONBUTTON' .. self:GetID()), 'KEY_')
	end
	return BActionUtil.ToShortKey(key)
end


--[[ Utility Functions ]]--

function BPetButton.ShowGrid()
	return bg_showPetGrid or BActionConfig.ShowGrid()
end

function BPetButton.Get(id)
	return getglobal(format('PetActionButton%d', id))
end

function BPetButton.ForAll(action, ...)
	for i = 1, NUM_PET_ACTION_SLOTS do
		action(BPetButton.Get(i), ...)
	end
end