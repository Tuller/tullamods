--[[
	Bongos MapBar
		Makes the minimap frame movable
--]]

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

local function CreateConfigMenu(name, frame)
	local menu = CreateFrame("Button", name, UIParent, "BongosRightClickMenu")
	menu.frame = frame

	menu:SetText("Map Bar")
	menu:SetWidth(220)
	menu:SetHeight(260)

	--checkbuttons
	local showTitle = CreateFrame("CheckButton", name .. "ShowTitle", menu, "GooeyCheckButton")
	showTitle:SetScript("OnClick", function() ToggleTitle(frame, this:GetChecked()) end)
	showTitle:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -28)
	showTitle:SetText(BONGOS_MAPBAR_SHOW_TITLE)

	local showZoom = CreateFrame("CheckButton", name .. "ShowZoom", menu, "GooeyCheckButton")
	showZoom:SetScript("OnClick", function() ToggleZoomButtons(frame, this:GetChecked()) end)
	showZoom:SetPoint("TOP", showTitle, "BOTTOM", 0, 2)
	showZoom:SetText(BONGOS_MAPBAR_SHOW_ZOOM)

	local showDayNight = CreateFrame("CheckButton", name .. "ShowDay", menu, "GooeyCheckButton")
	showDayNight:SetScript("OnClick", function() ToggleDayIndicator(frame, this:GetChecked()) end)
	showDayNight:SetPoint("TOP", showZoom, "BOTTOM", 0, 2)
	showDayNight:SetText(BONGOS_MAPBAR_SHOW_TIME)
	
	local showMap = CreateFrame("CheckButton", name .. "ShowMap", menu, "GooeyCheckButton")
	showMap:SetScript("OnClick", function() ToggleMap(frame, this:GetChecked()) end)
	showMap:SetPoint("TOP", showDayNight, "BOTTOM", 0, 2)
	showMap:SetText(BONGOS_MAPBAR_SHOW_MAP)

	--sliders
	local opacity = CreateFrame("Slider", name .. "Opacity", menu, "BongosOpacitySlider")
	opacity:SetPoint("BOTTOM", menu, "BOTTOM", 0, 24)
	
	local scale = CreateFrame("Slider", name .. "Scale", menu, "BongosScaleSlider")
	scale:SetPoint("BOTTOM", opacity, "TOP", 0, 24)
	
	return menu
end

--Called when the right click menu is shown, loads the correct values to the checkbuttons/sliders/text
local function ShowMenu(self)
	local name = 'BongosMapBarMenu'
	local menu = getglobal(name) or CreateConfigMenu(name, self)

	menu.onShow = 1
	
	getglobal(name .. 'ShowTitle'):SetChecked(self.sets.showTitle)
	getglobal(name .. 'ShowZoom'):SetChecked(self.sets.showZoom)
	getglobal(name .. 'ShowDay'):SetChecked(self.sets.showDay)
	getglobal(name .. 'ShowMap'):SetChecked(self.sets.showMap)

	self:DisplayMenu(menu)

	menu.onShow = nil
end


--[[ Startup ]]--

local function OnCreate(self)
	self.ShowMenu = ShowMenu

	self:SetFrameStrata('BACKGROUND')
	self:Attach(MinimapCluster)
	self:SetWidth(MinimapCluster:GetWidth())
	
	--make the minimap scrollable via the mousewheel
	local scrollFrame = CreateFrame('Frame', nil, Minimap)
	scrollFrame:SetAllPoints(scrollFrame:GetParent())
	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetScript('OnMouseWheel', function()
		if (Minimap:GetZoom() + arg1 <= Minimap:GetZoomLevels()) and (Minimap:GetZoom() + arg1 >= 0) then
			Minimap:SetZoom(Minimap:GetZoom() + arg1)
		end
	end)
end

Bongos.AddStartup(function()
	if not Bongos.GetBarSets('minimap') then
		Bongos.SetBarSets('minimap', {vis = 1, showTitle = 1})
	end

	local bar = BBar.Create('minimap', OnCreate)
	if not bar:IsUserPlaced() then
		bar:SetPoint("TOPRIGHT", UIParent)
	end
	
	--load settings
	--toggle title actually places the minimap on the bar, and adjusts the bar's height
	ToggleTitle(bar, bar.sets.showTitle)
	ToggleZoomButtons(bar, bar.sets.showZoom)
	ToggleDayIndicator(bar, bar.sets.showDay)
	ToggleMap(bar, bar.sets.showMap)
end)