--[[
	Mangos
		Because sometimes I feel bad about doing to much
--]]

--libs and omgspeed
local _G = getfenv(0)
local ceil = math.ceil
local min = math.min
local format = string.format

local KeyBound = LibStub('LibKeyBound-1.0')
local LBF = LibStub('LibButtonFacade', true)


--[[ Action Button ]]--

local ActionButton = Mangos:CreateClass('CheckButton')
ActionButton.unused = {}
ActionButton.active = {}

--constructor
function ActionButton:New(id)
	local b = self:Restore(id) or self:Create(id)
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
	elseif id <= 72 then
		local b = _G['BonusActionButton' .. (id-60)]
		b.isBonus = nil
		return b
	elseif id <= 120 then
		return CreateFrame('CheckButton', 'MangoActionButton' .. (id-72), nil, 'ActionBarButtonTemplate')
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
		b:SetAttribute('showgrid', 0)

		_G[b:GetName() .. 'Name']:Hide() --hide macro text

		if LBF then
			LBF:Group('Mangos', 'Action Bars'):AddButton(b)
		end
	end
	return b
end

function ActionButton:Restore(id)
	local b = self.unused[id]
	if b then
		self.unused[id] = nil
		b:Show()
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
			pages['[bonusbar:3]'] = 9
			pages['[bonusbar:4]'] = 8
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
}

ActionBar.class = select(2, UnitClass('player'))

function ActionBar:New(id)
	local f = self.super.New(self, id, self:GetDefaults(id))
	if f.id == 1 then
		f.sets.pages = setmetatable(f.sets.pages or {}, self.mainbarOffsets)
	else
		f.sets.pages = setmetatable(f.sets.pages or {}, self.defaultOffsets)
	end

	f.pages = f.sets.pages[f.class]
	f.baseID = ceil(120 / Mangos:NumBars()) * (id-1)
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
--	defaults.hidden = id > 5
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
	return (id - 1) % 120 + 1
end

function ActionBar:UpdateAction(i)
	local b = self.buttons[i]
	local maxSize = ceil(Mangos:NumBars() / 120)

	for state,condition in ipairs(self.conditions) do
		local page = self:GetPage(condition)
		local id = page and ToValidID(b:GetAttribute('action') + (self.id + page - 1)*maxSize) or nil

		b:SetAttribute('*action-S' .. state, id)
		b:SetAttribute('*action-S' .. state .. 's', id)
	end

	if self:IsPossessBar() and i <= 12 then
		b:SetAttribute('*action-possess', 120 + i)
	else
		b:SetAttribute('*action-possess', nil)
	end

	self.header:SetAttribute('addchild', b)
end

function ActionBar:UpdateActions()
	local maxSize = ceil(120 / Mangos:NumBars())

	for state,condition in ipairs(self.conditions) do
		local page = self:GetPage(condition)
		for _,b in pairs(self.buttons) do
			local page = self:GetPage(condition)
			local id = page and ToValidID(b:GetAttribute('action') + (self.id + page - 1)*maxSize) or nil

			b:SetAttribute('*action-S' .. state, id)
			b:SetAttribute('*action-S' .. state .. 's', id)
		end
	end

	if self:IsPossessBar() then
		for i = 1, min(#self.buttons, 10) do
			self.buttons[i]:SetAttribute('*action-possess', 120 + i)
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