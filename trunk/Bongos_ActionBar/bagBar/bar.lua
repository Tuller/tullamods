--[[
	bar.lua
		Scripts used for the Bongos Bag bar

	Saved Variables:
		Bongos.bag = {
			<All variables from BBar>
			space
				The spacing between action buttons, in pixels.  A nil value means that the bar is using default spacing
			rows
				How many rows the bar is organized into.
			oneBag
				Flag for if we're only showing the main bag.
		}
--]]

--constants
local DEFAULT_SPACING = 4
local DEFAULT_ROWS = 1
local BAG_SIZE = 37
local bags = {CharacterBag3Slot, CharacterBag2Slot, CharacterBag1Slot, CharacterBag0Slot, MainMenuBarBackpackButton}


--[[ UI Functions ]]--

local function Layout(self, rows, space)
	rows = (rows or self.sets.rows or DEFAULT_ROWS)
	if rows == DEFAULT_ROWS then
		self.sets.rows = nil
	else
		self.sets.rows = rows
	end
	
	space = (space or self.sets.space or DEFAULT_SPACING)
	if space == DEFAULT_SPACING then
		self.sets.space = nil
	else
		self.sets.space = space
	end
	
	for _,bag in pairs(bags) do bag:ClearAllPoints() end

	if self.sets.oneBag then
		for i = 1, #bags-1 do bags[i]:Hide() end
		bags[#bags]:SetPoint('TOPLEFT', self)

		self:SetWidth(BAG_SIZE); self:SetHeight(BAG_SIZE)
	else
		for _,bag in pairs(bags) do bag:Show() end	
		bags[1]:SetPoint('TOPLEFT', self)

		--horizontal alignment
		if rows == 1 then
			for i = 2, #bags do
				bags[i]:SetPoint('LEFT', bags[i-1], 'RIGHT', space, 0)
			end
			self:SetWidth((BAG_SIZE + space)* #bags - space)
			self:SetHeight((BAG_SIZE + space) - space)
		--vertical alignment
		else
			for i = 2, #bags do
				bags[i]:SetPoint('TOP', bags[i-1], 'BOTTOM', 0, -space)
			end
			self:SetWidth((BAG_SIZE + space) - space)
			self:SetHeight((BAG_SIZE + space)*#bags - space)
		end
	end
end


--[[ Config Functions ]]--

local function ShowAsOneBag(self, enable)
	if enable then
		self.sets.oneBag = 1
	else
		self.sets.oneBag = nil
	end
	self:Layout()
end

local function SetVertical(self, enable)
	if enable then
		self:Layout(5)
	else
		self:Layout(1)
	end
end

local function CreateConfigMenu(name, frame)
	local menu = CreateFrame('Button', name, UIParent, "BongosRightClickMenu")
	menu.frame = frame

	menu:SetText('Bag Bar')
	menu:SetWidth(220); menu:SetHeight(230)

	--checkbuttons
	local oneBag = CreateFrame("CheckButton", name .. "OneBag", menu, "GooeyCheckButton")
	oneBag:SetScript("OnClick", function() ShowAsOneBag(frame, this:GetChecked()) end)
	oneBag:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -28)
	oneBag:SetText(BONGOS_ONE_BAG)

	local vertical = CreateFrame("CheckButton", name .. "Vertical", menu, "GooeyCheckButton")
	vertical:SetScript("OnClick", function() SetVertical(frame, this:GetChecked()) end)
	vertical:SetPoint("TOP", oneBag, "BOTTOM", 0, 2)
	vertical:SetText(BONGOS_VERTICAL)

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
	
	return menu
end

--Called when the right click menu is shown, loads the correct values to the checkbuttons/sliders/text
local function ShowMenu(self)
	local name = 'BongosBagBarMenu'
	local menu = getglobal(name) or CreateConfigMenu(name, self)

	menu.onShow = 1

	getglobal(name .. 'Spacing'):SetValue(self.sets.space or DEFAULT_SPACING)
	getglobal(name .. 'Vertical'):SetChecked(self.sets.rows)
	getglobal(name .. 'OneBag'):SetChecked(self.sets.oneBag)

	self:DisplayMenu(menu)

	menu.onShow = nil
end

local function OnCreate(self)
	self.ShowMenu = ShowMenu
	self.Layout = Layout
	
	for _,bag in pairs(bags) do
		self:Attach(bag)
	end

	if self.sets.vis then
		MainMenuBarBackpackButton:Show()
	end
end


--[[ Startup ]]--

Bongos.AddStartup(function()
	if not Bongos.GetBarSets('bags') then
		Bongos.SetBarSets('bags', {x = 1261.85, y = 37, vis = 1})
	end

	local bar = BBar.Create('bags', OnCreate)
	bar:Layout()
end)