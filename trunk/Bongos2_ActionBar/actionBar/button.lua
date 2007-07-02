--[[
	BongosActionButton - A Bongos ActionButton
--]]

BongosActionButton = CreateFrame("CheckButton")
local Button_MT = {__index = BongosActionButton}
local _G = getfenv(0)
local format = format

--constants
local ATTACK_BUTTON_FLASH_TIME = 1
local TOOLTIP_UPDATE_TIME = 1
local MAX_BUTTONS = BONGOS_MAX_BUTTONS
local CLASS = BONGOS_CLASS
local MAX_PAGES = BONGOS_MAX_PAGES
local hasStance = (CLASS == "DRUID" or CLASS == "ROGUE" or CLASS == "WARRIOR" or CLASS == "PRIEST")

local BUTTON_NAME = "BongosActionButton%d"
local SIZE = 36

--globals
local buttons = {}; local shown = {}

--converts an ID into a valid action ID (between 1 and 120)
local function toValid(id) return mod(id - 1, 120) + 1 end

--[[ frame events ]]--

local function PostClick(self) self:PostClick() end
local function OnDragStart(self) self:OnDragStart() end
local function OnReceiveDrag(self) self:OnReceiveDrag() end
local function OnEnter(self) self:OnEnter() end
local function OnLeave(self) self:OnLeave() end

local function OnShow(self)
	if(self.needsUpdate) then
		self.needsUpdate = nil
		self:Update(true)
		-- self:UpdateUsable()
		shown[self] = (HasAction(self.id) or nil)
	end
end

local function OnHide(self)
	shown[self] = nil
end

local function OnAttributeChanged(self, var, val)
	if(var == "state-parent" or var == "statehidden") then
		if self:IsShown() then
			self:Update(true)
			-- self:UpdateUsable()
			shown[self] = (HasAction(self.id) or nil)
		else
			self.needsUpdate = true
		end
	end
end

local function OnEvent(self, event, arg1)
	if(event == "UPDATE_BINDINGS") then
		self:UpdateHotkey()
	end

	if(not self:GetParent():IsShown()) then return end

	if(event == "ACTIONBAR_SLOT_CHANGED") then
		if(arg1 == self:GetPagedID()) then
			self:Update()
			-- self:UpdateUsable()
		end
	end

	if not(self:IsShown() and HasAction(self:GetPagedID())) then return end

	if event == "PLAYER_ENTERING_WORLD" then
		self:Update()
		-- self:UpdateUsable()
	elseif event == "PLAYER_AURAS_CHANGED" or event == "PLAYER_TARGET_CHANGED" then
		self:UpdateUsable()
	elseif event == "UNIT_INVENTORY_CHANGED" then
		if(arg1 == "player") then
			self:Update()
			-- self:UpdateUsable()
		end
	elseif event == "ACTIONBAR_UPDATE_USABLE" or event == "UPDATE_INVENTORY_ALERTS" or event == "ACTIONBAR_UPDATE_COOLDOWN" then
		self:UpdateCooldown()
		self:UpdateUsable()
	elseif event == "ACTIONBAR_UPDATE_STATE" or event == "CRAFT_SHOW" or event == "CRAFT_CLOSE" or event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_CLOSE" then
		self:UpdateState()
	elseif event == "PLAYER_ENTER_COMBAT" or event == "PLAYER_LEAVE_COMBAT" or event == "START_AUTOREPEAT_SPELL" or event == "STOP_AUTOREPEAT_SPELL" then
		self:UpdateFlash()
	end
end


--[[ Constructorish ]]--

-- function BongosActionButton:GetBlizzButton(id)
	-- local button
	-- if(id <= 12) then
		-- button = _G[format("ActionButton%d", id)]
	-- elseif id <= 24 then
		-- button = _G[format("MultiBarBottomLeftButton%d", id-12)]
	-- elseif id <= 36 then
		-- button = _G[format("MultiBarBottomRightButton%d", id-24)]
	-- elseif id <= 48 then
		-- button = _G[format("MultiBarRightButton%d", id-36)]
	-- elseif id <= 60 then
		-- button = _G[format("MultiBarLeftButton%d", id-48)]
	-- end

	-- if(button) then
		-- _G[format(BUTTON_NAME, id)] = button
		-- button:UnregisterAllEvents()
		-- button:SetScript("OnUpdate", nil)
	-- end
	-- return button
-- end


--Create an Action Button with the given ID and parent
function BongosActionButton:Create(id)
	local button = CreateFrame("CheckButton", format(BUTTON_NAME, id), nil, "SecureActionButtonTemplate, ActionButtonTemplate")
	button.name = format(BUTTON_NAME, id)
	setmetatable(button, Button_MT)

	local name = button:GetName()
	button.icon = _G[name .. "Icon"]
	button.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)

	button.border = _G[name .. "Border"]
	button.border:SetVertexColor(0, 1, 0, 0.6)

	button.normal = _G[name .. "NormalTexture"]
	button.normal:SetVertexColor(1, 1, 1, 0.5)

	button.cooldown = _G[name .. "Cooldown"]
	button.flash = _G[name .. "Flash"]
	button.hotkey = _G[name .. "HotKey"]
	button.macro = _G[name .. "Name"]
	button.count = _G[name .. "Count"]

	button:SetScript("OnAttributeChanged", OnAttributeChanged)
	button:SetScript("PostClick", PostClick)
	button:SetScript("OnDragStart", OnDragStart)
	button:SetScript("OnReceiveDrag", OnReceiveDrag)
	button:SetScript("OnEnter", OnEnter)
	button:SetScript("OnLeave", OnLeave)
	button:SetScript("OnEvent", OnEvent)

	button:SetScript("OnShow", OnShow)
	button:SetScript("OnHide", OnHide)

	button:SetAttribute("type", "action")
	button:SetAttribute("action", id)
	button:SetAttribute("checkselfcast", true)
	button:SetAttribute("useparent-unit", true)
	button:SetAttribute("useparent-statebutton", true)

	button:RegisterForDrag("LeftButton", "RightButton")
	button:RegisterForClicks("AnyUp")

	buttons[id] = button
	shown[button] = true
	return button
end

--attatch the button to a bar,  make active
function BongosActionButton:Set(id, parent)
	local button = buttons[id] or self:Create(id)
	parent:Attach(button)
	parent:SetAttribute("addchild", button)

	button:ShowHotkey(BongosActionConfig:ShowingHotkeys())
	button:ShowMacro(BongosActionConfig:ShowingMacros())
	button:RegisterEvents()
	button:UpdateStates()

	return button
end

--load events
function BongosActionButton:RegisterEvents()
	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	self:RegisterEvent("UPDATE_BINDINGS")

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_AURAS_CHANGED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
	self:RegisterEvent("UPDATE_INVENTORY_ALERTS")
	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")

	self:RegisterEvent("ACTIONBAR_UPDATE_STATE")
	self:RegisterEvent("CRAFT_SHOW")
	self:RegisterEvent("CRAFT_CLOSE")
	self:RegisterEvent("TRADE_SKILL_SHOW")
	self:RegisterEvent("TRADE_SKILL_CLOSE")

	self:RegisterEvent("PLAYER_ENTER_COMBAT")
	self:RegisterEvent("PLAYER_LEAVE_COMBAT")
	self:RegisterEvent("START_AUTOREPEAT_SPELL")
	self:RegisterEvent("STOP_AUTOREPEAT_SPELL")
end

--hide the button
function BongosActionButton:Release()
	self:SetParent(nil)
	self:ClearAllPoints()
	self:UnregisterAllEvents()
	self:Hide()
	self.id = nil
end


--[[ OnX Functions ]]--

local IsActionInRange = IsActionInRange
local IsUsableAction = IsUsableAction

function BongosActionButton:OnUpdate(elapsed)
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
		if self.rangeTimer < 0 then
			local action = self:GetPagedID()
			local hotkey = self.hotkey
			if IsActionInRange(action) == 0 then
				hotkey:SetVertexColor(1, 0.1, 0.1)
				if BongosActionConfig:RangeColoring() and IsUsableAction(action) then
					local r,g,b = BongosActionConfig:GetRangeColor()
					self.icon:SetVertexColor(r,g,b)
				end
			else
				hotkey:SetVertexColor(0.6, 0.6, 0.6)
				if IsUsableAction(action) then
					self.icon:SetVertexColor(1, 1, 1)
				end
			end
			self.rangeTimer = TOOLTIP_UPDATE_TIME
		else
			self.rangeTimer = self.rangeTimer - elapsed
		end
	end

	-- Tooltip stuff, probably for the cooldown timer
	if self.nextTooltipUpdate then
		self.nextTooltipUpdate = self.nextTooltipUpdate - elapsed
		if self.nextTooltipUpdate <= 0 then
			if GameTooltip:IsOwned(self) then
				self:UpdateTooltip(self)
			else
				self.nextTooltipUpdate = nil
			end
		end
	end
end

function BongosActionButton:PostClick()
	self:UpdateState()
end

function BongosActionButton:OnDragStart()
	if not(BongosActionConfig:ButtonsLocked()) or self.showEmpty or BongosActionConfig:IsQuickMoveKeyDown() then
		PickupAction(self:GetPagedID())
		self:UpdateState()
	end
end

function BongosActionButton:OnReceiveDrag()
	PlaceAction(self:GetPagedID())
	self:UpdateState()
end

function BongosActionButton:OnEnter()
	self:UpdateTooltip()
	KeyBound:Set(self)
end

function BongosActionButton:OnLeave()
	self.nextTooltipUpdate = nil
	GameTooltip:Hide()
end


--[[ Update Code ]]--

--Updates the icon, count, cooldown, usability color, if the button is flashing, if the button is equipped,  and macro text.
function BongosActionButton:Update(refresh)
	local action = self:GetPagedID(refresh)
	local icon = self.icon
	local cooldown = self.cooldown
	local texture = GetActionTexture(action)

	if texture then
		shown[self] = true
		self.rangeTimer = (ActionHasRange(action) and -1) or nil
		icon:SetTexture(texture)
		icon:Show()

		self:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
	else
		shown[self] = nil
		self.rangeTimer = nil
		icon:Hide()

		self:SetNormalTexture("Interface\\Buttons\\UI-Quickslot")
		self.hotkey:SetVertexColor(0.6, 0.6, 0.6)
	end

	if HasAction(action) then
		self:UpdateState()
		self:UpdateUsable()
		self:UpdateCooldown()
		self:UpdateFlash()
		self:SetAlpha(1)
	else
		if self:ShowingEmpty() then 
			self:SetAlpha(1)
		else 
			self:SetAlpha(0)
		end
		cooldown:Hide()
	end
	self:UpdateCount()

	-- Add a green border if button is an equipped item
	local border = self.border
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
	self.macro:SetText(GetActionText(action))
end

--Update the cooldown timer
function BongosActionButton:UpdateCooldown()
	local start, duration, enable = GetActionCooldown(self:GetPagedID())
	CooldownFrame_SetTimer(self.cooldown, start, duration, enable)
end

--Update item count
function BongosActionButton:UpdateCount()
	local action = self:GetPagedID()
	self.count:SetText((IsConsumableAction(action) and GetActionCount(action)) or "")
end

--Update if a button is checked or not
function BongosActionButton:UpdateState()
	local action = self:GetPagedID()
	self:SetChecked(IsCurrentAction(action) or IsAutoRepeatAction(action))
end

--colors the action button if out of mana, out of range, etc
function BongosActionButton:UpdateUsable()
	local action = self:GetPagedID()
	local icon = self.icon

	local isUsable, notEnoughMana = IsUsableAction(action)
	if isUsable then
		if self.rangeTimer and BongosActionConfig:RangeColoring() and IsActionInRange(action) == 0 then
			local r,g,b = BongosActionConfig:GetRangeColor()
			icon:SetVertexColor(r,g,b)
		else
			icon:SetVertexColor(1, 1, 1)
		end
	else
		if notEnoughMana then
			--Make the icon blue if out of mana
			icon:SetVertexColor(0.5, 0.5, 1)
		else
			--Skill unusable
			icon:SetVertexColor(0.3, 0.3, 0.3)
		end
	end
end

function BongosActionButton:UpdateFlash()
	local action = self:GetPagedID()
	if (IsAttackAction(action) and IsCurrentAction(action)) or IsAutoRepeatAction(action) then
		self:StartFlash()
	else
		self:StopFlash()
	end
end

function BongosActionButton:StartFlash()
	self.flashing = true
	self.flashtime = 0
	self:UpdateState()
end

function BongosActionButton:StopFlash()
	self.flashing = nil
	self.flash:Hide()
	self:UpdateState()
end

function BongosActionButton:UpdateTooltip()
	if BongosActionConfig:ShowingTooltips() then
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


--[[ State Updating ]]--

--load up the action ID when in forms/paged from the parent action bar
function BongosActionButton:UpdateStates()
	local id = self:GetAttribute("action")
	local parent = self:GetParent()

	if(hasStance) then
		local maxState = (CLASS == "PRIEST" and 1) or GetNumShapeshiftForms()

		for i = 1, maxState do
			local state = format("s%d", i)
			local selfState = format("s%ds", i)
			local offset = parent:GetStateOffset(state)

			if(offset) then
				self:SetAttribute("*action-" .. state, toValid(id + offset))
				self:SetAttribute("*action-" .. selfState, toValid(id + offset))
			else
				self:SetAttribute("*action-" .. state, nil)
				self:SetAttribute("*action-" .. selfState, nil)
			end
		end

		if(CLASS == "DRUID") then
			local state = format("s%d", 7)
			local selfState = format("s%ds", 7)
			local offset = parent:GetStateOffset(state)

			if(offset) then
				self:SetAttribute("*action-" .. state, toValid(id + offset))
				self:SetAttribute("*action-" .. selfState, toValid(id + offset))
			else
				self:SetAttribute("*action-" .. state, nil)
				self:SetAttribute("*action-" .. selfState, nil)
			end
		end
	end

	for i = 1, MAX_PAGES do
		local state = format("p%d", i)
		local selfState = format("p%ds", i)
		local offset = parent:GetStateOffset(state)

		if(offset) then
			self:SetAttribute("*action-" .. state, toValid(id + offset))
			self:SetAttribute("*action-" .. selfState, toValid(id + offset))
		else
			self:SetAttribute("*action-" .. state, nil)
			self:SetAttribute("*action-" .. selfState, nil)
		end
	end

	for i = 1, 3 do
		local state = format("m%d", i)
		local selfState = format("m%ds", i)
		local offset = parent:GetStateOffset(state)

		if(offset) then
			self:SetAttribute("*action-" .. state, toValid(id + offset))
			self:SetAttribute("*action-" .. selfState, toValid(id + offset))
		else
			self:SetAttribute("*action-" .. state, nil)
			self:SetAttribute("*action-" .. selfState, nil)
		end
	end

	local offset = parent:GetStateOffset("help")
	if(offset) then
		self:SetAttribute("*action-help", toValid(id + offset))
		self:SetAttribute("*action-helps", toValid(id + offset))
	else
		self:SetAttribute("*action-help", nil)
		self:SetAttribute("*action-helps", nil)
	end

	-- self:UpdateVisibility(true)
	self:Update()
	self.needsUpdate = true
end


--[[ Hotkey Functions ]]--

function BongosActionButton:ShowHotkey(enable)
	local hotkey = self.hotkey
	if enable then
		hotkey:Show()
		self:UpdateHotkey()
	else
		hotkey:Hide()
	end
end

function BongosActionButton:UpdateHotkey()
	self.hotkey:SetText(self:GetHotkey() or "")
end

function BongosActionButton:GetHotkey()
	local key = GetBindingKey(format("CLICK %s:LeftButton", self.name))
	if key then
		return KeyBound:ToShortKey(key)
	end
end


--[[ Macro Functions ]]--

function BongosActionButton:ShowMacro(enable)
	local macro = self.macro
	if enable then
		macro:Show()
	else
		macro:Hide()
	end
end


--[[ Utility Functions ]]--

function BongosActionButton:GetPagedID(refresh)
	if refresh or not self.id then
		self.id = SecureButton_GetModifiedAttribute(self, "action", SecureStateChild_GetEffectiveButton(self))
	end
	return self.id
end

function BongosActionButton:ForAll(method, ...)
	for _, button in pairs(buttons) do
		local action = button[method]
		action(button, ...)
	end
end

function BongosActionButton:ShowingEmpty()
	return self.showEmpty or BongosActionConfig:ShowingEmptyButtons() or KeyBound:IsShown()
end

function BongosActionButton:Get(id)
	return buttons[id]
end

--range and tooltip updating
local UPDATE_DELAY = 0.2
BongosActionButton.nextUpdate = UPDATE_DELAY
BongosActionButton:SetScript("OnUpdate", function(self, elapsed)
	if(self.nextUpdate <= 0) then
		self.nextUpdate = UPDATE_DELAY
		for button in pairs(shown) do
			button:OnUpdate(UPDATE_DELAY)
		end
	else
		self.nextUpdate = self.nextUpdate - elapsed
	end
end)