--[[
	Bongos MapBar
		Makes the minimap frame movable
--]]

BongosMapBar = Bongos:NewModule("Bongos-MapBar")

--[[
	Compatibility Fixes
		These functions are for fixing issues with other addons
--]]

--Make titan not take control of the minimap
if IsAddOnLoaded("Titan") then
	local oTitanMovableFrame_CheckTopFrame = TitanMovableFrame_CheckTopFrame
	TitanMovableFrame_CheckTopFrame = function(frameTop, top, frameName)
		if frameName ~= "MinimapCluster" then
			oTitanMovableFrame_CheckTopFrame(frameTop, top, frameName)
		end
	end
	TitanMovableData["MinimapCluster"] = nil
end


--[[ Config ]]--

local function ToggleTitle(self, enable)
	if enable then
		self.sets.showTitle = 1
		self:SetHeight(MinimapCluster:GetHeight())

		MinimapZoneTextButton:Show()
		MinimapToggleButton:Show()
		MinimapBorderTop:Show()

		MinimapCluster:ClearAllPoints()
		MinimapCluster:SetPoint("TOPLEFT", self)
	else
		self.sets.showTitle = nil
		self:SetHeight(MinimapCluster:GetHeight() - 12)

		MinimapZoneTextButton:Hide()
		MinimapToggleButton:Hide()
		MinimapBorderTop:Hide()

		MinimapCluster:ClearAllPoints()
		MinimapCluster:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 12)
	end
end

local function ToggleZoomButtons(self, enable)
	if enable then
		self.sets.showZoom = 1

		MinimapZoomIn:Show()
		MinimapZoomOut:Show()
	else
		self.sets.showZoom = nil

		MinimapZoomIn:Hide()
		MinimapZoomOut:Hide()
	end
end

local function ToggleDayIndicator(self, enable)
	if enable then
		self.sets.showDay = 1
		GameTimeFrame:Show()
	else
		self.sets.showDay = nil
		GameTimeFrame:Hide()
	end
end

local function ToggleMap(self, enable)
	if enable then
		self.sets.showMap = 1
		MiniMapWorldMapButton:Show()
	else
		self.sets.showMap = nil
		MiniMapWorldMapButton:Hide()
	end
end

local function Bar_CreateMenu(self)
	local name = format("BongosMenu%s", self.id)
	local menu = BongosMenu:Create(name)
	menu.text:SetText("Map Bar")
	menu.frame = self

	--checkbuttons
	local showTitle = menu:CreateCheckButton(name .. "ShowTitle")
	showTitle:SetScript("OnShow", function(b) b:SetChecked(self.sets.showTitle) end)
	showTitle:SetScript("OnClick", function(b) ToggleTitle(self, b:GetChecked()) end)
	showTitle:SetText(BONGOS_MAPBAR_SHOW_TITLE)

	local showZoom = menu:CreateCheckButton(name .. "ShowZoom")
	showZoom:SetScript("OnShow", function(b) b:SetChecked(self.sets.showZoom) end)
	showZoom:SetScript("OnClick", function(b) ToggleZoomButtons(self, b:GetChecked()) end)
	showZoom:SetText(BONGOS_MAPBAR_SHOW_ZOOM)

	local showDayNight = menu:CreateCheckButton(name .. "ShowDay")
	showDayNight:SetScript("OnShow", function(b) b:SetChecked(self.sets.showDay) end)
	showDayNight:SetScript("OnClick", function(b) ToggleDayIndicator(self, b:GetChecked()) end)
	showDayNight:SetText(BONGOS_MAPBAR_SHOW_TIME)
	
	local showMap = menu:CreateCheckButton(name .. "ShowMap")
	showMap:SetScript("OnShow", function(b) b:SetChecked(self.sets.showMap) end)
	showMap:SetScript("OnClick", function(b) ToggleMap(self, b:GetChecked()) end)
	showMap:SetText(BONGOS_MAPBAR_SHOW_MAP)
	
	return menu
end


--[[ Startup ]]--

local function Bar_ShowMenu(self)
	if not self.menu then
		self.menu = Bar_CreateMenu(self)
	end

	local menu = self.menu
	menu.onShow = true
	self:PlaceMenu(menu)
	menu.onShow = nil
end

local function Bar_OnCreate(self)
	self.ShowMenu = Bar_ShowMenu
	self:EnableMouse(false)
	self:Attach(MinimapCluster)
	self:SetWidth(MinimapCluster:GetWidth())
	
	--make the minimap scrollable via the mousewheel
	local scrollFrame = CreateFrame("Frame", nil, Minimap)
	scrollFrame:SetAllPoints(Minimap)
	scrollFrame:EnableMouse(false)
	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetScript("OnMouseWheel", function(self, arg1)
		if (Minimap:GetZoom() + arg1 <= Minimap:GetZoomLevels()) and (Minimap:GetZoom() + arg1 >= 0) then
			Minimap:SetZoom(Minimap:GetZoom() + arg1)
		end
	end)
end

function BongosMapBar:Load()
	local bar = BBar:Create("minimap", Bar_OnCreate, nil, nil, "BACKGROUND")
	if not bar:IsUserPlaced() then
		bar:SetPoint("TOPRIGHT", UIParent)
	end
	
	--load settings
	--toggle title actually places the minimap on the bar, and adjusts the bar"s height
	ToggleTitle(bar, bar.sets.showTitle)
	ToggleZoomButtons(bar, bar.sets.showZoom)
	ToggleDayIndicator(bar, bar.sets.showDay)
	ToggleMap(bar, bar.sets.showMap)
	
	self.bar = bar
end

function BongosMapBar:Unload()
	self.bar:Destroy()
end