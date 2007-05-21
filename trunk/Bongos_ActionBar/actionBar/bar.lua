--[[
	BActionBar - A Bongos Actionbar
--]]

--basically, BActionBar inherits all methods from BBar
BActionBar = setmetatable(CreateFrame("Button"), {__index = BBar})
local Bar_MT = {__index = BActionBar}

--constants
local CLASS = BONGOS_CLASS
local MAX_BUTTONS = BONGOS_MAX_BUTTONS
local STANCES = BONGOS_STANCES
local MAX_PAGES = BONGOS_MAX_PAGES
local BUTTON_SIZE = 36
local PROWL_STATE = 7
local HELP_STATE = 15

local DEFAULT_NUM_ACTIONBARS = 10
local DEFAULT_SPACING = 2
local DEFAULT_SIZE = 12
local DEFAULT_COLS = 12

--2.1 statemap function!
local function GenerateStateMap()
	local pageStates = "[actionbar:2]10;[actionbar:3]11;[actionbar:4]12;[actionbar:5]13;[actionbar:6]14;"
	local pageMap = "10:p1;11:p2;12:p3;13:p4;14:p5;15:help"
	local pageMap2 = "10:p1s;11:p2s;12:p3s;13:p4s;14:p5s;15:helps"

	local classStates, stanceMap, stanceMap2
	if(CLASS == "ROGUE" or CLASS == "PRIEST") then
		classStates = "[stance:1]1;"
		stanceMap = "1:s1"
		stanceMap2 = "1:s1s"
	elseif(CLASS == "WARRIOR") then
		classStates = "[stance:1]1;[stance:2]2;[stance:3]3;"
		stanceMap = "1:s1;2:s2;3:s3"
		stanceMap2 = "1:s1s;2:s2s;3:s3s"
	elseif(CLASS == "DRUID") then
		classStates = "[stance:1]1;[stance:2,nostealth]2;[stance:2,stealth]7;[stance:3,nostealth]3;[stance:3,stealth]7;[stance:4]4;[stance:5]5;[stance:6]6;"
		stanceMap = "1:s1;2:s2;3:s3;4:s4;5:s5;6:s6;7:s7"
		stanceMap2 = "1:s1s;2:s2s;3:s3s;4:s4s;5:s5s;6:s6s;7:s7s"
	end
	
	local stateHeader
	if(classStates) then
		stateHeader = pageStates .. classStates .. "[help]15;0"
	else
		stateHeader = pageStates .. "[help]15;0"
	end
	
	local stateButton1, stateButton2
	if(STANCES) then
		stateButton1 = format("%s;%s", stanceMap, pageMap)
		stateButton2 =  format("%s;%s", stanceMap2, pageMap2)
	else
		stateButton1 = pageMap
		stateButton2 = pageMap2
	end
	return stateHeader, stateButton1, stateButton2
end


--[[ Constructor/Destructor]]--

function BActionBar:Create(id)
	local bar = setmetatable(BBar:CreateSecure(id), Bar_MT)
	bar:LoadStates()
	bar:SetRightClickUnit("player")

	--layout the bar
	if not bar:IsUserPlaced() then
		local start = bar:GetStartID()
		local row = mod(start-1, 12)
		local col = ceil(start / 12) - 1
		bar:SetPoint("CENTER", UIParent, "CENTER", 36 * row, -36 * col)
	end
	bar:Layout()
	SecureStateHeader_Refresh(bar, bar:GetCurrentState())

	return bar
end

function BActionBar:OnDelete()
	for i = self:GetStartID(), self:GetEndID() do
		local button = BongosActionButton:Get(i)
		if button then
			button:Release()
		end
	end
end


--[[ State Functions ]]--

local stateHeader, stateButton1, stateButton2 = GenerateStateMap()
function BActionBar:LoadStates()
	RegisterStateDriver(self, "state", stateHeader)

	self:SetAttribute("statemap-state", "$input")
	self:SetAttribute("statebutton", stateButton1)
	self:SetAttribute("statebutton2", stateButton2)
end

--things that should be documented more: this function
--hurray magic numbers!
function BActionBar:GetCurrentState()
	local page = GetActionBarPage()
	if(page == 1) then
		local stance = GetShapeshiftForm()
		--prowl check
		if((stance == 3 or stance == 2) and IsStealthed()) then
			return PROWL_STATE
		elseif(stance == 0) then
			if(UnitCanAssist("player", "target")) then
				return HELP_STATE
			end
			return stance
		end
	else
		return page + 9
	end
end


--[[ Menu Functions ]]--

local function StanceSlider_OnShow(self)
	local frame = self:GetParent().frame

	self:SetMinMaxValues(0, frame:GetNumber())
	self:SetValue(frame.sets[self.id] or 0)
	getglobal(self:GetName() .. "High"):SetText(frame:GetNumber()-1)
end

local function StanceSlider_OnValueChanged(self, value)
	local menu = self:GetParent()
	if not menu.onShow then
		menu.frame:SetStateOffset(self.id, value)
	end
	getglobal(self:GetName() .. "ValText"):SetText(value)
end

local function Menu_CreateStanceSlider(self, id, title)
	local name = self:GetName() .. "Stance" .. id

	local slider = self:CreateSlider(name)
	slider.id = id

	slider:SetScript("OnShow", StanceSlider_OnShow)
	slider:SetScript("OnValueChanged", StanceSlider_OnValueChanged)
	slider:SetValueStep(1)

	getglobal(name .. "Text"):SetText(title)
	getglobal(name .. "Low"):SetText(0)
end

function BActionBar:CreateMenu()
	local name = format("BongosMenu%s", self.id)
	local menu = BongosMenu:Create(name)

	for i = MAX_PAGES, 1, -1 do
		Menu_CreateStanceSlider(menu, "p" .. i, "Page " .. i)
	end

	if(STANCES) then
		for i in ipairs(STANCES) do
			Menu_CreateStanceSlider(menu, "s" .. i, STANCES[i])
		end
	end
	Menu_CreateStanceSlider(menu, "help", "Friendly Target")

	--spacing
	local spacing = menu:CreateSpacingSlider(name .. "Spacing")
	spacing:SetScript("OnShow", function(self)
		self:SetValue(menu.frame:GetSpacing())
	end)
	spacing:SetScript("OnValueChanged", function(self, value)
		if not menu.onShow then
			menu.frame:SetSpacing(value)
		end
		getglobal(self:GetName() .. "ValText"):SetText(value)
	end)

	--columns
	local cols = menu:CreateSlider(name .. "Cols")
	cols:SetScript("OnShow", function(self)
		self:SetValue(menu.frame:GetSize() - menu.frame:GetColumns() + 1)
	end)
	cols:SetScript("OnValueChanged", function(self, value)
		if not menu.onShow then
			menu.frame:SetColumns(menu.frame:GetSize() - value + 1)
		end
		getglobal(self:GetName() .. "ValText"):SetText(menu.frame:GetColumns())
	end)
	cols:SetValueStep(1)
	getglobal(name .. "ColsText"):SetText("Columns")
	getglobal(name .. "ColsHigh"):SetText(1)

	--size
	local size = menu:CreateSlider(name .. "Size")
	size:SetScript("OnShow", function(self)
		local frame = menu.frame
		getglobal(name .. "Size"):SetMinMaxValues(1, frame:GetMaxSize())
		getglobal(name .. "Size"):SetValue(frame:GetSize())
		getglobal(name .. "SizeHigh"):SetText(frame:GetMaxSize())
	end)
	size:SetScript("OnValueChanged", function(self, value)
		if not menu.onShow then
			menu.frame:SetSize(value)
		end
		getglobal(self:GetName() .. "ValText"):SetText(value)

		local size = menu.frame:GetSize()
		local cols = menu.frame:GetColumns()
		getglobal(name .. "Cols"):SetMinMaxValues(1, size)
		getglobal(name .. "Cols"):SetValue(size - cols + 1)
		getglobal(name .. "ColsLow"):SetText(size)
		getglobal(name .. "ColsValText"):SetText(cols)
	end)
	size:SetValueStep(1)
	getglobal(name .. "SizeText"):SetText("Size")
	getglobal(name .. "SizeLow"):SetText(1)

	return menu
end

--Called when the right click menu is shown, loads the correct values to the checkbuttons/sliders/text
function BActionBar:ShowMenu()
	--a metatable trickish
	if not BActionBar.menu then
		BActionBar.menu = self:CreateMenu()
	end

	local menu = self.menu
	if menu:IsShown() then
		menu:Hide()
	end

	menu.frame = self
	menu.text:SetText(format("Action Bar %s", self.id))

	menu.onShow = true
	self:PlaceMenu(menu)
	menu.onShow = nil
end


--[[ Sizing ]]--

function BActionBar:SetSize(size)
	if not size or size == DEFAULT_SIZE then
		size = nil
	end
	self.sets.size = size
	self:Layout()
end

function BActionBar:GetSize()
	return min(self.sets.size or DEFAULT_SIZE, self:GetMaxSize())
end

function BActionBar:GetMaxSize()
	return MAX_BUTTONS / self:GetNumber()
end


--[[ Columns ]]--

function BActionBar:SetColumns(cols)
	if not cols or cols == DEFAULT_COLS then
		cols = nil
	end
	self.sets.cols = cols
	self:Layout()
end

function BActionBar:GetColumns()
	return min(self.sets.cols or DEFAULT_COLS, self:GetSize())
end


--[[ Spacing ]]--

function BActionBar:SetSpacing(spacing)
	if not spacing or spacing == DEFAULT_SPACING then
		spacing = nil
	end
	self.sets.spacing = spacing
	self:Layout()
end

function BActionBar:GetSpacing()
	return self.sets.spacing or DEFAULT_SPACING
end


--[[ Start, End, and MaxIDs ]]--

--returns the first button ID on the given bar
function BActionBar:GetStartID()
	local prev = self:Get(self.id - 1)
	if prev then
		self.start = prev:GetMaxID() + 1
	else
		self.start = 1
	end
	return self.start
end

--returns the last button ID shown on the given bar
function BActionBar:GetEndID()
	return self:GetStartID() + self:GetSize() - 1
end

--returns the last button ID alloted to the bar
function BActionBar:GetMaxID()
	return self:GetStartID() + self:GetMaxSize() - 1
end


--[[ Layout ]]--

function BActionBar:Layout()
	local startID = self:GetStartID()
	local endID = self:GetEndID()
	local maxID = self:GetMaxID()

	local size = self:GetSize()
	local cols = self:GetColumns()
	local spacing = self:GetSpacing()
	local buttonSize = BUTTON_SIZE + spacing

	--size the bar
	self:SetWidth(buttonSize * cols - spacing)
	self:SetHeight(buttonSize * ceil(size / cols) - spacing)

	--place all used buttons, and update those buttons showstates and hotkeys
	for i = 1, size do
		local row = mod(i-1, cols)
		local col = ceil(i / cols) - 1
		local button = BongosActionButton:Set(startID + i-1, self)
		button:SetPoint("TOPLEFT", self, "TOPLEFT", buttonSize * row, -buttonSize * col)
	end

	--remove any unused buttons
	if startID < maxID then
		for i = endID + 1, maxID do
			local button = BongosActionButton:Get(i)
			if button then
				button:Release()
			else break end
		end
	end
end

function BActionBar:UpdateVisibility(showAll)
	local s = self:GetStartID()
	local e = self:GetEndID()
	local showEmpty = showAll or BongosActionButton:ShowingEmpty()

	local changed
	for i = s, e do
		if BongosActionButton:Get(i):UpdateVisibility(showEmpty) then
			changed = true
		end
	end

	if changed then
		SecureStateHeader_Refresh(self, self:GetCurrentState())
	end
end


--[[ Bar Numbers ]]--

function BActionBar:SetNumber(newSize)
	local oldSize = self:GetNumber()
	if oldSize ~= newSize then
		for i = 1, (oldSize or 10) do
			self:Get(i):Delete()
		end

		for i = 1, (newSize or 10) do
			self:Create(i)
		end
	end
end

function BActionBar:GetNumber()
	return BongosActionMain.profile.numActionBars or DEFAULT_NUM_ACTIONBARS
end


--[[ Stance Settings ]]--

function BActionBar:SetStateOffset(state, offset)
	if(offset == 0) then offset = nil end
	self.sets[state] = offset

	for i = self:GetStartID(), self:GetEndID() do
		local button = BongosActionButton:Get(i)
		button:UpdateStates()
	end
	SecureStateHeader_Refresh(self, self:GetCurrentState())
end

function BActionBar:GetStateOffset(state)
	local offset = self.sets[state]
	if(offset and offset ~= 0) then
		return offset * self:GetMaxSize()
	end
	return nil
end


--[[ Utility ]]--

--updates the showstates of every button on every bar
function BActionBar:UpdateVisibilityForAll()
	for i = 1, self:GetNumber() do
		local bar = self:Get(i)
		if bar:IsShown() then
			bar:UpdateVisibility()
		end
	end
end

function BActionBar:SetRightClickUnit(unit)
	self:SetAttribute("unit2", unit)
	for i = 1, MAX_PAGES do
		self:SetAttribute("unit-page" .. i .. "s", unit)
	end

	if(STANCES) then
		for i in pairs(STANCES) do
			self:SetAttribute("unit-stance" .. i .. "s", unit)
		end
	end
	
	self:SetAttribute("alt-unit*", "mouseover")
end