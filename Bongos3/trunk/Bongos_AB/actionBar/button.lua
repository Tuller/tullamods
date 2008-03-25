--[[
	ActionButton - A Bongos ActionButton
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local Action = Bongos:GetModule('ActionBar')
local Config = Bongos:GetModule('ActionBar-Config')
local Updater = Action.Updater

local ActionButton = Bongos:CreateWidgetClass('CheckButton')
Action.Button = ActionButton

local unused = {} --buttons we can reuse
local updatable = {} --buttons which have an action and are shown: thus we need to update based on range coloring
local used = {}

do
	local id = 1
	function ActionButton:Create(parent)
		local _G = getfenv(0)
		local b = self:New(CreateFrame('CheckButton', format('Bongos3ActionButton%d', id), parent, 'SecureActionButtonTemplate, ActionButtonTemplate'))
		local name = b:GetName()

		b.icon = _G[name .. 'Icon']
		b.border = _G[name .. 'Border']

		b.cooldown = _G[name .. 'Cooldown']
		b.cooldown:SetFrameLevel(max(b.cooldown:GetFrameLevel() - 1, 0))

		b.flash = _G[name .. 'Flash']
		b.hotkey = _G[name .. 'HotKey']
		b.macro = _G[name .. 'Name']
		b.count = _G[name .. 'Count']

		b:SetScript('OnAttributeChanged', self.OnAttributeChanged)
		b:SetScript('PostClick', self.UpdateState)
		b:SetScript('OnDragStart', self.OnDragStart)
		b:SetScript('OnReceiveDrag', self.OnReceiveDrag)
		b:SetScript('OnLeave', self.OnLeave)
		b:SetScript('OnEnter', self.OnEnter)
		b:SetScript('OnEvent', self.OnEvent)
		b:SetScript('OnShow', self.OnShow)
		b:SetScript('OnHide', self.OnHide)

		b:SetAttribute('type', 'action')
		b:SetAttribute('checkselfcast', true)
		b:SetAttribute('useparent-unit', true)
		b:SetAttribute('useparent-statebutton', true)

		b:RegisterForDrag('LeftButton', 'RightButton')
		b:RegisterForClicks('AnyUp')
		b:Hide()
		b:Skin()

		id = id + 1
		return b
	end
end

function ActionButton:Skin()
	self.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	self:GetNormalTexture():SetVertexColor(1, 1, 1, 0.5)
end

function ActionButton:UpdateNormalTexture(hasAction)
	if hasAction then
		self:SetNormalTexture('Interface/Buttons/UI-Quickslot2')
	else
		self:SetNormalTexture('Interface/Buttons/UI-Quickslot')
	end
end

function ActionButton:Get(parent)
	local b = self:GetUnused(parent) or self:Create(parent)
	parent:SetAttribute('addchild', b)

	b:SetParent(parent)
	b:ShowHotkey(Config:ShowingHotkeys())
	b:ShowMacro(Config:ShowingMacros())
	b:UpdateEquippedColor()
	b:UpdateEvents()

	used[b] = true

	return b
end

function ActionButton:GetUnused(parent)
	local button = next(unused)
	if button then
		unused[button] = nil
		button:SetParent(parent)
		return button
	end
end

function ActionButton:Release()
	self:Hide()
	self:SetParent(nil)
	self:UnregisterAllEvents()
	self:SetAttribute('showstates', nil)
	self.id = nil

	used[self] = nil
	unused[self] = true
end

--load events
function ActionButton:UpdateEvents()
	self:UnregisterAllEvents()

	self:RegisterEvent('UPDATE_BINDINGS')
	if self:IsVisible() then
		self:RegisterEvent('PLAYER_ENTERING_WORLD')
		self:RegisterEvent('PLAYER_AURAS_CHANGED')
		self:RegisterEvent('PLAYER_TARGET_CHANGED')
		self:RegisterEvent('UNIT_INVENTORY_CHANGED')
		self:RegisterEvent('ACTIONBAR_UPDATE_USABLE')
		self:RegisterEvent('UPDATE_INVENTORY_ALERTS')
		self:RegisterEvent('ACTIONBAR_UPDATE_COOLDOWN')

		self:RegisterEvent('ACTIONBAR_UPDATE_STATE')
		self:RegisterEvent('CRAFT_SHOW')
		self:RegisterEvent('CRAFT_CLOSE')
		self:RegisterEvent('TRADE_SKILL_SHOW')
		self:RegisterEvent('TRADE_SKILL_CLOSE')

		self:RegisterEvent('PLAYER_ENTER_COMBAT')
		self:RegisterEvent('PLAYER_LEAVE_COMBAT')
		self:RegisterEvent('START_AUTOREPEAT_SPELL')
		self:RegisterEvent('STOP_AUTOREPEAT_SPELL')
	end
end


--[[ OnX Functions ]]--

function ActionButton:OnEvent(event, arg1)
	if event == 'UPDATE_BINDINGS' then
		self:UpdateHotkey()
	elseif self:IsVisible() and HasAction(self:GetPagedID()) then
		if event == 'PLAYER_ENTERING_WORLD' then
			self:Update()
		elseif event == 'PLAYER_AURAS_CHANGED' or event == 'PLAYER_TARGET_CHANGED' then
			self:UpdateUsable()
		elseif event == 'UNIT_INVENTORY_CHANGED' then
			if arg1 == 'player' then
				self:Update()
			end
		elseif event == 'ACTIONBAR_UPDATE_USABLE' or event == 'UPDATE_INVENTORY_ALERTS' or event == 'ACTIONBAR_UPDATE_COOLDOWN' then
			self:UpdateCooldown()
			self:UpdateUsable()
		elseif event == 'ACTIONBAR_UPDATE_STATE' or event == 'CRAFT_SHOW' or event == 'CRAFT_CLOSE' or event == 'TRADE_SKILL_SHOW' or event == 'TRADE_SKILL_CLOSE' then
			self:UpdateState()
		elseif event == 'PLAYER_ENTER_COMBAT' or event == 'PLAYER_LEAVE_COMBAT' or event == 'START_AUTOREPEAT_SPELL' or event == 'STOP_AUTOREPEAT_SPELL' then
			self:UpdateFlash()
		end
	end
end

function ActionButton:OnAttributeChanged(var, val)
	if var == 'state-parent' or var == 'statehidden' then
		if self:IsShown() then
			self:Update(true)
			updatable[self] = (self.id and HasAction(self.id) or nil)
		else
			self.needsUpdate = true
		end
	end
end

function ActionButton:OnUpdate(elapsed)
	--update flashing
	if self.flashing then
		self.flashtime = self.flashtime - elapsed
		if self.flashtime <= 0 then
			local overtime = -self.flashtime
			if overtime >= ATTACK_BUTTON_FLASH_TIME then
				overtime = 0
			end
			self.flashtime = ATTACK_BUTTON_FLASH_TIME - overtime

			local flashTexture = self.flash
			if flashTexture:IsShown() then
				flashTexture:Hide()
			else
				flashTexture:Show()
			end
		end
	end

	-- Handle range indicator
	local action = self:GetPagedID()
	local hotkey = self.hotkey
	if IsActionInRange(action) == 0 then
		hotkey:SetVertexColor(1, 0.1, 0.1)
		if IsUsableAction(action) and Config:ColorOOR() then
			self.icon:SetVertexColor(Config:GetOORColor())
		end
	else
		hotkey:SetVertexColor(0.6, 0.6, 0.6)
		if IsUsableAction(action) then
			self.icon:SetVertexColor(1, 1, 1)
		end
	end
end

function ActionButton:OnDragStart()
	if LOCK_ACTIONBAR ~= '1' or self.showEmpty or IsModifiedClick('PICKUPACTION') then
		if not InCombatLockdown() then
			PickupAction(self:GetPagedID())
			self:Update()
		end
	end
end

function ActionButton:OnReceiveDrag()
	if not InCombatLockdown() then
		PlaceAction(self:GetPagedID())
		self:Update()
	end
end

function ActionButton:OnEnter()
	if GetCVar('UberTooltips') == '1' then
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end

	if Config:ShowingTooltips() then
		self:UpdateTooltip()
	end

	KeyBound:Set(self)
end

function ActionButton:UpdateTooltip()
	GameTooltip:SetAction(self:GetPagedID())
end

function ActionButton:OnLeave()
	GameTooltip:Hide()
end

function ActionButton:OnShow()
	if self.needsUpdate then
		self.needsUpdate = nil
		self:Update(true)
	end
	updatable[self] = (self.id and HasAction(self.id) or nil)
	self:UpdateEvents()
	self:UpdateState()
end

function ActionButton:OnHide()
	updatable[self] = nil
	self:UpdateEvents()
end


--[[ Updating ]]--

--Updates the icon, count, cooldown, usability color, if the button is flashing, if the button is equipped,  and macro text.
function ActionButton:Update(refresh)
	local action = self:GetPagedID(refresh)
	local icon = self.icon
	local cooldown = self.cooldown
	local texture = GetActionTexture(action)

	if texture then
		icon:SetTexture(texture)
		icon:Show()
		self:UpdateNormalTexture(true)
	else
		icon:Hide()
		cooldown:Hide()
		self:UpdateNormalTexture(nil)
		self.hotkey:SetVertexColor(0.6, 0.6, 0.6)
	end

	if HasAction(action) then
		self:UpdateState()
		self:UpdateUsable()
		self:UpdateCooldown()
		self:UpdateFlash()
	else
		self:SetChecked(false)
		cooldown:Hide()
	end

	self:UpdateCount()

	if IsEquippedAction(action) then
		self.border:Show()
	else
		self.border:Hide()
	end

	-- Update Macro Text
	local macroText = self.macro
	if not(IsConsumableAction(action) or IsStackableAction(action)) then
		macroText:SetText(GetActionText(action))
	else
		macroText:SetText('')
	end
end

--Update the cooldown timer
function ActionButton:UpdateCooldown()
	local start, duration, enable = GetActionCooldown(self:GetPagedID())
	CooldownFrame_SetTimer(self.cooldown, start, duration, enable)
end

--Update item count
function ActionButton:UpdateCount()
	local action = self:GetPagedID()
	self.count:SetText((IsConsumableAction(action) and GetActionCount(action)) or '')
end

--Update if a button is checked or not
function ActionButton:UpdateState()
	local action = self:GetPagedID()
	self:SetChecked(self:UpdateSpellInUse() or IsCurrentAction(action) or IsAutoRepeatAction(action))
end

--colors the action button if out of mana, out of range, etc
function ActionButton:UpdateUsable()
	local action = self:GetPagedID()
	local icon = self.icon

	local isUsable, notEnoughMana = IsUsableAction(action)
	if isUsable then
		--out of range
		if IsActionInRange(action) == 0 and Config:ColorOOR() then
			icon:SetVertexColor(Config:GetOORColor())
		--in range
		else
			icon:SetVertexColor(1, 1, 1)
		end
	--no mana
	elseif notEnoughMana then
		icon:SetVertexColor(Config:GetOOMColor())
	--unusable
	else
		icon:SetVertexColor(0.3, 0.3, 0.3)
	end
end

function ActionButton:UpdateFlash()
	local action = self:GetPagedID()
	if (IsAttackAction(action) and IsCurrentAction(action)) or IsAutoRepeatAction(action) then
		self:StartFlash()
	else
		self:StopFlash()
	end
end

--Buff/Debuff highlighting code
function ActionButton:UpdateBorder(spell)
	if spell then
		if UnitExists('target') then
			if UnitIsFriend('player', 'target') then
				if Updater:TargetHasBuff(spell) then

					self:GetCheckedTexture():SetVertexColor(Config:GetBuffColor())
					return true
				end
			elseif Updater:TargetHasDebuff(spell) then
				self:GetCheckedTexture():SetVertexColor(Config:GetDebuffColor())
				return true
			end
		end

		if Updater:PlayerHasBuff(spell) and not UnitIsFriend('player', 'target') then
			self:GetCheckedTexture():SetVertexColor(Config:GetBuffColor())
			return true
		end
	end
	self:GetCheckedTexture():SetVertexColor(1, 1, 1)
end

function ActionButton:UpdateSpellInUse()
	if Config:HighlightingBuffs() then
		local action = self:GetPagedID()
		if action then
			local spellID = self.spellID
			if spellID then
				if self.type == 'macro' then
					return self:UpdateBorder(GetMacroSpell(spellID))
				else
					return self:UpdateBorder(spellID)
				end
			end
		end
	end
	self:GetCheckedTexture():SetVertexColor(1, 1, 1)
end

function ActionButton:StartFlash()
	self.flashing = true
	self.flashtime = 0
	self:UpdateState()
end

function ActionButton:StopFlash()
	self.flashing = nil
	self.flash:Hide()
	self:UpdateState()
end

--visibility
--update button showstates based on what state actionIDs actually have actions
--returns true if the showstates have changed, false otherwise
function ActionButton:UpdateShowStates()
	local newStates

	if self:ShowingEmpty() then
		newStates = '*'
	else
		local id = self:GetAttribute('action')
		if HasAction(id) then
			newStates = 0
		end

		--so the possess bar's actions change dynamically, so we can not determine beforehand if we're going to have something to show or not
		--so, default to showing all actions
		--and yes, 999 is the magic state for the possess bar
		if self:GetParent():GetParent():IsPossessBar() then
			if newStates then
				newStates = newStates .. ',' .. 999
			else
				newStates = 999
			end
		end

		for i = 2, self:GetParent():GetParent():NumSets() do
			local action = self:GetAttribute(format('*action-s%ds', i)) or id
			if HasAction(action) then
				if newStates then
					newStates = newStates .. ',' .. i
				else
					newStates = i
				end
			end
		end
	end

	local newStates = newStates or '!*'
	if newStates ~= self:GetAttribute('showstates') then
		self:SetAttribute('showstates', newStates)
		return true
	end
end

--show empty buttons
function ActionButton:UpdateShown()
	if self:ShowingEmpty() or HasAction(self:GetPagedID()) then
		self:Show()
	else
		self:Hide()
	end
end

function ActionButton:ShowingEmpty()
	return self.showEmpty or KeyBound:IsShown() or Config:ShowingEmptyButtons()
end

--binding display
function ActionButton:ShowHotkey(enable)
	local hotkey = self.hotkey
	if enable then
		hotkey:Show()
		self:UpdateHotkey()
	else
		hotkey:Hide()
	end
end

function ActionButton:UpdateHotkey()
	self.hotkey:SetText(self:GetHotkey() or '')
end

function ActionButton:GetHotkey()
	local bindings = self:GetParent():GetParent():GetBindings(self.index)
	return bindings and KeyBound:ToShortKey(string.split(';', bindings))
end

--binding updating
function ActionButton:SetKey(key)
	self:GetParent():GetParent():AddBinding(self.index, key)
end

function ActionButton:FreeKey(key)
	return self:GetParent():GetParent():FreeBinding(key)
end

function ActionButton:ClearBindings()
	self:GetParent():GetParent():ClearBindings(self.index)
end

function ActionButton:GetBindings()
	local bindings = self:GetParent():GetParent():GetBindings(self.index)
	if bindings then
		local keys
		for i = 1, select('#', string.split(';', bindings)) do
			local hotKey = select(i, string.split(';', bindings))
			if keys then
				keys = keys .. ', ' .. GetBindingText(hotKey,'KEY_')
			else
				keys = GetBindingText(hotKey,'KEY_')
			end
		end
		return keys
	end
end

function ActionButton:GetActionName()
	return format('ActionBar%s Button%d', self:GetParent():GetParent().id, self.index)
end

--border coloring
function ActionButton:UpdateEquippedColor()
	self.border:SetVertexColor(Config:GetEquippedColor())
end

--macro
function ActionButton:ShowMacro(enable)
	local macro = self.macro
	if enable then
		macro:Show()
	else
		macro:Hide()
	end
end


--action updating
function ActionButton:UpdateSpellID()
	local type, arg1, arg2 = GetActionInfo(self:GetPagedID())

	self.type = type
	if type == 'spell' then
		if arg1 and arg2 and arg1 > 0 then
			self.spellID = GetSpellName(arg1, arg2)
		else
			self.spellID = nil
		end
	elseif type == 'item' then
		self.spellID = GetItemSpell(arg1)
	else
		self.spellID = arg1
	end
end

function ActionButton:UpdateAction(id)
	if self:GetPagedID() == id then
		self:Update()
		self:UpdateSpellID()
	end
end

function ActionButton:GetPagedID(refresh)
	if refresh or not self.id then
		self.id = SecureButton_GetModifiedAttribute(self, 'action', SecureStateChild_GetEffectiveButton(self))
		self:UpdateSpellID()
	end
	return self.id or 0
end


--[[ Utility Functions ]]--

function ActionButton:ForAll(method, ...)
	for button in self:GetAll() do
		button[method](button, ...)
	end
end

function ActionButton:GetAll()
	return pairs(used)
end

function ActionButton:GetUpdatable()
	return pairs(updatable)
end