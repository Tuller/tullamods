--[[
	BActionBar - A Bongos Actionbar
--]]


--[[ Object  stuff ]]--

--basically, BActionBar inherits all methods from BBar
BActionBar = CreateFrame('Button')
setmetatable(BActionBar, {__index = BBar})
local Bar_mt = {__index = BActionBar}
local super = BBar


--[[ Constants ]]--

local DEFAULT_SPACING = 2
local DEFAULT_SIZE = 12
local DEFAULT_COLS = 12
local MAX_BUTTONS = BActionButton.GetMax()
local BUTTON_SIZE = BActionButton.GetSize()


--[[ Constructor ]]--

--create a new actionbar, load settings and layout
function BActionBar.Create(id)
	if not Bongos.GetBarSets(id) then
		local sets = Bongos.SetBarSets(id, {vis = 1})
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

	local bar = BBar.Create(id, nil, BActionButton.OnDelete, 'SecureStateHeaderTemplate')
	setmetatable(bar, Bar_mt)
	
	if not bar.sets.vis then
		bar:SetAttribute('hidestates', '*')
	else
		bar:SetAttribute('hidestates', nil)
	end
	bar:SetAttribute('useparent-statebutton', true)
	bar:SetAttribute('useparent-unit', true)
	BState.Register(bar)

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


--[[ Destructor ]]--

function BActionBar:OnDelete()
	for i = self:GetStartID(), self:GetEndID() do
		local button = BActionButton.Get(i)
		if button then
			button:Release()
		end
	end
end


--[[ Menu Functions ]]--

--adds all buttons to the right click menu
local function CreateConfigMenu(name)
	local menu = CreateFrame("Button", name, UIParent, "BongosRightClickMenu")
	menu:SetWidth(220)
	menu:SetHeight(290)

	--checkbuttons
	local paging = CreateFrame('CheckButton', name .. 'Paging', menu, 'GooeyCheckButton')
	paging:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -28)
	paging:SetScript('OnClick', function() menu.frame:SetPaging(this:GetChecked()) end)
	paging:SetText('Page')

	--sliders
	local opacity = CreateFrame("Slider", name .. "Opacity", menu, "BongosOpacitySlider")
	opacity:SetPoint("BOTTOM", menu, "BOTTOM", 0, 24)

	local scale = CreateFrame("Slider", name .. "Scale", menu, "BongosScaleSlider")
	scale:SetPoint("BOTTOM", opacity, "TOP", 0, 24)

	local spacing = CreateFrame("Slider", name .. "Spacing", menu, "BongosSpaceSlider")
	spacing:SetPoint("BOTTOM", scale, "TOP", 0, 24)
	spacing:SetScript("OnValueChanged", function()
		if not menu.onShow then
			menu.frame:SetSpacing(this:GetValue())
		end
		getglobal(this:GetName() .. 'ValText'):SetText(this:GetValue())
	end)

	local cols = CreateFrame("Slider", name .. "Cols", menu, "BongosSlider")
	cols:SetPoint("BOTTOM", spacing, "TOP", 0, 24)
	cols:SetScript("OnValueChanged", function()
		if not menu.onShow then
			menu.frame:SetColumns(menu.frame:GetSize() - this:GetValue() + 1)
		end
		getglobal(this:GetName() .. 'ValText'):SetText(menu.frame:GetColumns())
	end)
	cols:SetValueStep(1)
	getglobal(name .. "ColsText"):SetText(BONGOS_COLUMNS)
	getglobal(name .. "ColsHigh"):SetText(1)

	local size = CreateFrame("Slider", name .. "Size", menu, "BongosSlider")
	size:SetPoint("BOTTOM", cols, "TOP", 0, 24)
	size:SetScript("OnValueChanged", function()
		if not menu.onShow then
			menu.frame:SetSize(this:GetValue())
		end
		getglobal(this:GetName() .. 'ValText'):SetText(this:GetValue())

		local size = menu.frame:GetSize()
		local cols = menu.frame:GetColumns()
		getglobal(name .. 'Cols'):SetMinMaxValues(1, size)
		getglobal(name .. 'Cols'):SetValue(size - cols + 1)
		getglobal(name .. "ColsLow"):SetText(size)
		getglobal(name .. "ColsValText"):SetText(cols)

	end)
	size:SetValueStep(1)
	getglobal(name .. "SizeText"):SetText(BONGOS_SIZE)
	getglobal(name .. "SizeLow"):SetText(1)
	
	return menu
end

--Called when the right click menu is shown, loads the correct values to the checkbuttons/sliders/text
function BActionBar:ShowMenu()
	local name = 'BongosActionBarMenu'
	local menu = getglobal(name) or CreateConfigMenu(name)

	menu:SetText(format('Action Bar %s', self.id))
	menu.frame = self
	menu.onShow = 1
	
	getglobal(name .. 'Paging'):SetChecked(self:CanPage())

	getglobal(name .. 'Size'):SetMinMaxValues(1, self:GetMaxSize())
	getglobal(name .. 'Size'):SetValue(self:GetSize())
	getglobal(name .. 'SizeHigh'):SetText(self:GetMaxSize())
	getglobal(name .. 'Cols'):SetValue(self:GetSize() - self:GetColumns() + 1)
	getglobal(name .. 'Spacing'):SetValue(self:GetSpacing())
	getglobal(name .. 'Scale'):SetValue(self:GetScale() * 100)
	getglobal(name .. 'Opacity'):SetValue(self:GetAlpha() * 100)

	self:DisplayMenu(menu)

	menu.onShow = nil
end


--[[ Paging ]]--

--enable/disables a bar paging
function BActionBar:SetPaging(enable)
	if enable then
		self.sets.paging = 1
	else
		self.sets.paging = nil
	end
	self:UpdatePaging()
end

--update button ids for each button
function BActionBar:UpdatePaging()
	self.state = nil
	for i = self:GetStartID(), self:GetEndID() do
		BActionButton.Get(i):UpdateAllPages()
	end
	SecureStateHeader_Refresh(self)
end

--returns a bar's offset for the given page, in buttons
function BActionBar:GetPageOffset(page)
	if self:CanPage() then
		return ((page * self:GetPageSkip() + page) * BActionBar.GetMaxSize()) or 0
	end
	return 0
end

--returns true if a bar can page, nil otherwise
function BActionBar:CanPage()
	return self.sets.paging
end

--returns how many bars are "skipped" when paging, 0 is default
function BActionBar:GetPageSkip()
	return BActionConfig.GetPageSkip()
end


--[[ Stances ]]--

local STANCE_FORMAT = 's%d'
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
		BActionButton.Get(i):UpdateStance(id)
	end
	SecureStateHeader_Refresh(self)
end

function BActionBar:UpdateStances()
	for i = self:GetStartID(), self:GetEndID() do
		BActionButton.Get(i):UpdateAllStances()
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
	local starti = self:GetStartID()
	local endi = self:GetEndID()
	local showEmpty = showAll or BActionButton.ShowingEmpty()

	local changed
	for i = starti, endi do
		if BActionButton.Get(i):UpdateVisibility(showEmpty) then
			changed = true
		end
	end

	if changed then
		SecureStateHeader_Refresh(self)
	end
end

function BActionBar:ShowFrame()
	super.ShowFrame(self)
	self:SetAttribute('hidestates', nil)
end

function BActionBar:HideFrame()
	super.HideFrame(self)
	self:SetAttribute('hidestates', '*')
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
	return MAX_BUTTONS / BActionBar.GetNumber()
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
	local prev = BActionBar.Get(self.id - 1)
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
		local button = BActionButton.Set(startID + i-1, self)
		button:SetPoint('TOPLEFT', self, 'TOPLEFT', buttonSize * row, -buttonSize * col)
	end

	--remove any unused buttons
	if startID < maxID then
		for i = endID + 1, maxID do
			local button = BActionButton.Get(i)
			if button then
				button:Release()
			else break end
		end
	end
end


--[[ Non Bar Specific Functions ]]--


--[[ Bar Numbers ]]--

function BActionBar.SetNumber(newSize)
	local oldSize = BActionBar.GetNumber()
	if oldSize ~= newSize then
		for i = 1, (oldSize or 10) do
			BActionBar.Get(i):Delete()
		end

		BActionDB.number = newSize
		for i = 1, (newSize or 10) do
			BActionBar.Create(i)
		end
	end
end

function BActionBar.GetNumber()
	return BActionDB.number or 10
end


--[[ Utility ]]--

--does an action to every visible bar
function BActionBar.ForAllShown(action, ...)
	for i = 1, BActionBar.GetNumber() do
		local bar = BActionBar.Get(i)
		if bar and bar:IsShown() then
			action(BActionBar.Get(i), ...)
		end
	end
end

--does an action to every button on a visible bar that has a stance page
function BActionBar.ForAllWithStance(action, ...)
	for i = 1, BActionBar.GetNumber() do
		local bar = BActionBar.Get(i)
		if bar:IsShown() and bar:HasStance() then
			bar.state = nil
			for j = bar:GetStartID(), bar:GetEndID() do
				action(BActionButton.Get(j), ...)
			end
		end
	end
end

--does an action to every button on a visible bar that is able to page
function BActionBar.ForAllWithPage(action, ...)
	for i = 1, BActionBar.GetNumber() do
		local bar = BActionBar.Get(i)
		if bar:IsShown() and bar:CanPage() then
			bar.state = nil
			for j = bar:GetStartID(), bar:GetEndID() do
				action(BActionButton.Get(j), ...)
			end
		end
	end
end

--updates the showstates of every button on every bar
function BActionBar.UpdateVisibilityForAll(showEmpty)
	for i = 1, BActionBar.GetNumber() do
		local bar = BActionBar.Get(i)
		if bar:IsShown() then
			bar:UpdateVisibility(showEmpty)
		end
	end
end


--[[ Startup ]]--

--create all actionbars
Bongos.AddStartup(function() 
	for i = 1, BActionBar.GetNumber() do 
		BActionBar.Create(i)
	end
end)
