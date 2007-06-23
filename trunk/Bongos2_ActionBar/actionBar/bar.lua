--[[
	BActionBar - A Bongos Actionbar
--]]

--basically, BActionBar inherits all methods from BBar
BActionBar = setmetatable(CreateFrame("Frame"), {__index = BBar})
local Bar_MT = {__index = BActionBar}

local L = BONGOS_LOCALS

--constants
local CLASS = BONGOS_CLASS
local MAX_BUTTONS = BONGOS_MAX_BUTTONS
local MAX_PAGES = BONGOS_MAX_PAGES
local hasStance = (CLASS == "DRUID" or CLASS == "ROGUE" or CLASS == "WARRIOR" or CLASS == "PRIEST")

local BUTTON_SIZE = 36
local PROWL_STATE = 7
local HELP_STATE = 15
local CTRL_STATE = 16
local ALT_STATE = 17
local SHIFT_STATE = 18

local DEFAULT_SPACING = 2
local DEFAULT_SIZE = 12
local DEFAULT_COLS = 12

--2.1 statemap function!
local function GenerateStateButton()
	local pageMap = "10:p1;11:p2;12:p3;13:p4;14:p5;15:help;16:m1;17:m2;18:m3"
	local pageMap2 = "10:p1s;11:p2s;12:p3s;13:p4s;14:p5s;15:helps;16:m1s;17:m2s;18:m3s"

	local classStates, stanceMap, stanceMap2
	if(CLASS == "ROGUE" or CLASS == "PRIEST") then
		stanceMap = "1:s1"
		stanceMap2 = "1:s1s"
	elseif(CLASS == "WARRIOR") then
		stanceMap = "1:s1;2:s2;3:s3"
		stanceMap2 = "1:s1s;2:s2s;3:s3s"
	elseif(CLASS == "DRUID") then
		stanceMap = "1:s1;2:s2;3:s3;4:s4;5:s5;6:s6;7:s7"
		stanceMap2 = "1:s1s;2:s2s;3:s3s;4:s4s;5:s5s;6:s6s;7:s7s"
	end

	local stateButton1, stateButton2
	if stanceMap then
		stateButton1 = format("%s;%s", stanceMap, pageMap)
		stateButton2 =  format("%s;%s", stanceMap2, pageMap2)
	else
		stateButton1 = pageMap
		stateButton2 = pageMap2
	end

	return stateButton1, stateButton2
end
local stateButton1, stateButton2 = GenerateStateButton()


--[[ Constructor/Destructor]]--

local function OnShow(self)
	self:UpdateVisibility()
end

function BActionBar:Create(id)
	local defaults
	if(id == 1) then
		defaults = {p1 = 1, p2 = 2, p3 = 3, p4 = 4, p5 = 5}
		if CLASS == "DRUID" then
			defaults.s1 = 8; defaults.s3 = 6
		elseif CLASS == "WARRIOR" then
			defaults.s1 = 6; defaults.s2 = 7; defaults.s3 = 8
		elseif CLASS == "ROGUE" then
			defaults.s1 = 6
		end
	end

	local bar = setmetatable(BBar:CreateHeader(id, nil, nil, defaults), Bar_MT)
	bar:SetAttribute("statemap-state", "$input")
	bar:SetAttribute("statebutton", stateButton1)
	bar:SetAttribute("*statebutton2", stateButton2)

	bar:SetRightClickUnit(BongosActionConfig:GetRightClickUnit())
	bar:UpdateStateHeader()
	bar:SetScript("OnShow", OnShow)

	--layout the bar
	if not bar:IsUserPlaced() then
		local start = bar:GetStartID()
		local row = mod(start-1, 12)
		local col = ceil(start / 12) - 1
		bar:SetPoint("CENTER", UIParent, "CENTER", 36 * row, -36 * col)
	end
	bar:Layout()
	SecureStateHeader_Refresh(bar)

	return bar
end

function BActionBar:OnDelete()
	self:SetScript("OnShow", nil)

	for i = self:GetStartID(), self:GetEndID() do
		local button = BongosActionButton:Get(i)
		if button then
			button:Release()
		end
	end
end


--[[ State Functions ]]--

--generates a new stance header based on what states we want to switch in
--priority is modifier, then pages, then stances, then friendly target, then default
function BActionBar:UpdateStateHeader()
	UnregisterStateDriver(self, "state", 0)

	local header
	if(self:GetStateOffset("m1")) then
		local state = "[modifier:ctrl]16;"
		header = (header and header .. state) or state
	end

	if(self:GetStateOffset("m2")) then
		local state = "[modifier:alt]17;"
		header = (header and header .. state) or state
	end

	if(self:GetStateOffset("m3")) then
		local state = "[modifier:shift]18;"
		header = (header and header .. state) or state
	end

	for i = 1, MAX_PAGES do
		if(self:GetStateOffset("p" .. i)) then
			local state = format("[actionbar:%d]%d;", i+1, i+9)
			header = (header and header .. state) or state
		end
	end

	if(hasStance) then
		local maxState = (CLASS == "PRIEST" and 1) or GetNumShapeshiftForms()

		--prowl
		if(CLASS == "DRUID" and self:GetStateOffset("s7")) then
			local state = "[stance:2/3,stealth]7;"
			header = (header and header .. state) or state
		end

		--other stances (bear, battle, shadowform, etc)
		for i = 1, maxState do
			if(self:GetStateOffset("s" .. i)) then
				local state = format("[stance:%d]%d;", i, i)
				header = (header and header .. state) or state
			end
		end
	end

	if(self:GetStateOffset("help")) then
		local state = format("[help]%d;", HELP_STATE)
		header = (header and header .. state) or state
	end

	--add in default state
	if(header) then
		RegisterStateDriver(self, "state", header .. "0")
	end

	self:SetAttribute("state", self:GetCurrentState())
end

--returns the current state of the given bar
function BActionBar:GetCurrentState()
	if(IsControlKeyDown() and self:GetStateOffset("m1")) then
		return CTRL_STATE
	end

	if(IsAltKeyDown() and self:GetStateOffset("m2")) then
		return ALT_STATE
	end

	if(IsShiftKeyDown() and self:GetStateOffset("m3")) then
		return SHIFT_STATE
	end

	--page check
	local page = GetActionBarPage()-1
	if(page > 0 and self:GetStateOffset("p" .. page)) then
		return page + 9
	end

	--stance check
	if(hasStance) then
		local stance = GetShapeshiftForm()
		if(stance > 0) then
			--prowl check
			if(stance == 3 and IsStealthed() and self:GetStateOffset("s7")) then
				return PROWL_STATE
			end

			--some sort of stance
			if(self:GetStateOffset("s" .. stance)) then
				return stance
			end
		end
	end

	--friently target check
	if(UnitCanAssist("player", "target") and self:GetStateOffset("help")) then
		return HELP_STATE
	end

	--default state
	return 0
end


--[[ Menu Functions ]]--

local function StanceSlider_OnShow(self)
	self.onShow = true
	local frame = self:GetParent().frame

	local numBars = BongosActionBar:GetNumber()
	local maxOffset = numBars - 1
	self:SetMinMaxValues(0, maxOffset)
	self:SetValue(frame.sets[self.id] or 0)
	getglobal(self:GetName() .. "High"):SetText(maxOffset)
	getglobal(self:GetName() .. "ValText"):SetText(format("Bar %s", mod(frame.id+self:GetValue()-1, numBars)+1))

	self.onShow = nil
end

local function StanceSlider_OnValueChanged(self, value)
	local frame = self:GetParent().frame
	if not self.onShow then
		frame:SetStateOffset(self.id, value)
		getglobal(self:GetName() .. "ValText"):SetText(format("Bar %s", mod(frame.id+value-1, BongosActionBar:GetNumber())+1))
	end
end

local function Panel_AddStanceSlider(self, id, title)
	local name = self:GetName() .. "Stance" .. id

	local slider = self:CreateSlider(name)
	slider.id = id

	slider:SetScript("OnShow", StanceSlider_OnShow)
	slider:SetScript("OnValueChanged", StanceSlider_OnValueChanged)
	slider:SetValueStep(1)

	getglobal(name .. "Text"):SetText(title)
	getglobal(name .. "Low"):SetText(0)

	return slider
end

local function Panel_AddLayoutSliders(panel)
	local name = panel:GetName()
	--spacing
	local spacing = panel:CreateSpacingSlider(name .. "Spacing")
	spacing:SetScript("OnShow", function(self)
		self.onShow = true
		local parent = self:GetParent()
		self:SetValue(parent.frame:GetSpacing())
		self.onShow = nil
	end)
	spacing:SetScript("OnValueChanged", function(self, value)
		if not self.onShow then
			local parent = self:GetParent()
			parent.frame:SetSpacing(value)
		end
		getglobal(self:GetName() .. "ValText"):SetText(value)
	end)

	--columns
	local cols = panel:CreateSlider(name .. "Cols")
	cols:SetScript("OnShow", function(self)
		self.onShow = true
		local parent = self:GetParent()
		self:SetValue(parent.frame:GetSize() - parent.frame:GetColumns() + 1)
		self.onShow = nil
	end)
	cols:SetScript("OnValueChanged", function(self, value)
		local parent = self:GetParent()
		if not self.onShow then
			parent.frame:SetColumns(parent.frame:GetSize() - value + 1)
		end
		getglobal(self:GetName() .. "ValText"):SetText(parent.frame:GetColumns())
	end)
	cols:SetValueStep(1)
	getglobal(name .. "ColsText"):SetText(L.Columns)
	getglobal(name .. "ColsHigh"):SetText(1)

	--size
	local size = panel:CreateSlider(name .. "Size")
	size:SetScript("OnShow", function(self)
		self.onShow = true
		local frame = self:GetParent().frame
		getglobal(name .. "Size"):SetMinMaxValues(1, frame:GetMaxSize())
		getglobal(name .. "Size"):SetValue(frame:GetSize())
		getglobal(name .. "SizeHigh"):SetText(frame:GetMaxSize())
		self.onShow = nil
	end)
	size:SetScript("OnValueChanged", function(self, value)
		local parent = self:GetParent()
		if not self.onShow then
			parent.frame:SetSize(value)
		end
		getglobal(self:GetName() .. "ValText"):SetText(value)

		local size = parent.frame:GetSize()
		local cols = parent.frame:GetColumns()
		getglobal(name .. "Cols"):SetMinMaxValues(1, size)
		getglobal(name .. "Cols"):SetValue(size - cols + 1)
		getglobal(name .. "ColsLow"):SetText(size)
		getglobal(name .. "ColsValText"):SetText(cols)
	end)
	size:SetValueStep(1)
	getglobal(name .. "SizeText"):SetText(L.Size)
	getglobal(name .. "SizeLow"):SetText(1)
end

local function Panel_AddStanceSliders(panel)
	Panel_AddStanceSlider(panel, "help", L.FriendlyStance)

	if(hasStance) then
		if(CLASS == "PRIEST") then
			Panel_AddStanceSlider(panel, "s1", L.ShadowForm)
		else
			if(CLASS == "DRUID") then
				panel.s7 = Panel_AddStanceSlider(panel, "s7", L.Prowl)
			end

			local OnShow = panel:GetScript("OnShow")
			panel:SetScript("OnShow", function(self)
				for i = GetNumShapeshiftForms(), 1, -1 do
					local state = "s" .. i
					local name = select(2, GetShapeshiftFormInfo(i))

					local slider = self[state]
					if slider then
						getglobal(slider:GetName() .. "Text"):SetText(name)
					else
						self[state] = Panel_AddStanceSlider(self, state, name)
						StanceSlider_OnShow(self[state])
					end
				end
				OnShow(self)
			end)
		end
	end
end

function BActionBar:CreateMenu()
	local name = format("BongosMenu%s", self.id)
	local menu, panel = BongosMenu:Create(name, true)

	--layout panel
	Panel_AddLayoutSliders(panel)

	--stances panel
	local panel = menu:AddPanel(L.Stances)
	Panel_AddStanceSliders(panel)

	--paging panel
	local panel = menu:AddPanel(L.Paging)
	for i = MAX_PAGES, 1, -1 do
		Panel_AddStanceSlider(panel, "p" .. i, format(L.Page, i+1))
	end

	local panel = menu:AddPanel(L.Modifier)
	Panel_AddStanceSlider(panel, "m3", "Shift")
	Panel_AddStanceSlider(panel, "m2", "Alt")
	Panel_AddStanceSlider(panel, "m1", "Ctrl")

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

	menu:SetFrame(self)
	menu.text:SetText(format(L.ActionBar, self.id))

	menu.onShow = true
	self:PlaceMenu(menu)
	menu:ShowPanel(L.Layout)
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
	return MAX_BUTTONS / BongosActionBar:GetNumber()
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
	if InCombatLockdown() then return end

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

function BActionBar:UpdateVisibility()
	local s, e = self:GetStartID(), self:GetEndID()
	for i = s, e do
		BongosActionButton:Get(i):Update()
	end
end


--[[ Stance Settings ]]--

function BActionBar:SetStateOffset(state, offset)
	if(offset == 0) then offset = nil end
	self.sets[state] = offset
	self:UpdateStateHeader()
	self:UpdateButtonStates()
end

function BActionBar:GetStateOffset(state)
	local offset = self.sets[state]
	if(offset and offset ~= 0) then
		return offset * self:GetMaxSize()
	end
	return nil
end

function BActionBar:UpdateButtonStates()
	for i = self:GetStartID(), self:GetEndID() do
		BongosActionButton:Get(i):UpdateStates()
	end
	SecureStateHeader_Refresh(self, self:GetCurrentState())
end


--[[ Utility ]]--

function BActionBar:SetRightClickUnit(unit)
	self:SetAttribute("*unit2", unit)

	for i = 1, 3 do
		self:SetAttribute(format("*unit-m%ds", i), unit)
	end

	for i = 1, MAX_PAGES do
		self:SetAttribute(format("*unit-p%ds", i), unit)
	end

	if(hasStance) then
		local maxState = (CLASS == "PRIEST" and 1) or GetNumShapeshiftForms()

		for i = 1, maxState do
			self:SetAttribute(format("*unit-s%ds", i), unit)
		end

		if(CLASS == "DRUID") then
			self:SetAttribute(format("*unit-s%ds", PROWL_STATE), unit)
		end
	end

	self:SetAttribute("*unit-helps", unit)
end