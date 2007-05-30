--[[
	BPetButton
		A Pet Action Button
		Should work exactly like the normal pet action buttons, but with a modified appearance
--]]

BongosPetButton = CreateFrame("CheckButton")
local Button_mt = {__index = BongosPetButton}
local petBar = PetActionBarFrame


--[[ Frame Events ]]--

local function OnDragStart(self) self:OnDragStart() end
local function OnReceiveDrag(self) self:OnReceiveDrag() end
local function OnEnter(self) self:OnEnter() end
local function OnLeave(self) self:OnLeave() end
local function OnEvent(self) self:UpdateHotkey() end


--[[ Constructorish ]]--

function BongosPetButton:Set(id, parent)
	local button = setmetatable(self:Get(id), Button_mt)
	button:SetToplevel(nil)
	button:SetScripts()
	button:Style()
	button:ShowHotkey(BongosActionConfig:ShowingHotkeys())

	parent:Attach(button)

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

	self:SetScript("OnDragStart", OnDragStart)
	self:SetScript("OnReceiveDrag", OnReceiveDrag)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnEvent", OnEvent)
	self:RegisterEvent("UPDATE_BINDINGS")
end


--[[ OnX Functions ]]--

function BongosPetButton:OnDragStart()
	if petBar.showgrid > 0 or not(BongosActionConfig:ButtonsLocked()) or BongosActionConfig:IsQuickMoveKeyDown() then
		self:SetChecked(0)
		PickupPetAction(self:GetID())
		PetActionBar_Update()
	end
end

function BongosPetButton:OnReceiveDrag()
	if petBar.showgrid > 0 or BongosActionConfig:IsQuickMoveKeyDown() then
		self:SetChecked(0)
		PickupPetAction(self:GetID())
		PetActionBar_Update()
	end
end

function BongosPetButton:OnEnter()
	if BongosActionConfig:ShowingTooltips() then
		PetActionButton_OnEnter(self)
	end
	KeyBound:Set(self)
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