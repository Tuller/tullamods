--[[
	BActionButton
		A Bongos ActionButton
--]]

BActionButton = CreateFrame('CheckButton')
local Button_mt = {__index = BActionButton}

local BUTTON_NAME = 'BActionButton%d'
local SIZE = 36
local MAX_BUTTONS = 120 --the current maximum amount of action buttons
local buttons = {}


--[[ Button Events ]]--

local function OnUpdate(self, arg1) self:OnUpdate(arg1) end
local function PostClick(self) self:PostClick() end
local function OnDragStart(self) self:OnDragStart() end
local function OnReceiveDrag(self) self:OnReceiveDrag() end
local function OnEnter(self) self:OnEnter() end
local function OnLeave(self) self:OnLeave() end
local function OnShow(self) self:Update(true) end


--[[ Action Button Methods ]]--

BActionButton.HasNormalTexture = true

--Create an Action Button with the given ID and parent
function BActionButton.Create(id)
	local name = format(BUTTON_NAME, id)
	local button = CreateFrame('CheckButton', name, nil, 'SecureActionButtonTemplate, ActionButtonTemplate')
	setmetatable(button, Button_mt)

	button:RegisterForDrag("LeftButton", "RightButton")
	button:RegisterForClicks('anyUp')
	button:SetAttribute('type', 'action')
	button:SetAttribute('action', id)
	button:SetID(id)
	button:SetAttribute('useparent-statebutton', true)
	button:SetAttribute('useparent-unit', true)
	button:SetAttribute('checkselfcast', true)

	button:SetScript('OnUpdate', OnUpdate)
	button:SetScript('PostClick', PostClick)
	button:SetScript('OnDragStart', OnDragStart)
	button:SetScript('OnReceiveDrag', OnReceiveDrag)
	button:SetScript('OnEnter', OnEnter)
	button:SetScript('OnLeave', OnLeave)
	button:SetScript('OnShow', OnShow)

	button:Style()
	button:Hide()

	buttons[id] = button

	return button
end


--[[ attach and remove ]]--

function BActionButton.Set(id, parent)
	local button = buttons[id] or BActionButton.Create(id)

	parent:Attach(button)
	parent:SetAttribute('addchild', button)

	button:ShowHotkey(BActionConfig.HotkeysShown())
	button:ShowMacro(BActionConfig.MacrosShown())
	button:UpdateAllStances()
	button:UpdateAllPages()
	button:UpdateVisibility()

	return button
end

function BActionButton:Release()
	self:SetParent(nil)
	self:ClearAllPoints()
	self:Hide()
end

--adjust the looks of the button, currently uses a zoomed layout
function BActionButton:Style()
	local name = self:GetName()
	getglobal(name .. 'Icon'):SetTexCoord(0.06, 0.94, 0.06, 0.94)
	getglobal(name .. 'Border'):SetVertexColor(0, 1, 0, 0.6)
	getglobal(name .. 'NormalTexture'):SetVertexColor(1, 1, 1, 0.5)
end


--[[ OnX Functions ]]--

function BActionButton:OnUpdate(elapsed)
	local name = self:GetName()
	if not getglobal(name .. "Icon"):IsShown() then return end

	--update flashing
	if self.flashing == 1 then
		self.flashtime = self.flashtime - elapsed
		if self.flashtime <= 0 then
			local overtime = -self.flashtime
			if overtime >= ATTACK_BUTTON_FLASH_TIME then
				overtime = 0
			end
			self.flashtime = ATTACK_BUTTON_FLASH_TIME - overtime

			local flashTexture = getglobal(name .. "Flash")
			if flashTexture:IsShown() then
				flashTexture:Hide()
			else
				flashTexture:Show()
			end
		end
	end

	-- Handle range indicator
	if self.rangeTimer then
		if self.rangeTimer < 0 then
			local pagedID = self:GetPagedID()
			local hotkey = getglobal(name .. "HotKey")

			if IsActionInRange(pagedID) == 0 then
				hotkey:SetVertexColor(1, 0.1, 0.1)

				if BActionConfig.ColorOutOfRange() and IsUsableAction(pagedID) then
					local r,g,b = BActionConfig.GetRangeColor()
					getglobal(name .. "Icon"):SetVertexColor(r,g,b)
				end
			else
				hotkey:SetVertexColor(0.6, 0.6, 0.6)

				if IsUsableAction(pagedID) then
					getglobal(name .. "Icon"):SetVertexColor(1, 1, 1)
				end
			end
			self.rangeTimer = TOOLTIP_UPDATE_TIME
		else
			self.rangeTimer = self.rangeTimer - elapsed
		end
	end

	-- Tooltip stuff, probably for the cooldown timer
	-- if self.nextTooltipUpdate then
		-- self.nextTooltipUpdate = self.nextTooltipUpdate - elapsed
		-- if self.nextTooltipUpdate <= 0 then
			-- if GameTooltip:IsOwned(self) then
				-- self:UpdateTooltip(self)
			-- else
				-- self.nextTooltipUpdate = nil
			-- end
		-- end
	-- end
end

function BActionButton:PostClick()
	self:UpdateState()
end

function BActionButton:OnDragStart()
	if not(BActionConfig.ButtonsLocked()) or bg_showGrid or BActionConfig.IsQuickMoveKeyDown() then
		PickupAction(self:GetPagedID())
		self:UpdateState()
	end
end

function BActionButton:OnReceiveDrag()
	PlaceAction(self:GetPagedID())
	self:UpdateState()
end

function BActionButton:OnEnter()
	self:UpdateTooltip()
	KeyBound_Set(self)
end

function BActionButton:OnLeave()
	self.nextTooltipUpdate = nil
	GameTooltip:Hide()
end


--[[ Update Functions ]]--

--Updates the icon, count, cooldown, usability color, if the button is flashing, if the button is equipped,  and macro text.
function BActionButton:Update(force)
	if force then self.id = nil end
	if not self:GetParent() then return end

	local name = self:GetName()
	local action = self:GetPagedID()
	local icon = getglobal(name .. 'Icon')
	local cooldown = getglobal(name .. 'Cooldown')
	local texture = GetActionTexture(action)

	if texture then
		icon:SetTexture(texture); icon:Show()
		self.rangeTimer = -1
		
		if BActionButton.HasNormalTexture then
			self:SetNormalTexture('Interface\\Buttons\\UI-Quickslot2')
		end
	else
		icon:Hide()
		self.rangeTimer = nil
		cooldown:Hide()
		
		if BActionButton.HasNormalTexture then
			self:SetNormalTexture('Interface\\Buttons\\UI-Quickslot')
		end
		getglobal(name .. 'HotKey'):SetVertexColor(0.6, 0.6, 0.6)
	end

	if HasAction(action) then
		self:UpdateState()
		self:UpdateUsable()
		self:UpdateCooldown()
		self:UpdateFlash()
	else
		cooldown:Hide()
	end
	self:UpdateCount()

	-- Add a green border if button is an equipped item
	local border = getglobal(name .. 'Border')
	if IsEquippedAction(action) then
		border:SetVertexColor(0, 1, 0, 0.6)
		border:Show()
	else
		border:Hide()
	end

	if GameTooltip:IsOwned(self) then
		self:UpdateTooltip()
	else
		self.nextTooltipUpdate = nil
	end

	-- Update Macro Text
	getglobal(name .. 'Name'):SetText(GetActionText(action))
end

--Update the cooldown timer
function BActionButton:UpdateCooldown()
	local start, duration, enable = GetActionCooldown(self:GetPagedID())
	CooldownFrame_SetTimer(getglobal(self:GetName().."Cooldown"), start, duration, enable)
end

--Update item count
function BActionButton:UpdateCount()
	local text = getglobal(self:GetName() .. 'Count')
	local action = self:GetPagedID()

	if IsConsumableAction(action) then
		text:SetText(GetActionCount(action))
	else
		text:SetText('')
	end
end

--Update if a button is checked or not
function BActionButton:UpdateState()
	local action = self:GetPagedID()
	self:SetChecked(IsCurrentAction(action) or IsAutoRepeatAction(action))
end

--colors the action button if out of mana, out of range, etc
function BActionButton:UpdateUsable()
	local action = self:GetPagedID()
	local icon = getglobal(self:GetName() .. "Icon")

	local isUsable, notEnoughMana = IsUsableAction(action)
	if isUsable then
		if BActionConfig.ColorOutOfRange() and IsActionInRange(action) == 0 then
			local r,g,b = BActionConfig.GetRangeColor()
			icon:SetVertexColor(r,g,b)
		else
			icon:SetVertexColor(1, 1, 1)
		end
	elseif notEnoughMana then
		--Make the icon blue if out of mana
		icon:SetVertexColor(0.5, 0.5, 1)
	else
		--Skill unusable
		icon:SetVertexColor(0.3, 0.3, 0.3)
	end
end

function BActionButton:UpdateFlash()
	local action = self:GetPagedID()
	if (IsAttackAction(action) and IsCurrentAction(action)) or IsAutoRepeatAction(action) then
		self:StartFlash()
	else
		self:StopFlash()
	end
end

function BActionButton:StartFlash()
	self.flashing = 1
	self.flashtime = 0
	self:UpdateState()
end

function BActionButton:StopFlash()
	self.flashing = 0
	getglobal(self:GetName() .. 'Flash'):Hide()
	
	self:UpdateState()
end

function BActionButton:UpdateSlot()
	local changed = self:UpdateVisibility(BActionButton.ShowingEmpty())
	if changed then
		SecureStateHeader_Refresh(self:GetParent())
	else
		self:Update()
	end
end

function BActionButton:UpdateTooltip()
	if BActionConfig.TooltipsShown() then
		if GetCVar("UberTooltips") == "1" then
			GameTooltip_SetDefaultAnchor(GameTooltip, self)
		else
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		end

		local action = self:GetPagedID()
		if GameTooltip:SetAction(action) then
			self.nextTooltipUpdate = TOOLTIP_UPDATE_TIME
		else
			self.nextTooltipUpdate = nil
		end
	end
end

--show if showing empty buttons, or if the slot has an action, hide otherwise
function BActionButton:UpdateVisibility(showEmpty)
	showEmpty = showEmpty or BActionButton.ShowingEmpty()

	local newstates
	local normAction = self:GetAttribute('action')
	local s,e = BState.GetStanceRange()
	local maxPage = BState.GetMaxPage()-1

	for i = s, e do
		for j = 0, maxPage do
			local state = i*10 + j
			local attribute = format('*action-s%d', state)
			if showEmpty or HasAction(self:GetAttribute(attribute) or normAction) then
				if not newstates then
					newstates = state
				else
					newstates = newstates .. ',' .. state
				end
			end
		end
	end
	newstates = newstates or '!*'	

	local oldstates = self:GetAttribute('showstates')
	if not oldstates or oldstates ~= newstates then
		self:SetAttribute('showstates', newstates)
		return true
	end
end


--[[ Stance Functions ]]--

function BActionButton:GetStanceID(stance)
	local parent = self:GetParent()
	if parent then
		local stateBar = parent:GetStanceBar(stance)
		if stateBar then
			local id = self:GetAttribute('action')
			local normID = id - parent:GetStartID()
			local stateID = normID + (stateBar-1) * MAX_BUTTONS / BActionBar.GetNumber() + 1

			return mod(stateID - 1, MAX_BUTTONS) + 1
		else
			return nil
		end
	end
	return nil
end

function BActionButton:UpdateStance(stance, noUpdate)
	local attribute = format('*action-s%d', stance * 10)
	self:SetAttribute(attribute, self:GetStanceID(stance))

	if not noUpdate then
		self:UpdateVisibility()
		self:Update(true) 
	end
end

function BActionButton:UpdateAllStances()
	local parent = self:GetParent()

	if parent then
		local s,e = BState.GetStanceRange()
		for i = s, e do
			self:UpdateStance(i, true)
		end

		self:UpdateVisibility()
		self:Update(true)
	end
end


--[[ Paging Functions ]]--

function BActionButton:UpdatePage(page, noUpdate)
	local parent = self:GetParent()
	local s,e = BState.GetStanceRange()

	if parent and parent:CanPage() then
		local pageID = mod(self:GetAttribute('action') + parent:GetPageOffset(page) - 1, MAX_BUTTONS) + 1
		for i = s, e do
			local attribute = format('*action-s%d', i*10 + page)
			self:SetAttribute(attribute, pageID)
		end
	else
		for i = s, e do
			local attribute = format('*action-s%d', i*10 + page)
			self:SetAttribute(attribute, self:GetStanceID(i))
		end
	end

	if not(noUpdate) and self:GetParent() then
		self:UpdateVisibility()
		self:Update(true) 
	end
end

function BActionButton:UpdateAllPages()
	for i = 1, BState.GetMaxPage() - 1 do
		self:UpdatePage(i, true)
	end

	self:UpdateVisibility()
	self:Update(true)
end


--[[ Hotkey Functions ]]--

function BActionButton:ShowHotkey(show)
	if show then
		getglobal(self:GetName() .. 'HotKey'):Show()
		self:UpdateHotkey()
	else
		getglobal(self:GetName() .. 'HotKey'):Hide()
	end
end

function BActionButton:UpdateHotkey()
	getglobal(self:GetName() .. 'HotKey'):SetText(self:GetHotkey() or '')
end

function BActionButton:GetHotkey()
	return BActionUtil.ToShortKey(GetBindingKey(format('CLICK %s:LeftButton', self:GetName())))
end


--[[ Macro Functions ]]--

function BActionButton:ShowMacro(show)
	if show then
		getglobal(self:GetName() .. 'Name'):Show()
	else
		getglobal(self:GetName() .. 'Name'):Hide()
	end
end


--[[ Meta Functions ]]--

-- does the given action to every single button currently in use
function BActionButton.ForAll(action, ...)
	for _,button in pairs(buttons) do
		if button:GetParent() then
			action(button, ...)
		end
	end
end

-- does the given action to every single button being shown
function BActionButton.ForAllShown(action, ...)
	for _,button in pairs(buttons) do
		if button:GetParent() and button:IsVisible() then
			action(button, ...)
		end
	end
end

--does the action to every single button being shown with an action
function BActionButton.ForAllWithAction(action, ...)
	for _,button in pairs(buttons) do
		if button:GetParent() and button:IsVisible() and HasAction(button:GetPagedID()) then
			action(button, ...)
		end
	end
end

--does the action to every single button matching the given id
function BActionButton.ForID(id, action, ...)
	for _,button in pairs(buttons) do
		if button:GetPagedID() == id then
			action(button, ...)
		end
	end
end


--[[ Utility Functions ]]--

function BActionButton:GetPagedID()
	if not self.id then
		if self:GetParent() then
			self.id = SecureButton_GetModifiedAttribute(self, 'action', SecureStateChild_GetEffectiveButton(self)) or 1
		else
			self.id = 1
		end
	end
	return self.id
end

function BActionButton.Get(id)
	return buttons[id]
end

function BActionButton.GetMax()
	return MAX_BUTTONS
end

function BActionButton.GetSize()
	return SIZE
end

function BActionButton.ShowingEmpty()
	return bg_showGrid or BActionConfig.ShowGrid()
end