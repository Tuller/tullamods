--[[
	ActionButton - A Bongos ActionButton
--]]

local Bongos = LibStub('AceAddon-3.0'):GetAddon('Bongos3')
local Action = Bongos:GetModule('ActionBar')

local ActionButton = Bongos:CreateWidgetClass('CheckButton')
Action.Button = ActionButton

local unused = {} --buttons we can reuse
local updatable = {} --buttons which have an action and are shown: thus we need to update based on range coloring

--buff and debuff caches
local targetBuffs = {}
local targetDebuffs = {}
local playerBuffs = {}

do
	local id = 1
	function ActionButton:Create(parent)
		local _G = getfenv(0)
		local b = self:New(CreateFrame('CheckButton', format('Bongos3ActionButton%d', id), parent, 'SecureActionButtonTemplate, ActionButtonTemplate'))

		local name = b:GetName()
		b.icon = _G[name .. 'Icon']
		b.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)

		b.border = _G[name .. 'Border']
		b.border:SetVertexColor(0, 1, 0, 0.7)

		b.normal = _G[name .. 'NormalTexture']
		b.normal:SetVertexColor(1, 1, 1, 0.5)

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

		b:SetScript('OnShow', self.OnShow)
		b:SetScript('OnHide', self.OnHide)

		b:SetAttribute('type', 'action')
		b:SetAttribute('checkselfcast', true)
		b:SetAttribute('useparent-unit', true)
		b:SetAttribute('useparent-statebutton', true)

		b:RegisterForDrag('LeftButton', 'RightButton')
		b:RegisterForClicks('AnyUp')

		id = id + 1
		return b
	end
end

function ActionButton:Get(parent)
	local b = self:GetUnused(parent) or self:Create(parent)
	parent:Attach(b)
	parent:SetAttribute('addchild', b)

	-- b:ShowHotkey(BongosActionConfig:ShowingHotkeys())
	-- b:ShowMacro(BongosActionConfig:ShowingMacros())
	b:UpdateEvents()

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
	if self.rangeTimer then
		local action = self:GetPagedID()
		local hotkey = self.hotkey
		if IsActionInRange(action) == 0 then
			hotkey:SetVertexColor(1, 0.1, 0.1)
			-- if IsUsableAction(action) and BongosActionConfig:RangeColoring() then
				-- local r,g,b = BongosActionConfig:GetRangeColor()
				-- self.icon:SetVertexColor(r,g,b)
			-- end
		else
			hotkey:SetVertexColor(0.6, 0.6, 0.6)
			if IsUsableAction(action) then
				self.icon:SetVertexColor(1, 1, 1)
			end
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
	self:UpdateTooltip()

	-- if BongosActionConfig:ShowingTooltips() then
		-- self:UpdateTooltip()
	-- end

--	KeyBound:Set(self)
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
end

function ActionButton:OnHide()
	updatable[self] = nil
	self:UpdateEvents()
end


--[[ Update Code ]]--

--Updates the icon, count, cooldown, usability color, if the button is flashing, if the button is equipped,  and macro text.
function ActionButton:Update(refresh)
	local action = self:GetPagedID(refresh)
	local icon = self.icon
	local cooldown = self.cooldown
	local texture = GetActionTexture(action)

	if texture then
		icon:SetTexture(texture)
		icon:Show()
		self.rangeTimer = (ActionHasRange(action) and -1) or nil

		self:SetNormalTexture('Interface/Buttons/UI-Quickslot2')
	else
		icon:Hide()
		cooldown:Hide()
		self.rangeTimer = nil

		self:SetNormalTexture('Interface/Buttons/UI-Quickslot')
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
		-- if IsActionInRange(action) == 0 and BongosActionConfig:RangeColoring() then
			-- local r,g,b = BongosActionConfig:GetRangeColor()
			-- icon:SetVertexColor(r,g,b)
		-- else
			-- icon:SetVertexColor(1, 1, 1)
		-- end
	elseif notEnoughMana then
		--Make the icon blue if out of mana
		icon:SetVertexColor(0.5, 0.5, 1)
	else
		--Skill unusable
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
				if targetBuffs[spell] then
					self:GetCheckedTexture():SetVertexColor(0, 1, 0)
					return true
				end
			elseif targetDebuffs[spell] then
				self:GetCheckedTexture():SetVertexColor(1, 0, 1)
				return true
			end
		end

		if playerBuffs[spell] and not UnitIsFriend('player', 'target') then
			self:GetCheckedTexture():SetVertexColor(0, 1, 0)
			return true
		end
	end
	self:GetCheckedTexture():SetVertexColor(1, 1, 1)
end

function ActionButton:UpdateSpellInUse()
	-- if BongosActionConfig:HighlightingBuffs() then
		-- local action = self:GetPagedID()
		-- if action then
			-- local spellID = self.spellID
			-- if spellID then
				-- if self.type == 'macro' then
					-- return self:UpdateBorder(GetMacroSpell(spellID))
				-- else
					-- return self:UpdateBorder(spellID)
				-- end
			-- end
		-- end
	-- end
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

function ActionButton:UpdateTooltip()
	GameTooltip:SetAction(self:GetPagedID())
end


--[[ State Updating ]]--
--[[
local CLASS = BONGOS_CLASS
local hasStance = (CLASS == 'DRUID' or CLASS == 'ROGUE' or CLASS == 'WARRIOR' or CLASS == 'PRIEST')

function ActionButton:UpdateStateAction(stateID)
	local id = self:GetAttribute('action')
	local offset = self:GetParent():GetStateOffset(stateID)

	if offset then
		self:SetAttribute('*action-' .. stateID, toValid(id + offset))
		self:SetAttribute('*action-' .. stateID .. 's', toValid(id + offset))
	else
		self:SetAttribute('*action-' .. stateID, nil)
		self:SetAttribute('*action-' .. stateID .. 's', nil)
	end
end

--load up the action ID when in forms/paged from the parent action bar
function ActionButton:UpdateStates()
	local id = self:GetAttribute('action')
	local parent = self:GetParent()

	if hasStance then
		local maxState = (CLASS == 'PRIEST' and 1) or GetNumShapeshiftForms()
		for i = 1, maxState do
			self:UpdateStateAction('s' .. i)
		end
		if CLASS == 'DRUID' then
			self:UpdateStateAction('s7')
		end
	end

	for i = 1, BONGOS_MAX_PAGES do
		self:UpdateStateAction('p' .. i)
	end

	for i = 1, 3 do
		self:UpdateStateAction('m' .. i)
	end

	self:UpdateStateAction('help')

	self:UpdateVisibility()
	self.needsUpdate = true
end

--update button showstates based on what state actionIDs actually have actions
--returns true if the showstates have changed, false otherwise
function ActionButton:UpdateVisibility()
	local newstates
	if self:ShowingEmpty() then
		newstates = '*'
	else
		local id = self:GetAttribute('action')
		if HasAction(id) then
			newstates = 0
		end

		if hasStance then
			local maxState = (CLASS == 'PRIEST' and 1) or GetNumShapeshiftForms()

			for i = 1, maxState do
				local action = self:GetAttribute('*action-s' .. i) or id
				if HasAction(action) then
					newstates = (newstates and newstates .. ',' .. i) or i
				end
			end

			if(CLASS == 'DRUID') then
				local action = self:GetAttribute('*action-s' .. 7) or id
				if HasAction(action) then
					newstates = (newstates and newstates .. ',' .. 7) or 7
				end
			end
		end

		for i = 1, BONGOS_MAX_PAGES do
			local action = self:GetAttribute('*action-p' .. i) or id
			if HasAction(action) then
				newstates = (newstates and newstates .. ',' .. (i+9)) or (i+9)
			end
		end

		for i = 1, 3 do
			local action = self:GetAttribute('*action-m' .. i) or id
			if HasAction(action) then
				newstates = (newstates and newstates .. ',' .. (i+15)) or (i+15)
			end
		end

		local action = self:GetAttribute('*action-help') or id
		if HasAction(action) then
			newstates = (newstates and newstates .. ',' .. 15) or 15
		end
	end

	newstates = newstates or '!*'
	local oldstates = self:GetAttribute('showstates')
	if not oldstates or oldstates ~= newstates then
		self:SetAttribute('showstates', newstates)
		return true
	end
end
--]]

--[[ Showgrid Stuff ]]

function ActionButton:UpdateGrid()
	if self:ShowingEmpty() or HasAction(self:GetPagedID()) then
		self:Show()
	else
		self:Hide()
	end
end


--[[ Hotkey Functions ]]--

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
	local key = GetBindingKey(format('CLICK %s:LeftButton', self:GetName()))
	if key then
		return KeyBound:ToShortKey(key)
	end
end


--[[ Macro Functions ]]--

function ActionButton:ShowMacro(enable)
	local macro = self.macro
	if enable then
		macro:Show()
	else
		macro:Hide()
	end
end


--[[ Utility Functions ]]--

function ActionButton:UpdateSpellID()
	local type, arg1, arg2 = GetActionInfo(self:GetPagedID())

	self.type = type
	if type == 'spell' then
		if arg1 and arg2 then
			--invalid spell slot check
			if arg1 > 0 then
				self.spellID = GetSpellName(arg1, arg2)
			end
		else
			self.spellID = nil
		end
	elseif type == 'item' then
		self.spellID = GetItemSpell(arg1)
	else
		self.spellID = arg1
	end
end

function ActionButton:GetPagedID(refresh)
	if refresh or not self.id then
		self.id = SecureButton_GetModifiedAttribute(self, 'action', SecureStateChild_GetEffectiveButton(self))
		self:UpdateSpellID()
	end
	return self.id or 0
end

function ActionButton:ShowingEmpty()
	return self.showEmpty
--	return self.showEmpty or BongosActionConfig:ShowingEmptyButtons() or KeyBound:IsShown()
end


--range check/flash and buff updating
--[[
do
	local f = CreateFrame('Frame')
	local newVals = {} --store new info in here

	--clear a table, returning true if there was stuff to clear
	local function ClearTable(t)
		if next(t) then
			for i in pairs(t) do
				t[i] = nil
			end
			return true
		end
	end

	--remove any values from t that are not in toClone
	--adds any values from tableToClone that are not in t
	--requires that both tables be using the same key value pairs
	local function CloneTable(t, toClone)
		local changed = false

		--remove any values not in tClone
		for i in pairs(t) do
			if not toClone[i] then
				t[i] = nil
				changed = true
			end
		end

		--add any values in tClone that are not in t
		for i,v in pairs(toClone) do
			if not t[i] then
				t[i] = v
				changed = true
			end
		end

		return changed
	end

	local function UpdateFriendlyTargetBuffs()
		local changed = false

		--clear the new vals table
		ClearTable(newVals)

		--friendly target, clear target debuffs
		if ClearTable(targetDebuffs) then
			changed = true
		end

		--add all target buffs into newVals
		local i = 1
		local buff
		repeat
			buff = UnitBuff('target', i)
			if buff then
				newVals[buff] = true
			end
			i = i + 1
		until not buff

		--set changed to true if the target buffs table has changed
		if CloneTable(targetBuffs, newVals) then
			changed = true
		end

		return changed
	end

	local function UpdateEnemyTargetDebuffs()
		local changed = false

		--clear the new vals table
		ClearTable(newVals)

		--enemy target, clear target buffs
		if ClearTable(targetBuffs) then
			changed = true
		end

		--update debuffs on enemy targets
		local i = 1
		local buff, cooldown, _
		repeat
			buff, _, _, _, _, cooldown = UnitDebuff('target', i)
			if buff and cooldown then
				newVals[buff] = true
			end
			i = i + 1
		until not buff

		--set changed to true if the target debuffs table has changed
		if CloneTable(targetDebuffs, newVals) then
			changed = true
		end

		return changed
	end

	local function ClearTargetBuffsAndDebuffs()
		local changed = false

		if ClearTable(targetBuffs) then
			changed = true
		end
		if ClearTable(targetDebuffs) then
			changed = true
		end

		return changed
	end

	function f:UpdateTargetBuffs()
		local changed = false

		if UnitExists('target') then
			if UnitIsFriend('player', 'target') then
				changed = UpdateFriendlyTargetBuffs()
			else
				changed = UpdateEnemyTargetDebuffs()
			end
		else
			changed = ClearTargetBuffsAndDebuffs()
		end

		--if change, mark for updating
		if changed then
			self.shouldUpdateBuffs = true
		end
	end

	function f:UpdatePlayerBuffs()
		local changed = false

		ClearTable(newVals)

		local buff
		local i = 1
		repeat
			buff = UnitBuff('player', i)
			if buff then
				newVals[buff] = true
			end
			i = i + 1
		until not buff

		if CloneTable(playerBuffs, newVals) then
			changed = true
		end

		--something changed, trigger update buffs
		if changed then
			self.shouldUpdateBuffs = true
		end
	end

	--buff and debuff updating stuff
	f:SetScript('OnEvent', function(self, event, unit)
		if BongosActionConfig:HighlightingBuffs() then
			if event == 'PLAYER_TARGET_CHANGED' then
				self:UpdateTargetBuffs()
			elseif event == 'UNIT_AURA' then
				if unit == 'target' then
					self:UpdateTargetBuffs()
				end
			elseif event == 'PLAYER_AURAS_CHANGED' then
				self:UpdatePlayerBuffs()
			end
		end
	end)
	f:RegisterEvent('UNIT_AURA')
	f:RegisterEvent('PLAYER_AURAS_CHANGED')
	f:RegisterEvent('PLAYER_TARGET_CHANGED')

	--on update script, handles throttled buff and debuff updating as well as range updating
	f:SetScript('OnUpdate', function(self, elapsed)
		if self.shouldUpdateBuffs then
			self.shouldUpdateBuffs = nil
			for button in pairs(updatable) do
				button:UpdateState()
			end
		end

		if self.nextUpdate < 0 then
			self.nextUpdate = self.delay
			for button in pairs(updatable) do
				button:OnUpdate(self.delay)
			end
		else
			self.nextUpdate = self.nextUpdate - elapsed
		end
	end)
	f.nextUpdate = 1
	f.delay = 1
end
--]]