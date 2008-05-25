--[[
	Class Button
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local ClassBar = Bongos:GetModule('ClassBar', true)
if not ClassBar then return end

local KeyBound = LibStub('LibKeyBound-1.0')
local Config = Bongos:GetModule('ActionBar-Config')
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

	button.icon = button:CreateTexture(name .. 'Icon', 'BACKGROUND')
	button.hotkey = button:CreateFontString(name .. 'HotKey', 'ARTWORK')

	--cooldown model
	button.cooldown = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')

	button:SetAttribute('type', 'spell')
	button:SetScript('PostClick', self.PostClick)
	button:SetScript('OnEvent', self.OnEvent)
	button:SetScript('OnEnter', self.OnEnter)
	button:SetScript('OnLeave', self.OnLeave)
	button:SetScript('OnShow', self.UpdateEvents)
	button:SetScript('OnHide', self.UpdateEvents)

	button:Skin()
	button:ShowHotkey(Config:ShowingHotkeys())
	button:UpdateSpell()
	button:UpdateEvents()

	buttons[id] = button

	return button
end

function ClassButton:Skin()
	self.icon:SetAllPoints(self)
	self.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)

	self:SetNormalTexture('Interface\\Buttons\\UI-Quickslot2')
	local nt = self:GetNormalTexture()
	nt:ClearAllPoints()
	nt:SetPoint('CENTER', 0, -1)
	nt:SetWidth(NT_SIZE); nt:SetHeight(NT_SIZE)

	self:SetPushedTexture('Interface\\Buttons\\UI-Quickslot-Depress')
	self:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square')
	self:SetCheckedTexture('Interface\\Buttons\\CheckButtonHilight')

	self.hotkey:SetFontObject('NumberFontNormalSmallGray')
	self.hotkey:SetPoint('TOPRIGHT', 2, -2)
	self.hotkey:SetJustifyH('RIGHT')
	self.hotkey:SetWidth(BUTTON_SIZE); self.hotkey:SetHeight(10)
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
	if Config:ShowingTooltips() then
		if GetCVar('UberTooltips') == '1' then
			GameTooltip_SetDefaultAnchor(GameTooltip, self)
		else
			GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		end
		GameTooltip:SetShapeshift(self:GetID())
	end
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