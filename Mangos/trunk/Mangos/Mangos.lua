--[[
	Mangos
		Because sometimes I feel bad about doing to much
--]]

--libs and omgspeed
local _G = getfenv(0)
local ceil = math.ceil
local format = string.format
local KeyBound = LibStub('LibKeyBound-1.0')
local Sticky = LibStub('LibStickyFrames-2.0')
local LBF = LibStub('LibButtonFacade', true)
local RANGE_INDICATOR = ''


--[[ Class Creator ]]--

local function CreateObject(type)
	local w = setmetatable({}, {__index = CreateFrame(type)})
	w.mt = {__index = w}

	w.Bind = function(self, o)
		return setmetatable(o, self.mt)
	end

	return w
end


--[[ Action Button ]]--

local AB = CreateObject('CheckButton')

function AB:Get(id)
	return self:New(id)
end

do
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
		elseif id <= 120 then
			return CreateFrame('CheckButton', 'MangoActionButton' .. (id-60), nil, 'ActionBarButtonTemplate')
		end
	end

	function AB:New(id)
		local b = Create(id)
		if b then
			self:Bind(b)

			b:SetAttribute('action', id)
			b:SetID(0)
			b:ClearAllPoints()
			b:SetAttribute('useparent-statebutton', true)
			b:SetAttribute('useparent-actionbar', nil)
			b:SetScript('OnEnter', self.OnEnter)
			b:SetAttribute('showgrid', 1)
			ActionButton_ShowGrid(b)

			_G[b:GetName() .. 'Name']:Hide() --hide macro text
			_G[b:GetName() .. 'HotKey']:SetAlpha(0)

			if LBF then
				LBF:Group('Mangos'):AddButton(b)
			end
		end
		return b
	end
end

--keybound support
function AB:OnEnter()
	ActionButton_SetTooltip(self)
	KeyBound:Set(self)
end

function AB:GetHotkey()
	local key = GetBindingKey(format('CLICK %s:LeftButton', self:GetName()))
	return KeyBound:ToShortKey(key)
end

--utility
function AB:RCall(f, ...)
	local pThis = this
	this = self
	f(...)
	this = pThis
end


--[[ Action Bar ]]--

local ABFrame = CreateObject('Frame')

function ABFrame:New(id, length)
	if (id-1)*length + 1 <= 120 then
		--create frame
		local f = self:Bind(CreateFrame('Frame', 'MangoBar' .. id, UIParent))
		f:SetClampedToScreen(true)
		f:SetMovable(true)
		f.maxLength = length
		f.id = id

		--create the header
		f.header = CreateFrame('Frame', nil, f, 'SecureStateHeaderTemplate')
		f.header:SetAttribute('statemap-state', '$input')
		f.header:SetAllPoints(f)

		--add buttons
		f.buttons = {}
		for i = 1, length do
			local b = AB:Get((id-1)*length + i)
			if b then
				f.buttons[i] = b
				b:SetParent(f.header)
			else
				break
			end
		end

		--register with LSF
		Sticky:RegisterFrame(f)
		Sticky:SetFrameEnabled(f, true)
		Sticky:SetFrameText(f, 'bar: ' .. id)

		--register as an ab
		f:Register()

		return f
	end
end

function ABFrame:Layout(columns, spacing, padW, padH)
	local columns = columns or #self.buttons
	local rows = ceil(#self.buttons / columns)
	local padW = padW or 0
	local padH = padH or padW or 0
	local spacing = spacing or 0
	local w = self.buttons[1]:GetWidth() + spacing
	local h = self.buttons[1]:GetHeight() + spacing

	for i,button in pairs(self.buttons) do
		local col = (i - 1) % columns
		local row = ceil(i / columns) - 1
		button:SetPoint('TOPLEFT', w * col + padW, -(h * row + padH))
	end

	self:SetWidth(w * columns - spacing + padW*2)
	self:SetHeight(h * ceil(#self.buttons/columns) - spacing + padH*2)
end

--stateheader code
function ABFrame:UpdateStateDriver()
	UnregisterStateDriver(self.header, 'state', 0)

	local header = ''
	if self.states then
		for state,condition in ipairs(self.states) do
			header = header .. condition .. state .. ';'
		end
	end

	if self.possessBar then
		header = header .. '[bonusbar:5]999;'
	end

	self:UpdateStateButton()
	self:UpdateActions()

	if header ~= '' then
		RegisterStateDriver(self.header, 'state', header .. 0)
	end
end

function ABFrame:RegisterShowStates(states)
	UnregisterStateDriver(self.header, 'visibility', 'show')
	self.header:Show()
	RegisterStateDriver(self.header, 'visibility', states .. 'show;hide')
end

function ABFrame:UpdateStateButton()
	local sb1, sb2 = '', ''

	if self.states then
		for state in ipairs(self.states) do
			sb1 = sb1 .. (state .. ':S' .. state .. ';')
			sb2 = sb2 .. (state .. ':S' .. state .. 's;')
		end
	end

	if self.possessBar then
		sb1 = sb1 .. '999:possess;'
	end

	self.header:SetAttribute('statebutton', sb1)
	self.header:SetAttribute('*statebutton2', sb2)
end

function ABFrame:SetPossessBar(enable)
	self.possessBar = enable or nil
	self:UpdateStateDriver()
end

do
	local function Validate(id)
		return (id - 1) % 120 + 1
	end

	function ABFrame:UpdateActions()
		if self.states then
			for state in pairs(self.states) do
				local offset = #self.buttons * self.offsets[state]

				for _,b in pairs(self.buttons) do
					local id = Validate(b:GetAttribute('action') + offset)
					b:SetAttribute('*action-S' .. state, id)
					b:SetAttribute('*action-S' .. state .. 's', id)
				end
			end
		end

		if self.possessBar then
			for i = 1, min(#self.buttons, 12) do
				self.buttons[i]:SetAttribute('*action-possess', 120 + i)
			end
		end

		for _,b in pairs(self.buttons) do
			self.header:SetAttribute('addchild', b)
		end
	end
end

--utility
function ABFrame:Register()
	if not ABFrame.frames then ABFrame.frames = {} end
	ABFrame.frames[self] = true
end

function ABFrame:ForAll(method, ...)
	if self.frames then
		for f in pairs(self.frames) do
			f[method](f, ...)
		end
	end
end


--[[ Core ]]--

Mangos = CreateFrame('Frame')
Mangos.locked = true
Mangos.abStyle = {'Entropy: Copper', 0.5, true}
Mangos.abCount = 10

function Mangos:Load()
	local barLength = ceil(120 / self.abCount)
	for i = 1, self.abCount do
		local f = ABFrame:New(i, barLength)
		if f then
			f:SetPoint('BOTTOM', 0, (i-1)*37)
			f:Layout(nil, 2)
			self:Register(i, f)
		else
			break
		end
	end

	if LBF then
		LBF:Group('Mangos'):Skin(unpack(self.abStyle))
	end

	local b = self:Get(1)
	b.states = {
		'[bar:2]',
		'[bar:3]',
		'[bar:4]',
		'[bar:5]',
		'[bar:6]'
	}
	b.offsets = {1, 2, 3, 4, 5, 6}
	b:SetPossessBar(true)

	self:RegisterSlashCommands()
end

function Mangos:Lock()
	self.locked = true
	Sticky:SetGroup(nil)
end

function Mangos:Unlock()
	self.locked = nil
	Sticky:SetGroup(true)
end

function Mangos:RegisterSlashCommands()
	SlashCmdList['MangosCOMMAND'] = function()
		if self.locked then
			self:Unlock()
		else
			self:Lock()
		end
	end
	SLASH_MangosCOMMAND1 = '/mangos'
	SLASH_MangosCOMMAND2 = '/mg'
end

function Mangos:HideBlizzard()
	UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarRight'] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarLeft'] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarBottomLeft'] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarBottomRight'] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS['MainMenuBar'] = nil
	MultiActionBar_UpdateGrid = Multibar_EmptyFunc
	MainMenuBar:UnregisterAllEvents()
	MainMenuBar:Hide()
end

function Mangos:Register(id, bar)
	if not self.bars then self.bars = {} end
	self.bars[id] = bar
end

function Mangos:Get(id)
	return self.bars and self.bars[id]
end

--startup
Mangos:SetScript('OnEvent', Mangos.Load)
Mangos:RegisterEvent('PLAYER_LOGIN')
Mangos:HideBlizzard()