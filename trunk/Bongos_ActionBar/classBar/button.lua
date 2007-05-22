--[[
	Class Button
--]]

BongosClassButton = CreateFrame("CheckButton")
local Button_mt = {__index = BongosClassButton}

local NORMALTEX_RATIO = 1.833333334
local BUTTON_SIZE = 30
local buttons = {}

--[[ Constructor ]]--

local function PostClick(self) self:PostClick() end
local function OnEnter(self) self:OnEnter() end
local function OnLeave(self) self:OnLeave() end

function BongosClassButton:Create(id, parent)
	local name = format("BongosClassButton%s", id)
	local button = setmetatable(CreateFrame("CheckButton", name, parent, "SecureActionButtonTemplate"), Button_mt)

	button:SetID(id)
	button:SetAlpha(parent:GetAlpha())
	button:SetHeight(BUTTON_SIZE)
	button:SetWidth(BUTTON_SIZE)

	--icon texture
	local icon = button:CreateTexture(name .. "Icon", "BACKGROUND")
	icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	icon:SetAllPoints(button)

	--normal, pushed, highlight, checked textures
	local normalTexture = button:CreateTexture(name .. "NormalTexture")
	normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot2")
	normalTexture:SetHeight(NORMALTEX_RATIO * BUTTON_SIZE)
	normalTexture:SetWidth(NORMALTEX_RATIO * BUTTON_SIZE)
	normalTexture:SetPoint("CENTER", button, "CENTER", 0, -1)

	button:SetNormalTexture(normalTexture)
	button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
	button:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")

	--hotkey
	local hotkey = button:CreateFontString(name .. "HotKey", "ARTWORK")
	hotkey:SetFontObject(NumberFontNormalSmallGray)
	hotkey:SetPoint("TOPRIGHT", button, "TOPRIGHT", 2, -2)
	hotkey:SetJustifyH("RIGHT")
	hotkey:SetWidth(BUTTON_SIZE); hotkey:SetHeight(10)

	--cooldown model
	CreateFrame("Cooldown", name .. "Cooldown", button, "CooldownFrameTemplate")

	--set what spell this button casts
	local spell = select(2, GetShapeshiftFormInfo(id))
	button:SetAttribute("type", "spell")
	button:SetAttribute("spell", spell)

	button:SetScript("PostClick", PostClick)
	button:SetScript("OnEnter", OnEnter)
	button:SetScript("OnLeave", OnLeave)

	button:ShowHotkey(BongosActionMain:ShowingHotkeys())
	button:Update()

	buttons[id] = button

	return button
end


--[[ OnX Functions ]]--

function BongosClassButton:PostClick()
	self:SetChecked(not self:GetChecked())
end

function BongosClassButton:OnEnter()
	if BongosActionMain:ShowingTooltips() then
		if GetCVar("UberTooltips") == "1" then
			GameTooltip_SetDefaultAnchor(GameTooltip, self)
		else
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		end
		GameTooltip:SetShapeshift(self:GetID())
	end
	KeyBound:Set(self)
end

function BongosClassButton:OnLeave()
	GameTooltip:Hide()
end


--[[ Update Functions ]]--

function BongosClassButton:Update()
	local texture, name, isActive, isCastable = GetShapeshiftFormInfo(self:GetID())
	self:SetChecked(isActive)

	--update icon
	local icon = getglobal(self:GetName() .. "Icon")
	icon:SetTexture(texture)

	if isCastable then
		icon:SetVertexColor(1, 1, 1)
	else
		icon:SetVertexColor(0.4, 0.4, 0.4)
	end

	--update cooldown
	local cooldown = getglobal(self:GetName() .. "Cooldown")
	if texture then
		cooldown:Show()
	else
		cooldown:Hide()
	end

	local start, duration, enable = GetShapeshiftFormCooldown(self:GetID())
	CooldownFrame_SetTimer(cooldown, start, duration, enable)
end


--[[ Hotkey Functions ]]--

function BongosClassButton:ShowHotkey(show)
	if show then
		getglobal(self:GetName() .. "HotKey"):Show()
		self:UpdateHotkey()
	else
		getglobal(self:GetName() .. "HotKey"):Hide()
	end
end

function BongosClassButton:UpdateHotkey()
	getglobal(self:GetName() .. "HotKey"):SetText(self:GetHotkey() or "")
end

function BongosClassButton:GetHotkey()
	local key = GetBindingKey(format("CLICK %s:LeftButton", self:GetName()))
	if not key then
		key = GetBindingText(GetBindingKey("SHAPESHIFTBUTTON" .. self:GetID()), "KEY_")
	end

	return KeyBound:ToShortKey(key)
end


--[[ Utility Functions ]]--

function BongosClassButton:ForAll(method, ...)
	for _, button in pairs(buttons) do
		local action = button[method]
		action(button, ...)
	end
end

function BongosClassButton:Get(id)
	return buttons[id]
end