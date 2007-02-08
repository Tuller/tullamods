--[[
	Class Button
--]]

BClassButton = CreateFrame('CheckButton')
local Button_mt = {__index = BClassButton}

local NORMALTEX_RATIO = 1.833333333
local BUTTON_SIZE = 30
local buttons = {}


--[[ Button Events ]]--

local function PostClick() this:PostClick() end
local function OnEnter() this:OnEnter() end
local function OnLeave() this:OnLeave() end


--[[ Constructor ]]--

function BClassButton.Create(id, parent)
	local name = 'BClassButton' .. id

	local button = CreateFrame("CheckButton", name, parent, 'SecureActionButtonTemplate')
	setmetatable(button, Button_mt)
	
	button:SetID(id)
	button:SetAlpha(parent:GetAlpha())
	button:SetHeight(BUTTON_SIZE); button:SetWidth(BUTTON_SIZE)

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
	CreateFrame('Cooldown', name .. 'Cooldown', button, 'CooldownFrameTemplate')

	--set what spell this button casts
	local spell = select(2, GetShapeshiftFormInfo(id))
	button:SetAttribute('type', 'spell')
	button:SetAttribute('spell', spell)

	button:SetScript("PostClick", PostClick)
	button:SetScript("OnEnter", OnEnter)
	button:SetScript("OnLeave", OnLeave)

	button:ShowHotkey(BActionConfig.HotkeysShown())
	button:Update()

	buttons[id] = button

	return button
end


--[[ OnX Functions ]]--

function BClassButton:PostClick()
	self:SetChecked(not self:GetChecked())
end

function BClassButton:OnEnter()
	if BActionConfig.TooltipsShown() then
		if GetCVar("UberTooltips") == "1" then
			GameTooltip_SetDefaultAnchor(GameTooltip, self)
		else
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		end
		GameTooltip:SetShapeshift(self:GetID())
	end
	KeyBound_Set(self)
end

function BClassButton:OnLeave()
	GameTooltip:Hide() 
end


--[[ Update Functions ]]--

function BClassButton:Update()
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

function BClassButton:ShowHotkey(show)
	if show then
		getglobal(self:GetName() .. 'HotKey'):Show()
		self:UpdateHotkey()
	else
		getglobal(self:GetName() .. 'HotKey'):Hide()
	end
end

function BClassButton:UpdateHotkey()
	getglobal(self:GetName() .. 'HotKey'):SetText(self:GetHotkey() or '')
end

function BClassButton:GetHotkey()
	local key = GetBindingKey('CLICK ' .. self:GetName() .. ':LeftButton')
	if not key then
		key = GetBindingText(GetBindingKey('SHAPESHIFTBUTTON' .. self:GetID()), 'KEY_')
	end

	return BActionUtil.ToShortKey(key)
end


--[[ Utility Functions ]]--

function BClassButton.ForAll(action, ...)
	for _, button in pairs(buttons) do
		action(button, ...)
	end
end

function BClassButton.Get(id)
	return buttons[id]
end