--[[
	BActionBar - A Bongos Actionbar
--]]

--basically, BActionBar inherits all methods from BBar
BActionBar = setmetatable(CreateFrame("Button"), {__index = BBar})
local Bar_MT = {__index = BActionBar}

local DEFAULT_SPACING = 2
local DEFAULT_SIZE = 12
local DEFAULT_COLS = 12
local MAX_BUTTONS = 120
local BUTTON_SIZE = 36
local STANCE_FORMAT = "s%d"

function BActionBar:Create(id)
	local bar = setmetatable(BBar:CreateSecure(id), Bar_MT)

	if(id == 1) then
		local class = select(2, UnitClass("player"))
		local classMap
		local pageMap = "[actionbar:2]8;[actionbar:3]9;[actionbar:4]10;[actionbar:5]11;[actionbar:6]12;"
		local stateButton = "8:p1;9:p2;10:p3;11:p4;12:p5;13:help;"

		if(class == "ROGUE" or class == "PRIEST") then
			classMap = "[stance:1]1;"
			stateButton = "1:s1;" .. stateButton
		elseif(class == "WARRIOR") then
			classMap = "[stance:1]1;[stance:2]2;[stance:3]3;"
			stateButton = "1:s1;2:s2;3:s3;" .. stateButton
		elseif(class == "DRUID") then
			classMap = "[stance:1]1;[stance:2]2;[stance:3,nostealth]3;[stance:3,stealth]4;[stance:4]5;[stance:5]6;[stance:6]7;"
			stateButton = "1:s1;2:s2;3:s3;4:s4;5:s5;6:s6;7:s7;" .. stateButton
		end
		RegisterStateDriver(bar, "states", pageMap .. (classMap or "") .. "[help]13;0")

		bar:SetAttribute("statemap-states", "$input")
		bar:SetAttribute("statebutton", stateButton)
	end

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
	for i = self:GetStartID(), self:GetEndID() do
		local button = BongosActionButton:Get(i)
		if button then
			button:Release()
		end
	end
end


--[[ Menu Functions ]]--

function BActionBar:CreateMenu()
	local name = format("BongosMenu%s", self.id)
	local menu = BongosMenu:Create(name)

	--spacing
	local spacing = BongosMenu:CreateSpacingSlider(menu, name .. "Spacing")
	spacing:SetPoint("BOTTOM", name .. "Scale", "TOP", 0, 24)
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
	local cols = BongosMenu:CreateSlider(menu, name .. "Cols")
	cols:SetPoint("BOTTOM", spacing, "TOP", 0, 24)
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
	local size = BongosMenu:CreateSlider(menu, name .. "Size")
	size:SetPoint("BOTTOM", cols, "TOP", 0, 24)
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
		getglobal(this:GetName() .. "ValText"):SetText(value)

		local size = menu.frame:GetSize()
		local cols = menu.frame:GetColumns()
		getglobal(name .. "Cols"):SetMinMaxValues(1, size)
		getglobal(name .. "Cols"):SetValue(size - cols + 1)
		getglobal(name .. "ColsLow"):SetText(size)
		getglobal(name .. "ColsValText"):SetText(cols)
	end)
	size:SetValueStep(1)
	getglobal(name .. "SizeText"):SetText(BONGOS_SIZE)
	getglobal(name .. "SizeLow"):SetText(1)

	menu:SetHeight(menu:GetHeight() + 128)

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
		SecureStateHeader_Refresh(self)
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
	return 10
end


--[[ Utility ]]--

--updates the showstates of every button on every bar
function BActionBar:UpdateVisibilityForAll(showEmpty)
	for i = 1, self:GetNumber() do
		local bar = self:Get(i)
		if bar:IsShown() then
			bar:UpdateVisibility(showEmpty)
		end
	end
end