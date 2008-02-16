--[[
	Class Button
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local ClassBar = Bongos:GetModule('ClassBar', true)
if not ClassBar then return end

local ClassButton = Bongos:CreateWidgetClass('CheckButton')
ClassBar.Button = ClassButton

local BUTTON_SIZE = 30
local NT_SIZE = (66/36) * BUTTON_SIZE
local buttons = {}


--[[ Constructor ]]--

function ClassButton:Create(id, parent)
	local name = format('BongosClassButton%d', id)

	--create the base button
	local button = self:New(CreateFrame('CheckButton', name, parent, 'SecureActionButtonTemplate'))
	button:SetWidth(BUTTON_SIZE); button:SetHeight(BUTTON_SIZE)
	button:SetID(id)

	--icon texture
	local icon = button:CreateTexture(name .. 'Icon', 'BACKGROUND')
	icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	icon:SetAllPoints(button)

	--normal, pushed, highlight, checked textures
	local normalTexture = button:CreateTexture(name .. 'NormalTexture')
	normalTexture:SetWidth(NT_SIZE); normalTexture:SetHeight(NT_SIZE)
	normalTexture:SetTexture('Interface\\Buttons\\UI-Quickslot2')
	normalTexture:SetPoint('CENTER', 0, -1)

	button:SetPushedTexture('Interface\\Buttons\\UI-Quickslot-Depress')
	button:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square')
	button:SetCheckedTexture('Interface\\Buttons\\CheckButtonHilight')

	--hotkey
	local hotkey = button:CreateFontString(name .. 'HotKey', 'ARTWORK')
	hotkey:SetFontObject('NumberFontNormalSmallGray')
	hotkey:SetPoint('TOPRIGHT', 2, -2)
	hotkey:SetJustifyH('RIGHT')
	hotkey:SetWidth(BUTTON_SIZE); hotkey:SetHeight(10)

	--cooldown model
	button.cooldown = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')

	button:SetAttribute('type', 'spell')
	button:SetScript('PostClick', self.PostClick)
	button:SetScript('OnEvent', self.OnEvent)
	button:SetScript('OnEnter', self.OnEnter)
	button:SetScript('OnLeave', self.OnLeave)
	button:SetScript('OnShow', self.UpdateEvents)
	button:SetScript('OnHide', self.UpdateEvents)

--	button:ShowHotkey(BongosActionConfig:ShowingHotkeys())
	button:UpdateSpell()
	button:UpdateEvents()

	buttons[id] = button

	return button
end


--[[ Frame Events ]]--

function ClassButton:UpdateEvents()
	if self:IsShown() then
		self:RegisterEvent('UPDATE_SHAPESHIFT_FORMS')
		self:RegisterEvent('PLAYER_ENTERING_WORLD')
		self:RegisterEvent('SPELL_UPDATE_COOLDOWN')
		self:RegisterEvent('SPELL_UPDATE_USABLE')
		self:RegisterEvent('PLAYER_AURAS_CHANGED')
		self:RegisterEvent('UPDATE_BINDINGS')
	else
		self:UnregisterAllEvents()
	end
end

function ClassButton:OnEvent(event)
	if event == 'UPDATE_BINDINGS' then
		self:UpdateHotkey()
	elseif event == 'UPDATE_SHAPESHIFT_FORMS' and (self:GetID() > GetNumShapeshiftForms()) then
		self:Hide()
	else
		self:Update()
	end
end

function ClassButton:OnEnter()
--	if BongosActionConfig:ShowingTooltips() then
		if GetCVar('UberTooltips') == '1' then
			GameTooltip_SetDefaultAnchor(GameTooltip, self)
		else
			GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		end
		GameTooltip:SetShapeshift(self:GetID())
--	end
	KeyBound:Set(self)
end

function ClassButton:OnLeave()
	GameTooltip:Hide()
end

function ClassButton:PostClick()
	self:SetChecked(not self:GetChecked())
end


--[[ Update Functions ]]--

function ClassButton:Update()
	local texture, name, isActive, isCastable = GetShapeshiftFormInfo(self:GetID())
	self:SetChecked(isActive)

	--update icon
	local icon = getglobal(self:GetName() .. 'Icon')
	icon:SetTexture(texture)
	if isCastable then
		icon:SetVertexColor(1, 1, 1)
	else
		icon:SetVertexColor(0.4, 0.4, 0.4)
	end

	--update cooldown
	if texture then
		local start, duration, enable = GetShapeshiftFormCooldown(self:GetID())
		CooldownFrame_SetTimer(self.cooldown, start, duration, enable)
	else
		self.cooldown:Hide()
	end
end

function ClassButton:UpdateSpell()
	self:SetAttribute('spell', select(2, GetShapeshiftFormInfo(self:GetID())))
	self:Update()
end


--[[ Hotkey Functions ]]--

function ClassButton:ShowHotkey(show)
	if show then
		getglobal(self:GetName() .. 'HotKey'):Show()
		self:UpdateHotkey()
	else
		getglobal(self:GetName() .. 'HotKey'):Hide()
	end
end

function ClassButton:UpdateHotkey()
	getglobal(self:GetName() .. 'HotKey'):SetText(self:GetHotkey() or '')
end

function ClassButton:GetHotkey()
	local key = GetBindingKey(format('CLICK %s:LeftButton', self:GetName()))
	if not key then
		key = GetBindingText(GetBindingKey('SHAPESHIFTBUTTON' .. self:GetID()), 'KEY_')
	end

	return KeyBound:ToShortKey(key)
end


--[[ Utility Functions ]]--

function ClassButton:ForAll(method, ...)
	for _, button in pairs(buttons) do
		button[method](button, ...)
	end
end

function ClassButton:Get(id)
	return buttons[id]
end