--[[
	BPetButton
		A Pet Action Button
		Should work exactly like the normal pet action buttons, but with a modified appearance
--]]

BongosPetButton = CreateFrame("CheckButton")
local Button_mt = {__index = BongosPetButton}

--[[ Constructorish ]]--

local function PostClick(self, arg1) self:PostClick(arg1) end
local function OnDragStart(self) self:OnDragStart(arg1) end
local function OnReceiveDrag(self) self:OnReceiveDrag(arg1) end
local function OnEnter(self) self:OnEnter() end
local function OnLeave(self) self:OnLeave() end

function BongosPetButton:Set(id, parent)
	local button = setmetatable(self:Get(id), Button_mt)
	button:SetToplevel(nil)
	button:SetScripts()
	button:Style()
	button:ShowHotkey(BongosActionConfig:ShowingHotkeys())

	parent:Attach(button)
	parent:SetAttribute("addchild", button)
	button:SetAttribute("showstates", "1")

	return button
end

function BongosPetButton:Style()
	local name = self:GetName()

	local autoCast = getglobal(name .. "AutoCast")
	autoCast:SetPoint("TOPLEFT", self, "TOPLEFT", -0.5, -1)
	autoCast:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0.5, -1.5)

	getglobal(name .. "Icon"):SetTexCoord(0.06, 0.94, 0.06, 0.94)
	getglobal(name .. "NormalTexture2"):SetVertexColor(1, 1, 1, 0.5)
end

function BongosPetButton:SetScripts()
	self:RegisterForDrag("LeftButton", "RightButton")
	self:RegisterForClicks("anyUp")

	self:SetScript("OnLoad", nil)
	self:SetScript("OnEvent", nil)
	self:SetScript("OnDragStart", OnDragStart)
	self:SetScript("OnReceiveDrag", OnReceiveDrag)
	self:SetScript("OnEnter", OnEnter)
end


--[[ OnX Functions ]]--

function BongosPetButton:OnDragStart()
	if not BongosActionConfig:ButtonsLocked() or BongosActionConfig:IsQuickMoveKeyDown() or self.showEmpty then
		self:SetChecked(false)
		PickupPetAction(self:GetID())
	end
end

function BongosPetButton:OnReceiveDrag()
	if self.showEmpty or BongosActionConfig:IsQuickMoveKeyDown() then
		self:SetChecked(false)
		PickupPetAction(self:GetID())
	end
end

function BongosPetButton:OnEnter()
	if BongosActionConfig:ShowingTooltips() then
		PetActionButton_OnEnter(self)
	end
	KeyBound:Set(self)
end


--[[ Update Functions ]]--

function BongosPetButton:Update()
	local action, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(self:GetID())
	local name = self:GetName()

	self.isToken = isToken
	self.tooltipSubtext = subtext
	self:SetChecked(isActive)

	local icon = getglobal(name .. "Icon")
	SetDesaturation(icon, not GetPetActionsUsable())

	if texture then
		icon:Show()
		self:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
	else
		icon:Hide()
		self:SetNormalTexture("Interface\\Buttons\\UI-Quickslot")
	end

	if not isToken then
		icon:SetTexture(texture)
		self.tooltipName = action
	else
		icon:SetTexture(getglobal(texture))
		self.tooltipName = getglobal(action)
	end

	local autoCastTexture = getglobal(name .. "AutoCastable")
	if autoCastAllowed then
		autoCastTexture:Show()
	else
		autoCastTexture:Hide()
	end

	local autoCastModel = getglobal(name .. "AutoCast")
	if autoCastEnabled then
		autoCastModel:Show()
	else
		autoCastModel:Hide()
	end
end

function BongosPetButton:UpdateCooldown()
	local start, duration, enable = GetPetActionCooldown(self:GetID())
	CooldownFrame_SetTimer(getglobal(self:GetName() .. "Cooldown"), start, duration, enable)
end

function BongosPetButton:UpdateVisibility()
	if not(UnitExists("pet")) or self:ShowingEmpty() or GetPetActionInfo(self:GetID()) then
		self:SetAttribute("showstates", "1")
	else
		self:SetAttribute("showstates", "!*")
	end
end


--[[ Hotkey Functions ]]--

function BongosPetButton:ShowHotkey(show)
	if show then
		getglobal(self:GetName() .. "HotKey"):Show()
		self:UpdateHotkey()
	else
		getglobal(self:GetName() .. "HotKey"):Hide()
	end
end

function BongosPetButton:UpdateHotkey()
	getglobal(self:GetName() .. "HotKey"):SetText(self:GetHotkey() or "")
end

function BongosPetButton:GetHotkey()
	local key = GetBindingKey(format("CLICK %s:LeftButton", self:GetName()))
	if not key then
		key = GetBindingText(GetBindingKey("BONUSACTIONBUTTON" .. self:GetID()), "KEY_")
	end
	return KeyBound:ToShortKey(key)
end


--[[ Utility Functions ]]--

function BongosPetButton:ShowingEmpty()
	return self.showEmpty or BongosActionConfig:ShowingEmptyButtons() or KeyBound:IsShown()
end

function BongosPetButton:Get(id)
	return getglobal(format("PetActionButton%d", id))
end

function BongosPetButton:ForAll(method, ...)
	for i = 1, NUM_PET_ACTION_SLOTS do
		local button = self:Get(i)
		local action = button[method]
		action(button, ...)
	end
end