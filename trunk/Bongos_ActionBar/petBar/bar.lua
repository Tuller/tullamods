--[[
	BPetBar
		A replacement for the default pet actionbar
--]]

--constants
local DEFAULT_SPACING = 2


--[[ Layout Functions ]]--

local function Layout(self, cols, space)
	cols = (cols or self.sets.cols or NUM_PET_ACTION_SLOTS)
	if cols == DEFAULT_COLS then
		self.sets.cols = nil
	else
		self.sets.cols = cols
	end

	space = (space or self.sets.space or DEFAULT_SPACING)
	if space == DEFAULT_SPACING then
		self.sets.space = nil
	else
		self.sets.space = space
	end
	space = space + 2
	
	local buttonSize = 30 + space
	local offset = space / 2

	self:SetWidth(buttonSize * cols - space)
	self:SetHeight(buttonSize * ceil(NUM_PET_ACTION_SLOTS / cols) - space)

	for i = 1, NUM_PET_ACTION_SLOTS do
		local row = mod(i - 1, cols)
		local col = ceil(i / cols) - 1
		local button = BPetButton.Get(i)
		button:ClearAllPoints()
		button:SetPoint('TOPLEFT', self, 'TOPLEFT', buttonSize * row, -buttonSize * col)
		button:Update()
	end
end


--[[ Events ]]--

local function OnEvent()
	if event == "UPDATE_BINDINGS" then
		BPetButton.ForAll(BPetButton.UpdateHotkey)
	elseif event == "UNIT_FLAGS" or event == "UNIT_AURA" then
		if arg1 == 'pet' then
			BPetButton.ForAll(BPetButton.Update)
		end
	elseif event == "PET_BAR_UPDATE" then
		BPetButton.ForAll(BPetButton.Update)
	elseif event =="PET_BAR_UPDATE_COOLDOWN" then
		BPetButton.ForAll(BPetButton.UpdateCooldown)
	elseif event =="PET_BAR_SHOWGRID" then
		bg_showPetGrid = true
		BPetButton.ForAll(BPetButton.UpdateVisibility)
	elseif event =="PET_BAR_HIDEGRID" then
		bg_showPetGrid = nil
		BPetButton.ForAll(BPetButton.UpdateVisibility)
	end
end


--[[ Rightclick Menu Functions ]]--

local function CreateConfigMenu(name, frame)
	local menu = CreateFrame("Button", name, UIParent, "BongosRightClickMenu")
	menu.frame = frame

	menu:SetText('Pet Bar')
	menu:SetWidth(220)
	menu:SetHeight(220)
	
	--sliders
	local opacity = CreateFrame("Slider", name .. "Opacity", menu, "BongosOpacitySlider")
	opacity:SetPoint("BOTTOM", menu, "BOTTOM", 0, 24)

	local scale = CreateFrame("Slider", name .. "Scale", menu, "BongosScaleSlider")
	scale:SetPoint("BOTTOM", opacity, "TOP", 0, 24)

	local spacing = CreateFrame("Slider", name .. "Spacing", menu, "BongosSpaceSlider")
	spacing:SetPoint("BOTTOM", scale, "TOP", 0, 24)
	spacing:SetScript("OnValueChanged", function()
		if not menu.onShow then
			frame:Layout(nil, this:GetValue())
		end
		getglobal(this:GetName() .. 'ValText'):SetText(this:GetValue())
	end)

	local cols = CreateFrame("Slider", name .. "Cols", menu, "BongosSlider")
	cols:SetPoint("BOTTOM", spacing, "TOP", 0, 24)
	cols:SetScript("OnValueChanged", function()
		if not menu.onShow then
			frame:Layout(NUM_PET_ACTION_SLOTS - this:GetValue() + 1)
		end
		getglobal(this:GetName() .. 'ValText'):SetText(NUM_PET_ACTION_SLOTS - this:GetValue() + 1)
	end)
	cols:SetValueStep(1)
	getglobal(name .. "Cols"):SetMinMaxValues(1, NUM_PET_ACTION_SLOTS)
	getglobal(name .. "ColsText"):SetText(BONGOS_COLUMNS)
	getglobal(name .. "ColsLow"):SetText(NUM_PET_ACTION_SLOTS)
	getglobal(name .. "ColsHigh"):SetText(1)
	
	return menu
end

--Called when the right click menu is shown, loads the correct values to the checkbuttons/sliders/text
local function ShowMenu(self)
	local name = 'BongosPetBarMenu'
	local menu = getglobal(name) or CreateConfigMenu(name, self)

	menu.onShow = 1
	
	getglobal(name .. 'Cols'):SetValue(NUM_PET_ACTION_SLOTS - (self.sets.cols or NUM_PET_ACTION_SLOTS) + 1)
	getglobal(name .. 'Spacing'):SetValue(self.sets.space or DEFAULT_SPACING)

	self:DisplayMenu(menu)

	menu.onShow = nil
end


--[[ Startup ]]--

local function OnCreate(self)
	self:SetFrameStrata('DIALOG')
	self.ShowMenu = ShowMenu
	self.Layout = Layout

	self:SetAttribute('unit', 'pet')
	self:SetAttribute('statemap-unitexists-true',  '1')
	self:SetAttribute('statemap-unitexists-false', '0')
	RegisterUnitWatch(self, true)

	for i=1, NUM_PET_ACTION_SLOTS do
		BPetButton.Set(i, self)
	end
	SecureStateHeader_Refresh(self)
end

Bongos.AddStartup(function()
	if not Bongos.GetBarSets('pet') then
		Bongos.SetBarSets('pet', {x = 579.75, y = 598.80, x = 579.75, vis = 1})
	end

	local bar = BBar.Create('pet', OnCreate, nil, 'SecureStateHeaderTemplate')
	bar:SetScript("OnEvent", OnEvent)
	bar:RegisterEvent("UNIT_FLAGS")
	bar:RegisterEvent("UNIT_AURA")
	bar:RegisterEvent("PET_BAR_UPDATE")
	bar:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
	bar:RegisterEvent("PET_BAR_SHOWGRID")
	bar:RegisterEvent("PET_BAR_HIDEGRID")
	bar:RegisterEvent("UPDATE_BINDINGS")

	bar:Layout()
end)