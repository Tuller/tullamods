--[[
	Mangos
		Because sometimes I feel bad about doing to much
--]]

local _G = getfenv(0)
local KeyBound = LibStub('LibKeyBound-1.0')
local Sticky = LibStub('LibStickyFrames-2.0')
local LBF = LibStub('LibButtonFacade', true)


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
	return self:Restore(id) or self:New(id)
end

local function Create(id)
	if id <= 12 then
		return _G['ActionButton' .. id]
	elseif id <= 24 then
		return _G['MultiBarBottomRightButton' .. (id-12)]
	elseif id <= 36 then
		return _G['MultiBarBottomLeftButton' .. (id-24)]
	elseif id <= 48 then
		return _G['MultiBarLeftButton' .. (id-36)]
	elseif id <= 60 then
		return _G['MultiBarRightButton' .. (id-48)]
	elseif id <= 120
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
		b:SetAttribute('showgrid', 2)
		b:Show()

		_G[b:GetName() .. 'Name']:Hide() --hide macro text

		if LBF then
			LBF:Group('Mangos'):AddButton(b)
		end
	end
	return b
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

--[[
function AB:Free()
	self:UnregisterAllEvents()
	self:SetParent(nil)
	self:Hide()

	if not AB.Unused then AB.Unused = {} end
	AB.Unused[self.baseID] = self
end

function AB:Restore(id)
	if self.Unused then
		local b = AB.Unused[id]
		if b then
			b:Load()
			AB.Unused[id] = nil
		end
		return b
	end
end
--]]

function AB:RCall(f, ...)
	local pThis = this
	this = self
	f(...)
	this = pThis
end


--[[ Action Bar ]]--

local ABFrame = CreateObject('Frame')

function ABFrame:New(id, numButtons)
	local f = self:Bind(CreateFrame('Frame', 'MangoBar' .. id, UIParent, 'SecureStateHeaderTemplate'))
	f:SetAttribute('statemap-state', '$input')
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:Register()

	f.buttons = {}
	for i = 1, numButtons do
		local b = AB:Get()
		f.buttons[i] 
	for _,b in pairs(buttons) do
		b:SetParent(f)
		f:SetAttribute('addchild', b)
	end
	f.buttons = buttons

	Sticky:RegisterFrame(f)
	Sticky:SetFrameEnabled(f, true)
	Sticky:SetFrameText(f, id)
	Sticky:SetFrameGroup(f, 'Mangos')

	return f
end

function ABFrame:Free()
	for i,button in self.buttons do
		button:Free()
		self.buttons[i] =  nil
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

	for i,button in ipairs(self.buttons) do
		local col = (i - 1) % columns
		local row = ceil(i / columns) - 1
		button:SetPoint('TOPLEFT', w * col + padW, -(h * row + padH))
	end

	self:SetWidth(w * columns - spacing + padW*2)
	self:SetHeight(h * ceil(#self.buttons/columns) - spacing + padH*2)
end

function ABFrame:ForAll(method, ...)
	if self.frames then
		for f in pairs(self.frames) do
			f[method](f, ...)
		end
	end
end

function ABFrame:Register()
	if not ABFrame.frames then ABFrame.frames = {} end
	ABFrame.frames[self] = true
end


--[[ States ]]--

--needs to be called whenever we change a state condition
--or when we change the number of available states
function ABFrame:UpdateStateDriver()
	UnregisterStateDriver(self, 'state', 0)

	local header = ''
	if self.states then
		for i,condition in ipairs(self.states) do
			header = header .. condition .. i .. ';'
		end
	end

	self:UpdateStateButton()
	self:UpdateActions()

	if header ~= '' then
		RegisterStateDriver(self, 'state', header .. 0)
	end
end

--todo: cleanup code
function ABFrame:UpdateStateButton()
	if self.states then
		local sb1 = ''
		for i in ipairs(self.states) do
			sb1 = sb1 .. (i .. ':S' .. i .. ';')
		end
		self:SetAttribute('statebutton', sb1 .. 0 .. ':nil')
	end
end

do
	local function Validate(id)
		return (id - 1) % 132 + 1
	end

	function ABFrame:UpdateActions()
		if self.states then
			for i,state in pairs(self.states) do
				for j,b in pairs(self.buttons) do
					local id = Validate(j + 12*(self.offsets[i]-1))
					b:SetAttribute('*action-S' .. i, id)
				end
			end
		end
	end
end


--[[ Core ]]--

Mangos = {}
Mangos.locked = true
Mangos.abStyle = {'Entropy: Copper', 0.5, true}
Mangos.abCount = 10
Mangos.settings = {}

function Mangos:Load()
	for i = 1, self.abCount do
		local f = ABFrame:New(i, ceil(120 / self.abCount))
		f:SetPoint('BOTTOM', 0, i*36 + 120)
		f:Layout()
		self:Register(f, i)
	end

	if LBF then
		LBF:Group('Mangos'):Skin(unpack(self.abStyle))
	end
	
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
	MainMenuBar:UnregisterAllEvents()
	MainMenuBar:Hide()
end

function Mangos:Register(id, bar)
	if not self.bars then self.bars = {} end
	self.bars[id] = bar
end

Mangos:Load()
Mangos:HideBlizzard()