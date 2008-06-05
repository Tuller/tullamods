--[[
	Mangos
		Because sometimes I feel bad about doing to much
--]]

--libs and omgspeed
local _G = getfenv(0)
local ceil = math.ceil
local min = math.min
local format = string.format
local MAX_BUTTONS = 120
local KeyBound = LibStub('LibKeyBound-1.0')
local LBF = LibStub('LibButtonFacade', true)
local L = LibStub('AceLocale-3.0'):GetLocale('Mangos')


--[[ Action Button ]]--

local ActionButton = Mangos:CreateClass('CheckButton')
ActionButton.unused = {}
ActionButton.active = {}

--constructor
function ActionButton:New(id)
	local b = self:Restore(id) or self:Create(id)
	b:SetAttribute('showgrid', 0)
	b:UpdateGrid()
	self.active[id] = b

	return b
end

local function Create(id)
	if id <= 12 then
		return _G['ActionButton' .. id]
	elseif id <= 24 then
		return _G['MultiBarBottomLeftButton' .. (id-12)]
	elseif id <= 36 then
		return _G['MultiBarBottomRightButton' .. (id-24)]
	elseif id <= 48 then
		return _G['MultiBarRightButton' .. (id-36)]
	elseif id <= 60 then
		return _G['MultiBarLeftButton' .. (id-48)]
	elseif id <= MAX_BUTTONS then
		return CreateFrame('CheckButton', 'MangoActionButton' .. (id-60), nil, 'ActionBarButtonTemplate')
	end
end

function ActionButton:Create(id)
	local b = Create(id)
	if b then
		self:Bind(b)

		b:SetAttribute('action', id)
		b:SetID(0)
		b:ClearAllPoints()
		b:SetAttribute('useparent-statebutton', true)
		b:SetAttribute('useparent-actionbar', nil)
		b:SetScript('OnEnter', self.OnEnter)

		_G[b:GetName() .. 'Name']:Hide() --hide macro text

		if LBF then
			LBF:Group('Mangos', ACTIONBAR_LABEL):AddButton(b)
		end
	end
	return b
end

function ActionButton:Restore(id)
	local b = self.unused[id]
	if b then
		self.unused[id] = nil
		b:LoadEvents()
		self.active[id] = b
		return b
	end
end

--destructor
function ActionButton:Free()
	local id = self:GetAttribute('action')

	self.active[id] = nil

	self:UnregisterAllEvents()
	self:SetParent(nil)
	self:Hide()

	self.unused[id] = self
end

function ActionButton:LoadEvents()
	self:RegisterEvent('PLAYER_ENTERING_WORLD')
	self:RegisterEvent('ACTIONBAR_SHOWGRID')
	self:RegisterEvent('ACTIONBAR_HIDEGRID')
	self:RegisterEvent('ACTIONBAR_PAGE_CHANGED')
	self:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
	self:RegisterEvent('UPDATE_BINDINGS')
end

--keybound support
function ActionButton:OnEnter()
	ActionButton_SetTooltip(self)
	KeyBound:Set(self)
end

function ActionButton:GetHotkey()
	return KeyBound:ToShortKey(GetBindingKey(format('CLICK %s:LeftButton', self:GetName())))
end

function ActionButton:UpdateGrid()
	if self:GetAttribute('showgrid') > 0 then
		self:RCall(ActionButton_ShowGrid)
	else
		self:RCall(ActionButton_HideGrid)
	end
end

--you can hopefully guess what the 'R' stands for
function ActionButton:RCall(f, ...)
	local pThis = this
	this = self
	f(...)
	this = pThis
end


--[[ Action Bar ]]--

local ActionBar = Mangos:CreateClass('Frame', Mangos.Frame)
Mangos.ActionBar = ActionBar


--[[ Constructor Code ]]--

ActionBar.defaultOffsets = {
	__index = function(t, i)
		t[i] = {};
		return t[i]
	end
}

ActionBar.mainbarOffsets = {
	__index = function(t, k)
		local pages = {
			['[bar:2]'] = 1,
			['[bar:3]'] = 2,
			['[bar:4]'] = 3,
			['[bar:5]'] = 4,
			['[bar:6]'] = 5,
		}

		if k == 'DRUID' then
			pages['[bonusbar:1,stealth]'] = 5
			pages['[bonusbar:1]'] = 6
			pages['[bonusbar:2]'] = 7
			pages['[bonusbar:3]'] = 8
			pages['[bonusbar:4]'] = 9
		elseif k == 'WARRIOR' then
			pages['[bonusbar:1]'] = 6
			pages['[bonusbar:2]'] = 7
			pages['[bonusbar:3]'] = 8
		elseif k == 'PRIEST' or k == 'ROGUE' then
			pages['[bonusbar:1]'] = 6
		end

		t[k] = pages
		return pages
	end
}

ActionBar.conditions = {
	'[mod:SELFCAST]',
	'[mod:ctrl]',
	'[mod:alt]',
	'[mod:shift]',
	'[bar:2]',
	'[bar:3]',
	'[bar:4]',
	'[bar:5]',
	'[bar:6]',
	'[bonusbar:1,stealth]',
	'[bonusbar:1]',
	'[bonusbar:2]',
	'[bonusbar:3]',
	'[bonusbar:4]',
	'[help]',
	'[harm]',
	'[none]'
}

ActionBar.class = select(2, UnitClass('player'))

function ActionBar:New(id)
	local f = self.super.New(self, id, self:GetDefaults(id))
	f.sets.pages = setmetatable(f.sets.pages, f.id == 1 and self.mainbarOffsets or self.defaultOffsets)

	f.pages = f.sets.pages[f.class]
	f.baseID = ceil(MAX_BUTTONS / Mangos:NumBars()) * (id-1)
	f.header:SetAttribute('statemap-state', '$input')

	f:LoadButtons()
	f:UpdateStateDriver()
	f:Layout()

	return f
end

function ActionBar:GetDefaults(id)
	local defaults = {}
	defaults.point = 'BOTTOM'
	defaults.x = 0
	defaults.y = 37*(id-1)
	defaults.pages = {}
	defaults.numButtons = 12

	return defaults
end


--[[ button stuff]]--

function ActionBar:LoadButtons()
	for i = 1, self:NumButtons() do
		local b = ActionButton:New(self.baseID + i)
		b:SetParent(self.header)
		self.buttons[i] = b
	end
	self:UpdateActions()
end

function ActionBar:AddButton(i)
	local b = ActionButton:New(self.baseID + i)
	self.buttons[i] = b

	b:SetParent(self.header)
	self:UpdateAction(i)
end

function ActionBar:RemoveButton(i)
	local b = self.buttons[i]
	self.buttons[i] = nil
	b:Free()
end


--[[ Paging Code ]]--

function ActionBar:SetPage(condition, page)
	self.pages[condition] = page
	self:UpdateStateDriver()
end

function ActionBar:GetPage(condition)
	return self.pages[condition]
end

function ActionBar:UpdateStateDriver()
	UnregisterStateDriver(self.header, 'state', 0)

	local header, sb1, sb2 = '', '', ''
	for state,condition in ipairs(self.conditions) do
		if self:GetPage(condition) then
			header = header .. condition .. state .. ';'
			sb1 = sb1 .. (state .. ':S' .. state .. ';')
			sb2 = sb2 .. (state .. ':S' .. state .. 's;')
		end
	end

	if self:IsPossessBar() then
		header = header .. '[bonusbar:5]999;'
		sb1 = sb1 .. '999:possess;'
	end

	self.header:SetAttribute('statebutton', sb1)
	self.header:SetAttribute('*statebutton2', sb2)

	if header ~= '' then
		RegisterStateDriver(self.header, 'state', header .. 0)
	end

	self:UpdateActions()
end

local function ToValidID(id)
	return (id - 1) % MAX_BUTTONS + 1
end

function ActionBar:UpdateAction(i)
	local b = self.buttons[i]
	local maxSize = ceil(Mangos:NumBars() / MAX_BUTTONS)

	for state,condition in ipairs(self.conditions) do
		local page = self:GetPage(condition)
		local id = page and ToValidID(b:GetAttribute('action') + (self.id + page - 1)*maxSize) or nil

		b:SetAttribute('*action-S' .. state, id)
		b:SetAttribute('*action-S' .. state .. 's', id)
	end

	if self:IsPossessBar() and i <= 12 then
		b:SetAttribute('*action-possess', MAX_BUTTONS + i)
	else
		b:SetAttribute('*action-possess', nil)
	end

	self.header:SetAttribute('addchild', b)
end

function ActionBar:UpdateActions()
	local maxSize = ceil(MAX_BUTTONS / Mangos:NumBars())

	for state,condition in ipairs(self.conditions) do
		local page = self:GetPage(condition)
		for i,b in pairs(self.buttons) do
			local page = self:GetPage(condition)
			local id = page and ToValidID(i + (self.id + page - 1)*maxSize) or nil

			b:SetAttribute('*action-S' .. state, id)
			b:SetAttribute('*action-S' .. state .. 's', id)
		end
	end

	if self:IsPossessBar() then
		for i = 1, min(#self.buttons, 10) do
			self.buttons[i]:SetAttribute('*action-possess', MAX_BUTTONS + i)
		end
		for i = 11, #self.buttons do
			self.buttons[i]:SetAttribute('*action-possess', nil)
		end
	else
		for _,b in pairs(self.buttons) do
			b:SetAttribute('*action-possess', nil)
		end
	end

	for _,b in pairs(self.buttons) do
		self.header:SetAttribute('addchild', b)
	end
end

function ActionBar:IsPossessBar()
	return self == Mangos:GetPossessBar()
end


--[[ Grid ]]--

function ActionBar:ShowGrid()
	for _,b in pairs(self.buttons) do
		b:SetAttribute('showgrid', b:GetAttribute('showgrid') + 1)
		b:UpdateGrid()
	end
end

function ActionBar:HideGrid()
	for _,b in pairs(self.buttons) do
		b:SetAttribute('showgrid', b:GetAttribute('showgrid') - 1)
		b:UpdateGrid()
	end
end

function ActionBar:KEYBOUND_ENABLED()
	self:ShowGrid()
end

function ActionBar:KEYBOUND_DISABLED()
	self:HideGrid()
end

do
	--state slider template
	local function ConditionSlider_OnShow(self)
		self:SetMinMaxValues(-1, Mangos:NumBars() - 1)
		self:SetValue(self:GetParent().owner:GetPage(self.condition) or -1)
	end

	local function ConditionSlider_UpdateValue(self, value)
		self:GetParent().owner:SetPage(self.condition, (value > -1 and value) or nil)
	end

	local function ConditionSlider_UpdateText(self, value)
		if value > -1 then
			local page = (self:GetParent().owner.id + value) % Mangos:NumBars()
			self.valText:SetFormattedText(L.Bar, page)
		else
			self.valText:SetText(DISABLE)
		end
	end

	local function ConditionSlider_New(panel, condition, text)
		local s = panel:NewSlider(condition, 0, 1, 1)
		s.OnShow = ConditionSlider_OnShow
		s.UpdateValue = ConditionSlider_UpdateValue
		s.UpdateText = ConditionSlider_UpdateText
		s.condition = condition
		s:SetWidth(s:GetWidth() + 28)

		local title = _G[s:GetName() .. 'Text']
		title:ClearAllPoints()
		title:SetPoint('BOTTOMLEFT', s, 'TOPLEFT')
		title:SetJustifyH('LEFT')
		title:SetText(text or condition)

		local value = s.valText
		value:ClearAllPoints()
		value:SetPoint('BOTTOMRIGHT', s, 'TOPRIGHT')
		value:SetJustifyH('RIGHT')

		return s
	end

	local function AddLayout(self)
		local p = self:AddLayoutPanel()
	end

	local function AddClass(self)
		local lClass, class = UnitClass('player')
		if class == 'WARRIOR' or class == 'DRUID' or class == 'PRIEST' or class == 'ROGUE' then
			local p = self:NewPanel(lClass)
			if class == 'WARRIOR' then
				ConditionSlider_New(p, '[bonusbar:3]', GetSpellInfo(2458))
				ConditionSlider_New(p, '[bonusbar:2]', GetSpellInfo(71))
				ConditionSlider_New(p, '[bonusbar:1]', GetSpellInfo(2457))
			elseif class == 'DRUID' then
				ConditionSlider_New(p, '[bonusbar:4]', GetSpellInfo(24858))
				ConditionSlider_New(p, '[bonusbar:3]', GetSpellInfo(5487))
				ConditionSlider_New(p, '[bonusbar:2]', GetSpellInfo(33891))
				ConditionSlider_New(p, '[bonusbar:1,stealth]', GetSpellInfo(5215))
				ConditionSlider_New(p, '[bonusbar:1]', GetSpellInfo(768))
			elseif class == 'PRIEST' then
				ConditionSlider_New(p, '[bonusbar:1]', GetSpellInfo(15473))
			elseif class == 'ROGUE' then
				ConditionSlider_New(p, '[bonusbar:1]', GetSpellInfo(1784))
			end
		end
	end

	local function AddPaging(self)
		local p = self:NewPanel(L.QuickPaging)
		for i = 6, 2, -1 do
			ConditionSlider_New(p, format('[bar:%d]', i), getglobal('BINDING_NAME_ACTIONPAGE' .. i))
		end
	end

	local function AddModifier(self)
		local p = self:NewPanel(L.Modifiers)
		ConditionSlider_New(p, '[mod:SELFCAST]', AUTO_SELF_CAST_KEY_TEXT)
		ConditionSlider_New(p, '[mod:shift]', SHIFT_KEY)
		ConditionSlider_New(p, '[mod:alt]', ALT_KEY)
		ConditionSlider_New(p, '[mod:ctrl]', CTRL_KEY)
	end

	local function AddTargeting(self)
		local p = self:NewPanel(L.Targeting)
		ConditionSlider_New(p, '[none]', NONE)
		ConditionSlider_New(p, '[harm]', L.Harm)
		ConditionSlider_New(p, '[help]', L.Help)
	end

	local function AddShowState(self)
		local p = self:NewPanel(L.ShowStates)
		p.height = 56

		local editBox = CreateFrame('EditBox', p:GetName() .. 'StateText', p,  'InputBoxTemplate')
		editBox:SetWidth(148); editBox:SetHeight(20)
		editBox:SetPoint('TOPLEFT', 12, -10)
		editBox:SetAutoFocus(false)
		editBox:SetScript('OnShow', function(self)
			self:SetText(self:GetParent().owner:GetShowStates() or '')
		end)
		editBox:SetScript('OnEnterPressed', function(self)
			local text = self:GetText()
			self:GetParent().owner:SetShowStates(text ~= '' and text or nil)
		end)
		editBox:SetScript('OnEditFocusLost', function(self) self:HighlightText(0, 0) end)
		editBox:SetScript('OnEditFocusGained', function(self) self:HighlightText() end)

		local set = CreateFrame('Button', p:GetName() .. 'Set', p, 'UIPanelButtonTemplate')
		set:SetWidth(30); set:SetHeight(20)
		set:SetText(L.Set)
		set:SetScript('OnClick', function(self)
			local text = editBox:GetText()
			self:GetParent().owner:SetShowStates(text ~= '' and text or nil)
		end)
		set:SetPoint('BOTTOMRIGHT', -8, 2)

		return p
	end

	function ActionBar:CreateMenu()
		local menu = Mangos.Menu:New(self.id)
		AddLayout(menu)
		AddClass(menu)
		AddPaging(menu)
		AddModifier(menu)
		AddTargeting(menu)
		AddShowState(menu)

		ActionBar.menu = menu
	end
end