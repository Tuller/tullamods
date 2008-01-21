--[[
	BongosClassBar
		A replacement for the Blizzard shapeshift bar
--]]

local class = BONGOS_CLASS
if not(class == 'DRUID' or class == 'ROGUE' or class == 'WARRIOR' or class == 'PALADIN') then
	return
end

BongosClassBar = Bongos:NewModule('Bongos-ClassBar')
local L = BONGOS_LOCALS
local DEFAULT_SPACING = 2


--[[ Bar ]]--

local function Bar_SetSpacing(self, spacing)
	self:Layout(nil, spacing)
end

local function Bar_GetSpacing(self)
	return self.sets.spacing or DEFAULT_SPACING
end

local function Bar_Layout(self, cols, space)
	local numForms = GetNumShapeshiftForms()

	cols = (cols or self.sets.cols or numForms)
	self.sets.cols = (cols ~= numForms and cols) or nil

	space = (space or self.sets.space or DEFAULT_SPACING)
	self.sets.space = (space ~= DEFAULT_SPACING and space) or nil

	local size = 30 + space
	local offset = space / 2

	for i = 1, numForms do
		local row = (i - 1) % cols
		local col = ceil(i / cols) - 1
		BongosClassButton:Get(i):SetPoint('TOPLEFT', size * row, -size * col)
	end

	self:SetSize(size * cols - space, size * ceil(numForms/cols) - space)
end

local function Bar_CreateMenu(frame)
	local menu,panel = BongosMenu:CreateMenu(frame.id)

	--sliders
	panel:AddSpacingSlider()

	local cols = panel:AddSlider(L.Columns, 1, 1, 1)
	cols:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetMinMaxValues(1, GetNumShapeshiftForms())
		self:SetValue(GetNumShapeshiftForms() - (frame.sets.cols or GetNumShapeshiftForms()) + 1)
		getglobal(self:GetName() .. 'Low'):SetText(GetNumShapeshiftForms())
		self.onShow = nil
	end)
	cols:SetScript('OnValueChanged', function(self, value)
		if not self.onShow then
			frame:Layout(GetNumShapeshiftForms() - value + 1)
		end
		getglobal(self:GetName() .. 'ValText'):SetText(GetNumShapeshiftForms() - value + 1)
	end)

	return menu
end

local function Bar_OnCreate(self)
	self.CreateMenu = Bar_CreateMenu
	self.Layout = Bar_Layout
	self.SetSpacing = Bar_SetSpacing
	self.GetSpacing = Bar_GetSpacing
end


--[[ Events ]]--

function BongosClassBar:Load()
	self.bar = BBar:Create('class', Bar_OnCreate, nil, {x = 703, y = 651})
	self:UpdateForms()

	self:RegisterEvent('UPDATE_SHAPESHIFT_FORMS', 'UpdateForms')
end

function BongosClassBar:Unload()
	self:UnregisterAllEvents()
	self.bar:Destroy()
end

function BongosClassBar:UpdateForms()
	for id = 1, GetNumShapeshiftForms() do
		local button = BongosClassButton:Get(id) or BongosClassButton:Create(id, self.bar)
		button:UpdateSpell()
		button:Show()
	end
	self.bar:Layout()
end