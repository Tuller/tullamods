--[[
	BActionBar - A Bongos Actionbar
--]]

--basically, BActionBar inherits all methods from BBar
local BBar = BBar
local Bar_mt = {__index = BActionBar}
local BongosActionButton = BongosActionButton
BActionBar = setmetatable(CreateFrame("Button"), {__index = BBar})

local DEFAULT_SPACING = 2
local DEFAULT_SIZE = 12
local DEFAULT_COLS = 12
local MAX_BUTTONS = BongosActionButton:GetMax()
local BUTTON_SIZE = BongosActionButton:GetSize()
local STANCE_FORMAT = "s%d"

function BActionBar:Create(id)
	--load settings
	if not Bongos:GetBarSets(id) then
		local sets = Bongos:SetBarSets(id, {})
		if id == 1 then
			sets.paging = 1
			local class = select(2,UnitClass("player"))
			if class == 'DRUID' then
				sets['s1'] = 9; sets['s3'] = 7; sets['s7'] = 7
			elseif class == 'WARRIOR' then
				sets['s1'] = 7; sets['s2'] = 8; sets['s3'] = 9
			elseif class == 'ROGUE' then
				sets['s1'] = 7
			end
		end
	end

	local bar = setmetatable(BBar:Create(id, nil, nil, 'SecureStateHeaderTemplate'), Bar_mt)
	bar:SetAttribute('useparent-statebutton', true)
	bar:SetAttribute('useparent-unit', true)
	BState.Register(bar)

	--layout the bar
	if not bar:IsUserPlaced() then
		local start = bar:GetStartID()
		local row = mod(start - 1, 12)
		local col = ceil(start / 12) - 1
		bar:SetPoint('CENTER', UIParent, 'CENTER', 36 * row, -36 * col)
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

	--checkbuttons
	local paging = BongosMenu:CreateCheckButton(menu, name .. "Paging")
	paging:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -88)
	paging:SetScript("OnShow", function(self) self:SetChecked(menu.frame:CanPage()) end)
	paging:SetScript("OnCick", function(self) menu.frame:SetPaging(self:GetChecked()) end)
	paging:SetText("Page")

	--spacing
	local spacing = BongosMenu:CreateSpacingSlider(menu, name .. "Spacing")
	spacing:SetPoint("BOTTOM", name .. "Scale", "TOP", 0, 24)
	spacing:SetScript("OnShow", function(self)
		self:SetValue(menu.frame:GetSpacing())
	end)
	spacing:SetScript("OnValueChanged", function(self, value)
		if not menu.onShow then
			menu.frame:Layout(nil, value)
		end
		getglobal(self:GetName() .. 'ValText'):SetText(value)
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
		cols:SetMinMaxValues(1, size)
		cols:SetValue(size - cols + 1)
		getglobal(name .. "ColsLow"):SetText(size)
		getglobal(name .. "ColsValText"):SetText(cols)
	end)
	size:SetValueStep(1)
	getglobal(name .. "SizeText"):SetText(BONGOS_SIZE)
	getglobal(name .. "SizeLow"):SetText(1)

	menu:SetHeight(menu:GetHeight() + 96)

	return menu
end

--Called when the right click menu is shown, loads the correct values to the checkbuttons/sliders/text
function BActionBar:ShowMenu()
	if not self.menu then
		BActionBar.menu = self:CreateMenu()
	end

	local menu = self.menu
	menu.frame = self
	menu:SetText(format("Action Bar %s", self.id))

	menu.onShow = true
	self:PlaceMenu(menu)
	menu.onShow = nil
end


--[[ Paging ]]--

--enable/disables a bar paging
function BActionBar:SetPaging(enable)
	if enable then
		self.sets.paging = true
	else
		self.sets.paging = nil
	end
	self:UpdatePaging()
end

--update button ids for each button
function BActionBar:UpdatePaging()
	self.state = nil
	for i = self:GetStartID(), self:GetEndID() do
		BongosActionButton:Get(i):UpdateAllPages()
	end
	SecureStateHeader_Refresh(self)
end

--returns a bar's offset for the given page, in buttons
function BActionBar:GetPageOffset(page)
	if self:CanPage() then
		return ((page * self:GetPageSkip() + page) * self:GetMaxSize()) or 0
	end
	return 0
end

--returns true if a bar can page, nil otherwise
function BActionBar:CanPage()
	return self.sets.paging
end

--returns how many bars are "skipped" when paging, 0 is default
function BActionBar:GetPageSkip()
	return 0
end


--[[ Stances ]]--

function BActionBar:SetStanceBar(id, barID)
	self.sets[format(STANCE_FORMAT, id)] = barID
	self:UpdateStance(id)
end

function BActionBar:GetStanceBar(id)
	return self.sets[format(STANCE_FORMAT, id)]
end

function BActionBar:UpdateStance(id)
	self.state = nil
	for i = self:GetStartID(), self:GetEndID() do
		BongosActionButton:Get(i):UpdateStance(id)
	end
	SecureStateHeader_Refresh(self)
end

function BActionBar:UpdateStances()
	for i = self:GetStartID(), self:GetEndID() do
		BongosActionButton:Get(i):UpdateAllStances()
	end
	SecureStateHeader_Refresh(self)
end

function BActionBar:HasStance()
	local s,e = BState.GetStanceRange()
	for i = s, e do
		if self:GetStanceBar(i) then
			return true
		end
	end
end


--[[ Visibility ]]--

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
		button:SetPoint('TOPLEFT', self, 'TOPLEFT', buttonSize * row, -buttonSize * col)
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


--[[ Bar Numbers ]]--

function BActionBar:SetNumber(newSize)
	local oldSize = self:GetNumber()
	if oldSize ~= newSize then
		for i = 1, (oldSize or 10) do
			self:Get(i):Delete()
		end

--		BActionDB.number = newSize
		for i = 1, (newSize or 10) do
			self:Create(i)
		end
	end
end

function BActionBar:GetNumber()
	return 10
--	return BActionDB.number or 10
end


--[[ Utility ]]--

--does an action to every visible bar
function BActionBar:ForAllShown(action, ...)
	for i = 1, self:GetNumber() do
		local bar = self:Get(i)
		if bar and bar:IsShown() then
			action(bar, ...)
		end
	end
end

--does an action to every button on a visible bar that has a stance page
function BActionBar:ForAllWithStance(action, ...)
	for i = 1, self:GetNumber() do
		local bar = self:Get(i)
		if bar:IsShown() and bar:HasStance() then
			bar.state = nil
			for j = bar:GetStartID(), bar:GetEndID() do
				action(BActionButton:Get(j), ...)
			end
		end
	end
end

--does an action to every button on a visible bar that is able to page
function BActionBar:ForAllWithPage(action, ...)
	for i = 1, self:GetNumber() do
		local bar = self:Get(i)
		if bar:IsShown() and bar:CanPage() then
			bar.state = nil
			for j = bar:GetStartID(), bar:GetEndID() do
				action(BActionButton:Get(j), ...)
			end
		end
	end
end

--updates the showstates of every button on every bar
function BActionBar:UpdateVisibilityForAll(showEmpty)
	for i = 1, self:GetNumber() do
		local bar = self:Get(i)
		if bar:IsShown() then
			bar:UpdateVisibility(showEmpty)
		end
	end
end