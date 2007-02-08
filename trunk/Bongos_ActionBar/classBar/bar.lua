--[[
	BClassBar
		A replacement for the Blizzard shapeshift bar
--]]

--constants
local DEFAULT_SPACING = 2

local PLAYER_CLASS = select(2, UnitClass('player'))
if not(PLAYER_CLASS == 'DRUID' or PLAYER_CLASS == 'ROGUE' or PLAYER_CLASS == 'PALADIN' or PLAYER_CLASS == 'WARRIOR') then 
	return 
end 


--[[ Layout Functions ]]--

local function Layout(self, cols, space)
	if InCombatLockdown() then SeeQ.Do(function() self:Layout(cols, space) end) end
	local numForms = GetNumShapeshiftForms()
	
	cols = (cols or self.sets.cols or numForms)
	if cols == numForms then
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
	
	local buttonSize = 30 + space
	local offset = space / 2

	self:SetWidth(buttonSize * cols - space)
	self:SetHeight(buttonSize * ceil(numForms / cols) - space)

	for i = 1, numForms do
		local row = mod(i-1, cols)
		local col = ceil(i / cols) - 1
		BClassButton.Get(i):SetPoint('TOPLEFT', self, 'TOPLEFT', buttonSize * row, -buttonSize * col)
	end
end


--[[ OnX Functions ]]--

local function OnEvent()
	if event == "UPDATE_BINDINGS" then
		BClassButton.ForAll(BClassButton.UpdateHotkey)
	else
		for i=1, GetNumShapeshiftForms() do
			local button = BClassButton.Get(i)
			if not button then
				button = BClassButton.Create(i, this)
				layoutChanged = 1
			else
				button:Update()
			end
		end

		if layoutChanged then
			this:Layout()
			layoutChanged = nil
		end
	end
end


--[[ Rightclick Menu Functions ]]--

local function CreateConfigMenu(name, frame)
	local menu = CreateFrame("Button", name, UIParent, "BongosRightClickMenu")
	menu.frame = frame

	menu:SetText('Class Bar')
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
			frame:Layout(GetNumShapeshiftForms() - this:GetValue() + 1)
		end
		getglobal(this:GetName() .. 'ValText'):SetText(GetNumShapeshiftForms() - this:GetValue() + 1)
	end)
	cols:SetValueStep(1)
	getglobal(name .. "ColsText"):SetText(BONGOS_COLUMNS)
	getglobal(name .. "ColsHigh"):SetText(1)
	
	return menu
end

--Called when the right click menu is shown, loads the correct values to the checkbuttons/sliders/text
local function ShowMenu(self)
	local name = 'BongosClassBarMenu'
	local menu = getglobal(name) or CreateConfigMenu(name, self)

	menu.onShow = 1
	
	getglobal(name .. 'Cols'):SetMinMaxValues(1, GetNumShapeshiftForms())
	getglobal(name .. "ColsLow"):SetText(GetNumShapeshiftForms())
	getglobal(name .. 'Cols'):SetValue(GetNumShapeshiftForms() - (self.sets.cols or GetNumShapeshiftForms()) + 1)
	getglobal(name .. 'Spacing'):SetValue(self.sets.space or DEFAULT_SPACING)

	self:DisplayMenu(menu)

	menu.onShow = nil
end


--[[ Startup ]]--

local function OnCreate(self)
	self.ShowMenu = ShowMenu
	self.Layout = Layout
end

Bongos.AddStartup(function()
	if not Bongos.GetBarSets('class') then
		Bongos.SetBarSets('class', {x = 504.428, y = 600.571, vis = 1})
	end

	local bar = BBar.Create('class', OnCreate)

	bar:SetScript('OnEvent', OnEvent)
	bar:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
	bar:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
	bar:RegisterEvent("UPDATE_INVENTORY_ALERTS")
	bar:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	bar:RegisterEvent("SPELL_UPDATE_USABLE")
	bar:RegisterEvent("PLAYER_AURAS_CHANGED")
	bar:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
	bar:RegisterEvent("UNIT_HEALTH")
	bar:RegisterEvent("UNIT_RAGE")
	bar:RegisterEvent("UNIT_FOCUS")
	bar:RegisterEvent("UNIT_ENERGY")
	bar:RegisterEvent("UPDATE_BINDINGS")
end)