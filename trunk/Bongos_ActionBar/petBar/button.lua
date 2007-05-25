--[[
	BPetButton
		A Pet Action Button
		Should work exactly like the normal pet action buttons, but with a modified appearance
--]]

function BongosPetButton_Init()

BongosPetButton = CreateFrame("CheckButton", nil, nil, "SecureFrameTemplate")
local Button_mt = {__index = BongosPetButton}

--[[ Constructorish ]]--

local function OnDragStart(self) self:OnDragStart(arg1) end
local function OnReceiveDrag(self) self:OnReceiveDrag(arg1) end
local function OnEnter(self) self:OnEnter() end
local function OnLeave(self) self:OnLeave() end
local function OnEvent(self) self:UpdateHotkey() end

function BongosPetButton:Set(id, parent)
	local button = setmetatable(self:Get(id), Button_mt)
	button:SetParent(parent)
	button:SetFrameLevel(0)
	button:SetToplevel(false)

	button:SetScripts()
	button:Style()
	button:ShowHotkey(BongosActionConfig:ShowingHotkeys())

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
	self:RegisterEvent("UPDATE_BINDINGS")
	self:RegisterForDrag("LeftButton", "RightButton")
	self:RegisterForClicks("anyUp")

	self:SetScript("OnLoad", nil)
	self:SetScript("OnEvent", OnEvent)
	self:SetScript("OnDragStart", OnDragStart)
	self:SetScript("OnReceiveDrag", OnReceiveDrag)
	self:SetScript("OnEnter", OnEnter)
end


--[[ OnX Functions ]]--

function BongosPetButton:OnDragStart()
	if not BongosActionConfig:ButtonsLocked() or BongosActionConfig:IsQuickMoveKeyDown() or PetActionBarFrame.showgrid > 0 then
		self:SetChecked(false)
		PickupPetAction(self:GetID())
	end
end

function BongosPetButton:OnReceiveDrag()
	if PetActionBarFrame.showgrid > 0 or BongosActionConfig:IsQuickMoveKeyDown() then
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

function BongosPetButton:UpdateVisibility()
	if GetPetActionInfo(self:GetID()) or self:ShowingEmpty() then
		self:Show()
	else
		self:Hide()
	end
end


--[[ Hotkey Functions ]]--

function BongosPetButton:UpdateHotkey()
	getglobal(self:GetName() .. "HotKey"):SetText(self:GetHotkey() or "")
end

function BongosPetButton:ShowHotkey(show)
	if show then
		getglobal(self:GetName() .. "HotKey"):Show()
		self:UpdateHotkey()
	else
		getglobal(self:GetName() .. "HotKey"):Hide()
	end
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
	return PetActionBarFrame.showgrid > 0 or BongosActionConfig:ShowingEmptyButtons() or KeyBound:IsShown()
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

end